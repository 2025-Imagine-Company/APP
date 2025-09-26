import 'package:app/features/user_profile/presentation/minting_screen.dart';
import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:permission_handler/permission_handler.dart';
=======
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/http_client.dart';
import 'core/services/token_provider.dart';
import 'features/authentication/data/auth_api.dart';
import 'features/authentication/data/auth_repository.dart';
import 'features/authentication/presentation/authentication_bloc.dart';
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
import 'features/record/presentation/loading_screen.dart';
import 'features/record/presentation/model_complete_screen.dart';
import 'core/themes/theme.dart';
=======
import 'package:permission_handler/permission_handler.dart';
import 'features/record/presentation/loading_screen.dart';
import 'features/record/presentation/model_complete_screen.dart';
>>>>>>> Stashed changes

void main() {
  final tokenProvider = SecureTokenProvider();
  final http = HttpClient(tokenProvider);
  final api = AuthApi(http.raw);
  final repo = AuthRepository(api: api, tokenSink: _TokenSinkImpl(tokenProvider));
  runApp(AudionApp(repo: repo));
}

class AudionApp extends StatelessWidget {
  final AuthRepository repo;
  const AudionApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
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
=======
    return RepositoryProvider.value(
      value: repo,
      child: BlocProvider(
        create: (_) => AuthenticationBloc(repo)..add(const CheckSession()),
        child: MaterialApp(
          title: 'Audion',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFFE9E9E9),
          ),
          initialRoute: '/splash', // 시나리오: Splash → Intro → Login
          routes: {
            '/': (context) => const ModelCompleteScreen(),
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
          },
        ),
      ),
>>>>>>> Stashed changes
    );
  }
}
class _TokenSinkImpl implements TokenSink {
  final SecureTokenProvider provider;
  _TokenSinkImpl(this.provider);
  @override
  Future<void> clear() => provider.clear();
  @override
  Future<void> save(String token) => provider.save(token);
}