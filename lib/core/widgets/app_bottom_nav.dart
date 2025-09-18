// lib/core/widgets/app_bottom_nav.dart
import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFE6E6E6); // 바텀바 배경

    final icons = const [
      Icons.home_rounded,
      Icons.mic_rounded,
      Icons.currency_bitcoin_rounded,
      Icons.settings_rounded,
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // ← 하단 공백
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 30,
            width: double.infinity,
            color: bg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(icons.length, (i) {
                final selected = i == currentIndex;
                return IconButton(
                  iconSize: selected ? 28 : 26,
                  onPressed: () => onTap?.call(i),
                  icon: Icon(
                    icons[i],
                    color: selected ? Colors.red : Colors.black54,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
