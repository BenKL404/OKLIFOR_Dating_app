import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/config/oklifor_media_url.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_chat_attachment_launch.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../models/chat_models.dart';
import 'chat_image_viewer_screen.dart';

/// Écran « Médias » : photos + fichiers (PDF, etc.) avec ouverture via l’app système.
class ConversationMediaScreen extends StatefulWidget {
  final ChatThread thread;
  final List<ChatMessage> messages;

  const ConversationMediaScreen({
    super.key,
    required this.thread,
    required this.messages,
  });

  @override
  State<ConversationMediaScreen> createState() => _ConversationMediaScreenState();
}

class _ConversationMediaScreenState extends State<ConversationMediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ChatMessage> get _images => widget.messages
      .where((m) => m.kind == ChatMessageKind.image && (m.imageUrl?.isNotEmpty ?? false))
      .toList(growable: false);

  /// Messages [file] avec URL, ou anciens textes « 📄 … » sans pièce jointe.
  List<ChatMessage> get _fileRows {
    final withUrl = widget.messages
        .where((m) => m.kind == ChatMessageKind.file)
        .toList(growable: false);
    final legacy = widget.messages
        .where(
          (m) =>
              m.kind == ChatMessageKind.text &&
              (m.text ?? '').trimLeft().startsWith('📄'),
        )
        .toList(growable: false);
    final seen = <String>{};
    final out = <ChatMessage>[];
    for (final m in [...withUrl, ...legacy]) {
      if (seen.add(m.id)) out.add(m);
    }
    out.sort((a, b) {
      final ca = a.createdAt;
      final cb = b.createdAt;
      if (ca != null && cb != null) return ca.compareTo(cb);
      return 0;
    });
    return out;
  }

  String _fileLabel(ChatMessage m) {
    final t = (m.text ?? '').trim();
    if (t.startsWith('📄')) return t.substring(t.indexOf('📄') + 1).trim();
    return t.isEmpty ? 'Document' : t;
  }

  Future<void> _openFile(ChatMessage m) async {
    final raw = (m.fileUrl ?? '').trim();
    if (raw.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ce document a été envoyé sans fichier (ancien format). Renvoie-le depuis « Document ».',
            ),
          ),
        );
      }
      return;
    }
    await launchChatAttachmentUrl(context, raw);
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final files = _fileRows;

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: Text('Médias · ${widget.thread.name}'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: context.oklOnSurfaceMuted(0.55),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: 'Photos (${images.length})'),
            Tab(text: 'Fichiers (${files.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PhotosGrid(images: images),
          files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.fileX,
                        size: 48,
                        color: context.oklOnSurfaceMuted(0.45),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun document dans cette conversation',
                        style: TextStyle(color: context.oklOnSurfaceMuted(0.55)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: files.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: context.oklDivider,
                  ),
                  itemBuilder: (context, i) {
                    final m = files[i];
                    final openable = (m.fileUrl ?? '').trim().isNotEmpty;
                    return ListTile(
                      leading: Icon(
                        LucideIcons.fileText,
                        color: openable
                            ? Theme.of(context).colorScheme.primary
                            : context.oklOnSurfaceMuted(0.45),
                      ),
                      title: Text(
                        _fileLabel(m),
                        style: TextStyle(color: context.oklOnSurface),
                      ),
                      subtitle: Text(
                        openable ? 'Appuyer pour ouvrir' : 'Pas de fichier joint',
                        style: TextStyle(
                          color: context.oklOnSurfaceMuted(0.5),
                          fontSize: 12,
                        ),
                      ),
                      trailing: openable
                          ? Icon(
                              LucideIcons.externalLink,
                              size: 18,
                              color: context.oklOnSurfaceMuted(0.45),
                            )
                          : null,
                      onTap: openable ? () => _openFile(m) : null,
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _PhotosGrid extends StatelessWidget {
  final List<ChatMessage> images;

  const _PhotosGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Center(
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
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: images.length,
      itemBuilder: (context, i) {
        final m = images[i];
        final url = OkliforMediaUrl.resolve(m.imageUrl!);
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
    );
  }
}
