// lib/features/record/presentation/recording_text_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    this.lines = _mockLines,
    this.interval = const Duration(seconds: 2),
    this.autoplay = true,
  });

  final List<String> lines;
  final Duration interval;
  final bool autoplay;

  @override
  State<RecordScreen> createState() => _RecordingTextScreenState();
}

enum _RecState { stopped, recording, paused }

class _RecordingTextScreenState extends State<RecordScreen> {
  final _scroll = ScrollController();
  Timer? _timer;
  int _idx = 0;
  _RecState _state = _RecState.stopped;

  @override
  void initState() {
    super.initState();
    if (widget.autoplay) _start();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _state = _RecState.recording);
    _timer = Timer.periodic(widget.interval, _tick);
  }

  void _resume() => _start();

  void _pause() {
    _timer?.cancel();
    setState(() => _state = _RecState.paused);
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _state = _RecState.stopped;
      _idx = 0;
    });
    _scrollToCurrent();
  }

  void _tick(Timer _) {
    if (!mounted) return;
    if (_idx < widget.lines.length - 1) {
      setState(() => _idx++);
      _scrollToCurrent();
    } else {
      _stop();
    }
  }

  void _scrollToCurrent() {
    final target = (_idx * 28.0) - 100;
    final max = _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
    _scroll.animateTo(
      target.clamp(0, max),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _state == _RecState.recording;
    final isStopped   = _state == _RecState.stopped;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('RECORDING...'),
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
                  child: Image.asset('assets/images/record_screen.png', fit: BoxFit.cover),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final isCurrent = i == _idx;
                    final isPast = i < _idx;
                    final style = isCurrent
                        ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)
                        : isPast
                        ? const TextStyle(fontSize: 14, color: Colors.black54)
                        : const TextStyle(fontSize: 14, color: Colors.black26);
                    return Text(
                      widget.lines[i],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: style,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// 네가 교체할 자리. 일단 "..."로 채움.
const _mockLines = <String>[
  "As we're walking on by her soul slides away",
  "But don't look back in anger I heard you say",
  "Take me to the place where you go",
  "Where nobody knows",
  "If it's night or day But please don't put your life in the hands",
  "Of a rock and roll band",
];

class TappableAsset extends StatelessWidget {
  const TappableAsset({
    super.key,
    required this.asset,
    this.height = 45,
    this.onTap,
  });

  final String asset;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Image.asset(asset, height: height, fit: BoxFit.contain),
    );
  }
}
