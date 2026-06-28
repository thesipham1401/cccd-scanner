import 'package:googleapis/sheets/v4.dart';
import 'auth_service.dart';
import '../models/cccd_data.dart';

const List<String> kHeader = [
  'Số CCCD', 'Số CMND cũ', 'Họ và tên', 'Ngày sinh', 'Giới tính',
  'Địa chỉ thường trú', 'Ngày cấp', 'Quê quán', 'Ngày quét',
];

class SheetsService {
  final AuthService auth;
  final String spreadsheetId;
  final String sheetName;

  SheetsService(this.auth, this.spreadsheetId, {this.sheetName = 'Trang tính1'});

  Future<SheetsApi> _api() async {
    final client = await auth.authedClient();
    if (client == null) {
      throw StateError('Chưa đăng nhập Google');
    }
    return SheetsApi(client);
  }

  Future<void> ensureHeader() async {
    final api = await _api();
    final res = await api.spreadsheets.values
        .get(spreadsheetId, '$sheetName!A1:I1');
    final hasHeader = (res.values?.isNotEmpty ?? false) &&
        (res.values!.first.isNotEmpty);
    if (hasHeader) return;
    await api.spreadsheets.values.update(
      ValueRange(values: [kHeader]),
      spreadsheetId,
      '$sheetName!A1',
      valueInputOption: 'RAW',
    );
  }

  Future<bool> cccdExists(String cccdNumber) async {
    final api = await _api();
    final res = await api.spreadsheets.values
        .get(spreadsheetId, '$sheetName!A2:A');
    final col = res.values ?? [];
    return col.any((row) => row.isNotEmpty && '${row.first}' == cccdNumber);
  }

  Future<void> appendRow(CccdData data, String scanDate) async {
    final api = await _api();
    await api.spreadsheets.values.append(
      ValueRange(values: [data.toSheetRow(scanDate)]),
      spreadsheetId,
      '$sheetName!A1',
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
  }
}
