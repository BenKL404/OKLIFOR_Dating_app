import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/models/me_response.dart';

/// Après OTP ou splash avec session valide : applique les sessions puis route l’assistant profil ou l’accueil.
void applyMeAndGoHome(BuildContext context, MeResponse me) {
  me.applyToLocalSessions();
  if (!me.profile.profileOnboardingCompleted) {
    context.go('/profile-setup');
  } else {
    context.go('/discovery');
  }
}
