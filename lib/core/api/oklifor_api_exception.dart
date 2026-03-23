import 'package:dio/dio.dart';

class OkliforApiException implements Exception {
  OkliforApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  static OkliforApiException fromDio(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    String msg = e.message ?? 'Erreur réseau';
    if (data is Map) {
      final title = data['title']?.toString();
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) {
        msg = detail;
      } else if (title != null && title.isNotEmpty) {
        msg = title;
      }
    }
    return OkliforApiException(msg, statusCode: code);
  }
}
