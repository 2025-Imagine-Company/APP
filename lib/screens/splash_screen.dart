import 'dart:async';
import 'dart:ui' as ui; // ImageFilter.blur
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/intro');
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 왼쪽 상단 배경 이미지
          Positioned(
            top: -40,
            left: -40,
            child: Image.asset(
              'assets/images/bg_top.png', // 교체 경로
              width: 240,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
          // 오른쪽 하단 배경 이미지
          Positioned(
            right: -40,
            bottom: -40,
            child: Image.asset(
              'assets/images/bg_bottom.png', // 교체 경로
              width: 280,
              height: 280,
              fit: BoxFit.cover,
            ),
          ),

          // 전체 블러 + 살짝 화이트 오버레이
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(color: Colors.white.withOpacity(0.35)),
              ),
            ),
          ),

          // 중앙 콘텐츠: 이미지 위, 텍스트 아래
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 중앙 상단 이미지
                Image.asset(
                  'assets/images/hero.png', // 교체 경로
                  width: 112,
                  height: 112,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Audion',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
