// lib/core/services/recorder_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart' as fs;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class RecorderService {
  final fs.FlutterSoundRecorder _rec = fs.FlutterSoundRecorder();
  bool _opened = false;

  Future<void> init() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw Exception('Microphone permission denied');
    }
    if (!_opened) {
      await _rec.openRecorder();
      // 진행 이벤트 주기 설정
      await _rec.setSubscriptionDuration(const Duration(milliseconds: 200));
      _opened = true;
    }
  }

  Future<String> start({String filename = 'record.m4a'}) async {
    if (!_opened) await init();
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/recordings';
    await Directory(path).create(recursive: true);
    final file = '$path/$filename';
    await _rec.startRecorder(
      toFile: file,
      codec: fs.Codec.aacADTS,   // m4a 호환
      bitRate: 128000,
      sampleRate: 44100,
    );
    return file; // 예정 경로
  }

  Future<String?> stop() => _rec.stopRecorder();

  // 널 안전 스트림 제공
  Stream<fs.RecordingDisposition> get onProgress =>
      _rec.onProgress ?? const Stream<fs.RecordingDisposition>.empty();

  bool get isRecording => _rec.isRecording;

  Future<void> dispose() async {
    if (_opened) {
      await _rec.closeRecorder();
      _opened = false;
    }
  }
}
