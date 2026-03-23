/// Réponses JSON de `GET /api/v1/chat/threads` et messages.
class ChatThreadPayload {
  ChatThreadPayload({
    required this.id,
    required this.type,
    required this.participantUserIds,
    required this.name,
    required this.lastMessagePreview,
    this.lastMessageAt,
  });

  final String id;
  final String type;
  final List<String> participantUserIds;
  final String name;
  final String lastMessagePreview;
  final String? lastMessageAt;

  factory ChatThreadPayload.fromJson(Map<String, dynamic> j) {
    final parts = j['participantUserIds'];
    return ChatThreadPayload(
      id: j['id'] as String? ?? '',
      type: j['type'] as String? ?? 'DIRECT',
      participantUserIds: parts is List
          ? parts.map((e) => e.toString()).toList(growable: false)
          : const [],
      name: j['name'] as String? ?? '',
      lastMessagePreview: j['lastMessagePreview'] as String? ?? '',
      lastMessageAt: j['lastMessageAt'] as String?,
    );
  }
}

class ChatMessagePayload {
  ChatMessagePayload({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.kind,
    this.text,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.voiceSeconds,
    this.locationLabel,
    this.createdAt,
    this.readByRecipient = false,
  });

  final String id;
  final String threadId;
  final String senderUserId;
  final String kind;
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final int? voiceSeconds;
  final String? locationLabel;
  final String? createdAt;
  final bool readByRecipient;

  factory ChatMessagePayload.fromJson(Map<String, dynamic> j) {
    final vs = j['voiceSeconds'];
    final rb = j['readByRecipient'];
    final readByRecipient = rb is bool ? rb : false;
    return ChatMessagePayload(
      id: j['id'] as String? ?? '',
      threadId: j['threadId'] as String? ?? '',
      senderUserId: j['senderUserId'] as String? ?? '',
      kind: j['kind'] as String? ?? 'TEXT',
      text: j['text'] as String?,
      imageUrl: j['imageUrl'] as String?,
      videoUrl: j['videoUrl'] as String?,
      audioUrl: j['audioUrl'] as String?,
      voiceSeconds: vs is int ? vs : (vs is num ? vs.toInt() : null),
      locationLabel: j['locationLabel'] as String?,
      createdAt: j['createdAt'] as String?,
      readByRecipient: readByRecipient,
    );
  }
}

class ChatMediaUploadPayload {
  ChatMediaUploadPayload({required this.mediaKind, required this.signedUrl});

  final String mediaKind;
  final String signedUrl;

  factory ChatMediaUploadPayload.fromJson(Map<String, dynamic> j) {
    return ChatMediaUploadPayload(
      mediaKind: j['mediaKind'] as String? ?? 'IMAGE',
      signedUrl: j['signedUrl'] as String? ?? '',
    );
  }
}
