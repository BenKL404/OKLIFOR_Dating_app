/// Préférences alignées sur [SettingsResponse] / [SettingsPatchRequest] côté Spring.
class UserAppSettings {
  const UserAppSettings({
    required this.protectDirectory,
    required this.neighborhoodMode,
    required this.incognito,
    required this.notifyMessages,
    required this.notifyLikes,
    required this.notifyMatches,
    required this.notifyLive,
    required this.notifyEmail,
    required this.notifySound,
    required this.privacyShowOnline,
    required this.privacyShowDistance,
    required this.privacyReadReceipts,
    required this.privacyAllowRequests,
    required this.securityTwoFactor,
    required this.securityBiometric,
    required this.securityScreenLock,
    required this.appLanguage,
    required this.appAutoPlayMedia,
    required this.appDataSaver,
    required this.appVibrate,
  });

  final bool protectDirectory;
  final bool neighborhoodMode;
  final bool incognito;
  final bool notifyMessages;
  final bool notifyLikes;
  final bool notifyMatches;
  final bool notifyLive;
  final bool notifyEmail;
  final bool notifySound;
  final bool privacyShowOnline;
  final bool privacyShowDistance;
  final bool privacyReadReceipts;
  final bool privacyAllowRequests;
  final bool securityTwoFactor;
  final bool securityBiometric;
  final bool securityScreenLock;
  final String appLanguage;
  final bool appAutoPlayMedia;
  final bool appDataSaver;
  final bool appVibrate;

  static UserAppSettings defaults() => const UserAppSettings(
        protectDirectory: true,
        neighborhoodMode: true,
        incognito: false,
        notifyMessages: true,
        notifyLikes: true,
        notifyMatches: true,
        notifyLive: false,
        notifyEmail: false,
        notifySound: true,
        privacyShowOnline: true,
        privacyShowDistance: true,
        privacyReadReceipts: true,
        privacyAllowRequests: true,
        securityTwoFactor: false,
        securityBiometric: false,
        securityScreenLock: true,
        appLanguage: 'fr',
        appAutoPlayMedia: true,
        appDataSaver: false,
        appVibrate: true,
      );

  static bool _b(Map<String, dynamic> j, String k, bool d) =>
      j[k] as bool? ?? d;

  factory UserAppSettings.fromJson(Map<String, dynamic> j) {
    if (j.isEmpty) return defaults();
    return UserAppSettings(
      protectDirectory: _b(j, 'protectDirectory', true),
      neighborhoodMode: _b(j, 'neighborhoodMode', true),
      incognito: _b(j, 'incognito', false),
      notifyMessages: _b(j, 'notifyMessages', true),
      notifyLikes: _b(j, 'notifyLikes', true),
      notifyMatches: _b(j, 'notifyMatches', true),
      notifyLive: _b(j, 'notifyLive', false),
      notifyEmail: _b(j, 'notifyEmail', false),
      notifySound: _b(j, 'notifySound', true),
      privacyShowOnline: _b(j, 'privacyShowOnline', true),
      privacyShowDistance: _b(j, 'privacyShowDistance', true),
      privacyReadReceipts: _b(j, 'privacyReadReceipts', true),
      privacyAllowRequests: _b(j, 'privacyAllowRequests', true),
      securityTwoFactor: _b(j, 'securityTwoFactor', false),
      securityBiometric: _b(j, 'securityBiometric', false),
      securityScreenLock: _b(j, 'securityScreenLock', true),
      appLanguage: j['appLanguage'] as String? ?? 'fr',
      appAutoPlayMedia: _b(j, 'appAutoPlayMedia', true),
      appDataSaver: _b(j, 'appDataSaver', false),
      appVibrate: _b(j, 'appVibrate', true),
    );
  }

  UserAppSettings copyWith({
    bool? protectDirectory,
    bool? neighborhoodMode,
    bool? incognito,
    bool? notifyMessages,
    bool? notifyLikes,
    bool? notifyMatches,
    bool? notifyLive,
    bool? notifyEmail,
    bool? notifySound,
    bool? privacyShowOnline,
    bool? privacyShowDistance,
    bool? privacyReadReceipts,
    bool? privacyAllowRequests,
    bool? securityTwoFactor,
    bool? securityBiometric,
    bool? securityScreenLock,
    String? appLanguage,
    bool? appAutoPlayMedia,
    bool? appDataSaver,
    bool? appVibrate,
  }) {
    return UserAppSettings(
      protectDirectory: protectDirectory ?? this.protectDirectory,
      neighborhoodMode: neighborhoodMode ?? this.neighborhoodMode,
      incognito: incognito ?? this.incognito,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyLikes: notifyLikes ?? this.notifyLikes,
      notifyMatches: notifyMatches ?? this.notifyMatches,
      notifyLive: notifyLive ?? this.notifyLive,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      notifySound: notifySound ?? this.notifySound,
      privacyShowOnline: privacyShowOnline ?? this.privacyShowOnline,
      privacyShowDistance: privacyShowDistance ?? this.privacyShowDistance,
      privacyReadReceipts: privacyReadReceipts ?? this.privacyReadReceipts,
      privacyAllowRequests: privacyAllowRequests ?? this.privacyAllowRequests,
      securityTwoFactor: securityTwoFactor ?? this.securityTwoFactor,
      securityBiometric: securityBiometric ?? this.securityBiometric,
      securityScreenLock: securityScreenLock ?? this.securityScreenLock,
      appLanguage: appLanguage ?? this.appLanguage,
      appAutoPlayMedia: appAutoPlayMedia ?? this.appAutoPlayMedia,
      appDataSaver: appDataSaver ?? this.appDataSaver,
      appVibrate: appVibrate ?? this.appVibrate,
    );
  }
}
