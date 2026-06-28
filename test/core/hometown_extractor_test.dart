import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/core/hometown_extractor.dart';

void main() {
  test('value on same line after colon', () {
    final lines = [
      'Giới tính / Sex: Nam',
      'Quê quán / Place of origin: Nam Định',
      'Nơi thường trú / Place of residence: Hà Nội',
    ];
    expect(extractHometown(lines), 'Nam Định');
  });

  test('value wraps to next line', () {
    final lines = [
      'Quê quán / Place of origin:',
      'Xã X, Huyện Y,',
      'Tỉnh Nam Định',
      'Nơi thường trú / Place of residence: Hà Nội',
    ];
    expect(extractHometown(lines), 'Xã X, Huyện Y, Tỉnh Nam Định');
  });

  test('returns empty when not present', () {
    expect(extractHometown(['Họ và tên: A']), '');
  });
}
