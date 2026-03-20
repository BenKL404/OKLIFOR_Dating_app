import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_feedback.dart';

class StatusStory {
  final String name;
  final String avatarUrl;
  /// Vide si statut texte sur fond [solidBackground].
  final String imageUrl;
  final String caption;
  final String timeAgo;
  final Color? solidBackground;

  const StatusStory({
    required this.name,
    required this.avatarUrl,
    this.imageUrl = '',
    required this.caption,
    required this.timeAgo,
    this.solidBackground,
  });

  bool get isTextOnly =>
      imageUrl.isEmpty && solidBackground != null;
}

class StatusViewerScreen extends StatefulWidget {
  final List<StatusStory> stories;
  final int initialIndex;

  const StatusViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _storyDuration = Duration(seconds: 6);
  static const _closeDragThreshold = 120.0;
  static const _tapMaxDuration = Duration(milliseconds: 220);
  static const _tapMaxDistance = 16.0;
  static const _tapBottomExclusionHeight = 90.0;
  late final PageController _pageController;
  late final AnimationController _progressController;
  int _currentIndex = 0;
  Timer? _autoAdvance;
  final TextEditingController _commentController = TextEditingController();
  bool _canSend = false;
  bool _pausedByTouch = false;
  bool _pausedByKeyboard = false;
  double _verticalDragOffset = 0;
  DateTime? _pointerDownAt;
  Offset? _pointerDownPos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addListener(() => setState(() {}));
    _commentController.addListener(_syncCanSend);
    _startStoryCycle();
  }

  void _syncCanSend() {
    final hasText = _commentController.text.trim().isNotEmpty;
    if (hasText == _canSend) return;
    setState(() => _canSend = hasText);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoAdvance?.cancel();
    _commentController.removeListener(_syncCanSend);
    _commentController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _handleKeyboardStateFromMetrics();
  }

  void _handleKeyboardStateFromMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final keyboardVisible = view.viewInsets.bottom > 0;
    if (keyboardVisible == _pausedByKeyboard) return;
    _pausedByKeyboard = keyboardVisible;
    if (keyboardVisible) {
      _pauseStory();
    } else {
      _resumeStoryIfNeeded();
    }
  }

  void _startStoryCycle() {
    _autoAdvance?.cancel();
    _progressController
      ..reset()
      ..forward();
    _scheduleNextTick(_storyDuration);
  }

  void _scheduleNextTick(Duration duration) {
    _autoAdvance?.cancel();
    if (duration <= Duration.zero) {
      _goNext();
      return;
    }
    _autoAdvance = Timer(duration, _goNext);
  }

  Duration _remainingDuration() {
    final leftMs = (_storyDuration.inMilliseconds * (1 - _progressController.value)).round();
    return Duration(milliseconds: leftMs.clamp(0, _storyDuration.inMilliseconds));
  }

  void _pauseStory() {
    _autoAdvance?.cancel();
    _progressController.stop();
  }

  void _resumeStoryIfNeeded() {
    if (_pausedByTouch || _pausedByKeyboard) return;
    _progressController.forward();
    _scheduleNextTick(_remainingDuration());
  }

  void _goNext() {
    if (_pausedByTouch || _pausedByKeyboard) return;
    if (_currentIndex >= widget.stories.length - 1) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _goPrevious() {
    if (_pausedByTouch || _pausedByKeyboard) return;
    if (_currentIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.stories;
    final current = stories[_currentIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!context.mounted) return;
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          _pausedByTouch = true;
          _pointerDownAt = DateTime.now();
          _pointerDownPos = event.localPosition;
          _pauseStory();
        },
        onPointerUp: (event) {
          final size = MediaQuery.sizeOf(context);
          final downAt = _pointerDownAt;
          final downPos = _pointerDownPos;
          final elapsed = downAt == null ? null : DateTime.now().difference(downAt);
          final moved = downPos == null
              ? double.infinity
              : (event.localPosition - downPos).distance;
          final isTapZone = event.localPosition.dy < (size.height - _tapBottomExclusionHeight);
          final isRealTap = !_pausedByKeyboard &&
              elapsed != null &&
              elapsed <= _tapMaxDuration &&
              moved <= _tapMaxDistance &&
              isTapZone;

          _pausedByTouch = false;
          _resumeStoryIfNeeded();
          _pointerDownAt = null;
          _pointerDownPos = null;

          if (isRealTap) {
            if (event.localPosition.dx < size.width * 0.38) {
              _goPrevious();
            } else {
              _goNext();
            }
          }
        },
        onPointerCancel: (_) {
          _pausedByTouch = false;
          _pointerDownAt = null;
          _pointerDownPos = null;
          _resumeStoryIfNeeded();
        },
        child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          if (details.delta.dy <= 0) return;
          setState(() {
            _verticalDragOffset = (_verticalDragOffset + details.delta.dy).clamp(0, 220);
          });
        },
        onVerticalDragEnd: (_) {
          if (_verticalDragOffset > _closeDragThreshold) {
            Navigator.of(context, rootNavigator: true).pop();
            return;
          }
          setState(() => _verticalDragOffset = 0);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _verticalDragOffset, 0),
          child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: stories.length,
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
              _startStoryCycle();
            },
            itemBuilder: (context, i) {
              final s = stories[i];
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (s.isTextOnly)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            s.solidBackground!,
                            HSLColor.fromColor(s.solidBackground!)
                                .withLightness(
                                  (HSLColor.fromColor(s.solidBackground!)
                                              .lightness *
                                          0.5)
                                      .clamp(0.08, 0.9),
                                )
                                .toColor(),
                          ],
                        ),
                      ),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: s.imageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      memCacheWidth: 1080,
                      placeholder: (c, u) => Container(color: context.oklSurface),
                      errorWidget: (c, u, e) => Container(
                        color: context.oklSurface,
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.imageOff,
                          color: context.oklOnSurfaceMuted(0.55),
                          size: 42,
                        ),
                      ),
                    ),
                  if (!s.isTextOnly)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x66000000),
                            Colors.transparent,
                            Color(0xA6000000)
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 92,
                    child: Text(
                      s.caption,
                      textAlign: s.isTextOnly ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: s.isTextOnly ? 22 : 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < stories.length; i++) ...[
                        Expanded(
                          child: Container(
                            height: 2.6,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: i < _currentIndex
                                  ? 1
                                  : i == _currentIndex
                                      ? _progressController.value
                                      : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (i != stories.length - 1) const SizedBox(width: 4),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: current.avatarUrl,
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
                        child: Text(
                          '${current.name} · ${current.timeAgo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      OklAppBarIconButton(
                        icon: LucideIcons.x,
                        onPressed: () {
                          final n = Navigator.of(context, rootNavigator: true);
                          if (n.canPop()) n.pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      OklAppBarIconButton(
                        icon: LucideIcons.moreVertical,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: SafeArea(
              top: false,
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
                          controller: _commentController,
                          style: TextStyle(color: context.oklOnSurface),
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Repondre...',
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
                                LucideIcons.camera,
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
                                onTap: () => OklFeedback.snack(
                                  context,
                                  'Options piece jointe (demo)',
                                ),
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
                          onSubmitted: (value) {
                            if (value.trim().isEmpty) return;
                            OklFeedback.snack(context, 'Reponse envoyee');
                            _commentController.clear();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      final text = _commentController.text.trim();
                      if (text.isNotEmpty) {
                        OklFeedback.snack(context, 'Reponse envoyee');
                        _commentController.clear();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _canSend ? AppColors.primary : context.oklSurface,
                      ),
                      child: Icon(
                        LucideIcons.send,
                        size: 18,
                        color: _canSend
                            ? Colors.white
                            : (Theme.of(context).textTheme.bodyMedium?.color ??
                                context.oklOnSurfaceMuted(0.62)),
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
      ),
      ),
    ),
    );
  }
}
