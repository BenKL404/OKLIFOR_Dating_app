import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/okl_chat_attachment_launch.dart';
import '../../../core/utils/okl_media_cache.dart';
import '../models/chat_models.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.messages,
    required this.initialIndex,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;
  bool _uiVisible = true;

  // drag-to-dismiss
  double _dragDy = 0;
  bool _dragging = false;
  bool _zoomed = false;

  // snap-back animation
  late final AnimationController _snapAnim;
  late Animation<double> _snapTween;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _snapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (mounted) setState(() => _dragDy = _snapTween.value);
      });
    _snapTween = const AlwaysStoppedAnimation(0.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _snapAnim.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    final root = Navigator.of(context, rootNavigator: true);
    if (root.canPop()) {
      root.pop();
      return;
    }
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  double get _dismissFraction => (_dragDy.abs() / 300.0).clamp(0.0, 1.0);
  double get _bgAlpha => (1.0 - _dismissFraction * 0.9).clamp(0.0, 1.0);
  double get _imgScale => (1.0 - _dismissFraction * 0.22).clamp(0.72, 1.0);

  void _onDragStart(DragStartDetails _) {
    if (_zoomed) return;
    _snapAnim.stop();
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    setState(() => _dragDy += d.delta.dy);
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_dragging) return;
    final velocity = d.velocity.pixelsPerSecond.dy;
    if (_dismissFraction > 0.32 || velocity.abs() > 700) {
      _close();
      return;
    }
    final from = _dragDy;
    _snapTween = Tween<double>(begin: from, end: 0).animate(
      CurvedAnimation(parent: _snapAnim, curve: Curves.easeOutCubic),
    );
    _dragDy = 0;
    _dragging = false;
    _snapAnim.forward(from: 0);
  }

  void _showMoreMenu(BuildContext context, ChatMessage msg, String url) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final caption = (msg.text ?? '').trim();
        final isVideo = msg.kind == ChatMessageKind.video;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.share2, color: Colors.white70),
                title: const Text('Partager', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  shareChatAttachmentUrl(
                    context,
                    url,
                    displayName: caption.isEmpty ? (isVideo ? 'video.mp4' : 'image.jpg') : caption,
                  );
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.save, color: Colors.white70),
                title: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  saveChatFileToDownloads(context, url, displayName: caption);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.download, color: Colors.white70),
                title: const Text('Sauver dans la galerie', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  saveChatMediaToGallery(
                    context,
                    url,
                    displayName: caption,
                    isVideo: isVideo,
                  );
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();
    final currentMsg = widget.messages[_currentIndex];
    final caption = (currentMsg.text ?? '').trim();
    const sender = ''; 
    final sentAt = (currentMsg.time).trim();
    final isVideo = currentMsg.kind == ChatMessageKind.video;
    final url = (isVideo ? currentMsg.videoUrl : currentMsg.imageUrl) ?? '';

    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Opacity(
            opacity: _bgAlpha,
            child: const ColoredBox(color: Colors.black),
          ),
          
          // Media Pager
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() => _uiVisible = !_uiVisible),
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Transform.translate(
              offset: Offset(0, _dragging ? _dragDy : _snapTween.value),
              child: Transform.scale(
                scale: _imgScale,
                child: PageView.builder(
                  controller: _pageController,
                  physics: _zoomed || _dragging ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                  onPageChanged: (idx) => setState(() {
                    _currentIndex = idx;
                    _zoomed = false;
                  }),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.messages[index];
                    if (msg.kind == ChatMessageKind.video) {
                      return _VideoItem(
                        url: msg.videoUrl ?? '',
                        caption: msg.text ?? '',
                        tag: 'chat_img_${msg.id}',
                        isActive: index == _currentIndex,
                        onZoomChanged: (z) {
                          if (z != _zoomed) setState(() => _zoomed = z);
                        },
                      );
                    }
                    return _ImageItem(
                      url: msg.imageUrl ?? '',
                      caption: msg.text ?? '',
                      tag: 'chat_img_${msg.id}',
                      onZoomChanged: (z) {
                        if (z != _zoomed) setState(() => _zoomed = z);
                      },
                      uiVisible: _uiVisible,
                      onUiVisibilityChange: (v) {
                        if (_uiVisible != v) setState(() => _uiVisible = v);
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // Overlay UI
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _uiVisible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_uiVisible,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.only(top: topPad + 2, left: 2, right: 6, bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.78), Colors.transparent],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _close,
                          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 22),
                        ),
                        Expanded(
                          child: sender.isEmpty && sentAt.isEmpty
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (sender.isNotEmpty)
                                      Text(
                                        sender,
                                        style: const TextStyle(
                                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2,
                                        ),
                                      ),
                                    if (sentAt.isNotEmpty)
                                      Text(
                                        sentAt,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.58), fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        IconButton(
                          tooltip: 'Galerie',
                          onPressed: () => saveChatMediaToGallery(
                            context, url, displayName: caption, isVideo: isVideo,
                          ),
                          icon: Icon(LucideIcons.download, color: Colors.white.withValues(alpha: 0.9), size: 20),
                        ),
                        IconButton(
                          tooltip: 'Plus',
                          onPressed: () => _showMoreMenu(context, currentMsg, url),
                          icon: Icon(LucideIcons.moreVertical, color: Colors.white.withValues(alpha: 0.9), size: 20),
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
    );
  }
}

class _TgBottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TgBottomAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageItem extends StatefulWidget {
  final String url;
  final String caption;
  final String tag;
  final ValueChanged<bool> onZoomChanged;
  final bool uiVisible;
  final ValueChanged<bool> onUiVisibilityChange;

  const _ImageItem({
    required this.url,
    required this.caption,
    required this.tag,
    required this.onZoomChanged,
    required this.uiVisible,
    required this.onUiVisibilityChange,
  });

  @override
  State<_ImageItem> createState() => _ImageItemState();
}

class _ImageItemState extends State<_ImageItem> {
  final TransformationController _transform = TransformationController();
  bool _localZoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(() {
      final s = _transform.value.getMaxScaleOnAxis();
      final z = s > 1.05;
      if (z != _localZoomed) {
        _localZoomed = z;
        widget.onZoomChanged(z);
      }
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (_transform.value.getMaxScaleOnAxis() > 1.1) {
      _transform.value = Matrix4.identity();
      widget.onZoomChanged(false);
    } else {
      // Zoom to 2.5x
      final zoom = Matrix4.identity()..scaleByDouble(2.5);
      _transform.value = zoom;
      widget.onZoomChanged(true);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onDoubleTap: _onDoubleTap,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 0.8,
            maxScale: 6.0,
            onInteractionStart: (_) {
              if (widget.uiVisible) widget.onUiVisibilityChange(false);
            },
            child: Hero(
              tag: widget.tag,
              child: Material(
                color: Colors.transparent,
                child: SizedBox.expand(
                  child: CachedNetworkImage(
                    imageUrl: widget.url,
                    cacheManager: oklChatMediaCache,
                    fit: BoxFit.contain,
                    memCacheWidth: 1600,
                    placeholder: (c, u) => const Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (c, u, e) => const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 64),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _ImageBottomOverlay(
          url: widget.url,
          caption: widget.caption,
          uiVisible: widget.uiVisible,
        ),
      ],
    );
  }
}

class _ImageBottomOverlay extends StatelessWidget {
  final String url;
  final String caption;
  final bool uiVisible;

  const _ImageBottomOverlay({
    required this.url,
    required this.caption,
    required this.uiVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: uiVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !uiVisible,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.paddingOf(context).bottom + 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption.isNotEmpty) ...[
                  Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TgBottomAction(
                      icon: LucideIcons.share2,
                      label: 'Partager',
                      onTap: () => shareChatAttachmentUrl(context, url, displayName: caption),
                    ),
                    _TgBottomAction(
                      icon: LucideIcons.save,
                      label: 'Enregistrer',
                      onTap: () => saveChatFileToDownloads(context, url, displayName: caption),
                    ),
                    _TgBottomAction(
                      icon: LucideIcons.download,
                      label: 'Galerie',
                      onTap: () => saveChatMediaToGallery(context, url, displayName: caption, isVideo: false),
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

class _VideoItem extends StatefulWidget {
  final String url;
  final String caption;
  final String tag;
  final bool isActive;
  final ValueChanged<bool> onZoomChanged;

  const _VideoItem({
    required this.url,
    required this.caption,
    required this.tag,
    required this.isActive,
    required this.onZoomChanged,
  });

  @override
  State<_VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<_VideoItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;
  final TransformationController _transform = TransformationController();
  bool _localZoomed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _transform.addListener(() {
      final s = _transform.value.getMaxScaleOnAxis();
      final z = s > 1.05;
      if (z != _localZoomed) {
        _localZoomed = z;
        widget.onZoomChanged(z);
      }
    });
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (widget.isActive && mounted) {
        _controller!.play();
      }
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void didUpdateWidget(_VideoItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) {
      if (widget.isActive) {
        _controller?.play();
      } else {
        _controller?.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (_transform.value.getMaxScaleOnAxis() > 1.1) {
      _transform.value = Matrix4.identity();
      widget.onZoomChanged(false);
    } else {
      // Zoom to 2.0x
      final zoom = Matrix4.identity()..scaleByDouble(2.0);
      _transform.value = zoom;
      widget.onZoomChanged(true);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 64),
      );
    }
    if (!_initialized || _controller == null) {
      return const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onDoubleTap: _onDoubleTap,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 0.8,
            maxScale: 6.0,
            child: Hero(
              tag: widget.tag,
              child: Material(
                color: Colors.transparent,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Place controls at bottom of the PAGE, not on the video center
        _VideoControlsOverlay(
          url: widget.url,
          controller: _controller!,
          caption: widget.caption,
          uiVisible: widget.isActive,
        ),
      ],
    );
  }
}

class _VideoControlsOverlay extends StatefulWidget {
  final String url;
  final VideoPlayerController controller;
  final String caption;
  final bool uiVisible;

  const _VideoControlsOverlay({
    required this.url,
    required this.controller,
    required this.caption,
    required this.uiVisible,
  });

  @override
  State<_VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<_VideoControlsOverlay> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.controller.value.isPlaying;
    _position = widget.controller.value.position;
    _duration = widget.controller.value.duration;
    widget.controller.addListener(_listener);
  }

  void _listener() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.controller.value.isPlaying;
        _position = widget.controller.value.position;
        _duration = widget.controller.value.duration;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _skip(int seconds) {
    var newPos = _position + Duration(seconds: seconds);
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > _duration) newPos = _duration;
    widget.controller.seekTo(newPos);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.uiVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !widget.uiVisible,
        child: Stack(
          children: [
            // Tap to play/pause in center
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _isPlaying ? widget.controller.pause() : widget.controller.play(),
              child: Center(
                child: AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.play, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),

            // Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.caption.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          widget.caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    // Progress Bar
                    Row(
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              overlayColor: Colors.white10,
                            ),
                            child: Slider(
                              value: _position.inMilliseconds.toDouble(),
                              max: _duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                              onChanged: (v) => widget.controller.seekTo(Duration(milliseconds: v.toInt())),
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ControlButton(
                          icon: LucideIcons.rotateCcw,
                          onTap: () => _skip(-10),
                          label: '-10s',
                        ),
                        const SizedBox(width: 40),
                        _ControlButton(
                          icon: _isPlaying ? LucideIcons.pause : LucideIcons.play,
                          onTap: () => _isPlaying ? widget.controller.pause() : widget.controller.play(),
                          size: 32,
                        ),
                        const SizedBox(width: 40),
                        _ControlButton(
                          icon: LucideIcons.rotateCw,
                          onTap: () => _skip(10),
                          label: '+10s',
                        ),
                      ],
                    ),
                    // const SizedBox(height: 20),
                    // // Actions (Telegram style)
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //   children: [
                    //     _TgBottomAction(
                    //       icon: LucideIcons.share2,
                    //       label: 'Partager',
                    //       onTap: () => shareChatAttachmentUrl(context, widget.url, displayName: widget.caption),
                    //     ),
                    //     _TgBottomAction(
                    //       icon: LucideIcons.save,
                    //       label: 'Enregistrer',
                    //       onTap: () => saveChatFileToDownloads(context, widget.url, displayName: widget.caption),
                    //     ),
                    //     _TgBottomAction(
                    //       icon: LucideIcons.download,
                    //       label: 'Galerie',
                    //       onTap: () => saveChatMediaToGallery(context, widget.url, displayName: widget.caption, isVideo: true),
                    //     ),
                    //   ],
                    // ),
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

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final String? label;

  const _ControlButton({required this.icon, required this.onTap, this.size = 24, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: size),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
