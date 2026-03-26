import 'dart:io';

import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../config/oklifor_media_url.dart';
import 'okl_feedback.dart';
import 'okl_media_cache.dart';

String _sanitizeFileName(String name) {
  return name.replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), '_').trim();
}

String _fileNameFromHint(Uri uri, String? displayHint) {
  final hint = displayHint?.trim() ?? '';
  if (hint.isNotEmpty) {
    final base = hint.replaceFirst(RegExp(r'^📄\s*'), '').trim();
    if (base.isNotEmpty && base.contains('.')) {
      return _sanitizeFileName(base);
    }
  }
  if (uri.pathSegments.isNotEmpty) {
    final seg = uri.pathSegments.last;
    if (seg.isNotEmpty && seg.contains('.')) {
      return _sanitizeFileName(Uri.decodeComponent(seg));
    }
  }
  return 'fichier_${DateTime.now().millisecondsSinceEpoch}.bin';
}

String _mimeFromFileName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
  if (lower.endsWith('.pptx')) {
    return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
  }
  if (lower.endsWith('.txt')) return 'text/plain';
  if (lower.endsWith('.zip')) return 'application/zip';
  return 'application/octet-stream';
}

/// Télécharge (ou réutilise le cache) puis enregistre dans Téléchargements.
/// Android uniquement.
Future<bool> saveChatFileToDownloads(
  BuildContext context,
  String raw, {
  String? displayName,
}) async {
  if (!Platform.isAndroid) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Enregistrement Downloads dispo sur Android');
    }
    return false;
  }
  final resolved = OkliforMediaUrl.resolve(raw.trim());
  final uri = Uri.tryParse(resolved);
  if (!_isValidHttpUrl(resolved, uri)) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Lien du fichier invalide');
    }
    return false;
  }

  try {
    final name = _fileNameFromHint(uri!, displayName);
    final mime = _mimeFromFileName(name);
    final cachedFile = await oklChatMediaCache.getSingleFile(resolved);
    const ch = MethodChannel('oklifor.media/save_to_downloads');
    final ok = await ch.invokeMethod<bool>('saveFile', <String, dynamic>{
          'path': cachedFile.path,
          'suggestedName': name,
          'mimeType': mime,
        }) ??
        false;
    if (context.mounted) {
      OklFeedback.snack(
        context,
        ok ? 'Enregistré dans Téléchargements' : 'Enregistrement impossible',
      );
    }
    return ok;
  } catch (_) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Enregistrement impossible');
    }
    return false;
  }
}

Future<bool> _ensureGallerySavePermission(BuildContext context, {required bool isVideo}) async {
  if (!Platform.isAndroid && !Platform.isIOS) return true;
  try {
    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      if (status.isGranted) return true;
      if (context.mounted) {
        OklFeedback.snack(context, 'Autorisation photos requise pour enregistrer');
      }
      return false;
    }

    final info = await DeviceInfoPlugin().androidInfo;
    final sdk = info.version.sdkInt;
    if (sdk >= 33) {
      final perm = isVideo ? Permission.videos : Permission.photos;
      final status = await perm.request();
      if (status.isGranted) return true;
      if (context.mounted) {
        OklFeedback.snack(context, 'Autorisation média requise pour enregistrer');
      }
      return false;
    }

    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (context.mounted) {
      OklFeedback.snack(context, 'Autorisation stockage requise pour enregistrer');
    }
    return false;
  } catch (_) {
    // En cas de souci permission/OS, on tente quand même via GallerySaver.
    return true;
  }
}

/// Télécharge puis enregistre dans la galerie (Photos).
Future<void> saveChatMediaToGallery(
  BuildContext context,
  String raw, {
  String? displayName,
  required bool isVideo,
}) async {
  final resolved = OkliforMediaUrl.resolve(raw.trim());
  final uri = Uri.tryParse(resolved);
  if (!_isValidHttpUrl(resolved, uri)) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Lien du média invalide');
    }
    return;
  }

  if (!await _ensureGallerySavePermission(context, isVideo: isVideo)) return;

  try {
    // Remplit le cache + réutilise le fichier local si déjà présent.
    final cachedFile = await oklChatMediaCache.getSingleFile(resolved);
    const ch = MethodChannel('oklifor.media/save_to_gallery');
    final ok = await ch.invokeMethod<bool>('saveFile', <String, dynamic>{
          'path': cachedFile.path,
          'isVideo': isVideo,
          'suggestedName': (displayName ?? '').trim(),
        }) ??
        false;

    if (context.mounted) {
      OklFeedback.snack(context, ok ? 'Enregistré dans la galerie' : 'Enregistrement impossible');
    }
  } catch (_) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Enregistrement impossible');
    }
  }
}

Future<String> _downloadAttachmentToTemp(String url, String fileName) async {
  final dir = await getTemporaryDirectory();
  final sub = Directory(p.join(dir.path, 'chat_attachments'));
  if (!await sub.exists()) {
    await sub.create(recursive: true);
  }
  final path = p.join(
    sub.path,
    '${DateTime.now().millisecondsSinceEpoch}_$fileName',
  );
  await Dio().download(url, path);
  return path;
}

bool _isValidHttpUrl(String resolved, Uri? uri) {
  return uri != null &&
      (uri.isScheme('http') || uri.isScheme('https')) &&
      resolved.isNotEmpty;
}

/// Télécharge puis ouvre avec une app externe (PDF, navigateur, etc.).
Future<void> launchChatAttachmentUrl(
  BuildContext context,
  String raw, {
  String? displayName,
}) async {
  final resolved = OkliforMediaUrl.resolve(raw.trim());
  final uri = Uri.tryParse(resolved);
  if (!_isValidHttpUrl(resolved, uri)) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Lien du fichier invalide');
    }
    return;
  }

  try {
    final name = _fileNameFromHint(uri!, displayName);
    final path = await _downloadAttachmentToTemp(resolved, name);
    final result = await OpenFilex.open(path, type: _mimeFromFileName(name));
    if (result.type != ResultType.done && context.mounted) {
      OklFeedback.snack(
        context,
        'Aucune app pour ouvrir ce fichier',
      );
    }
  } catch (_) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Téléchargement ou ouverture impossible');
    }
  }
}

/// Feuille système : enregistrer, Drive, messagerie…
Future<void> shareChatAttachmentUrl(
  BuildContext context,
  String raw, {
  String? displayName,
}) async {
  final resolved = OkliforMediaUrl.resolve(raw.trim());
  final uri = Uri.tryParse(resolved);
  if (!_isValidHttpUrl(resolved, uri)) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Lien du fichier invalide');
    }
    return;
  }

  Rect? shareOrigin;
  if (context.mounted) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      shareOrigin = box.localToGlobal(Offset.zero) & box.size;
    }
  }

  try {
    final name = _fileNameFromHint(uri!, displayName);
    final path = await _downloadAttachmentToTemp(resolved, name);
    final mime = _mimeFromFileName(name);
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, name: name, mimeType: mime)],
        subject: name,
        sharePositionOrigin: shareOrigin,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Partage / enregistrement impossible');
    }
  }
}
