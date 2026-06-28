import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pending_record.dart';

class OfflineQueue {
  static const _key = 'pending_records';

  Future<List<PendingRecord>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PendingRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save(List<PendingRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> enqueue(PendingRecord record) async {
    final items = await all()..add(record);
    await _save(items);
  }

  Future<void> remove(String id) async {
    final items = await all()..removeWhere((e) => e.id == id);
    await _save(items);
  }
}
