import '../../../features/profile/models/settings_session.dart';
import '../../../features/profile/models/user_app_settings.dart';
import '../../../features/profile/models/user_profile.dart';
import '../../../features/profile/models/vip_subscription.dart';

class MeResponse {
  MeResponse({
    required this.userId,
    required this.phoneE164,
    required this.profile,
    required this.settings,
    required this.subscription,
  });

  final String userId;
  final String phoneE164;
  final MeProfileJson profile;
  final Map<String, dynamic> settings;
  final MeSubscriptionJson subscription;

  factory MeResponse.fromJson(Map<String, dynamic> j) {
    return MeResponse(
      userId: j['userId'] as String? ?? '',
      phoneE164: j['phoneE164'] as String? ?? '',
      profile: MeProfileJson.fromJson(j['profile'] as Map<String, dynamic>? ?? {}),
      settings: Map<String, dynamic>.from(j['settings'] as Map? ?? {}),
      subscription:
          MeSubscriptionJson.fromJson(j['subscription'] as Map<String, dynamic>? ?? {}),
    );
  }

  UserProfile toUserProfile() {
    return UserProfile(
      userId: userId,
      displayName: profile.displayName,
      city: profile.city,
      bio: profile.bio,
      relationGoal: profile.relationGoal,
      languages: profile.languages,
      ethnicity: profile.ethnicity,
      lifestyle: profile.lifestyle,
      profession: profile.profession,
      education: profile.education,
      coverUrl: profile.coverUrl,
      avatarUrl: profile.avatarUrl,
      phoneVerified: profile.phoneVerified,
      emailVerified: profile.emailVerified,
      idVerified: profile.idVerified,
      idPendingReview: profile.idPendingReview,
      profileOnboardingCompleted: profile.profileOnboardingCompleted,
    );
  }

  void applyVipSession() {
    subscription.applyToVipSession();
  }

  void applyToLocalSessions() {
    ProfileSession.set(toUserProfile());
    SettingsSession.set(UserAppSettings.fromJson(settings));
    subscription.applyToVipSession();
  }
}

class MeProfileJson {
  MeProfileJson({
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
    required this.phoneVerified,
    required this.emailVerified,
    required this.idVerified,
    required this.idPendingReview,
    this.profileOnboardingCompleted = true,
  });

  final String displayName;
  final String city;
  final String bio;
  final String relationGoal;
  final String languages;
  final String ethnicity;
  final String lifestyle;
  final String profession;
  final String education;
  final String coverUrl;
  final String avatarUrl;
  final bool phoneVerified;
  final bool emailVerified;
  final bool idVerified;
  final bool idPendingReview;
  /// Si `false`, afficher l’assistant profil après connexion.
  final bool profileOnboardingCompleted;

  factory MeProfileJson.fromJson(Map<String, dynamic> j) {
    return MeProfileJson(
      displayName: j['displayName'] as String? ?? '',
      city: j['city'] as String? ?? '',
      bio: j['bio'] as String? ?? '',
      relationGoal: j['relationGoal'] as String? ?? '',
      languages: j['languages'] as String? ?? '',
      ethnicity: j['ethnicity'] as String? ?? '',
      lifestyle: j['lifestyle'] as String? ?? '',
      profession: j['profession'] as String? ?? '',
      education: j['education'] as String? ?? '',
      coverUrl: j['coverUrl'] as String? ?? '',
      avatarUrl: j['avatarUrl'] as String? ?? '',
      phoneVerified: j['phoneVerified'] as bool? ?? false,
      emailVerified: j['emailVerified'] as bool? ?? false,
      idVerified: j['idVerified'] as bool? ?? false,
      idPendingReview: j['idPendingReview'] as bool? ?? false,
      profileOnboardingCompleted: j['profileOnboardingCompleted'] as bool? ?? true,
    );
  }
}

class MeSubscriptionJson {
  MeSubscriptionJson({
    required this.active,
    this.validUntil,
    required this.planCode,
    this.planUuid,
  });

  final bool active;
  final DateTime? validUntil;
  final String planCode;
  final String? planUuid;

  factory MeSubscriptionJson.fromJson(Map<String, dynamic> j) {
    DateTime? until;
    final v = j['validUntil'];
    if (v is String && v.isNotEmpty) {
      until = DateTime.tryParse(v);
    }
    return MeSubscriptionJson(
      active: j['active'] as bool? ?? false,
      validUntil: until,
      planCode: j['planCode'] as String? ?? '',
      planUuid: j['planUuid'] as String?,
    );
  }

  void applyToVipSession() {
    VipSession.setRemoteState(
      isActive: active,
      expiresAt: validUntil,
      planId: planCode,
    );
  }
}
