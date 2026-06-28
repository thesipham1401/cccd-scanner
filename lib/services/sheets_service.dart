import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cccd_data.dart';

/// Outcome of trying to append a row to the sheet via the Apps Script Web App.
enum AppendResult { appended, duplicate }

/// Sends rows to a Google Apps Script Web App bound to the shared Sheet.
/// No Google Sign-In / Google Cloud needed: the script (running as the sheet
/// owner) does the writing; a shared [secret] guards the endpoint.
class SheetsService {
  final String scriptUrl;
  final String secret;
  final http.Client _client;

  SheetsService(this.scriptUrl, this.secret, {http.Client? client})
      : _client = client ?? http.Client();

  /// Appends one row. With [force] false the script rejects a duplicate Số CCCD
  /// (returns [AppendResult.duplicate]); call again with [force] true to add it
  /// anyway. Throws on network/HTTP/script errors so callers can queue offline.
  Future<AppendResult> append(
    CccdData data,
    String scanDate, {
    bool force = false,
  }) async {
    final resp = await _client.post(
      Uri.parse(scriptUrl),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': secret,
        'force': force,
        'row': data.toSheetRow(scanDate),
      }),
    );
    if (resp.statusCode != 200) {
      throw http.ClientException('HTTP ${resp.statusCode}', Uri.parse(scriptUrl));
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    switch (body['result']) {
      case 'appended':
        return AppendResult.appended;
      case 'duplicate':
        return AppendResult.duplicate;
      default:
        throw StateError('Script error: ${body['message'] ?? body['result']}');
    }
  }
}
