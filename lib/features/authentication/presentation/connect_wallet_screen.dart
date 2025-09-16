import 'package:flutter/material.dart';

class WalletConnectingScreen extends StatefulWidget {
  const WalletConnectingScreen({super.key});
  @override
  State<WalletConnectingScreen> createState() => _WalletConnectingScreenState();
}

class _WalletConnectingScreenState extends State<WalletConnectingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goConnectSuccess() {
    //테스트용
    Navigator.pushReplacementNamed(context, '/successConnect');
  }

  void _goSelectWallet() {
    // TODO: 진행 중 연결이 있다면 취소 처리
    Navigator.pushReplacementNamed(context, '/selectWallet');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Your Wallet'),
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
                    const Text(
                      '지갑을 연결하는 중입니다...',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 110),
                    RotationTransition(
                      turns: _ctrl,
                      child: Image.asset('assets/images/hourglass.png', width: 200, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      '팝업이 열렸다며 서명 요청을 확인해주세요',
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((s) {
                    if (s.contains(WidgetState.disabled)) return const Color(0xFFEEEEEE);
                    if (s.contains(WidgetState.pressed))  return const Color(0xFFBDBDBD);
                    return Color(0xFFBDBDBD);
                  }),
                  foregroundColor: const WidgetStatePropertyAll(Colors.black87),
                  elevation: const WidgetStatePropertyAll(0),
                  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 22)),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                onPressed: _goConnectSuccess,
                // _goSelectWallet,
                child: const Text('취소'),
              ),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}
