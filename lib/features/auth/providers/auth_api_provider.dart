import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/auth_token_storage.dart';
import '../../../core/api/oklifor_api_client.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage();
});

final okliforApiClientProvider = Provider<OkliforApiClient>((ref) {
  return OkliforApiClient(ref.watch(authTokenStorageProvider));
});
