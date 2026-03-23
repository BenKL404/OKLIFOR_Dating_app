import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_api_provider.dart';
import '../models/chat_models.dart';

final chatContactsProvider = FutureProvider<List<ChatContact>>((ref) async {
  try {
    final api = ref.read(okliforApiClientProvider);
    final payloads = await api.fetchContacts();
    return payloads
        .map(
          (p) => ChatContact(
            id: p.userId,
            name: p.displayName.isEmpty ? 'Profil Oklifor' : p.displayName,
            avatarUrl: p.avatarUrl,
          ),
        )
        .toList(growable: false);
  } catch (_) {
    return List<ChatContact>.from(kDemoContacts);
  }
});
