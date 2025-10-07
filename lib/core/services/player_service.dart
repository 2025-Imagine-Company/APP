// lib/core/services/player_service.dart
import 'package:audioplayers/audioplayers.dart';

class PlayerService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> setSource(String path) async {
    await _player.setSourceDeviceFile(path);
  }

  Future<void> play() => _player.resume();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration d) => _player.seek(d);

  Stream<PlayerState> get state$ => _player.onPlayerStateChanged;
  Stream<Duration> get duration$ => _player.onDurationChanged;
  Stream<Duration> get position$ => _player.onPositionChanged;

  Future<void> dispose() async => _player.dispose();
}
