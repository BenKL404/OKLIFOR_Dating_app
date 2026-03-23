import 'package:flutter/foundation.dart';

/// Abonnement Pass VIP (démo — remplaçable par API + passerelle de paiement).
class VipSubscriptionState {
  final bool isActive;
  final DateTime? expiresAt;
  /// `monthly` | `yearly` | vide si inactif.
  final String planId;

  const VipSubscriptionState({
    required this.isActive,
    this.expiresAt,
    this.planId = '',
  });

  static const inactive = VipSubscriptionState(isActive: false);

  String get planLabelFr => switch (planId) {
        'monthly' => 'Pass VIP mensuel',
        'yearly' => 'Pass VIP annuel',
        _ => '',
      };

  String get expiresLabelFr {
    if (!isActive || expiresAt == null) return '';
    final d = expiresAt!;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}

class VipSession {
  VipSession._();

  static final ValueNotifier<VipSubscriptionState> subscription =
      ValueNotifier<VipSubscriptionState>(VipSubscriptionState.inactive);

  /// Synchronise avec `GET /api/v1/me` (Spring).
  static void setRemoteState({
    required bool isActive,
    DateTime? expiresAt,
    required String planId,
  }) {
    if (!isActive ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      subscription.value = VipSubscriptionState.inactive;
      return;
    }
    subscription.value = VipSubscriptionState(
      isActive: true,
      expiresAt: expiresAt,
      planId: planId,
    );
  }

  static void activate({required String planId, required Duration validity}) {
    subscription.value = VipSubscriptionState(
      isActive: true,
      expiresAt: DateTime.now().add(validity),
      planId: planId,
    );
  }

  static void deactivateDemo() {
    subscription.value = VipSubscriptionState.inactive;
  }
}
