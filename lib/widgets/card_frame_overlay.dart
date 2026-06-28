import 'package:flutter/material.dart';

class CardFrameOverlay extends StatelessWidget {
  final String hint;
  const CardFrameOverlay({super.key, this.hint = 'Đưa thẻ vào trong khung'});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth * 0.85;
      final h = w * 54 / 85.6; // CCCD aspect ratio
      return Stack(children: [
        Center(
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Text(hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  backgroundColor: Colors.black54)),
        ),
      ]);
    });
  }
}
