import 'package:flutter/material.dart';
import 'features/user_profile/presentation/mypage_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'features/authentication/presentation/login_screen.dart';
import 'features/authentication/presentation/select_wallet_screen.dart';
import 'features/authentication/presentation/connect_wallet_screen.dart';
import 'features/authentication/presentation/connect_success_screen.dart';
// import 'features/record/presentation/record_screen.dart'

void main() {
  runApp(const AudionApp());
}

class AudionApp extends StatelessWidget {
  const AudionApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audion',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE9E9E9), // 전역 배경
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MypageScreen(),
        '/intro': (context) => const IntroScreen(),
        '/login': (context) => const LoginScreen(),
        '/selectWallet': (context) => const WalletSelectScreen(),
        '/connectWallet': (context) => const WalletConnectingScreen(),
        '/successConnect': (context) => const WalletConnectedScreen(),
        // '/record': (context) => const RecordScreen(),
        '/myPage': (context) => const MypageScreen(),
      },
    );
  }
}
