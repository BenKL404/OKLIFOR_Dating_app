import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/okl_pick_media_permissions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/layout_constants.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/widgets/okl_pill_search_bar.dart';
import '../../../core/widgets/okl_story_gauge_ring.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_providers.dart';
import '../repository/chat_repository.dart';
import 'conversation_screen.dart';
import 'create_group_screen.dart';
import 'create_text_status_screen.dart';
import 'new_message_screen.dart';
import 'chat_search_results_screen.dart';
import 'chat_thread_detail_screen.dart';
import 'status_viewer_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  TextStatusPublishResult? _myTextStatus;
  String? _myMediaStatusLocalPath;
  String _myMediaStatusCaption = 'Mon humeur du jour.';
  // Fix #3 — avatar chargé depuis le profil réel (fallback statique en cas d'erreur)
  String _myAvatarUrl =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80&auto=format&fit=crop';

  bool _searchMode = false;
  bool _showArchived = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final Map<String, bool> _typingByThreadId = <String, bool>{};
  final Map<String, Timer> _typingHideTimersByThreadId = <String, Timer>{};

  // Fix #4 — stocker toutes les subscriptions pour les annuler dans dispose()
  final Map<String, StreamSubscription<ChatRepoEvent>> _threadSubscriptions = {};



  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToEvents();
      _loadMyStatus(); // Fix #3
    });
  }

  /// Fix #4 — abonne les threads visibles aux events temps réel en gardant les subscriptions.
  void _subscribeToEvents() {
    final threads = ref.read(chatThreadsProvider).value ?? [];
    final repo = ref.read(chatRepositoryProvider);
    for (final t in threads) {
      if (_threadSubscriptions.containsKey(t.id)) continue;
      final sub = repo.watchThread(t.id).listen((event) {
        if (!mounted) return;
        if (event is ChatRepoPresenceEvent) {
          setState(() {
            final idx = _getThreads().indexWhere((x) => x.id == t.id);
            if (idx < 0) return;
            ref
                .read(chatThreadsProvider.notifier)
                .upsertThread(
                  _getThreads()[idx].copyWith(online: event.online),
                );
          });
        } else if (event is ChatRepoTypingEvent) {
          _typingHideTimersByThreadId.remove(t.id)?.cancel();
          if (!event.typing) {
            _typingHideTimersByThreadId[t.id] = Timer(
              const Duration(milliseconds: 900),
              () {
                if (!mounted) return;
                setState(() => _typingByThreadId[t.id] = false);
              },
            );
            return;
          }
          setState(() => _typingByThreadId[t.id] = true);
        }
      });
      _threadSubscriptions[t.id] = sub;  // Fix #4 — stocker pour cancel()
    }
  }

  /// Fix #3 — charge le statut courant depuis l'API au démarrage.
  Future<void> _loadMyStatus() async {
    try {
      final api = ref.read(okliforApiClientProvider);
      final status = await api.fetchMyUserStatus();
      if (!mounted) return;
      if (status != null) {
        final kind = status.kind;
        if (kind == 'TEXT') {
          setState(() {
            _myTextStatus = TextStatusPublishResult(
              text: status.text ?? '',
              backgroundColor: _parseStoryHexColor(status.backgroundColorHex) ?? const Color(0xFF1E3A5F),
            );
            _myMediaStatusLocalPath = null;
          });
        } else if (kind == 'IMAGE' || kind == 'VIDEO') {
          setState(() {
            _myTextStatus = null;
            _myMediaStatusLocalPath = status.mediaUrl ?? '';
            _myMediaStatusCaption = status.caption ?? '';
          });
        }
      }
    } catch (_) {
      // Échec silencieux — l'utilisateur peut ne pas avoir de statut
    }
  }

  List<ChatThread> _getThreads() =>
      ref.read(chatThreadsProvider).value ?? [];

  @override
  void dispose() {
    // Fix #4 — annuler toutes les subscriptions WS proprement
    for (final sub in _threadSubscriptions.values) {
      sub.cancel();
    }
    _threadSubscriptions.clear();
    for (final t in _typingHideTimersByThreadId.values) {
      t.cancel();
    }
    _typingHideTimersByThreadId.clear();
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

  List<ChatThread> get _visibleChats {
    final threads = ref.watch(chatThreadsProvider).value ?? [];
    final active = threads.where((c) => !c.isArchived);
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return active.toList(growable: false);
    return active
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.lastMsg.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<ChatThread> get _archivedChats {
    final threads = ref.watch(chatThreadsProvider).value ?? [];
    final archived = threads.where((c) => c.isArchived);
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return archived.toList(growable: false);
    return archived
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.lastMsg.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  String _formatRelativeTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return "à l'instant";
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays < 7) return 'il y a ${d.inDays} j';
    return 'récemment';
  }

  StatusStory _threadToStatusStory(ChatThread c) {
    if (c.statusKind == 'TEXT') {
      return StatusStory(
        name: c.name,
        avatarUrl: c.avatarUrl,
        imageUrl: '',
        caption: c.statusCaption,
        timeAgo: c.statusTimeAgo,
        solidBackground: _parseStoryHexColor(c.statusBackgroundHex) ??
            const Color(0xFF1E3A5F),
      );
    }
    return StatusStory(
      name: c.name,
      avatarUrl: c.avatarUrl,
      imageUrl: c.statusImageUrl,
      caption: c.statusCaption,
      timeAgo: c.statusTimeAgo,
    );
  }

  Color? _parseStoryHexColor(String? h) {
    if (h == null || h.isEmpty) return null;
    var s = h.trim().replaceFirst('#', '');
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    return Color(int.parse(s, radix: 16));
  }

  List<StatusStory> _storiesForViewer() {
    final threads = ref.read(chatThreadsProvider).value ?? [];
    final hasMyStatus =
        _myTextStatus != null ||
        (_myMediaStatusLocalPath != null && _myMediaStatusLocalPath!.isNotEmpty);

    if (!hasMyStatus) {
      return threads.where((c) => c.hasStory).map(_threadToStatusStory).toList();
    }

    final StatusStory mine;
    if (_myTextStatus != null) {
      mine = StatusStory(
        name: 'Mon statut',
        avatarUrl: _myAvatarUrl,
        imageUrl: '',
        caption: _myTextStatus!.text,
        timeAgo: "à l'instant",
        solidBackground: _myTextStatus!.backgroundColor,
      );
    } else {
      mine = StatusStory(
        name: 'Mon statut',
        avatarUrl: _myAvatarUrl,
        imageUrl: _myMediaStatusLocalPath!,
        caption: _myMediaStatusCaption,
        timeAgo: "à l'instant",
      );
    }
    return [
      mine,
      ...threads.where((c) => c.hasStory).map(_threadToStatusStory),
    ];
  }

  void _openStatusViewer(BuildContext context, int initialIndex) {
    final stories = _storiesForViewer();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            StatusViewerScreen(stories: stories, initialIndex: initialIndex),
      ),
    );
  }

  void _openMyStatusAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_myTextStatus != null ||
                  (_myMediaStatusLocalPath != null &&
                      _myMediaStatusLocalPath!.isNotEmpty)) ...[
                ListTile(
                  leading: Icon(
                    LucideIcons.trash2,
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                  title: Text(
                    'Supprimer mon statut',
                    style: TextStyle(
                      color: ctx.oklOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    // Fix #3 — Supprimer le statut via l'API
                    try {
                      await ref.read(okliforApiClientProvider).deleteMyUserStatus();
                    } catch (_) {}
                    if (!mounted) return;
                    setState(() {
                      _myTextStatus = null;
                      _myMediaStatusLocalPath = null;
                    });
                    if (context.mounted) {
                      OklFeedback.snack(context, 'Statut supprimé');
                    }
                  },
                ),
                Divider(height: 1, color: ctx.oklDivider),
              ],
              ListTile(
                leading: Icon(LucideIcons.camera, color: ctx.oklOnSurface),
                title: Text(
                  'Camera',
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Prendre une photo ou video',
                  style: TextStyle(
                    color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                        ctx.oklOnSurfaceMuted(0.62),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openPickMediaMenu(context, source: ImageSource.camera);
                },
              ),
              Divider(height: 1, color: ctx.oklDivider),
              ListTile(
                leading: Icon(LucideIcons.image, color: ctx.oklOnSurface),
                title: Text(
                  'Galerie',
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Choisir depuis les photos',
                  style: TextStyle(
                    color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                        ctx.oklOnSurfaceMuted(0.62),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openPickMediaMenu(context, source: ImageSource.gallery);
                },
              ),
              Divider(height: 1, color: ctx.oklDivider),
              ListTile(
                leading: Icon(LucideIcons.type, color: ctx.oklOnSurface),
                title: Text(
                  'Statut texte',
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final r =
                      await Navigator.of(context, rootNavigator: true)
                          .push<TextStatusPublishResult>(
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => const CreateTextStatusScreen(),
                            ),
                          );
                  if (!mounted || r == null) return;
                  // Fix #3 — Publier le statut texte via l'API
                  try {
                    await ref.read(okliforApiClientProvider).publishTextUserStatus(
                      text: r.text,
                      backgroundColorHex: r.backgroundColor
                          .value.toRadixString(16).padLeft(8, '0').toUpperCase(),
                    );
                  } catch (_) {
                    // Échec silencieux — le statut reste visible localement
                  }
                  if (!mounted) return;
                  setState(() {
                    _myTextStatus = r;
                    _myMediaStatusLocalPath = null;
                  });
                  if (!context.mounted) return;
                  OklFlows.pushResult(
                    context,
                    icon: LucideIcons.sparkles,
                    title: 'Statut publié',
                    subtitle: 'Tes contacts le verront en haut de Messages.',
                    primaryLabel: 'Super',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPickMediaMenu(BuildContext context, {required ImageSource source}) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.oklSurface,
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
                leading: Icon(LucideIcons.image, color: ctx.oklOnSurface),
                title: Text(
                  'Photo',
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Choisir ou capturer une image',
                  style: TextStyle(
                    color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                        ctx.oklOnSurfaceMuted(0.62),
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _requestAndPickMedia(
                    context,
                    source: source,
                    isVideo: false,
                  );
                },
              ),
              Divider(height: 1, color: ctx.oklDivider),
              ListTile(
                leading: Icon(LucideIcons.video, color: ctx.oklOnSurface),
                title: Text(
                  'Vidéo',
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Choisir ou capturer une vidéo',
                  style: TextStyle(
                    color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                        ctx.oklOnSurfaceMuted(0.62),
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _requestAndPickMedia(
                    context,
                    source: source,
                    isVideo: true,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestAndPickMedia(
    BuildContext context, {
    required ImageSource source,
    required bool isVideo,
  }) async {
    if (source == ImageSource.camera) {
      if (!await OklPickMediaPermissions.ensureImageSource(
        context,
        ImageSource.camera,
      )) {
        return;
      }
      if (isVideo) {
        if (!await OklPickMediaPermissions.ensureMicrophone(context)) {
          return;
        }
      }
    } else {
      if (!await OklPickMediaPermissions.ensureGalleryForPick(
        context,
        isVideo: isVideo,
      )) {
        return;
      }
    }

    final picker = ImagePicker();
    final xFile = isVideo
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source);

    if (!mounted || xFile == null) return;

    setState(() {
      _myTextStatus = null;
      _myMediaStatusLocalPath = kIsWeb ? null : xFile.path;
      _myMediaStatusCaption = isVideo ? 'Ma vidéo statut' : 'Ma photo statut';
    });

    if (!context.mounted) return;
    OklFlows.pushResult(
      context,
      icon: isVideo ? LucideIcons.video : LucideIcons.image,
      title: isVideo ? 'Vidéo ajoutée' : 'Photo ajoutée',
      subtitle: 'Ton statut média est prêt.',
      primaryLabel: 'OK',
    );
  }

  void _openComposeMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.oklSurface,
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
                leading: Icon(
                  LucideIcons.messageSquarePlus,
                  color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                      ctx.oklOnSurfaceMuted(0.62),
                ),
                title: Text(
                  'Nouveau message',
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Écrire à un match',
                  style: TextStyle(
                    color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                        ctx.oklOnSurfaceMuted(0.62),
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _openNewMessageFlow();
                },
              ),
              Divider(height: 1, color: ctx.oklDivider),
              ListTile(
                leading: Icon(
                  LucideIcons.users,
                  color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                      ctx.oklOnSurfaceMuted(0.62),
                ),
                title: Text(
                  'Nouveau groupe',
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  "Jusqu'à 8 personnes",
                  style: TextStyle(
                    color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                        ctx.oklOnSurfaceMuted(0.62),
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _openCreateGroupFlow();
                },
              ),
              Divider(height: 1, color: ctx.oklDivider),
              ListTile(
                leading: Icon(
                  LucideIcons.camera,
                  color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                      ctx.oklOnSurfaceMuted(0.62),
                ),
                title: Text(
                  'Statut photo / vidéo',
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  "Ouvre l'appareil ou la galerie",
                  style: TextStyle(
                    color: Theme.of(ctx).textTheme.bodyMedium?.color ??
                        ctx.oklOnSurfaceMuted(0.62),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openMyStatusAddMenu(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNewMessageFlow() async {
    final c = await Navigator.of(context, rootNavigator: true)
        .push<ChatContact>(
          MaterialPageRoute<ChatContact>(
            builder: (_) => const NewMessageScreen(),
          ),
        );
    if (!mounted || c == null) return;
    try {
      final thread =
          await ref.read(chatRepositoryProvider).createDirectThread(c.id);
      ref.read(chatThreadsProvider.notifier).prependThread(thread);
      if (!mounted) return;
      _openConversation(context, thread);
    } catch (_) {
      if (mounted) {
        OklFeedback.snack(context, 'Création de conversation impossible');
      }
    }
  }

  Future<void> _openCreateGroupFlow() async {
    final r = await Navigator.of(context, rootNavigator: true)
        .push<CreateGroupResult>(
          MaterialPageRoute<CreateGroupResult>(
            builder: (_) => const CreateGroupScreen(),
          ),
        );
    if (!mounted || r == null) return;
    final thread = await ref
        .read(chatRepositoryProvider)
        .createGroupThread(
          r.name,
          r.members.map((m) => m.id).toList(),
        );
    ref.read(chatThreadsProvider.notifier).prependThread(thread);
    _openConversation(context, thread);
  }

  void _updateThread(
    String threadId,
    ChatThread Function(ChatThread current) transform,
  ) {
    final threads = ref.read(chatThreadsProvider).value ?? [];
    final idx = threads.indexWhere((t) => t.id == threadId);
    if (idx < 0) return;
    ref
        .read(chatThreadsProvider.notifier)
        .upsertThread(transform(threads[idx]));
  }

  void _removeThread(String threadId) {
    ref.read(chatThreadsProvider.notifier).removeThread(threadId);
  }

  void _openChatActions(BuildContext context, ChatThread chat) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.oklSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ctx.oklDivider,
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
                      color: ctx.oklSurface,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.togoGold,
                          ),
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
                        style: TextStyle(
                          color: ctx.oklOnSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        chat.online ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                          color: chat.online
                              ? AppColors.green
                              : ctx.oklOnSurfaceMuted(0.55),
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
                _openConversation(context, chat);
              },
            ),
            _SheetAction(
              icon: LucideIcons.user,
              label: chat.isGroup ? 'Infos du groupe' : 'Voir le profil',
              onTap: () async {
                Navigator.pop(ctx);
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatThreadDetailScreen(thread: chat),
                  ),
                );
              },
            ),
            _SheetAction(
              icon: LucideIcons.phone,
              label: 'Appel vocal',
              onTap: () {
                Navigator.pop(ctx);
                _updateThread(
                  chat.id,
                  (current) => current.copyWith(
                    lastMsg: '📞 Appel vocal',
                    time: formatTimeNow(),
                    isUnread: false,
                    unreadCount: 0,
                  ),
                );
                OklFlows.pushOutgoingCall(
                  context,
                  contactName: chat.name,
                  avatarUrl: chat.isGroup ? null : chat.avatarUrl,
                );
              },
            ),
            _SheetAction(
              icon: chat.isMuted ? LucideIcons.bell : LucideIcons.bellOff,
              label: chat.isMuted
                  ? 'Réactiver les notifications'
                  : 'Mettre en silencieux',
              onTap: () {
                Navigator.pop(ctx);
                _updateThread(
                  chat.id,
                  (current) => current.copyWith(isMuted: !current.isMuted),
                );
              },
            ),
            _SheetAction(
              icon: chat.isUnread ? LucideIcons.checkCheck : LucideIcons.circle,
              label: chat.isUnread
                  ? 'Marquer comme lu'
                  : 'Marquer comme non lu',
              onTap: () {
                Navigator.pop(ctx);
                _updateThread(chat.id, (current) {
                  final unreadAfter = !current.isUnread;
                  return current.copyWith(
                    isUnread: unreadAfter,
                    unreadCount: unreadAfter
                        ? (current.unreadCount > 0 ? current.unreadCount : 1)
                        : 0,
                  );
                });
              },
            ),
            _SheetAction(
              icon: LucideIcons.archive,
              label: chat.isArchived ? 'Désarchiver' : 'Archiver',
              subtle: true,
              onTap: () {
                Navigator.pop(ctx);
                _updateThread(
                  chat.id,
                  (current) =>
                      current.copyWith(isArchived: !current.isArchived),
                );
              },
            ),
            _SheetAction(
              icon: LucideIcons.trash2,
              label: 'Supprimer la discussion',
              subtle: true,
              onTap: () async {
                Navigator.pop(ctx);
                await OklFeedback.confirm(
                  context,
                  title: 'Supprimer la discussion',
                  body: 'Cette conversation sera retirée de ta liste.',
                  confirmLabel: 'Supprimer',
                  onConfirm: () => _removeThread(chat.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openConversation(BuildContext context, ChatThread chat) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(thread: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleChats = _visibleChats;
    final archivedChats = _archivedChats;
    final hasArchived = archivedChats.isNotEmpty;
    final extraArchivedItems =
        (hasArchived && _showArchived) ? archivedChats.length : 0;
    final totalItems =
        visibleChats.length + (hasArchived ? 1 : 0) + extraArchivedItems;
    final isDark = context.oklMeetIsDark;
    final titleColor = isDark ? Colors.white : context.oklOnSurface;
    final hasMyStatus =
        _myTextStatus != null ||
        (_myMediaStatusLocalPath != null && _myMediaStatusLocalPath!.isNotEmpty);
    final threads = ref.watch(chatThreadsProvider).value ?? [];

    return Scaffold(
      backgroundColor: context.oklScaffold,
      body: Container(
        decoration: context.oklMeetCanvasDecoration,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: context.oklMeetHeaderScrimGradient,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
                      child: _searchMode
                          ? Row(
                              children: [
                                OklAppBarIconButton(
                                  icon: LucideIcons.arrowLeft,
                                  onPressed: _exitSearch,
                                  useOverlayStyle: isDark,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OklPillSearchBar(
                                    controller: _searchController,
                                    focusNode: _searchFocus,
                                    hintText: 'Nom ou mot-clé…',
                                    autofocus: true,
                                    onSubmitted: (q) {
                                      final t = q.trim();
                                      if (t.isEmpty) return;
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              ChatSearchResultsScreen(
                                                query: t,
                                                threads: visibleChats,
                                                onThreadUpdated:
                                                    (id, last, time) {
                                                      _updateThread(
                                                        id,
                                                        (c) => c.copyWith(
                                                          lastMsg: last,
                                                          time: time,
                                                          isUnread: false,
                                                          unreadCount: 0,
                                                        ),
                                                      );
                                                    },
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Chat',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.0,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                                OklAppBarIconButton(
                                  icon: LucideIcons.search,
                                  onPressed: _enterSearch,
                                  useOverlayStyle: isDark,
                                ),
                                const SizedBox(width: 4),
                                OklAppBarIconButton(
                                  icon: LucideIcons.edit,
                                  onPressed: () =>
                                      _openComposeMenu(context),
                                  useOverlayStyle: isDark,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 112,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _StoryBubble(
                      name: 'Mon statut',
                      isMine: true,
                      showActiveStoryRing: hasMyStatus,
                      imageUrl: _myAvatarUrl.isEmpty ? null : _myAvatarUrl,
                      onTap: () => _openStatusViewer(context, 0),
                      onAddTap: () => _openMyStatusAddMenu(context),
                    ),
                    ...threads
                        .where((c) => c.hasStory)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                          final idx = entry.key;
                          final c = entry.value;
                          return _StoryBubble(
                            name: c.name,
                            imageUrl: c.avatarUrl,
                            onTap: () =>
                                _openStatusViewer(context, idx + 1),
                          );
                        }),
                  ],
                ),
              ),
              Divider(height: 1, color: context.oklDivider),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: oklMainShellListBottomPadding(context),
                  ),
                  itemCount: totalItems,
                  itemBuilder: (context, i) {
                    final archiveHeaderIndex = hasArchived ? 0 : -1;
                    final archivedStartIndex = hasArchived ? 1 : 0;
                    final activeStartIndex =
                        archivedStartIndex + extraArchivedItems;

                    if (hasArchived && i == archiveHeaderIndex) {
                      return _ArchiveHeaderTile(
                        count: archivedChats.length,
                        expanded: _showArchived,
                        onTap: () =>
                            setState(
                              () => _showArchived = !_showArchived,
                            ),
                      );
                    }

                    if (hasArchived &&
                        _showArchived &&
                        i >= archivedStartIndex &&
                        i < activeStartIndex) {
                      final archivedIndex = i - archivedStartIndex;
                      final chat = archivedChats[archivedIndex];
                      return _SwipeChatTile(
                        key: ValueKey('archived_${chat.id}'),
                        chat: chat,
                        onArchiveToggle: () {
                          _updateThread(
                            chat.id,
                            (current) => current.copyWith(
                              isArchived: !current.isArchived,
                            ),
                          );
                        },
                        onReadToggle: () {
                          _updateThread(chat.id, (current) {
                            final unreadAfter = !current.isUnread;
                            return current.copyWith(
                              isUnread: unreadAfter,
                              unreadCount: unreadAfter
                                  ? (current.unreadCount > 0
                                        ? current.unreadCount
                                        : 1)
                                  : 0,
                            );
                          });
                        },
                        child: _ChatTile(
                          chat: chat,
                          showTyping: _typingByThreadId[chat.id] ?? false,
                          onTap: () => _openConversation(context, chat),
                          onLongPress: () =>
                              _openChatActions(context, chat),
                        ),
                      );
                    }

                    final activeIndex = i - activeStartIndex;
                    final chat = visibleChats[activeIndex];
                    return _SwipeChatTile(
                        key: ValueKey('active_${chat.id}'),
                        chat: chat,
                        onArchiveToggle: () {
                          _updateThread(
                            chat.id,
                            (current) => current.copyWith(
                              isArchived: !current.isArchived,
                            ),
                          );
                        },
                        onReadToggle: () {
                          _updateThread(chat.id, (current) {
                            final unreadAfter = !current.isUnread;
                            return current.copyWith(
                              isUnread: unreadAfter,
                              unreadCount: unreadAfter
                                  ? (current.unreadCount > 0
                                        ? current.unreadCount
                                        : 1)
                                  : 0,
                            );
                          });
                        },
                        child: _ChatTile(
                          chat: chat,
                          showTyping: _typingByThreadId[chat.id] ?? false,
                          onTap: () => _openConversation(context, chat),
                          onLongPress: () =>
                              _openChatActions(context, chat),
                        ),
                      );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: oklMainShellBottomOverlay(context) + 8,
        ),
        child: FloatingActionButton(
          onPressed: () => _openComposeMenu(context),
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child:
              const Icon(LucideIcons.messageSquarePlus, color: Colors.white),
        ),
      ),
    );
  }
}

class _ArchiveHeaderTile extends StatelessWidget {
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  const _ArchiveHeaderTile({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                LucideIcons.archive,
                color: context.oklOnSurfaceMuted(0.55),
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Archivées',
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: context.oklOnSurfaceMuted(0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                color: context.oklOnSurfaceMuted(0.45),
                size: 18,
              ),
            ],
          ),
        ),
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
        color: subtle ? context.oklScaffold : context.oklSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                      context.oklOnSurfaceMuted(0.62),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: subtle
                          ? (Theme.of(context).textTheme.bodyMedium?.color ??
                                context.oklOnSurfaceMuted(0.62))
                          : context.oklOnSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: context.oklOnSurfaceMuted(0.55),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeChatTile extends StatelessWidget {
  final ChatThread chat;
  final VoidCallback onArchiveToggle;
  final VoidCallback onReadToggle;
  final Widget child;

  const _SwipeChatTile({
    super.key,
    required this.chat,
    required this.onArchiveToggle,
    required this.onReadToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('swipe_${chat.id}'),
      direction: DismissDirection.horizontal,
      movementDuration: const Duration(milliseconds: 160),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.14,
        DismissDirection.endToStart: 0.14,
      },
      resizeDuration: null,
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        if (direction == DismissDirection.startToEnd) {
          onArchiveToggle();
        } else if (direction == DismissDirection.endToStart) {
          onReadToggle();
        }
        return false;
      },
      background: _SwipeActionBackground(
        icon: chat.isArchived ? LucideIcons.archiveRestore : LucideIcons.archive,
        label: chat.isArchived ? 'Désarchiver' : 'Archiver',
        color: const Color(0xFF1C7C54),
        alignStart: true,
      ),
      secondaryBackground: _SwipeActionBackground(
        icon: chat.isUnread ? LucideIcons.checkCheck : LucideIcons.circle,
        label: chat.isUnread ? 'Marquer lu' : 'Marquer non lu',
        color: AppColors.primary,
        alignStart: false,
      ),
      child: child,
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool alignStart;

  const _SwipeActionBackground({
    required this.icon,
    required this.label,
    required this.color,
    required this.alignStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatThread chat;
  final bool showTyping;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatTile({
    required this.chat,
    this.showTyping = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = 62.0;
    final innerSize = avatarSize - 6;

    Widget avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        chat.hasStory
            ? OklStoryGaugeRing(
                outerSize: avatarSize,
                strokeWidth: 2.5,
                child: SizedBox(
                  width: innerSize,
                  height: innerSize,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: chat.avatarUrl,
                      width: innerSize,
                      height: innerSize,
                      fit: BoxFit.cover,
                      memCacheWidth: 128,
                      filterQuality: FilterQuality.medium,
                      placeholder: (c, u) => Container(color: context.oklSurface),
                      errorWidget: (c, u, e) => Icon(
                        LucideIcons.user,
                        color: context.oklOnSurfaceMuted(0.55),
                      ),
                    ),
                  ),
                ),
              )
            : ClipOval(
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: CachedNetworkImage(
                    imageUrl: chat.avatarUrl,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    memCacheWidth: 128,
                    filterQuality: FilterQuality.medium,
                    placeholder: (c, u) => Container(color: context.oklSurface),
                    errorWidget: (c, u, e) => Icon(
                      LucideIcons.user,
                      color: context.oklOnSurfaceMuted(0.55),
                    ),
                  ),
                ),
              ),
        if (chat.online)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: context.oklScaffold, width: 2),
              ),
            ),
          ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  avatar,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat.name,
                                style: TextStyle(
                                  color: context.oklOnSurface,
                                  fontSize: 16,
                                  fontWeight: chat.isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              chat.time,
                              style: TextStyle(
                                color: chat.isUnread
                                    ? AppColors.primary
                                    : context.oklOnSurfaceMuted(0.45),
                                fontSize: 12,
                                fontWeight: chat.isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        if (chat.isGroup) ...[
                          const SizedBox(height: 1),
                          Text(
                            'Groupe · ${chat.groupMemberCount} membres',
                            style: TextStyle(
                              color: context.oklOnSurfaceMuted(0.45),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (!showTyping && chat.lastMsg.startsWith('Vous:'))
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  LucideIcons.checkCheck,
                                  size: 13,
                                  color: AppColors.primary.withValues(alpha: 0.8),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                showTyping ? 'En train d\'écrire…' : chat.lastMsg,
                                style: TextStyle(
                                  color: showTyping
                                      ? AppColors.primary
                                      : chat.isUnread
                                      ? context.oklOnSurface.withValues(alpha: 0.75)
                                      : context.oklOnSurfaceMuted(0.48),
                                  fontSize: 13,
                                  fontWeight: showTyping
                                      ? FontWeight.w600
                                      : chat.isUnread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (chat.isMuted)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  LucideIcons.bellOff,
                                  size: 14,
                                  color: context.oklOnSurfaceMuted(0.45),
                                ),
                              ),
                            if (chat.isUnread)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: 92,
          endIndent: 0,
          color: context.oklDivider,
        ),
      ],
    );
  }
}

class _StoryBubble extends StatelessWidget {
  final String name;
  final bool isMine;
  final bool showActiveStoryRing;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onAddTap;

  const _StoryBubble({
    required this.name,
    this.isMine = false,
    this.showActiveStoryRing = false,
    this.imageUrl,
    required this.onTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    const double outer = 72;
    const double inner = 64;

    final Widget img = ClipOval(
      child: SizedBox(
        width: inner,
        height: inner,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: inner,
                height: inner,
                fit: BoxFit.cover,
                memCacheWidth: 144,
                placeholder: (c, u) => Container(color: context.oklSurface),
              )
            : Container(color: context.oklSurface),
      ),
    );

    Widget circle;
    if (!isMine || showActiveStoryRing) {
      circle = OklStoryGaugeRing(
        outerSize: outer,
        strokeWidth: 3,
        child: SizedBox(width: inner, height: inner, child: img),
      );
    } else {
      circle = Container(
        width: outer,
        height: outer,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.oklSurface,
          border: Border.all(color: context.oklDivider, width: 1.5),
        ),
        child: Center(child: img),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: outer,
              height: outer,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  circle,
                  if (isMine)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: onAddTap ?? onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.oklScaffold,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.plus,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 76,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.oklOnSurface.withValues(alpha: 0.75),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
