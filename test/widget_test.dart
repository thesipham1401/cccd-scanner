import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/widgets/card_frame_overlay.dart';

void main() {
  testWidgets('CardFrameOverlay renders its hint', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: CardFrameOverlay(hint: 'Đưa thẻ vào trong khung')),
    ));
    expect(find.text('Đưa thẻ vào trong khung'), findsOneWidget);
  });
}
