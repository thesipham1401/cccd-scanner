import 'package:flutter/material.dart';
import '../models/cccd_data.dart';
import '../models/pending_record.dart';
import '../services/sheets_service.dart';
import '../services/offline_queue.dart';

class ReviewScreen extends StatefulWidget {
  final CccdData initial;
  final bool fromFallback;
  final SheetsService sheets;
  final OfflineQueue queue;
  final VoidCallback onSaved;
  const ReviewScreen({
    super.key,
    required this.initial,
    required this.fromFallback,
    required this.sheets,
    required this.queue,
    required this.onSaved,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final Map<String, TextEditingController> _c;
  bool _consent = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _c = {
      'Số CCCD': TextEditingController(text: d.cccdNumber),
      'Số CMND cũ': TextEditingController(text: d.oldIdNumber),
      'Họ và tên': TextEditingController(text: d.fullName),
      'Ngày sinh': TextEditingController(text: d.dateOfBirth),
      'Giới tính': TextEditingController(text: d.gender),
      'Địa chỉ thường trú': TextEditingController(text: d.permanentAddress),
      'Ngày cấp': TextEditingController(text: d.issueDate),
      'Quê quán': TextEditingController(text: d.hometown),
    };
  }

  CccdData _collect() => CccdData(
        cccdNumber: _c['Số CCCD']!.text.trim(),
        oldIdNumber: _c['Số CMND cũ']!.text.trim(),
        fullName: _c['Họ và tên']!.text.trim(),
        dateOfBirth: _c['Ngày sinh']!.text.trim(),
        gender: _c['Giới tính']!.text.trim(),
        permanentAddress: _c['Địa chỉ thường trú']!.text.trim(),
        issueDate: _c['Ngày cấp']!.text.trim(),
        hometown: _c['Quê quán']!.text.trim(),
      );

  String _today() {
    final n = DateTime.now();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(n.day)}/${two(n.month)}/${n.year}';
  }

  Future<void> _save() async {
    final data = _collect();
    final scanDate = _today();
    setState(() => _busy = true);
    try {
      final result = await widget.sheets.append(data, scanDate);
      if (result == AppendResult.duplicate) {
        if (!mounted) return;
        final go = await _confirmDuplicate();
        if (go != true) {
          setState(() => _busy = false);
          return;
        }
        await widget.sheets.append(data, scanDate, force: true);
      }
      _toast('Đã lưu ✅');
      widget.onSaved();
    } catch (_) {
      await widget.queue
          .enqueue(PendingRecord(data: data, scanDate: scanDate));
      _toast('Mất mạng — đã lưu tạm, sẽ tự gửi lại');
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmDuplicate() => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Khách đã tồn tại'),
          content: const Text('Số CCCD này đã có trong bảng. Vẫn lưu thêm?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Bỏ')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Vẫn lưu')),
          ],
        ),
      );

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xem lại thông tin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.fromFallback)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '⚠ Đọc bằng OCR (không có QR) — vui lòng kiểm tra kỹ từng dòng.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          for (final entry in _c.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                    labelText: entry.key,
                    border: const OutlineInputBorder()),
              ),
            ),
          CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: const Text('Khách hàng đồng ý cho thu thập thông tin'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (_consent && !_busy) ? _save : null,
              child: Text(_busy ? 'Đang lưu...' : 'Lưu',
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
