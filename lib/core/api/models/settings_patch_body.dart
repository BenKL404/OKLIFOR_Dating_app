/// Corps partiel pour `PATCH /api/v1/me/settings` (champs null = omis du JSON).
class SettingsPatchBody {
  const SettingsPatchBody({
    this.protectDirectory,
    this.neighborhoodMode,
    this.incognito,
    this.notifyMessages,
    this.notifyLikes,
    this.notifyMatches,
    this.notifyLive,
    this.notifyEmail,
    this.notifySound,
    this.privacyShowOnline,
    this.privacyShowDistance,
    this.privacyReadReceipts,
    this.privacyAllowRequests,
    this.securityTwoFactor,
    this.securityBiometric,
    this.securityScreenLock,
    this.appLanguage,
    this.appAutoPlayMedia,
    this.appDataSaver,
    this.appVibrate,
  });

  final bool? protectDirectory;
  final bool? neighborhoodMode;
  final bool? incognito;
  final bool? notifyMessages;
  final bool? notifyLikes;
  final bool? notifyMatches;
  final bool? notifyLive;
  final bool? notifyEmail;
  final bool? notifySound;
  final bool? privacyShowOnline;
  final bool? privacyShowDistance;
  final bool? privacyReadReceipts;
  final bool? privacyAllowRequests;
  final bool? securityTwoFactor;
  final bool? securityBiometric;
  final bool? securityScreenLock;
  final String? appLanguage;
  final bool? appAutoPlayMedia;
  final bool? appDataSaver;
  final bool? appVibrate;

  Map<String, dynamic> toJson() => {
        'protectDirectory': ?protectDirectory,
        'neighborhoodMode': ?neighborhoodMode,
        'incognito': ?incognito,
        'notifyMessages': ?notifyMessages,
        'notifyLikes': ?notifyLikes,
        'notifyMatches': ?notifyMatches,
        'notifyLive': ?notifyLive,
        'notifyEmail': ?notifyEmail,
        'notifySound': ?notifySound,
        'privacyShowOnline': ?privacyShowOnline,
        'privacyShowDistance': ?privacyShowDistance,
        'privacyReadReceipts': ?privacyReadReceipts,
        'privacyAllowRequests': ?privacyAllowRequests,
        'securityTwoFactor': ?securityTwoFactor,
        'securityBiometric': ?securityBiometric,
        'securityScreenLock': ?securityScreenLock,
        'appLanguage': ?appLanguage,
        'appAutoPlayMedia': ?appAutoPlayMedia,
        'appDataSaver': ?appDataSaver,
        'appVibrate': ?appVibrate,
      };
}
