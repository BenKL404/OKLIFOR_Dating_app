import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/settings_patch_body.dart';
import '../../../core/api/oklifor_api_exception.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../models/settings_session.dart';
import '../models/user_app_settings.dart';

/// Applique un patch optimiste, envoie `PATCH /me/settings`, puis réconcilie avec la réponse serveur.
Future<void> persistAppSettings(
  WidgetRef ref,
  BuildContext context, {
  required UserAppSettings Function(UserAppSettings previous) applyOptimistic,
  required SettingsPatchBody patch,
}) async {
  final prev = SettingsSession.settings.value;
  final optimistic = applyOptimistic(prev);
  SettingsSession.set(optimistic);
  try {
    final json =
        await ref.read(okliforApiClientProvider).patchMySettings(patch);
    SettingsSession.set(UserAppSettings.fromJson(json));
  } on OkliforApiException catch (e) {
    // Offline-first: si c’est un problème réseau, on garde l’optimiste local.
    // Si token invalide (401/403), on annule (sinon l’app diverge côté serveur).
    final code = e.statusCode;
    if (code == 401 || code == 403) {
      SettingsSession.set(prev);
    }
    if (context.mounted) {
      OklFeedback.snack(
        context,
        (code == null)
            ? 'Hors ligne: réglage enregistré localement'
            : e.message,
      );
    }
  } catch (e) {
    // Offline / erreur inconnue: garder l'optimiste local.
    if (context.mounted) {
      OklFeedback.snack(context, 'Hors ligne: réglage enregistré localement');
    }
  }
}
