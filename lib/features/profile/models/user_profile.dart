import 'package:flutter/foundation.dart';

import '../../../core/config/oklifor_media_url.dart';

/// Données profil + étapes de vérification (synchronisées via [ProfileSession] après /me).
class UserProfile {
  /// Identifiant compte (UUID backend). Vide si session locale sans connexion.
  final String userId;
  final String displayName;
  final String city;
  final String bio;
  final String relationGoal;
  final String languages;
  /// Origines / communautés (texte libre).
  final String ethnicity;
  /// Mode de vie (rythme, sorties, etc.).
  final String lifestyle;
  final String profession;
  final String education;
  final String coverUrl;
  final String avatarUrl;

  final bool phoneVerified;
  final bool emailVerified;
  final bool idVerified;
  final bool idPendingReview;

  const UserProfile({
    this.userId = '',
    required this.displayName,
    required this.city,
    required this.bio,
    required this.relationGoal,
    required this.languages,
    this.ethnicity = '',
    this.lifestyle = '',
    this.profession = '',
    this.education = '',
    required this.coverUrl,
    required this.avatarUrl,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.idVerified = false,
    this.idPendingReview = false,
  });

  /// URL exploitable par [CachedNetworkImage] (préfixe [OkliforApiConfig.baseUrl] si besoin).
  String get coverUrlForDisplay => OkliforMediaUrl.resolve(coverUrl);

  String get avatarUrlForDisplay => OkliforMediaUrl.resolve(avatarUrl);

  /// Badge doré Oklifor : téléphone + email + identité validée.
  bool get hasOkliforCertificate =>
      phoneVerified && emailVerified && idVerified;

  /// Score affiché 0–100 pour la carte confiance.
  int get trustScore {
    var n = 0;
    if (phoneVerified) n += 34;
    if (emailVerified) n += 33;
    if (idVerified) n += 33;
    return n.clamp(0, 100);
  }

  int get completedVerificationSteps {
    var s = 0;
    if (phoneVerified) s++;
    if (emailVerified) s++;
    if (idVerified) s++;
    return s;
  }

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? city,
    String? bio,
    String? relationGoal,
    String? languages,
    String? ethnicity,
    String? lifestyle,
    String? profession,
    String? education,
    String? coverUrl,
    String? avatarUrl,
    bool? phoneVerified,
    bool? emailVerified,
    bool? idVerified,
    bool? idPendingReview,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      relationGoal: relationGoal ?? this.relationGoal,
      languages: languages ?? this.languages,
      ethnicity: ethnicity ?? this.ethnicity,
      lifestyle: lifestyle ?? this.lifestyle,
      profession: profession ?? this.profession,
      education: education ?? this.education,
      coverUrl: coverUrl ?? this.coverUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      idVerified: idVerified ?? this.idVerified,
      idPendingReview: idPendingReview ?? this.idPendingReview,
    );
  }

  /// Profil par défaut hors connexion (aperçu UI).
  static UserProfile initialDemo() {
    return const UserProfile(
      userId: '',
      displayName: 'Amina K.',
      city: 'Lomé, Agouè',
      bio:
          'Passionnée de musique live et de bons spots à Lomé. '
          'J’aime les conversations sincères et les sorties entre ami·e·s.',
      relationGoal: 'Relation sérieuse',
      languages: 'Français, Ewe, un peu d’anglais',
      ethnicity: 'Afrique de l’Ouest',
      lifestyle: 'Sorties le week-end, rythme calme en semaine',
      profession: 'Consultante en communication',
      education: 'Master – sciences de l’information',
      coverUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=85&auto=format&fit=crop',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=85&auto=format&fit=crop',
      phoneVerified: true,
      emailVerified: false,
      idVerified: false,
      idPendingReview: false,
    );
  }
}

/// État global léger (mis à jour par [MeResponse.applyToLocalSessions]).
class ProfileSession {
  ProfileSession._();

  static final ValueNotifier<UserProfile> profile =
      ValueNotifier<UserProfile>(UserProfile.initialDemo());

  static void set(UserProfile p) {
    profile.value = p;
  }

  static void update(UserProfile Function(UserProfile current) fn) {
    profile.value = fn(profile.value);
  }
}
