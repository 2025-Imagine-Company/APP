import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenProvider {
  Future<void> save(String token);
  Future<String?> read();
  Future<bool> hasToken();
  Future<void> clear();
  String? get cached; // 메모리 값 즉시 확인용
}

class SecureTokenProvider implements TokenProvider {
  // --- 싱글턴 ---
  static final SecureTokenProvider _instance =
  SecureTokenProvider._internal(keyNamespace: 'prod');
  factory SecureTokenProvider() => _instance;

  SecureTokenProvider._internal({String keyNamespace = 'prod'})
      : _k = '${keyNamespace}_auth_token';

  final String _k;
  final _storage = const FlutterSecureStorage();
  String? _cache;

  AndroidOptions get _a => const AndroidOptions(
    encryptedSharedPreferences: true,
  );
  IOSOptions get _i => const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );
  WebOptions get _w => const WebOptions(dbName: 'app_kv');

  @override
  Future<void> save(String token) async {
    _cache = token;
    await _storage.write(
      key: _k,
      value: token,
      aOptions: _a,
      iOptions: _i,
      webOptions: _w,
    );
  }

  @override
  Future<String?> read() async {
    if (_cache != null && _cache!.isNotEmpty) return _cache;
    _cache = await _storage.read(
      key: _k,
      aOptions: _a,
      iOptions: _i,
      webOptions: _w,
    );
    return _cache;
  }

  @override
  Future<bool> hasToken() async => (await read())?.isNotEmpty == true;

  @override
  Future<void> clear() async {
    _cache = null;
    await _storage.delete(
      key: _k,
      aOptions: _a,
      iOptions: _i,
      webOptions: _w,
    );
  }

  @override
  String? get cached => _cache;
}
