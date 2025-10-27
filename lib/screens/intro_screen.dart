import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/Audion.png'),
            SizedBox(height: 20,),
            Image.asset('assets/images/audion_logo_2.png'),
            SizedBox(height: 40,),
            ElevatedButton(
              style: TextButton.styleFrom(
                backgroundColor: Color.fromRGBO(
                  0,
                  0,
                  0,
                  0.005,
                ),
                foregroundColor: Colors.black,
                fixedSize: Size(264, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/selectWallet');
              },
              child: const Text('Click to get start'),
            ),
          ],
        ),
      )
    );
  }
}
