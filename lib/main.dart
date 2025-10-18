// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// theme
import 'core/themes/theme.dart';

// API 통신
import 'core/services/http_client.dart';
import 'core/services/token_provider.dart';
import 'core/services/http_client.dart' show HttpClient;
import 'features/authentication/data/auth_api.dart';
import 'features/authentication/data/auth_repository.dart';
import 'features/authentication/presentation/authentication_bloc.dart';

// 각 페이지
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
import 'features/user_profile/presentation/minting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenProvider = SecureTokenProvider();

  final prefs = await SharedPreferences.getInstance();
  final firstRun = prefs.getBool('first_run') ?? true;
  if (firstRun) {
    await tokenProvider.clear();           // ← 최초 1회 토큰 삭제
    await prefs.setBool('first_run', false);
  }

  final http = HttpClient(tokenProvider);
  final api  = AuthApi(http.raw);
  final repo = AuthRepository(api: api, tokenSink: _TokenSinkImpl(tokenProvider, http));

  runApp(AudionApp(repo: repo));
}

class AudionApp extends StatelessWidget {
  final AuthRepository repo;
  const AudionApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repo,
      child: BlocProvider(
        create: (_) => AuthenticationBloc(repo),
        child: MaterialApp(
          title: 'Audion',
          theme: appTheme,
          initialRoute: '/',
          routes: {
            '/':            (context) => const SplashScreen(),
            '/splash':      (context) => const SplashScreen(),
            '/intro':       (context) => const IntroScreen(),
            '/login':       (context) => const LoginScreen(),
            '/selectWallet':(context) => const WalletSelectScreen(),
            '/connectWallet':(context) => const WalletConnectingScreen(),
            '/successConnect':(context) => const WalletConnectedScreen(),
            '/recordHome':  (context) => const RecordHomeScreen(),
            '/recordWarning':(context) => const RecordWarningScreen(),
            '/recording':   (context) => const RecordScreen(),
            '/myPage':      (context) => const MypageScreen(),
            '/loading':     (context) => const LoadingScreen(),
            '/modelComplete':(context) => const ModelCompleteScreen(),
            '/minting':     (context) => const MintingScreen(),
          },
        ),
      ),
    );
  }
}

class _TokenSinkImpl implements TokenSink {
  final SecureTokenProvider provider;
  final HttpClient http;
  _TokenSinkImpl(this.provider, this.http);
  @override
  Future<void> clear() async {
    await provider.clear();
    http.setToken(null);
  }
  @override
  Future<void> save(String token) async {
    await provider.save(token);
    http.setToken(token);
  }
}
