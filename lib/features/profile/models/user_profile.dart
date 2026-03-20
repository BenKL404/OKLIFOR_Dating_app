import 'package:flutter/foundation.dart';

/// Données profil + étapes de vérification (démo, synchronisées via [ProfileSession]).
class UserProfile {
  final String displayName;
  final String city;
  final String bio;
  final String relationGoal;
  final String languages;
  final String coverUrl;
  final String avatarUrl;

  final bool phoneVerified;
  final bool emailVerified;
  final bool idVerified;
  final bool idPendingReview;

  const UserProfile({
    required this.displayName,
    required this.city,
    required this.bio,
    required this.relationGoal,
    required this.languages,
    required this.coverUrl,
    required this.avatarUrl,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.idVerified = false,
    this.idPendingReview = false,
  });

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
    String? displayName,
    String? city,
    String? bio,
    String? relationGoal,
    String? languages,
    String? coverUrl,
    String? avatarUrl,
    bool? phoneVerified,
    bool? emailVerified,
    bool? idVerified,
    bool? idPendingReview,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      relationGoal: relationGoal ?? this.relationGoal,
      languages: languages ?? this.languages,
      coverUrl: coverUrl ?? this.coverUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      idVerified: idVerified ?? this.idVerified,
      idPendingReview: idPendingReview ?? this.idPendingReview,
    );
  }

  static UserProfile initialDemo() {
    return const UserProfile(
      displayName: 'Amina K.',
      city: 'Lomé, Agouè',
      bio:
          'Passionnée de musique live et de bons spots à Lomé. '
          'J’aime les conversations sincères et les sorties entre ami·e·s.',
      relationGoal: 'Relation sérieuse',
      languages: 'Français, Ewe, un peu d’anglais',
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

/// État global léger pour la démo (remplaçable par Riverpod / API plus tard).
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
