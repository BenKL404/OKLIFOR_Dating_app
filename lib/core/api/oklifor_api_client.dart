import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/oklifor_api_config.dart';
import 'auth_token_storage.dart';
import 'models/chat_api_models.dart';
import 'models/me_response.dart';
import 'models/settings_patch_body.dart';
import 'oklifor_api_exception.dart';

class TokenResponse {
  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInSeconds,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInSeconds;
  final String userId;

  factory TokenResponse.fromJson(Map<String, dynamic> j) {
    return TokenResponse(
      accessToken: j['accessToken'] as String? ?? '',
      refreshToken: j['refreshToken'] as String? ?? '',
      tokenType: j['tokenType'] as String? ?? 'Bearer',
      expiresInSeconds: (j['expiresInSeconds'] as num?)?.toInt() ?? 0,
      userId: j['userId'] as String? ?? '',
    );
  }
}

class OkliforApiClient {
  OkliforApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: OkliforApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final t = await _storage.readAccessToken();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          handler.next(options);
        },
      ),
    );
  }

  final AuthTokenStorage _storage;
  late final Dio _dio;

  Future<void> requestOtp(String phoneDigitsOrE164) async {
    try {
      await _dio.post<void>(
        '/api/v1/auth/otp/request',
        data: {'phone': phoneDigitsOrE164},
      );
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<TokenResponse> loginWithFirebaseIdToken({required String idToken}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/firebase',
        data: {'idToken': idToken},
      );
      return TokenResponse.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<TokenResponse> verifyOtp({
    required String phoneE164,
    required String code,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/otp/verify',
        data: {'phone': phoneE164, 'code': code},
      );
      final body = res.data ?? {};
      return TokenResponse.fromJson(body);
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  /// Selfie obligatoire. Pièce : soit [idPdfBytes], soit [idRectoBytes] + [idVersoBytes] (pas les deux).
  Future<void> submitVerificationUpload({
    required Uint8List selfieBytes,
    required String selfieFilename,
    Uint8List? idPdfBytes,
    String? idPdfFilename,
    Uint8List? idRectoBytes,
    String? idRectoFilename,
    Uint8List? idVersoBytes,
    String? idVersoFilename,
  }) async {
    final pdfBytes = idPdfBytes;
    final usePdf = pdfBytes != null && pdfBytes.isNotEmpty;
    final map = <String, dynamic>{
      'selfie': MultipartFile.fromBytes(
        selfieBytes,
        filename: selfieFilename.isEmpty ? 'selfie.jpg' : selfieFilename,
      ),
    };
    if (usePdf) {
      final pdfName = idPdfFilename;
      map['idPdf'] = MultipartFile.fromBytes(
        pdfBytes,
        filename: (pdfName != null && pdfName.isNotEmpty) ? pdfName : 'piece.pdf',
      );
    } else {
      final r = idRectoBytes;
      final v = idVersoBytes;
      if (r == null || r.isEmpty || v == null || v.isEmpty) {
        throw ArgumentError('idRecto et idVerso requis si pas de PDF');
      }
      final rectoName = idRectoFilename;
      final versoName = idVersoFilename;
      map['idRecto'] = MultipartFile.fromBytes(
        r,
        filename: (rectoName != null && rectoName.isNotEmpty) ? rectoName : 'recto.jpg',
      );
      map['idVerso'] = MultipartFile.fromBytes(
        v,
        filename: (versoName != null && versoName.isNotEmpty) ? versoName : 'verso.jpg',
      );
    }
    final form = FormData.fromMap(map);
    try {
      await _dio.post<void>('/api/v1/me/verification/submit', data: form);
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  /// Démo : valide l’identité côté serveur si `oklifor.verification.demo-approve-enabled=true`.
  Future<void> simulateVerificationApprove() async {
    try {
      await _dio.post<void>('/api/v1/me/verification/simulate-approve');
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> patchMySettings(SettingsPatchBody body) async {
    final data = body.toJson();
    if (data.isEmpty) {
      throw StateError('patch_settings_vide');
    }
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/me/settings',
        data: data,
      );
      return Map<String, dynamic>.from(res.data ?? {});
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<MeResponse> fetchMe() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/api/v1/me');
      return MeResponse.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<MeResponse> patchMyProfile({
    String? displayName,
    String? city,
    String? bio,
    String? relationGoal,
    String? languages,
    String? ethnicity,
    String? lifestyle,
    String? profession,
    String? education,
    String? coverUrl,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (city != null) body['city'] = city;
    if (bio != null) body['bio'] = bio;
    if (relationGoal != null) body['relationGoal'] = relationGoal;
    if (languages != null) body['languages'] = languages;
    if (ethnicity != null) body['ethnicity'] = ethnicity;
    if (lifestyle != null) body['lifestyle'] = lifestyle;
    if (profession != null) body['profession'] = profession;
    if (education != null) body['education'] = education;
    if (coverUrl != null) body['coverUrl'] = coverUrl;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    try {
      if (body.isNotEmpty) {
        await _dio.patch<void>('/api/v1/me/profile', data: body);
      }
      return fetchMe();
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  /// Texte + images optionnelles (JPEG/PNG/WebP). Réconcilie avec [fetchMe] après succès.
  Future<MeResponse> uploadMyProfileFull({
    required String displayName,
    required String city,
    required String bio,
    required String relationGoal,
    required String languages,
    required String ethnicity,
    required String lifestyle,
    required String profession,
    required String education,
    Uint8List? avatarBytes,
    String? avatarFilename,
    Uint8List? coverBytes,
    String? coverFilename,
  }) async {
    final map = <String, dynamic>{
      'displayName': displayName,
      'city': city,
      'bio': bio,
      'relationGoal': relationGoal,
      'languages': languages,
      'ethnicity': ethnicity,
      'lifestyle': lifestyle,
      'profession': profession,
      'education': education,
    };
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      final fn = avatarFilename;
      map['avatar'] = MultipartFile.fromBytes(
        avatarBytes,
        filename: (fn != null && fn.isNotEmpty) ? fn : 'avatar.jpg',
      );
    }
    if (coverBytes != null && coverBytes.isNotEmpty) {
      final fn = coverFilename;
      map['cover'] = MultipartFile.fromBytes(
        coverBytes,
        filename: (fn != null && fn.isNotEmpty) ? fn : 'cover.jpg',
      );
    }
    final form = FormData.fromMap(map);
    try {
      await _dio.post<void>('/api/v1/me/profile/upload-full', data: form);
      return fetchMe();
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<void> persistTokens(TokenResponse tokens) async {
    await _storage.writeTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      userId: tokens.userId,
    );
  }

  Future<void> logout() async {
    await _storage.clear();
  }

  Future<MeResponse> activateSubscription({
    required String planCode,
    String? paymentProvider,
    String? externalPaymentReference,
  }) async {
    try {
      await _dio.post<void>(
        '/api/v1/me/subscription/activate',
        data: {
          'planCode': planCode,
          if (paymentProvider != null && paymentProvider.isNotEmpty)
            'paymentProvider': paymentProvider,
          if (externalPaymentReference != null &&
              externalPaymentReference.isNotEmpty)
            'externalPaymentReference': externalPaymentReference,
        },
      );
      return fetchMe();
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<List<ChatThreadPayload>> fetchChatThreads() async {
    try {
      final res = await _dio.get<List<dynamic>>('/api/v1/chat/threads');
      final list = res.data ?? [];
      return list
          .whereType<Map>()
          .map((m) => ChatThreadPayload.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<List<ChatMessagePayload>> fetchChatMessages(
    String threadId, {
    int size = 50,
  }) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/api/v1/chat/threads/$threadId/messages',
        queryParameters: {'size': size},
      );
      final list = res.data ?? [];
      return list
          .whereType<Map>()
          .map((m) => ChatMessagePayload.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<ChatMessagePayload> sendChatMessage({
    required String threadId,
    required String kind,
    String? text,
    String? imageUrl,
    int? voiceSeconds,
    String? locationLabel,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/chat/threads/$threadId/messages',
        data: {
          'kind': kind,
          'text': ?text,
          'imageUrl': ?imageUrl,
          'voiceSeconds': ?voiceSeconds,
          'locationLabel': ?locationLabel,
        },
      );
      return ChatMessagePayload.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }

  Future<ChatThreadPayload> createDirectThread(String peerUserId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/chat/threads/direct',
        data: {'peerUserId': peerUserId},
      );
      return ChatThreadPayload.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw OkliforApiException.fromDio(e);
    }
  }
}
