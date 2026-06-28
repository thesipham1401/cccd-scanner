import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/models/cccd_data.dart';

void main() {
  test('toSheetRow returns 9 columns in the defined order', () {
    final d = CccdData(
      cccdNumber: '012345678901',
      oldIdNumber: '123456789',
      fullName: 'Nguyễn Văn A',
      dateOfBirth: '01/02/1990',
      gender: 'Nam',
      permanentAddress: 'Hà Nội',
      issueDate: '10/10/2021',
      hometown: 'Nam Định',
    );
    expect(d.toSheetRow('28/06/2026'), [
      '012345678901', '123456789', 'Nguyễn Văn A', '01/02/1990',
      'Nam', 'Hà Nội', '10/10/2021', 'Nam Định', '28/06/2026',
    ]);
  });

  test('copyWith overrides only the given field', () {
    final d = CccdData(fullName: 'A').copyWith(hometown: 'Huế');
    expect(d.fullName, 'A');
    expect(d.hometown, 'Huế');
  });
}
