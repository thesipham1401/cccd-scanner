import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_queue.dart';
import 'sheets_service.dart';

class SyncService {
  final OfflineQueue queue;
  final SheetsService sheets;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  SyncService(this.queue, this.sheets);

  Future<bool> _online() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Flushes queued records to the sheet while online. Stops at the first
  /// failure so the rest stay queued for the next attempt. Returns the count
  /// successfully appended.
  Future<int> flush() async {
    if (!await _online()) return 0;
    final pending = await queue.all();
    var count = 0;
    for (final r in pending) {
      try {
        await sheets.appendRow(r.data, r.scanDate);
        await queue.remove(r.id);
        count++;
      } catch (_) {
        break;
      }
    }
    return count;
  }

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) flush();
    });
  }

  void dispose() => _sub?.cancel();
}
