// lib/features/record/presentation/record_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    this.lines = _mockLines,
    this.interval = const Duration(seconds: 2),
    this.autoplay = false, // 입장 시 자동 시작 OFF
  });

  final List<String> lines;
  final Duration interval;
  final bool autoplay;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

enum _RecState { stopped, recording, paused }

class _RecordScreenState extends State<RecordScreen> {
  // ===== 스크립트 진행 =====
  final _scroll = ScrollController();
  Timer? _timer;
  int _idx = 0;
  _RecState _state = _RecState.stopped;
  static const _rowHeight = 24.0;

  // ===== 녹음/재생 =====
  final AudioRecorder _rec = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRec = false;
  String? _lastPath;

  // 미니 플레이어 상태
  bool _isPlaying = false;
  Duration _dur = Duration.zero;
  Duration _pos = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.autoplay) _start();

    _player.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) {
      setState(() => _dur = d);
    });
    _player.onPositionChanged.listen((p) {
      setState(() => _pos = p);
    });
  }

  // ---------------- 스크립트 & 녹음 제어 ----------------
  Future<void> _start() async {
    final granted = await Permission.microphone.request().isGranted;
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('마이크 권한이 필요합니다.')));
      return;
    }

    _timer?.cancel();
    setState(() => _state = _RecState.recording);
    _timer = Timer.periodic(widget.interval, _tick);

    await _startRec();
  }

  Future<void> _resume() async {
    _timer?.cancel();
    setState(() => _state = _RecState.recording);
    _timer = Timer.periodic(widget.interval, _tick);

    await _resumeRec();
  }

  Future<void> _pause() async {
    setState(() => _state = _RecState.paused);
    _timer?.cancel();
    await _pauseRec(); // 저장 없음
  }

  Future<void> _stop() async {
    // 스크립트 정지 + 처음으로
    setState(() {
      _state = _RecState.stopped;
      _idx = 0;
    });
    _timer?.cancel();
    _scrollToCurrent();

    // 녹음 종료 + 저장 확인
    final saved = await _stopRec();
    if (!mounted) return;
    if (saved != null) {
      final f = File(saved);
      final ok = await f.exists();
      final len = ok ? await f.length() : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장됨: ${saved.split('/').last} (${len}B)')),
      );
      await _player.setSourceDeviceFile(saved); // 재생 준비
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('저장 실패')));
    }
  }

  Future<void> _softFinish() async {
    setState(() => _state = _RecState.paused);
    _timer?.cancel();
    await _pauseRec(); // 저장하지 않음
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('스크립트 완료 ⏹=저장, ▶=이어하기')),
    );
  }

  void _tick(Timer _) {
    if (!mounted || _state != _RecState.recording) return;

    if (_idx < widget.lines.length - 1) {
      setState(() => _idx++);
      _scrollToCurrent();
    } else {
      _softFinish(); // 자동 저장 금지
    }
  }

  void _scrollToCurrent() {
    final target = (_idx * _rowHeight) - 100;
    final max = _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
    _scroll.animateTo(
      target.clamp(0, max),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ---------------- record 패키지로 녹음 ----------------
  Future<void> _startRec() async {
    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${dir.path}/recordings');
    if (!await recDir.exists()) await recDir.create(recursive: true);

    final base = '${recDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}';

    // 코덱 지원 확인 후 AAC → WAV 폴백
    final aacOk = await _rec.isEncoderSupported(AudioEncoder.aacLc);
    final cfg = aacOk
        ? const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 1,
    )
        : const RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    );
    final path = aacOk ? '$base.m4a' : '$base.wav';

    await _rec.start(cfg, path: path);

    setState(() {
      _isRec = true;
      _lastPath = path;
    });
  }

  Future<void> _pauseRec() async {
    if (await _rec.isRecording()) {
      await _rec.pause();
      if (mounted) setState(() => _isRec = false);
    }
  }

  Future<void> _resumeRec() async {
    if (await _rec.isPaused()) {
      await _rec.resume();
      setState(() => _isRec = true);
    } else if (!await _rec.isRecording()) {
      await _startRec();
    }
  }

  /// 녹음 종료 후 최종 파일 경로 반환
  Future<String?> _stopRec() async {
    if (!await _rec.isRecording() && !await _rec.isPaused()) return _lastPath;
    final path = await _rec.stop();
    setState(() => _isRec = false);
    _lastPath = path ?? _lastPath;
    return _lastPath;
  }

  // 최근 저장 파일 재생 토글
  Future<void> _togglePlayLast() async {
    if (_lastPath == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(_lastPath!));
    }
  }

  Future<void> _seekLast(double millis) async {
    await _player.seek(Duration(milliseconds: millis.toInt()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    _player.dispose();
    _rec.dispose();
    super.dispose();
  }

  // 업로드 화면으로 이동
  Future<void> _goUpload() async {
    if (_lastPath == null) return;
    // 재생 중이면 정지
    if (_isPlaying) await _player.stop();

    final durSec = _dur == Duration.zero ? null : _dur.inMilliseconds / 1000.0;

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/loading',
      arguments: {
        'path': _lastPath!,   // 파일 절대경로
        'duration': durSec,   // (nullable) 초 단위
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _state == _RecState.recording;
    final isStopped = _state == _RecState.stopped;

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
                  itemCount: widget.lines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final isCurrent = i == _idx;
                    final isPast = i < _idx;
                    final style = isCurrent
                        ? const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    )
                        : isPast
                        ? const TextStyle(fontSize: 14, color: Colors.black54)
                        : const TextStyle(fontSize: 14, color: Colors.black26);
                    return SizedBox(
                      height: _rowHeight,
                      child: Center(
                        child: Text(
                          widget.lines[i],
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

            // 미니 플레이어 (파일 있을 때만 표시)
            if (_lastPath != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: _isPlaying ? '일시정지' : '재생',
                          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                          iconSize: 36,
                          onPressed: _togglePlayLast,
                        ),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: _dur.inMilliseconds.toDouble().clamp(0, double.infinity),
                            value: _pos.inMilliseconds
                                .clamp(0, _dur.inMilliseconds)
                                .toDouble(),
                            onChanged: (v) => _seekLast(v),
                          ),
                        ),
                        Text(
                          '${_pos.inSeconds}/${_dur.inSeconds}s',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ⏹ 종료(스크립트 초기화 + 파일 저장 확인)
                IconButton(
                  icon: const Icon(Icons.stop_rounded),
                  iconSize: 36,
                  color: Colors.black87,
                  onPressed: _stop,
                  tooltip: '종료',
                ),
                // ⏸ 중지(스크립트/녹음 일시정지)
                IconButton(
                  icon: const Icon(Icons.pause_rounded),
                  iconSize: 36,
                  color: Colors.black87,
                  onPressed: isRecording ? _pause : null,
                  tooltip: '중지',
                ),
                // ▶ 실행(처음)/재개
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  iconSize: 40,
                  color: Colors.black87,
                  onPressed: isRecording ? null : (isStopped ? _start : _resume),
                  tooltip: '실행',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ▼ 업로드 버튼 (정지 상태 & 파일 있을 때 활성화)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isStopped && _lastPath != null ? _goUpload : null,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('업로드'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 데모 문장
const _mockLines = <String>[
  '마이크 테스트를 시작합니다.',
  '지금은 예시 문장입니다.',
  '녹음과 자막 싱크를 확인하세요.',
  '일시정지 후 재개도 점검합니다.',
  '마지막 줄입니다.',
];
