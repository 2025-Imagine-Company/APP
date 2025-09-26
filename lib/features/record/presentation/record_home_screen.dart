// lib/features/record/presentation/record_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../authentication/presentation/authentication_bloc.dart';
import '../../../../core/widgets/earning_box.dart';
import '../../../../core/widgets/custom_bottom_bar.dart';

class RecordHomeScreen extends StatelessWidget {
  const RecordHomeScreen({super.key, this.nickname});

  final String? nickname;

  static const _fallbackMockNickname = 'Sally';
  static const _mock = [
    {'title': 'case1_low_girl','amount': 232234,'rate': 2.8,'image': 'assets/images/earning_mock1.png'},
    {'title': '어린아이 목소리 v.2','amount': 232234,'rate': 2.8,'image': 'assets/images/earning_mock2.png'},
  ];

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthenticationBloc>().state;

    // 1) 명시 전달 > 2) 서버 닉네임 > 3) 지갑주소 축약 > 4) mock
    final derived =
        nickname ??
            _nickFromAuth(authState) ??
            _shortAddr(authState.me?.nickname) ??
            _fallbackMockNickname;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(nickname: derived),
              const _HeroImage(imagePath: 'assets/images/record_home.png', width: 300),
              _EarningsSection(items: _mock),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(),
    );
  }

  String? _nickFromAuth(AuthState s) {
    // 서버가 닉네임을 제공한다면 여기에 매핑
    // 예: return s.me?.nickname;
    return null;
  }

  String? _shortAddr(String? addr) {
    if (addr == null || addr.length < 10) return addr;
    final a = addr.toLowerCase();
    return '${a.substring(0, 6)}...${a.substring(a.length - 4)}';
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        const Text('home', style: TextStyle(color: Colors.black45, fontSize: 20)),
        Text('안녕하세요,\n$nickname님!',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pushNamed(context, '/recordWarning'),
            child: const Text('녹음하러 가기'),
          ),
        ),
      ]),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imagePath, this.width = 300});

  final String imagePath;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: width,
        child: Image.asset(imagePath, fit: BoxFit.contain),
      ),
    );
  }
}

class _EarningsSection extends StatelessWidget {
  const _EarningsSection({required this.items});

  final List<Map<String, Object>> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 40),
        const Text('오늘의 수익', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 352),
            child: Column(
              children: List.generate(items.length, (i) {
                final m = items[i];
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: i == items.length - 1 ? 0 : 12),
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
      ]),
    );
  }
}
