import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double percent = 0.0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addListener(() {
            setState(() {
              percent = _controller.value;
            });
          })
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              center: Image.asset("assets/images/graphic_eq.png"),
            ),
            SizedBox(height: 60),
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
                  TextSpan(text: "잠시만 기다려주세요\n"), // 일반 글씨
                  TextSpan(
                    text: "AI", // bold로 바꿀 글씨
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "가 "),
                  TextSpan(
                    text: "녹음된 음성", // bold로 바꿀 글씨
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "을 학습 중 입니다"),
                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}
