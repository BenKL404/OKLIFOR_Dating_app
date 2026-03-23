import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/oklifor_media_url.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../data/chat_api_mapping.dart';
import '../data/chat_websocket_client.dart';
import '../models/chat_models.dart';
import 'chat_image_viewer_screen.dart';
import 'chat_thread_detail_screen.dart';
import 'conversation_search_screen.dart';
import 'conversation_media_screen.dart';
import 'conversation_mute_screen.dart';
import 'share_contact_screen.dart';
import 'new_message_screen.dart';

final _chatMediaCache = CacheManager(
  Config(
    'okliforChatMediaCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 300,
  ),
);

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
    if (!useRemote) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  Future<void> _loadRemoteMessages() async {
    try {
      final api = ref.read(okliforApiClientProvider);
      final storage = ref.read(authTokenStorageProvider);
      final myId = await storage.readUserId();
      final list = await api.fetchChatMessages(widget.thread.id);
      final mapped = chatMessagesFromPayloads(list, myUserId: myId);
      if (!mounted) return;
      setState(() {
        _messages = List<ChatMessage>.from(mapped);
        _loadingRemote = false;
      });
      unawaited(_markReadHttp());
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages = List<ChatMessage>.from(
          seedMessagesForThread(widget.thread.id),
        );
        _loadingRemote = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  @override
  void dispose() {
    _wsMessageSub?.cancel();
    _wsPresenceSub?.cancel();
    _wsTypingSub?.cancel();
    _wsReadReceiptSub?.cancel();
    _wsClient?.dispose();
    _recordTimer?.cancel();
    _typingStopDebounce?.cancel();
    _peerTypingHideTimer?.cancel();
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
      await client.subscribeThread(widget.thread.id);
      await _wsMessageSub?.cancel();
      await _wsPresenceSub?.cancel();
      await _wsTypingSub?.cancel();
      await _wsReadReceiptSub?.cancel();
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
          }
          if (!msg.mine) unawaited(_notifyReadCur());
          return;
        }
        setState(() => _messages.add(msg));
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
  }

  Future<bool> _sendBackendMessage({
    required String kind,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    int? voiceSeconds,
    String? locationLabel,
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

  void _afterAppend() {
    widget.onThreadPreviewUpdated?.call(
      _messages.last.kind == ChatMessageKind.text
          ? _messages.last.text ?? 'Message'
          : _labelForKind(_messages.last.kind),
      _messages.last.time,
    );
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

  String _messagePreview(ChatMessage m) {
    if (m.text != null && m.text!.trim().isNotEmpty) return m.text!.trim();
    switch (m.kind) {
      case ChatMessageKind.image:
        return '📷 Photo';
      case ChatMessageKind.video:
        return '🎬 Vidéo';
      case ChatMessageKind.voice:
        return '🎤 Vocal';
      case ChatMessageKind.location:
        return '📍 Position';
      case ChatMessageKind.system:
        return 'Système';
      case ChatMessageKind.text:
        return 'Message';
    }
  }

  String _labelForKind(ChatMessageKind k) {
    switch (k) {
      case ChatMessageKind.image:
        return '📷 Photo';
      case ChatMessageKind.video:
        return '🎬 Vidéo';
      case ChatMessageKind.voice:
        return '🎤 Message vocal';
      case ChatMessageKind.location:
        return '📍 Position';
      case ChatMessageKind.system:
        return _messages.last.text ?? '';
      case ChatMessageKind.text:
        return _messages.last.text ?? '';
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
    if (_peerOnline) return 'En ligne · Voir le profil';
    if (_peerLastSeenEpoch != null && _peerLastSeenEpoch! > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        _peerLastSeenEpoch! * 1000,
      ).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return 'Vu à $hh:$mm · Voir le profil';
    }
    return 'Hors ligne · Voir le profil';
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final duration = _formatDuration(_recordingSeconds);
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
      if (!mounted) return;
      OklFlows.pushResult(
        context,
        icon: LucideIcons.mic,
        title: 'Note vocale envoyée',
        subtitle: 'Durée : $duration — ton message est dans la conversation.',
        primaryLabel: 'OK',
      );
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
                      if (isBackendThreadId(widget.thread.id)) {
                        _runMediaUpload(
                          _pickAndSendDocumentFile,
                          onError: 'Échec de l’envoi document',
                        );
                      } else {
                        _pushDemoMessage(
                          ChatMessage(
                            id: 'doc${DateTime.now().millisecondsSinceEpoch}',
                            kind: ChatMessageKind.text,
                            text: '📄 document_contrat.pdf (démo)',
                            mine: true,
                            time: formatTimeNow(),
                          ),
                        );
                      }
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.image,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isBackendThreadId(widget.thread.id)) {
                        _runMediaUpload(
                          _pickAndSendImageFromGallery,
                          onError: 'Échec de l’envoi image',
                        );
                      } else {
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
                      }
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
      locationLabel: locationLabel,
      mine: true,
      time: formatTimeNow(),
      createdAt: DateTime.now().toUtc(),
    );
    setState(() => _messages.add(msg));
    _afterAppend();
  }

  Future<void> _pickAndSendImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
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
      imageUrl: upload.mediaKind.toUpperCase() == 'IMAGE'
          ? upload.signedUrl
          : null,
    );
    if (upload.mediaKind.toUpperCase() == 'IMAGE') {
      _appendLocalMineMessage(
        kind: ChatMessageKind.image,
        imageUrl: _absoluteMediaUrl(upload.signedUrl),
      );
    }
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
    final text = '📄 ${f.name}';
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
        builder: (_) => ChatImageViewerScreen(imageUrl: url, heroTag: tag),
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
    final t = widget.thread;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!context.mounted) return;
        _popConversationRoot();
      },
      child: Scaffold(
        backgroundColor: context.oklScaffold,
        appBar: AppBar(
          backgroundColor: context.oklScaffold,
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
                              color: context.oklOnSurface,
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
                                  ? (Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color ??
                                        context.oklOnSurfaceMuted(0.62))
                                  : (_peerTyping
                                        ? AppColors.primary
                                        : (_peerOnline
                                        ? AppColors.green
                                        : (Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.color ??
                                              context.oklOnSurfaceMuted(0.62)))),
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
                                color: context.oklSurface,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Aujourd’hui',
                                style: TextStyle(
                                  color: context.oklOnSurfaceMuted(0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      final msg = _messages[i - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onLongPress: () => _openMessageActions(msg),
                          child: _RichMessageBubble(
                            message: msg,
                            onTapImage: msg.kind == ChatMessageKind.image
                                ? () => _openImageViewer(msg)
                                : null,
                            onMessageMenu: _openMessageActions,
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
                                    color: context.oklSurface,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    readOnly: _isRecording || _isUploadingMedia,
                                    style: TextStyle(
                                      color: context.oklOnSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _isRecording
                                          ? 'Enregistrement… ${_formatDuration(_recordingSeconds)}'
                                          : 'Message…',
                                      hintStyle: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color ??
                                            context.oklOnSurfaceMuted(0.62),
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
                                        child: Icon(
                                          LucideIcons.smile,
                                          size: 18,
                                          color:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.color ??
                                              context.oklOnSurfaceMuted(0.62),
                                        ),
                                      ),
                                      suffixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: GestureDetector(
                                          onTap: _isUploadingMedia
                                              ? null
                                              : _openAttachmentOptions,
                                          child: Icon(
                                            LucideIcons.plus,
                                            size: 18,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.color ??
                                                context.oklOnSurfaceMuted(0.62),
                                          ),
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
                                    : context.oklSurface,
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

class _RichMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTapImage;
  final void Function(ChatMessage m)? onMessageMenu;

  const _RichMessageBubble({
    required this.message,
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
              width: 170,
              height: 120,
              decoration: BoxDecoration(
                color: context.oklSurface,
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
            width: 170,
            height: 120,
            decoration: BoxDecoration(
              color: context.oklSurface,
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
            width: 170,
            fit: BoxFit.cover,
            memCacheWidth: 340,
            placeholder: (c, u) =>
                Container(width: 170, height: 120, color: context.oklSurface),
            errorWidget: (c, u, e) => imageErrorBox(),
          ),
        );
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.58,
            ),
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
                    child: Hero(tag: heroTag, child: img),
                  ),
                ),
                const SizedBox(height: 4),
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
      case ChatMessageKind.video:
        return _VideoMessageBubble(message: m);
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
      case ChatMessageKind.text:
        final bg = m.mine
            ? AppColors.primary.withValues(alpha: 0.26)
            : context.oklSurface;
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
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
                  style: TextStyle(color: context.oklOnSurface, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.time,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.55),
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
        );
    }
  }
}

class _VideoMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _VideoMessageBubble({required this.message});

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
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.62,
        ),
        decoration: BoxDecoration(
          color: context.oklSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.oklDivider),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => _VideoPlayerScreen(url: videoUrl),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.black87),
                      Container(color: Colors.black.withValues(alpha: 0.22)),
                      const Align(
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.playCircle,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
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

class _WhatsAppStyleVoiceBubbleState extends State<_WhatsAppStyleVoiceBubble> {
  late final AudioPlayer _player;
  bool _ready = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  String? _loadError;
  int _setupGeneration = 0;

  ChatMessage get m => widget.message;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _bindStreams();
    _setup();
  }

  void _bindStreams() {
    _player.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
      setState(() => _duration = d);
    });
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s.playing);
    });
  }

  Future<void> _setup() async {
    final gen = ++_setupGeneration;
    final raw = m.audioUrl?.trim() ?? '';
    if (raw.isEmpty) {
      if (!mounted || gen != _setupGeneration) return;
      setState(() {
        _ready = false;
        _loadError = 'audio_manquant';
      });
      return;
    }
    final url = OkliforMediaUrl.resolve(raw);
    try {
      await _bindAudioFromUrl(url);
      if (!mounted || gen != _setupGeneration) return;
      setState(() {
        _ready = true;
        _loadError = null;
        _duration = _player.duration ?? Duration.zero;
      });
    } catch (e) {
      if (!mounted || gen != _setupGeneration) return;
      try {
        final f = await _chatMediaCache.getSingleFile(url);
        if (!mounted || gen != _setupGeneration) return;
        await _player.stop();
        await _player.setAudioSource(AudioSource.file(f.path));
        if (!mounted || gen != _setupGeneration) return;
        setState(() {
          _ready = true;
          _loadError = null;
          _duration = _player.duration ?? Duration.zero;
        });
      } catch (_) {
        if (!mounted || gen != _setupGeneration) return;
        setState(() {
          _ready = false;
          _loadError = e.toString();
        });
      }
    }
  }

  /// Lecture réseau plus fiable (cache progressif) hors Web ; repli sur URI direct.
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
      try {
        await _player.setAudioSource(LockCachingAudioSource(uri));
      } catch (_) {
        await _player.setAudioSource(AudioSource.uri(uri));
      }
      return;
    }
    await _player.setAudioSource(AudioSource.uri(uri));
  }

  @override
  void didUpdateWidget(covariant _WhatsAppStyleVoiceBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.audioUrl != widget.message.audioUrl) {
      _setup();
    }
  }

  @override
  void dispose() {
    _player.dispose();
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
                                    onPressed: !_ready
                                        ? null
                                        : () async {
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
                                    'Lecture impossible',
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
  const _VideoPlayerScreen({required this.url});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _ready = false;
  Duration _position = Duration.zero;

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
            File((await _chatMediaCache.getSingleFile(widget.url)).path),
          );
    await c.initialize();
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _ready && c != null
          ? Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: c.value.aspectRatio > 0
                          ? c.value.aspectRatio
                          : 16 / 9,
                      child: VideoPlayer(c),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  child: Column(
                    children: [
                      Slider(
                        value: _position.inMilliseconds.toDouble().clamp(
                          0,
                          (c.value.duration.inMilliseconds <= 0
                                  ? 1
                                  : c.value.duration.inMilliseconds)
                              .toDouble(),
                        ),
                        min: 0,
                        max:
                            (c.value.duration.inMilliseconds <= 0
                                    ? 1
                                    : c.value.duration.inMilliseconds)
                                .toDouble(),
                        onChanged: (v) =>
                            c.seekTo(Duration(milliseconds: v.toInt())),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (c.value.isPlaying) {
                                await c.pause();
                              } else {
                                await c.play();
                              }
                              setState(() {});
                            },
                            icon: Icon(
                              c.value.isPlaying
                                  ? LucideIcons.pauseCircle
                                  : LucideIcons.playCircle,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
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
