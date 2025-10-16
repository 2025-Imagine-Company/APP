// lib/features/voice/presentation/loading_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:dio/dio.dart';

import 'package:app/core/services/http_client.dart';
import 'package:app/core/services/token_provider.dart';
import 'package:app/features/record/data/voice_api.dart';

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

String statusLabel(ModelStatus s) {
  switch (s) {
    case ModelStatus.training:
      return '학습 중 (TRAINING)';
    case ModelStatus.done:
      return '완료 (DONE)';
    case ModelStatus.error:
      return '실패 (ERROR)';
    case ModelStatus.unknown:
      return '알 수 없음';
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
  ModelStatus _status = ModelStatus.unknown;
  bool _creating = false;

  // 폴링 제어
  bool _isPolling = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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

    // 1) 모델 생성(1회)
    try {
      setState(() {
        _creating = true;
        _status = ModelStatus.training; // 생성 시작 → 학습 중으로 표시
      });
      final created = await _api.createModel(
        voiceFileId: _voiceFileId!,
        modelName: modelName,
      );
      _modelId = (created['modelId'] ?? created['id'])?.toString();
      if (_modelId == null) {
        throw Exception('modelId가 응답에 없습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('모델 생성 실패: $e')));
      Navigator.pop(context);
      return;
    } finally {
      if (mounted) setState(() => _creating = false);
    }

    // 2) 5초 간격 폴링 (첫 조회 5초 지연)
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
      if (!mounted) return;
      setState(() => _status = status);

      if (status == ModelStatus.done) {
        _done = true;
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/modelComplete');
      } else if (status == ModelStatus.error) {
        _done = true;
        final msg = (res['errorMessage'] ?? '모델 학습에 실패했습니다.').toString();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context);
      }
      // TRAINING/UNKNOWN → 다음 루프에서 재확인
    } on DioException catch (e) {
      // 서버 준비 중일 때 404/500은 조용히 재시도
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
    _done = true; // 루프 종료
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = _controller.value; // 단순 애니메이션

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 20.0,
              percent: percent,
              progressColor: Colors.red,
              backgroundColor: Colors.red.shade100,
              circularStrokeCap: CircularStrokeCap.butt,
              center: Image.asset('assets/images/graphic_eq.png'),
            ),
            const SizedBox(height: 60),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w100,
                  decoration: TextDecoration.none,
                ),
                children: [
                  TextSpan(text: '잠시만 기다려주세요\n'),
                  TextSpan(text: 'AI', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '가 '),
                  TextSpan(text: '녹음된 음성', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '을 학습 중 입니다'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _creating ? '모델 생성 중...' : '상태: ${statusLabel(_status)}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
