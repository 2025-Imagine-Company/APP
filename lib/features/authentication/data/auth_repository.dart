// lib/features/authentication/data/auth_repository.dart
import '../domain/auth_entities.dart';
import 'auth_api.dart'; // ← 추가

abstract class IAuthRepository {
  Future<AuthToken> loginWithTestWallet(String wallet);
  Future<Me> loadMe();
  Future<void> persistToken(String token);
  Future<void> logout();
}

// 토큰 저장만 분리해 DIP 준수
abstract class TokenSink {
  Future<void> save(String token);
  Future<void> clear();
}

class AuthRepository implements IAuthRepository {
  final IAuthApi api;
  final TokenSink tokenSink;

  AuthRepository({required this.api, required this.tokenSink});

  @override
  Future<AuthToken> loginWithTestWallet(String wallet) async {
    final t = await api.testLogin(wallet);
    await tokenSink.save(t.token);
    return t;
  }

  @override
  Future<Me> loadMe() => api.me();

  @override
  Future<void> persistToken(String token) => tokenSink.save(token);

  @override
  Future<void> logout() => tokenSink.clear();
}
