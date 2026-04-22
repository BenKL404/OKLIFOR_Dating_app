import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import '../models/chat_models.dart';
import 'chat_repository.dart';

// ── Images mock Unsplash (stables, pas de quota) ─────────────────────────

const _kMockImages = [
  'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&q=80&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=600&q=80&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=600&q=80&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=600&q=80&auto=format&fit=crop',
];

// ── Réponses automatiques simulées ───────────────────────────────────────

const _kAutoReplies = [
  'Ah oui, bonne idée 😄',
  'C\'est noté, je te recontacte bientôt !',
  '👍👍',
  'Super, j\'adore ça !',
  'Haha tu es trop drôle 😂',
  'Ok ok, à tout à l\'heure alors !',
  'Je suis là, t\'inquiète 😌',
  'Attends je regarde ça…',
  '🔥🔥🔥',
  'Hmm, je sais pas encore, on verra !',
];

// ── Messages initiaux enrichis par thread ────────────────────────────────

List<ChatMessage> _buildMessages(String threadId) {
  final now = DateTime.now();
  String t(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  switch (threadId) {
    case 'afi':
      return [
        ChatMessage(
          id: 'afi-1',
          kind: ChatMessageKind.system,
          text: 'Messages chiffrés de bout en bout · Oklifor',
          mine: false,
          time: t(now.subtract(const Duration(hours: 2))),
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        ChatMessage(
          id: 'afi-2',
          kind: ChatMessageKind.text,
          text: 'Coucou Afi ! Tu as vu le coucher de soleil hier soir ?',
          mine: true,
          time: t(now.subtract(const Duration(hours: 1, minutes: 30))),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
          readByRecipient: true,
        ),
        ChatMessage(
          id: 'afi-2b',
          kind: ChatMessageKind.image,
          imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&q=80&auto=format&fit=crop',
          text: 'Voici une photo de nous deux 📸',
          mine: true,
          time: t(now.subtract(const Duration(hours: 1, minutes: 28))),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 28)),
          readByRecipient: true,
        ),
        ChatMessage(
          id: 'afi-3',
          kind: ChatMessageKind.image,
          imageUrl: 'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=600&q=80&auto=format&fit=crop',
          text: 'Regarde ce coucher de soleil 🌅',
          mine: false,
          time: t(now.subtract(const Duration(hours: 1, minutes: 20))),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        ),
        ChatMessage(
          id: 'afi-4',
          kind: ChatMessageKind.text,
          text: 'C\'est la photo que j\'ai prise depuis la plage ! 😍',
          mine: false,
          time: t(now.subtract(const Duration(hours: 1, minutes: 19))),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 19)),
        ),
        ChatMessage(
          id: 'afi-5',
          kind: ChatMessageKind.voice,
          voiceSeconds: 18,
          audioUrl: null,
          mine: true,
          time: t(now.subtract(const Duration(minutes: 45))),
          createdAt: now.subtract(const Duration(minutes: 45)),
          readByRecipient: true,
        ),
        ChatMessage(
          id: 'afi-6',
          kind: ChatMessageKind.text,
          text: 'Haha tu es trop drôle 😂',
          mine: false,
          time: t(now.subtract(const Duration(minutes: 10))),
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
        ChatMessage(
          id: 'afi-8',
          kind: ChatMessageKind.video,
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80&auto=format&fit=crop',
          text: 'Vraiment cool ce nouveau lecteur ! 🐝',
          mine: false,
          time: t(now.subtract(const Duration(minutes: 2))),
          createdAt: now.subtract(const Duration(minutes: 2)),
        ),
      ];

    case 'kofi':
      return [
        ChatMessage(
          id: 'kofi-1',
          kind: ChatMessageKind.system,
          text: 'Messages chiffrés de bout en bout · Oklifor',
          mine: false,
          time: t(now.subtract(const Duration(hours: 3))),
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        ChatMessage(
          id: 'kofi-2',
          kind: ChatMessageKind.text,
          text: 'Kofi, t\'es dispo ce soir pour le foot ?',
          mine: true,
          time: t(now.subtract(const Duration(hours: 2))),
          createdAt: now.subtract(const Duration(hours: 2)),
          readByRecipient: true,
        ),
        ChatMessage(
          id: 'kofi-3',
          kind: ChatMessageKind.voice,
          voiceSeconds: 8,
          audioUrl: null,
          mine: false,
          time: t(now.subtract(const Duration(hours: 1, minutes: 50))),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 50)),
        ),
        ChatMessage(
          id: 'kofi-4',
          kind: ChatMessageKind.image,
          imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80&auto=format&fit=crop',
          mine: false,
          time: t(now.subtract(const Duration(hours: 1))),
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        ChatMessage(
          id: 'kofi-5',
          kind: ChatMessageKind.text,
          text: 'La plage c\'est trop bien aujourd\'hui 🏖️',
          mine: false,
          time: t(now.subtract(const Duration(hours: 1))),
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        ChatMessage(
          id: 'kofi-6',
          kind: ChatMessageKind.text,
          text: 'RDV demain à Kodjoviakopé ?',
          mine: false,
          time: t(now.subtract(const Duration(minutes: 15))),
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
      ];

    case 'g-weekend':
      return [
        ChatMessage(
          id: 'gw-1',
          kind: ChatMessageKind.system,
          text: 'Tu as créé le groupe « Week-end Lomé »',
          mine: false,
          time: t(now.subtract(const Duration(days: 1, hours: 5))),
          createdAt: now.subtract(const Duration(days: 1, hours: 5)),
        ),
        ChatMessage(
          id: 'gw-2',
          kind: ChatMessageKind.text,
          text: 'Salut tout le monde ! On se retrouve où samedi ?',
          mine: false,
          time: t(now.subtract(const Duration(hours: 10))),
          createdAt: now.subtract(const Duration(hours: 10)),
        ),
        ChatMessage(
          id: 'gw-3',
          kind: ChatMessageKind.text,
          text: 'Place de la préf ? 16h',
          mine: true,
          time: t(now.subtract(const Duration(hours: 9, minutes: 50))),
          createdAt: now.subtract(const Duration(hours: 9, minutes: 50)),
          readByRecipient: true,
        ),
        ChatMessage(
          id: 'gw-4',
          kind: ChatMessageKind.location,
          locationLabel: 'Marché de Tokoin — Lomé',
          mine: false,
          time: t(now.subtract(const Duration(hours: 9, minutes: 30))),
          createdAt: now.subtract(const Duration(hours: 9, minutes: 30)),
        ),
        ChatMessage(
          id: 'gw-5',
          kind: ChatMessageKind.image,
          imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&q=80&auto=format&fit=crop',
          mine: false,
          time: t(now.subtract(const Duration(hours: 5))),
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        ChatMessage(
          id: 'gw-6',
          kind: ChatMessageKind.text,
          text: 'Kofi : j\'apporte les jus 🧃',
          mine: false,
          time: t(now.subtract(const Duration(hours: 2))),
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ];

    case 'sena':
      return [
        ChatMessage(
          id: 'sena-1',
          kind: ChatMessageKind.system,
          text: 'Messages chiffrés de bout en bout · Oklifor',
          mine: false,
          time: t(now.subtract(const Duration(hours: 4))),
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
        ChatMessage(
          id: 'sena-2',
          kind: ChatMessageKind.text,
          text: 'Sena ! Nouveau café spot à Tokoin, tu connais ?',
          mine: true,
          time: t(now.subtract(const Duration(hours: 3))),
          createdAt: now.subtract(const Duration(hours: 3)),
          readByRecipient: true,
        ),
        ChatMessage(
          id: 'sena-3',
          kind: ChatMessageKind.image,
          imageUrl: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=600&q=80&auto=format&fit=crop',
          mine: true,
          time: t(now.subtract(const Duration(hours: 2, minutes: 55))),
          createdAt: now.subtract(const Duration(hours: 2, minutes: 55)),
          readByRecipient: true,
        ),
        ChatMessage(
          id: 'sena-4',
          kind: ChatMessageKind.text,
          text: 'J\'ai vu ta story 🔥',
          mine: false,
          time: t(now.subtract(const Duration(hours: 1, minutes: 30))),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        ),
      ];

    case 'mawuli':
      return [
        ChatMessage(
          id: 'maw-1',
          kind: ChatMessageKind.system,
          text: 'Messages chiffrés de bout en bout · Oklifor',
          mine: false,
          time: t(now.subtract(const Duration(hours: 6))),
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        ChatMessage(
          id: 'maw-2',
          kind: ChatMessageKind.text,
          text: 'Mawuli, tu fais quoi ce week-end ? Rando à Kpalimé ?',
          mine: true,
          time: t(now.subtract(const Duration(hours: 2))),
          createdAt: now.subtract(const Duration(hours: 2)),
          readByRecipient: true,
        ),
        ChatMessage(
          id: 'maw-3',
          kind: ChatMessageKind.voice,
          voiceSeconds: 24,
          audioUrl: null,
          mine: false,
          time: t(now.subtract(const Duration(hours: 1, minutes: 30))),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        ),
        ChatMessage(
          id: 'maw-4',
          kind: ChatMessageKind.image,
          imageUrl: 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=600&q=80&auto=format&fit=crop',
          mine: false,
          time: t(now.subtract(const Duration(hours: 1))),
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        ChatMessage(
          id: 'maw-5',
          kind: ChatMessageKind.text,
          text: 'OK je te fais signe',
          mine: false,
          time: t(now.subtract(const Duration(minutes: 60))),
          createdAt: now.subtract(const Duration(minutes: 60)),
        ),
      ];

    default:
      return [
        ChatMessage(
          id: '$threadId-v1',
          kind: ChatMessageKind.video,
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&q=80&auto=format&fit=crop',
          text: 'Vraiment cool ce nouveau lecteur ! 🐝',
          mine: false,
          time: t(now.subtract(const Duration(minutes: 2))),
          createdAt: now.subtract(const Duration(minutes: 2)),
        ),
      ];
  }
}

// ── MockChatRepository ────────────────────────────────────────────────────

class MockChatRepository implements ChatRepository {
  final _rng = Random();

  // État mutable en mémoire
  final List<ChatThread> _threads = List.from(kSeedThreads);
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, StreamController<ChatRepoEvent>> _watchControllers = {};
  final Map<String, Timer?> _autoReplyTimers = {};

  int _msgCounter = 1000;

  MockChatRepository() {
    for (final t in kSeedThreads) {
      _messages[t.id] = _buildMessages(t.id);
    }
  }

  // ── Threads ──────────────────────────────────────────────────────────────

  @override
  Future<List<ChatThread>> fetchThreads() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_threads);
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  @override
  Future<List<ChatMessage>> fetchMessages(String threadId, {int page = 0}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _messages.putIfAbsent(threadId, () => _buildMessages(threadId));
    return List.unmodifiable(_messages[threadId]!);
  }

  // ── Send helpers ─────────────────────────────────────────────────────────

  String _newId() => 'mock_${_msgCounter++}';
  String _nowTime() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  void _appendMessage(String threadId, ChatMessage msg) {
    _messages.putIfAbsent(threadId, () => []);
    _messages[threadId]!.add(msg);
    _watchControllers[threadId]?.add(ChatRepoMessageEvent(msg));
    _updateThreadPreview(threadId, msg);
  }

  void _updateThreadPreview(String threadId, ChatMessage msg) {
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx < 0) return;
    String preview;
    switch (msg.kind) {
      case ChatMessageKind.image:
        preview = '📷 Photo';
      case ChatMessageKind.video:
        preview = '🎥 Vidéo';
      case ChatMessageKind.voice:
        preview = '🎙️ Message vocal';
      case ChatMessageKind.file:
        preview = '📎 Fichier';
      case ChatMessageKind.location:
        preview = '📍 Localisation';
      default:
        preview = msg.text ?? '';
    }
    _threads[idx] = _threads[idx].copyWith(
      lastMsg: msg.mine ? 'Vous : $preview' : preview,
      time: msg.time,
      isUnread: !msg.mine,
      unreadCount: msg.mine ? 0 : (_threads[idx].unreadCount + 1),
    );
    // Remonte le fil en tête de liste
    final thread = _threads.removeAt(idx);
    _threads.insert(0, thread);
  }

  void _scheduleAutoReply(String threadId) {
    _autoReplyTimers[threadId]?.cancel();
    _autoReplyTimers[threadId] = Timer(
      Duration(milliseconds: 1200 + _rng.nextInt(2000)),
      () {
        // Indicateur "en train d'écrire…"
        _watchControllers[threadId]?.add(const ChatRepoTypingEvent(true));
        Timer(Duration(milliseconds: 800 + _rng.nextInt(1200)), () {
          _watchControllers[threadId]?.add(const ChatRepoTypingEvent(false));
          final reply = _kAutoReplies[_rng.nextInt(_kAutoReplies.length)];
          final msg = ChatMessage(
            id: _newId(),
            kind: ChatMessageKind.text,
            text: reply,
            mine: false,
            time: _nowTime(),
            createdAt: DateTime.now(),
          );
          _appendMessage(threadId, msg);
        });
      },
    );
  }

  @override
  Future<ChatMessage> sendText(String threadId, String text) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final msg = ChatMessage(
      id: _newId(),
      kind: ChatMessageKind.text,
      text: text,
      mine: true,
      time: _nowTime(),
      createdAt: DateTime.now(),
      readByRecipient: false,
    );
    _appendMessage(threadId, msg);
    _scheduleAutoReply(threadId);
    return msg;
  }

  @override
  Future<ChatMessage> sendImage(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Choisit une image mock au lieu d'uploader
    final url = _kMockImages[_rng.nextInt(_kMockImages.length)];
    final msg = ChatMessage(
      id: _newId(),
      kind: ChatMessageKind.image,
      imageUrl: url,
      text: caption,
      mine: true,
      time: _nowTime(),
      createdAt: DateTime.now(),
    );
    _appendMessage(threadId, msg);
    _scheduleAutoReply(threadId);
    return msg;
  }

  @override
  Future<ChatMessage> sendVideo(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final msg = ChatMessage(
      id: _newId(),
      kind: ChatMessageKind.video,
      videoUrl: 'mock://video/$filename',
      text: caption,
      mine: true,
      time: _nowTime(),
      createdAt: DateTime.now(),
    );
    _appendMessage(threadId, msg);
    _scheduleAutoReply(threadId);
    return msg;
  }

  @override
  Future<ChatMessage> sendAudio(
    String threadId,
    Uint8List bytes,
    String filename, {
    int durationSeconds = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final msg = ChatMessage(
      id: _newId(),
      kind: ChatMessageKind.voice,
      audioUrl: 'mock://audio/$filename',
      voiceSeconds: durationSeconds > 0 ? durationSeconds : 5,
      mine: true,
      time: _nowTime(),
      createdAt: DateTime.now(),
    );
    _appendMessage(threadId, msg);
    _scheduleAutoReply(threadId);
    return msg;
  }

  @override
  Future<ChatMessage> sendFile(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final msg = ChatMessage(
      id: _newId(),
      kind: ChatMessageKind.file,
      fileUrl: 'mock://file/$filename',
      text: caption ?? filename,
      mine: true,
      time: _nowTime(),
      createdAt: DateTime.now(),
    );
    _appendMessage(threadId, msg);
    _scheduleAutoReply(threadId);
    return msg;
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  @override
  Future<void> markRead(String threadId) async {
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx >= 0) {
      _threads[idx] = _threads[idx].copyWith(isUnread: false, unreadCount: 0);
    }
  }

  @override
  Future<void> deleteMessage(String threadId, String messageId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final threadMsgs = _messages[threadId];
    if (threadMsgs != null) {
      final index = threadMsgs.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        threadMsgs.removeAt(index);
      }
    }
  }

  @override
  Future<void> deleteThread(String threadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _threads.removeWhere((t) => t.id == threadId);
    _messages.remove(threadId);
  }

  @override
  Future<ChatThread> createDirectThread(String contactId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _threads.firstWhere(
      (t) => t.id == 'dm_$contactId',
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
    if (existing.id.isNotEmpty) return existing;

    final contact = kDemoContacts.firstWhere(
      (c) => c.id == contactId,
      orElse: () => ChatContact(
        id: contactId,
        name: 'Contact',
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80',
      ),
    );
    final thread = ChatThread(
      id: 'dm_$contactId',
      name: contact.name,
      lastMsg: '',
      time: _nowTime(),
      avatarUrl: contact.avatarUrl,
      statusImageUrl: '',
      statusCaption: '',
      statusTimeAgo: '',
      online: _rng.nextBool(),
    );
    _threads.insert(0, thread);
    return thread;
  }

  @override
  Future<ChatThread> createGroupThread(String name, List<String> memberIds) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final thread = ChatThread(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      lastMsg: '',
      time: _nowTime(),
      avatarUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=200&q=80',
      statusImageUrl: '',
      statusCaption: '',
      statusTimeAgo: '',
      isGroup: true,
      groupMemberCount: memberIds.length + 1,
    );
    _threads.insert(0, thread);
    _messages[thread.id] = [
      ChatMessage(
        id: '${thread.id}-sys',
        kind: ChatMessageKind.system,
        text: 'Groupe « $name » créé — invite tes ami·e·s.',
        mine: false,
        time: _nowTime(),
        createdAt: DateTime.now(),
      ),
    ];
    return thread;
  }

  @override
  Future<List<ChatContact>> fetchContacts() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(kDemoContacts);
  }

  // ── Stream temps réel ────────────────────────────────────────────────────

  @override
  Stream<ChatRepoEvent> watchThread(String threadId) {
    _watchControllers.putIfAbsent(
      threadId,
      () => StreamController<ChatRepoEvent>.broadcast(),
    );

    // Simule la présence du peer après 1 s
    Future.delayed(const Duration(seconds: 1), () {
      final idx = _threads.indexWhere((t) => t.id == threadId);
      final online = idx >= 0 ? _threads[idx].online : true;
      _watchControllers[threadId]?.add(ChatRepoPresenceEvent(online));
    });

    return _watchControllers[threadId]!.stream;
  }

  @override
  void dispose() {
    for (final c in _watchControllers.values) {
      c.close();
    }
    for (final t in _autoReplyTimers.values) {
      t?.cancel();
    }
    _watchControllers.clear();
    _autoReplyTimers.clear();
  }
}
