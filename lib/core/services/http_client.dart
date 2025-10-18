// lib/core/services/http_client.dart
import 'package:dio/dio.dart';
import 'package:app/core/constants/endpoints.dart';
import 'package:app/core/services/token_provider.dart';

class HttpClient {
  final Dio _dio;
  String? _cachedToken;

  HttpClient._(this._dio);

  factory HttpClient(TokenProvider tokenProvider) {
    final dio = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Accept': 'application/json'},
      // <= 모든 상태코드를 '성공'으로 간주해 예외를 던지지 않게 함
      validateStatus: (code) => true,
      // 상태코드가 에러여도 바디는 받게
      receiveDataWhenStatusError: true,
    ));

    final client = HttpClient._(dio);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.baseUrl != Endpoints.baseUrl) {
          options.baseUrl = Endpoints.baseUrl;
        }
        if (options.extra['auth'] == false) return handler.next(options);

        client._cachedToken ??= await tokenProvider.read();
        final t = client._cachedToken;
        if (t != null && t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        } else {
          options.headers.remove('Authorization');
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          client._cachedToken = null;
          await tokenProvider.clear();
        }
        handler.next(e);
      },
    ));

    // 에러 로그는 끄고 요청/응답만 가볍게 출력
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: false,
      responseHeader: true,
      responseBody: true,
      error: false, // <= 여기!
    ));

    return client;
  }

  void setToken(String? token) => _cachedToken = token;
  Dio get raw => _dio;
}
