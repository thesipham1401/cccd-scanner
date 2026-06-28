String _stripDiacritics(String s) {
  const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i == -1 ? ch : to[i]);
  }
  return b.toString();
}

bool _isOriginLabel(String line) {
  final n = _stripDiacritics(line);
  return n.contains('que quan') || n.contains('place of origin');
}

bool _isOtherLabel(String line) {
  final n = _stripDiacritics(line);
  return n.contains('noi thuong tru') ||
      n.contains('place of residence') ||
      n.contains('co gia tri') ||
      n.contains('date of expiry');
}

String extractHometown(List<String> lines) {
  for (var i = 0; i < lines.length; i++) {
    if (!_isOriginLabel(lines[i])) continue;
    final after = lines[i].contains(':')
        ? lines[i].substring(lines[i].indexOf(':') + 1).trim()
        : '';
    if (after.isNotEmpty) return after;
    final parts = <String>[];
    for (var j = i + 1; j < lines.length && parts.length < 2; j++) {
      if (_isOtherLabel(lines[j])) break;
      parts.add(lines[j].trim());
    }
    return parts.join(' ').trim();
  }
  return '';
}
