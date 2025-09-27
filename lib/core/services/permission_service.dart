import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

abstract class IPermissionService {
  Future<bool> ensureMic();           // 필요 시 요청
  Future<bool> hasMic();              // 상태만 확인
  Future<void> openSettings();        // 설정 화면 열기
}

class PermissionService implements IPermissionService {
  @override
  Future<bool> hasMic() async {
    if (kIsWeb) return true; // 웹은 녹음 UX별로 별도 처리. 여기선 통과.
    final s = await Permission.microphone.status;
    return s.isGranted;
  }

  @override
  Future<bool> ensureMic() async {
    if (kIsWeb) return true;
    var s = await Permission.microphone.status;
    if (s.isGranted) return true;

    s = await Permission.microphone.request();
    if (s.isGranted) return true;

    if (s.isPermanentlyDenied) {
      // 사용자가 “다시 묻지 않기” 선택
      return false;
    }
    return false;
  }

  @override
  Future<void> openSettings() => openAppSettings();
}
