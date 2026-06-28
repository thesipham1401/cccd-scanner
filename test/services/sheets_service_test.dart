import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cccd_scanner/models/cccd_data.dart';
import 'package:cccd_scanner/services/sheets_service.dart';

void main() {
  const data = CccdData(cccdNumber: '012345678901', fullName: 'A');

  SheetsService serviceReturning(Map<String, dynamic> json,
      {int status = 200, void Function(Map<String, dynamic> body)? capture}) {
    final client = MockClient((req) async {
      capture?.call(jsonDecode(req.body) as Map<String, dynamic>);
      return http.Response(jsonEncode(json), status);
    });
    return SheetsService('https://script.example/exec', 'sekret',
        client: client);
  }

  test('appended result is parsed', () async {
    final s = serviceReturning({'result': 'appended'});
    expect(await s.append(data, '28/06/2026'), AppendResult.appended);
  });

  test('duplicate result is parsed', () async {
    final s = serviceReturning({'result': 'duplicate'});
    expect(await s.append(data, '28/06/2026'), AppendResult.duplicate);
  });

  test('sends secret, force and the 9-column row', () async {
    late Map<String, dynamic> sent;
    final s = serviceReturning({'result': 'appended'},
        capture: (b) => sent = b);
    await s.append(data, '28/06/2026', force: true);
    expect(sent['secret'], 'sekret');
    expect(sent['force'], true);
    expect((sent['row'] as List).length, 9);
    expect((sent['row'] as List).first, '012345678901');
  });

  test('throws on non-200', () async {
    final s = serviceReturning({'result': 'appended'}, status: 500);
    expect(() => s.append(data, '28/06/2026'), throwsA(isA<http.ClientException>()));
  });

  test('throws on script error result', () async {
    final s = serviceReturning({'result': 'error', 'message': 'unauthorized'});
    expect(() => s.append(data, '28/06/2026'), throwsStateError);
  });
}
