// lib/features/authentication/data/auth_repository.dart
import '../domain/auth_entities.dart';
import 'auth_api.dart'; // ← 추가

abstract class IAuthRepository {
  Future<AuthToken> loginWithTestWallet(String wallet);
  Future<AuthToken> loginWithSignature({required String walletAddress, required String message, required String signature});
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
    // TODO: 실제 구현에서는 월렛 서명(message, signature)을 받아 전달해야 함
    final t = await api.testLogin(
      walletAddress: wallet,
      message: 'Sign in to Audion',
      signature: '0x' + '0'.padRight(130, '0'), // placeholder
    );
    await tokenSink.save(t.token);
    return t;
  }

  @override
  Future<AuthToken> loginWithSignature({required String walletAddress, required String message, required String signature}) async {
    final t = await api.testLogin(
      walletAddress: walletAddress,
      message: message,
      signature: signature,
    );
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
