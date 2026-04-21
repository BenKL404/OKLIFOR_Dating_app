import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/offline_action_queue.dart';
import '../../../core/utils/offline_sync_coordinator.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../models/chat_models.dart';
import 'chat_api_mapping.dart';
import 'chat_local_cache.dart';

/// Envoie tous les messages chat en attente (hors ligne) et met à jour le cache disque.
Future<void> flushAllPendingChatMessages(WidgetRef ref) async {
  final userId = await ref.read(authTokenStorageProvider).readUserId() ?? '';
  if (userId.isEmpty) return;
  final threadIds = await OfflineActionQueue.pendingChatThreadIds(userId);
  if (threadIds.isEmpty) return;
  final api = ref.read(okliforApiClientProvider);
  var didSync = false;

  for (final threadId in threadIds) {
    final actions = await OfflineActionQueue.loadSendChatMessageActions(
      userId: userId,
      threadId: threadId,
    );
    if (actions.isEmpty) continue;

    var disk = await ChatLocalCache.loadMessages(userId, threadId) ?? <ChatMessage>[];
    final toRemove = <String>{};

    for (final a in actions) {
      final actionId = a['id']?.toString() ?? '';
      final localId = a['localMessageId']?.toString() ?? '';
      final kind = a['kind']?.toString() ?? '';
      if (actionId.isEmpty || localId.isEmpty || kind.isEmpty) {
        if (actionId.isNotEmpty) toRemove.add(actionId);
        continue;
      }
      try {
        final sent = await api.sendChatMessage(
          threadId: threadId,
          kind: kind,
          text: a['text'] as String?,
          imageUrl: a['imageUrl'] as String?,
          videoUrl: a['videoUrl'] as String?,
          audioUrl: a['audioUrl'] as String?,
          voiceSeconds: (a['voiceSeconds'] as num?)?.toInt(),
          locationLabel: a['locationLabel'] as String?,
          fileUrl: a['fileUrl'] as String?,
        );
        final mapped = chatMessageFromPayload(sent, myUserId: userId);
        disk = disk.where((m) => m.id != localId).toList();
        if (!disk.any((m) => m.id == mapped.id)) {
          disk.add(mapped);
        }
        await ChatLocalCache.saveMessages(userId, threadId, disk);
        toRemove.add(actionId);
        didSync = true;
      } catch (_) {
        break;
      }
    }
    await OfflineActionQueue.removeActionsByIds(userId: userId, ids: toRemove);
  }
  if (didSync) OfflineSyncCoordinator.bump();
}
