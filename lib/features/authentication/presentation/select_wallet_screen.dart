import 'package:flutter/material.dart';

enum WalletProvider { metamask, walletConnect }

class WalletSelectScreen extends StatelessWidget {
  const WalletSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
              'Connect Your Wallet'
          )
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
                        height: 28
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WalletButton(
                          label: 'MetaMask',
                          assetPath: 'assets/images/metamask_logo.png',
                          onTap: () => Navigator.pop(context, WalletProvider.metamask)
                        ),
                        const SizedBox(
                            width: 24
                        ),
                        _WalletButton(
                          label: 'WalletConnect',
                          assetPath: 'assets/images/walletconnect_logo.png',
                          onTap: () => Navigator.pop(
                              context,
                              WalletProvider.walletConnect
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
                onPressed: () {},
                child: const Text(
                    '지갑이 없으신가요? 지갑 만들기'
                )
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
