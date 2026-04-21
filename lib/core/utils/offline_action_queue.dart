import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// File d’attente offline persistée sur disque.
///
/// On enregistre uniquement des actions légères (JSON) à rejouer quand
/// le backend redevient disponible.
class OfflineActionQueue {
  OfflineActionQueue._();

  static const _dirName = 'offline_queue_v1';

  static String _safeFileSegment(String id) {
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  static Future<Directory> _rootDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, _dirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _queueFile(String userId) async {
    final root = await _rootDir();
    return File(p.join(root.path, 'q_${_safeFileSegment(userId)}.json'));
  }

  static Future<List<Map<String, dynamic>>> _loadRaw(String userId) async {
    if (kIsWeb || userId.isEmpty) return const [];
    try {
      final f = await _queueFile(userId);
      if (!await f.exists()) return const [];
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _saveRaw(
    String userId,
    List<Map<String, dynamic>> actions,
  ) async {
    if (kIsWeb || userId.isEmpty) return;
    try {
      final f = await _queueFile(userId);
      await f.writeAsString(jsonEncode(actions));
    } catch (_) {}
  }

  /// Enqueue message à envoyer plus tard.
  ///
  /// - [localMessageId] sert à réconcilier l’UI (remplacer / supprimer la bulle locale).
  static Future<void> enqueueSendChatMessage({
    required String userId,
    required String threadId,
    required String localMessageId,
    required String kind,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    int? voiceSeconds,
    String? locationLabel,
    String? fileUrl,
  }) async {
    if (kIsWeb) return;
    if (userId.isEmpty || threadId.isEmpty || localMessageId.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final action = <String, dynamic>{
      'id': 'a_${DateTime.now().microsecondsSinceEpoch}',
      'type': 'send_chat_message',
      'createdAt': now,
      'threadId': threadId,
      'localMessageId': localMessageId,
      'kind': kind,
      ?'text': text,
      ?'imageUrl': imageUrl,
      ?'videoUrl': videoUrl,
      ?'audioUrl': audioUrl,
      ?'voiceSeconds': voiceSeconds,
      ?'locationLabel': locationLabel,
      ?'fileUrl': fileUrl,
    };
    final list = (await _loadRaw(userId)).toList(growable: true);
    list.add(action);
    await _saveRaw(userId, list);
  }

  static Future<List<Map<String, dynamic>>> loadSendChatMessageActions({
    required String userId,
    required String threadId,
  }) async {
    final all = await _loadRaw(userId);
    return all
        .where((a) => a['type'] == 'send_chat_message')
        .where((a) => (a['threadId']?.toString() ?? '') == threadId)
        .toList(growable: false);
  }

  static Future<void> removeActionsByIds({
    required String userId,
    required Set<String> ids,
  }) async {
    if (ids.isEmpty) return;
    final all = await _loadRaw(userId);
    final kept = all.where((a) => !ids.contains(a['id']?.toString() ?? '')).toList();
    await _saveRaw(userId, kept);
  }

  /// Enqueue un patch profil léger (sans images).
  static Future<void> enqueuePatchMyProfile({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    if (kIsWeb) return;
    if (userId.isEmpty) return;
    if (patch.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final action = <String, dynamic>{
      'id': 'p_${DateTime.now().microsecondsSinceEpoch}',
      'type': 'patch_my_profile',
      'createdAt': now,
      'patch': patch,
    };
    final list = (await _loadRaw(userId)).toList(growable: true);
    list.add(action);
    await _saveRaw(userId, list);
  }

  static Future<List<Map<String, dynamic>>> loadPatchMyProfileActions({
    required String userId,
  }) async {
    final all = await _loadRaw(userId);
    return all
        .where((a) => a['type'] == 'patch_my_profile')
        .toList(growable: false);
  }

  /// Threads ayant au moins un message chat en attente d’envoi.
  static Future<Set<String>> pendingChatThreadIds(String userId) async {
    final all = await _loadRaw(userId);
    final out = <String>{};
    for (final a in all) {
      if (a['type'] != 'send_chat_message') continue;
      final tid = a['threadId']?.toString() ?? '';
      if (tid.isNotEmpty) out.add(tid);
    }
    return out;
  }

  /// Nombre d’actions en attente (affichage bannière).
  static Future<({int chat, int profile})> pendingCounts(String userId) async {
    final all = await _loadRaw(userId);
    var chat = 0;
    var profile = 0;
    for (final a in all) {
      final t = a['type']?.toString();
      if (t == 'send_chat_message') chat++;
      if (t == 'patch_my_profile') profile++;
    }
    return (chat: chat, profile: profile);
  }
}

