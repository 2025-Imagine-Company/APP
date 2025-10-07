// lib/features/record/presentation/controllers/record_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

enum RecState { stopped, recording, paused }

class RecordController extends ChangeNotifier {
  RecordController({
    required List<String> lines,
    Duration interval = const Duration(seconds: 2), // ← this.interval 제거
    bool autoplay = false,
  })  : _lines = List.unmodifiable(lines),
        _interval = interval {
    if (autoplay) start();
  }

  final List<String> _lines;
  final Duration _interval;

  Timer? _timer;
  int _index = 0;
  RecState _state = RecState.stopped;

  List<String> get lines => _lines;
  int get index => _index;
  RecState get state => _state;
  bool get isRecording => _state == RecState.recording;

  void start() {
    if (_state == RecState.recording) return;  // ← 가드
    _timer?.cancel();
    _state = RecState.recording;
    notifyListeners();
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  void pause() {
    if (_state != RecState.recording) return;  // ← 가드
    _timer?.cancel();
    _state = RecState.paused;
    notifyListeners();
  }

  void resume() => start();

  void stop({bool rewind = false}) {
    if (_state == RecState.stopped) return;    // ← 가드
    _timer?.cancel();
    _state = RecState.stopped;
    if (rewind) _index = 0;
    notifyListeners();
  }

  void _tick() {
    if (_index < _lines.length - 1) {
      _index += 1;
      notifyListeners();
    } else {
      stop(rewind: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
