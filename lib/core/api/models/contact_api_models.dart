class ContactPayload {
  ContactPayload({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.addedAtIso,
  });

  final String userId;
  final String displayName;
  final String avatarUrl;
  final String? addedAtIso;

  factory ContactPayload.fromJson(Map<String, dynamic> json) {
    return ContactPayload(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      addedAtIso: json['addedAt'] as String?,
    );
  }
}
