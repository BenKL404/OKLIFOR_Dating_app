import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/oklifor_media_url.dart';
import 'okl_media_cache.dart';

/// Arborescence "comme WhatsApp" (mais dans le stockage externe de l’app).
///
/// Android: `Android/data/<package>/files/Oklifor/Media/...`
/// iOS: Documents/Oklifor/Media/...
enum OklMediaBucket {
  images,
  video,
  documents,
  audio,
  voiceNotes,
}

String _bucketFolder(OklMediaBucket b) {
  switch (b) {
    case OklMediaBucket.images:
      return 'Oklifor Images';
    case OklMediaBucket.video:
      return 'Oklifor Video';
    case OklMediaBucket.documents:
      return 'Oklifor Documents';
    case OklMediaBucket.audio:
      return 'Oklifor Audio';
    case OklMediaBucket.voiceNotes:
      return 'Oklifor Voice Notes';
  }
}

String _sanitizeFileName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'file.bin';
  return trimmed.replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), '_');
}

String _basenameFromHintOrUrl(Uri uri, String? displayName) {
  final hint = (displayName ?? '').trim();
  if (hint.isNotEmpty) {
    final base = hint.replaceFirst(RegExp(r'^📄\s*'), '').trim();
    if (base.isNotEmpty) return _sanitizeFileName(base);
  }
  if (uri.pathSegments.isNotEmpty) {
    final seg = uri.pathSegments.last.trim();
    if (seg.isNotEmpty) return _sanitizeFileName(Uri.decodeComponent(seg));
  }
  return 'file_${DateTime.now().millisecondsSinceEpoch}.bin';
}

String _stableKey(String url) => md5.convert(utf8.encode(url)).toString();

Future<Directory> _baseDir() async {
  if (Platform.isAndroid) {
    // WhatsApp-like: Android/media/<package>/...
    if (!kIsWeb) {
      try {
        const ch = MethodChannel('oklifor.media/storage');
        final path = await ch.invokeMethod<String>('getExternalMediaBasePath');
        if (path != null && path.trim().isNotEmpty) {
          final d = Directory(path.trim());
          if (!await d.exists()) {
            await d.create(recursive: true);
          }
          return d;
        }
      } catch (_) {}
    }

    // Fallback: app external files (Android/data/<package>/files)
    final ext = await getExternalStorageDirectory();
    if (ext != null) return ext;
  }
  return getApplicationDocumentsDirectory();
}

Future<Directory> _bucketDir(OklMediaBucket bucket) async {
  final base = await _baseDir();
  final dir = Directory(p.join(base.path, 'Oklifor', 'Media', _bucketFolder(bucket)));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Renvoie un fichier persistant s’il existe déjà (sinon `null`).
Future<File?> getOkliforLocalFileIfExists(
  String rawUrl, {
  required OklMediaBucket bucket,
  String? displayName,
}) async {
  final resolved = OkliforMediaUrl.resolve(rawUrl.trim());
  final uri = Uri.tryParse(resolved);
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) return null;

  final dir = await _bucketDir(bucket);
  final baseName = _basenameFromHintOrUrl(uri, displayName);
  final key = _stableKey(resolved);
  final path = p.join(dir.path, '${key}_$baseName');
  final f = File(path);
  return await f.exists() ? f : null;
}

/// Assure la présence d’une copie locale persistante.
///
/// - Télécharge via `oklChatMediaCache` (donc 0 redownload si déjà en cache)
/// - Copie dans `Oklifor/Media/...` (persistant)
Future<File> ensureOkliforLocalFile(
  String rawUrl, {
  required OklMediaBucket bucket,
  String? displayName,
}) async {
  final resolved = OkliforMediaUrl.resolve(rawUrl.trim());
  final uri = Uri.tryParse(resolved);
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
    throw ArgumentError('invalid_url');
  }

  final existing = await getOkliforLocalFileIfExists(
    resolved,
    bucket: bucket,
    displayName: displayName,
  );
  if (existing != null) return existing;

  final dir = await _bucketDir(bucket);
  final baseName = _basenameFromHintOrUrl(uri, displayName);
  final key = _stableKey(resolved);
  final dest = File(p.join(dir.path, '${key}_$baseName'));

  final cached = await oklChatMediaCache.getSingleFile(resolved);
  if (await dest.exists()) return dest;
  await cached.copy(dest.path);
  return dest;
}

/// Persist from an existing local file path (sender side).
/// Copies the file into `Oklifor/Media/...` using the URL key, avoiding re-download.
Future<File> persistOkliforLocalFileFromPath(
  String rawUrl, {
  required OklMediaBucket bucket,
  required String sourcePath,
  String? displayName,
}) async {
  final resolved = OkliforMediaUrl.resolve(rawUrl.trim());
  final uri = Uri.tryParse(resolved);
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
    throw ArgumentError('invalid_url');
  }
  final src = File(sourcePath);
  if (!await src.exists()) {
    throw ArgumentError('source_missing');
  }

  final existing = await getOkliforLocalFileIfExists(
    resolved,
    bucket: bucket,
    displayName: displayName,
  );
  if (existing != null) return existing;

  final dir = await _bucketDir(bucket);
  final baseName = _basenameFromHintOrUrl(uri, displayName);
  final key = _stableKey(resolved);
  final dest = File(p.join(dir.path, '${key}_$baseName'));
  if (await dest.exists()) return dest;
  await src.copy(dest.path);
  return dest;
}

