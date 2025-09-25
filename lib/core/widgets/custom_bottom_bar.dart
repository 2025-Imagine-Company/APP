import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
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
              IconButton(
                icon: Icon(
                    Icons.home_filled,
                    color: currentRoute == '/recordHome' ? Color(0xFFFF2424) : Colors.black,
                    size: 24
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/recordHome');
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.mic,
                  color: currentRoute == '/recordWarning' ? Color(0xFFFF2424) : Colors.black,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/recordWarning');
                },
              ),
              IconButton(
                iconSize: 24, // 아이콘 자체 크기
                padding: EdgeInsets.zero, // 패딩 제거
                constraints: BoxConstraints(), // 크기 제한 제거
                icon: CircleAvatar(
                  radius: 14,
                  backgroundColor: currentRoute == '/myPage' ? Color(0xFFFF2424) : Colors.black,
                  child: const Icon(
                    Icons.currency_bitcoin_outlined,
                    color: Color(0xFFD9D9D9),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/myPage');
                },
              ),
              IconButton(
                icon: Icon(
                    Icons.settings,
                    color: currentRoute == '/' ? Color(0xFFFF2424) : Colors.black,
                    size: 26),
                onPressed: () {
                  Navigator.pushNamed(context, '/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
