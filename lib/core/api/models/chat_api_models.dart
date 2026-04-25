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
    this.fileUrl,
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
  final String? fileUrl;
  final String? locationLabel;
  final String? createdAt;
  final bool readByRecipient;

  factory ChatMessagePayload.fromJson(Map<String, dynamic> j) {
    final vs = j['voiceSeconds'];
    final rb = j['readByRecipient'];
    final readByRecipient = rb is bool ? rb : (rb == 'true' || rb == 1);
    
    // Helper to safely get a string
    String s(dynamic v) => v?.toString() ?? '';

    return ChatMessagePayload(
      id: s(j['id']),
      threadId: s(j['threadId']),
      senderUserId: s(j['senderUserId']),
      kind: s(j['kind']).isEmpty ? 'TEXT' : s(j['kind']),
      text: j['text']?.toString(),
      imageUrl: j['imageUrl']?.toString(),
      videoUrl: j['videoUrl']?.toString(),
      audioUrl: j['audioUrl']?.toString(),
      voiceSeconds: vs is int ? vs : (vs is num ? vs.toInt() : int.tryParse(vs?.toString() ?? '')),
      fileUrl: j['fileUrl']?.toString(),
      locationLabel: j['locationLabel']?.toString(),
      createdAt: j['createdAt']?.toString(),
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

class ChatPresignPayload {
  ChatPresignPayload({
    required this.putUrl,
    required this.fileUrl,
    required this.mediaKind,
  });

  final String putUrl;
  final String fileUrl;
  final String mediaKind;

  factory ChatPresignPayload.fromJson(Map<String, dynamic> j) {
    return ChatPresignPayload(
      putUrl: j['putUrl'] as String? ?? '',
      fileUrl: j['fileUrl'] as String? ?? '',
      mediaKind: j['mediaKind'] as String? ?? 'IMAGE',
    );
  }
}
