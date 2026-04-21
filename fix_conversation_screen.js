const fs = require('fs');
let content = fs.readFileSync(
  'lib/features/chat/views/conversation_screen.dart',
  'utf8'
);
const lines = content.split('\n');

// ── 1. Replace imports block (lines 1-42) ────────────────────────────────
const newImports = `import 'dart:async';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_chat_attachment_launch.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/utils/okl_media_cache.dart';
import '../models/chat_models.dart';
import '../providers/chat_providers.dart';
import '../repository/chat_repository.dart';
import 'chat_image_viewer_screen.dart';
import 'chat_thread_detail_screen.dart';
import 'conversation_search_screen.dart';
import 'conversation_media_screen.dart';
import 'conversation_mute_screen.dart';
import 'gallery_picker_screen.dart';
import 'document_compose_screen.dart';
import 'share_contact_screen.dart';
import 'new_message_screen.dart';`;

// Find first import line and last import line
let firstImport = -1, lastImport = -1;
for (let i = 0; i < lines.length; i++) {
  if (lines[i].startsWith('import ')) {
    if (firstImport === -1) firstImport = i;
    lastImport = i;
  }
  if (firstImport !== -1 && !lines[i].startsWith('import ') && i > lastImport) break;
}
console.log('Replacing imports from line', firstImport+1, 'to', lastImport+1);
lines.splice(firstImport, lastImport - firstImport + 1, ...newImports.split('\n'));
content = lines.join('\n');

// ── 2. Remove static cache + offline sync state variables ────────────────
const removeVars = [
  /\s*static final Map<String, List<ChatMessage>> _memMessagesByThread =\s*\n\s*<String, List<ChatMessage>>\{\};\n/,
  /\s*static final Map<String, DateTime> _memMessagesFetchedAtByThread =\s*\n\s*<String, DateTime>\{\};\n/,
  /\s*static const Duration _messagesFetchTtl = Duration\(seconds: 45\);\n/,
  /\s*Timer\? _loadingOverlayDebounceTimer;\n/,
  /\s*ChatWebSocketClient\? _wsClient;\n/,
  /\s*StreamSubscription<dynamic>\? _wsMessageSub;\n/,
  /\s*StreamSubscription<dynamic>\? _wsPresenceSub;\n/,
  /\s*StreamSubscription<dynamic>\? _wsTypingSub;\n/,
  /\s*StreamSubscription<dynamic>\? _wsReadReceiptSub;\n/,
  /\s*StreamSubscription<String>\? _wsErrorSub;\n/,
  /\s*String\? _myUserId;\n/,
  /\s*int\? _peerLastSeenEpoch;\n/,
  /\s*Timer\? _typingStopDebounce;\n/,
  /\s*bool _lastTypingSent = false;\n/,
  /\s*DateTime\? _lastTypingSentAt;\n/,
  /\s*Timer\? _persistMessagesDebounce;\n/,
  /\s*final Set<String> _prefetchedPersistentUrls = <String>\{\};\n/,
  /\s*late final VoidCallback _offlineSyncListener;\n/,
];
removeVars.forEach(re => {
  const before = content.length;
  content = content.replace(re, '\n');
  if (content.length === before) console.log('NOT REMOVED:', re.toString().substring(0, 50));
});

// ── 3. Add StreamSubscription for repo events ─────────────────────────────
const addSubscription = `  StreamSubscription<ChatRepoEvent>? _repoSub;\n`;
content = content.replace(
  '  final Set<String> _prefetchedMediaUrls = <String>{};',
  `  final Set<String> _prefetchedMediaUrls = <String>{};\n  StreamSubscription<ChatRepoEvent>? _repoSub;`
);

// ── 4. Replace _flushOfflineQueueForThread with no-op ────────────────────
content = content.replace(
  /Future<void> _flushOfflineQueueForThread\(\) async \{[\s\S]*?^  \}/m,
  `Future<void> _flushOfflineQueueForThread() async {}`
);

// ── 5. Replace _reloadMessagesFromDiskAfterGlobalSync with no-op ──────────
content = content.replace(
  /Future<void> _reloadMessagesFromDiskAfterGlobalSync\(\) async \{[\s\S]*?^  \}/m,
  `Future<void> _reloadMessagesFromDiskAfterGlobalSync() async {}`
);

// ── 6. Replace _shouldFetchRemoteMessages ────────────────────────────────
content = content.replace(
  /bool _shouldFetchRemoteMessages\(\) \{[\s\S]*?^  \}/m,
  `bool _shouldFetchRemoteMessages() => true;`
);

// ── 7. Replace _messagesFingerprint ──────────────────────────────────────
// keep as-is, it's just a helper

// ── 8. Replace _hydratePeerIdentity with no-op ───────────────────────────
content = content.replace(
  /Future<void> _hydratePeerIdentity\(\) async \{[\s\S]*?^  \}/m,
  `Future<void> _hydratePeerIdentity() async {}`
);

// ── 9. Replace _loadRemoteMessages with repo call ────────────────────────
const newLoadRemote = `  Future<void> _loadRemoteMessages() async {
    final repo = ref.read(chatRepositoryProvider);
    final messages = await repo.fetchMessages(widget.thread.id);
    if (!mounted) return;
    setState(() {
      _messages = List<ChatMessage>.from(messages);
      _loadingRemote = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    _subscribeToRepoEvents();
  }`;
content = content.replace(
  /Future<void> _loadRemoteMessages\(\) async \{[\s\S]*?^  \}/m,
  newLoadRemote
);

// ── 10. Replace _prefetchPersistentDocuments with no-op ──────────────────
content = content.replace(
  /void _prefetchPersistentDocuments\(List<ChatMessage> msgs\) \{[\s\S]*?^  \}/m,
  `void _prefetchPersistentDocuments(List<ChatMessage> msgs) {}`
);

// ── 11. Replace dispose ──────────────────────────────────────────────────
const newDispose = `  @override
  void dispose() {
    _scrollController.dispose();
    _loadingOverlayDebounceTimer?.cancel();
    _repoSub?.cancel();
    _recordTimer?.cancel();
    _peerTypingHideTimer?.cancel();
    _messageController.removeListener(_syncSendState);
    _audioRecorder.dispose();
    _messageController.dispose();
    super.dispose();
  }`;
content = content.replace(
  /@override\s*\n  void dispose\(\) \{[\s\S]*?super\.dispose\(\);\s*\n  \}/m,
  newDispose
);

// ── 12. Replace _connectRealtime with repo subscribe ─────────────────────
const newConnectRealtime = `  Future<void> _connectRealtime() async {
    _subscribeToRepoEvents();
    await ref.read(chatRepositoryProvider).markRead(widget.thread.id);
  }

  void _subscribeToRepoEvents() {
    _repoSub?.cancel();
    final repo = ref.read(chatRepositoryProvider);
    _repoSub = repo.watchThread(widget.thread.id).listen((event) {
      if (!mounted) return;
      switch (event) {
        case ChatRepoMessageEvent(:final message):
          final dup = _messages.any((m) => m.id == message.id);
          if (!dup) {
            setState(() => _messages.add(message));
            _afterAppend();
          }
        case ChatRepoPresenceEvent(:final online):
          setState(() => _peerOnline = online);
        case ChatRepoTypingEvent(:final typing):
          _peerTypingHideTimer?.cancel();
          setState(() => _peerTyping = typing);
          if (typing) {
            _peerTypingHideTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(() => _peerTyping = false);
            });
          }
        case ChatRepoReadEvent():
          break;
      }
    });
  }`;
content = content.replace(
  /Future<void> _connectRealtime\(\) async \{[\s\S]*?^  \}/m,
  newConnectRealtime
);

// ── 13. Replace _markReadHttp + _notifyReadCur with no-ops ───────────────
content = content.replace(
  /Future<void> _markReadHttp\(\) async \{[\s\S]*?^  \}/m,
  `Future<void> _markReadHttp() async {
    await ref.read(chatRepositoryProvider).markRead(widget.thread.id);
  }`
);
content = content.replace(
  /Future<void> _notifyReadCur\(\) async \{[\s\S]*?^  \}/m,
  `Future<void> _notifyReadCur() async {
    await _markReadHttp();
  }`
);

// ── 14. Replace _applyReadReceipt with simplified version ────────────────
content = content.replace(
  /void _applyReadReceipt\(\s*\n?\s*String threadId[\s\S]*?^  \}/m,
  `void _applyReadReceipt(String threadId, String readerUserId, int readAtEpoch) {
    if (!mounted || threadId != widget.thread.id) return;
    setState(() {
      _messages = _messages.map((m) {
        if (!m.mine || m.readByRecipient) return m;
        return m.copyWith(readByRecipient: true);
      }).toList();
    });
  }`
);

// ── 15. Replace _sendBackendMessage with repo call ───────────────────────
const newSendBackend = `  Future<bool> _sendBackendMessage({
    required String kind,
    String? localMessageId,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    int? voiceSeconds,
    String? locationLabel,
    String? fileUrl,
  }) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      switch (kind.toUpperCase()) {
        case 'TEXT':
          await repo.sendText(widget.thread.id, text ?? '');
        case 'IMAGE':
          if (imageUrl != null) {
            // image already appended locally; mock repo handles auto-reply
          }
        case 'VIDEO':
          break;
        case 'VOICE':
        case 'AUDIO':
          break;
        case 'FILE':
          break;
        case 'LOCATION':
          break;
      }
      return true;
    } catch (e) {
      if (mounted) OklFeedback.snack(context, 'Envoi impossible: \$e');
      return false;
    }
  }`;
content = content.replace(
  /Future<bool> _sendBackendMessage\(\{[\s\S]*?^  \}/m,
  newSendBackend
);

// ── 16. Replace _emitTyping with no-op ───────────────────────────────────
content = content.replace(
  /void _emitTyping\(bool hasText\) \{[\s\S]*?^  \}/m,
  `void _emitTyping(bool hasText) {}`
);

// ── 17. Replace _persistMessagesForCache + _schedulePersistMessages ───────
content = content.replace(
  /Future<void> _persistMessagesForCache\(\) async \{[\s\S]*?^  \}/m,
  `Future<void> _persistMessagesForCache() async {}`
);
content = content.replace(
  /void _schedulePersistMessages\(\) \{[\s\S]*?^  \}/m,
  `void _schedulePersistMessages() {}`
);

// ── 18. Simplify _afterAppend ─────────────────────────────────────────────
const newAfterAppend = `  void _afterAppend() {
    widget.onThreadPreviewUpdated?.call(
      _messagePreview(_messages.last),
      _messages.last.time,
    );
    _prefetchRecentMedia(_messages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        final px = _scrollController.position.pixels;
        final isNearBottom = (max - px) < 160;
        final lastMine = _messages.isNotEmpty ? (_messages.last.mine) : false;
        final shouldAutoScroll = lastMine || (_userHasScrolled && isNearBottom);
        if (shouldAutoScroll) {
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }`;
content = content.replace(
  /void _afterAppend\(\) \{[\s\S]*?^  \}/m,
  newAfterAppend
);

// ── 19. Replace _sendText to use repo ────────────────────────────────────
const newSendText = `  Future<void> _sendText() async {
    final txt = _messageController.text.trim();
    if (txt.isEmpty) return;
    final payload = _replyingTo == null
        ? txt
        : '\\u21aa \${_messagePreview(_replyingTo!)}\\n\$txt';
    setState(() => _replyingTo = null);
    _messageController.clear();
    _syncSendState();
    final msg = await ref.read(chatRepositoryProvider).sendText(
      widget.thread.id,
      payload,
    );
    if (!mounted) return;
    if (!_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages.add(msg));
      _afterAppend();
    }
  }`;
content = content.replace(
  /Future<void> _sendText\(\) async \{[\s\S]*?^  \}/m,
  newSendText
);

// ── 20. Remove isBackendThreadId check in _openGalleryMediaChoice ─────────
content = content.replace(
  /void _openGalleryMediaChoice\(\) \{[\s\S]*?^  \}/m,
  `  void _openGalleryMediaChoice() {
    _runMediaUpload(
      _openWhatsAppGalleryFlow,
      onError: "Echec de l'envoi media",
    );
  }`
);

// ── 21. Replace _openWhatsAppGalleryFlow to use repo ─────────────────────
const newGalleryFlow = `  Future<void> _openWhatsAppGalleryFlow() async {
    final composed = await Navigator.of(context, rootNavigator: true)
        .push<OklComposedMedia>(
          MaterialPageRoute<OklComposedMedia>(
            builder: (_) => const GalleryPickerScreen(),
          ),
        );
    if (!mounted || composed == null) return;
    final bytes = composed.bytes != null
        ? Uint8List.fromList(composed.bytes!)
        : (kIsWeb ? null : null);
    if (bytes == null && composed.filePath == null) return;
    final fileBytes = bytes ?? Uint8List(0);
    final caption = composed.caption.trim();
    final ext = composed.filename.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext);
    if (isVideo) {
      final msg = await ref.read(chatRepositoryProvider).sendVideo(
        widget.thread.id,
        fileBytes,
        composed.filename,
        caption: caption.isEmpty ? null : caption,
      );
      if (mounted && !_messages.any((m) => m.id == msg.id)) {
        setState(() => _messages.add(msg));
        _afterAppend();
      }
    } else {
      final msg = await ref.read(chatRepositoryProvider).sendImage(
        widget.thread.id,
        fileBytes,
        composed.filename,
        caption: caption.isEmpty ? null : caption,
      );
      if (mounted && !_messages.any((m) => m.id == msg.id)) {
        setState(() => _messages.add(msg));
        _afterAppend();
      }
    }
  }`;
content = content.replace(
  /Future<void> _openWhatsAppGalleryFlow\(\) async \{[\s\S]*?^  \}/m,
  newGalleryFlow
);

// ── 22. Replace _pickAndSendVideoFromCamera to use repo ──────────────────
const newPickVideo = `  Future<void> _pickAndSendVideoFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.camera);
    if (picked == null) return;
    final bytes = kIsWeb ? await picked.readAsBytes() : Uint8List(0);
    final msg = await ref.read(chatRepositoryProvider).sendVideo(
      widget.thread.id,
      bytes,
      picked.name,
    );
    if (mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages.add(msg));
      _afterAppend();
    }
  }`;
content = content.replace(
  /Future<void> _pickAndSendVideoFromCamera\(\) async \{[\s\S]*?^  \}/m,
  newPickVideo
);

// ── 23. Replace _pickAndSendAudioFile to use repo ────────────────────────
const newPickAudio = `  Future<void> _pickAndSendAudioFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'webm'],
      withData: kIsWeb,
    );
    final f = picked?.files.single;
    if (f == null) return;
    final bytes = kIsWeb ? (f.bytes ?? Uint8List(0)) : Uint8List(0);
    final msg = await ref.read(chatRepositoryProvider).sendAudio(
      widget.thread.id,
      bytes,
      f.name,
    );
    if (mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages.add(msg));
      _afterAppend();
    }
  }`;
content = content.replace(
  /Future<void> _pickAndSendAudioFile\(\) async \{[\s\S]*?^  \}/m,
  newPickAudio
);

// ── 24. Replace _pickAndSendDocumentFile to use repo ─────────────────────
const newPickDoc = `  Future<void> _pickAndSendDocumentFile() async {
    final picked = await FilePicker.platform.pickFiles(withData: kIsWeb);
    final f = picked?.files.single;
    if (f == null) return;
    final composed = await Navigator.of(context, rootNavigator: true)
        .push<DocumentComposeResult>(
          MaterialPageRoute<DocumentComposeResult>(
            builder: (_) => DocumentComposeScreen(file: f),
          ),
        );
    if (!mounted || composed == null) return;
    try {
      final bytes = kIsWeb ? (f.bytes ?? Uint8List(0)) : Uint8List(0);
      final caption = composed.caption.trim();
      final label = caption.isEmpty ? '\\u{1F4C4} \${f.name}' : '\\u{1F4C4} \${f.name}\\n\$caption';
      final msg = await ref.read(chatRepositoryProvider).sendFile(
        widget.thread.id,
        bytes,
        f.name,
        caption: label,
      );
      if (mounted && !_messages.any((m) => m.id == msg.id)) {
        setState(() => _messages.add(msg));
        _afterAppend();
      }
    } catch (_) {
      if (mounted) OklFeedback.snack(context, 'Envoi du document impossible');
    }
  }`;
content = content.replace(
  /Future<void> _pickAndSendDocumentFile\(\) async \{[\s\S]*?^  \}/m,
  newPickDoc
);

// ── 25. Replace _sendSharedContact to use repo ────────────────────────────
const newSendContact = `  Future<void> _sendSharedContact(ChatContact c) async {
    final text = '\\u{1F464} Contact partage: \${c.name}';
    final msg = await ref.read(chatRepositoryProvider).sendText(
      widget.thread.id,
      text,
    );
    if (mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages.add(msg));
      _afterAppend();
    }
  }`;
content = content.replace(
  /Future<void> _sendSharedContact\(ChatContact c\) async \{[\s\S]*?^  \}/m,
  newSendContact
);

// ── 26. Replace _runMediaUpload to remove connectivity check ─────────────
const newRunMediaUpload = `  Future<void> _runMediaUpload(
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
        _uploadError = '\$onError: \$e';
      });
      OklFeedback.snack(context, _uploadError!);
    }
  }`;
content = content.replace(
  /Future<void> _runMediaUpload\(\s*\n\s*Future<void> Function\(\) action[\s\S]*?^  \}/m,
  newRunMediaUpload
);

// ── 27. Replace _absoluteMediaUrl to just return raw ─────────────────────
content = content.replace(
  /String _absoluteMediaUrl\(String raw\) \{[\s\S]*?^  \}/m,
  `String _absoluteMediaUrl(String raw) => raw;`
);

// ── 28. Remove isBackendThreadId checks in _toggleRecording ───────────────
// Simplified version: always use mock path
content = content.replace(
  /if \(isBackendThreadId\(widget\.thread\.id\)\) \{\s*\n\s*try \{[\s\S]*?else \{\s*\n\s*final msg = ChatMessage\(\s*\n\s*id: 'v/m,
  `// mock mode: use local voice\n        {\n          final msg = ChatMessage(\n          id: 'v`
);

// ── 29. Fix _openAttachmentOptions - remove all isBackendThreadId guards ──
// Replace backend-guarded attachment handlers with direct calls
content = content.replace(
  /if \(isBackendThreadId\(widget\.thread\.id\)\) \{\s*\n\s*_runMediaUpload\(\s*\n\s*_pickAndSendDocumentFile,/m,
  `_runMediaUpload(\n                        _pickAndSendDocumentFile,`
);
content = content.replace(
  /if \(isBackendThreadId\(widget\.thread\.id\)\) \{\s*\n\s*_runMediaUpload\(\s*\n\s*_pickAndSendVideoFromCamera,/m,
  `_runMediaUpload(\n                        _pickAndSendVideoFromCamera,`
);
// Remove else snack for camera
content = content.replace(
  /\} else \{\s*\n\s*OklFeedback\.snack\(\s*\n\s*context,\s*\n\s*'Conversation non synchronisée avec le backend',\s*\n\s*\);\s*\n\s*\}\s*\n\s*\},\s*\n\s*\),\s*\n\s*\],/m,
  `          ],`
);

// ── 30. Fix location send in attachment options ────────────────────────────
content = content.replace(
  /if \(isBackendThreadId\(widget\.thread\.id\)\) \{\s*\n\s*_appendLocalMineMessage\(\s*\n\s*kind: ChatMessageKind\.location,\s*\n\s*locationLabel: 'Boulevard du 13 janvier, Lomé',\s*\n\s*\);\s*\n\s*_sendBackendMessage\(\s*\n\s*kind: 'LOCATION',\s*\n\s*locationLabel: 'Boulevard du 13 janvier, Lomé',\s*\n\s*\);\s*\n\s*\} else \{[\s\S]*?\}\s*\n\s*\},\s*\n\s*\),\s*\n\s*_AttachTile\(/m,
  `_appendLocalMineMessage(\n                      kind: ChatMessageKind.location,\n                      locationLabel: 'Boulevard du 13 janvier, Lomé',\n                    );\n                  },\n                ),\n                _AttachTile(`
);

// ── 31. Replace initState ─────────────────────────────────────────────────
const newInitState = `  @override
  void initState() {
    super.initState();
    _lastKnownScrollPx = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0;
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final px = _scrollController.position.pixels;
      if (!_userHasScrolled && (px - _lastKnownScrollPx).abs() > 4) {
        _userHasScrolled = true;
      }
      _lastKnownScrollPx = px;
    });
    _messages = List<ChatMessage>.from(
      widget.initialMessagesOverride ?? <ChatMessage>[],
    );
    _audioRecorder = AudioRecorder();
    _messageController.addListener(_syncSendState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRemoteMessages();
    });
  }`;
content = content.replace(
  /@override\s*\n  void initState\(\) \{[\s\S]*?^  \}/m,
  newInitState
);

// ── 32. Fix apostrophe strings ────────────────────────────────────────────
const apostropheLines = content.split('\n');
apostropheLines.forEach((line, i) => {
  // Check if a single-quoted string contains an internal apostrophe
  // by looking for the pattern '...word's...
  if (line.match(/'[^']*[a-zA-Zàèéêùûîô]'[a-zA-Z]/)) {
    const fixed = line.replace(/'([^']*[a-zA-Zàèéêùûîô])'([a-zA-Z])/g, (m, p1, p2) => {
      return `"${p1}'${p2}`;
    });
    // Close the double-quote string if the line ends with single quote
    if (fixed !== line) {
      console.log('Fixed apostrophe line', i+1, ':', line.trim().substring(0, 60));
    }
  }
});

// Simpler approach: find all single-quoted strings with apostrophes and fix them
content = content
  .replace(/'Pas de connexion : impossible d'envoyer([^']*)'/g, '"Pas de connexion : impossible d\'envoyer$1"')
  .replace(/'Impossible de démarrer l'enregistrement([^']*)'/g, '"Impossible de démarrer l\'enregistrement$1"')
  .replace(/'Pas de connexion : impossible d'envoyer un média pour le moment\.'/g, '"Pas de connexion : impossible d\'envoyer un media pour le moment."')
  .replace(/'Enregistrement audio introuvable\.'/g, '"Enregistrement audio introuvable."')
  .replace(/'Envoi de la note vocale impossible\. Vérifie ta connexion\.'/g, '"Envoi de la note vocale impossible. Verifie ta connexion."')
  .replace(/'Conversation non synchronisée avec le backend'/g, '"Conversation non synchronisee avec le backend"')
  .replace(/'Échec de l'envoi ([^']*)'/g, '"Echec de l\'envoi $1"');

// ── Save ──────────────────────────────────────────────────────────────────
fs.writeFileSync(
  'lib/features/chat/views/conversation_screen.dart',
  content,
  'utf8'
);
console.log('\nDone! File saved.');
