import 'package:flutter/foundation.dart';

/// Incrémenté après une synchronisation globale des messages hors ligne
/// (ex. [flushAllPendingChatMessages]) pour que l’écran discussion recharge le cache disque.
class OfflineSyncCoordinator {
  OfflineSyncCoordinator._();

  static final ValueNotifier<int> generation = ValueNotifier<int>(0);

  static void bump() => generation.value++;
}
