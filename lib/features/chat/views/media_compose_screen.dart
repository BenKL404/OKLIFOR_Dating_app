import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/utils/okl_image_crop.dart';
import 'gallery_picker_screen.dart';

class MediaComposeScreen extends StatefulWidget {
  final AssetEntity entity;
  const MediaComposeScreen({super.key, required this.entity});

  @override
  State<MediaComposeScreen> createState() => _MediaComposeScreenState();
}

class _MediaComposeScreenState extends State<MediaComposeScreen> {
  final _caption = TextEditingController();
  final _focus = FocusNode();

  File? _file;
  bool _loading = true;
  Uint8List? _croppedBytes;

  VideoPlayerController? _video;
  bool _sending = false;

  bool get _isVideo => widget.entity.type == AssetType.video;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (kIsWeb) {
      if (mounted) {
        OklFeedback.snack(context, 'Aperçu média non dispo sur Web');
        Navigator.pop(context);
      }
      return;
    }
    final f = await widget.entity.file;
    if (!mounted) return;
    if (f == null) {
      OklFeedback.snack(context, 'Impossible d’ouvrir ce fichier');
      Navigator.pop(context);
      return;
    }
    _file = f;
    if (_isVideo) {
      final c = VideoPlayerController.file(f);
      await c.initialize();
      c.setLooping(true);
      await c.play();
      _video = c;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _caption.dispose();
    _focus.dispose();
    _video?.dispose();
    super.dispose();
  }

  Future<void> _cropImage() async {
    final f = _file;
    if (f == null || _isVideo) return;
    final bytes = await cropPickedImageIfPossible(
      context: context,
      xFile: XFile(f.path),
      kind: OklImageCropKind.verificationId,
    );
    if (!mounted) return;
    if (bytes == null) return;
    setState(() => _croppedBytes = bytes);
  }

  Future<void> _send() async {
    if (_sending) return;
    final f = _file;
    if (f == null) return;
    setState(() => _sending = true);

    final filename = widget.entity.title?.trim().isNotEmpty == true
        ? widget.entity.title!.trim()
        : 'media_${DateTime.now().millisecondsSinceEpoch}';
    final caption = _caption.text.trim();

    try {
      if (_isVideo) {
        // Read video bytes directly — avoids content:// URI issues on Android
        final bytes = await f.readAsBytes();
        if (!mounted) return;
        Navigator.pop(
          context,
          OklComposedMedia(
            isVideo: true,
            filename: filename,
            bytes: bytes,
            caption: caption,
          ),
        );
        return;
      }

      // Image — prefer cropped bytes, otherwise load from entity origin
      final Uint8List? imageBytes;
      if (_croppedBytes != null) {
        imageBytes = _croppedBytes;
      } else {
        imageBytes = await widget.entity.originBytes;
      }

      if (!mounted) return;
      if (imageBytes == null || imageBytes.isEmpty) {
        OklFeedback.snack(context, 'Impossible de lire ce fichier image');
        setState(() => _sending = false);
        return;
      }

      Navigator.pop(
        context,
        OklComposedMedia(
          isVideo: false,
          filename: filename,
          bytes: imageBytes,
          caption: caption,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      OklFeedback.snack(context, 'Erreur lecture média : $e');
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.white70))
        : (_isVideo
            ? Center(
                child: AspectRatio(
                  aspectRatio: _video?.value.aspectRatio ?? (9 / 16),
                  child: _video == null
                      ? const SizedBox.shrink()
                      : VideoPlayer(_video!),
                ),
              )
            : Center(
                child: _croppedBytes != null
                    ? Image.memory(_croppedBytes!, fit: BoxFit.contain)
                    : (_file == null
                        ? const SizedBox.shrink()
                        : Image.file(_file!, fit: BoxFit.contain)),
              ));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_isVideo ? 'Vidéo' : 'Photo'),
        actions: [
          if (!_isVideo)
            IconButton(
              tooltip: 'Recadrer',
              icon: const Icon(LucideIcons.crop),
              onPressed: _loading ? null : () => unawaited(_cropImage()),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: preview),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0B141A),
                border: Border(
                  top: BorderSide(color: Color(0x22000000)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caption,
                      focusNode: _focus,
                      style: const TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ajouter une légende…',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF202C33),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: (_loading || _sending) ? null : () => unawaited(_send()),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.send, size: 18),
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

