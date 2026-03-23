import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Aperçu plein écran de la photo de profil (style WhatsApp : fond noir, zoom, fermeture).
class OklProfilePhotoViewer {
  OklProfilePhotoViewer._();

  static const Object heroTag = 'okl-profile-avatar-fullscreen';

  static Future<void> open(BuildContext context, {required String imageUrl}) async {
    final u = imageUrl.trim();
    if (u.isEmpty) return;
    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ViewerPage(imageUrl: u);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _ViewerPage extends StatelessWidget {
  const _ViewerPage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(64),
              child: Center(
                child: Hero(
                  tag: OklProfilePhotoViewer.heroTag,
                  child: Material(
                    color: Colors.transparent,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      width: size.width,
                      height: size.height,
                      memCacheWidth: (size.width * dpr).round().clamp(400, 2048),
                      placeholder: (c, _) => const SizedBox(
                        width: 120,
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      errorWidget: (c, _, err) => const Icon(
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
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
