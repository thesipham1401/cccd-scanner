import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/main.dart';

void main() {
  testWidgets('app boots and shows title', (tester) async {
    await tester.pumpWidget(const CccdScannerApp());
    expect(find.text('CCCD Scanner'), findsOneWidget);
  });
}
