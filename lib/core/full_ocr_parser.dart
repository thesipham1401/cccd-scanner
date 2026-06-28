import '../models/cccd_data.dart';
import 'hometown_extractor.dart';
import 'text_utils.dart';

String _valueAfterColon(String line) =>
    line.contains(':') ? line.substring(line.indexOf(':') + 1).trim() : '';

String _findByLabel(List<String> lines, List<String> needles) {
  for (final line in lines) {
    final n = stripVietnameseDiacritics(line);
    if (needles.any(n.contains)) {
      final v = _valueAfterColon(line);
      if (v.isNotEmpty) return v;
    }
  }
  return '';
}

final _twelveDigits = RegExp(r'\d{12}');

String _findCccdNumber(List<String> lines) {
  final labelled = _findByLabel(lines, ['so /', 'so/', 'no:']);
  final m1 = _twelveDigits.firstMatch(labelled);
  if (m1 != null) return m1.group(0)!;
  for (final line in lines) {
    final m = _twelveDigits.firstMatch(line.replaceAll(' ', ''));
    if (m != null) return m.group(0)!;
  }
  return '';
}

CccdData parseFullFront(List<String> lines) {
  return CccdData(
    cccdNumber: _findCccdNumber(lines),
    fullName: _findByLabel(lines, ['ho va ten', 'full name']),
    dateOfBirth: _findByLabel(lines, ['ngay sinh', 'date of birth']),
    gender: _findByLabel(lines, ['gioi tinh', 'sex']),
    permanentAddress: _findByLabel(lines, ['noi thuong tru', 'place of residence']),
    hometown: extractHometown(lines),
  );
}
