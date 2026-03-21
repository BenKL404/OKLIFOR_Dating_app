import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../models/chat_models.dart';
import 'chat_image_viewer_screen.dart';

class ConversationMediaScreen extends StatelessWidget {
  final ChatThread thread;
  final List<ChatMessage> messages;

  const ConversationMediaScreen({
    super.key,
    required this.thread,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final images = messages
        .where((m) => m.kind == ChatMessageKind.image && (m.imageUrl?.isNotEmpty ?? false))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: Text('Médias · ${thread.name}'),
      ),
      body: images.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.imageOff, size: 48, color: context.oklOnSurfaceMuted(0.45)),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune photo dans cette conversation',
                    style: TextStyle(color: context.oklOnSurfaceMuted(0.55)),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: images.length,
              itemBuilder: (context, i) {
                final m = images[i];
                final url = m.imageUrl!;
                final tag = 'media_grid_${m.id}';
                return Material(
                  color: context.oklSurface,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push<void>(
                        MaterialPageRoute<void>(
                          fullscreenDialog: true,
                          builder: (_) => ChatImageViewerScreen(imageUrl: url, heroTag: tag),
                        ),
                      );
                    },
                    child: Hero(
                      tag: tag,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        placeholder: (c, u) => Container(color: c.oklSurface),
                        errorWidget: (c, u, e) => Container(
                          color: c.oklSurface,
                          child: Icon(LucideIcons.imageOff, color: c.oklOnSurfaceMuted(0.45)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
