import 'package:dio/dio.dart';
import '../constants/endpoints.dart';
import 'token_provider.dart';

class HttpClient {
  final Dio _dio;
  String? _cachedToken; // 메모리 캐시

  HttpClient._(this._dio);

  factory HttpClient(TokenProvider tokenProvider) {
    final dio = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,                // 예: https://api.example.com
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    final client = HttpClient._(dio);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 비인증 요청 패스
        if (options.extra['auth'] == false) {
          return handler.next(options);
        }
        // 캐시 토큰 없으면 1회 로드
        client._cachedToken ??= await tokenProvider.read();

        if (client._cachedToken != null && client._cachedToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${client._cachedToken}';
        } else {
          options.headers.remove('Authorization');
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // 401 처리 예시: 토큰 만료 → 로그아웃/클리어
        if (e.response?.statusCode == 401) {
          client._cachedToken = null;
          await tokenProvider.clear();
          // TODO: Bloc에 Logout 이벤트 발행하거나 재시도 로직 추가
        }
        handler.next(e);
      },
    ));

    dio.interceptors.add(LogInterceptor(
      responseBody: true,  // ← 응답 JSON 그대로 출력
    ));
    // 선택: 로깅
    // dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    return client;
  }

  // 로그인 성공 직후 메모리 캐시 갱신용
  void setToken(String? token) {
    _cachedToken = token;
  }

  Dio get raw => _dio;
}
