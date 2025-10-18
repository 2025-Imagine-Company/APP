// lib/core/constants/endpoints.dart
class Endpoints {
  // 기본값은 원격 백엔드. 필요 시 --dart-define=API_BASE_URL=... 로 주입
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://13.124.143.111:8080',
  );
  static const testLogin = '/auth/login';
  static const me = '/auth/me';
  static const voiceUpload = '/voice/upload';

}
