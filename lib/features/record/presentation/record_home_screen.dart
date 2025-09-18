// lib/features/record/presentation/record_home_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/widgets/earning_box.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

class RecordHomeScreen extends StatelessWidget {
  const RecordHomeScreen({
    super.key,
    this.nickname = _mockNickname,
  });

  final String nickname;

  static const _mockNickname = 'Sally';
  static const _mock = [
    {
      'title': 'case1_low_girl',
      'amount': 232234,
      'rate': 2.8,
      'image': 'assets/images/earning_mock1.png',
    },
    {
      'title': '어린아이 목소리 v.2',
      'amount': 232234,
      'rate': 2.8,
      'image': 'assets/images/earning_mock2.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ↑ 상단 영역만 패딩
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text('home', style: TextStyle(color: Colors.black45, fontSize: 20)),
                    Text('안녕하세요,\n$nickname님!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/recordWarning'),
                        child: const Text('녹음하러 가기'),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 300,
                  child: Image.asset('assets/images/record_home.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('오늘의 수익', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Column(
                          children: List.generate(_mock.length, (i) {
                            final m = _mock[i];
                            return Padding(
                              padding: EdgeInsets.only(bottom: i == _mock.length - 1 ? 0 : 12),
                              child: EarningBox(
                                title: m['title'] as String,
                                amount: m['amount'] as int,
                                rate: m['rate'] as double,
                                imageAsset: m['image'] as String,
                                backgroundColor: i.isOdd ? Colors.red : Colors.black,
                                onTap: () {},
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, '/record');
              break;
            case 2:
              Navigator.pushNamed(context, '/earnings');
              break;
            case 3:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
      ),
    );
  }
}
