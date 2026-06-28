import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/models/cccd_data.dart';
import 'package:cccd_scanner/models/pending_record.dart';

void main() {
  test('json round-trip preserves data', () {
    final r = PendingRecord(
      id: 'r1',
      scanDate: '28/06/2026',
      data: const CccdData(cccdNumber: '012345678901', fullName: 'A'),
    );
    final back = PendingRecord.fromJson(r.toJson());
    expect(back.id, 'r1');
    expect(back.scanDate, '28/06/2026');
    expect(back.data.cccdNumber, '012345678901');
    expect(back.data.fullName, 'A');
  });
}
