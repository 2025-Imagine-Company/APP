import 'package:flutter/material.dart';
import 'features/user_profile/presentation/mypage_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'features/authentication/presentation/login_screen.dart';
import 'features/authentication/presentation/select_wallet_screen.dart';
import 'features/authentication/presentation/connect_wallet_screen.dart';
import 'features/authentication/presentation/connect_success_screen.dart';
import 'features/record/presentation/record_home_screen.dart';
import 'features/record/presentation/record_warning_screen.dart';
import 'features/record/presentation/record_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const AudionApp());
}

class AudionApp extends StatelessWidget {
  const AudionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audion',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE9E9E9), // 전역 배경
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE9E9E9), // 앱바 배경 통일
          elevation: 0,
          foregroundColor: Colors.black,       // 아이콘/텍스트 색
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const RecordHomeScreen(),
        '/splash': (context) => const SplashScreen(),
        '/intro': (context) => const IntroScreen(),
        '/login': (context) => const LoginScreen(),
        '/selectWallet': (context) => const WalletSelectScreen(),
        '/connectWallet': (context) => const WalletConnectingScreen(),
        '/successConnect': (context) => const WalletConnectedScreen(),
        '/recordHome': (context) => const RecordHomeScreen(),
        '/recordWarning': (context) => const RecordWarningScreen(),
        '/recording': (context) => const RecordScreen(),
        '/myPage': (context) => const MypageScreen(),
      },
    );
  }
}
