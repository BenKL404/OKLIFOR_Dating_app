const fs = require('fs');
const content = fs.readFileSync('lib/features/chat/views/conversation_screen.dart', 'utf8');
const lines = content.split('\n');

// Helper: find end of method starting at startLine (line index)
// Returns the line index of the closing brace
function findMethodEnd(lines, startLine) {
  let depth = 0;
  let started = false;
  for (let i = startLine; i < lines.length; i++) {
    const line = lines[i];
    for (const ch of line) {
      if (ch === '{') { depth++; started = true; }
      else if (ch === '}') { depth--; }
    }
    if (started && depth === 0) return i;
  }
  return -1;
}

// Helper: find the start line of a method by searching for a pattern
function findMethodStart(lines, pattern, fromLine = 0) {
  for (let i = fromLine; i < lines.length; i++) {
    if (pattern.test(lines[i])) return i;
  }
  return -1;
}

// Helper: replace a method with new implementation
function replaceMethod(lines, signature, newImpl) {
  const startIdx = findMethodStart(lines, signature);
  if (startIdx === -1) {
    console.log('NOT FOUND:', signature.toString());
    return lines;
  }
  const endIdx = findMethodEnd(lines, startIdx);
  if (endIdx === -1) {
    console.log('NO END FOUND for:', signature.toString());
    return lines;
  }
  console.log(`Replacing lines ${startIdx+1}-${endIdx+1}: ${lines[startIdx].trim().substring(0,60)}`);
  const newLines = newImpl.split('\n');
  lines.splice(startIdx, endIdx - startIdx + 1, ...newLines);
  return lines;
}

let L = [...lines];

// ── Fix 1: Add _loadingOverlayDebounceTimer to state vars ────────────────
{
  const idx = findMethodStart(L, /bool _isUploadingMedia = false;/);
  if (idx !== -1) {
    L.splice(idx, 0, '  Timer? _loadingOverlayDebounceTimer;');
    console.log('Added _loadingOverlayDebounceTimer at line', idx+1);
  }
}

// ── Fix 2: Remove leftover old _sendBackendMessage body (lines after new impl) ─
// Find the NEW _sendBackendMessage ending at "  }) async {"
{
  const newEndIdx = findMethodStart(L, /\}\) async \{/);
  if (newEndIdx !== -1) {
    // Find the start of the NEXT proper method after this garbage
    // The garbage starts at the line with "}) async {"
    // Look for the next method signature
    let garbageEnd = -1;
    // Count braces from the "}) async {" line
    let depth = 0;
    let started = false;
    for (let i = newEndIdx; i < L.length; i++) {
      const line = L[i];
      for (const ch of line) {
        if (ch === '{') { depth++; started = true; }
        else if (ch === '}') { depth--; }
      }
      if (started && depth === 0) {
        garbageEnd = i;
        break;
      }
    }
    if (garbageEnd !== -1 && garbageEnd > newEndIdx) {
      console.log(`Removing garbage lines ${newEndIdx+1}-${garbageEnd+1}`);
      L.splice(newEndIdx, garbageEnd - newEndIdx + 1);
    }
  }
}

// ── Fix 3: Replace _connectRealtime if it still has old code ─────────────
L = replaceMethod(L, /Future<void> _connectRealtime\(\) async \{/, `  Future<void> _connectRealtime() async {
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
  }`);

// ── Fix 4: Replace _markReadHttp ─────────────────────────────────────────
L = replaceMethod(L, /Future<void> _markReadHttp\(\) async \{/, `  Future<void> _markReadHttp() async {
    await ref.read(chatRepositoryProvider).markRead(widget.thread.id);
  }`);

// ── Fix 5: Replace _notifyReadCur ────────────────────────────────────────
L = replaceMethod(L, /Future<void> _notifyReadCur\(\) async \{/, `  Future<void> _notifyReadCur() async {
    await _markReadHttp();
  }`);

// ── Fix 6: Replace _applyReadReceipt ─────────────────────────────────────
L = replaceMethod(L, /void _applyReadReceipt\(/, `  void _applyReadReceipt(String threadId, String readerUserId, int readAtEpoch) {
    if (!mounted || threadId != widget.thread.id) return;
    setState(() {
      _messages = _messages.map((m) {
        if (!m.mine || m.readByRecipient) return m;
        return m.copyWith(readByRecipient: true);
      }).toList();
    });
  }`);

// ── Fix 7: Replace _emitTyping ────────────────────────────────────────────
L = replaceMethod(L, /void _emitTyping\(bool hasText\) \{/, `  void _emitTyping(bool hasText) {}`);

// ── Fix 8: Replace _persistMessagesForCache ──────────────────────────────
L = replaceMethod(L, /Future<void> _persistMessagesForCache\(\) async \{/, `  Future<void> _persistMessagesForCache() async {}`);

// ── Fix 9: Replace _schedulePersistMessages ──────────────────────────────
L = replaceMethod(L, /void _schedulePersistMessages\(\) \{/, `  void _schedulePersistMessages() {}`);

// ── Fix 10: Replace _flushOfflineQueueForThread ───────────────────────────
L = replaceMethod(L, /Future<void> _flushOfflineQueueForThread\(\) async \{/, `  Future<void> _flushOfflineQueueForThread() async {}`);

// ── Fix 11: Replace _reloadMessagesFromDiskAfterGlobalSync ───────────────
L = replaceMethod(L, /Future<void> _reloadMessagesFromDiskAfterGlobalSync\(\) async \{/, `  Future<void> _reloadMessagesFromDiskAfterGlobalSync() async {}`);

// ── Fix 12: Replace _shouldFetchRemoteMessages ───────────────────────────
L = replaceMethod(L, /bool _shouldFetchRemoteMessages\(\) \{/, `  bool _shouldFetchRemoteMessages() => true;`);

// ── Fix 13: Replace _hydratePeerIdentity ─────────────────────────────────
L = replaceMethod(L, /Future<void> _hydratePeerIdentity\(\) async \{/, `  Future<void> _hydratePeerIdentity() async {}`);

// ── Fix 14: Replace _loadRemoteMessages ──────────────────────────────────
L = replaceMethod(L, /Future<void> _loadRemoteMessages\(\) async \{/, `  Future<void> _loadRemoteMessages() async {
    final repo = ref.read(chatRepositoryProvider);
    final messages = await repo.fetchMessages(widget.thread.id);
    if (!mounted) return;
    setState(() {
      _messages = List<ChatMessage>.from(messages);
      _loadingRemote = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    _subscribeToRepoEvents();
  }`);

// ── Fix 15: Replace _prefetchPersistentDocuments ─────────────────────────
L = replaceMethod(L, /void _prefetchPersistentDocuments\(List<ChatMessage> msgs\) \{/, `  void _prefetchPersistentDocuments(List<ChatMessage> msgs) {}`);

// ── Fix 16: Replace _sendText ─────────────────────────────────────────────
L = replaceMethod(L, /Future<void> _sendText\(\) async \{/, `  Future<void> _sendText() async {
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
  }`);

// ── Fix 17: Replace _openGalleryMediaChoice ──────────────────────────────
L = replaceMethod(L, /void _openGalleryMediaChoice\(\) \{/, `  void _openGalleryMediaChoice() {
    _runMediaUpload(
      _openWhatsAppGalleryFlow,
      onError: "Echec envoi media",
    );
  }`);

// ── Fix 18: Replace _openWhatsAppGalleryFlow ─────────────────────────────
L = replaceMethod(L, /Future<void> _openWhatsAppGalleryFlow\(\) async \{/, `  Future<void> _openWhatsAppGalleryFlow() async {
    final composed = await Navigator.of(context, rootNavigator: true)
        .push<OklComposedMedia>(
          MaterialPageRoute<OklComposedMedia>(
            builder: (_) => const GalleryPickerScreen(),
          ),
        );
    if (!mounted || composed == null) return;
    final bytes = kIsWeb
        ? (composed.bytes != null ? Uint8List.fromList(composed.bytes!) : Uint8List(0))
        : Uint8List(0);
    final caption = composed.caption.trim();
    final ext = composed.filename.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext);
    if (isVideo) {
      final msg = await ref.read(chatRepositoryProvider).sendVideo(
        widget.thread.id, bytes, composed.filename,
        caption: caption.isEmpty ? null : caption,
      );
      if (mounted && !_messages.any((m) => m.id == msg.id)) {
        setState(() => _messages.add(msg));
        _afterAppend();
      }
    } else {
      final msg = await ref.read(chatRepositoryProvider).sendImage(
        widget.thread.id, bytes, composed.filename,
        caption: caption.isEmpty ? null : caption,
      );
      if (mounted && !_messages.any((m) => m.id == msg.id)) {
        setState(() => _messages.add(msg));
        _afterAppend();
      }
    }
  }`);

// ── Fix 19: Replace _pickAndSendVideoFromCamera ───────────────────────────
L = replaceMethod(L, /Future<void> _pickAndSendVideoFromCamera\(\) async \{/, `  Future<void> _pickAndSendVideoFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.camera);
    if (picked == null) return;
    final bytes = kIsWeb ? await picked.readAsBytes() : Uint8List(0);
    final msg = await ref.read(chatRepositoryProvider).sendVideo(
      widget.thread.id, bytes, picked.name,
    );
    if (mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages.add(msg));
      _afterAppend();
    }
  }`);

// ── Fix 20: Replace _pickAndSendAudioFile ────────────────────────────────
L = replaceMethod(L, /Future<void> _pickAndSendAudioFile\(\) async \{/, `  Future<void> _pickAndSendAudioFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'webm'],
      withData: kIsWeb,
    );
    final f = picked?.files.single;
    if (f == null) return;
    final bytes = kIsWeb ? (f.bytes ?? Uint8List(0)) : Uint8List(0);
    final msg = await ref.read(chatRepositoryProvider).sendAudio(
      widget.thread.id, bytes, f.name,
    );
    if (mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages.add(msg));
      _afterAppend();
    }
  }`);

// ── Fix 21: Replace _pickAndSendDocumentFile ─────────────────────────────
L = replaceMethod(L, /Future<void> _pickAndSendDocumentFile\(\) async \{/, `  Future<void> _pickAndSendDocumentFile() async {
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
      final msg = await ref.read(chatRepositoryProvider).sendFile(
        widget.thread.id, bytes, f.name,
        caption: caption.isEmpty ? null : caption,
      );
      if (mounted && !_messages.any((m) => m.id == msg.id)) {
        setState(() => _messages.add(msg));
        _afterAppend();
      }
    } catch (_) {
      if (mounted) OklFeedback.snack(context, 'Envoi du document impossible');
    }
  }`);

// ── Fix 22: Replace _sendSharedContact ───────────────────────────────────
L = replaceMethod(L, /Future<void> _sendSharedContact\(ChatContact c\) async \{/, `  Future<void> _sendSharedContact(ChatContact c) async {
    final text = '\\u{1F464} Contact: \${c.name}';
    final msg = await ref.read(chatRepositoryProvider).sendText(
      widget.thread.id, text,
    );
    if (mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages.add(msg));
      _afterAppend();
    }
  }`);

// ── Fix 23: Replace _runMediaUpload ──────────────────────────────────────
L = replaceMethod(L, /Future<void> _runMediaUpload\(/, `  Future<void> _runMediaUpload(
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
  }`);

// ── Fix 24: Replace _absoluteMediaUrl ────────────────────────────────────
L = replaceMethod(L, /String _absoluteMediaUrl\(String raw\) \{/, `  String _absoluteMediaUrl(String raw) => raw;`);

// ── Fix 25: Replace _afterAppend ─────────────────────────────────────────
L = replaceMethod(L, /void _afterAppend\(\) \{/, `  void _afterAppend() {
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
        if (lastMine || (_userHasScrolled && isNearBottom)) {
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }`);

// ── Fix 26: Remove remaining isBackendThreadId/WS/API references ──────────
// Replace entire content with symbol removal
let joined = L.join('\n');

// Remove isBackendThreadId import
joined = joined.replace(/import '\.\.\/data\/chat_api_mapping\.dart';\n/g, '');

// Define isBackendThreadId as always false (mock mode)
// Find a good place to add it - after the class state declaration
const stubFn = `
  // Mock mode: no backend thread IDs
  bool isBackendThreadId(String id) => false;
  bool get _isBackendThread => false;
`;

// Add stub after the class opening or after first method
// Find _syncSendState and add before it
joined = joined.replace(
  /void _syncSendState\(\) \{/,
  `${stubFn}\n  void _syncSendState() {`
);

// Remove remaining oklIsDeviceOnline references
joined = joined.replace(/if \(!await oklIsDeviceOnline\(\)\) \{[\s\S]*?\}\s*\n/g, '');
joined = joined.replace(/if \(await oklIsDeviceOnline\(\)\)[\s\S]*?\}\s*\n/g, '');

// Remove remaining OfflineSyncCoordinator references
joined = joined.replace(/OfflineSyncCoordinator\.[^;]+;\n/g, '');
joined = joined.replace(/OfflineSyncCoordinator\.[^;]+\n\s*\.\s*[^;]+;\n/g, '');

// Remove OfflineActionQueue references
joined = joined.replace(/unawaited\(OfflineActionQueue\.[^)]+\)\);\n/g, '');
joined = joined.replace(/await OfflineActionQueue\.[^;]+;\n/g, '');

// Remove OkliforMediaUrl references (replace with identity)
joined = joined.replace(/OkliforMediaUrl\.resolve\(([^)]+)\)/g, '$1');

// Remove persistOkliforLocalFileFromPath/ensureOkliforLocalFile calls
joined = joined.replace(/unawaited\(\s*\n?\s*ensureOkliforLocalFile\([\s\S]*?\)\s*\n\s*\)\s*\);\s*\n/g, '');
joined = joined.replace(/unawaited\(\s*\n?\s*persistOkliforLocalFileFromPath\([\s\S]*?\)\s*\);\s*\n/g, '');
joined = joined.replace(/await ensureOkliforLocalFile\([\s\S]*?\);\s*\n/g, '');
joined = joined.replace(/await persistOkliforLocalFileFromPath\([\s\S]*?\);\s*\n/g, '');

// Remove oklCanUseMessageIdForStorage references
joined = joined.replace(/oklCanUseMessageIdForStorage\([^)]+\)/g, 'false');

// Remove OklMediaBucket references
joined = joined.replace(/bucket: OklMediaBucket\.\w+,\s*\n/g, '');

// Remove chatMessageFromPayload, chatMessagesFromPayloads references
joined = joined.replace(/chatMessageFromPayload\([^)]+\)/g, '_messages.first');
joined = joined.replace(/chatMessagesFromPayloads\([^)]+\)/g, '_messages');

// Remove the upload-related API calls still referencing okliforApiClientProvider
joined = joined.replace(/final upload = await ref\s*\n\s*\.read\(okliforApiClientProvider\)[\s\S]*?;\s*\n/g, '');

// Fix remaining apostrophe issues
joined = joined
  .replace(/'d'envoyer/g, '"d\'envoyer')
  .replace(/'impossible d'/g, '"impossible d\'')
  .replace(/'Pas de connexion[^']*d'[^']*/g, (m) => m.replace(/'/g, '"').replace(/d"/, "d'"))
  .replace(/'l'enregistrement/g, '"l\'enregistrement');

// ── Save ──────────────────────────────────────────────────────────────────
fs.writeFileSync('lib/features/chat/views/conversation_screen.dart', joined, 'utf8');
console.log('\nDone!');
