import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_feedback.dart';
import 'media_compose_screen.dart';

class OklComposedMedia {
  final bool isVideo;
  final String filename;
  final String? filePath;
  final List<int>? bytes;
  final String caption;

  const OklComposedMedia({
    required this.isVideo,
    required this.filename,
    required this.caption,
    this.filePath,
    this.bytes,
  });
}

class GalleryPickerScreen extends StatefulWidget {
  const GalleryPickerScreen({super.key});

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  static const _pageSize = 120;

  final List<AssetEntity> _items = <AssetEntity>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;

  AssetPathEntity? _path;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    if (kIsWeb) {
      if (!mounted) return;
      OklFeedback.snack(context, 'Galerie WhatsApp non dispo sur Web');
      Navigator.pop(context);
      return;
    }

    final perm = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    if (!perm.isAuth) {
      OklFeedback.snack(context, 'Autorisation galerie refusée');
      Navigator.pop(context);
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
      onlyAll: true,
    );
    if (!mounted) return;
    if (paths.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    _path = paths.first;
    await _loadMore(reset: true);
  }

  Future<void> _loadMore({required bool reset}) async {
    if (_path == null) return;
    if (reset) {
      setState(() {
        _items.clear();
        _page = 0;
        _hasMore = true;
        _loading = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    final page = reset ? 0 : _page;
    final next = await _path!.getAssetListPaged(page: page, size: _pageSize);
    if (!mounted) return;
    setState(() {
      _items.addAll(next);
      _page = page + 1;
      _hasMore = next.length == _pageSize;
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _openCompose(AssetEntity entity) async {
    final composed = await Navigator.of(context).push<OklComposedMedia>(
      MaterialPageRoute<OklComposedMedia>(
        builder: (_) => MediaComposeScreen(entity: entity),
      ),
    );
    if (!mounted) return;
    if (composed == null) return;
    Navigator.pop(context, composed);
  }

  @override
  Widget build(BuildContext context) {
    final cols = MediaQuery.sizeOf(context).width > 430 ? 4 : 3;
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202C33),
        foregroundColor: Colors.white,
        title: const Text('Galerie'),
        actions: [
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 800) {
            unawaited(_loadMore(reset: false));
          }
          return false;
        },
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(2),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: (ctx, i) {
                  if (i >= _items.length) {
                    return Center(
                      child: _loadingMore
                          ? const CircularProgressIndicator(
                              color: Colors.white54,
                            )
                          : const SizedBox.shrink(),
                    );
                  }
                  final e = _items[i];
                  return _GalleryTile(
                    entity: e,
                    onTap: () => unawaited(_openCompose(e)),
                  );
                },
              ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final AssetEntity entity;
  final VoidCallback onTap;
  const _GalleryTile({required this.entity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isVideo = entity.type == AssetType.video;
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: entity.thumbnailDataWithSize(const ThumbnailSize(320, 320)),
            builder: (ctx, snap) {
              final data = snap.data;
              if (data == null) {
                return Container(color: context.oklSurface);
              }
              return Image.memory(
                data,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              );
            },
          ),
          if (isVideo)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.video,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmtDur(entity.videoDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

String _fmtDur(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

