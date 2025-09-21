// lib/core/widgets/earning_box.dart
import 'package:flutter/material.dart';

class EarningBox extends StatelessWidget {
  const EarningBox({
    super.key,
    required this.title,
    required this.amount,          // 예: 232234
    required this.rate,            // 예: 2.8
    required this.imageAsset,      // 예: 'assets/images/earning_mock1.png'
    this.backgroundColor = Colors.black,
    this.onTap,
  });

  final String title;
  final int amount;
  final double rate;
  final String imageAsset;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bright = ThemeData.estimateBrightnessForColor(backgroundColor);
    final primaryText = bright == Brightness.dark ? Colors.white : Colors.black87;
    final subText = bright == Brightness.dark ? Colors.white70 : Colors.black54;
    final chipBg = bright == Brightness.dark ? Colors.white24 : Colors.black12;

    final amountColor = backgroundColor == Colors.red ? Colors.white : const Color(0xFFE53935);



    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(imageAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '+ ${_fmt(amount)} \$',
                          style: TextStyle(color: amountColor, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text('${rate.toStringAsFixed(1)}%', style: TextStyle(color: subText, fontSize: 12)),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: chipBg, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(Icons.chevron_right_rounded, size: 16, color: subText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //오늘의 수익 박스 숫자 ,로 나눠주기
  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }
}
