import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_feedback.dart';
import '../models/chat_models.dart';
import 'chat_image_viewer_screen.dart';
import 'chat_thread_detail_screen.dart';
import 'conversation_search_screen.dart';
import 'conversation_media_screen.dart';
import 'conversation_mute_screen.dart';
import 'share_contact_screen.dart';

/// Conversation 1:1 ou groupe avec bulles riches (texte, image, vocal, lieu, système).
class ConversationScreen extends StatefulWidget {
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
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _canSend = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordTimer;
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List<ChatMessage>.from(
      widget.initialMessagesOverride ??
          seedMessagesForThread(widget.thread.id),
    );
    _messageController.addListener(_syncSendState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _messageController.removeListener(_syncSendState);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  String _labelForKind(ChatMessageKind k) {
    switch (k) {
      case ChatMessageKind.image:
        return '📷 Photo';
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

  void _toggleRecording() {
    if (_isRecording) {
      final duration = _formatDuration(_recordingSeconds);
      _recordTimer?.cancel();
      setState(() => _isRecording = false);
      final msg = ChatMessage(
        id: 'v${DateTime.now().millisecondsSinceEpoch}',
        kind: ChatMessageKind.voice,
        voiceSeconds: _recordingSeconds.clamp(1, 999),
        mine: true,
        time: formatTimeNow(),
      );
      setState(() {
        _messages.add(msg);
        _recordingSeconds = 0;
      });
      _afterAppend();
      OklFlows.pushResult(
        context,
        icon: LucideIcons.mic,
        title: 'Note vocale envoyée',
        subtitle: 'Durée : $duration — ton message est dans la conversation.',
        primaryLabel: 'OK',
      );
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

  void _sendText() {
    final txt = _messageController.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          id: 't${DateTime.now().millisecondsSinceEpoch}',
          kind: ChatMessageKind.text,
          text: txt,
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
                      _pushDemoMessage(
                        ChatMessage(
                          id: 'doc${DateTime.now().millisecondsSinceEpoch}',
                          kind: ChatMessageKind.text,
                          text: '📄 document_contrat.pdf (démo)',
                          mine: true,
                          time: formatTimeNow(),
                        ),
                      );
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.image,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(ctx);
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
                    },
                  ),
                  _AttachTile(
                    icon: LucideIcons.camera,
                    label: 'Caméra',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pushDemoMessage(
                        ChatMessage(
                          id: 'cam${DateTime.now().millisecondsSinceEpoch}',
                          kind: ChatMessageKind.image,
                          imageUrl:
                              'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=600&q=80&auto=format&fit=crop',
                          mine: true,
                          time: formatTimeNow(),
                        ),
                      );
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
                      _pushDemoMessage(
                        ChatMessage(
                          id: 'loc${DateTime.now().millisecondsSinceEpoch}',
                          kind: ChatMessageKind.location,
                          locationLabel: 'Boulevard du 13 janvier, Lomé',
                          mine: true,
                          time: formatTimeNow(),
                        ),
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
                              _pushDemoMessage(
                                ChatMessage(
                                  id: 'vc${DateTime.now().millisecondsSinceEpoch}',
                                  kind: ChatMessageKind.text,
                                  text: '👤 Contact partagé : ${c.name}',
                                  mine: true,
                                  time: formatTimeNow(),
                                ),
                              );
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
                      _pushDemoMessage(
                        ChatMessage(
                          id: 'aud${DateTime.now().millisecondsSinceEpoch}',
                          kind: ChatMessageKind.text,
                          text: '🎵 ma_piste_audio.m4a (démo)',
                          mine: true,
                          time: formatTimeNow(),
                        ),
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

  void _pushDemoMessage(ChatMessage m) {
    setState(() => _messages.add(m));
    _afterAppend();
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
                color: Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                color: Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                color: Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                    builder: (_) => ConversationMuteScreen(threadName: widget.thread.name),
                  ),
                );
              },
            ),
            if (widget.thread.isGroup)
              ListTile(
                leading: Icon(
                  LucideIcons.userMinus,
                  color: Theme.of(ctx).textTheme.bodyMedium?.color ??
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
                    body: 'Tu ne recevras plus les messages de « ${widget.thread.name} ».',
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
                          t.isGroup
                              ? '${t.groupMemberCount} membres · Infos du groupe'
                              : (t.online ? 'En ligne · Voir le profil' : 'Hors ligne · Voir le profil'),
                          style: TextStyle(
                            color: t.isGroup
                                ? (Theme.of(context).textTheme.bodyMedium?.color ??
                                    context.oklOnSurfaceMuted(0.62))
                                : (t.online
                                    ? AppColors.green
                                    : (Theme.of(context).textTheme.bodyMedium?.color ??
                                        context.oklOnSurfaceMuted(0.62))),
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
      body: Column(
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
                  child: _RichMessageBubble(
                    message: msg,
                    onTapImage: msg.kind == ChatMessageKind.image
                        ? () => _openImageViewer(msg)
                        : null,
                  ),
                );
              },
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
                          color: context.oklSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: TextField(
                          controller: _messageController,
                          readOnly: _isRecording,
                          style: TextStyle(color: context.oklOnSurface),
                          decoration: InputDecoration(
                            hintText: _isRecording
                                ? 'Enregistrement… ${_formatDuration(_recordingSeconds)}'
                                : 'Message…',
                            hintStyle: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color ??
                                  context.oklOnSurfaceMuted(0.62),
                            ),
                            isDense: true,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            border: InputBorder.none,
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                LucideIcons.smile,
                                size: 18,
                                color: Theme.of(context).textTheme.bodyMedium?.color ??
                                    context.oklOnSurfaceMuted(0.62),
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: _openAttachmentOptions,
                                child: Icon(
                                  LucideIcons.plus,
                                  size: 18,
                                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                                      context.oklOnSurfaceMuted(0.62),
                                ),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
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
                      onPressed: () {
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
                            : (Theme.of(context).textTheme.bodyMedium?.color ??
                                context.oklOnSurfaceMuted(0.62)),
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
    ),
    );
  }
}

class _RichMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTapImage;

  const _RichMessageBubble({
    required this.message,
    this.onTapImage,
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
                color: (Theme.of(context).textTheme.bodyMedium?.color ??
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
        final img = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: m.imageUrl ?? '',
            width: 220,
            fit: BoxFit.cover,
            memCacheWidth: 440,
            placeholder: (c, u) => Container(
              width: 220,
              height: 140,
              color: context.oklSurface,
            ),
          ),
        );
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            child: Column(
              crossAxisAlignment:
                  m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTapImage,
                    borderRadius: BorderRadius.circular(14),
                    child: Hero(
                      tag: heroTag,
                      child: img,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.time,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.55),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      case ChatMessageKind.voice:
        final sec = m.voiceSeconds ?? 0;
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: m.mine
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : context.oklSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.oklDivider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.mic,
                  size: 18,
                  color: m.mine
                      ? AppColors.primary
                      : (Theme.of(context).textTheme.bodyMedium?.color ??
                          context.oklOnSurfaceMuted(0.62)),
                ),
                const SizedBox(width: 10),
                Text(
                  '${sec}s',
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  LucideIcons.play,
                  size: 18,
                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                      context.oklOnSurfaceMuted(0.62),
                ),
                const Spacer(),
                Text(
                  m.time,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.55),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 18),
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
                Text(
                  m.time,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.55),
                    fontSize: 10,
                  ),
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
              crossAxisAlignment:
                  m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  m.text ?? '',
                  style: TextStyle(
                    color: context.oklOnSurface,
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
                        color: context.oklOnSurfaceMuted(0.55),
                        fontSize: 10,
                      ),
                    ),
                    if (m.mine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.checkCheck,
                        size: 12,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
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
                color: Theme.of(context).textTheme.bodyMedium?.color ??
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
