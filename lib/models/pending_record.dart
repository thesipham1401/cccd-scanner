import 'cccd_data.dart';

class PendingRecord {
  final String id;
  final String scanDate;
  final CccdData data;

  PendingRecord({required this.scanDate, required this.data, String? id})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'scanDate': scanDate,
        'data': data.toJson(),
      };

  factory PendingRecord.fromJson(Map<String, dynamic> j) => PendingRecord(
        id: j['id'],
        scanDate: j['scanDate'],
        data: CccdData.fromJson(Map<String, dynamic>.from(j['data'])),
      );
}
