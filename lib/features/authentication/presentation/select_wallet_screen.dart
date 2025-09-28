import 'package:flutter/material.dart';
import 'package:app/core/services/wallet_kit_service.dart';
import 'package:app/core/services/auth_api.dart';

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
                          onTap: () async {
                            try {
                              final api = AuthApiService();
                              // 1) 주소 확보
                              final address = await WalletKitService.instance.requestAddress();
                              if (address == null) {
                                throw StateError('지갑 주소를 가져오지 못했습니다.');
                              }
                              // 2) 서버에서 nonce 발급
                              final nonce = await api.fetchNonce(address);
                              // 3) nonce로 personal_sign 수행 (연결 포함)
                              await WalletKitService.instance.connectAndPersonalSign(
                                context: context,
                                message: nonce,
                                onSuccess: () async {
                                  try {
                                    final signature = WalletKitService.instance.lastSignature;
                                    if (signature == null) {
                                      throw StateError('서명 결과가 없습니다.');
                                    }
                                    // 4) verify → 토큰 저장
                                    await api.verifyAndIssueToken(address: address, signature: signature);
                                    if (!context.mounted) return;
                                    // 5) 마이페이지로 이동
                                    Navigator.pushReplacementNamed(context, '/myPage');
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('로그인 실패: $e')),
                                    );
                                  }
                                },
                                onFailure: (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('지갑 연결/서명에 실패했습니다. 다시 시도해주세요.')),
                                  );
                                },
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('로그인 준비 실패: $e')),
                              );
                            }
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
