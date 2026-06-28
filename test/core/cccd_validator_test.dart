import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/core/cccd_validator.dart';

void main() {
  test('accepts 12 digits', () {
    expect(isValidCccdNumber('012345678901'), isTrue);
  });
  test('rejects wrong length', () {
    expect(isValidCccdNumber('12345'), isFalse);
    expect(isValidCccdNumber('0123456789012'), isFalse);
  });
  test('rejects non-digits', () {
    expect(isValidCccdNumber('01234567890a'), isFalse);
    expect(isValidCccdNumber(''), isFalse);
  });
}
