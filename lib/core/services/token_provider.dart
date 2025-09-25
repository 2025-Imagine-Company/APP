// lib/core/services/token_provider.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenProvider {
  Future<void> save(String token);
  Future<String?> read();
  Future<void> clear();
}

class SecureTokenProvider implements TokenProvider {
  static const _k = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> save(String token) => _storage.write(key: _k, value: token);

  @override
  Future<String?> read() => _storage.read(key: _k);

  @override
  Future<void> clear() => _storage.delete(key: _k);
}
