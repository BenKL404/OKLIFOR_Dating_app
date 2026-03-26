import 'dart:async';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/oklifor_media_url.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_chat_attachment_launch.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/utils/okl_media_cache.dart';
import '../../../core/utils/okl_persistent_media_store.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../data/chat_api_mapping.dart';
import '../data/chat_local_cache.dart';
import '../data/chat_websocket_client.dart';
import '../models/chat_models.dart';
import 'chat_image_viewer_screen.dart';
import 'chat_thread_detail_screen.dart';
import 'conversation_search_screen.dart';
import 'conversation_media_screen.dart';
import 'conversation_mute_screen.dart';
import 'gallery_picker_screen.dart';
import 'document_compose_screen.dart';
import 'share_contact_screen.dart';
import 'new_message_screen.dart';

final _chatMediaCache = oklChatMediaCache;

const _waBg = Color(0xFF0B141A);
const _waAppBar = Color(0xFF202C33);
const _waIncomingBubble = Color(0xFF202C33);
const _waOutgoingBubble = Color(0xFF005C4B);
const _waInput = Color(0xFF202C33);
const _waTextPrimary = Colors.white;
const _waTextSecondary = Color(0xFF8696A0);

/// Conversation 1:1 ou groupe avec bulles riches (texte, image, vocal, lieu, système).
class ConversationScreen extends ConsumerStatefulWidget {
  final ChatThread thread;
  final List<ChatMessage>? initialMessagesOverride;
  final void Function(String lastMessage, String time)? onThreadPreviewUpdated;

  const ConversationScreen({
    super.key,
    required this.thread,
    this.initialMessagesOverride,
    this.onThreadPreviewUpdated,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _canSend = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordTimer;
  late List<ChatMessage> _messages;
  bool _loadingRemote = false;
  bool _isUploadingMedia = false;
  String? _uploadError;
  Future<void> Function()? _retryUploadAction;
  ChatWebSocketClient? _wsClient;
  StreamSubscription<dynamic>? _wsMessageSub;
  StreamSubscription<dynamic>? _wsPresenceSub;
  StreamSubscription<dynamic>? _wsTypingSub;
  StreamSubscription<dynamic>? _wsReadReceiptSub;
  StreamSubscription<String>? _wsErrorSub;
  String? _myUserId;
  bool _peerOnline = false;
  bool _peerTyping = false;
  int? _peerLastSeenEpoch;
  Timer? _typingStopDebounce;
  Timer? _peerTypingHideTimer;
  bool _lastTypingSent = false;
  DateTime? _lastTypingSentAt;
  late final AudioRecorder _audioRecorder;
  ChatMessage? _replyingTo;
  Timer? _persistMessagesDebounce;
  final Map<String, String> _messageReactions = <String, String>{};
  String? _resolvedPeerName;
  String? _resolvedPeerAvatarUrl;
  final Set<String> _prefetchedMediaUrls = <String>{};
  final Set<String> _prefetchedPersistentUrls = <String>{};

  @override
  void initState() {
    super.initState();
    final useRemote =
        widget.initialMessagesOverride == null &&
        isBackendThreadId(widget.thread.id);
    if (useRemote) {
      _loadingRemote = true;
      _messages = [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRemoteMessages();
        _connectRealtime();
        _scrollToEnd();
      });
    } else {
      _messages = List<ChatMessage>.from(
        widget.initialMessagesOverride ??
            seedMessagesForThread(widget.thread.id),
      );
    }
    _audioRecorder = AudioRecorder();
    _messageController.addListener(_syncSendState);
    if (isBackendThreadId(widget.thread.id) && !widget.thread.isGroup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_hydratePeerIdentity());
      });
    }
    if (!useRemote) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  Future<void> _hydratePeerIdentity() async {
    try {
      final api = ref.read(okliforApiClientProvider);
      final storage = ref.read(authTokenStorageProvider);
      final myId = await storage.readUserId();
      String? peerId;
      for (final id in widget.thread.participantUserIds) {
        if (id != myId) {
          peerId = id;
          break;
        }
      }
      if (peerId == null) return;
      final contacts = await api.fetchContacts();
      dynamic match;
      for (final c in contacts) {
        if (c.userId == peerId) {
          match = c;
          break;
        }
      }
      // Fallback: si pas dans les contacts, on tente de l'ajouter pour obtenir
      // displayName/avatar (et on garde les infos si dispo).
      if (match == null) {
        try {
          match = await api.addContactByUserId(peerId);
        } catch (_) {}
      }
      if (!mounted || match == null) return;
      final displayName = (match.displayName as String?)?.trim();
      final avatarRaw = (match.avatarUrl as String?)?.trim();
      setState(() {
        if (displayName != null && displayName.isNotEmpty) {
          _resolvedPeerName = displayName;
        }
        if (avatarRaw != null && avatarRaw.isNotEmpty) {
          _resolvedPeerAvatarUrl = OkliforMediaUrl.resolve(avatarRaw);
        }
      });
    } catch (_) {
      // Ignore: keep thread seed data if contact lookup fails.
    }
  }

  Future<void> _loadRemoteMessages() async {
    final storage = ref.read(authTokenStorageProvider);
    final myId = await storage.readUserId();

    if (myId != null && myId.isNotEmpty) {
      final cached = await ChatLocalCache.loadMessages(myId, widget.thread.id);
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _messages = List<ChatMessage>.from(cached);
          _loadingRemote = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    }

    try {
      final api = ref.read(okliforApiClientProvider);
      final list = await api.fetchChatMessages(widget.thread.id);
      final mapped = chatMessagesFromPayloads(list, myUserId: myId);
      if (!mounted) return;
      setState(() {
        _messages = List<ChatMessage>.from(mapped);
        _loadingRemote = false;
      });
      _prefetchRecentMedia(mapped);
      _prefetchPersistentDocuments(mapped);
      if (myId != null && myId.isNotEmpty) {
        unawaited(
          ChatLocalCache.saveMessages(myId, widget.thread.id, _messages),
        );
      }
      unawaited(_markReadHttp());
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } catch (_) {
      if (!mounted) return;
      if (_messages.isEmpty) {
        setState(() {
          _messages = List<ChatMessage>.from(
            seedMessagesForThread(widget.thread.id),
          );
          _loadingRemote = false;
        });
      } else {
        setState(() => _loadingRemote = false);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  void _prefetchPersistentDocuments(List<ChatMessage> msgs) {
    for (final m in msgs) {
      if (m.kind != ChatMessageKind.file) continue;
      final raw = (m.fileUrl ?? '').trim();
      if (raw.isEmpty) continue;
      final resolved = OkliforMediaUrl.resolve(raw);
      if (!_prefetchedPersistentUrls.add(resolved)) continue;
      unawaited(
        ensureOkliforLocalFile(
          resolved,
          bucket: OklMediaBucket.documents,
          displayName: _cleanDocumentLabel(m.text),
        ).then((_) {
          if (!mounted) return;
          // Refresh doc card state ("Télécharger" disappears).
          setState(() {});
        }),
      );
    }
  }

  @override
  void dispose() {
    _wsMessageSub?.cancel();
    _wsPresenceSub?.cancel();
    _wsTypingSub?.cancel();
    _wsReadReceiptSub?.cancel();
    _wsErrorSub?.cancel();
    _wsClient?.dispose();
    _recordTimer?.cancel();
    _typingStopDebounce?.cancel();
    _peerTypingHideTimer?.cancel();
    _persistMessagesDebounce?.cancel();
    _messageController.removeListener(_syncSendState);
    _audioRecorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connectRealtime() async {
    if (!isBackendThreadId(widget.thread.id)) return;
    try {
      final storage = ref.read(authTokenStorageProvider);
      final token = await storage.readAccessToken();
      final myId = await storage.readUserId();
      if (token == null || token.isEmpty) return;
      _myUserId = myId;
      final client = ChatWebSocketClient();
      await client.connect(accessToken: token);
      try {
        await client.subscribeThreadAndWait(widget.thread.id);
      } catch (e) {
        // ignore: avoid_print
        print('WS subscribe failed for ${widget.thread.id}: $e');
      }
      await _wsMessageSub?.cancel();
      await _wsPresenceSub?.cancel();
      await _wsTypingSub?.cancel();
      await _wsReadReceiptSub?.cancel();
      await _wsErrorSub?.cancel();
      _wsClient = client;
      _wsMessageSub = client.messages.listen((payload) {
        if (!mounted) return;
        if (payload.threadId != widget.thread.id) return;
        final msg = chatMessageFromPayload(payload, myUserId: _myUserId);
        if (msg.mine) {
          final localIdx = _messages.indexWhere(
            (m) =>
                m.id.startsWith('local_') &&
                m.mine &&
                m.kind == msg.kind &&
                (msg.kind == ChatMessageKind.text
                    ? (m.text ?? '') == (msg.text ?? '')
                    : true),
          );
          if (localIdx >= 0) {
            setState(() => _messages.removeAt(localIdx));
            _schedulePersistMessages();
          }
        }
        final dupIdx = _messages.indexWhere((m) => m.id == msg.id);
        if (dupIdx >= 0) {
          final prev = _messages[dupIdx];
          if (msg.readByRecipient && !prev.readByRecipient) {
            setState(
              () => _messages[dupIdx] =
                  prev.copyWith(readByRecipient: true),
            );
            _schedulePersistMessages();
          }
          if (!msg.mine) unawaited(_notifyReadCur());
          return;
        }
        setState(() => _messages.add(msg));
        // Auto-download documents on receipt.
        if (!msg.mine && msg.kind == ChatMessageKind.file) {
          _prefetchPersistentDocuments([msg]);
        }
        if (!msg.mine) {
          unawaited(_notifyReadCur());
          if (_peerTyping) setState(() => _peerTyping = false);
        }
        _afterAppend();
      });
      _wsPresenceSub = client.presence.listen((event) {
        if (!mounted || event.threadId != widget.thread.id) return;
        if (_myUserId != null && event.userId == _myUserId) return;
        setState(() {
          _peerOnline = event.online;
          _peerLastSeenEpoch = event.lastSeenEpoch;
          if (_peerOnline) _peerTyping = false;
        });
      });
      _wsTypingSub = client.typing.listen((event) {
        if (!mounted || event.threadId != widget.thread.id) return;
        if (_myUserId != null && event.userId == _myUserId) return;
        _peerTypingHideTimer?.cancel();
        if (event.typing) {
          setState(() => _peerTyping = true);
          return;
        }
        _peerTypingHideTimer = Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() => _peerTyping = false);
        });
      });
      _wsReadReceiptSub = client.readReceipts.listen((event) {
        if (!mounted) return;
        _applyReadReceipt(event.threadId, event.userId, event.readAtEpoch);
      });
      _wsErrorSub = client.errors.listen((code) {
        // ignore: avoid_print
        print('WS chat error: $code');
      });
      unawaited(_notifyReadCur());
    } catch (_) {
      // Fallback HTTP uniquement si websocket indisponible.
    }
  }

  Future<void> _markReadHttp() async {
    if (!isBackendThreadId(widget.thread.id)) return;
    try {
      await ref.read(okliforApiClientProvider).markThreadRead(widget.thread.id);
    } catch (_) {}
  }

  Future<void> _notifyReadCur() async {
    if (!isBackendThreadId(widget.thread.id)) return;
    final ws = _wsClient;
    if (ws != null && ws.isConnected) {
      try {
        await ws.markRead(threadId: widget.thread.id);
      } catch (_) {
        await _markReadHttp();
      }
    } else {
      await _markReadHttp();
    }
  }

  void _applyReadReceipt(String threadId, String readerUserId, int readAtEpoch) {
    if (!mounted || threadId != widget.thread.id) return;
    if (_myUserId != null && readerUserId == _myUserId) return;
    if (readAtEpoch <= 0) return;
    final readAt = DateTime.fromMillisecondsSinceEpoch(
      readAtEpoch * 1000,
      isUtc: true,
    );
    setState(() {
      _messages = _messages.map((m) {
        if (!m.mine || m.readByRecipient) return m;
        if (m.createdAt == null) return m;
        final at = m.createdAt!.toUtc();
        if (!at.isAfter(readAt)) {
          return m.copyWith(readByRecipient: true);
        }
        return m;
      }).toList();
    });
    _schedulePersistMessages();
  }

  Future<bool> _sendBackendMessage({
    required String kind,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    int? voiceSeconds,
    String? locationLabel,
    String? fileUrl,
  }) async {
    if (!isBackendThreadId(widget.thread.id)) return false;
    final ws = _wsClient;
    if (ws != null && ws.isConnected) {
      try {
        await ws.sendMessage(
          threadId: widget.thread.id,
          kind: kind,
          text: text,
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          audioUrl: audioUrl,
          voiceSeconds: voiceSeconds,
          locationLabel: locationLabel,
          fileUrl: fileUrl,
        );
        return true;
      } catch (_) {
        // fallback HTTP
      }
    }
    try {
      final api = ref.read(okliforApiClientProvider);
      final storage = ref.read(authTokenStorageProvider);
      final myId = await storage.readUserId();
      final sent = await api.sendChatMessage(
        threadId: widget.thread.id,
        kind: kind,
        text: text,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        voiceSeconds: voiceSeconds,
        locationLabel: locationLabel,
        fileUrl: fileUrl,
      );
      if (!mounted) return true;
      final mapped = chatMessageFromPayload(sent, myUserId: myId);
      if (_messages.any((m) => m.id == mapped.id)) return true;
      setState(() => _messages.add(mapped));
      _afterAppend();
      return true;
    } catch (e) {
      if (mounted) {
        OklFeedback.snack(context, 'Envoi impossible : $e');
      }
      return false;
    }
  }

  void _syncSendState() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText == _canSend) return;
    setState(() => _canSend = hasText);
    _emitTyping(hasText);
  }

  void _emitTyping(bool hasText) {
    if (!isBackendThreadId(widget.thread.id)) return;
    final ws = _wsClient;
    if (ws == null || !ws.isConnected) return;
    final now = DateTime.now();
    final elapsedMs = _lastTypingSentAt == null
        ? 999999
        : now.difference(_lastTypingSentAt!).inMilliseconds;
    if (_lastTypingSent == hasText && elapsedMs < 700) {
      _typingStopDebounce?.cancel();
      if (hasText) {
        _typingStopDebounce = Timer(const Duration(seconds: 2), () {
          unawaited(ws.sendTyping(threadId: widget.thread.id, typing: false));
          _lastTypingSent = false;
          _lastTypingSentAt = DateTime.now();
        });
      }
      return;
    }
    _typingStopDebounce?.cancel();
    if (hasText) {
      unawaited(ws.sendTyping(threadId: widget.thread.id, typing: true));
      _lastTypingSent = true;
      _lastTypingSentAt = now;
      _typingStopDebounce = Timer(const Duration(seconds: 2), () {
        unawaited(ws.sendTyping(threadId: widget.thread.id, typing: false));
        _lastTypingSent = false;
        _lastTypingSentAt = DateTime.now();
      });
    } else {
      unawaited(ws.sendTyping(threadId: widget.thread.id, typing: false));
      _lastTypingSent = false;
      _lastTypingSentAt = now;
    }
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _popConversationRoot() {
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _persistMessagesForCache() async {
    if (!isBackendThreadId(widget.thread.id)) return;
    final myId = await ref.read(authTokenStorageProvider).readUserId();
    if (myId == null || myId.isEmpty || !mounted) return;
    await ChatLocalCache.saveMessages(
      myId,
      widget.thread.id,
      List<ChatMessage>.from(_messages),
    );
  }

  void _schedulePersistMessages() {
    if (!isBackendThreadId(widget.thread.id)) return;
    _persistMessagesDebounce?.cancel();
    _persistMessagesDebounce = Timer(const Duration(milliseconds: 800), () {
      unawaited(_persistMessagesForCache());
    });
  }

  void _afterAppend() {
    widget.onThreadPreviewUpdated?.call(
      _messagePreview(_messages.last),
      _messages.last.time,
    );
    _schedulePersistMessages();
    _prefetchRecentMedia(_messages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _prefetchRecentMedia(List<ChatMessage> messages) {
    if (kIsWeb) return;
    const maxPrefetch = 4;
    var count = 0;
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      final raw = switch (m.kind) {
        ChatMessageKind.image => (m.imageUrl ?? '').trim(),
        ChatMessageKind.video => (m.videoUrl ?? '').trim(),
        ChatMessageKind.voice => (m.audioUrl ?? '').trim(),
        _ => '',
      };
      if (raw.isEmpty) continue;
      final url = _absoluteMediaUrl(raw).trim();
      if (url.isEmpty) continue;
      if (_prefetchedMediaUrls.contains(url)) continue;
      _prefetchedMediaUrls.add(url);
      count += 1;
      unawaited(_chatMediaCache.downloadFile(url));
      if (count >= maxPrefetch) break;
    }
  }

  String _messagePreview(ChatMessage m) {
    if (m.text != null && m.text!.trim().isNotEmpty) return m.text!.trim();
    switch (m.kind) {
      case ChatMessageKind.image:
        return '📷 Photo';
      case ChatMessageKind.video:
        return '🎬 Vidéo';
      case ChatMessageKind.voice:
        return '🎤 Vocal';
      case ChatMessageKind.file:
        return m.text?.trim().isNotEmpty == true ? m.text!.trim() : '📄 Fichier';
      case ChatMessageKind.location:
        return '📍 Position';
      case ChatMessageKind.system:
        return 'Système';
      case ChatMessageKind.text:
        return 'Message';
    }
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _presenceSubtitle(ChatThread t) {
    if (t.isGroup) {
      return '${t.groupMemberCount} membres · Infos du groupe';
    }
    if (_peerTyping) return 'Écrit…';
    if (_peerOnline) return 'En ligne';
    if (_peerLastSeenEpoch != null && _peerLastSeenEpoch! > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        _peerLastSeenEpoch! * 1000,
      ).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return 'Vu à $hh:$mm';
    }
    return 'Hors ligne';
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _recordTimer?.cancel();
      setState(() => _isRecording = false);
      final seconds = _recordingSeconds.clamp(1, 999);
      _recordingSeconds = 0;
      if (isBackendThreadId(widget.thread.id)) {
        try {
          final recordedPath = await _audioRecorder.stop();
          if (recordedPath != null && recordedPath.isNotEmpty) {
            final upload = await ref
                .read(okliforApiClientProvider)
                .uploadChatMedia(
                  threadId: widget.thread.id,
                  filename:
                      'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
                  filePath: recordedPath,
                );
            final mediaKind = upload.mediaKind.toUpperCase();
            final url = _absoluteMediaUrl(upload.signedUrl);
            // Afficher d’abord le message local pour que l’écho WebSocket retire la bonne bulle.
            _appendLocalMineMessage(
              kind: ChatMessageKind.voice,
              audioUrl: url,
              voiceSeconds: seconds,
            );
            // Persist sender-side (no re-download): copy from recorded file.
            if (!kIsWeb) {
              try {
                await persistOkliforLocalFileFromPath(
                  upload.signedUrl,
                  bucket: OklMediaBucket.voiceNotes,
                  sourcePath: recordedPath,
                  displayName: 'voice_${widget.thread.id}_$seconds.m4a',
                );
              } catch (_) {}
            }
            await _sendBackendMessage(
              kind: mediaKind,
              audioUrl: (mediaKind == 'VOICE' || mediaKind == 'AUDIO')
                  ? url
                  : null,
              voiceSeconds: seconds,
            );
          } else {
            _appendLocalMineMessage(
              kind: ChatMessageKind.voice,
              voiceSeconds: seconds,
            );
            await _sendBackendMessage(kind: 'VOICE', voiceSeconds: seconds);
          }
        } catch (_) {
          _appendLocalMineMessage(
            kind: ChatMessageKind.voice,
            voiceSeconds: seconds,
          );
          await _sendBackendMessage(kind: 'VOICE', voiceSeconds: seconds);
        }
      } else {
        final msg = ChatMessage(
          id: 'v${DateTime.now().millisecondsSinceEpoch}',
          kind: ChatMessageKind.voice,
          voiceSeconds: seconds,
          mine: true,
          time: formatTimeNow(),
        );
        setState(() => _messages.add(msg));
        _afterAppend();
      }
      return;
    }

    final allowed = await _audioRecorder.hasPermission();
    if (!allowed) {
      if (mounted) {
        OklFeedback.alert(
          context,
          title: 'Micro requis',
          message: 'Autorise le micro pour enregistrer une note vocale.',
        );
      }
      return;
    }

    try {
      final outPath = kIsWeb
          ? 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a'
          : '${(await getTemporaryDirectory()).path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: outPath,
      );
    } catch (e) {
      if (mounted) {
        OklFeedback.snack(
          context,
          'Impossible de démarrer l’enregistrement: $e',
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRecording) return;
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _sendText() async {
    final txt = _messageController.text.trim();
    if (txt.isEmpty) return;
    final payload = _replyingTo == null
        ? txt
        : '↪ ${_messagePreview(_replyingTo!)}\n$txt';
    final replyingBackup = _replyingTo;
    setState(() => _replyingTo = null);
    if (isBackendThreadId(widget.thread.id)) {
      _emitTyping(false);
      _messageController.clear();
      _syncSendState();
      _appendLocalMineMessage(kind: ChatMessageKind.text, text: payload);
      final ok = await _sendBackendMessage(kind: 'TEXT', text: payload);
      if (!ok && mounted) {
        setState(() {
          _messages.removeWhere(
            (m) =>
                m.id.startsWith('local_') &&
                m.mine &&
                (m.text ?? '') == payload,
          );
          _replyingTo = replyingBackup;
        });
        _messageController.text = txt;
        _syncSendState();
      }
      return;
    }
    setState(() {
      _messages.add(
        ChatMessage(
          id: 't${DateTime.now().millisecondsSinceEpoch}',
          kind: ChatMessageKind.text,
          text: payload,
          mine: true,
          time: formatTimeNow(),
        ),
      );
      _messageController.clear();
    });
    _afterAppend();
  }

  void _openGalleryMediaChoice() {
    if (!isBackendThreadId(widget.thread.id)) {
      _pushDemoMessage(
        ChatMessage(
          id: 'img${DateTime.now().millisecondsSinceEpoch}',
          kind: ChatMessageKind.image,
          imageUrl:
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80&auto=format&fit=crop',
          mine: true,
          time: formatTimeNow(),
        ),
      );
      return;
    }
    _runMediaUpload(
      _openWhatsAppGalleryFlow,
      onError: 'Échec de l’envoi média',
    );
  }

  Future<void> _openWhatsAppGalleryFlow() async {
    final composed = await Navigator.of(context, rootNavigator: true)
        .push<OklComposedMedia>(
      MaterialPageRoute<OklComposedMedia>(
        builder: (_) => const GalleryPickerScreen(),
      ),
    );
    if (!mounted) return;
    if (composed == null) return;

    final upload = await ref.read(okliforApiClientProvider).uploadChatMedia(
          threadId: widget.thread.id,
          filename: composed.filename,
          fileBytes: kIsWeb ? Uint8List.fromList(composed.bytes ?? []) : (composed.bytes == null ? null : Uint8List.fromList(composed.bytes!)),
          filePath: kIsWeb ? null : composed.filePath,
        );
    final kind = upload.mediaKind.toUpperCase();
    final abs = _absoluteMediaUrl(upload.signedUrl);
    final caption = composed.caption.trim();

    if (kind == 'IMAGE') {
      _appendLocalMineMessage(
        kind: ChatMessageKind.image,
        imageUrl: abs,
        text: caption.isEmpty ? null : caption,
      );
      await _sendBackendMessage(
        kind: 'IMAGE',
        imageUrl: upload.signedUrl,
        text: caption.isEmpty ? null : caption,
      );
    } else if (kind == 'VIDEO') {
      _appendLocalMineMessage(
        kind: ChatMessageKind.video,
        videoUrl: abs,
        text: caption.isEmpty ? null : caption,
      );
      await _sendBackendMessage(
        kind: 'VIDEO',
        videoUrl: upload.signedUrl,
        text: caption.isEmpty ? null : caption,
      );
    } else {
      // Fallback: serveur a classé en FILE → on l’envoie comme document.
      final label = '📄 ${composed.filename}';
      _appendLocalMineMessage(
        kind: ChatMessageKind.file,
        text: label,
        fileUrl: abs,
      );
      await _sendBackendMessage(kind: 'FILE', text: label, fileUrl: upload.signedUrl);
    }
  }

  void _openAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _AttachTile(
                    icon: LucideIcons.fileText,
                    label: 'Document',
                    onTap: () {
                      Navigator.pop(ctx);
                      _runMediaUpload(
                        _pickAndSendDocumentFile,
                        onError: 'Échec de l’envoi document',
                      );
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.image,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(ctx);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _openGalleryMediaChoice();
                      });
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.camera,
                    label: 'Caméra',
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isBackendThreadId(widget.thread.id)) {
                        _runMediaUpload(
                          _pickAndSendVideoFromCamera,
                          onError: 'Échec de l’envoi vidéo',
                        );
                      } else {
                        _pushDemoMessage(
                          ChatMessage(
                            id: 'cam${DateTime.now().millisecondsSinceEpoch}',
                            kind: ChatMessageKind.video,
                            videoUrl:
                                'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
                            mine: true,
                            time: formatTimeNow(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _AttachTile(
                    icon: LucideIcons.mapPin,
                    label: 'Position',
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isBackendThreadId(widget.thread.id)) {
                        _appendLocalMineMessage(
                          kind: ChatMessageKind.location,
                          locationLabel: 'Boulevard du 13 janvier, Lomé',
                        );
                        _sendBackendMessage(
                          kind: 'LOCATION',
                          locationLabel: 'Boulevard du 13 janvier, Lomé',
                        );
                      } else {
                        _pushDemoMessage(
                          ChatMessage(
                            id: 'loc${DateTime.now().millisecondsSinceEpoch}',
                            kind: ChatMessageKind.location,
                            locationLabel: 'Boulevard du 13 janvier, Lomé',
                            mine: true,
                            time: formatTimeNow(),
                          ),
                        );
                      }
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.userPlus,
                    label: 'Contact',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context, rootNavigator: true).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ShareContactScreen(
                            onPick: (c) {
                              if (isBackendThreadId(widget.thread.id)) {
                                _sendSharedContact(c);
                              } else {
                                _pushDemoMessage(
                                  ChatMessage(
                                    id: 'vc${DateTime.now().millisecondsSinceEpoch}',
                                    kind: ChatMessageKind.text,
                                    text: '👤 Contact partagé : ${c.name}',
                                    mine: true,
                                    time: formatTimeNow(),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.music,
                    label: 'Audio',
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isBackendThreadId(widget.thread.id)) {
                        _runMediaUpload(
                          _pickAndSendAudioFile,
                          onError: 'Échec de l’envoi audio',
                        );
                      } else {
                        _pushDemoMessage(
                          ChatMessage(
                            id: 'aud${DateTime.now().millisecondsSinceEpoch}',
                            kind: ChatMessageKind.text,
                            text: '🎵 ma_piste_audio.m4a (démo)',
                            mine: true,
                            time: formatTimeNow(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pushDemoMessage(ChatMessage m) {
    setState(() => _messages.add(m));
    _afterAppend();
  }

  String _absoluteMediaUrl(String raw) {
    return OkliforMediaUrl.resolve(raw);
  }

  void _appendLocalMineMessage({
    required ChatMessageKind kind,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    int? voiceSeconds,
    String? fileUrl,
    String? locationLabel,
  }) {
    final msg = ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      text: text,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      voiceSeconds: voiceSeconds,
      fileUrl: fileUrl,
      locationLabel: locationLabel,
      mine: true,
      time: formatTimeNow(),
      createdAt: DateTime.now().toUtc(),
    );
    setState(() => _messages.add(msg));
    _afterAppend();
  }

  Future<void> _pickAndSendVideoFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.camera);
    if (picked == null) return;
    final bytes = kIsWeb ? await picked.readAsBytes() : null;
    final upload = await ref
        .read(okliforApiClientProvider)
        .uploadChatMedia(
          threadId: widget.thread.id,
          filename: picked.name,
          fileBytes: bytes,
          filePath: kIsWeb ? null : picked.path,
        );
    await _sendBackendMessage(
      kind: upload.mediaKind.toUpperCase(),
      videoUrl: upload.mediaKind.toUpperCase() == 'VIDEO'
          ? upload.signedUrl
          : null,
    );
    if (upload.mediaKind.toUpperCase() == 'VIDEO') {
      _appendLocalMineMessage(
        kind: ChatMessageKind.video,
        videoUrl: _absoluteMediaUrl(upload.signedUrl),
      );
    }
  }

  Future<void> _pickAndSendAudioFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'webm'],
      withData: kIsWeb,
    );
    final f = picked?.files.single;
    if (f == null) return;
    final upload = await ref
        .read(okliforApiClientProvider)
        .uploadChatMedia(
          threadId: widget.thread.id,
          filename: f.name,
          fileBytes: kIsWeb ? f.bytes : null,
          filePath: kIsWeb ? null : f.path,
        );
    final mediaKind = upload.mediaKind.toUpperCase();
    final absAudio = _absoluteMediaUrl(upload.signedUrl);
    // Persist sender-side (no re-download): copy from picked file.
    if (!kIsWeb && (f.path ?? '').isNotEmpty) {
      try {
        await persistOkliforLocalFileFromPath(
          upload.signedUrl,
          bucket: OklMediaBucket.audio,
          sourcePath: f.path!,
          displayName: f.name,
        );
      } catch (_) {}
    }
    if (mediaKind == 'VOICE' || mediaKind == 'AUDIO') {
      _appendLocalMineMessage(
        kind: ChatMessageKind.voice,
        audioUrl: absAudio,
      );
    }
    await _sendBackendMessage(
      kind: mediaKind,
      audioUrl: (mediaKind == 'VOICE' || mediaKind == 'AUDIO')
          ? absAudio
          : null,
    );
  }

  Future<void> _pickAndSendDocumentFile() async {
    final picked = await FilePicker.platform.pickFiles(withData: kIsWeb);
    final f = picked?.files.single;
    if (f == null) return;
    if (!isBackendThreadId(widget.thread.id)) {
      _pushDemoMessage(
        ChatMessage(
          id: 'doc${DateTime.now().millisecondsSinceEpoch}',
          kind: ChatMessageKind.file,
          text: '📄 ${f.name}',
          mine: true,
          time: formatTimeNow(),
        ),
      );
      return;
    }

    final composed = await Navigator.of(context, rootNavigator: true)
        .push<DocumentComposeResult>(
      MaterialPageRoute<DocumentComposeResult>(
        builder: (_) => DocumentComposeScreen(file: f),
      ),
    );
    if (!mounted || composed == null) return;

    try {
      final upload = await ref.read(okliforApiClientProvider).uploadChatMedia(
            threadId: widget.thread.id,
            filename: f.name,
            fileBytes: kIsWeb ? f.bytes : null,
            filePath: kIsWeb ? null : f.path,
          );
      final caption = composed.caption.trim();
      final label = caption.isEmpty ? '📄 ${f.name}' : '📄 ${f.name}\n$caption';
      final abs = _absoluteMediaUrl(upload.signedUrl);
      _appendLocalMineMessage(
        kind: ChatMessageKind.file,
        text: label,
        fileUrl: abs,
      );
      // Persist sender-side (no re-download): copy from picked file.
      if (!kIsWeb && (f.path ?? '').isNotEmpty) {
        try {
          await persistOkliforLocalFileFromPath(
            upload.signedUrl,
            bucket: OklMediaBucket.documents,
            sourcePath: f.path!,
            displayName: f.name,
          );
        } catch (_) {}
      }
      final ok = await _sendBackendMessage(
        kind: 'FILE',
        text: label,
        fileUrl: abs,
      );
      if (!ok && mounted) {
        setState(() {
          _messages.removeWhere(
            (m) =>
                m.id.startsWith('local_') &&
                m.mine &&
                m.kind == ChatMessageKind.file &&
                (m.text ?? '') == label,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        OklFeedback.snack(context, 'Envoi du document impossible');
      }
    }
  }

  Future<void> _sendSharedContact(ChatContact c) async {
    final text = '👤 Contact partagé : ${c.name}';
    _appendLocalMineMessage(kind: ChatMessageKind.text, text: text);
    final ok = await _sendBackendMessage(kind: 'TEXT', text: text);
    if (!ok && mounted) {
      setState(() {
        _messages.removeWhere(
          (m) => m.id.startsWith('local_') && m.mine && (m.text ?? '') == text,
        );
      });
    }
  }

  Future<void> _runMediaUpload(
    Future<void> Function() action, {
    required String onError,
  }) async {
    if (!mounted) return;
    setState(() {
      _isUploadingMedia = true;
      _uploadError = null;
      _retryUploadAction = action;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _uploadError = null;
        _retryUploadAction = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _uploadError = '$onError: $e';
      });
      OklFeedback.snack(context, _uploadError!);
    }
  }

  void _openThreadDetail() {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatThreadDetailScreen(thread: widget.thread),
      ),
    );
  }

  void _openImageViewer(ChatMessage message) {
    final url = message.imageUrl;
    if (url == null || url.isEmpty) return;
    final tag = 'chat_img_${message.id}';
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ChatImageViewerScreen(
          imageUrl: url,
          heroTag: tag,
          caption: (message.text ?? '').trim().isEmpty ? null : message.text,
        ),
      ),
    );
  }

  void _openConversationMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                LucideIcons.search,
                color:
                    Theme.of(ctx).textTheme.bodyMedium?.color ??
                    ctx.oklOnSurfaceMuted(0.62),
              ),
              title: Text(
                'Rechercher dans la conversation',
                style: TextStyle(color: ctx.oklOnSurface),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => ConversationSearchScreen(
                      threadName: widget.thread.name,
                      messages: List<ChatMessage>.from(_messages),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.image,
                color:
                    Theme.of(ctx).textTheme.bodyMedium?.color ??
                    ctx.oklOnSurfaceMuted(0.62),
              ),
              title: Text(
                'Médias, liens et docs',
                style: TextStyle(color: ctx.oklOnSurface),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => ConversationMediaScreen(
                      thread: widget.thread,
                      messages: List<ChatMessage>.from(_messages),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.bellOff,
                color:
                    Theme.of(ctx).textTheme.bodyMedium?.color ??
                    ctx.oklOnSurfaceMuted(0.62),
              ),
              title: Text(
                'Mettre en silencieux',
                style: TextStyle(color: ctx.oklOnSurface),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ConversationMuteScreen(threadName: widget.thread.name),
                  ),
                );
              },
            ),
            if (widget.thread.isGroup)
              ListTile(
                leading: Icon(
                  LucideIcons.userMinus,
                  color:
                      Theme.of(ctx).textTheme.bodyMedium?.color ??
                      ctx.oklOnSurfaceMuted(0.62),
                ),
                title: Text(
                  'Quitter le groupe',
                  style: TextStyle(color: ctx.oklOnSurface),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  OklFeedback.confirm(
                    context,
                    title: 'Quitter le groupe ?',
                    body:
                        'Tu ne recevras plus les messages de « ${widget.thread.name} ».',
                    confirmLabel: 'Quitter',
                    onConfirm: () {
                      OklFlows.pushResult(
                        context,
                        icon: LucideIcons.userMinus,
                        title: 'Tu as quitté le groupe',
                        subtitle:
                            'Tu ne recevras plus les messages de « ${widget.thread.name} ». Tu peux être réinvité·e plus tard.',
                        primaryLabel: 'Compris',
                      ).then((_) {
                        if (context.mounted) _popConversationRoot();
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread.isGroup
        ? widget.thread
        : widget.thread.copyWith(
            name: _resolvedPeerName ?? widget.thread.name,
            avatarUrl: _resolvedPeerAvatarUrl ?? widget.thread.avatarUrl,
          );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!context.mounted) return;
        _popConversationRoot();
      },
      child: Scaffold(
        backgroundColor: _waBg,
        appBar: AppBar(
          backgroundColor: _waAppBar,
          foregroundColor: _waTextPrimary,
          elevation: 0,
          leading: OklAppBarBackButton(onPressed: _popConversationRoot),
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openThreadDetail,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    if (!t.isGroup)
                      Hero(
                        tag: 'thread_avatar_${t.id}',
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: t.avatarUrl,
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            memCacheWidth: 80,
                            placeholder: (c, u) => Container(
                              width: 34,
                              height: 34,
                              color: context.oklSurface,
                            ),
                            errorWidget: (c, u, e) => Container(
                              width: 34,
                              height: 34,
                              color: context.oklSurface,
                              alignment: Alignment.center,
                              child: Icon(
                                LucideIcons.user,
                                size: 18,
                                color: context.oklOnSurfaceMuted(0.5),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: t.avatarUrl,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          memCacheWidth: 80,
                          placeholder: (c, u) => Container(
                            width: 34,
                            height: 34,
                            color: context.oklSurface,
                          ),
                          errorWidget: (c, u, e) => Container(
                            width: 34,
                            height: 34,
                            color: context.oklSurface,
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.user,
                              size: 18,
                              color: context.oklOnSurfaceMuted(0.5),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.name,
                            style: TextStyle(
                              color: _waTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _presenceSubtitle(t),
                            style: TextStyle(
                              color: t.isGroup
                                  ? _waTextSecondary
                                  : (_peerTyping
                                        ? const Color(0xFF25D366)
                                        : (_peerOnline
                                        ? const Color(0xFF25D366)
                                        : _waTextSecondary)),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: OklAppBarIconButton(
                icon: LucideIcons.phone,
                onPressed: () => OklFlows.pushOutgoingCall(
                  context,
                  contactName: t.name,
                  avatarUrl: t.isGroup ? null : t.avatarUrl,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OklAppBarIconButton(
                icon: LucideIcons.moreVertical,
                onPressed: _openConversationMenu,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    itemCount: _messages.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _waAppBar.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Aujourd’hui',
                                style: TextStyle(
                                  color: _waTextSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      final msg = _messages[i - 1];
                      return KeyedSubtree(
                        key: ValueKey('msg_${msg.id}'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onLongPress: () => _openMessageActions(msg),
                            child: _RichMessageBubble(
                              message: msg,
                              peerDisplayName: widget.thread.name,
                              peerAvatarUrl: widget.thread.avatarUrl,
                              reactionEmoji: _messageReactions[msg.id],
                              onTapImage: msg.kind == ChatMessageKind.image
                                  ? () => _openImageViewer(msg)
                                  : null,
                              onMessageMenu: _openMessageActions,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_replyingTo != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: context.oklSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.oklDivider),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Réponse à: ${_messagePreview(_replyingTo!)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.oklOnSurfaceMuted(0.72),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _replyingTo = null),
                                    icon: const Icon(LucideIcons.x, size: 16),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_isUploadingMedia)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(999),
                              color: AppColors.primary,
                            ),
                          ),
                        if (_uploadError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: context.oklSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.oklDivider),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _uploadError!,
                                      style: TextStyle(
                                        color: context.oklOnSurfaceMuted(0.72),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _retryUploadAction == null
                                        ? null
                                        : () => _runMediaUpload(
                                            _retryUploadAction!,
                                            onError:
                                                'Nouvelle tentative échouée',
                                          ),
                                    child: const Text('Réessayer'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _waInput,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    readOnly: _isRecording || _isUploadingMedia,
                                    style: TextStyle(
                                      color: _waTextPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _isRecording
                                          ? 'Enregistrement… ${_formatDuration(_recordingSeconds)}'
                                          : 'Message…',
                                      hintStyle: TextStyle(
                                        color: _waTextSecondary,
                                      ),
                                      isDense: true,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      border: InputBorder.none,
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: GestureDetector(
                                          onTap: () {
                                            final common = [
                                              '😊',
                                              '😂',
                                              '❤️',
                                              '🔥',
                                              '🙏',
                                            ];
                                            showModalBottomSheet<void>(
                                              context: context,
                                              backgroundColor: context.oklSurface,
                                              shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.vertical(
                                                  top: Radius.circular(18),
                                                ),
                                              ),
                                              builder: (sheetContext) => SafeArea(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(14),
                                                  child: Wrap(
                                                    spacing: 10,
                                                    runSpacing: 10,
                                                    children: common
                                                        .map(
                                                          (emoji) => InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            onTap: () {
                                                              Navigator.pop(
                                                                sheetContext,
                                                              );
                                                              final cur =
                                                                  _messageController
                                                                      .text;
                                                              final next = cur.isEmpty
                                                                  ? emoji
                                                                  : '$cur $emoji';
                                                              _messageController.text =
                                                                  next;
                                                              _messageController
                                                                      .selection =
                                                                  TextSelection.collapsed(
                                                                offset: next.length,
                                                              );
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        14,
                                                                    vertical: 8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: context
                                                                    .oklScaffold,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                  999,
                                                                ),
                                                                border: Border.all(
                                                                  color: context
                                                                      .oklDivider,
                                                                ),
                                                              ),
                                                              child: Text(
                                                                emoji,
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize: 22,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(growable: false),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Icon(
                                            LucideIcons.smile,
                                            size: 18,
                                            color:
                                                _waTextSecondary,
                                          ),
                                        ),
                                      ),
                                      suffixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: _isUploadingMedia
                                                  ? null
                                                  : _openAttachmentOptions,
                                              child: Icon(
                                                LucideIcons.paperclip,
                                                size: 18,
                                                color: _waTextSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            GestureDetector(
                                              onTap: _isUploadingMedia
                                                  ? null
                                                  : _openGalleryMediaChoice,
                                              child: Icon(
                                                LucideIcons.camera,
                                                size: 18,
                                                color: _waTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                    ),
                                    onSubmitted: (_) => _sendText(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _canSend
                                    ? AppColors.primary
                                    : _isRecording
                                    ? AppColors.togoRed
                                    : _waInput,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _isUploadingMedia
                                    ? null
                                    : () {
                                        if (_canSend) {
                                          _sendText();
                                          return;
                                        }
                                        _toggleRecording();
                                      },
                                icon: Icon(
                                  _canSend ? LucideIcons.send : LucideIcons.mic,
                                  color: _canSend || _isRecording
                                      ? Colors.white
                                      : (Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color ??
                                            context.oklOnSurfaceMuted(0.62)),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_loadingRemote)
              Positioned.fill(
                child: Material(
                  color: context.oklScaffold.withValues(alpha: 0.72),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _forwardMessage(ChatMessage m) async {
    final c = await Navigator.of(context, rootNavigator: true)
        .push<ChatContact>(
          MaterialPageRoute<ChatContact>(
            builder: (_) => const NewMessageScreen(),
          ),
        );
    if (!mounted || c == null) return;
    try {
      final api = ref.read(okliforApiClientProvider);
      final thread = await api.createDirectThread(c.id);
      await api.sendChatMessage(
        threadId: thread.id,
        kind: 'TEXT',
        text: _messagePreview(m),
      );
      if (!mounted) return;
      OklFeedback.snack(context, 'Message transféré à ${c.name}');
    } catch (_) {
      if (!mounted) return;
      OklFeedback.snack(context, 'Transfert impossible');
    }
  }

  void _openMessageActions(ChatMessage m) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: ['❤️', '😂', '🔥', '👍', '😮']
                      .map(
                        (emoji) => InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              if (_messageReactions[m.id] == emoji) {
                                _messageReactions.remove(m.id);
                              } else {
                                _messageReactions[m.id] = emoji;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.oklScaffold,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: context.oklDivider),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
            if (m.kind == ChatMessageKind.image &&
                (m.imageUrl ?? '').trim().isNotEmpty)
              ListTile(
                leading: const Icon(LucideIcons.download),
                title: const Text('Enregistrer la photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(
                    saveChatMediaToGallery(
                      context,
                      m.imageUrl!,
                      isVideo: false,
                      displayName: 'photo_${m.id}',
                    ),
                  );
                },
              ),
            if (m.kind == ChatMessageKind.video &&
                (m.videoUrl ?? '').trim().isNotEmpty)
              ListTile(
                leading: const Icon(LucideIcons.download),
                title: const Text('Enregistrer la vidéo'),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(
                    saveChatMediaToGallery(
                      context,
                      m.videoUrl!,
                      isVideo: true,
                      displayName: 'video_${m.id}',
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(LucideIcons.reply),
              title: const Text('Répondre'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = m);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.forward),
              title: const Text('Transférer'),
              onTap: () {
                Navigator.pop(ctx);
                _forwardMessage(m);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2),
              title: const Text('Effacer'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _messages.removeWhere((x) => x.id == m.id));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadReceiptTicks extends StatelessWidget {
  final ChatMessage message;
  final bool forDarkBackground;

  const _ReadReceiptTicks({
    required this.message,
    this.forDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!message.mine) return const SizedBox.shrink();
    final read = message.readByRecipient
        ? (forDarkBackground
            ? const Color(0xFF7DD3FC)
            : AppColors.primary.withValues(alpha: 0.85))
        : (forDarkBackground
            ? Colors.white54
            : context.oklOnSurfaceMuted(0.45));
    return Icon(
      message.readByRecipient ? LucideIcons.checkCheck : LucideIcons.check,
      size: 12,
      color: read,
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes o';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} Ko';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} Mo';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(gb < 10 ? 1 : 0)} Go';
}

String _cleanDocumentLabel(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return 'Document';
  final noIcon = s.replaceFirst(RegExp(r'^📄\s*'), '').trim();
  final firstLine = noIcon.split('\n').first.trim();
  return firstLine.isEmpty ? 'Document' : firstLine;
}

String _documentCaption(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return '';
  final noIcon = s.replaceFirst(RegExp(r'^📄\s*'), '').trim();
  final parts = noIcon.split('\n');
  if (parts.length <= 1) return '';
  return parts.sublist(1).join('\n').trim();
}

String _fileExt(String name) {
  final idx = name.lastIndexOf('.');
  if (idx < 0 || idx == name.length - 1) return '';
  return name.substring(idx + 1).toLowerCase();
}

String _mimeFromFileName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
  if (lower.endsWith('.pptx')) {
    return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
  }
  if (lower.endsWith('.txt')) return 'text/plain';
  if (lower.endsWith('.zip')) return 'application/zip';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.m4a')) return 'audio/mp4';
  return 'application/octet-stream';
}

class _DocumentMessageCard extends StatefulWidget {
  final ChatMessage message;
  const _DocumentMessageCard({required this.message});

  @override
  State<_DocumentMessageCard> createState() => _DocumentMessageCardState();
}

class _DocumentMessageCardState extends State<_DocumentMessageCard> {
  Stream<FileResponse>? _downloadStream;
  bool _downloading = false;
  double? _progress;
  int? _totalBytes;

  String get _rawUrl => (widget.message.fileUrl ?? '').trim();
  String get _resolvedUrl => OkliforMediaUrl.resolve(_rawUrl);
  bool get _openable => _rawUrl.isNotEmpty;

  Future<bool> _persisted() async {
    if (!_openable || kIsWeb) return false;
    final title = _cleanDocumentLabel(widget.message.text);
    final f = await getOkliforLocalFileIfExists(
      _rawUrl,
      bucket: OklMediaBucket.documents,
      displayName: title,
    );
    return f != null;
  }

  Future<void> _openCachedOrDownload() async {
    if (!_openable || kIsWeb) {
      if (mounted) {
        OklFeedback.snack(context, 'Fichier indisponible');
      }
      return;
    }
    final title = _cleanDocumentLabel(widget.message.text);
    try {
      final local = await ensureOkliforLocalFile(
        _rawUrl,
        bucket: OklMediaBucket.documents,
        displayName: title,
      );
      await OpenFilex.open(local.path, type: _mimeFromFileName(title));
    } catch (_) {
      _startDownload(openAfter: true);
    }
  }

  Future<void> _saveToDownloads() async {
    if (!_openable) return;
    await saveChatFileToDownloads(
      context,
      _rawUrl,
      displayName: widget.message.text,
    );
  }

  void _startDownload({required bool openAfter}) {
    if (!_openable || kIsWeb) return;
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _progress = null;
      _totalBytes = null;
      _downloadStream = _chatMediaCache.getFileStream(
        _resolvedUrl,
        withProgress: true,
      );
    });
    _downloadStream!.listen(
      (event) async {
        if (!mounted) return;
        if (event is DownloadProgress) {
          final total = event.totalSize;
          final downloaded = event.downloaded;
          setState(() {
            _totalBytes = total;
            _progress = total != null && total > 0 ? downloaded / total : null;
          });
        } else if (event is FileInfo) {
          setState(() {
            _downloading = false;
            _progress = 1;
          });
          // Persist after first download so it survives app restarts,
          // then rebuild so the "Télécharger" button disappears.
          try {
            await ensureOkliforLocalFile(
              _rawUrl,
              bucket: OklMediaBucket.documents,
              displayName: _cleanDocumentLabel(widget.message.text),
            );
            if (mounted) setState(() {});
          } catch (_) {}
          if (openAfter) {
            final title = _cleanDocumentLabel(widget.message.text);
            await OpenFilex.open(event.file.path, type: _mimeFromFileName(title));
          } else {
            if (mounted) {
              OklFeedback.snack(context, 'Téléchargement terminé');
            }
          }
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _downloading = false;
          _downloadStream = null;
          _progress = null;
          _totalBytes = null;
        });
        OklFeedback.snack(context, 'Téléchargement impossible');
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final title = _cleanDocumentLabel(m.text);
    final caption = _documentCaption(m.text);
    final ext = _fileExt(title);
    final extLabel = (ext.isEmpty ? 'FILE' : ext.toUpperCase());

    final bg = m.mine ? const Color(0xFF005C4B) : _waIncomingBubble;
    final border = Border.all(color: Colors.white.withValues(alpha: 0.06));

    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openable ? () => unawaited(_openCachedOrDownload()) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: border,
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          extLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<bool>(
                                future: _persisted(),
                                builder: (ctx, snap) {
                                  final persisted = snap.data == true;
                                  final size = persisted
                                      ? 'Téléchargé'
                                      : (_totalBytes != null
                                          ? _formatBytes(_totalBytes!)
                                          : null);
                                  final subtitle = size == null
                                      ? 'Document'
                                      : 'Document • $size';
                                  return Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.68),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<bool>(
                        future: _persisted(),
                        builder: (ctx, snap) {
                          final persisted = snap.data == true;
                          if (!_openable || kIsWeb) {
                            return _DocActionIcon(
                              icon: LucideIcons.alertCircle,
                              onTap: null,
                              tooltip: 'Indisponible',
                            );
                          }
                          if (_downloading) {
                            return _DocProgressRing(value: _progress);
                          }
                          if (persisted) {
                            return SizedBox(
                              height: 34,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    unawaited(_openCachedOrDownload()),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  foregroundColor:
                                      Colors.white.withValues(alpha: 0.92),
                                ),
                                icon: const Icon(
                                  LucideIcons.externalLink,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Ouvrir',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }
                          return _DocActionIcon(
                            icon: LucideIcons.download,
                            tooltip: 'Télécharger',
                            onTap: () => _startDownload(openAfter: false),
                          );
                        },
                      ),
                      FutureBuilder<bool>(
                        future: _persisted(),
                        builder: (ctx, snap) {
                          final persisted = snap.data == true;
                          if (!_openable || kIsWeb) return const SizedBox.shrink();
                          if (persisted) return const SizedBox.shrink();
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 6),
                              _DocActionIcon(
                                icon: LucideIcons.save,
                                tooltip: 'Enregistrer',
                                onTap: () => unawaited(_saveToDownloads()),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  if (caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        caption,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.90),
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (m.mine) ...[
                        _ReadReceiptTicks(message: m, forDarkBackground: true),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        m.time,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  const _DocActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: Colors.white.withValues(alpha: onTap == null ? 0.45 : 0.88),
          ),
        ),
      ),
    );
  }
}

class _DocProgressRing extends StatelessWidget {
  final double? value;
  const _DocProgressRing({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.88),
            ),
          ),
          Icon(
            LucideIcons.arrowDownToLine,
            size: 16,
            color: Colors.white.withValues(alpha: 0.82),
          ),
        ],
      ),
    );
  }
}

class _RichMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String peerDisplayName;
  final String peerAvatarUrl;
  final String? reactionEmoji;
  final VoidCallback? onTapImage;
  final void Function(ChatMessage m)? onMessageMenu;

  const _RichMessageBubble({
    required this.message,
    required this.peerDisplayName,
    required this.peerAvatarUrl,
    this.reactionEmoji,
    this.onTapImage,
    this.onMessageMenu,
  });

  @override
  Widget build(BuildContext context) {
    final m = message;
    switch (m.kind) {
      case ChatMessageKind.system:
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.oklSurface.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m.text ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    (Theme.of(context).textTheme.bodyMedium?.color ??
                            context.oklOnSurfaceMuted(0.62))
                        .withValues(alpha: 0.95),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        );
      case ChatMessageKind.image:
        final heroTag = 'chat_img_${m.id}';
        final imageUrl = (m.imageUrl ?? '').trim();
        if (imageUrl.isEmpty) {
          return Align(
            alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 230,
              height: 300,
              decoration: BoxDecoration(
                color: m.mine ? _waOutgoingBubble : _waIncomingBubble,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.oklDivider),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.imageOff,
                    size: 28,
                    color: context.oklOnSurfaceMuted(0.45),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Image indisponible',
                    style: TextStyle(
                      color: context.oklOnSurfaceMuted(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        Widget imageErrorBox() {
          return Container(
            width: 230,
            height: 300,
            decoration: BoxDecoration(
              color: m.mine ? _waOutgoingBubble : _waIncomingBubble,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.oklDivider),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.imageOff,
                  size: 28,
                  color: context.oklOnSurfaceMuted(0.45),
                ),
                const SizedBox(height: 6),
                Text(
                  'Image introuvable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }

        final img = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            cacheManager: _chatMediaCache,
            width: 230,
            height: 300,
            fit: BoxFit.cover,
            memCacheWidth: 520,
            placeholder: (c, u) =>
                Container(width: 230, height: 300, color: _waIncomingBubble),
            errorWidget: (c, u, e) => imageErrorBox(),
          ),
        );
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: m.mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTapImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Hero(tag: heroTag, child: img),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              m.time,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (m.mine) ...[
                              const SizedBox(width: 4),
                              _ReadReceiptTicks(
                                message: m,
                                forDarkBackground: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if ((m.text ?? '').trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: m.mine ? _waOutgoingBubble : _waIncomingBubble,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Text(
                    (m.text ?? '').trim(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (reactionEmoji != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _waIncomingBubble,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      reactionEmoji!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        );
      case ChatMessageKind.video:
        return _VideoMessageBubble(
          message: m,
          peerDisplayName: peerDisplayName,
          peerAvatarUrl: peerAvatarUrl,
          reactionEmoji: reactionEmoji,
        );
      case ChatMessageKind.voice:
        return _WhatsAppStyleVoiceBubble(
          message: m,
          onMessageMenu: onMessageMenu,
        );
      case ChatMessageKind.location:
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: m.mine
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : context.oklSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.oklDivider),
            ),
            child: Column(
              crossAxisAlignment:
                  m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.locationLabel ?? 'Position',
                        style: TextStyle(
                          color: context.oklOnSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 88,
                    color: context.oklScaffold,
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.map,
                      color: context.oklOnSurfaceMuted(0.55),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m.mine) ...[
                      _ReadReceiptTicks(message: m),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      m.time,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.55),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case ChatMessageKind.file:
        return _DocumentMessageCard(message: m);
      case ChatMessageKind.text:
        final bg = m.mine ? _waOutgoingBubble : _waIncomingBubble;
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: m.mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!m.mine)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: peerAvatarUrl,
                          width: 18,
                          height: 18,
                          fit: BoxFit.cover,
                          memCacheWidth: 36,
                          errorWidget: (c, u, e) => Container(
                            width: 18,
                            height: 18,
                            color: context.oklSurface,
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.user,
                              size: 10,
                              color: context.oklOnSurfaceMuted(0.55),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        peerDisplayName,
                        style: TextStyle(
                          color: context.oklOnSurfaceMuted(0.66),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.oklDivider),
                ),
                child: Column(
                  crossAxisAlignment: m.mine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.text ?? '',
                      style: const TextStyle(color: _waTextPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.time,
                          style: TextStyle(
                            color: _waTextSecondary,
                            fontSize: 10,
                          ),
                        ),
                        if (m.mine) ...[
                          const SizedBox(width: 4),
                          _ReadReceiptTicks(message: m),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (reactionEmoji != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.oklSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: context.oklDivider),
                    ),
                    child: Text(
                      reactionEmoji!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        );
    }
  }
}

class _VideoMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String peerDisplayName;
  final String peerAvatarUrl;
  final String? reactionEmoji;
  const _VideoMessageBubble({
    required this.message,
    required this.peerDisplayName,
    required this.peerAvatarUrl,
    this.reactionEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final m = message;
    final videoUrl = m.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      return Align(
        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          'Vidéo indisponible',
          style: TextStyle(color: context.oklOnSurfaceMuted(0.6)),
        ),
      );
    }
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: m.mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!m.mine)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: peerAvatarUrl,
                      width: 18,
                      height: 18,
                      fit: BoxFit.cover,
                      memCacheWidth: 36,
                      errorWidget: (c, u, e) => Container(
                        width: 18,
                        height: 18,
                        color: context.oklSurface,
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.user,
                          size: 10,
                          color: context.oklOnSurfaceMuted(0.55),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    peerDisplayName,
                    style: TextStyle(
                      color: context.oklOnSurfaceMuted(0.66),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.66,
            ),
            decoration: BoxDecoration(
              color: m.mine ? _waOutgoingBubble : _waIncomingBubble,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.oklDivider),
            ),
            padding: const EdgeInsets.all(0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => _VideoPlayerScreen(
                      url: videoUrl,
                      caption: (m.text ?? '').trim().isEmpty ? null : m.text,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.black),
                      Container(color: Colors.black.withValues(alpha: 0.22)),
                      const Align(
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.playCircle,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'VIDÉO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m.time,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (m.mine) ...[
                                const SizedBox(width: 4),
                                _ReadReceiptTicks(
                                  message: m,
                                  forDarkBackground: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if ((m.text ?? '').trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: m.mine ? _waOutgoingBubble : _waIncomingBubble,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                (m.text ?? '').trim(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (reactionEmoji != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.oklSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.oklDivider),
                ),
                child: Text(
                  reactionEmoji!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bulle vocale style WhatsApp : avatar + micro, lecture, forme d’onde cliquable, durée, reçus.
class _WhatsAppStyleVoiceBubble extends StatefulWidget {
  final ChatMessage message;
  final void Function(ChatMessage m)? onMessageMenu;

  const _WhatsAppStyleVoiceBubble({
    required this.message,
    this.onMessageMenu,
  });

  @override
  State<_WhatsAppStyleVoiceBubble> createState() =>
      _WhatsAppStyleVoiceBubbleState();
}

class _GlobalVoicePlayback {
  _GlobalVoicePlayback._();

  static final _GlobalVoicePlayback instance = _GlobalVoicePlayback._();

  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<String?> activeMessageId = ValueNotifier<String?>(null);
}

class _WhatsAppStyleVoiceBubbleState extends State<_WhatsAppStyleVoiceBubble> {
  AudioPlayer get _player => _GlobalVoicePlayback.instance.player;
  bool _ready = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  String? _loadError;
  int _setupGeneration = 0;
  bool _preparing = false;
  bool _isActive = false;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  ChatMessage get m => widget.message;

  @override
  void initState() {
    super.initState();
    _GlobalVoicePlayback.instance.activeMessageId.addListener(_onActiveChanged);
    _onActiveChanged();
    // IMPORTANT (téléphone réel):
    // ne pas précharger automatiquement tous les vocaux visibles dans la liste,
    // sinon MediaCodec/ExoPlayer fait des init/release en cascade -> "Loading interrupted".
  }

  void _onActiveChanged() {
    final active = _GlobalVoicePlayback.instance.activeMessageId.value == m.id;
    if (active == _isActive) return;
    _isActive = active;
    if (_isActive) {
      _attachStreams();
    } else {
      _detachStreams();
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
          _duration = Duration.zero;
          _ready = false;
          _loadError = null;
        });
      }
    }
  }

  void _attachStreams() {
    _detachStreams();
    _posSub = _player.positionStream.listen((p) {
      if (!mounted) return;
      if (!_isActive) return;
      setState(() => _position = p);
    });
    _durSub = _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
      if (!_isActive) return;
      setState(() => _duration = d);
    });
    _stateSub = _player.playerStateStream.listen((s) {
      if (!mounted) return;
      if (!_isActive) return;
      setState(() => _playing = s.playing);
    });
  }

  void _detachStreams() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _posSub = null;
    _durSub = null;
    _stateSub = null;
  }

  Future<void> _setup() async {
    if (_preparing) return;
    _preparing = true;
    final gen = ++_setupGeneration;
    final raw = m.audioUrl?.trim() ?? '';
    if (raw.isEmpty) {
      if (!mounted || gen != _setupGeneration) return;
      setState(() {
        _ready = false;
        _loadError = 'audio_manquant';
      });
      _preparing = false;
      return;
    }
    final url = OkliforMediaUrl.resolve(raw);
    try {
      await _bindAudioFromUrl(url);
      // Appliquer vitesse courante sur ce player global.
      await _player.setSpeed(_speed);
      if (!mounted || gen != _setupGeneration) return;
      setState(() {
        _ready = true;
        _loadError = null;
        _duration = _player.duration ?? Duration.zero;
      });
    } catch (e) {
      if (!mounted || gen != _setupGeneration) return;
      setState(() {
        _ready = false;
        _loadError = e.toString();
      });
    } finally {
      _preparing = false;
    }
  }

  /// Stable key for the same media file even if signature changes.
  /// We compare only the path part of the signed URL.
  static String _audioKey(String resolvedUrl) {
    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) return resolvedUrl;
    return uri.path; // ignores query (exp/sig)
  }

  /// Hors Web : télécharger d’abord via le cache (même pile HTTP que les images) —
  /// souvent plus fiable sur téléphone réel que le stream ExoPlayer seul.
  Future<void> _bindAudioFromUrl(String url) async {
    final uri = Uri.parse(url);
    await _player.stop();
    if (uri.scheme == 'file') {
      await _player.setAudioSource(AudioSource.uri(uri));
      return;
    }
    if (kIsWeb) {
      await _player.setAudioSource(AudioSource.uri(uri));
      return;
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      Object? lastError;
      try {
        // 1) Prefer persisted local file (Android/media/.../Oklifor/...) if present.
        final persisted = await getOkliforLocalFileIfExists(
          url,
          bucket: OklMediaBucket.voiceNotes,
          displayName: 'voice_${m.id}.m4a',
        );
        if (persisted != null) {
          await _player.setAudioSource(AudioSource.file(persisted.path));
          return;
        }

        // 2) Otherwise, try streaming source first (supports range), then fallback to full download.
        await _player.setAudioSource(LockCachingAudioSource(uri));
        // Persist asynchronously for next time (reuses cache afterwards anyway).
        unawaited(
          ensureOkliforLocalFile(
            url,
            bucket: OklMediaBucket.voiceNotes,
            displayName: 'voice_${m.id}.m4a',
          ),
        );
        return;
      } catch (e) {
        lastError = e;
      }
      try {
        final cached = await _chatMediaCache.getSingleFile(url);
        final len = await cached.length();
        if (len < 1024) {
          throw Exception('fichier_audio_trop_petit($len)');
        }
        await _player.setAudioSource(AudioSource.file(cached.path));
        unawaited(
          persistOkliforLocalFileFromPath(
            url,
            bucket: OklMediaBucket.voiceNotes,
            sourcePath: cached.path,
            displayName: 'voice_${m.id}.m4a',
          ),
        );
        return;
      } catch (e) {
        lastError = e;
      }
      try {
        await _player.setAudioSource(AudioSource.uri(uri));
        return;
      } catch (e) {
        lastError = e;
      }
      throw Exception(lastError.toString());
    }
    await _player.setAudioSource(AudioSource.uri(uri));
  }

  @override
  void didUpdateWidget(covariant _WhatsAppStyleVoiceBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prevRaw = oldWidget.message.audioUrl?.trim() ?? '';
    final nextRaw = widget.message.audioUrl?.trim() ?? '';
    if (prevRaw == nextRaw) return;

    final prevKey = prevRaw.isEmpty ? '' : _audioKey(OkliforMediaUrl.resolve(prevRaw));
    final nextKey = nextRaw.isEmpty ? '' : _audioKey(OkliforMediaUrl.resolve(nextRaw));

    // If it's the same file (only exp/sig changed), do NOT interrupt playback/loading.
    // But if we previously failed to load, retry with the fresh signed URL.
    final sameFile = prevKey.isNotEmpty && prevKey == nextKey;
    if (sameFile && _ready) return;

    // Do not auto-reload in background; only refresh when user tries to play again.
    setState(() {
      _ready = false;
      _loadError = null;
      _duration = Duration.zero;
      _position = Duration.zero;
    });
  }

  @override
  void dispose() {
    _GlobalVoicePlayback.instance.activeMessageId.removeListener(_onActiveChanged);
    _detachStreams();
    super.dispose();
  }

  static String _fmtDur(Duration d) {
    final s = d.inSeconds;
    final mm = s ~/ 60;
    final ss = s % 60;
    return '$mm:${ss.toString().padLeft(2, '0')}';
  }

  void _seekFromLocalX(double localX, double width) {
    if (width <= 0) return;
    final total = _duration.inMilliseconds;
    if (total <= 0) return;
    final f = (localX / width).clamp(0.0, 1.0);
    unawaited(
      _player.seek(Duration(milliseconds: (f * total).round())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mine = m.mine;
    final bubble = mine ? const Color(0xFF1B3B32) : context.oklSurface;
    final border = mine ? Colors.transparent : context.oklDivider;
    final onBubble = mine ? Colors.white70 : context.oklOnSurfaceMuted(0.72);
    final waveInactive = mine
        ? const Color(0xFF4A8A7A).withValues(alpha: 0.55)
        : context.oklOnSurfaceMuted(0.28);
    final waveActive = mine
        ? const Color(0xFF9FE6D4)
        : AppColors.primary.withValues(alpha: 0.75);
    final playhead = mine
        ? const Color(0xFF7DD3FC)
        : AppColors.primary;

    final totalMs = _duration.inMilliseconds;
    final fallbackSec = m.voiceSeconds ?? 0;
    final effectiveDur = totalMs > 0
        ? _duration
        : Duration(seconds: fallbackSec > 0 ? fallbackSec : 1);
    final posMs = _position.inMilliseconds.clamp(
      0,
      effectiveDur.inMilliseconds <= 0 ? 1 : effectiveDur.inMilliseconds,
    );
    final progress = effectiveDur.inMilliseconds <= 0
        ? 0.0
        : posMs / effectiveDur.inMilliseconds;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Material(
          color: bubble,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (widget.onMessageMenu != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onMessageMenu!(m),
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              LucideIcons.chevronDown,
                              size: 16,
                              color: mine ? Colors.white54 : onBubble,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: CircleAvatar(
                                  backgroundColor: mine
                                      ? const Color(0xFF0F2433)
                                      : context.oklScaffold,
                                  child: Icon(
                                    LucideIcons.user,
                                    size: 22,
                                    color: mine
                                        ? const Color(0xFF7DD3FC)
                                        : context.oklOnSurfaceMuted(0.55),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: mine
                                        ? const Color(0xFF3DDC97)
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: bubble,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    LucideIcons.mic,
                                    size: 9,
                                    color: mine ? const Color(0xFF0A2A22) : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    onPressed: () async {
                                      if (_preparing) return;
                                      // Make this bubble the active one (stops previous).
                                      final global = _GlobalVoicePlayback.instance;
                                      if (global.activeMessageId.value != m.id) {
                                        try {
                                          await _player.stop();
                                        } catch (_) {}
                                        global.activeMessageId.value = m.id;
                                      }
                                      if (!_ready) {
                                        await _setup();
                                      }
                                      if (!_ready) return;
                                      if (_playing) {
                                        await _player.pause();
                                      } else {
                                        await _player.play();
                                      }
                                    },
                                    icon: Icon(
                                      _playing
                                          ? LucideIcons.pause
                                          : LucideIcons.play,
                                      size: 22,
                                      color: onBubble,
                                    ),
                                  ),
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, cons) {
                                        final w = cons.maxWidth;
                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTapDown: (d) =>
                                              _seekFromLocalX(d.localPosition.dx, w),
                                          onHorizontalDragUpdate: (d) =>
                                              _seekFromLocalX(d.localPosition.dx, w),
                                          child: SizedBox(
                                            height: 30,
                                            child: CustomPaint(
                                              painter: _WhatsAppVoiceWaveformPainter(
                                                progress: progress,
                                                inactiveColor: waveInactive,
                                                activeColor: waveActive,
                                                playheadColor: playhead,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final next = _speed == 1.0
                                          ? 1.5
                                          : (_speed == 1.5 ? 2.0 : 1.0);
                                      await _player.setSpeed(next);
                                      if (mounted) setState(() => _speed = next);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        '${_speed}x',
                                        style: TextStyle(
                                          color: onBubble,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _ready && totalMs > 0
                                        ? _fmtDur(effectiveDur)
                                        : (fallbackSec > 0
                                            ? _fmtDur(
                                                Duration(seconds: fallbackSec),
                                              )
                                            : (_ready ? _fmtDur(_position) : '—')),
                                    style: TextStyle(
                                      color: onBubble,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (mine) ...[
                                    _ReadReceiptTicks(
                                      message: m,
                                      forDarkBackground: true,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    m.time,
                                    style: TextStyle(
                                      color: mine
                                          ? Colors.white54
                                          : context.oklOnSurfaceMuted(0.55),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_ready && _loadError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Lecture impossible: ${_loadError!.toString().split('\n').first}',
                                    style: TextStyle(
                                      color: mine
                                          ? Colors.redAccent.shade100
                                          : Theme.of(context).colorScheme.error,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _WhatsAppVoiceWaveformPainter extends CustomPainter {
  final double progress;
  final Color inactiveColor;
  final Color activeColor;
  final Color playheadColor;

  _WhatsAppVoiceWaveformPainter({
    required this.progress,
    required this.inactiveColor,
    required this.activeColor,
    required this.playheadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 36;
    const gap = 1.2;
    final barW = (size.width - (barCount - 1) * gap) / barCount;
    final inactive = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;
    final active = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    for (var i = 0; i < barCount; i++) {
      final x = i * (barW + gap);
      final t = barCount <= 1 ? 0.0 : i / (barCount - 1);
      final h = (0.22 + (i % 7) * 0.11) * size.height;
      final y = (size.height - h) / 2;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, h),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(r, t <= progress ? active : inactive);
    }
    final px = (size.width * progress).clamp(4.0, size.width - 4.0);
    canvas.drawCircle(
      Offset(px, size.height / 2),
      4.2,
      Paint()..color = playheadColor,
    );
    canvas.drawCircle(
      Offset(px, size.height / 2),
      2.4,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _WhatsAppVoiceWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.playheadColor != playheadColor;
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String? caption;
  const _VideoPlayerScreen({required this.url, this.caption});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _ready = false;
  Duration _position = Duration.zero;
  bool _controlsVisible = true;
  bool _muted = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) return;
    final c = kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(widget.url))
        : VideoPlayerController.file(
            await ensureOkliforLocalFile(
              widget.url,
              bucket: OklMediaBucket.video,
              displayName: (widget.caption ?? '').trim(),
            ),
          );
    await c.initialize();
    await c.setLooping(true);
    c.addListener(() {
      if (!mounted) return;
      setState(() => _position = c.value.position);
    });
    setState(() {
      _controller = c;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final caption = (widget.caption ?? '').trim();
    final hasCaption = caption.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      body: _ready && c != null
          ? GestureDetector(
              onTap: () => setState(() => _controlsVisible = !_controlsVisible),
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio:
                          c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
                      child: VideoPlayer(c),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _controlsVisible ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.only(
                              top: MediaQuery.paddingOf(context).top,
                              left: 8,
                              right: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.65),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                OklAppBarIconButton(
                                  icon: LucideIcons.arrowLeft,
                                  onPressed: () => Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Partager',
                                  onPressed: () => shareChatAttachmentUrl(
                                    context,
                                    widget.url,
                                    displayName:
                                        caption.isEmpty ? 'video.mp4' : caption,
                                  ),
                                  icon: const Icon(
                                    LucideIcons.share2,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Enregistrer',
                                  onPressed: () => saveChatFileToDownloads(
                                    context,
                                    widget.url,
                                    displayName: caption,
                                  ),
                                  icon: const Icon(
                                    LucideIcons.save,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Galerie',
                                  onPressed: () => saveChatMediaToGallery(
                                    context,
                                    widget.url,
                                    displayName: caption,
                                    isVideo: true,
                                  ),
                                  icon: const Icon(
                                    LucideIcons.video,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.75),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Slider(
                                  value: _position.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                        0,
                                        (c.value.duration.inMilliseconds <= 0
                                                ? 1
                                                : c.value.duration.inMilliseconds)
                                            .toDouble(),
                                      ),
                                  min: 0,
                                  max: (c.value.duration.inMilliseconds <= 0
                                          ? 1
                                          : c.value.duration.inMilliseconds)
                                      .toDouble(),
                                  onChanged: (v) => c.seekTo(
                                    Duration(milliseconds: v.toInt()),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      tooltip: 'Vitesse',
                                      onPressed: () async {
                                        final next = _speed == 1.0
                                            ? 1.5
                                            : (_speed == 1.5 ? 2.0 : 1.0);
                                        await c.setPlaybackSpeed(next);
                                        if (mounted) {
                                          setState(() => _speed = next);
                                        }
                                      },
                                      icon: Text(
                                        '${_speed}x',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: _muted ? 'Son' : 'Muet',
                                      onPressed: () async {
                                        final next = !_muted;
                                        await c.setVolume(next ? 0 : 1);
                                        if (mounted) {
                                          setState(() => _muted = next);
                                        }
                                      },
                                      icon: Icon(
                                        _muted
                                            ? LucideIcons.volumeX
                                            : LucideIcons.volume2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: c.value.isPlaying ? 'Pause' : 'Lecture',
                                      onPressed: () async {
                                        if (c.value.isPlaying) {
                                          await c.pause();
                                        } else {
                                          await c.play();
                                        }
                                        if (mounted) setState(() {});
                                      },
                                      icon: Icon(
                                        c.value.isPlaying
                                            ? LucideIcons.pauseCircle
                                            : LucideIcons.playCircle,
                                        color: Colors.white,
                                        size: 44,
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasCaption)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        caption,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.92),
                                          fontSize: 14,
                                          height: 1.3,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
    );
  }
}

class _AttachTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.oklScaffold,
                shape: BoxShape.circle,
                border: Border.all(color: context.oklDivider),
              ),
              child: Icon(icon, color: context.oklOnSurface, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    context.oklOnSurfaceMuted(0.62),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
