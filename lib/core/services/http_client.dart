// lib/core/services/http_client.dart
import 'package:dio/dio.dart';
import '../constants/endpoints.dart';
import 'token_provider.dart';

class HttpClient {
  final Dio _dio;
  HttpClient._(this._dio);

  factory HttpClient(TokenProvider tokenProvider) {
    final dio = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Accept': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenProvider.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }
        handler.next(options);
      },
    ));
    return HttpClient._(dio);
  }

  Dio get raw => _dio;
}
