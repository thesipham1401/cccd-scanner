import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/core/qr_parser.dart';

void main() {
  const ok =
      '012345678901|123456789|Nguyễn Văn A|01021990|Nam|123 Hà Nội|10102021';

  test('parses all 7 fields and formats dates', () {
    final d = parseQrFront(ok);
    expect(d.cccdNumber, '012345678901');
    expect(d.oldIdNumber, '123456789');
    expect(d.fullName, 'Nguyễn Văn A');
    expect(d.dateOfBirth, '01/02/1990');
    expect(d.gender, 'Nam');
    expect(d.permanentAddress, '123 Hà Nội');
    expect(d.issueDate, '10/10/2021');
    expect(d.hometown, '');
  });

  test('throws when not exactly 7 fields', () {
    expect(() => parseQrFront('a|b|c'), throwsFormatException);
  });

  test('throws when CCCD number is not 12 digits', () {
    const bad = '123|123456789|A|01021990|Nam|HN|10102021';
    expect(() => parseQrFront(bad), throwsFormatException);
  });

  test('tolerates empty old-id field', () {
    const noOld = '012345678901||A|01021990|Nam|HN|10102021';
    expect(parseQrFront(noOld).oldIdNumber, '');
  });
}
