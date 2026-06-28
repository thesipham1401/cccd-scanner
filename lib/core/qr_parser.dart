import '../models/cccd_data.dart';
import 'cccd_validator.dart';
import 'date_utils.dart';

CccdData parseQrFront(String raw) {
  final parts = raw.split('|');
  if (parts.length != 7) {
    throw FormatException('Expected 7 QR fields, got ${parts.length}');
  }
  final cccd = parts[0].trim();
  if (!isValidCccdNumber(cccd)) {
    throw FormatException('Invalid CCCD number: "$cccd"');
  }
  return CccdData(
    cccdNumber: cccd,
    oldIdNumber: parts[1].trim(),
    fullName: parts[2].trim(),
    dateOfBirth: qrDateToDisplay(parts[3].trim()),
    gender: parts[4].trim(),
    permanentAddress: parts[5].trim(),
    issueDate: qrDateToDisplay(parts[6].trim()),
  );
}
