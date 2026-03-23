import '../models/chat_models.dart';

/// Schéma : `oklifor://profile?uid=<id>&n=<nom>` (nom encodé par [Uri]).
class OklContactQrCodec {
  OklContactQrCodec._();

  static const String host = 'profile';

  static const String _fallbackAvatar =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80&auto=format&fit=crop';

  /// Encode la carte du profil courant avec l’identifiant compte réel.
  static String encodeMyCard({required String userId, required String displayName}) {
    final uid = userId.trim();
    if (uid.isEmpty) {
      return '';
    }
    final uri = Uri(
      scheme: 'oklifor',
      host: host,
      queryParameters: {
        'uid': uid,
        'n': displayName.trim().isEmpty ? 'Moi' : displayName.trim(),
      },
    );
    return uri.toString();
  }

  /// Encode une fiche contact (ex. entrées de [kDemoContacts] pour essais locaux).
  static String encodeContact(ChatContact c) {
    final uri = Uri(
      scheme: 'oklifor',
      host: host,
      queryParameters: {
        'uid': c.id,
        'n': c.name,
      },
    );
    return uri.toString();
  }

  /// Décode une chaîne scannée (URL complète ou texte brut).
  static ChatContact? tryDecode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    Uri? uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    if (uri.scheme != 'oklifor' || uri.host != host) {
      return null;
    }

    final uid = uri.queryParameters['uid'];
    if (uid == null || uid.isEmpty) return null;

    final nameParam = uri.queryParameters['n'];
    final name = (nameParam == null || nameParam.isEmpty) ? 'Profil Oklifor' : nameParam;

    for (final c in kDemoContacts) {
      if (c.id == uid) return c;
    }

    return ChatContact(id: uid, name: name, avatarUrl: _fallbackAvatar);
  }
}
