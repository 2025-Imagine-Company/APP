import 'package:flutter/material.dart';

class WalletConnectedScreen extends StatelessWidget {
  const WalletConnectedScreen({
    super.key,
    this.bottomImagePath = 'assets/images/red_block.png', // <- 너가 넣을 경로
    this.bottomImageHeight = 120,
  });

  final String bottomImagePath;
  final double bottomImageHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '지갑 연결 완료!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                bottomImagePath,
                width: double.infinity,
                height: bottomImageHeight,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
