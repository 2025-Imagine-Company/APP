// lib/features/record/presentation/recording_text_screen.dart
import 'package:flutter/material.dart';
import 'controllers/record_controller.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart' as fs;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    this.lines = const <String>[
      '마이크 테스트를 시작합니다.',
      '지금은 예시 문장입니다.',
      '녹음과 자막 싱크를 확인하세요.',
      '일시정지 후 재개도 점검합니다.',
      '마지막 줄입니다.',
    ],
    this.interval = const Duration(seconds: 2),
    this.autoplay = false,
  });

  final List<String> lines;
  final Duration interval;
  final bool autoplay;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with WidgetsBindingObserver {
  late final RecordController _controller;
  final _scroll = ScrollController();

  final fs.FlutterSoundRecorder _rec = fs.FlutterSoundRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _recOpened = false;
  bool _isRec = false;
  bool _isPlaying = false;

  String? _lastPath;
  Duration _aDur = Duration.zero;
  Duration _aPos = Duration.zero;

  static const _rowHeight = 24.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = RecordController(
      lines: widget.lines,
      interval: widget.interval,
      autoplay: widget.autoplay,
    )..addListener(_onChanged);

    _initAudioLayer();
  }

  Future<void> _initAudioLayer() async {
    if (!_recOpened) {
      await _rec.openRecorder();
      _recOpened = true;
    }
    _player.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) {
      setState(() => _aDur = d);
    });
    _player.onPositionChanged.listen((p) {
      setState(() => _aPos = p);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_controller.state == RecState.recording) _controller.pause();
      if (_isRec) _pauseRec();
    }
  }

  void _onChanged() {
    if (_controller.state == RecState.stopped && _isRec) {
      _stopRec();
    }

    final target = (_controller.index * _rowHeight) - 100;
    final max = _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
    _scroll.animateTo(
      target.clamp(0, max),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller..removeListener(_onChanged)..dispose();
    _scroll.dispose();

    _player.dispose();
    if (_recOpened) {
      _rec.closeRecorder();
    }
    super.dispose();
  }

  Future<void> _startRec() async {
    if (!_recOpened) await _rec.openRecorder();
    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${dir.path}/recordings');
    if (!await recDir.exists()) await recDir.create(recursive: true);

    String file = '${recDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _rec.startRecorder(
        toFile: file,
        codec: fs.Codec.aacMP4,
        bitRate: 128000,
        sampleRate: 44100,
      );
    } catch (e) {
      file = '${recDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _rec.startRecorder(
        toFile: file,
        codec: fs.Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
    }

    setState(() {
      _isRec = true;
      _lastPath = file;
    });
  }


  Future<void> _pauseRec() async {
    try { await _rec.pauseRecorder(); } catch (_) {}
    setState(() => _isRec = false);
  }

  Future<void> _resumeRec() async {
    try { await _rec.resumeRecorder(); } catch (_) { await _startRec(); }
    setState(() => _isRec = true);
  }

  Future<void> _stopRec() async {
    final path = await _rec.stopRecorder();
    _isRec = false;
    if (path != null && path.isNotEmpty) {
      _lastPath = path;

      // 저장 파일 확인
      final f = File(path);
      final ok = await f.exists();
      final len = ok ? await f.length() : 0;
      debugPrint('Saved: $path  exists=$ok  bytes=$len');

      await _player.setSourceDeviceFile(path); // 재생 준비
    }
    setState(() {});
  }


  Future<List<FileSystemEntity>> listRecs() async {
    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${dir.path}/recordings');
    if (!await recDir.exists()) return [];
    return recDir.list().toList(); // 파일들 경로 확인용
  }

  Future<void> _handleStop() async {
    if (_isRec || _rec.isPaused) await _stopRec();
    _controller.stop(rewind: true);
  }

  Future<void> _handlePause() async {
    _controller.pause();
    if (_isRec) {
      await _pauseRec();
    }
    if (_isPlaying) {
      await _player.pause();
    }
  }

  Future<void> _handlePlay() async {
    if (_controller.state == RecState.stopped) {
      await _startRec();         // 파일 먼저 열고
      _controller.start();       // 타이머 시작
      _lastPath = null;
    } else {
      _controller.resume();
      if (!_isRec) await _resumeRec();
    }
  }


  Future<void> stopPlay() async => _player.stop(); // 반환타입 명시

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final isRecording = state == RecState.recording;
    // final isStopped = state == RecState.stopped;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(isRecording ? 'RECORDING...' : 'READY'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 316,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/record_screen.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  controller: _scroll,
                  itemCount: _controller.lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final isCurrent = i == _controller.index;
                    final isPast = i < _controller.index;
                    final style = isCurrent
                        ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)
                        : isPast
                        ? const TextStyle(fontSize: 14, color: Colors.black54)
                        : const TextStyle(fontSize: 14, color: Colors.black26);
                    return SizedBox(
                      height: _rowHeight,
                      child: Center(
                        child: Text(
                          _controller.lines[i],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: style,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Slider(
                    min: 0,
                    max: _aDur.inMilliseconds.toDouble().clamp(0, double.infinity),
                    value: _aPos.inMilliseconds.clamp(0, _aDur.inMilliseconds).toDouble(),
                    onChanged: (v) async {
                      await _player.seek(Duration(milliseconds: v.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_aPos.inSeconds}s'),
                      Text('${_aDur.inSeconds}s'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.stop_rounded),
                  iconSize: 36,
                  color: Colors.black87,
                  onPressed: _handleStop,
                  tooltip: '종료',
                ),
                IconButton(
                  icon: const Icon(Icons.pause_rounded),
                  iconSize: 36,
                  color: Colors.black87,
                  onPressed: isRecording ? _handlePause : null,
                  tooltip: '중지',

                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  iconSize: 40,
                  color: Colors.black87,
                  onPressed: isRecording ? null : _handlePlay,
                  tooltip: '실행',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
