import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cccd_scanner/models/cccd_data.dart';
import 'package:cccd_scanner/models/pending_record.dart';
import 'package:cccd_scanner/services/offline_queue.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('enqueue then all returns the record', () async {
    final q = OfflineQueue();
    await q.enqueue(PendingRecord(
      id: 'a', scanDate: '28/06/2026',
      data: const CccdData(cccdNumber: '012345678901'),
    ));
    final items = await q.all();
    expect(items.length, 1);
    expect(items.first.data.cccdNumber, '012345678901');
  });

  test('remove deletes by id', () async {
    final q = OfflineQueue();
    await q.enqueue(PendingRecord(id: 'a', scanDate: 'x', data: const CccdData()));
    await q.enqueue(PendingRecord(id: 'b', scanDate: 'y', data: const CccdData()));
    await q.remove('a');
    final items = await q.all();
    expect(items.map((e) => e.id), ['b']);
  });
}
