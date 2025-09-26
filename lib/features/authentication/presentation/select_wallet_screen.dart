import 'package:flutter/material.dart';
import 'package:app/core/services/wallet_kit_service.dart';

// enum WalletProvider { metamask, walletConnect }

class WalletSelectScreen extends StatelessWidget {
  const WalletSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Wallet'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('로그인 할 지갑을 선택 해 주세요',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700
                        ),
                        textAlign: TextAlign.center
                    ),
                    const SizedBox(
                        height: 110
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WalletButton(
                          label: 'MetaMask',
                          assetPath: 'assets/images/metamask_logo.png',
                          onTap: () {
                            WalletKitService.instance.connectAndPersonalSign(
                              context: context,
                              message: 'Login to Audion',
                              onSuccess: () {
                                if (!context.mounted) return;
                                Navigator.pushReplacementNamed(context, '/successConnect');
                              },
                              onFailure: (e) {
                                if (!context.mounted) return;
                                // 실패해도 선택 화면 유지
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('지갑 연결/서명에 실패했습니다. 다시 시도해주세요.')),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(
                            width: 24
                        ),
                        _WalletButton(
                          label: 'WalletConnect',
                          assetPath: 'assets/images/walletconnect_logo.png',
                          onTap: () => Navigator.pushReplacementNamed(context, '/connectWallet'),
                        ),
                      ],
                    ),
                    const SizedBox(
                        height: 150
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
                height: 12
            ),
          ]),
        ),
      ),
    );
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 112, height: 112,
          child: ClipOval( // ← 원 모양으로 자름
            child: Image.asset(
                assetPath,
                fit: BoxFit.cover
            ), // ← 꽉 차게
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
          label,
          style: const TextStyle(
              fontSize: 13
          )
      ),
    ]);
  }
}
