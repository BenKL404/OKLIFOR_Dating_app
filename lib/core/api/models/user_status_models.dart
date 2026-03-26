/// Statut / story utilisateur (`/api/v1/me/status`, `/api/v1/status/previews`).
class MyUserStatusPayload {
  MyUserStatusPayload({
    required this.kind,
    this.text,
    this.backgroundColorHex,
    this.caption,
    this.mediaUrl,
    this.createdAt,
    this.expiresAt,
  });

  final String kind;
  final String? text;
  final String? backgroundColorHex;
  final String? caption;
  final String? mediaUrl;
  final String? createdAt;
  final String? expiresAt;

  factory MyUserStatusPayload.fromJson(Map<String, dynamic> j) {
    return MyUserStatusPayload(
      kind: (j['kind'] as String? ?? 'TEXT').toUpperCase(),
      text: j['text'] as String?,
      backgroundColorHex: j['backgroundColorHex'] as String?,
      caption: j['caption'] as String?,
      mediaUrl: j['mediaUrl'] as String?,
      createdAt: j['createdAt'] as String?,
      expiresAt: j['expiresAt'] as String?,
    );
  }
}

class StatusPreviewPayload {
  StatusPreviewPayload({
    required this.userId,
    required this.hasStory,
    this.kind,
    this.text,
    this.backgroundColorHex,
    this.caption,
    this.mediaUrl,
    this.createdAt,
  });

  final String userId;
  final bool hasStory;
  final String? kind;
  final String? text;
  final String? backgroundColorHex;
  final String? caption;
  final String? mediaUrl;
  final String? createdAt;

  factory StatusPreviewPayload.fromJson(Map<String, dynamic> j) {
    return StatusPreviewPayload(
      userId: j['userId'] as String? ?? '',
      hasStory: j['hasStory'] as bool? ?? false,
      kind: (j['kind'] as String?)?.toUpperCase(),
      text: j['text'] as String?,
      backgroundColorHex: j['backgroundColorHex'] as String?,
      caption: j['caption'] as String?,
      mediaUrl: j['mediaUrl'] as String?,
      createdAt: j['createdAt'] as String?,
    );
  }
}
