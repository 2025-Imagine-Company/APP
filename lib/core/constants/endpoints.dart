// lib/core/constants/endpoints.dart
class Endpoints {
  // 기본값은 원격 백엔드. 필요 시 --dart-define=API_BASE_URL=... 로 주입
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://audion.site',
  );
  static const testLogin = '/auth/login';
  static const me = '/auth/me';

  // voice
  static const voiceUpload = '/voice/upload';
  static String voiceGet(String id) => '/voice/$id';
  static const voiceMyFiles = '/voice/my-files';
  static const voiceMyFilesPaged = '/voice/my-files/paged';

  // model
  static const modelCreate = '/model';
  static String modelGet(String id) => '/model/$id';
  static const modelMyModels = '/model/my-models';
  static const modelMyModelsPaged = '/model/my-models/paged';
}
