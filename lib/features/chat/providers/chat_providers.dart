import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_api_provider.dart';
import '../models/chat_models.dart';
import '../repository/api_chat_repository.dart';
import '../repository/chat_repository.dart';

// ── Repository singleton ──────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repo = ApiChatRepository(
    api: ref.watch(okliforApiClientProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

// ── Threads (liste des conversations) ─────────────────────────────────────

class ChatThreadsNotifier extends AsyncNotifier<List<ChatThread>> {
  @override
  Future<List<ChatThread>> build() async {
    return ref.read(chatRepositoryProvider).fetchThreads();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).fetchThreads(),
    );
  }

  void upsertThread(ChatThread updated) {
    final current = state.value ?? [];
    final idx = current.indexWhere((t) => t.id == updated.id);
    final list = List<ChatThread>.from(current);
    if (idx < 0) {
      list.insert(0, updated);
    } else {
      list.removeAt(idx);
      list.insert(0, updated);
    }
    state = AsyncData(list);
  }

  void prependThread(ChatThread thread) {
    final current = state.value ?? [];
    if (current.any((t) => t.id == thread.id)) return;
    state = AsyncData([thread, ...current]);
  }

  void removeThread(String threadId) {
    final current = state.value ?? [];
    state = AsyncData(current.where((t) => t.id != threadId).toList());
  }
}

final chatThreadsProvider =
    AsyncNotifierProvider<ChatThreadsNotifier, List<ChatThread>>(
  ChatThreadsNotifier.new,
);

// ── Store des messages (map threadId → messages) ──────────────────────────

class ChatMessagesStoreNotifier extends Notifier<Map<String, List<ChatMessage>>> {
  @override
  Map<String, List<ChatMessage>> build() => {};

  List<ChatMessage> getMessages(String threadId) => state[threadId] ?? const [];

  void setMessages(String threadId, List<ChatMessage> messages) {
    state = {...state, threadId: List.unmodifiable(messages)};
  }

  void appendMessage(String threadId, ChatMessage msg) {
    final current = state[threadId] ?? [];
    state = {...state, threadId: [...current, msg]};
    // Met à jour l'aperçu du fil
    _updateThreadPreview(threadId, msg);
  }

  void _updateThreadPreview(String threadId, ChatMessage msg) {
    String preview;
    switch (msg.kind) {
      case ChatMessageKind.image:
        preview = '📷 Photo';
      case ChatMessageKind.video:
        preview = '🎥 Vidéo';
      case ChatMessageKind.voice:
        preview = '🎙️ Vocal';
      case ChatMessageKind.file:
        preview = '📎 Fichier';
      case ChatMessageKind.location:
        preview = '📍 Localisation';
      default:
        preview = msg.text ?? '';
    }
    final thread = ref.read(chatThreadsProvider).value?.firstWhere(
          (t) => t.id == threadId,
          orElse: () => const ChatThread(
            id: '',
            name: '',
            lastMsg: '',
            time: '',
            avatarUrl: '',
            statusImageUrl: '',
            statusCaption: '',
            statusTimeAgo: '',
          ),
        );
    if (thread == null || thread.id.isEmpty) return;
    ref.read(chatThreadsProvider.notifier).upsertThread(
          thread.copyWith(
            lastMsg: msg.mine ? 'Vous : $preview' : preview,
            time: msg.time,
            isUnread: !msg.mine,
            unreadCount: msg.mine ? 0 : thread.unreadCount + 1,
          ),
        );
  }
}

final chatMessagesStoreProvider =
    NotifierProvider<ChatMessagesStoreNotifier, Map<String, List<ChatMessage>>>(
  ChatMessagesStoreNotifier.new,
);

// Vue dérivée par thread (lecture seule)
final messagesForThreadProvider =
    Provider.family<List<ChatMessage>, String>((ref, threadId) {
  return ref.watch(chatMessagesStoreProvider)[threadId] ?? const [];
});

// ── Présence & typing par thread ──────────────────────────────────────────

class ThreadPresenceState {
  final bool online;
  final bool typing;
  const ThreadPresenceState({this.online = false, this.typing = false});
  ThreadPresenceState copyWith({bool? online, bool? typing}) =>
      ThreadPresenceState(
        online: online ?? this.online,
        typing: typing ?? this.typing,
      );
}

class ChatPresenceStoreNotifier
    extends Notifier<Map<String, ThreadPresenceState>> {
  @override
  Map<String, ThreadPresenceState> build() => {};

  void setPresence(String threadId, ThreadPresenceState s) {
    state = {...state, threadId: s};
  }

  void updateOnline(String threadId, bool online) {
    final current = state[threadId] ?? const ThreadPresenceState();
    state = {...state, threadId: current.copyWith(online: online)};
  }

  void updateTyping(String threadId, bool typing) {
    final current = state[threadId] ?? const ThreadPresenceState();
    state = {...state, threadId: current.copyWith(typing: typing)};
  }
}

final chatPresenceStoreProvider =
    NotifierProvider<ChatPresenceStoreNotifier, Map<String, ThreadPresenceState>>(
  ChatPresenceStoreNotifier.new,
);

final presenceForThreadProvider =
    Provider.family<ThreadPresenceState, String>((ref, threadId) {
  return ref.watch(chatPresenceStoreProvider)[threadId] ??
      const ThreadPresenceState();
});

// ── Service de watch (abonnement aux events d'un thread) ─────────────────

/// Gère le stream d'évènements d'un thread et met à jour les stores.
class ThreadWatcherNotifier extends AsyncNotifier<void> {
  StreamSubscription<ChatRepoEvent>? _sub;
  Timer? _typingHideTimer;
  late String _threadId;

  @override
  Future<void> build() async {}

  void startWatching(String threadId) {
    if (_sub != null && _threadId == threadId) return;
    _threadId = threadId;
    ref.onDispose(stopWatching);
    _sub?.cancel();
    final repo = ref.read(chatRepositoryProvider);

    _sub = repo.watchThread(threadId).listen((event) {
      switch (event) {
        case ChatRepoMessageEvent(:final message):
          ref.read(chatMessagesStoreProvider.notifier).appendMessage(
                threadId,
                message,
              );
        case ChatRepoPresenceEvent(:final online):
          ref
              .read(chatPresenceStoreProvider.notifier)
              .updateOnline(threadId, online);
        case ChatRepoTypingEvent(:final typing):
          ref
              .read(chatPresenceStoreProvider.notifier)
              .updateTyping(threadId, typing);
          if (typing) {
            _typingHideTimer?.cancel();
            _typingHideTimer = Timer(const Duration(seconds: 3), () {
              ref
                  .read(chatPresenceStoreProvider.notifier)
                  .updateTyping(threadId, false);
            });
          }
        case ChatRepoReadEvent():
          break;
      }
    });
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
    _typingHideTimer?.cancel();
  }

}

// Un watcher par thread
final threadWatcherProvider =
    AsyncNotifierProvider<ThreadWatcherNotifier, void>(
  ThreadWatcherNotifier.new,
);

// ── Helpers d'envoi de messages ───────────────────────────────────────────

extension ChatSend on WidgetRef {
  ChatRepository get _repo => read(chatRepositoryProvider);
  ChatMessagesStoreNotifier get _store =>
      read(chatMessagesStoreProvider.notifier);

  Future<void> chatSendText(String threadId, String text) async {
    final msg = await _repo.sendText(threadId, text);
    _store.appendMessage(threadId, msg);
  }

  Future<void> chatSendImage(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  }) async {
    final msg =
        await _repo.sendImage(threadId, bytes, filename, caption: caption);
    _store.appendMessage(threadId, msg);
  }

  Future<void> chatSendVideo(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  }) async {
    final msg =
        await _repo.sendVideo(threadId, bytes, filename, caption: caption);
    _store.appendMessage(threadId, msg);
  }

  Future<void> chatSendAudio(
    String threadId,
    Uint8List bytes,
    String filename, {
    int durationSeconds = 0,
  }) async {
    final msg = await _repo.sendAudio(
      threadId,
      bytes,
      filename,
      durationSeconds: durationSeconds,
    );
    _store.appendMessage(threadId, msg);
  }

  Future<void> chatSendFile(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  }) async {
    final msg =
        await _repo.sendFile(threadId, bytes, filename, caption: caption);
    _store.appendMessage(threadId, msg);
  }
}

// ── Contacts ──────────────────────────────────────────────────────────────

final chatContactsProvider = FutureProvider<List<ChatContact>>((ref) {
  return ref.read(chatRepositoryProvider).fetchContacts();
});
