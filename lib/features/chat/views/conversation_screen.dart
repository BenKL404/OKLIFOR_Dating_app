import 'dart:async';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
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
import '../../../core/utils/okl_pick_media_permissions.dart';
import '../models/chat_models.dart';
import '../providers/chat_providers.dart';
import '../repository/chat_repository.dart';
import 'media_viewer_screen.dart';
import 'chat_thread_detail_screen.dart';
import 'conversation_search_screen.dart';
import 'conversation_media_screen.dart';
import 'conversation_mute_screen.dart';
import 'gallery_picker_screen.dart';
import 'document_compose_screen.dart';
import 'share_contact_screen.dart';
import 'new_message_screen.dart';

final _chatMediaCache = oklChatMediaCache;

Color _chatBg(BuildContext context) => context.oklScaffold;
Color _chatAppBar(BuildContext context) => context.oklSurface;
Color _chatIncomingBubble(BuildContext context) =>
    context.oklSurface.withValues(alpha: 0.92);
Color _chatOutgoingBubble(BuildContext context) =>
    AppColors.primaryDark.withValues(alpha: 0.94);
Color _chatInputBg(BuildContext context) => context.oklSurface;
Color _chatTextPrimary(BuildContext context) => context.oklOnSurface;
Color _chatTextSecondary(BuildContext context) => context.oklOnSurfaceMuted(0.62);

const double _chatBubbleRadius = 18;
const double _chatPillRadius = 999;
const Map<String, List<String>> _emojiKeyboardByCategory = {
  'smileys': ['😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😎', '🤩', '🥳', '😇', '🙂', '🙃', '😉', '🤗', '🤭', '😴', '🤔', '😅', '😭', '😡', '😱', '🤯', '😬', '🥺', '😏', '🤪', '😌', '🫠', '🫡', '🥹', '😤'],
  'gestures': ['👍', '👎', '👏', '🙏', '👌', '🤝', '💪', '🙌', '👋', '🤞', '✌️', '🤟', '🤌', '👊', '✊', '🫶', '🫡', '🤲', '👉', '👈', '☝️', '👇', '🤙', '🖐️', '🤘', '🤏', '🫰', '🫵'],
  'love': ['❤️', '💕', '💖', '💘', '💝', '💞', '💓', '💗', '💟', '💌', '🔥', '✨', '🌹', '🥰', '😍', '😘', '💍', '👩‍❤️‍👨', '💫', '🫶', '🌷', '💐', '🍫', '🎀', '💏', '💑'],
  'fun': ['🔥', '🎉', '🥂', '🍾', '🍻', '🍷', '🍔', '🍕', '🌮', '🍩', '🎵', '🎶', '⚽', '🏆', '🎬', '📸', '🎮', '🌴', '🌊', '☀️', '🌙', '⭐', '🎁', '🚀', '🎯', '🎲', '🎸', '🎤', '🏖️', '🥳'],
};

const Map<String, List<String>> _stickerPacks = {
  'Visages': ['😀', '😂', '🥰', '😎', '🤩', '😭', '🥺', '😏', '🤗', '😤', '🤯', '😴', '🤔', '😅', '🫠', '🥹'],
  'Amour': ['❤️', '💕', '💖', '🥰', '😍', '😘', '💌', '🌹', '🫶', '💏', '💑', '💍', '🌷', '💐', '🍫', '💫'],
  'Fun': ['🎉', '🔥', '✨', '🎊', '🏆', '💪', '🤙', '🎵', '🌈', '⭐', '🎁', '🚀', '🥳', '🎮', '🏖️', '🍕'],
  'Nature': ['🌸', '🌺', '🌻', '🦋', '🐝', '🌴', '🌊', '☀️', '🌙', '⭐', '🌈', '🦜', '🐬', '🦁', '🌿', '🍃'],
};

// Asymmetric "tail" radii — mine has tail on top-right, theirs on top-left.
BorderRadius _bubbleRadius(bool mine) => mine
    ? const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(4),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
      )
    : const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
      );

Border _chatSoftBorder(BuildContext context) => Border.all(
      color: Colors.white.withValues(alpha: 0.06),
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
  final FocusNode _messageFocus = FocusNode();
  final _scrollController = ScrollController();
  bool _userHasScrolled = false;
  double _lastKnownScrollPx = 0;
  bool _canSend = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordTimer;
  late List<ChatMessage> _messages;
  // IDs locaux en attente de confirmation serveur (optimistic send)
  final Set<String> _pendingLocalIds = {};
  // IDs locaux en erreur d'envoi (utilisés pour le retry UI)
  // ignore: unused_field
  final Set<String> _failedLocalIds = {};
  bool _loadingRemote = false;
  Timer? _loadingOverlayDebounceTimer;
  bool _isUploadingMedia = false;
  String? _uploadError;
  bool _peerOnline = false;
  bool _peerTyping = false;
  int? _peerLastSeenEpoch;
  Timer? _peerTypingHideTimer;
  late final AudioRecorder _audioRecorder;
  ChatMessage? _replyingTo;
  final Map<String, String> _messageReactions = <String, String>{};
  String? _resolvedPeerName;
  String? _resolvedPeerAvatarUrl;
  final Set<String> _prefetchedMediaUrls = <String>{};
  StreamSubscription<ChatRepoEvent>? _repoSub;
  String? _currentRecordingPath;
  bool _showEmojiKeyboard = false;
  String _emojiMainTab = 'emoji'; // 'emoji' | 'stickers'
  String _emojiCategory = 'smileys';
  String _stickerPack = 'Visages';
  final List<String> _recentEmojis = <String>[];

  @override
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
  }

  Future<void> _loadRemoteMessages() async {
    final repo = ref.read(chatRepositoryProvider);
    final messages = await repo.fetchMessages(widget.thread.id);
    if (!mounted) return;
    setState(() {
      _messages = List<ChatMessage>.from(messages);
      _loadingRemote = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    await _connectRealtime();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _loadingOverlayDebounceTimer?.cancel();
    _repoSub?.cancel();
    _recordTimer?.cancel();
    _peerTypingHideTimer?.cancel();
    _messageController.removeListener(_syncSendState);
    _messageFocus.dispose();
    _audioRecorder.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _insertEmoji(String emoji) {
    final cur = _messageController.text;
    final selection = _messageController.selection;
    final start = selection.start < 0 ? cur.length : selection.start;
    final end = selection.end < 0 ? cur.length : selection.end;
    final next = cur.replaceRange(start, end, emoji);
    _messageController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    if (_recentEmojis.contains(emoji)) {
      _recentEmojis.remove(emoji);
    }
    _recentEmojis.insert(0, emoji);
    if (_recentEmojis.length > 18) {
      _recentEmojis.removeRange(18, _recentEmojis.length);
    }
    if (mounted) {
      setState(() {
        _emojiCategory = 'recent';
      });
    }
  }

  Future<void> _sendSticker(String sticker) async {
    setState(() => _showEmojiKeyboard = false);
    _messageFocus.canRequestFocus = true;
    final msg = await ref.read(chatRepositoryProvider).sendText(
      widget.thread.id, sticker,
    );
    if (mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages.add(msg));
      _afterAppend();
    }
  }

  void _toggleEmojiKeyboard() {
    if (_showEmojiKeyboard) {
      setState(() => _showEmojiKeyboard = false);
      _messageFocus.canRequestFocus = true;
      _messageFocus.requestFocus();
      return;
    }
    _messageFocus.canRequestFocus = false;
    _messageFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    setState(() => _showEmojiKeyboard = true);
  }

  IconData _emojiCategoryIcon(String key) {
    switch (key) {
      case 'recent':   return LucideIcons.history;
      case 'gestures': return LucideIcons.hand;
      case 'love':     return LucideIcons.heart;
      case 'fun':      return LucideIcons.partyPopper;
      case 'smileys':
      default:         return LucideIcons.smile;
    }
  }

  Widget _buildEmojiKeyboardPanel(BuildContext context) {
    // Ensure _emojiCategory is valid given current recent state
    final validCats = [
      if (_recentEmojis.isNotEmpty) 'recent',
      ..._emojiKeyboardByCategory.keys,
    ];
    if (!validCats.contains(_emojiCategory)) {
      _emojiCategory = _emojiKeyboardByCategory.keys.first;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: context.oklSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: context.oklDivider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Pack tabs (stickers only) ──────────────────────────────────
          if (_emojiMainTab == 'stickers')
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                children: _stickerPacks.keys.map((pack) {
                  final active = pack == _stickerPack;
                  return GestureDetector(
                    onTap: () => setState(() => _stickerPack = pack),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? AppColors.primary.withValues(alpha: 0.45)
                              : context.oklDivider,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pack,
                        style: TextStyle(
                          color: active
                              ? AppColors.primary
                              : context.oklOnSurfaceMuted(0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Content grid ───────────────────────────────────────────────
          SizedBox(
            height: 220,
            child: _emojiMainTab == 'emoji'
                ? GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: (_emojiKeyboardByCategory[_emojiCategory] ??
                            _recentEmojis)
                        .length,
                    itemBuilder: (context, i) {
                      final emojis =
                          _emojiKeyboardByCategory[_emojiCategory] ??
                              _recentEmojis;
                      final emoji = emojis[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _insertEmoji(emoji),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount:
                        (_stickerPacks[_stickerPack] ?? []).length,
                    itemBuilder: (context, i) {
                      final sticker =
                          (_stickerPacks[_stickerPack] ?? [])[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _sendSticker(sticker),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.oklScaffold,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.oklDivider),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            sticker,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── Bottom nav bar ─────────────────────────────────────────────
          Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.oklDivider)),
            ),
            child: Row(
              children: [
                // Category icons (emoji mode only)
                if (_emojiMainTab == 'emoji')
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: validCats.map((cat) {
                        final active = cat == _emojiCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _emojiCategory = cat),
                          child: SizedBox(
                            width: 38,
                            height: 46,
                            child: Icon(
                              _emojiCategoryIcon(cat),
                              size: 18,
                              color: active
                                  ? AppColors.primary
                                  : context.oklOnSurfaceMuted(0.45),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  const Spacer(),

                // Separator
                Container(
                  width: 1,
                  height: 22,
                  color: context.oklDivider,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),

                // Emoji tab button
                GestureDetector(
                  onTap: () => setState(() => _emojiMainTab = 'emoji'),
                  child: Container(
                    width: 44,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: _emojiMainTab == 'emoji'
                        ? BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          )
                        : null,
                    child: Text(
                      '😊',
                      style: TextStyle(
                        fontSize: 20,
                        color: _emojiMainTab == 'emoji'
                            ? null
                            : context.oklOnSurfaceMuted(0.4),
                      ),
                    ),
                  ),
                ),

                // Stickers tab button
                GestureDetector(
                  onTap: () => setState(() => _emojiMainTab = 'stickers'),
                  child: Container(
                    width: 44,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: _emojiMainTab == 'stickers'
                        ? BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          )
                        : null,
                    child: Icon(
                      LucideIcons.sticker,
                      size: 20,
                      color: _emojiMainTab == 'stickers'
                          ? AppColors.primary
                          : context.oklOnSurfaceMuted(0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectRealtime() async {
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
          // Dédupliquer par ID (la bulle locale optimiste a un id local_xxx différent)
          final existsById = _messages.any((m) => m.id == message.id);
          if (!existsById) {
            setState(() => _messages.add(message));
            // Fix #5 — mettre à jour le thread preview pour les messages entrants
            if (!message.mine) {
              widget.onThreadPreviewUpdated?.call(
                _messagePreview(message),
                message.time,
              );
              // Met aussi à jour le state Riverpod pour la liste des threads
              final threads = ref.read(chatThreadsProvider).value ?? [];
              final idx = threads.indexWhere((t) => t.id == widget.thread.id);
              if (idx >= 0) {
                ref.read(chatThreadsProvider.notifier).upsertThread(
                  threads[idx].copyWith(
                    lastMsg: _messagePreview(message),
                    time: message.time,
                    isUnread: true,
                    unreadCount: threads[idx].unreadCount + 1,
                  ),
                );
              }
            }
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
  }

  void _syncSendState() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText == _canSend) return;
    setState(() => _canSend = hasText);
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  /// Scroll fiable vers le bas — deux callbacks pour laisser le layout se stabiliser.
  void _scrollToEndAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  void _popConversationRoot() {
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  void _afterAppend() {
    widget.onThreadPreviewUpdated?.call(
      _messagePreview(_messages.last),
      _messages.last.time,
    );
    _prefetchRecentMedia(_messages);
    final lastMine = _messages.isNotEmpty && _messages.last.mine;
    if (lastMine) {
      _scrollToEndAfterLayout();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        final px = _scrollController.position.pixels;
        if ((max - px) < 160) {
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
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
        return m.text?.trim().isNotEmpty == true
            ? m.text!.trim()
            : '📄 Fichier';
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

      try {
        await _audioRecorder.stop();
      } catch (_) {}

      final path = _currentRecordingPath;
      _currentRecordingPath = null;

      if (!kIsWeb && path != null) {
        final file = File(path);
        if (await file.exists()) {
          setState(() => _isUploadingMedia = true);
          try {
            final bytes = await file.readAsBytes();
            final filename =
                'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
            final msg = await ref.read(chatRepositoryProvider).sendAudio(
                  widget.thread.id,
                  bytes,
                  filename,
                  durationSeconds: seconds,
                );
            if (mounted) {
              setState(() {
                _messages.add(msg);
                _isUploadingMedia = false;
              });
              _afterAppend();
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isUploadingMedia = false);
              OklFeedback.snack(context, 'Envoi impossible : $e');
            }
          } finally {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
      return;
    }

    final allowed = await OklPickMediaPermissions.ensureMicrophone(context);
    if (!allowed) return;

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
      _currentRecordingPath = outPath;
    } catch (e) {
      if (mounted) {
        OklFeedback.snack(
          context,
          "Impossible de démarrer l'enregistrement : $e",
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
        : '\u21aa ${_messagePreview(_replyingTo!)}\n$txt';
    setState(() => _replyingTo = null);
    _messageController.clear();
    _syncSendState();

    // Fix #2 — Optimistic send : bulle locale immédiate
    final localId = _appendLocalMineMessage(
      kind: ChatMessageKind.text,
      text: payload,
    );
    _pendingLocalIds.add(localId);

    try {
      final msg = await ref.read(chatRepositoryProvider).sendText(
        widget.thread.id,
        payload,
      );
      if (!mounted) return;
      // Remplacer la bulle locale par le message serveur
      _replaceLocalMessage(localId, msg);
    } catch (_) {
      if (!mounted) return;
      _markMessageFailed(localId);
    }
  }

  /// Remplace un message local (optimiste) par le message confirmé par le serveur.
  void _replaceLocalMessage(String localId, ChatMessage serverMsg) {
    setState(() {
      _pendingLocalIds.remove(localId);
      final idx = _messages.indexWhere((m) => m.id == localId);
      if (idx >= 0) {
        _messages[idx] = serverMsg;
      } else if (!_messages.any((m) => m.id == serverMsg.id)) {
        _messages.add(serverMsg);
      }
    });
  }

  /// Marque un message local comme échoué (❌).
  void _markMessageFailed(String localId) {
    setState(() {
      _pendingLocalIds.remove(localId);
      _failedLocalIds.add(localId);
      _messages.removeWhere((m) => m.id == localId);
    });
    OklFeedback.snack(context, 'Envoi échoué');
  }

  void _openGalleryMediaChoice() {
    _runMediaUpload(_openGalleryFlow, onError: 'Échec envoi media');
  }

  void _openCameraMediaChoice() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: _chatAppBar(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _chatTextSecondary(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              _CameraChoiceTile(
                icon: LucideIcons.camera,
                label: 'Photo',
                sub: 'Prendre une photo',
                onTap: () {
                  Navigator.pop(ctx);
                  _runMediaUpload(
                    _pickAndSendImageFromCamera,
                    onError: 'Échec de la prise de photo',
                  );
                },
              ),
              const SizedBox(height: 10),
              _CameraChoiceTile(
                icon: LucideIcons.video,
                label: 'Vidéo',
                sub: 'Enregistrer une vidéo',
                onTap: () {
                  Navigator.pop(ctx);
                  _runMediaUpload(
                    _pickAndSendVideoFromCamera,
                    onError: 'Échec de l\'envoi vidéo',
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGalleryFlow() async {
    final composed = await Navigator.of(context, rootNavigator: true)
        .push<OklComposedMedia>(
          MaterialPageRoute<OklComposedMedia>(
            builder: (_) => const GalleryPickerScreen(),
          ),
        );
    if (!mounted || composed == null) return;

    // Bytes are always populated by MediaComposeScreen now
    final bytes = composed.bytes != null && composed.bytes!.isNotEmpty
        ? Uint8List.fromList(composed.bytes!)
        : Uint8List(0);

    if (bytes.isEmpty) {
      OklFeedback.snack(context, 'Impossible de lire le fichier sélectionné');
      return;
    }

    final caption = composed.caption.trim();

    if (composed.isVideo) {
      final localId = _appendLocalMineMessage(
        kind: ChatMessageKind.video,
        text: caption.isEmpty ? null : caption,
      );
      _pendingLocalIds.add(localId);
      try {
        final msg = await ref.read(chatRepositoryProvider).sendVideo(
          widget.thread.id, bytes, composed.filename,
          caption: caption.isEmpty ? null : caption,
        );
        if (mounted) _replaceLocalMessage(localId, msg);
      } catch (e, st) {
        if (mounted) {
          _markMessageFailed(localId);
          OklFeedback.snack(context, 'Erreur envoi vidéo: $e');
          debugPrint('Send Video Error: $e\n$st');
        }
      }
    } else {
      final localId = _appendLocalMineMessage(
        kind: ChatMessageKind.image,
        text: caption.isEmpty ? null : caption,
      );
      _pendingLocalIds.add(localId);
      try {
        final msg = await ref.read(chatRepositoryProvider).sendImage(
          widget.thread.id, bytes, composed.filename,
          caption: caption.isEmpty ? null : caption,
        );
        if (mounted) _replaceLocalMessage(localId, msg);
      } catch (e, st) {
        if (mounted) {
          _markMessageFailed(localId);
          OklFeedback.snack(context, 'Erreur envoi image: $e');
          debugPrint('Send Image Error: $e\n$st');
        }
      }
    }
  }


  Future<void> _pickAndSendImageFromCamera() async {
    final canUse = await OklPickMediaPermissions.ensureImageSource(
      context,
      ImageSource.camera,
    );
    if (!canUse || !mounted) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    // Fix #1+6 — lire les bytes sur toutes les plateformes
    final bytes = await picked.readAsBytes();
    final localId = _appendLocalMineMessage(kind: ChatMessageKind.image);
    _pendingLocalIds.add(localId);
    try {
      final msg = await ref.read(chatRepositoryProvider).sendImage(
        widget.thread.id, bytes, picked.name,
      );
      if (mounted) _replaceLocalMessage(localId, msg);
    } catch (_) {
      if (mounted) _markMessageFailed(localId);
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
                        onError: "Échec de l'envoi document",
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _openCameraMediaChoice();
                      });
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
                      _appendLocalMineMessage(
                      kind: ChatMessageKind.location,
                      locationLabel: 'Boulevard du 13 janvier, Lomé',
                    );
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
                              _sendSharedContact(c);
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
                      _runMediaUpload(
                        _pickAndSendAudioFile,
                        onError: "Echec de l'envoi audio",
                      );
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

  String _absoluteMediaUrl(String raw) => raw;

  Future<Uint8List> _readPlatformFileBytes(PlatformFile f) async {
    final b = f.bytes;
    if (b != null && b.isNotEmpty) return b;
    final p = f.path;
    if (p != null && p.isNotEmpty) {
      final file = File(p);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) return bytes;
      }
    }
    final stream = f.readStream;
    if (stream != null) {
      final chunks = <int>[];
      await for (final chunk in stream) {
        chunks.addAll(chunk);
      }
      if (chunks.isNotEmpty) return Uint8List.fromList(chunks);
    }
    return Uint8List(0);
  }

  String _appendLocalMineMessage({
    required ChatMessageKind kind,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    int? voiceSeconds,
    String? fileUrl,
    String? locationLabel,
  }) {
    final id = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final msg = ChatMessage(
      id: id,
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
    return id;
  }

  Future<void> _pickAndSendVideoFromCamera() async {
    final canUseCamera = await OklPickMediaPermissions.ensureImageSource(
      context,
      ImageSource.camera,
    );
    if (!canUseCamera) return;
    if (!mounted) return;
    final canUseMicrophone = await OklPickMediaPermissions.ensureMicrophone(
      context,
    );
    if (!canUseMicrophone) return;

    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.camera);
    if (picked == null) return;
    // Fix #1+6 — lire les bytes sur toutes les plateformes
    final bytes = await picked.readAsBytes();
    final localId = _appendLocalMineMessage(kind: ChatMessageKind.video);
    _pendingLocalIds.add(localId);
    try {
      final msg = await ref.read(chatRepositoryProvider).sendVideo(
        widget.thread.id, bytes, picked.name,
      );
      if (mounted) _replaceLocalMessage(localId, msg);
    } catch (_) {
      if (mounted) _markMessageFailed(localId);
    }
  }

  Future<void> _pickAndSendAudioFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'webm'],
      withData: true,   // Fix #1 — toujours charger les bytes
    );
    final f = picked?.files.single;
    if (f == null) return;
    final bytes = await _readPlatformFileBytes(f);
    if (bytes.isEmpty) {
      if (!mounted) return;
      OklFeedback.snack(context, 'Fichier audio illisible');
      return;
    }
    final localId = _appendLocalMineMessage(kind: ChatMessageKind.voice);
    _pendingLocalIds.add(localId);
    try {
      final msg = await ref.read(chatRepositoryProvider).sendAudio(
        widget.thread.id, bytes, f.name,
      );
      if (mounted) _replaceLocalMessage(localId, msg);
    } catch (_) {
      if (mounted) _markMessageFailed(localId);
    }
  }

  Future<void> _pickAndSendDocumentFile() async {
    // Document mode: accepter tout type, y compris gros fichiers (stream/path/bytes).
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
      withReadStream: true,
    );
    final f = picked?.files.single;
    if (f == null) return;
    if (!mounted) return;
    final composed = await Navigator.of(context, rootNavigator: true)
        .push<DocumentComposeResult>(
          MaterialPageRoute<DocumentComposeResult>(
            builder: (_) => DocumentComposeScreen(file: f),
          ),
        );
    if (!mounted || composed == null) return;
    final bytes = await _readPlatformFileBytes(f);
    if (bytes.isEmpty) {
      if (!mounted) return;
      OklFeedback.snack(context, 'Fichier document illisible');
      return;
    }
    final caption = composed.caption.trim();
    final localId = _appendLocalMineMessage(
      kind: ChatMessageKind.file,
      text: caption.isEmpty ? f.name : caption,
    );
    _pendingLocalIds.add(localId);
    try {
      final msg = await ref.read(chatRepositoryProvider).sendFile(
        widget.thread.id, bytes, f.name,
        caption: caption.isEmpty ? null : caption,
      );
      if (mounted) _replaceLocalMessage(localId, msg);
    } catch (_) {
      if (mounted) _markMessageFailed(localId);
    }
  }

  Future<void> _sendSharedContact(ChatContact c) async {
    final text = '\u{1F464} Contact: ${c.name}';
    final msg = await ref.read(chatRepositoryProvider).sendText(
      widget.thread.id, text,
    );
    if (mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages.add(msg));
      _afterAppend();
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
    });
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _uploadError = null;
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

  void _openMediaViewer(ChatMessage message) {
    final mediaMsgs = _messages.where((m) => m.kind == ChatMessageKind.image || m.kind == ChatMessageKind.video).toList();
    if (mediaMsgs.isEmpty) return;
    var initialIndex = mediaMsgs.indexWhere((m) => m.id == message.id);
    if (initialIndex < 0) {
      mediaMsgs.add(message);
      initialIndex = mediaMsgs.length - 1;
    }
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MediaViewerScreen(
          messages: mediaMsgs,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _clearConversation() async {
    final snapshot = List<ChatMessage>.from(_messages);
    setState(() {
      _messages.clear();
      _replyingTo = null;
    });
    try {
      final deletable = snapshot.where((m) => m.mine).toList(growable: false);
      for (final m in deletable) {
        await ref.read(chatRepositoryProvider).deleteMessage(widget.thread.id, m.id);
      }
      if (!mounted) return;
      OklFeedback.snack(context, 'Conversation vidée');
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages = snapshot);
      OklFeedback.snack(context, 'Vidage impossible');
    }
  }

  Future<void> _deleteConversation() async {
    final threads = ref.read(chatThreadsProvider).value ?? [];
    final idx = threads.indexWhere((t) => t.id == widget.thread.id);
    final ChatThread? existing = idx >= 0 ? threads[idx] : null;
    ref.read(chatThreadsProvider.notifier).removeThread(widget.thread.id);
    try {
      await ref.read(chatRepositoryProvider).deleteThread(widget.thread.id);
      if (!mounted) return;
      unawaited(ref.read(chatThreadsProvider.notifier).refresh());
      OklFeedback.snack(context, 'Discussion supprimée');
      _popConversationRoot();
    } catch (_) {
      if (!mounted) return;
      if (existing != null) {
        ref.read(chatThreadsProvider.notifier).upsertThread(existing);
      }
      OklFeedback.snack(context, 'Suppression impossible');
    }
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
            ListTile(
              leading: Icon(
                LucideIcons.eraser,
                color:
                    Theme.of(ctx).textTheme.bodyMedium?.color ??
                    ctx.oklOnSurfaceMuted(0.62),
              ),
              title: Text(
                'Vider la conversation',
                style: TextStyle(color: ctx.oklOnSurface),
              ),
              onTap: () {
                Navigator.pop(ctx);
                OklFeedback.confirm(
                  context,
                  title: 'Vider la conversation ?',
                  body: 'Les messages affichés seront supprimés.',
                  confirmLabel: 'Vider',
                  onConfirm: () => _clearConversation(),
                );
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.trash2,
                color: AppColors.togoRed,
              ),
              title: Text(
                'Supprimer la discussion',
                style: TextStyle(color: AppColors.togoRed),
              ),
              onTap: () {
                Navigator.pop(ctx);
                OklFeedback.confirm(
                  context,
                  title: 'Supprimer la discussion ?',
                  body: 'La conversation entière sera supprimée.',
                  confirmLabel: 'Supprimer',
                  onConfirm: () => _deleteConversation(),
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
        backgroundColor: _chatBg(context),
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: _chatAppBar(context),
          foregroundColor: _chatTextPrimary(context),
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
                              color: _chatTextPrimary(context),
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
                                  ? _chatTextSecondary(context)
                                  : (_peerTyping
                                        ? AppColors.green
                                        : (_peerOnline
                                              ? AppColors.green
                                              : _chatTextSecondary(context))),
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
                    cacheExtent: 1200,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
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
                                color: _chatAppBar(context).withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(_chatPillRadius),
                              ),
                              child: Text(
                                "Aujourd'hui",
                                style: TextStyle(
                                  color: _chatTextSecondary(context),
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
                          child: RepaintBoundary(
                            child: _SwipeReplyMessage(
                              message: msg,
                              onReply: () {
                                HapticFeedback.selectionClick();
                                setState(() => _replyingTo = msg);
                              },
                              child: GestureDetector(
                                onLongPress: () => _openMessageActions(msg),
                                child: _RichMessageBubble(
                                  message: msg,
                                  peerDisplayName: widget.thread.name,
                                  peerAvatarUrl: widget.thread.avatarUrl,
                                  reactionEmoji: _messageReactions[msg.id],
                                isPending: _pendingLocalIds.contains(msg.id),
                                  onTapMedia: msg.kind == ChatMessageKind.image || msg.kind == ChatMessageKind.video
                                      ? () => _openMediaViewer(msg)
                                      : null,
                                  onMessageMenu: _openMessageActions,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  maintainBottomViewPadding: true,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      10, 6, 10,
                      10 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_replyingTo != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2C34),
                                borderRadius: BorderRadius.circular(12),
                                border: _chatSoftBorder(context),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 3.5,
                                    height: 42,
                                    margin: const EdgeInsets.only(
                                      right: 8,
                                      top: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(_chatPillRadius),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _replyingTo!.mine
                                              ? 'Vous'
                                              : widget.thread.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _messagePreview(_replyingTo!),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.82,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _replyingTo = null),
                                    icon: const Icon(
                                      LucideIcons.x,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox.shrink(),
              
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _chatInputBg(context),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _toggleEmojiKeyboard,
                                icon: Icon(
                                  _showEmojiKeyboard
                                      ? LucideIcons.keyboard
                                      : LucideIcons.smile,
                                  size: 18,
                                  color: _chatTextSecondary(context),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(_chatPillRadius),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _chatInputBg(context),
                                    borderRadius: BorderRadius.circular(_chatPillRadius),
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    focusNode: _messageFocus,
                                    readOnly:
                                        _isRecording ||
                                        _isUploadingMedia ||
                                        _showEmojiKeyboard,
                                    style: TextStyle(color: _chatTextPrimary(context)),
                                    decoration: InputDecoration(
                                      hintText: _isRecording
                                          ? 'Enregistrement… ${_formatDuration(_recordingSeconds)}'
                                          : 'Message…',
                                      hintStyle: TextStyle(
                                        color: _chatTextSecondary(context),
                                      ),
                                      isDense: true,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      border: InputBorder.none,
                                      suffixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
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
                                                color: _chatTextSecondary(context),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            GestureDetector(
                                              onTap: _isUploadingMedia
                                                  ? null
                                                  : _openCameraMediaChoice,
                                              child: Icon(
                                                LucideIcons.camera,
                                                size: 18,
                                                color: _chatTextSecondary(context),
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
                                    onTap: () {
                                      if (_showEmojiKeyboard) {
                                        setState(() => _showEmojiKeyboard = false);
                                        _messageFocus.canRequestFocus = true;
                                        _messageFocus.requestFocus();
                                      }
                                    },
                                    onTapOutside: (_) {
                                      if (_showEmojiKeyboard) return;
                                      _messageFocus.unfocus();
                                    },
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
                                    : _chatInputBg(context),
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
                // Emoji / sticker keyboard panel — inline under composer
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: _showEmojiKeyboard ? 312 : 0,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: 312,
                      child: SizedBox(
                        height: 312,
                        child: _buildEmojiKeyboardPanel(context),
                      ),
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
      final repo = ref.read(chatRepositoryProvider);
      final thread = await repo.createDirectThread(c.id);
      await repo.sendText(thread.id, _messagePreview(m));
      if (!mounted) return;
      OklFeedback.snack(context, 'Message transféré à ${c.name}');
    } catch (_) {
      if (!mounted) return;
      OklFeedback.snack(context, 'Transfert impossible');
    }
  }

  // ignore: unused_element
  Future<String?> _editForwardDocumentCaption({
    required String fileName,
    required String initialCaption,
  }) async {
    final controller = TextEditingController(text: initialCaption);
    final result = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ctx.oklOnSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ajouter / modifier la légende',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text('Transférer'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  // ignore: unused_element
  Future<String?> _editForwardMediaCaption({
    required String title,
    required String initialCaption,
  }) async {
    final controller = TextEditingController(text: initialCaption);
    final result = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ctx.oklOnSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ajouter / modifier la légende',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text('Transférer'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final index = _messages.indexWhere((x) => x.id == message.id);
    if (index < 0) return;
    setState(() {
      _messages.removeAt(index);
      if (_replyingTo?.id == message.id) {
        _replyingTo = null;
      }
    });
    try {
      await ref.read(chatRepositoryProvider).deleteMessage(
            widget.thread.id,
            message.id,
          );
      if (!mounted) return;
      OklFeedback.snack(context, 'Message supprimé');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.insert(index.clamp(0, _messages.length), message);
      });
      OklFeedback.snack(context, 'Suppression impossible');
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
                          borderRadius: BorderRadius.circular(_chatPillRadius),
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
                              borderRadius: BorderRadius.circular(_chatPillRadius),
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
                unawaited(_deleteMessage(m));
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
  if (firstLine.isEmpty) return 'Document';
  // Avoid exposing technical generated names (ex: file_1774304985828.pdf).
  final genericGenerated = RegExp(
    r'^(file|img|image|video|audio|voice)[_-]?\d+(\.[a-z0-9]+)?$',
    caseSensitive: false,
  );
  if (genericGenerated.hasMatch(firstLine)) {
    final ext = _fileExt(firstLine);
    return ext.isEmpty ? 'Document' : 'Document.$ext';
  }
  return firstLine;
}

String _documentCaption(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return '';
  final noIcon = s.replaceFirst(RegExp(r'^📄\s*'), '').trim();
  final parts = noIcon.split('\n');
  if (parts.length <= 1) return '';
  return parts.sublist(1).join('\n').trim();
}

class _ReplyPayload {
  final String? repliedPreview;
  final String body;

  const _ReplyPayload({required this.repliedPreview, required this.body});
}

_ReplyPayload _splitReplyPayload(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return const _ReplyPayload(repliedPreview: null, body: '');
  if (!text.startsWith('↪')) {
    return _ReplyPayload(repliedPreview: null, body: text);
  }
  final noArrow = text.replaceFirst(RegExp(r'^↪\s*'), '');
  final firstNl = noArrow.indexOf('\n');
  if (firstNl <= 0) {
    return _ReplyPayload(repliedPreview: null, body: text);
  }
  final preview = noArrow.substring(0, firstNl).trim();
  final body = noArrow.substring(firstNl + 1).trim();
  return _ReplyPayload(
    repliedPreview: preview.isEmpty ? null : preview,
    body: body,
  );
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

IconData _documentIconForFileName(String name) {
  final lower = name.toLowerCase().trim();
  // Images
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.heic')) {
    return LucideIcons.fileImage;
  }

  // Video
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.3gp')) {
    return LucideIcons.fileVideo;
  }

  // Audio
  if (lower.endsWith('.m4a') ||
      lower.endsWith('.mp3') ||
      lower.endsWith('.aac') ||
      lower.endsWith('.wav') ||
      lower.endsWith('.ogg') ||
      lower.endsWith('.flac') ||
      lower.endsWith('.opus')) {
    return LucideIcons.fileAudio;
  }

  // Archives
  if (lower.endsWith('.zip') ||
      lower.endsWith('.rar') ||
      lower.endsWith('.7z') ||
      lower.endsWith('.tar') ||
      lower.endsWith('.gz') ||
      lower.endsWith('.bz2')) {
    return LucideIcons.fileArchive;
  }

  // Spreadsheet
  if (lower.endsWith('.xls') ||
      lower.endsWith('.xlsx') ||
      lower.endsWith('.csv') ||
      lower.endsWith('.ods')) {
    return LucideIcons.fileSpreadsheet;
  }

  // Code / data
  if (lower.endsWith('.json') ||
      lower.endsWith('.xml') ||
      lower.endsWith('.yaml') ||
      lower.endsWith('.yml') ||
      lower.endsWith('.txt') ||
      lower.endsWith('.log') ||
      lower.endsWith('.md') ||
      lower.endsWith('.dart') ||
      lower.endsWith('.js') ||
      lower.endsWith('.ts') ||
      lower.endsWith('.java') ||
      lower.endsWith('.kt') ||
      lower.endsWith('.swift') ||
      lower.endsWith('.py') ||
      lower.endsWith('.sql') ||
      lower.endsWith('.html') ||
      lower.endsWith('.css')) {
    return LucideIcons.fileCode;
  }

  // Documents
  if (lower.endsWith('.pdf') ||
      lower.endsWith('.doc') ||
      lower.endsWith('.docx') ||
      lower.endsWith('.ppt') ||
      lower.endsWith('.pptx')) {
    return LucideIcons.fileText;
  }

  return LucideIcons.file;
}

({String label, Color color}) _documentBadgeForFileName(String name) {
  final lower = name.toLowerCase().trim();
  // Palette alignée app (Togo + primary).
  if (lower.endsWith('.pdf')) return (label: 'PDF', color: AppColors.togoRed);
  if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
    return (label: 'DOC', color: AppColors.primary);
  }
  if (lower.endsWith('.xls') ||
      lower.endsWith('.xlsx') ||
      lower.endsWith('.csv') ||
      lower.endsWith('.ods')) {
    return (label: 'XLS', color: AppColors.togoGreen);
  }
  if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
    return (label: 'PPT', color: AppColors.secondary);
  }
  if (lower.endsWith('.zip') ||
      lower.endsWith('.rar') ||
      lower.endsWith('.7z') ||
      lower.endsWith('.tar') ||
      lower.endsWith('.gz') ||
      lower.endsWith('.bz2')) {
    return (label: 'ZIP', color: AppColors.togoGoldOnLight);
  }
  if (lower.endsWith('.m4a') ||
      lower.endsWith('.mp3') ||
      lower.endsWith('.aac') ||
      lower.endsWith('.wav') ||
      lower.endsWith('.ogg') ||
      lower.endsWith('.flac') ||
      lower.endsWith('.opus')) {
    return (label: 'AUD', color: AppColors.blue);
  }
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.3gp')) {
    return (label: 'VID', color: AppColors.secondary);
  }
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.heic')) {
    return (label: 'IMG', color: AppColors.primaryDark);
  }
  return (label: 'FILE', color: const Color(0xFF607D8B));
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
  bool? _isPersisted;
  int _persistCheckSeq = 0;

  String get _rawUrl => (widget.message.fileUrl ?? '').trim();
  String get _resolvedUrl => _rawUrl;
  bool get _openable => _rawUrl.isNotEmpty;
  // ignore: unused_element
  String? get _storageObjectId => null;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshPersistedState());
  }

  @override
  void didUpdateWidget(covariant _DocumentMessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prevUrl = (oldWidget.message.fileUrl ?? '').trim();
    if (prevUrl != _rawUrl || oldWidget.message.id != widget.message.id) {
      _isPersisted = null;
      unawaited(_refreshPersistedState());
    }
  }

  Future<void> _refreshPersistedState() async {
    final seq = ++_persistCheckSeq;
    final value = await _persisted();
    if (!mounted) return;
    if (seq != _persistCheckSeq) return;
    // Once we know it's persisted, don't "downgrade" to avoid UI flicker.
    if (_isPersisted == true && value == false) return;
    if (_isPersisted == value) return;
    setState(() => _isPersisted = value);
  }

  Future<bool> _persisted() async {
    if (!_openable) return false;
    try {
      final info = await _chatMediaCache.getFileFromCache(_resolvedUrl);
      return info != null;
    } catch (_) {
      return false;
    }
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
      await launchChatAttachmentUrl(context, _rawUrl, displayName: title);
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

  void _showDocumentLongPressActions() {
    if (!_openable || kIsWeb) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111B21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ListTile(
          leading: const Icon(LucideIcons.save, color: Colors.white),
          title: const Text(
            'Enregistrer',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () {
            Navigator.of(ctx).pop();
            unawaited(_saveToDownloads());
          },
        ),
      ),
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
                        if (mounted) {
              setState(() {
                _isPersisted = true;
              });
            }
          } catch (_) {}
          if (openAfter) {
            final title = _cleanDocumentLabel(widget.message.text);
            try {
              final result = await OpenFilex.open(
                event.file.path,
                type: _mimeFromFileName(title),
              );
              if (result.type != ResultType.done && mounted) {
                await launchChatAttachmentUrl(
                  context,
                  _rawUrl,
                  displayName: title,
                );
              }
            } catch (_) {
              if (mounted) {
                await launchChatAttachmentUrl(
                  context,
                  _rawUrl,
                  displayName: title,
                );
              }
            }
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
    final hasCaption = caption.isNotEmpty;
    final badge = _documentBadgeForFileName(title);
    final fallbackIcon = _documentIconForFileName(title);
    final bg = m.mine ? _chatOutgoingBubble(context) : _chatIncomingBubble(context);
    final border = _chatSoftBorder(context);

    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: !_openable || _downloading
                ? null
                : () {
                    if (_isPersisted == true) {
                      unawaited(_openCachedOrDownload());
                    } else {
                      _startDownload(openAfter: false);
                    }
                  },
            onLongPress: _openable ? _showDocumentLongPressActions : null,
            borderRadius: BorderRadius.circular(_chatBubbleRadius),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(_chatBubbleRadius),
                border: border,
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: m.mine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: badge.color.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: badge.color.withValues(alpha: 0.42),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: badge.label == 'FILE'
                            ? Icon(
                                fallbackIcon,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                              )
                            : Text(
                                badge.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: badge.label.length <= 2
                                      ? 13
                                      : badge.label.length <= 3
                                          ? 11
                                          : 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
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
                              if (_totalBytes != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _formatBytes(_totalBytes!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.68),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!_openable || kIsWeb)
                        _DocActionIcon(
                          icon: LucideIcons.alertCircle,
                          onTap: null,
                          tooltip: 'Indisponible',
                        )
                      else if (_downloading)
                        _DocProgressRing(value: _progress)
                      else if (_isPersisted == true)
                        _DocActionIcon(
                          icon: LucideIcons.externalLink,
                          tooltip: 'Ouvrir',
                          onTap: () => unawaited(_openCachedOrDownload()),
                        )
                      else
                        _DocActionIcon(
                          icon: LucideIcons.download,
                          tooltip: 'Télécharger',
                          onTap: () => _startDownload(openAfter: false),
                        ),
                    ],
                  ),
                  if (hasCaption)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        caption,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
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

class _SwipeReplyMessage extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onReply;
  final Widget child;

  const _SwipeReplyMessage({
    required this.message,
    required this.onReply,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    return Dismissible(
      key: ValueKey('reply_swipe_${message.id}'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.14},
      movementDuration: const Duration(milliseconds: 150),
      resizeDuration: null,
      confirmDismiss: (direction) async {
        onReply();
        return false;
      },
      background: Container(
        margin: EdgeInsets.only(left: mine ? 44 : 6, right: mine ? 6 : 44),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          LucideIcons.reply,
          size: 18,
          color: AppColors.primary.withValues(alpha: 0.9),
        ),
      ),
      child: child,
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
            border: _chatSoftBorder(context),
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
  final bool isPending;
  final VoidCallback? onTapMedia;
  final void Function(ChatMessage m)? onMessageMenu;

  const _RichMessageBubble({
    required this.message,
    required this.peerDisplayName,
    required this.peerAvatarUrl,
    this.reactionEmoji,
    this.isPending = false,
    this.onTapMedia,
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
          if (m.mine && isPending) {
            return Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: MediaQuery.sizeOf(context).width * 0.72,
                height: 260,
                decoration: BoxDecoration(
                  color: _chatOutgoingBubble(context),
                  borderRadius: BorderRadius.circular(_chatBubbleRadius),
                  border: Border.all(color: context.oklDivider),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        LucideIcons.image,
                        size: 36,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 0.8,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                          LucideIcons.clock3,
                          size: 10,
                          color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Align(
            alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.72,
              height: 260,
              decoration: BoxDecoration(
                color: m.mine ? _chatOutgoingBubble(context) : _chatIncomingBubble(context),
                borderRadius: BorderRadius.circular(_chatBubbleRadius),
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
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: m.mine ? _chatOutgoingBubble(context) : _chatIncomingBubble(context),
              borderRadius: BorderRadius.circular(_chatBubbleRadius),
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

        final img = CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: _chatMediaCache,
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
          memCacheWidth: 520,
          placeholder: (c, u) =>
              Container(
                width: double.infinity,
                height: 260,
                color: _chatIncomingBubble(context),
              ),
          errorWidget: (c, u, e) => imageErrorBox(),
        );
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                ),
                decoration: BoxDecoration(
                  color: m.mine
                      ? _chatOutgoingBubble(context)
                      : _chatIncomingBubble(context),
                  borderRadius: BorderRadius.circular(_chatBubbleRadius),
                  border: Border.all(color: context.oklDivider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTapMedia,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(_chatBubbleRadius),
                          topRight: Radius.circular(_chatBubbleRadius),
                          bottomLeft: Radius.circular(
                              (m.text ?? '').isEmpty ? _chatBubbleRadius : 0),
                          bottomRight: Radius.circular(
                              (m.text ?? '').isEmpty ? _chatBubbleRadius : 0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(_chatBubbleRadius),
                            topRight: Radius.circular(_chatBubbleRadius),
                            bottomLeft: Radius.circular(
                                (m.text ?? '').isEmpty ? _chatBubbleRadius : 0),
                            bottomRight: Radius.circular(
                                (m.text ?? '').isEmpty ? _chatBubbleRadius : 0),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Hero(tag: heroTag, child: img),
                              if (m.mine && isPending)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.52),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.clock3,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if ((m.text ?? '').isEmpty)
                                Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius:
                                        BorderRadius.circular(_chatPillRadius),
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
                    ),
                    if ((m.text ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (m.text ?? '').trim(),
                              style: TextStyle(
                                color: m.mine
                                    ? Colors.white
                                    : context.oklOnSurface,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  m.time,
                                  style: TextStyle(
                                    color: m.mine
                                        ? Colors.white.withValues(alpha: 0.65)
                                        : context.oklOnSurfaceMuted(0.5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
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
                  ],
                ),
              ),
              if (reactionEmoji != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _chatIncomingBubble(context),
                      borderRadius: BorderRadius.circular(_chatPillRadius),
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
        if (m.mine && isPending && (m.videoUrl ?? '').trim().isEmpty) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.72,
              height: 220,
              decoration: BoxDecoration(
                color: _chatOutgoingBubble(context),
                borderRadius: BorderRadius.circular(_chatBubbleRadius),
                border: Border.all(color: context.oklDivider),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      LucideIcons.video,
                      size: 34,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.52),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 0.8,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.clock3,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _VideoMessageBubble(
          message: m,
          peerDisplayName: peerDisplayName,
          peerAvatarUrl: peerAvatarUrl,
          reactionEmoji: reactionEmoji,
          onTapVideo: onTapMedia,
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
              borderRadius: BorderRadius.circular(_chatBubbleRadius),
              border: Border.all(color: context.oklDivider),
            ),
            child: Column(
              crossAxisAlignment: m.mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
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
        final bg =
            m.mine ? _chatOutgoingBubble(context) : _chatIncomingBubble(context);
        final parsed = _splitReplyPayload(m.text);
        final hasReply = parsed.repliedPreview != null;
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
                  borderRadius: BorderRadius.circular(_chatBubbleRadius),
                  border: Border.all(color: context.oklDivider),
                ),
                child: Column(
                  crossAxisAlignment: m.mine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (hasReply)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: _chatSoftBorder(context),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              height: 28,
                              margin: const EdgeInsets.only(right: 7, top: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(_chatPillRadius),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                parsed.repliedPreview!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      parsed.body,
                      style: TextStyle(
                        color: m.mine
                            ? Colors.white.withValues(alpha: 0.96)
                            : _chatTextPrimary(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.time,
                          style: TextStyle(
                            color: m.mine
                                ? Colors.white.withValues(alpha: 0.72)
                                : _chatTextSecondary(context),
                            fontSize: 10,
                          ),
                        ),
                        if (m.mine) ...[
                          const SizedBox(width: 4),
                          _ReadReceiptTicks(message: m, forDarkBackground: true),
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
                      borderRadius: BorderRadius.circular(_chatPillRadius),
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
  final VoidCallback? onTapVideo;
  const _VideoMessageBubble({
    required this.message,
    required this.peerDisplayName,
    required this.peerAvatarUrl,
    this.reactionEmoji,
    this.onTapVideo,
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
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          decoration: BoxDecoration(
            color: m.mine
                ? _chatOutgoingBubble(context)
                : _chatIncomingBubble(context),
            borderRadius: BorderRadius.circular(_chatBubbleRadius),
            border: Border.all(color: context.oklDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: onTapVideo,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_chatBubbleRadius),
                    topRight: Radius.circular(_chatBubbleRadius),
                    bottomLeft: Radius.circular(
                        (m.text ?? '').isEmpty ? _chatBubbleRadius : 0),
                    bottomRight: Radius.circular(
                        (m.text ?? '').isEmpty ? _chatBubbleRadius : 0),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _VideoCoverFrame(
                          videoUrl: videoUrl,
                          fallbackImageUrl: m.imageUrl,
                        ),
                        Container(color: Colors.black.withValues(alpha: 0.22)),
                        const Align(
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.playCircle,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        // Time/Receipts on top ONLY if NO text
                        if ((m.text ?? '').isEmpty) ...[
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius:
                                    BorderRadius.circular(_chatPillRadius),
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
                      ],
                    ),
                  ),
                ),
              ),
              if ((m.text ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (m.text ?? '').trim(),
                        style: TextStyle(
                          color: m.mine
                              ? Colors.white
                              : context.oklOnSurface,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            m.time,
                            style: TextStyle(
                              color: m.mine
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : context.oklOnSurfaceMuted(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
          if (reactionEmoji != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.oklSurface,
                  borderRadius: BorderRadius.circular(_chatPillRadius),
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

class _VideoCoverFrame extends StatefulWidget {
  final String videoUrl;
  final String? fallbackImageUrl;

  const _VideoCoverFrame({
    required this.videoUrl,
    required this.fallbackImageUrl,
  });

  @override
  State<_VideoCoverFrame> createState() => _VideoCoverFrameState();
}

class _VideoCoverFrameState extends State<_VideoCoverFrame> {
  VideoPlayerController? _controller;
  bool _loadFailed = false;
  Duration? _videoDuration;

  bool get _hasFallbackImage =>
      (widget.fallbackImageUrl ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasFallbackImage) {
      unawaited(_initVideoFrame());
    }
  }

  @override
  void didUpdateWidget(covariant _VideoCoverFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.fallbackImageUrl != widget.fallbackImageUrl) {
      _disposeController();
      _loadFailed = false;
      if (!_hasFallbackImage) {
        unawaited(_initVideoFrame());
      }
    }
  }

  Future<void> _initVideoFrame() async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller = ctrl;
      await ctrl.initialize();
      _videoDuration = ctrl.value.duration;
      await ctrl.pause();
      if (mounted) setState(() {});
    } catch (_) {
      _loadFailed = true;
      if (mounted) setState(() {});
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasFallbackImage) {
      return CachedNetworkImage(
        imageUrl: widget.fallbackImageUrl!,
        cacheManager: _chatMediaCache,
        fit: BoxFit.cover,
        placeholder: (c, u) => Container(color: context.oklSurface),
        errorWidget: (c, u, e) => _videoFallback(context),
      );
    }

    final c = _controller;
    if (c != null && c.value.isInitialized && !_loadFailed) {
      final size = c.value.size;
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(c),
            ),
          ),
          if (_videoDuration != null && _videoDuration!.inMilliseconds > 0)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(_chatPillRadius),
                ),
                child: Text(
                  _formatDurationLabel(_videoDuration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return _videoFallback(context);
  }

  String _formatDurationLabel(Duration d) {
    final total = d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _videoFallback(BuildContext context) {
    return Container(
      color: Color.alphaBlend(
        context.oklOnSurface.withValues(alpha: 0.08),
        context.oklSurface,
      ),
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.video,
        color: context.oklOnSurfaceMuted(0.52),
        size: 30,
      ),
    );
  }
}

/// Bulle vocale style WhatsApp : avatar + micro, lecture, forme d'onde cliquable, durée, reçus.
class _WhatsAppStyleVoiceBubble extends StatefulWidget {
  final ChatMessage message;
  final void Function(ChatMessage m)? onMessageMenu;

  const _WhatsAppStyleVoiceBubble({required this.message, this.onMessageMenu});

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
    final url = raw;
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

  /// Hors Web : télécharger d'abord via le cache (même pile HTTP que les images) —
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
        // ignore: experimental_member_use
        await _player.setAudioSource(LockCachingAudioSource(uri));
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

    final prevKey = prevRaw.isEmpty
        ? ''
        : _audioKey(prevRaw);
    final nextKey = nextRaw.isEmpty
        ? ''
        : _audioKey(nextRaw);

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
    _GlobalVoicePlayback.instance.activeMessageId.removeListener(
      _onActiveChanged,
    );
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
    unawaited(_player.seek(Duration(milliseconds: (f * total).round())));
  }

  @override
  Widget build(BuildContext context) {
    final mine = m.mine;
    final bubble = mine ? const Color(0xFF1B3B32) : context.oklSurface;
    final onBubble = mine ? Colors.white : context.oklOnSurface;
    final waveInactive = mine
        ? Colors.white.withValues(alpha: 0.28)
        : context.oklOnSurfaceMuted(0.28);
    final waveActive = mine
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.primary.withValues(alpha: 0.75);
    final playhead = mine ? Colors.white : AppColors.primary;
    final playBtnBg = mine ? Colors.white.withValues(alpha: 0.16) : context.oklScaffold;
    final playBtnFg = mine ? Colors.white : AppColors.primary;

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
    final durationLabel = _ready && totalMs > 0
        ? _fmtDur(effectiveDur)
        : (fallbackSec > 0
              ? _fmtDur(Duration(seconds: fallbackSec))
              : (_ready ? _fmtDur(_position) : '—'));

    final voiceBr = _bubbleRadius(mine);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Material(
          color: bubble,
          borderRadius: voiceBr,
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(borderRadius: voiceBr),
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: playBtnBg,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          if (_preparing) return;
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
                          _playing ? LucideIcons.pause : LucideIcons.play,
                          size: 20,
                          color: playBtnFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 26,
                        child: LayoutBuilder(
                          builder: (context, cons) {
                            final w = cons.maxWidth;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (d) =>
                                  _seekFromLocalX(d.localPosition.dx, w),
                              onHorizontalDragUpdate: (d) =>
                                  _seekFromLocalX(d.localPosition.dx, w),
                              child: CustomPaint(
                                painter: _WhatsAppVoiceWaveformPainter(
                                  progress: progress,
                                  inactiveColor: waveInactive,
                                  activeColor: waveActive,
                                  playheadColor: playhead,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () async {
                        final next = _speed == 1.0
                            ? 1.5
                            : (_speed == 1.5 ? 2.0 : 1.0);
                        await _player.setSpeed(next);
                        if (mounted) setState(() => _speed = next);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          '${_speed}x',
                          style: TextStyle(
                            color: onBubble.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (widget.onMessageMenu != null) ...[
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: () => widget.onMessageMenu!(m),
                        borderRadius: BorderRadius.circular(_chatPillRadius),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            LucideIcons.chevronDown,
                            size: 15,
                            color: onBubble.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      durationLabel,
                      style: TextStyle(
                        color: onBubble.withValues(alpha: 0.82),
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (mine) ...[
                      _ReadReceiptTicks(message: m, forDarkBackground: true),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      m.time,
                      style: TextStyle(
                        color: onBubble.withValues(alpha: 0.68),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (!_ready && _loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.alertCircle,
                            size: 12,
                            color: mine
                                ? Colors.redAccent.shade100
                                : Theme.of(context).colorScheme.error),
                        const SizedBox(width: 4),
                        Text(
                          _loadError == 'audio_manquant'
                              ? 'Audio indisponible'
                              : 'Lecture impossible',
                          style: TextStyle(
                            color: mine
                                ? Colors.redAccent.shade100
                                : Theme.of(context).colorScheme.error,
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

class _CameraChoiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _CameraChoiceTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.oklSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: context.oklOnSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      color: context.oklOnSurfaceMuted(0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
