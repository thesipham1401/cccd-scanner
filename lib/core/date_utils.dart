String qrDateToDisplay(String raw) {
  if (raw.isEmpty) return '';
  if (raw.length != 8 || int.tryParse(raw) == null) {
    throw FormatException('Expected ddMMyyyy, got "$raw"');
  }
  final dd = raw.substring(0, 2);
  final mm = raw.substring(2, 4);
  final yyyy = raw.substring(4, 8);
  return '$dd/$mm/$yyyy';
}
