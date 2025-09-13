import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'features/authentication/presentation/login_screen.dart';
import 'features/authentication/presentation/select_wallet_screen.dart';
// import 'features/record/presentation/record_screen.dart'

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
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/intro': (context) => const IntroScreen(),
        '/login': (context) => const LoginScreen(),
        '/selectWallet': (context) => const WalletSelectScreen(),

        // '/record': (context) => const RecordScreen(),
      },
    );
  }
}
