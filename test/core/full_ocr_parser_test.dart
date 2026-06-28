import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/core/full_ocr_parser.dart';

void main() {
  final lines = [
    'CĂN CƯỚC CÔNG DÂN',
    'Số / No: 012345678901',
    'Họ và tên / Full name: NGUYỄN VĂN A',
    'Ngày sinh / Date of birth: 01/02/1990',
    'Giới tính / Sex: Nam',
    'Quê quán / Place of origin: Nam Định',
    'Nơi thường trú / Place of residence: 12 Hà Nội',
  ];

  test('extracts labelled fields', () {
    final d = parseFullFront(lines);
    expect(d.cccdNumber, '012345678901');
    expect(d.fullName, 'NGUYỄN VĂN A');
    expect(d.dateOfBirth, '01/02/1990');
    expect(d.gender, 'Nam');
    expect(d.hometown, 'Nam Định');
    expect(d.permanentAddress, '12 Hà Nội');
  });

  test('missing fields are empty, never throws', () {
    final d = parseFullFront(['random text', 'no labels']);
    expect(d.cccdNumber, '');
    expect(d.fullName, '');
  });

  test('recovers a 12-digit number even without a Số label', () {
    final d = parseFullFront(['ABC 012345678901 XYZ']);
    expect(d.cccdNumber, '012345678901');
  });
}
