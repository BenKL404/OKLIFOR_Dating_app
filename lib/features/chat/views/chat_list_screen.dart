import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
import '../data/chat_api_mapping.dart';
import '../data/chat_websocket_client.dart';
import '../models/chat_models.dart';
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
  static const _mineStoryUrl =
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80&auto=format&fit=crop';
  static const _mineStatusImageUrl =
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200&q=85&auto=format&fit=crop';

  late List<ChatThread> _threads;
  TextStatusPublishResult? _myTextStatus;
  String? _myMediaStatusLocalPath;
  String _myMediaStatusCaption = 'Mon humeur du jour.';

  bool _searchMode = false;
  bool _showArchived = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  ChatWebSocketClient? _wsClient;
  StreamSubscription<dynamic>? _wsMessageSub;
  StreamSubscription<dynamic>? _wsPresenceSub;
  StreamSubscription<dynamic>? _wsTypingSub;
  String? _myUserId;
  final Map<String, bool> _typingByThreadId = <String, bool>{};
  final Map<String, Timer> _typingHideTimersByThreadId = <String, Timer>{};

  @override
  void initState() {
    super.initState();
    _threads = List<ChatThread>.from(kSeedThreads);
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _tryLoadRemoteThreads(),
    );
  }

  Future<void> _tryLoadRemoteThreads() async {
    try {
      final api = ref.read(okliforApiClientProvider);
      final storage = ref.read(authTokenStorageProvider);
      final myId = await storage.readUserId();
      final token = await storage.readAccessToken();
      final raw = await api.fetchChatThreads();
      final contacts = await api.fetchContacts();
      final contactNameById = <String, String>{
        for (final c in contacts) c.userId: c.displayName,
      };
      final mapped = raw
          .map(
            (p) => chatThreadFromPayload(
              p,
              myUserId: myId,
              contactNameById: contactNameById,
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _threads = mapped;
        _myUserId = myId;
      });
      if (token != null && token.isNotEmpty) {
        await _connectRealtime(token, mapped.map((e) => e.id).toList());
      }
    } catch (_) {
      // Pas de token / API : on garde les conversations démo.
    }
  }

  Future<void> _connectRealtime(String token, List<String> threadIds) async {
    await _wsMessageSub?.cancel();
    await _wsPresenceSub?.cancel();
    await _wsTypingSub?.cancel();
    await _wsClient?.dispose();
    final client = ChatWebSocketClient();
    await client.connect(accessToken: token);
    for (final id in threadIds) {
      await client.subscribeThread(id);
    }
    _wsClient = client;
    _wsMessageSub = client.messages.listen(_applyIncomingRealtimeMessage);
    _wsPresenceSub = client.presence.listen(_applyIncomingPresence);
    _wsTypingSub = client.typing.listen(_applyIncomingTyping);
  }

  void _applyIncomingRealtimeMessage(dynamic payload) {
    if (!mounted) return;
    final p = payload;
    final threadId = p.threadId as String;
    final kind = (p.kind as String).toUpperCase();
    final mine = _myUserId != null && p.senderUserId == _myUserId;
    final preview = _previewForRealtime(kind, p.text as String?);
    final last = mine ? 'Vous: $preview' : preview;
    final t = _formatTimeRealtime(p.createdAt as String?);

    setState(() {
      final i = _threads.indexWhere((x) => x.id == threadId);
      if (i < 0) return;
      final updated = _threads[i].copyWith(
        lastMsg: last,
        time: t,
        isUnread: mine ? false : true,
        unreadCount: mine ? 0 : (_threads[i].unreadCount + 1),
      );
      _typingHideTimersByThreadId.remove(threadId)?.cancel();
      _typingByThreadId[threadId] = false;
      _threads.removeAt(i);
      _threads.insert(0, updated);
    });
  }

  void _applyIncomingPresence(dynamic payload) {
    if (!mounted) return;
    final p = payload;
    if (_myUserId != null && p.userId == _myUserId) return;
    final threadId = p.threadId as String;
    final online = p.online as bool;
    setState(() {
      final i = _threads.indexWhere((x) => x.id == threadId);
      if (i < 0) return;
      _threads[i] = _threads[i].copyWith(online: online);
      if (online) {
        _typingHideTimersByThreadId.remove(threadId)?.cancel();
        _typingByThreadId[threadId] = false;
      }
    });
  }

  void _applyIncomingTyping(dynamic payload) {
    if (!mounted) return;
    final p = payload;
    if (_myUserId != null && p.userId == _myUserId) return;
    final threadId = p.threadId as String;
    final typing = p.typing as bool;
    _typingHideTimersByThreadId.remove(threadId)?.cancel();
    if (!typing) {
      _typingHideTimersByThreadId[threadId] = Timer(
        const Duration(milliseconds: 900),
        () {
          if (!mounted) return;
          setState(() {
            final i = _threads.indexWhere((x) => x.id == threadId);
            if (i < 0) return;
            _typingByThreadId[threadId] = false;
          });
        },
      );
      return;
    }
    setState(() {
      final i = _threads.indexWhere((x) => x.id == threadId);
      if (i < 0) return;
      _typingByThreadId[threadId] = typing;
    });
  }

  static String _previewForRealtime(String kind, String? text) {
    if (text != null && text.trim().isNotEmpty) return text.trim();
    switch (kind) {
      case 'IMAGE':
        return '📷 Photo';
      case 'VIDEO':
        return '🎬 Vidéo';
      case 'VOICE':
        return '🎤 Message vocal';
      case 'LOCATION':
        return '📍 Position';
      default:
        return 'Message';
    }
  }

  static String _formatTimeRealtime(String? iso) {
    final dt = iso == null ? null : DateTime.tryParse(iso);
    if (dt == null) return formatTimeNow();
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _wsMessageSub?.cancel();
    _wsPresenceSub?.cancel();
    _wsTypingSub?.cancel();
    for (final t in _typingHideTimersByThreadId.values) {
      t.cancel();
    }
    _typingHideTimersByThreadId.clear();
    _wsClient?.dispose();
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
    final active = _threads.where((c) => !c.isArchived);
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
    final archived = _threads.where((c) => c.isArchived);
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

  List<StatusStory> _storiesForViewer() {
    final mine = _myTextStatus != null
        ? StatusStory(
            name: 'Mon statut',
            avatarUrl: _mineStoryUrl,
            imageUrl: '',
            caption: _myTextStatus!.text,
            timeAgo: 'à l’instant',
            solidBackground: _myTextStatus!.backgroundColor,
          )
        : (_myMediaStatusLocalPath != null &&
              _myMediaStatusLocalPath!.isNotEmpty)
        ? StatusStory(
            name: 'Mon statut',
            avatarUrl: _mineStoryUrl,
            imageUrl: _myMediaStatusLocalPath!,
            caption: _myMediaStatusCaption,
            timeAgo: 'à l’instant',
          )
        : StatusStory(
            name: 'Mon statut',
            avatarUrl: _mineStoryUrl,
            imageUrl: _mineStatusImageUrl,
            caption: 'Mon humeur du jour.',
            timeAgo: 'à l’instant',
          );
    return [
      mine,
      ..._threads
          .where((c) => c.hasStory)
          .map(
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
                    color:
                        Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                    color:
                        Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                  final r = await Navigator.of(context, rootNavigator: true)
                      .push<TextStatusPublishResult>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => const CreateTextStatusScreen(),
                        ),
                      );
                  if (!mounted || r == null) return;
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
                    color:
                        Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                    color:
                        Theme.of(ctx).textTheme.bodyMedium?.color ??
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
    // Demander les permissions uniquement quand l'utilisateur veut publier
    // un statut média.
    if (source == ImageSource.camera) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        if (!mounted || !context.mounted) return;
        if (cam.isPermanentlyDenied) {
          OklFeedback.alert(
            context,
            title: 'Permission requise',
            message:
                'L’accès a été refusé définitivement. Active la permission dans les réglages du téléphone.',
          );
        } else {
          OklFeedback.alert(
            context,
            title: 'Permission refusée',
            message: 'Impossible d’utiliser la caméra sans autorisation.',
          );
        }
        return;
      }
      if (isVideo) {
        final mic = await Permission.microphone.request();
        if (!mic.isGranted) {
          if (!mounted || !context.mounted) return;
          if (mic.isPermanentlyDenied) {
            OklFeedback.alert(
              context,
              title: 'Permission requise',
              message:
                  'Le micro a été refusé. Active la permission dans les réglages pour filmer avec le son.',
            );
          } else {
            OklFeedback.alert(
              context,
              title: 'Permission refusée',
              message: 'Sans micro, la vidéo peut être refusée par l’appareil.',
            );
          }
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
      _myMediaStatusLocalPath = xFile.path;
      _myMediaStatusCaption = 'Mon statut média.';
    });

    if (!context.mounted) return;
    OklFlows.pushResult(
      context,
      icon: isVideo ? LucideIcons.video : LucideIcons.image,
      title: isVideo ? 'Vidéo ajoutée' : 'Photo ajoutée',
      subtitle:
          'Ton statut média est prêt. Les contacts le verront dans la barre des statuts.',
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
                  color:
                      Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                    color:
                        Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                  color:
                      Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                  'Jusqu’à 8 personnes (démo)',
                  style: TextStyle(
                    color:
                        Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                  color:
                      Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                  'Ouvre l’appareil ou la galerie',
                  style: TextStyle(
                    color:
                        Theme.of(ctx).textTheme.bodyMedium?.color ??
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
    String id = 'dm_${c.id}';
    try {
      final api = ref.read(okliforApiClientProvider);
      final storage = ref.read(authTokenStorageProvider);
      final myId = await storage.readUserId();
      final remote = await api.createDirectThread(c.id);
      final mapped = chatThreadFromPayload(
        remote,
        myUserId: myId,
        contactNameById: {c.id: c.name},
      );
      id = mapped.id;
      final remoteIdx = _threads.indexWhere((t) => t.id == mapped.id);
      if (remoteIdx >= 0) {
        setState(() => _threads[remoteIdx] = mapped);
      } else {
        setState(() => _threads.insert(0, mapped));
      }
    } catch (_) {
      // Mode dégradé: création locale si API indisponible.
    }
    final idx = _threads.indexWhere((t) => t.id == id);
    final ChatThread thread;
    if (idx >= 0) {
      thread = _threads[idx];
    } else {
      thread = ChatThread(
        id: id,
        name: c.name,
        lastMsg: 'Nouvelle conversation',
        time: formatTimeNow(),
        avatarUrl: c.avatarUrl,
        statusImageUrl: '',
        statusCaption: '',
        statusTimeAgo: '',
        online: true,
      );
      setState(() => _threads.insert(0, thread));
    }
    if (!mounted) return;
    _openConversation(context, thread);
  }

  Future<void> _openCreateGroupFlow() async {
    final r = await Navigator.of(context, rootNavigator: true)
        .push<CreateGroupResult>(
          MaterialPageRoute<CreateGroupResult>(
            builder: (_) => const CreateGroupScreen(),
          ),
        );
    if (!mounted || r == null) return;
    final id = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final thread = ChatThread(
      id: id,
      name: r.name,
      lastMsg: 'Groupe créé — dis bonjour 👋',
      time: formatTimeNow(),
      avatarUrl: r.members.first.avatarUrl,
      statusImageUrl: r.members.length > 1
          ? r.members[1].avatarUrl
          : r.members.first.avatarUrl,
      statusCaption: r.name,
      statusTimeAgo: 'à l’instant',
      isGroup: true,
      groupMemberCount: r.members.length,
      online: false,
    );
    setState(() => _threads.insert(0, thread));
    _openConversation(context, thread);
  }

  void _updateThreadById(
    String threadId,
    ChatThread Function(ChatThread current) transform,
  ) {
    if (!mounted) return;
    setState(() {
      final i = _threads.indexWhere((t) => t.id == threadId);
      if (i < 0) return;
      _threads[i] = transform(_threads[i]);
    });
  }

  void _removeThreadById(String threadId) {
    if (!mounted) return;
    setState(() => _threads.removeWhere((t) => t.id == threadId));
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
                _updateThreadById(
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
                _updateThreadById(chat.id, (current) {
                  return current.copyWith(isMuted: !current.isMuted);
                });
              },
            ),
            _SheetAction(
              icon: chat.isUnread ? LucideIcons.checkCheck : LucideIcons.circle,
              label: chat.isUnread
                  ? 'Marquer comme lu'
                  : 'Marquer comme non lu',
              onTap: () {
                Navigator.pop(ctx);
                _updateThreadById(chat.id, (current) {
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
                _updateThreadById(
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
                  onConfirm: () => _removeThreadById(chat.id),
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
        builder: (_) => ConversationScreen(
          thread: chat,
          onThreadPreviewUpdated: (last, time) {
            if (!mounted) return;
            setState(() {
              final i = _threads.indexWhere((t) => t.id == chat.id);
              if (i >= 0) {
                final updated = _threads[i].copyWith(
                  lastMsg: 'Vous: $last',
                  time: time,
                  isUnread: false,
                  unreadCount: 0,
                );
                _threads.removeAt(i);
                _threads.insert(0, updated);
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleChats = _visibleChats;
    final archivedChats = _archivedChats;
    final hasArchived = archivedChats.isNotEmpty;
    final extraArchivedItems = (hasArchived && _showArchived)
        ? archivedChats.length
        : 0;
    final totalItems =
        visibleChats.length + (hasArchived ? 1 : 0) + extraArchivedItems;
    final isDark = context.oklMeetIsDark;
    final titleColor = isDark ? Colors.white : context.oklOnSurface;

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
                                      final results = _visibleChats;
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              ChatSearchResultsScreen(
                                                query: t,
                                                threads: results,
                                                onThreadUpdated:
                                                    (id, last, time) {
                                                      if (!mounted) return;
                                                      setState(() {
                                                        final i = _threads
                                                            .indexWhere(
                                                              (x) => x.id == id,
                                                            );
                                                        if (i >= 0) {
                                                          _threads[i] =
                                                              _threads[i]
                                                                  .copyWith(
                                                                    lastMsg:
                                                                        last,
                                                                    time: time,
                                                                    isUnread:
                                                                        false,
                                                                    unreadCount:
                                                                        0,
                                                                  );
                                                        }
                                                      });
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
                                Container(
                                  width: 3,
                                  height: 36,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.togoGreen,
                                        AppColors.togoGold,
                                        AppColors.togoRed,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Messages',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.85,
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
                                  onPressed: () => _openComposeMenu(context),
                                  useOverlayStyle: isDark,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _StoryBubble(
                      name: 'Mon statut',
                      isMine: true,
                      showActiveStoryRing: _myTextStatus != null,
                      imageUrl: _mineStoryUrl,
                      onTap: () => _openStatusViewer(context, 0),
                      onAddTap: () => _openMyStatusAddMenu(context),
                    ),
                    ..._threads
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
                            onTap: () => _openStatusViewer(context, idx + 1),
                          );
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: context.oklDivider),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: oklMainShellListBottomPadding(context),
                  ),
                  itemCount: totalItems,
                  itemBuilder: (context, i) {
                    final archiveHeaderIndex = hasArchived ? 0 : -1;
                    final archivedStartIndex = hasArchived ? 1 : 0;
                    final activeStartIndex =
                        archivedStartIndex + extraArchivedItems;

                    if (hasArchived && i == archiveHeaderIndex) {
                      return Column(
                        children: [
                          _ArchiveHeaderTile(
                            count: archivedChats.length,
                            expanded: _showArchived,
                            onTap: () =>
                                setState(() => _showArchived = !_showArchived),
                          ),
                          Divider(height: 1, color: context.oklDivider),
                        ],
                      );
                    }

                    if (hasArchived &&
                        _showArchived &&
                        i >= archivedStartIndex &&
                        i < activeStartIndex) {
                      final archivedIndex = i - archivedStartIndex;
                      final chat = archivedChats[archivedIndex];
                      final isLastArchived =
                          archivedIndex == archivedChats.length - 1;
                      return Column(
                        children: [
                          _ChatTile(
                            chat: chat,
                            showTyping: _typingByThreadId[chat.id] ?? false,
                            onTap: () => _openConversation(context, chat),
                            onLongPress: () => _openChatActions(context, chat),
                          ),
                          if (!isLastArchived)
                            Divider(
                              height: 1,
                              color: context.oklDivider,
                              indent: 76,
                            ),
                        ],
                      );
                    }

                    final activeIndex = i - activeStartIndex;
                    final chat = visibleChats[activeIndex];
                    return Column(
                      children: [
                        _ChatTile(
                          chat: chat,
                          showTyping: _typingByThreadId[chat.id] ?? false,
                          onTap: () => _openConversation(context, chat),
                          onLongPress: () => _openChatActions(context, chat),
                        ),
                        Divider(
                          height: 1,
                          color: context.oklDivider,
                          indent: 76,
                        ),
                      ],
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
          child: const Icon(LucideIcons.messageSquarePlus, color: Colors.white),
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
                color: context.oklOnSurfaceMuted(0.62),
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
                  color: context.oklOnSurfaceMuted(0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                color: context.oklOnSurfaceMuted(0.55),
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
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
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
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: InkWell(
          onTap: onTap,
          splashColor: context.oklSurface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    chat.hasStory
                        ? OklStoryGaugeRing(
                            outerSize: 56,
                            strokeWidth: 2,
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: context.oklScaffold,
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: context.oklSurface,
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
                                        color: context.oklSurface,
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
                                      errorWidget: (c, u, e) => Icon(
                                        LucideIcons.user,
                                        color: context.oklOnSurfaceMuted(0.55),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: context.oklScaffold,
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: context.oklSurface,
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
                                      color: context.oklSurface,
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
                                    errorWidget: (c, u, e) => Icon(
                                      LucideIcons.user,
                                      color: context.oklOnSurfaceMuted(0.55),
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
                            border: Border.all(
                              color: context.oklScaffold,
                              width: 2,
                            ),
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
                          color: context.oklOnSurface,
                          fontSize: 15,
                          fontWeight: chat.isUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (chat.isGroup) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Groupe · ${chat.groupMemberCount} membres',
                          style: TextStyle(
                            color: context.oklOnSurfaceMuted(0.52),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (!showTyping && chat.lastMsg.startsWith('Vous:'))
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                LucideIcons.checkCheck,
                                size: 14,
                                color: chat.isUnread
                                    ? context.oklOnSurfaceMuted(0.62)
                                    : AppColors.primary,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              showTyping ? 'Écrit…' : chat.lastMsg,
                              style: TextStyle(
                                color: showTyping
                                    ? AppColors.primary
                                    : chat.isUnread
                                    ? (Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color ??
                                          context.oklOnSurfaceMuted(0.62))
                                    : context.oklOnSurfaceMuted(0.55),
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
                        ],
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
                        color: chat.isUnread
                            ? AppColors.primary
                            : context.oklOnSurfaceMuted(0.55),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 24,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (chat.isMuted)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                LucideIcons.bellOff,
                                size: 16,
                                color: context.oklOnSurfaceMuted(0.55),
                              ),
                            ),
                          if (chat.isUnread && chat.unreadCount > 0)
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
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
                          else if (!chat.isMuted)
                            const SizedBox(width: 22, height: 22),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  final String name;
  final bool isMine;

  /// Anneau jauge rouge (ex. statut texte publié à l’instant).
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
                  if (!isMine || showActiveStoryRing)
                    OklStoryGaugeRing(
                      outerSize: 58,
                      strokeWidth: 2.5,
                      child: SizedBox(
                        width: 52,
                        height: 52,
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
                                        color: context.oklSurface,
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
                                    color: context.oklSurface,
                                  ),
                                ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.oklSurface,
                        border: Border.all(
                          color: context.oklDivider,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: ClipOval(
                          child: imageUrl != null
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
                                  color: context.oklSurface,
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
                            border: Border.all(
                              color: context.oklScaffold,
                              width: 1.8,
                            ),
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
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      context.oklOnSurfaceMuted(0.62),
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
