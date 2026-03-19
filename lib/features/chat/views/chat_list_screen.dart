import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/widgets/okl_pill_search_bar.dart';
import 'status_viewer_screen.dart';

class _Chat {
  final String name;
  final String lastMsg;
  final String time;
  final String avatarUrl;
  final String statusImageUrl;
  final String statusCaption;
  final String statusTimeAgo;
  final bool hasStory;
  final bool isUnread;
  final int unreadCount;
  final bool online;

  const _Chat({
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.avatarUrl,
    required this.statusImageUrl,
    required this.statusCaption,
    required this.statusTimeAgo,
    this.hasStory = false,
    this.isUnread = false,
    this.unreadCount = 0,
    this.online = true,
  });
}

final _chats = [
  const _Chat(
    name: 'Afi',
    lastMsg: 'Haha tu es trop drôle 😂',
    time: '14:20',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80&auto=format&fit=crop',
    statusImageUrl:
        'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=1200&q=85&auto=format&fit=crop',
    statusCaption: 'Petit coucher de soleil a Lome.',
    statusTimeAgo: 'il y a 12 min',
    hasStory: true,
    isUnread: true,
    unreadCount: 2,
    online: true,
  ),
  const _Chat(
    name: 'Kofi',
    lastMsg: 'RDV demain à Kodjoviakopé ?',
    time: '13:55',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80&auto=format&fit=crop',
    statusImageUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=85&auto=format&fit=crop',
    statusCaption: 'Direction la plage ce soir.',
    statusTimeAgo: 'il y a 1 h',
    isUnread: true,
    unreadCount: 1,
    online: true,
  ),
  const _Chat(
    name: 'Sena',
    lastMsg: 'J\'ai vu ta story 🔥',
    time: '12:30',
    avatarUrl:
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80&auto=format&fit=crop',
    statusImageUrl:
        'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=1200&q=85&auto=format&fit=crop',
    statusCaption: 'Nouveau cafe spot a Tokoin.',
    statusTimeAgo: 'il y a 34 min',
    hasStory: true,
    online: false,
  ),
  const _Chat(
    name: 'Mawuli',
    lastMsg: 'OK je te fais signe',
    time: '11:00',
    avatarUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80&auto=format&fit=crop',
    statusImageUrl:
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1200&q=85&auto=format&fit=crop',
    statusCaption: 'Sortie nature du weekend.',
    statusTimeAgo: 'hier',
    online: true,
  ),
];

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const _mineStoryUrl =
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80&auto=format&fit=crop';
  static const _mineStatusImageUrl =
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200&q=85&auto=format&fit=crop';

  bool _searchMode = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _enterSearch() {
    setState(() => _searchMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _exitSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _searchMode = false);
  }

  List<_Chat> get _visibleChats {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _chats;
    return _chats
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.lastMsg.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<StatusStory> _storiesForViewer() {
    return [
      const StatusStory(
        name: 'Mon statut',
        avatarUrl: _mineStoryUrl,
        imageUrl: _mineStatusImageUrl,
        caption: 'Mon humeur du jour.',
        timeAgo: 'a l instant',
      ),
      ..._chats.where((c) => c.hasStory).map(
            (c) => StatusStory(
              name: c.name,
              avatarUrl: c.avatarUrl,
              imageUrl: c.statusImageUrl,
              caption: c.statusCaption,
              timeAgo: c.statusTimeAgo,
            ),
          ),
    ];
  }

  void _openStatusViewer(BuildContext context, int initialIndex) {
    final stories = _storiesForViewer();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => StatusViewerScreen(
          stories: stories,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _openMyStatusAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.textPrimary),
                title: const Text(
                  'Camera',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Prendre une photo ou video',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  OklFeedback.snack(context, 'Ouverture camera (demo)');
                },
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(LucideIcons.image, color: AppColors.textPrimary),
                title: const Text(
                  'Galerie',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Choisir depuis les photos',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  OklFeedback.snack(context, 'Ouverture galerie (demo)');
                },
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(LucideIcons.type, color: AppColors.textPrimary),
                title: const Text(
                  'Statut texte',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  OklFeedback.snack(context, 'Creation statut texte (demo)');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openComposeMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.messageSquarePlus, color: AppColors.togoGreen),
                title: const Text('Nouveau message',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Écrire à un match',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  OklFeedback.snack(context, 'Choisis un match pour démarrer');
                },
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(LucideIcons.users, color: AppColors.togoGold),
                title: const Text('Nouveau groupe',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Jusqu’à 8 personnes (démo)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  OklFeedback.snack(context, 'Groupes — fonctionnalité à venir');
                },
              ),
              const Divider(height: 1, color: AppColors.divider),
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.primary),
                title: const Text('Statut photo / vidéo',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  OklFeedback.snack(context, 'Caméra ouverte (simulation)');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChatActions(BuildContext context, _Chat chat) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: chat.avatarUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    memCacheWidth: 128,
                    placeholder: (c, u) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.dark,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.togoGold),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        chat.online ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                          color: chat.online ? AppColors.green : AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SheetAction(
              icon: LucideIcons.messageCircle,
              label: 'Ouvrir la conversation',
              onTap: () {
                Navigator.pop(ctx);
                OklFeedback.snack(context, 'Conversation avec ${chat.name} — écran chat à brancher');
              },
            ),
            _SheetAction(
              icon: LucideIcons.user,
              label: 'Voir le profil',
              onTap: () {
                Navigator.pop(ctx);
                OklFeedback.snack(context, 'Profil de ${chat.name}');
              },
            ),
            _SheetAction(
              icon: LucideIcons.phone,
              label: 'Appel vocal',
              onTap: () {
                Navigator.pop(ctx);
                OklFeedback.snack(context, 'Appel vers ${chat.name}… (démo)');
              },
            ),
            _SheetAction(
              icon: LucideIcons.bellOff,
              label: 'Mettre en silencieux',
              onTap: () {
                Navigator.pop(ctx);
                OklFeedback.snack(context, 'Notifications désactivées pour ${chat.name}');
              },
            ),
            _SheetAction(
              icon: LucideIcons.archive,
              label: 'Archiver',
              subtle: true,
              onTap: () {
                Navigator.pop(ctx);
                OklFeedback.snack(context, 'Conversation archivée');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openConversation(BuildContext context, _Chat chat) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => _ConversationScreen(chat: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _searchMode
                  ? Row(
                      children: [
                        Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _exitSearch,
                            borderRadius: BorderRadius.circular(12),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: Icon(
                                  LucideIcons.arrowLeft,
                                  color: AppColors.textPrimary,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OklPillSearchBar(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            hintText: 'Nom ou mot-clé…',
                            autofocus: true,
                            onSubmitted: (q) {
                              if (q.trim().isEmpty) return;
                              OklFeedback.snack(context, 'Recherche « $q » — bientôt disponible');
                            },
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Messages',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        Row(
                          children: [
                            _IconBtn(icon: LucideIcons.search, onTap: _enterSearch),
                            const SizedBox(width: 10),
                            _IconBtn(
                              icon: LucideIcons.edit,
                              onTap: () => _openComposeMenu(context),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _StoryBubble(
                    name: 'Mon statut',
                    isMine: true,
                    imageUrl: _mineStoryUrl,
                    onTap: () => _openStatusViewer(context, 0),
                    onAddTap: () => _openMyStatusAddMenu(context),
                  ),
                  ..._chats
                      .where((c) => c.hasStory)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (entry) {
                          final idx = entry.key;
                          final c = entry.value;
                          return _StoryBubble(
                          name: c.name,
                          imageUrl: c.avatarUrl,
                          onTap: () => _openStatusViewer(context, idx + 1),
                        );
                        },
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView.separated(
                itemCount: _visibleChats.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 76,
                ),
                itemBuilder: (context, i) {
                  final chat = _visibleChats[i];
                  return _ChatTile(
                    chat: chat,
                    onTap: () => _openConversation(context, chat),
                    onLongPress: () => _openChatActions(context, chat),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openComposeMenu(context),
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.messageSquarePlus, color: Colors.white),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool subtle;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: subtle ? AppColors.dark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: subtle ? AppColors.textSecondary : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final _Chat chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatTile({
    required this.chat,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: chat.hasStory ? AppColors.igStoryGradient : null,
                      color: chat.hasStory ? null : Colors.transparent,
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.dark,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surface,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: chat.avatarUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            memCacheWidth: 96,
                            filterQuality: FilterQuality.medium,
                            placeholder: (c, u) => Container(
                              width: 48,
                              height: 48,
                              color: AppColors.dark,
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.togoGold,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (c, u, e) => const Icon(
                              LucideIcons.user,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (chat.online)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.dark, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: chat.isUnread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chat.lastMsg,
                      style: TextStyle(
                        color: chat.isUnread
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: chat.isUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    chat.time,
                    style: TextStyle(
                      color: chat.isUnread ? AppColors.primary : AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (chat.isUnread && chat.unreadCount > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${chat.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationScreen extends StatefulWidget {
  final _Chat chat;

  const _ConversationScreen({required this.chat});

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _canSend = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordTimer;

  void _syncSendState() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText == _canSend) return;
    setState(() => _canSend = hasText);
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_syncSendState);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _messageController.removeListener(_syncSendState);
    _messageController.dispose();
    super.dispose();
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleRecording() {
    if (_isRecording) {
      final duration = _formatDuration(_recordingSeconds);
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
      });
      OklFeedback.snack(context, 'Note vocale enregistree ($duration) - demo');
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

  void _openAttachmentOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
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
                      OklFeedback.snack(context, 'Document (démo)');
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.image,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(ctx);
                      OklFeedback.snack(context, 'Galerie (démo)');
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.camera,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(ctx);
                      OklFeedback.snack(context, 'Camera (démo)');
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
                      OklFeedback.snack(context, 'Position (démo)');
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.userPlus,
                    label: 'Contact',
                    onTap: () {
                      Navigator.pop(ctx);
                      OklFeedback.snack(context, 'Contact (démo)');
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.music,
                    label: 'Audio',
                    onTap: () {
                      Navigator.pop(ctx);
                      OklFeedback.snack(context, 'Audio (démo)');
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

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        titleSpacing: 0,
        title: Row(
          children: [
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: chat.avatarUrl,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                memCacheWidth: 80,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  chat.online ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    color: chat.online ? AppColors.green : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => OklFeedback.snack(context, 'Appel vocal (démo)'),
            icon: const Icon(LucideIcons.phone, size: 19),
          ),
          IconButton(
            onPressed: () => OklFeedback.snack(context, 'Options conversation'),
            icon: const Icon(LucideIcons.moreVertical, size: 19),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              children: [
                _MsgBubble(
                  text: chat.lastMsg,
                  mine: false,
                  time: chat.time,
                ),
                const SizedBox(height: 8),
                const _MsgBubble(
                  text: 'On en parle ce soir ?',
                  mine: true,
                  time: '14:22',
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: TextField(
                          controller: _messageController,
                          readOnly: _isRecording,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: _isRecording
                                ? 'Enregistrement... ${_formatDuration(_recordingSeconds)}'
                                : 'Message...',
                            hintStyle: const TextStyle(color: AppColors.textSecondary),
                            isDense: true,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            border: InputBorder.none,
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                LucideIcons.camera,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => _openAttachmentOptions(context),
                                child: const Icon(
                                  LucideIcons.plus,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isEmpty) return;
                            OklFeedback.snack(context, 'Message envoye');
                            _messageController.clear();
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
                              : AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (_canSend) {
                          final txt = _messageController.text.trim();
                          if (txt.isEmpty) return;
                          OklFeedback.snack(context, 'Message envoye');
                          _messageController.clear();
                          return;
                        }
                        _toggleRecording();
                      },
                      icon: Icon(
                        _canSend ? LucideIcons.send : LucideIcons.mic,
                        color: _canSend || _isRecording
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                color: AppColors.dark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
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

class _MsgBubble extends StatelessWidget {
  final String text;
  final bool mine;
  final String time;

  const _MsgBubble({
    required this.text,
    required this.mine,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bg = mine ? AppColors.primary.withValues(alpha: 0.26) : AppColors.surface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  final String name;
  final bool isMine;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onAddTap;

  const _StoryBubble({
    required this.name,
    this.isMine = false,
    this.imageUrl,
    required this.onTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isMine ? null : AppColors.igStoryGradient,
                      color: isMine ? AppColors.surface : null,
                      border: isMine
                          ? Border.all(color: AppColors.divider, width: 1.5)
                          : null,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.dark,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: isMine
                            ? (imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl!,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 104,
                                  )
                                : Container(
                                    width: 52,
                                    height: 52,
                                    color: AppColors.surface,
                                  ))
                            : CachedNetworkImage(
                                imageUrl: imageUrl ?? '',
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                memCacheWidth: 104,
                                placeholder: (c, u) => Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.surface,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (isMine)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: GestureDetector(
                        onTap: onAddTap ?? onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 19,
                          height: 19,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.dark, width: 1.8),
                          ),
                          child: const Icon(
                            LucideIcons.plus,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 68,
              child: Text(
                name.length > 9 ? '${name.substring(0, 8)}…' : name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: Icon(icon, color: AppColors.textPrimary, size: 19)),
        ),
      ),
    );
  }
}
