// lib/features/authentication/presentation/select_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/dev_wallets.dart';
import 'authentication_bloc.dart';

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WalletButton(
                        label: 'MetaMask',
                        assetPath: 'assets/images/metamask_logo.png',
                        onTap: isLoading ? null : () => _pickAndLogin(ctx),
                      ),
                      const SizedBox(width: 24),
                      _WalletButton(
                        label: 'WalletConnect',
                        assetPath: 'assets/images/walletconnect_logo.png',
                        onTap: isLoading ? null : () => _pickAndLogin(ctx),
                      ),
                    ],
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

  Future<void> _pickAndLogin(BuildContext context) async {
    // await 전에 참조 캡처하여 "don't use BuildContext across async gaps" 회피
    final authBloc = context.read<AuthenticationBloc>();

    final wallet = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => const _DevWalletPicker(),
    );

    if (wallet == null) return;
    authBloc.add(LoginWithWallet(wallet.toLowerCase()));
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

class _DevWalletPicker extends StatelessWidget {
  const _DevWalletPicker();

  @override
  Widget build(BuildContext context) {
    final wallets = DevWallets.list;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('개발용 지갑 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: wallets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final w = wallets[i];
                  return ListTile(
                    dense: true,
                    title: Text(w, style: const TextStyle(fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: w));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('주소 복사됨')),
                        );
                      },
                    ),
                    onTap: () => Navigator.pop(context, w),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }
}
