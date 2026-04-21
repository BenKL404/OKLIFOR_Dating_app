import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../api/models/me_response.dart';
import '../../features/chat/models/chat_models.dart';

/// Cache disque minimal pour que l’app reste utilisable hors-ligne.
///
/// Objectif: si l’utilisateur a déjà été connecté au moins une fois,
/// on peut démarrer l’app, afficher le profil, les discussions et les contacts
/// même si le backend est indisponible.
class AppLocalCache {
  AppLocalCache._();

  static const _dirName = 'app_cache_v1';

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

  static Future<File> _meFile(String userId) async {
    final root = await _rootDir();
    return File(p.join(root.path, 'me_${_safeFileSegment(userId)}.json'));
  }

  static Future<File> _contactsFile(String userId) async {
    final root = await _rootDir();
    return File(p.join(root.path, 'contacts_${_safeFileSegment(userId)}.json'));
  }

  static Future<void> saveMe(MeResponse me) async {
    if (kIsWeb) return;
    if (me.userId.isEmpty) return;
    try {
      final f = await _meFile(me.userId);
      await f.writeAsString(jsonEncode(me.toJson()));
    } catch (_) {}
  }

  static Future<MeResponse?> loadMe(String userId) async {
    if (kIsWeb) return null;
    if (userId.isEmpty) return null;
    try {
      final f = await _meFile(userId);
      if (!await f.exists()) return null;
      final raw = jsonDecode(await f.readAsString());
      if (raw is! Map) return null;
      return MeResponse.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveChatContacts(
    String userId,
    List<ChatContact> contacts,
  ) async {
    if (kIsWeb) return;
    if (userId.isEmpty) return;
    try {
      final f = await _contactsFile(userId);
      final list = contacts
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'avatarUrl': c.avatarUrl,
            },
          )
          .toList(growable: false);
      await f.writeAsString(jsonEncode(list));
    } catch (_) {}
  }

  static Future<List<ChatContact>?> loadChatContacts(String userId) async {
    if (kIsWeb) return null;
    if (userId.isEmpty) return null;
    try {
      final f = await _contactsFile(userId);
      if (!await f.exists()) return null;
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) return null;
      final out = <ChatContact>[];
      for (final e in raw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          out.add(
            ChatContact(
              id: m['id']?.toString() ?? '',
              name: m['name']?.toString() ?? '',
              avatarUrl: m['avatarUrl']?.toString() ?? '',
            ),
          );
        }
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }
}

