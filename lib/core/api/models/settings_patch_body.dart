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
        if (protectDirectory != null) 'protectDirectory': protectDirectory,
        if (neighborhoodMode != null) 'neighborhoodMode': neighborhoodMode,
        if (incognito != null) 'incognito': incognito,
        if (notifyMessages != null) 'notifyMessages': notifyMessages,
        if (notifyLikes != null) 'notifyLikes': notifyLikes,
        if (notifyMatches != null) 'notifyMatches': notifyMatches,
        if (notifyLive != null) 'notifyLive': notifyLive,
        if (notifyEmail != null) 'notifyEmail': notifyEmail,
        if (notifySound != null) 'notifySound': notifySound,
        if (privacyShowOnline != null) 'privacyShowOnline': privacyShowOnline,
        if (privacyShowDistance != null) 'privacyShowDistance': privacyShowDistance,
        if (privacyReadReceipts != null) 'privacyReadReceipts': privacyReadReceipts,
        if (privacyAllowRequests != null) 'privacyAllowRequests': privacyAllowRequests,
        if (securityTwoFactor != null) 'securityTwoFactor': securityTwoFactor,
        if (securityBiometric != null) 'securityBiometric': securityBiometric,
        if (securityScreenLock != null) 'securityScreenLock': securityScreenLock,
        if (appLanguage != null) 'appLanguage': appLanguage,
        if (appAutoPlayMedia != null) 'appAutoPlayMedia': appAutoPlayMedia,
        if (appDataSaver != null) 'appDataSaver': appDataSaver,
        if (appVibrate != null) 'appVibrate': appVibrate,
      };
}
