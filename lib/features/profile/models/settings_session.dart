import 'package:flutter/foundation.dart';

import 'user_app_settings.dart';

/// État des paramètres utilisateur (synchronisé avec `GET/PATCH /api/v1/me/settings`).
class SettingsSession {
  SettingsSession._();

  static final ValueNotifier<UserAppSettings> settings =
      ValueNotifier<UserAppSettings>(UserAppSettings.defaults());

  static void set(UserAppSettings value) {
    settings.value = value;
  }

  static void reset() {
    settings.value = UserAppSettings.defaults();
  }
}
