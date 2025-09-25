import 'package:flutter/material.dart';

class ModelCompleteScreen extends StatefulWidget {
  const ModelCompleteScreen({super.key});

  @override
  State<ModelCompleteScreen> createState() => _ModelCompleteScreenState();
}

class _ModelCompleteScreenState extends State<ModelCompleteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/images/complete_icon.png"),
            SizedBox(height: 30),
            Text(
              "모델 생성 완료!",
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 50),
            Image.asset("assets/images/audion_logo_2.png"),
            SizedBox(height: 40),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFD8D8D8),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                fixedSize: Size(256, 44),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/myPage');
              },
              child: Text(
                "모델 테스트 하기",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFD8D8D8),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                fixedSize: Size(256, 44),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/myPage');
              },
              child: Text("판매 등록하러 가기", style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 10),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFD8D8D8),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                fixedSize: Size(256, 44),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/myPage');
              },
              child: Text("내 라이브러리", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
