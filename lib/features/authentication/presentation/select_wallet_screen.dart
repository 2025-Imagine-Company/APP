// lib/features/authentication/presentation/select_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'authentication_bloc.dart';
import 'package:app/features/authentication/data/auth_repository.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

class WalletSelectScreen extends StatefulWidget {
  const WalletSelectScreen({super.key});

  @override
  State<WalletSelectScreen> createState() => _WalletSelectScreenState();
}

class _WalletSelectScreenState extends State<WalletSelectScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 이전 로그인 상태/토큰 초기화
    context.read<AuthenticationBloc>().add(const LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Wallet')),
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthState>(
          // 상태가 바뀔 때만 listener 실행
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (ctx, s) {
            if (s.status == AuthStatus.failure) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(s.error ?? '로그인 실패')),
              );
            }
            if (s.status == AuthStatus.authenticated) {
              Navigator.pushNamedAndRemoveUntil(ctx, '/recordHome', (_) => false);
            }
          },
          builder: (ctx, s) {
            final isLoading = s.status == AuthStatus.loading;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '로그인 할 지갑을 선택 해 주세요',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: _WalletButton(
                      label: 'MetaMask',
                      assetPath: 'assets/images/metamask_logo.png',
                      onTap: isLoading ? null : () => _connectAndSign(ctx),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isLoading) const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _connectAndSign(BuildContext context) async {
    final authBloc = context.read<AuthenticationBloc>();
    try {
      final message = 'Sign this message to login';

      // 우선 MetaMask 직접 경로 사용 (웹)
      if (js_util.hasProperty(html.window, 'ethereum')) {
        final eth = js_util.getProperty(html.window, 'ethereum');
        if (eth == null) {
          throw Exception('window.ethereum 개체가 null 입니다. 브라우저/확장 상태를 확인하세요.');
        }
        if (!js_util.hasProperty(eth, 'request')) {
          throw Exception('MetaMask API(request)가 비활성화되어 있습니다. 확장 프로그램 상태를 확인해 주세요.');
        }
        dynamic accountsCall;
        try {
              // requesting accounts
          accountsCall = js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_requestAccounts'})]);
          if (accountsCall == null) {
            throw Exception('[MM-ACCOUNTS] request returned null');
          }
        } catch (e) {
          throw Exception('[MM-ACCOUNTS] request call failed: $e');
        }
        List accounts;
        try {
          accounts = await js_util.promiseToFuture<List>(accountsCall);
        } catch (e) {
          throw Exception('[MM-ACCOUNTS] promiseToFuture failed: $e');
        }
        if (accounts.isEmpty || accounts.first == null) {
          throw Exception('[MM-ACCOUNTS] 지갑 계정을 가져오지 못했습니다.');
        }
        final address = (accounts.first as String).toLowerCase();
        dynamic sig;
        try {
              // personal_sign attempt
          final signCall = js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'personal_sign', 'params': [message, address]})]);
          if (signCall == null) {
            throw Exception('[MM-SIGN] primary request returned null');
          }
          sig = await js_util.promiseToFuture(signCall);
        } catch (e1) {
          try {
                // personal_sign alt order attempt
            final signAltCall = js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'personal_sign', 'params': [address, message]})]);
            if (signAltCall == null) {
              throw Exception('[MM-SIGN] alt request returned null');
            }
            sig = await js_util.promiseToFuture(signAltCall);
          } catch (e2) {
            throw Exception('[MM-SIGN] both orders failed: primary=$e1, alt=$e2');
          }
        }
        final signature = sig is String ? sig : sig.toString();
        if (signature.isEmpty) {
          throw Exception('서명 결과가 비어 있습니다.');
        }
        final repo = context.read<AuthRepository>();
        try {
          await repo.loginWithSignature(walletAddress: address, message: message, signature: signature);
        } catch (e) {
          throw Exception('[API-LOGIN] 호출 실패: $e');
        }
        authBloc.add(const CheckSession());
        return;
      }

      throw Exception('MetaMask 확장이 탐지되지 않았습니다. 데모는 MetaMask 웹 확장 전용입니다.');
    } catch (e, s) {
          // 상세 원인 노출 제거(릴리즈 정리)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 준비 실패: ${e.toString()}')),
      );
    }
  }
}

class _WalletButton extends StatelessWidget {
  const _WalletButton({
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Column(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Opacity(
            opacity: disabled ? 0.5 : 1,
            child: SizedBox(
              width: 112, height: 112,
              child: ClipOval(child: Image.asset(assetPath, fit: BoxFit.cover)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// 개발용 지갑 선택 UI는 데모 실서명으로 대체되어 제거합니다.
