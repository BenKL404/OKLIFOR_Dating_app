import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/api/auth_token_storage.dart';
import '../../../core/api/models/contact_api_models.dart';
import '../../../core/api/oklifor_api_client.dart';
import '../data/chat_api_mapping.dart';
import '../data/chat_local_cache.dart';
import '../data/chat_websocket_client.dart';
import '../models/chat_models.dart';
import 'chat_repository.dart';

/// Implémentation réelle du [ChatRepository] :
///   - REST via [OkliforApiClient]
///   - WebSocket temps réel via [ChatWebSocketClient]
///   - Cache disque via [ChatLocalCache]
class ApiChatRepository implements ChatRepository {
  ApiChatRepository({
    required OkliforApiClient api,
    required AuthTokenStorage tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final OkliforApiClient _api;
  final AuthTokenStorage _tokenStorage;
  final ChatWebSocketClient _ws = ChatWebSocketClient();

  // Contrôleurs d'événements par thread (pour watchThread)
  final Map<String, StreamController<ChatRepoEvent>> _eventControllers = {};
  // Abonnements aux streams WebSocket globaux
  StreamSubscription<dynamic>? _wsMsgSub;
  StreamSubscription<dynamic>? _wsPresenceSub;
  StreamSubscription<dynamic>? _wsTypingSub;
  StreamSubscription<dynamic>? _wsReadSub;
  bool _wsListening = false;

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<String> _myUserId() async =>
      (await _tokenStorage.readUserId()) ?? '';


  // ── WebSocket — connexion et dispatch ─────────────────────────────────────

  Future<void> _ensureWsConnected() async {
    if (_ws.isConnected) return;
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return;
    await _ws.connect(accessToken: token);
    _startWsListeners();
  }

  void _startWsListeners() {
    if (_wsListening) return;
    _wsListening = true;

    // Messages entrants
    _wsMsgSub = _ws.messages.listen((payload) async {
      final myId = await _myUserId();
      final msg = chatMessageFromPayload(payload, myUserId: myId);
      final ctrl = _eventControllers[payload.threadId];
      ctrl?.add(ChatRepoMessageEvent(msg));
    });

    // Présence
    _wsPresenceSub = _ws.presence.listen((event) {
      final ctrl = _eventControllers[event.threadId];
      ctrl?.add(ChatRepoPresenceEvent(event.online));
    });

    // Typing
    _wsTypingSub = _ws.typing.listen((event) {
      final ctrl = _eventControllers[event.threadId];
      ctrl?.add(ChatRepoTypingEvent(event.typing));
    });

    // Read receipts
    _wsReadSub = _ws.readReceipts.listen((event) {
      final ctrl = _eventControllers[event.threadId];
      ctrl?.add(const ChatRepoReadEvent());
    });
  }

  // ── Threads ───────────────────────────────────────────────────────────────

  @override
  Future<List<ChatThread>> fetchThreads() async {
    final myId = await _myUserId();

    // Charger les contacts pour résoudre noms/avatars
    Map<String, String> nameById = {};
    Map<String, String> avatarById = {};
    try {
      final contacts = await _api.fetchContacts();
      for (final c in contacts) {
        nameById[c.userId] = c.displayName;
        avatarById[c.userId] = c.avatarUrl;
      }
    } catch (_) {
      // Si les contacts échouent, on continue sans résolution de noms
    }

    List<ChatThread> threads;
    try {
      final payloads = await _api.fetchChatThreads();
      threads = payloads
          .map((p) => chatThreadFromPayload(
                p,
                myUserId: myId,
                contactNameById: nameById,
                contactAvatarById: avatarById,
              ))
          .toList();
      // Persist to disk cache
      await ChatLocalCache.saveThreads(myId, threads);
    } catch (_) {
      // Fallback cache disque en cas d'erreur réseau
      final cached = await ChatLocalCache.loadThreads(myId);
      threads = cached ?? const [];
    }

    // Enrichir avec les aperçus de statuts si on a des participants
    try {
      final userIds = threads
          .expand((t) => t.participantUserIds)
          .where((id) => id != myId)
          .toSet()
          .toList();
      if (userIds.isNotEmpty) {
        final previews = await _api.fetchStatusPreviews(userIds);
        final previewMap = {for (final p in previews) p.userId: p};
        threads = threads.map((t) {
          if (t.isGroup) return t;
          final otherId = t.participantUserIds
              .firstWhere((id) => id != myId, orElse: () => '');
          if (otherId.isEmpty) return t;
          final sp = previewMap[otherId];
          if (sp == null) return t;
          return t.copyWith(
            hasStory: true,
            statusKind: sp.kind,
            statusImageUrl: sp.mediaUrl ?? '',
            statusCaption: sp.text ?? '',
            statusBackgroundHex: sp.backgroundColorHex,
            statusTimeAgo: _relativeTime(sp.createdAt),
          );
        }).toList();
      }
    } catch (_) {
      // Les statuts sont optionnels — pas bloquant
    }

    return threads;
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'hier';
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Future<List<ChatMessage>> fetchMessages(String threadId,
      {int page = 0}) async {
    final myId = await _myUserId();

    // Essaie d'abord le réseau
    try {
      final payloads = await _api.fetchChatMessages(threadId);
      final messages = chatMessagesFromPayloads(payloads, myUserId: myId);
      await ChatLocalCache.saveMessages(myId, threadId, messages);
      return messages;
    } catch (_) {
      // Fallback cache disque
      final cached = await ChatLocalCache.loadMessages(myId, threadId);
      return cached ?? const [];
    }
  }

  // ── Envoi — helpers communs ───────────────────────────────────────────────

  String _contentTypeFor(String kind, String filename) {
    final lower = filename.toLowerCase();
    if (kind == 'IMAGE') {
      if (lower.endsWith('.png')) return 'image/png';
      if (lower.endsWith('.webp')) return 'image/webp';
      return 'image/jpeg';
    }
    if (kind == 'VIDEO') {
      if (lower.endsWith('.webm')) return 'video/webm';
      if (lower.endsWith('.mov')) return 'video/quicktime';
      return 'video/mp4';
    }
    if (kind == 'VOICE') {
      if (lower.endsWith('.wav')) return 'audio/wav';
      if (lower.endsWith('.ogg')) return 'audio/ogg';
      if (lower.endsWith('.webm')) return 'audio/webm';
      return 'audio/mp4';
    }
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'application/octet-stream';
  }

  /// Gets a presigned PUT URL, uploads directly to MinIO, then sends the message.
  Future<ChatMessage> _uploadAndSend({
    required String threadId,
    required String kind,
    required Uint8List bytes,
    required String filename,
    String? caption,
    int? voiceSeconds,
  }) async {
    debugPrint('[OKL_SEND] START kind=$kind filename=$filename bytes=${bytes.length}');
    final myId = await _myUserId();

    // 1. Compress images to WebP before upload
    Uint8List uploadBytes = bytes;
    String uploadFilename = filename;
    if (kind == 'IMAGE') {
      try {
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          format: CompressFormat.webp,
          quality: 82,
        );
        if (compressed.length < bytes.length) {
          uploadBytes = compressed;
          uploadFilename = filename.replaceAll(
            RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false),
            '.webp',
          );
        }
      } catch (e) {
        debugPrint('[OKL_SEND] compress error: $e');
      }
    }

    final ct = _contentTypeFor(kind, uploadFilename);
    debugPrint('[OKL_SEND] contentType=$ct uploadBytes=${uploadBytes.length}');

    // 2. Presign via backend
    debugPrint('[OKL_SEND] calling presign...');
    final presign = await _api.presignChatMedia(
      threadId: threadId,
      filename: uploadFilename,
      contentType: ct,
    );
    debugPrint('[OKL_SEND] presign ok putUrl=${presign.putUrl} fileUrl=${presign.fileUrl}');

    // 3. Upload directly to object storage (bypasses backend)
    debugPrint('[OKL_SEND] uploading to presigned url...');
    await _api.uploadToPresignedUrl(
      putUrl: presign.putUrl,
      bytes: uploadBytes,
      contentType: ct,
    );
    debugPrint('[OKL_SEND] upload ok');

    // 4. Send message with permanent public URL
    final fileUrl = presign.fileUrl;
    debugPrint('[OKL_SEND] sending chat message fileUrl=$fileUrl');
    final payload = await _api.sendChatMessage(
      threadId: threadId,
      kind: kind,
      text: caption,
      imageUrl: kind == 'IMAGE' ? fileUrl : null,
      videoUrl: kind == 'VIDEO' ? fileUrl : null,
      audioUrl: kind == 'VOICE' ? fileUrl : null,
      voiceSeconds: voiceSeconds,
      fileUrl: kind == 'FILE' ? fileUrl : null,
    );
    debugPrint('[OKL_SEND] message sent id=${payload.id}');

    return chatMessageFromPayload(payload, myUserId: myId);
  }

  // ── Envoi texte ───────────────────────────────────────────────────────────

  @override
  Future<ChatMessage> sendText(String threadId, String text) async {
    final myId = await _myUserId();
    final payload = await _api.sendChatMessage(
      threadId: threadId,
      kind: 'TEXT',
      text: text,
    );
    return chatMessageFromPayload(payload, myUserId: myId);
  }

  // ── Envoi image ───────────────────────────────────────────────────────────

  @override
  Future<ChatMessage> sendImage(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  }) async {
    return _uploadAndSend(
      threadId: threadId,
      kind: 'IMAGE',
      bytes: bytes,
      filename: filename,
      caption: caption,
    );
  }

  // ── Envoi vidéo ───────────────────────────────────────────────────────────

  @override
  Future<ChatMessage> sendVideo(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  }) async {
    return _uploadAndSend(
      threadId: threadId,
      kind: 'VIDEO',
      bytes: bytes,
      filename: filename,
      caption: caption,
    );
  }

  // ── Envoi audio ───────────────────────────────────────────────────────────

  @override
  Future<ChatMessage> sendAudio(
    String threadId,
    Uint8List bytes,
    String filename, {
    int durationSeconds = 0,
  }) async {
    return _uploadAndSend(
      threadId: threadId,
      kind: 'VOICE',
      bytes: bytes,
      filename: filename,
      voiceSeconds: durationSeconds > 0 ? durationSeconds : null,
    );
  }

  // ── Envoi fichier ─────────────────────────────────────────────────────────

  @override
  Future<ChatMessage> sendFile(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  }) async {
    return _uploadAndSend(
      threadId: threadId,
      kind: 'FILE',
      bytes: bytes,
      filename: filename,
      caption: caption ?? filename,
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  @override
  Future<void> markRead(String threadId) async {
    try {
      await _api.markThreadRead(threadId);
    } catch (_) {
      // Silencieux : l'UI ne doit pas crasher si le réseau est absent
    }
  }

  // ── Création de fils ──────────────────────────────────────────────────────

  @override
  Future<ChatThread> createDirectThread(String contactId) async {
    final myId = await _myUserId();
    final payload = await _api.createDirectThread(contactId);

    // Résoudre le nom du contact
    Map<String, String> nameById = {};
    Map<String, String> avatarById = {};
    try {
      final contacts = await _api.fetchContacts();
      for (final c in contacts) {
        nameById[c.userId] = c.displayName;
        avatarById[c.userId] = c.avatarUrl;
      }
    } catch (_) {}

    return chatThreadFromPayload(
      payload,
      myUserId: myId,
      contactNameById: nameById,
      contactAvatarById: avatarById,
    );
  }

  @override
  Future<ChatThread> createGroupThread(
      String name, List<String> memberIds) async {
    final myId = await _myUserId();
    // Le backend ne supporte pas encore de groupe multi-membres via l'API
    // On crée un DM avec le premier membre en attendant
    // TODO: câbler quand l'endpoint POST /api/v1/chat/threads/group sera disponible
    if (memberIds.isEmpty) {
      throw StateError('createGroupThread_aucun_membre');
    }
    final payload = await _api.createDirectThread(memberIds.first);
    return chatThreadFromPayload(
      payload,
      myUserId: myId,
    );
  }

  // ── Contacts ──────────────────────────────────────────────────────────────

  @override
  Future<List<ChatContact>> fetchContacts() async {
    final List<ContactPayload> payloads = await _api.fetchContacts();
    return payloads
        .map((c) => ChatContact(
              id: c.userId,
              name: c.displayName.isNotEmpty ? c.displayName : 'Utilisateur',
              avatarUrl: c.avatarUrl.isNotEmpty
                  ? c.avatarUrl
                  : kDefaultChatAvatarUrl,
            ))
        .toList();
  }

  // ── Stream temps réel ─────────────────────────────────────────────────────

  @override
  Stream<ChatRepoEvent> watchThread(String threadId) {
    // Crée (ou réutilise) le contrôleur broadcast pour ce thread
    final ctrl = _eventControllers.putIfAbsent(
      threadId,
      () => StreamController<ChatRepoEvent>.broadcast(),
    );

    // Connexion WS différée (non bloquante)
    _ensureWsConnected().then((_) {
      if (_ws.isConnected) {
        _ws.subscribeThread(threadId).catchError((_) {});
      }
    });

    return ctrl.stream;
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _wsMsgSub?.cancel();
    _wsPresenceSub?.cancel();
    _wsTypingSub?.cancel();
    _wsReadSub?.cancel();
    _ws.dispose();
    for (final c in _eventControllers.values) {
      c.close();
    }
    _eventControllers.clear();
  }
}
