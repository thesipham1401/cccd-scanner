import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/core/date_utils.dart';

void main() {
  test('converts ddMMyyyy to dd/MM/yyyy', () {
    expect(qrDateToDisplay('01021990'), '01/02/1990');
    expect(qrDateToDisplay('31122000'), '31/12/2000');
  });

  test('empty stays empty', () {
    expect(qrDateToDisplay(''), '');
  });

  test('throws on malformed length', () {
    expect(() => qrDateToDisplay('1234'), throwsFormatException);
    expect(() => qrDateToDisplay('0102199'), throwsFormatException);
  });
}
