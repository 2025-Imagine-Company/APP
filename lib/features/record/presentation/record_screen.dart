// lib/features/record/presentation/record_screen.dart
import 'dart:async';
import 'dart:io' show Directory, File; // 네이티브만 사용
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:app/core/services/http_client.dart';
import 'package:app/core/services/token_provider.dart';
import 'package:app/features/record/data/record_api.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    this.lines = _mockLines,
    this.interval = const Duration(seconds: 2),
    this.autoplay = false,
  });

  final List<String> lines;
  final Duration interval;
  final bool autoplay;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

enum _RecState { stopped, recording, paused }

class _RecordScreenState extends State<RecordScreen> {
  final _scroll = ScrollController();
  Timer? _timer;
  int _idx = 0;
  _RecState _state = _RecState.stopped;
  static const _rowHeight = 24.0;

  final AudioRecorder _rec = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  // 네이티브 결과
  String? _lastPath;

  // 웹 결과(메모리 WAV)
  StreamSubscription<Uint8List>? _webStreamSub;
  final List<int> _webPcm = [];
  Uint8List? _lastBytes;
  String? _lastFileName;

  // 플레이어
  bool _isPlaying = false;
  Duration _dur = Duration.zero;
  Duration _pos = Duration.zero;

  // 업로드 상태
  bool _isUploading = false;
  String? _uploadedFileId;

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

  // ===== 스크립트 & 녹음 제어 =====
  Future<void> _start() async {
    if (!kIsWeb) {
      final ok = await Permission.microphone.request().isGranted;
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이크 권한이 필요합니다.')),
        );
        return;
      }
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
    await _pauseRec();
  }

  Future<void> _stop() async {
    setState(() {
      _state = _RecState.stopped;
      _idx = 0;
    });
    _timer?.cancel();
    _scrollToCurrent();

    final saved = await _stopRec();
    if (!mounted) return;

    final ok = kIsWeb ? (_lastBytes != null) : (saved != null);
    if (ok) {
      final filename = _lastFileName ?? (saved?.split('/').last ?? 'voice');
      final len = kIsWeb ? _lastBytes!.length : (await File(saved!).length());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장됨: $filename (${len}B)')),
      );
      if (kIsWeb) {
        await _player.stop();
        await _player.setSource(BytesSource(_lastBytes!));
      } else {
        await _player.setSourceDeviceFile(saved!);
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('저장 실패')));
    }
  }

  Future<void> _softFinish() async {
    setState(() => _state = _RecState.paused);
    _timer?.cancel();
    await _pauseRec();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('스크립트 완료 ⏹=저장, ▶=이어하기')),
    );
  }

  // 1) 공용 확인 다이얼로그 헬퍼
  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true, // 루트 네비게이터에 띄우기
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _tick(Timer _) {
    if (!mounted || _state != _RecState.recording) return;
    if (_idx < widget.lines.length - 1) {
      setState(() => _idx++);
      _scrollToCurrent();
    } else {
      _softFinish();
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

  // ===== record 녹음 =====
  Future<void> _startRec() async {
    if (kIsWeb) {
      _webPcm.clear();
      _lastBytes = null;
      _lastFileName = null;

      final stream = await _rec.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );
      _webStreamSub?.cancel();
      _webStreamSub = stream.listen((chunk) => _webPcm.addAll(chunk));

      setState(() {
        _lastPath = null;
      });
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${dir.path}/recordings');
    if (!await recDir.exists()) await recDir.create(recursive: true);

    final base = '${recDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}';
    final aacOk = await _rec.isEncoderSupported(AudioEncoder.aacLc);

    final cfg = aacOk
        ? RecordConfig(
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
      _lastPath = path;
    });
  }

  Future<void> _pauseRec() async {
    if (await _rec.isRecording()) {
      await _rec.pause();
    }
  }

  Future<void> _resumeRec() async {
    if (await _rec.isPaused()) {
      await _rec.resume();
    } else if (!await _rec.isRecording()) {
      await _startRec();
    }
  }

  Future<String?> _stopRec() async {
    if (kIsWeb) {
      await _webStreamSub?.cancel();
      await _rec.stop();

      final wav = _buildWav(
        pcm: Uint8List.fromList(_webPcm),
        sampleRate: 44100,
        channels: 1,
        bitsPerSample: 16,
      );
      _lastBytes = wav;
      _lastFileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.wav';

      setState(() {
        _lastPath = null;
      });
      return null;
    }

    if (!await _rec.isRecording() && !await _rec.isPaused()) return _lastPath;
    final path = await _rec.stop();
    _lastPath = path ?? _lastPath;
    return _lastPath;
  }

  // ===== 재생 =====
  Future<void> _togglePlayLast() async {
    if (kIsWeb) {
      if (_lastBytes == null) return;
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play(BytesSource(_lastBytes!));
      }
      return;
    }
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

  // ===== 업로드 & 확인 & 모델 생성 확인 =====
  Future<void> _onUploadFlow() async {
    // 업로드 확인 다이얼로그
    final ok = await _confirm(
      title: '업로드',
      message: '녹음 파일을 서버로 업로드하시겠습니까?',
    );
    if (!ok) return;

    // 업로드 실행
    setState(() => _isUploading = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('업로드 중...')));
    try {
      final api = VoiceApi(HttpClient(SecureTokenProvider()));
      final duration = _dur == Duration.zero ? null : _dur.inMilliseconds / 1000.0;

      Map<String, dynamic> resp;
      if (kIsWeb) {
        if (_lastBytes == null) throw Exception('업로드할 바이트가 없습니다.');
        resp = await api.uploadBytes(
          bytes: _lastBytes!,
          filename: _lastFileName ?? 'voice.wav',
          durationSec: duration,
        );
      } else {
        if (_lastPath == null) throw Exception('업로드할 파일 경로가 없습니다.');
        resp = await api.upload(file: File(_lastPath!), durationSec: duration);
      }

      final fileId = resp['fileId'] as String?;
      _uploadedFileId = fileId;

      if (fileId == null) {
        throw Exception('fileId가 응답에 없습니다.');
      }

      // 업로드 직후 확인 호출
      final detail = await VoiceApi(HttpClient(SecureTokenProvider())).getFile(fileId);
      final status = (detail['status'] ?? 'UNKNOWN').toString();
      final fname = (detail['filename'] ?? _lastFileName ?? 'voice').toString();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 확인: $fname ($status)')),
      );

      // 모델 생성 확인
      final goModel = await _confirm(
        title: '모델 생성',
        message: '업로드가 완료되었습니다. 모델을 생성하시겠습니까?',
      );
      // "모델 생성하시겠습니까?" 확인 시
      if (goModel == true && mounted) {
        if (_uploadedFileId == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('fileId 없음')));
          return;
        }
        Navigator.pushNamed(
          context,
          '/loading',
          arguments: {
            'voiceFileId': _uploadedFileId,     // ★ 필수
            // 선택: 모델 이름을 미리 정하고 싶으면 넣기
            'modelName': 'My Voice',
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ===== WAV 유틸(웹) =====
  Uint8List _buildWav({
    required Uint8List pcm,
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcm.length;
    final totalSize = 36 + dataSize;

    final header = BytesBuilder();
    header.add([0x52, 0x49, 0x46, 0x46]); // RIFF
    header.add(_le32(totalSize));
    header.add([0x57, 0x41, 0x56, 0x45]); // WAVE
    header.add([0x66, 0x6d, 0x74, 0x20]); // fmt
    header.add(_le32(16)); // PCM
    header.add(_le16(1)); // PCM format
    header.add(_le16(channels));
    header.add(_le32(sampleRate));
    header.add(_le32(byteRate));
    header.add(_le16(blockAlign));
    header.add(_le16(bitsPerSample));
    header.add([0x64, 0x61, 0x74, 0x61]); // data
    header.add(_le32(dataSize));

    return Uint8List.fromList([...header.toBytes(), ...pcm]);
  }

  List<int> _le16(int v) => [v & 0xff, (v >> 8) & 0xff];
  List<int> _le32(int v) =>
      [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    _player.dispose();
    _webStreamSub?.cancel();
    _rec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _state == _RecState.recording;
    final isStopped = _state == _RecState.stopped;
    final hasResult = kIsWeb ? _lastBytes != null : _lastPath != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(isRecording ? 'RECORDING...' : 'RECORD PAGE'),
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
                        ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)
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

            if (hasResult) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
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
                        value: _pos.inMilliseconds.clamp(0, _dur.inMilliseconds).toDouble(),
                        onChanged: (v) => _seekLast(v),
                      ),
                    ),
                    Text('${_pos.inSeconds}/${_dur.inSeconds}s', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.stop_rounded),
                  iconSize: 36,
                  color: Colors.black87,
                  onPressed: _stop,
                  tooltip: '종료',
                ),
                IconButton(
                  icon: const Icon(Icons.pause_rounded),
                  iconSize: 36,
                  color: Colors.black87,
                  onPressed: isRecording ? _pause : null,
                  tooltip: '중지',
                ),
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

            // 업로드 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isStopped && hasResult && !_isUploading) ? _onUploadFlow : null,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(_isUploading ? '업로드 중...' : '업로드'),
              ),
            ),
            const SizedBox(height: 8),
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
