// lib/features/voice/presentation/loading_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:app/core/services/http_client.dart';
import 'package:app/core/services/token_provider.dart';
import 'package:app/features/record/data/record_api.dart';

enum ModelStatus { training, done, error, unknown }

ModelStatus parseModelStatus(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'TRAINING':
      return ModelStatus.training;
    case 'DONE':
      return ModelStatus.done;
    case 'ERROR':
      return ModelStatus.error;
    default:
      return ModelStatus.unknown;
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final _api = VoiceApi(HttpClient(SecureTokenProvider()));

  String? _voiceFileId;
  String? _modelId;

  // 폴링 제어
  bool _isPolling = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlow());
  }

  Future<void> _startFlow() async {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    _voiceFileId = args?['voiceFileId'] as String?;
    final modelName = args?['modelName'] as String?;

    if (_voiceFileId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('voiceFileId 누락')));
      Navigator.pop(context);
      return;
    }

    try {
      final created = await _api.createModel(
        voiceFileId: _voiceFileId!,
        modelName: modelName,
      );
      _modelId = (created['modelId'] ?? created['id'])?.toString();
      if (_modelId == null) throw Exception('modelId가 응답에 없습니다.');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('모델 생성 실패: $e')));
      Navigator.pop(context);
      return;
    }

    _pollLoop();
  }

  Future<void> _pollLoop() async {
    await Future.delayed(const Duration(seconds: 5));
    while (mounted && !_done) {
      await _pollOnce();
      if (!mounted || _done) break;
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<void> _pollOnce() async {
    if (_modelId == null || _isPolling || !mounted) return;
    _isPolling = true;
    try {
      final res = await _api.getModel(_modelId!);
      final status = parseModelStatus(res['status'] as String?);

      if (status == ModelStatus.done) {
        _done = true;
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/modelComplete');
      } else if (status == ModelStatus.error) {
        _done = true;
        final msg = (res['errorMessage'] ?? '모델 학습에 실패했습니다.').toString();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code != 404 && code != 500) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상태 확인 실패($code): ${e.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('상태 확인 실패: $e')));
    } finally {
      _isPolling = false;
    }
  }

  @override
  void dispose() {
    _done = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final loaderSize = screenW * 0.8 > 320 ? 320.0 : screenW * 0.8;
    final ringWidth = loaderSize * 0.08;
    final centerIconSize = loaderSize * 0.4;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: loaderSize,
              height: loaderSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _controller,
                    child: CustomPaint(
                      size: Size(loaderSize, loaderSize),
                      painter: _RingPainter(
                        strokeWidth: ringWidth,
                        color: Colors.red,
                        trailColor: Colors.red.shade100,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/graphic_eq.png',
                    width: centerIconSize,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w100,
                  decoration: TextDecoration.none,
                ),
                children: [
                  TextSpan(text: '잠시만 기다려주세요\n'),
                  TextSpan(
                    text: 'AI',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '가 '),
                  TextSpan(
                    text: '녹음된 음성',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '을 학습 중 입니다'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.strokeWidth,
    required this.color,
    required this.trailColor,
  });

  final double strokeWidth;
  final Color color;
  final Color trailColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide / 2) - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final trailPaint = Paint()
      ..color = trailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.1415926535,
      false,
      trailPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      3.1415926535 / 2,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
