// lib/features/authentication/data/auth_api.dart
import 'package:dio/dio.dart';
import '../../../core/constants/endpoints.dart';
import '../domain/auth_entities.dart';

abstract class IAuthApi {
  Future<AuthToken> testLogin(String wallet);
  Future<Me> me();
}

class AuthApi implements IAuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  @override
  Future<AuthToken> testLogin(String wallet) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.testLogin,
      queryParameters: {'walletAddress': wallet.toLowerCase()}, // ← 쿼리 전송
      options: Options(extra: {'auth': false}),                  // ← 토큰 미부착
    );
    final d = res.data!;
    return AuthToken(
      token: d['token'] as String,
      type: d['type'] as String,
      walletAddress: d['walletAddress'] as String,
      expiresInHours: (d['expiresInHours'] as num).toInt(),
      note: d['note'] as String?,
    );
  }

  @override
  Future<Me> me() async {
    final res = await _dio.get<Map<String, dynamic>>(Endpoints.me); // ← Bearer 자동 부착
    final d = res.data!;
    return Me(
      userId: d['userId'] as String,
      walletAddress: d['walletAddress'] as String,
      tokenRemainingSeconds: (d['tokenRemainingSeconds'] as num).toInt(),
      isValid: d['isValid'] as bool,
    );
  }
}
