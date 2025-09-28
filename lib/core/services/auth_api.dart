import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthApiService {
  AuthApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8085',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ));

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'accessToken';
  static const String _addressKey = 'walletAddress';

  Future<String> fetchNonce(String address) async {
    final res = await _dio.post('/auth/nonce', data: {'address': address});
    return res.data['nonce'] as String;
  }

  Future<String> verifyAndIssueToken({required String address, required String signature}) async {
    final res = await _dio.post('/auth/verify', data: {
      'address': address,
      'signature': signature,
    });
    final token = res.data['accessToken'] as String;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _addressKey, value: address);
    return token;
  }

  Future<Map<String, dynamic>> getMe() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      // 토큰이 없다면 로컬에 저장된 주소로 최소 정보 반환
      final savedAddress = await _storage.read(key: _addressKey);
      if (savedAddress != null && savedAddress.isNotEmpty) {
        return {'nickname': 'Name', 'address': savedAddress};
      }
      throw StateError('No access token');
    }
    final res = await _dio.get('/me', options: Options(headers: {
      'Authorization': 'Bearer $token',
    }));
    return res.data as Map<String, dynamic>;
  }

  Future<String?> getStoredAddress() async {
    return _storage.read(key: _addressKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}


