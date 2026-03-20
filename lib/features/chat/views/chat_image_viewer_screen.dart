import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/okl_app_bar_icon_button.dart';

/// Affichage plein écran d’une image de conversation (zoom pincement).
class ChatImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const ChatImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    void close() {
      if (!context.mounted) return;
      // pop() et non maybePop() : avec PopScope(canPop: false) ailleurs,
      // maybePop() peut refuser de fermer cette route.
      final root = Navigator.of(context, rootNavigator: true);
      if (root.canPop()) {
        root.pop();
        return;
      }
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black38,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: OklAppBarIconButton(
              icon: LucideIcons.x,
              onPressed: close,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.6,
          maxScale: 5,
          child: Hero(
            tag: heroTag,
            child: Material(
              color: Colors.transparent,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
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
    );
  }
}
