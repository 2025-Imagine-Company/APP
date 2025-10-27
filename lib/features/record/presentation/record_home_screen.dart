// lib/features/record/presentation/record_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../authentication/presentation/authentication_bloc.dart';
import '../../../../core/widgets/custom_bottom_bar.dart';
import '../../../core/services/permission_service.dart';

class RecordHomeScreen extends StatelessWidget {
  const RecordHomeScreen({super.key, this.nickname});

  final String? nickname;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthenticationBloc>().state;
    final derived = nickname ?? auth.me?.displayName ?? '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(nickname: derived),
              const _HeroImage(imagePath: 'assets/images/record_home.png', width: 300),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                onPressed: () async {
                  final nav = Navigator.of(context);                // await 전에 캡처
                  final ok = await PermissionService().ensureMic();
                  if (ok) {nav.pushNamed('/recordWarning');
                  }else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('마이크 권한이 필요합니다. 설정에서 허용해 주세요.'),
                          action: SnackBarAction(
                            label: '설정',
                            onPressed: () => PermissionService().openSettings(),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('녹음하러 가기'),
              ),
            ),
          ]
        ),
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