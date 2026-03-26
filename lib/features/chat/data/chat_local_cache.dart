import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/chat_models.dart';

/// Cache disque des discussions (liste + messages) pour consultation hors-ligne, type WhatsApp.
class ChatLocalCache {
  ChatLocalCache._();

  static const _maxMessagesPerThread = 800;
  static const _dirName = 'chat_cache_v1';

  static Future<Directory> _rootDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, _dirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _safeFileSegment(String id) {
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Supprime tout le cache (ex. après déconnexion).
  static Future<void> clearAll() async {
    if (kIsWeb) return;
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory(p.join(base.path, _dirName));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  static Future<File> _threadsFile(String userId) async {
    final root = await _rootDir();
    return File(p.join(root.path, 'threads_${_safeFileSegment(userId)}.json'));
  }

  static Future<File> _messagesFile(String userId, String threadId) async {
    final root = await _rootDir();
    return File(
      p.join(
        root.path,
        'msg_${_safeFileSegment(userId)}_${_safeFileSegment(threadId)}.json',
      ),
    );
  }

  static Future<void> saveThreads(String userId, List<ChatThread> threads) async {
    if (kIsWeb || userId.isEmpty) return;
    try {
      final list = threads.map(_threadToJson).toList();
      final f = await _threadsFile(userId);
      await f.writeAsString(jsonEncode(list));
    } catch (_) {}
  }

  static Future<List<ChatThread>?> loadThreads(String userId) async {
    if (kIsWeb || userId.isEmpty) return null;
    try {
      final f = await _threadsFile(userId);
      if (!await f.exists()) return null;
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) return null;
      final out = <ChatThread>[];
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          final t = _threadFromJson(e);
          if (t != null) out.add(t);
        } else if (e is Map) {
          final t = _threadFromJson(Map<String, dynamic>.from(e));
          if (t != null) out.add(t);
        }
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveMessages(
    String userId,
    String threadId,
    List<ChatMessage> messages,
  ) async {
    if (kIsWeb || userId.isEmpty || threadId.isEmpty) return;
    try {
      var slice = messages;
      if (slice.length > _maxMessagesPerThread) {
        slice = slice.sublist(slice.length - _maxMessagesPerThread);
      }
      final list = slice.map(_messageToJson).toList();
      final f = await _messagesFile(userId, threadId);
      await f.writeAsString(jsonEncode(list));
    } catch (_) {}
  }

  static Future<List<ChatMessage>?> loadMessages(
    String userId,
    String threadId,
  ) async {
    if (kIsWeb || userId.isEmpty || threadId.isEmpty) return null;
    try {
      final f = await _messagesFile(userId, threadId);
      if (!await f.exists()) return null;
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) return null;
      final out = <ChatMessage>[];
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          final m = _messageFromJson(e);
          if (m != null) out.add(m);
        } else if (e is Map) {
          final m = _messageFromJson(Map<String, dynamic>.from(e));
          if (m != null) out.add(m);
        }
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _threadToJson(ChatThread t) {
    return {
      'id': t.id,
      'name': t.name,
      'lastMsg': t.lastMsg,
      'time': t.time,
      'avatarUrl': t.avatarUrl,
      'statusImageUrl': t.statusImageUrl,
      'statusCaption': t.statusCaption,
      'statusTimeAgo': t.statusTimeAgo,
      'participantUserIds': t.participantUserIds,
      'statusKind': t.statusKind,
      'statusBackgroundHex': t.statusBackgroundHex,
      'hasStory': t.hasStory,
      'isUnread': t.isUnread,
      'unreadCount': t.unreadCount,
      'online': t.online,
      'isGroup': t.isGroup,
      'groupMemberCount': t.groupMemberCount,
      'isMuted': t.isMuted,
      'isArchived': t.isArchived,
    };
  }

  static ChatThread? _threadFromJson(Map<String, dynamic> j) {
    try {
      return ChatThread(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        lastMsg: j['lastMsg'] as String? ?? '',
        time: j['time'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String? ?? '',
        statusImageUrl: j['statusImageUrl'] as String? ?? '',
        statusCaption: j['statusCaption'] as String? ?? '',
        statusTimeAgo: j['statusTimeAgo'] as String? ?? '',
        participantUserIds: (j['participantUserIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        statusKind: j['statusKind'] as String?,
        statusBackgroundHex: j['statusBackgroundHex'] as String?,
        hasStory: j['hasStory'] as bool? ?? false,
        isUnread: j['isUnread'] as bool? ?? false,
        unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
        online: j['online'] as bool? ?? false,
        isGroup: j['isGroup'] as bool? ?? false,
        groupMemberCount: (j['groupMemberCount'] as num?)?.toInt() ?? 0,
        isMuted: j['isMuted'] as bool? ?? false,
        isArchived: j['isArchived'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _messageToJson(ChatMessage m) {
    return {
      'id': m.id,
      'kind': m.kind.name,
      'text': m.text,
      'imageUrl': m.imageUrl,
      'videoUrl': m.videoUrl,
      'audioUrl': m.audioUrl,
      'voiceSeconds': m.voiceSeconds,
      'fileUrl': m.fileUrl,
      'locationLabel': m.locationLabel,
      'mine': m.mine,
      'time': m.time,
      'showTail': m.showTail,
      'readByRecipient': m.readByRecipient,
      'createdAt': m.createdAt?.toUtc().toIso8601String(),
    };
  }

  static ChatMessage? _messageFromJson(Map<String, dynamic> j) {
    try {
      final kindName = j['kind'] as String? ?? 'text';
      final kind = ChatMessageKind.values.firstWhere(
        (e) => e.name == kindName,
        orElse: () => ChatMessageKind.text,
      );
      final createdRaw = j['createdAt'] as String?;
      return ChatMessage(
        id: j['id'] as String? ?? '',
        kind: kind,
        text: j['text'] as String?,
        imageUrl: j['imageUrl'] as String?,
        videoUrl: j['videoUrl'] as String?,
        audioUrl: j['audioUrl'] as String?,
        voiceSeconds: (j['voiceSeconds'] as num?)?.toInt(),
        fileUrl: j['fileUrl'] as String?,
        locationLabel: j['locationLabel'] as String?,
        mine: j['mine'] as bool? ?? false,
        time: j['time'] as String? ?? '',
        showTail: j['showTail'] as bool? ?? true,
        readByRecipient: j['readByRecipient'] as bool? ?? false,
        createdAt:
            createdRaw == null ? null : DateTime.tryParse(createdRaw)?.toUtc(),
      );
    } catch (_) {
      return null;
    }
  }
}
