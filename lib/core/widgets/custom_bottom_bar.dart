import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      width: 351,
      height: 69,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            color: Color(0xFFD9D9D9),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.home_filled, color: Colors.black, size: 24,),
              Icon(Icons.mic, color: Colors.black, size: 26,),
              CircleAvatar(
                  radius: 15,
                  backgroundColor: Color(0xFFFF2424),
                  child: const Icon(Icons.currency_bitcoin_outlined,color: Color(0xFFD9D9D9),)
              ),
              Icon(Icons.settings, color: Colors.black, size: 26,)
            ],
          ),
        ),
      ),
    );
  }
}