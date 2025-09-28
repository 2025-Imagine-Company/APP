import 'package:app/features/user_profile/presentation/minting_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'features/record/presentation/loading_screen.dart';
import 'features/record/presentation/model_complete_screen.dart';
import 'core/themes/theme.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const AudionApp());
}

class AudionApp extends StatelessWidget {
  const AudionApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audion',
      theme: appTheme,
      initialRoute: '/splash',
      routes: {
        '/': (context) => const MintingScreen(),
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
        '/loading': (context) => const LoadingScreen(),
        '/modelComplete': (context) => const ModelCompleteScreen(),
        '/minting': (context) => const MintingScreen(),
      },
    );
  }
}
