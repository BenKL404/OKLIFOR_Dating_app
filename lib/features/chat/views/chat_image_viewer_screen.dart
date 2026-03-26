import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_chat_attachment_launch.dart';
import '../../../core/utils/okl_media_cache.dart';
import '../../../core/utils/okl_persistent_media_store.dart';

/// Affichage plein écran d’une image de conversation (zoom pincement).
class ChatImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final String? caption;

  const ChatImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.caption,
  });

  @override
  State<ChatImageViewerScreen> createState() => _ChatImageViewerScreenState();
}

class _ChatImageViewerScreenState extends State<ChatImageViewerScreen> {
  bool _uiVisible = true;
  double _dragDy = 0;
  File? _local;

  @override
  void initState() {
    super.initState();
    unawaited(_hydrateLocal());
  }

  Future<void> _hydrateLocal() async {
    try {
      final f = await ensureOkliforLocalFile(
        widget.imageUrl,
        bucket: OklMediaBucket.images,
        displayName: (widget.caption ?? '').trim(),
      );
      if (!mounted) return;
      setState(() => _local = f);
    } catch (_) {}
  }

  void _close() {
    if (!mounted) return;
    final root = Navigator.of(context, rootNavigator: true);
    if (root.canPop()) {
      root.pop();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final caption = (widget.caption ?? '').trim();
    final hasCaption = caption.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _uiVisible = !_uiVisible),
            onVerticalDragUpdate: (d) {
              _dragDy += d.delta.dy;
              if (_dragDy.abs() > 120) {
                _dragDy = 0;
                _close();
              }
            },
            onVerticalDragEnd: (_) => _dragDy = 0,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.9,
                maxScale: 5,
                child: Hero(
                  tag: widget.heroTag,
                  child: Material(
                    color: Colors.transparent,
                    child: _local != null
                        ? Image.file(_local!, fit: BoxFit.contain)
                        : CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                            cacheManager: oklChatMediaCache,
                            fit: BoxFit.contain,
                            memCacheWidth: 1600,
                            placeholder: (c, u) => const SizedBox(
                              width: 120,
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white54,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (c, u, e) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white38,
                              size: 64,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _uiVisible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_uiVisible,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top,
                      left: 8,
                      right: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        OklAppBarIconButton(
                          icon: LucideIcons.arrowLeft,
                          onPressed: _close,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Partager',
                          onPressed: () => shareChatAttachmentUrl(
                            context,
                            widget.imageUrl,
                            displayName: caption.isEmpty ? 'image.jpg' : caption,
                          ),
                          icon: const Icon(
                            LucideIcons.share2,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Enregistrer',
                          onPressed: () => saveChatFileToDownloads(
                            context,
                            widget.imageUrl,
                            displayName: caption,
                          ),
                          icon: const Icon(
                            LucideIcons.save,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Galerie',
                          onPressed: () => saveChatMediaToGallery(
                            context,
                            widget.imageUrl,
                            displayName: caption,
                            isVideo: false,
                          ),
                          icon: Icon(
                            LucideIcons.download,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (hasCaption)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        caption,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
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
