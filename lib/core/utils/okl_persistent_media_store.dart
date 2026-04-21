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

/// URL sans query / fragment — les liens signés changent à chaque appel API ;
/// la clé de stockage doit rester stable pour retrouver le même fichier local.
String _normalizedUrlForStorageKey(String resolved) {
  final u = Uri.tryParse(resolved);
  if (u == null) return resolved;
  if (u.scheme != 'http' && u.scheme != 'https') return resolved;
  try {
    final path = u.path.isEmpty ? '/' : u.path;
    return '${u.origin}$path';
  } catch (_) {
    return resolved;
  }
}

/// Clé stable pour nommer les fichiers (préfixe MD5).
String _stableKeyForUrl(String resolved) =>
    md5.convert(utf8.encode(_normalizedUrlForStorageKey(resolved))).toString();

/// Ancienne clé (MD5 de l’URL complète avec query) — rétrocompatibilité.
String _legacyStableKeyFullUrl(String resolved) =>
    md5.convert(utf8.encode(resolved)).toString();

String? _extensionFromUriPath(Uri uri) {
  if (uri.pathSegments.isEmpty) return null;
  final seg = uri.pathSegments.last;
  final dot = seg.lastIndexOf('.');
  if (dot > 0 && dot < seg.length - 1) {
    final ext = seg.substring(dot).toLowerCase();
    if (ext.length <= 12 && RegExp(r'^\.[a-z0-9]+$').hasMatch(ext)) {
      return ext;
    }
  }
  return null;
}

String _extensionForStorage(Uri uri, String? displayName) {
  final fromPath = _extensionFromUriPath(uri);
  if (fromPath != null) return fromPath;
  final hint = (displayName ?? '').trim();
  if (hint.isNotEmpty) {
    final base = hint.replaceFirst(RegExp(r'^📄\s*'), '').trim();
    final dot = base.lastIndexOf('.');
    if (dot > 0 && dot < base.length - 1) {
      final ext = base.substring(dot).toLowerCase();
      if (ext.length <= 12 && RegExp(r'^\.[a-z0-9]+$').hasMatch(ext)) {
        return ext;
      }
    }
  }
  return '.bin';
}

bool _isStableBackendMessageId(String? messageId) {
  final t = messageId?.trim() ?? '';
  return t.isNotEmpty && !t.startsWith('local_');
}

/// Clé dérivée de l’ID message (backend) — stable même si l’URL signée change.
String _stableKeyFromMessageId(String messageId) =>
    md5.convert(utf8.encode('okl|msgmedia|v1|$messageId')).toString();

/// Nom de fichier persistant : préfère l’ID message si fourni, sinon URL normalisée.
String _stableStorageFileName(
  String resolved,
  Uri uri,
  String? displayName, {
  String? storageObjectId,
}) {
  final ext = _extensionForStorage(uri, displayName);
  final key = _isStableBackendMessageId(storageObjectId)
      ? _stableKeyFromMessageId(storageObjectId!)
      : _stableKeyForUrl(resolved);
  return '$key$ext';
}

/// `true` si [messageId] peut servir de clé de stockage (pas un id local temporaire).
bool oklCanUseMessageIdForStorage(String? messageId) =>
    _isStableBackendMessageId(messageId);

Future<File?> _findFileStartingWithPrefix(Directory dir, String keyPrefix) async {
  if (!await dir.exists()) return null;
  await for (final entity in dir.list(followLinks: false)) {
    if (entity is! File) continue;
    final name = p.basename(entity.path);
    if (name.startsWith(keyPrefix)) return entity;
  }
  return null;
}

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
///
/// [storageObjectId] : id message backend (UUID) — préféré à l’URL (tokens signés).
/// Ce n’est pas une variable `.env` (globale), mais un identifiant par message.
Future<File?> getOkliforLocalFileIfExists(
  String rawUrl, {
  required OklMediaBucket bucket,
  String? displayName,
  String? storageObjectId,
}) async {
  final resolved = OkliforMediaUrl.resolve(rawUrl.trim());
  final uri = Uri.tryParse(resolved);
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) return null;

  final dir = await _bucketDir(bucket);
  final ext = _extensionForStorage(uri, displayName);

  // 0) Clé par ID message (stable même si l’URL signée change)
  if (_isStableBackendMessageId(storageObjectId)) {
    final keyMsg = _stableKeyFromMessageId(storageObjectId!);
    final byMsg = File(p.join(dir.path, '$keyMsg$ext'));
    if (await byMsg.exists()) return byMsg;
    final byMsgPrefix = await _findFileStartingWithPrefix(dir, keyMsg);
    if (byMsgPrefix != null) return byMsgPrefix;
  }

  final keyNew = _stableKeyForUrl(resolved);
  final keyOld = _legacyStableKeyFullUrl(resolved);

  // 1) Schéma URL : {md5(urlSansQuery)}{.ext}
  final stableName = _stableStorageFileName(
    resolved,
    uri,
    displayName,
    storageObjectId: null,
  );
  final preferred = File(p.join(dir.path, stableName));
  if (await preferred.exists()) return preferred;

  // 2) Ancien schéma : {md5(urlComplète)}_{nomAffiché|segment}
  final baseName = _basenameFromHintOrUrl(uri, displayName);
  final legacyNewKey = File(p.join(dir.path, '${keyNew}_$baseName'));
  if (await legacyNewKey.exists()) return legacyNewKey;
  final legacyOldKey = File(p.join(dir.path, '${keyOld}_$baseName'));
  if (await legacyOldKey.exists()) return legacyOldKey;

  // 3) Toute variante de nom commençant par la clé URL
  final byNew = await _findFileStartingWithPrefix(dir, keyNew);
  if (byNew != null) return byNew;
  final byOld = await _findFileStartingWithPrefix(dir, keyOld);
  if (byOld != null) return byOld;

  return null;
}

/// Assure la présence d’une copie locale persistante.
///
/// - Télécharge via `oklChatMediaCache` (donc 0 redownload si déjà en cache)
/// - Copie dans `Oklifor/Media/...` (persistant)
Future<File> ensureOkliforLocalFile(
  String rawUrl, {
  required OklMediaBucket bucket,
  String? displayName,
  String? storageObjectId,
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
    storageObjectId: storageObjectId,
  );
  if (existing != null) return existing;

  final dir = await _bucketDir(bucket);
  final stableName = _stableStorageFileName(
    resolved,
    uri,
    displayName,
    storageObjectId: storageObjectId,
  );
  final dest = File(p.join(dir.path, stableName));

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
  String? storageObjectId,
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
    storageObjectId: storageObjectId,
  );
  if (existing != null) return existing;

  final dir = await _bucketDir(bucket);
  final stableName = _stableStorageFileName(
    resolved,
    uri,
    displayName,
    storageObjectId: storageObjectId,
  );
  final dest = File(p.join(dir.path, stableName));
  if (await dest.exists()) return dest;
  await src.copy(dest.path);
  return dest;
}

