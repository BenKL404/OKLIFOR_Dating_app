import '../../../core/api/models/chat_api_models.dart';
import '../../../core/config/oklifor_media_url.dart';
import '../models/chat_models.dart';

const kDefaultChatAvatarUrl =
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80&auto=format&fit=crop';

/// Fils dont l’id est un UUID viennent du backend Spring.
bool isBackendThreadId(String id) => id.length >= 32 && id.contains('-');

String _formatApiTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

ChatThread chatThreadFromPayload(
  ChatThreadPayload p, {
  required String? myUserId,
  Map<String, String>? contactNameById,
  Map<String, String>? contactAvatarById,
}) {
  final isGroup = p.type.toUpperCase() == 'GROUP';
  var title = p.name.trim();
  if (title.isEmpty && isGroup) {
    title = 'Groupe';
  }
  if (title.isEmpty && !isGroup) {
    final mine = myUserId ?? '';
    String? other;
    for (final id in p.participantUserIds) {
      if (id != mine) {
        other = id;
        break;
      }
    }
    if (other != null && other.isNotEmpty) {
      final knownName = contactNameById?[other]?.trim();
      if (knownName != null && knownName.isNotEmpty) {
        title = knownName;
      } else {
        // Ne jamais afficher d'ID utilisateur brut dans l'UI.
        title = 'Utilisateur';
      }
    } else {
      title = 'Conversation';
    }
  }
  final mine = myUserId ?? '';
  String? otherUserId;
  for (final id in p.participantUserIds) {
    if (id != mine) {
      otherUserId = id;
      break;
    }
  }
  final rawAvatar = otherUserId == null ? null : contactAvatarById?[otherUserId];
  final resolvedAvatar = (rawAvatar != null && rawAvatar.trim().isNotEmpty)
      ? OkliforMediaUrl.resolve(rawAvatar.trim())
      : kDefaultChatAvatarUrl;
  final preview = p.lastMessagePreview.trim().isEmpty
      ? 'Aucun message'
      : p.lastMessagePreview;
  final time = _formatApiTime(p.lastMessageAt);
  return ChatThread(
    id: p.id,
    name: title,
    lastMsg: preview,
    time: time.isEmpty ? '—' : time,
    avatarUrl: resolvedAvatar,
    statusImageUrl: resolvedAvatar,
    statusCaption: '',
    statusTimeAgo: '',
    participantUserIds: List<String>.from(p.participantUserIds),
    statusKind: null,
    statusBackgroundHex: null,
    hasStory: false,
    isUnread: false,
    unreadCount: 0,
    online: false,
    isGroup: isGroup,
    groupMemberCount: isGroup ? p.participantUserIds.length : 0,
    isMuted: false,
    isArchived: false,
  );
}

ChatMessageKind _parseMessageKind(String raw) {
  switch (raw.toUpperCase()) {
    case 'IMAGE':
      return ChatMessageKind.image;
    case 'VIDEO':
      return ChatMessageKind.video;
    case 'VOICE':
    case 'AUDIO':
      return ChatMessageKind.voice;
    case 'FILE':
      return ChatMessageKind.file;
    case 'LOCATION':
      return ChatMessageKind.location;
    case 'SYSTEM':
      return ChatMessageKind.system;
    case 'TEXT':
    default:
      return ChatMessageKind.text;
  }
}

ChatMessage chatMessageFromPayload(
  ChatMessagePayload p, {
  required String? myUserId,
}) {
  final mine = myUserId != null && p.senderUserId == myUserId;
  final time = _formatApiTime(p.createdAt);
  final kind = _parseMessageKind(p.kind);
  final created = p.createdAt == null || p.createdAt!.isEmpty
      ? null
      : DateTime.tryParse(p.createdAt!);
  return ChatMessage(
    id: p.id,
    kind: kind,
    text: p.text,
    imageUrl: p.imageUrl == null ? null : OkliforMediaUrl.resolve(p.imageUrl!),
    videoUrl: p.videoUrl == null ? null : OkliforMediaUrl.resolve(p.videoUrl!),
    audioUrl: p.audioUrl == null ? null : OkliforMediaUrl.resolve(p.audioUrl!),
    voiceSeconds: p.voiceSeconds,
    fileUrl: p.fileUrl == null ? null : OkliforMediaUrl.resolve(p.fileUrl!),
    locationLabel: p.locationLabel,
    mine: mine,
    time: time.isEmpty ? '—' : time,
    showTail: true,
    readByRecipient: mine ? p.readByRecipient : false,
    createdAt: created,
  );
}

List<ChatMessage> chatMessagesFromPayloads(
  List<ChatMessagePayload> list, {
  required String? myUserId,
}) {
  final sorted = List<ChatMessagePayload>.from(list);
  sorted.sort((a, b) {
    final da =
        DateTime.tryParse(a.createdAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final db =
        DateTime.tryParse(b.createdAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return da.compareTo(db);
  });
  return sorted
      .map((p) => chatMessageFromPayload(p, myUserId: myUserId))
      .toList(growable: false);
}
