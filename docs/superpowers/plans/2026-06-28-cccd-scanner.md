# CCCD Scanner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter mobile app that lets 2–10 staff scan (or import a photo of) a Vietnamese CCCD card, extract the holder's data, and append one row per person to a shared Google Sheet.

**Architecture:** Pure-Dart logic modules (QR parsing, date/validation, OCR field extraction, sheet-row mapping, offline queue) are unit-tested in isolation. Device/cloud integration (camera, ML Kit OCR, Google Sign-In, Sheets API) lives in thin service wrappers behind interfaces so logic stays testable. Three screens (Login → Capture → Review) drive the flow. The primary data source is the front-side QR (7 fields); OCR supplies **Quê quán** and acts as a full-field fallback when the QR can't be read.

**Tech Stack:** Flutter (Dart 3), `mobile_scanner` (QR), `google_mlkit_text_recognition` (OCR), `google_mlkit_document_scanner` (auto-crop), `image_picker` (gallery), `google_sign_in` + `extension_google_sign_in_as_googleapis_auth` + `googleapis` (Sheets v4), `connectivity_plus` (network), `shared_preferences` (offline queue).

## Global Constraints

- Platforms: Android + iOS, single codebase. Android is the priority target for first working build.
- Dart SDK: `>=3.3.0 <4.0.0`. Flutter stable channel.
- **Do NOT persist card images** — only extracted text is stored (legal: NĐ 13/2023/NĐ-CP). `image_picker`/camera temp files must not be uploaded or kept after extraction.
- Google Sheet columns, in exact order: `Số CCCD | Số CMND cũ | Họ và tên | Ngày sinh | Giới tính | Địa chỉ thường trú | Ngày cấp | Quê quán | Ngày quét`.
- QR front-side format: 7 fields separated by `|`: `<Số CCCD>|<Số CMND cũ>|<Họ và tên>|<Ngày sinh ddMMyyyy>|<Giới tính>|<Nơi thường trú>|<Ngày cấp ddMMyyyy>`.
- Dates: QR delivers `ddMMyyyy`; stored/displayed as `dd/MM/yyyy`.
- A valid CCCD number is exactly 12 digits.
- Save screen requires a **consent checkbox** ticked before saving.
- All user-facing copy is Vietnamese.

---

## File Structure

```
lib/
  main.dart                         # App entry, routing, auth gate
  models/
    cccd_data.dart                  # CccdData model + toSheetRow()
    pending_record.dart             # Queued record (CccdData + scanDate) JSON-serializable
  core/
    qr_parser.dart                  # parseQrFront() -> CccdData (pure)
    date_utils.dart                 # qrDateToDisplay() (pure)
    cccd_validator.dart             # isValidCccdNumber() (pure)
    hometown_extractor.dart         # extractHometown(lines) (pure)
    full_ocr_parser.dart            # parseFullFront(lines) -> CccdData (pure)
  services/
    auth_service.dart               # Google Sign-In wrapper
    sheets_service.dart             # ensureHeader/exists/appendRow
    ocr_service.dart                # ML Kit text recognition wrapper
    capture_service.dart            # camera + gallery -> InputImage
    offline_queue.dart              # enqueue/list/remove via SharedPreferences
    sync_service.dart               # flush queue when online
  screens/
    login_screen.dart
    capture_screen.dart
    review_screen.dart
  widgets/
    card_frame_overlay.dart         # rectangle guide overlay
test/
  core/
    qr_parser_test.dart
    date_utils_test.dart
    cccd_validator_test.dart
    hometown_extractor_test.dart
    full_ocr_parser_test.dart
  models/
    cccd_data_test.dart
    pending_record_test.dart
  services/
    offline_queue_test.dart
```

Decomposition: pure logic in `lib/core` + `lib/models` (Tasks 2–9, fully unit-tested). Integration wrappers in `lib/services` (Tasks 10–13). UI in `lib/screens` (Tasks 14–17). Each task ends with an independently testable deliverable.

---

### Task 1: Scaffold project, dependencies, and CccdData model

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `lib/models/cccd_data.dart`
- Test: `test/models/cccd_data_test.dart`

**Interfaces:**
- Produces: `class CccdData` with named fields `cccdNumber, oldIdNumber, fullName, dateOfBirth, gender, permanentAddress, issueDate, hometown` (all `String`, default `''`), a `copyWith(...)`, and `List<String> toSheetRow(String scanDate)` returning the 9 columns in order.

- [ ] **Step 1: Create the Flutter project**

Run:
```bash
cd /d/cccd-scanner
flutter create --org com.cccdscanner --platforms=android,ios --project-name cccd_scanner .
```
Expected: `lib/`, `pubspec.yaml`, `android/`, `ios/` created. (Existing `docs/` and `.claude/` are left untouched.)

- [ ] **Step 2: Add dependencies to `pubspec.yaml`**

Set the `dependencies` block to:
```yaml
environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  mobile_scanner: ^5.2.3
  google_mlkit_text_recognition: ^0.13.1
  google_mlkit_document_scanner: ^0.2.0
  image_picker: ^1.1.2
  google_sign_in: ^6.2.1
  extension_google_sign_in_as_googleapis_auth: ^2.0.12
  googleapis: ^13.2.0
  connectivity_plus: ^6.0.5
  shared_preferences: ^2.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

Run: `flutter pub get`
Expected: "Got dependencies!"

- [ ] **Step 3: Write the failing test for the model**

`test/models/cccd_data_test.dart`:
```dart
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
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/models/cccd_data_test.dart`
Expected: FAIL — `cccd_data.dart` not found / `CccdData` undefined.

- [ ] **Step 5: Implement the model**

`lib/models/cccd_data.dart`:
```dart
class CccdData {
  final String cccdNumber;
  final String oldIdNumber;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String permanentAddress;
  final String issueDate;
  final String hometown;

  const CccdData({
    this.cccdNumber = '',
    this.oldIdNumber = '',
    this.fullName = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.permanentAddress = '',
    this.issueDate = '',
    this.hometown = '',
  });

  CccdData copyWith({
    String? cccdNumber,
    String? oldIdNumber,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? permanentAddress,
    String? issueDate,
    String? hometown,
  }) {
    return CccdData(
      cccdNumber: cccdNumber ?? this.cccdNumber,
      oldIdNumber: oldIdNumber ?? this.oldIdNumber,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      issueDate: issueDate ?? this.issueDate,
      hometown: hometown ?? this.hometown,
    );
  }

  List<String> toSheetRow(String scanDate) => [
        cccdNumber,
        oldIdNumber,
        fullName,
        dateOfBirth,
        gender,
        permanentAddress,
        issueDate,
        hometown,
        scanDate,
      ];

  Map<String, dynamic> toJson() => {
        'cccdNumber': cccdNumber,
        'oldIdNumber': oldIdNumber,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'permanentAddress': permanentAddress,
        'issueDate': issueDate,
        'hometown': hometown,
      };

  factory CccdData.fromJson(Map<String, dynamic> j) => CccdData(
        cccdNumber: j['cccdNumber'] ?? '',
        oldIdNumber: j['oldIdNumber'] ?? '',
        fullName: j['fullName'] ?? '',
        dateOfBirth: j['dateOfBirth'] ?? '',
        gender: j['gender'] ?? '',
        permanentAddress: j['permanentAddress'] ?? '',
        issueDate: j['issueDate'] ?? '',
        hometown: j['hometown'] ?? '',
      );
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/models/cccd_data_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 7: Replace `lib/main.dart` with a minimal placeholder app**

```dart
import 'package:flutter/material.dart';

void main() => runApp(const CccdScannerApp());

class CccdScannerApp extends StatelessWidget {
  const CccdScannerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CCCD Scanner',
      home: Scaffold(body: Center(child: Text('CCCD Scanner'))),
    );
  }
}
```

- [ ] **Step 8: Commit**

```bash
git init
git add -A
git commit -m "feat: scaffold Flutter project, deps, and CccdData model"
```

---

### Task 2: Date conversion util

**Files:**
- Create: `lib/core/date_utils.dart`
- Test: `test/core/date_utils_test.dart`

**Interfaces:**
- Produces: `String qrDateToDisplay(String raw)` — converts `ddMMyyyy` to `dd/MM/yyyy`; returns `''` for empty input; throws `FormatException` if non-empty but not 8 digits.

- [ ] **Step 1: Write the failing test**

`test/core/date_utils_test.dart`:
```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/date_utils_test.dart`
Expected: FAIL — `date_utils.dart` not found.

- [ ] **Step 3: Implement**

`lib/core/date_utils.dart`:
```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/date_utils_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/date_utils.dart test/core/date_utils_test.dart
git commit -m "feat: add QR date to display conversion"
```

---

### Task 3: CCCD number validator

**Files:**
- Create: `lib/core/cccd_validator.dart`
- Test: `test/core/cccd_validator_test.dart`

**Interfaces:**
- Produces: `bool isValidCccdNumber(String s)` — true iff `s` is exactly 12 ASCII digits.

- [ ] **Step 1: Write the failing test**

`test/core/cccd_validator_test.dart`:
```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/cccd_validator_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

`lib/core/cccd_validator.dart`:
```dart
final _twelveDigits = RegExp(r'^\d{12}$');

bool isValidCccdNumber(String s) => _twelveDigits.hasMatch(s);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/cccd_validator_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/cccd_validator.dart test/core/cccd_validator_test.dart
git commit -m "feat: add CCCD number validator"
```

---

### Task 4: QR front-side parser

**Files:**
- Create: `lib/core/qr_parser.dart`
- Test: `test/core/qr_parser_test.dart`

**Interfaces:**
- Consumes: `qrDateToDisplay` (Task 2), `isValidCccdNumber` (Task 3), `CccdData` (Task 1).
- Produces: `CccdData parseQrFront(String raw)` — splits on `|`, expects 7 fields, validates the CCCD number, converts both dates; throws `FormatException` on wrong field count or invalid CCCD number. Maps field 6 (`Nơi thường trú`) into `permanentAddress`. `hometown` is left `''` (comes from OCR).

- [ ] **Step 1: Write the failing test**

`test/core/qr_parser_test.dart`:
```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/qr_parser_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

`lib/core/qr_parser.dart`:
```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/qr_parser_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/qr_parser.dart test/core/qr_parser_test.dart
git commit -m "feat: parse CCCD front-side QR into CccdData"
```

---

### Task 5: Hometown (Quê quán) OCR extractor

**Files:**
- Create: `lib/core/hometown_extractor.dart`
- Test: `test/core/hometown_extractor_test.dart`

**Interfaces:**
- Produces: `String extractHometown(List<String> lines)` — given OCR text lines from the front, returns the **Quê quán / Place of origin** value. Looks for a line containing `Quê quán` (diacritics-insensitive) or `Place of origin`; takes text after the colon on the same line, and if empty, joins the following 1–2 lines until the next known label. Returns `''` if not found.

- [ ] **Step 1: Write the failing test**

`test/core/hometown_extractor_test.dart`:
```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/hometown_extractor_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

`lib/core/hometown_extractor.dart`:
```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/hometown_extractor_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/hometown_extractor.dart test/core/hometown_extractor_test.dart
git commit -m "feat: extract Quê quán from OCR text lines"
```

---

### Task 6: Full front-side OCR fallback parser

**Files:**
- Create: `lib/core/full_ocr_parser.dart`
- Test: `test/core/full_ocr_parser_test.dart`

**Interfaces:**
- Consumes: `CccdData` (Task 1), `extractHometown` (Task 5).
- Produces: `CccdData parseFullFront(List<String> lines)` — best-effort label-based extraction of every front field when the QR can't be read. Any field not found is left `''`. Never throws. Used only as fallback; the Review screen forces manual confirmation afterward.

- [ ] **Step 1: Write the failing test**

`test/core/full_ocr_parser_test.dart`:
```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/full_ocr_parser_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

`lib/core/full_ocr_parser.dart`:
```dart
import '../models/cccd_data.dart';
import 'hometown_extractor.dart';

String _strip(String s) {
  const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i == -1 ? ch : to[i]);
  }
  return b.toString();
}

String _valueAfterColon(String line) =>
    line.contains(':') ? line.substring(line.indexOf(':') + 1).trim() : '';

String _findByLabel(List<String> lines, List<String> needles) {
  for (final line in lines) {
    final n = _strip(line);
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/full_ocr_parser_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/full_ocr_parser.dart test/core/full_ocr_parser_test.dart
git commit -m "feat: full front-side OCR fallback parser"
```

---

### Task 7: PendingRecord model (offline-queue item)

**Files:**
- Create: `lib/models/pending_record.dart`
- Test: `test/models/pending_record_test.dart`

**Interfaces:**
- Consumes: `CccdData` (Task 1).
- Produces: `class PendingRecord { final CccdData data; final String scanDate; final String id; }` with `toJson()` / `fromJson()` round-trip. `id` defaults to a millisecond timestamp string when omitted.

- [ ] **Step 1: Write the failing test**

`test/models/pending_record_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cccd_scanner/models/cccd_data.dart';
import 'package:cccd_scanner/models/pending_record.dart';

void main() {
  test('json round-trip preserves data', () {
    final r = PendingRecord(
      id: 'r1',
      scanDate: '28/06/2026',
      data: const CccdData(cccdNumber: '012345678901', fullName: 'A'),
    );
    final back = PendingRecord.fromJson(r.toJson());
    expect(back.id, 'r1');
    expect(back.scanDate, '28/06/2026');
    expect(back.data.cccdNumber, '012345678901');
    expect(back.data.fullName, 'A');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/pending_record_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

`lib/models/pending_record.dart`:
```dart
import 'cccd_data.dart';

class PendingRecord {
  final String id;
  final String scanDate;
  final CccdData data;

  PendingRecord({required this.scanDate, required this.data, String? id})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'scanDate': scanDate,
        'data': data.toJson(),
      };

  factory PendingRecord.fromJson(Map<String, dynamic> j) => PendingRecord(
        id: j['id'],
        scanDate: j['scanDate'],
        data: CccdData.fromJson(Map<String, dynamic>.from(j['data'])),
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/pending_record_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/models/pending_record.dart test/models/pending_record_test.dart
git commit -m "feat: add PendingRecord model for offline queue"
```

---

### Task 8: Offline queue (SharedPreferences-backed)

**Files:**
- Create: `lib/services/offline_queue.dart`
- Test: `test/services/offline_queue_test.dart`

**Interfaces:**
- Consumes: `PendingRecord` (Task 7).
- Produces: `class OfflineQueue` with `Future<void> enqueue(PendingRecord)`, `Future<List<PendingRecord>> all()`, `Future<void> remove(String id)`. Backed by `SharedPreferences` key `pending_records` storing a JSON list. Tests inject state with `SharedPreferences.setMockInitialValues({})`.

- [ ] **Step 1: Write the failing test**

`test/services/offline_queue_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cccd_scanner/models/cccd_data.dart';
import 'package:cccd_scanner/models/pending_record.dart';
import 'package:cccd_scanner/services/offline_queue.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('enqueue then all returns the record', () async {
    final q = OfflineQueue();
    await q.enqueue(PendingRecord(
      id: 'a', scanDate: '28/06/2026',
      data: const CccdData(cccdNumber: '012345678901'),
    ));
    final items = await q.all();
    expect(items.length, 1);
    expect(items.first.data.cccdNumber, '012345678901');
  });

  test('remove deletes by id', () async {
    final q = OfflineQueue();
    await q.enqueue(PendingRecord(id: 'a', scanDate: 'x', data: const CccdData()));
    await q.enqueue(PendingRecord(id: 'b', scanDate: 'y', data: const CccdData()));
    await q.remove('a');
    final items = await q.all();
    expect(items.map((e) => e.id), ['b']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/offline_queue_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

`lib/services/offline_queue.dart`:
```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pending_record.dart';

class OfflineQueue {
  static const _key = 'pending_records';

  Future<List<PendingRecord>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PendingRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save(List<PendingRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> enqueue(PendingRecord record) async {
    final items = await all()..add(record);
    await _save(items);
  }

  Future<void> remove(String id) async {
    final items = await all()..removeWhere((e) => e.id == id);
    await _save(items);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/offline_queue_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Run the full suite + analyzer (logic core checkpoint)**

Run: `flutter test && flutter analyze`
Expected: All tests pass; analyzer reports no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/services/offline_queue.dart test/services/offline_queue_test.dart
git commit -m "feat: add SharedPreferences-backed offline queue"
```

---

### Task 9: Google Sign-In auth service

> Integration task — no device-free unit test. Verified manually on an Android device/emulator.

**Files:**
- Create: `lib/services/auth_service.dart`
- Modify: `android/app/build.gradle` (set `minSdkVersion 21`), Google Cloud Console (OAuth client + Sheets API enabled)

**Interfaces:**
- Produces: `class AuthService` with `Future<GoogleSignInAccount?> signIn()`, `Future<void> signOut()`, `GoogleSignInAccount? get currentUser`, and `Future<AuthClient?> authedClient()` returning a `googleapis_auth` client scoped for Sheets. Exposes the configured `GoogleSignIn` instance for the Sheets service.

- [ ] **Step 1: Google Cloud setup (manual, one-time)**

1. Create/select a project in Google Cloud Console.
2. Enable **Google Sheets API**.
3. Configure OAuth consent screen (External, add test users = staff emails).
4. Create an **OAuth client ID** for Android: package `com.cccdscanner.cccd_scanner` + SHA-1 from `cd android && ./gradlew signingReport`.
5. (iOS, later) create an iOS OAuth client; add reversed client ID to `ios/Runner/Info.plist`.

Record the steps in `docs/superpowers/notes/google-setup.md` so other staff can re-do for release signing keys.

- [ ] **Step 2: Implement the service**

`lib/services/auth_service.dart`:
```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart' show SheetsApi;

class AuthService {
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: <String>[SheetsApi.spreadsheetsScope]);

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();

  Future<GoogleSignInAccount?> signInSilently() =>
      _googleSignIn.signInSilently();

  Future<void> signOut() => _googleSignIn.signOut();

  Future<AuthClient?> authedClient() => _googleSignIn.authenticatedClient();
}
```

- [ ] **Step 3: Set Android minSdk**

In `android/app/build.gradle`, inside `defaultConfig`, set `minSdkVersion 21` (ML Kit + Sign-In requirement).

- [ ] **Step 4: Manual verification**

Temporarily wire a button in `main.dart` that calls `AuthService().signIn()` and prints the account email. Run `flutter run` on a device, tap, complete Google login.
Expected: console prints the signed-in email; no crash.
Revert the temporary button after verifying.

- [ ] **Step 5: Commit**

```bash
git add lib/services/auth_service.dart android/app/build.gradle docs/superpowers/notes/google-setup.md
git commit -m "feat: add Google Sign-In auth service"
```

---

### Task 10: Google Sheets service (header, dedup, append)

> Integration task — verified manually against a real test sheet.

**Files:**
- Create: `lib/services/sheets_service.dart`

**Interfaces:**
- Consumes: `AuthService.authedClient()` (Task 9), `CccdData.toSheetRow` (Task 1).
- Produces: `class SheetsService(this.auth, this.spreadsheetId)` with:
  - `Future<void> ensureHeader()` — if row 1 is empty, write the 9 header labels.
  - `Future<bool> cccdExists(String cccdNumber)` — read column A and check membership.
  - `Future<void> appendRow(CccdData data, String scanDate)` — `values.append` one row.
  - Const `kHeader` = the 9 column labels in order.

- [ ] **Step 1: Implement the service**

`lib/services/sheets_service.dart`:
```dart
import 'package:googleapis/sheets/v4.dart';
import 'auth_service.dart';
import '../models/cccd_data.dart';

const List<String> kHeader = [
  'Số CCCD', 'Số CMND cũ', 'Họ và tên', 'Ngày sinh', 'Giới tính',
  'Địa chỉ thường trú', 'Ngày cấp', 'Quê quán', 'Ngày quét',
];

class SheetsService {
  final AuthService auth;
  final String spreadsheetId;
  final String sheetName;

  SheetsService(this.auth, this.spreadsheetId, {this.sheetName = 'Trang tính1'});

  Future<SheetsApi> _api() async {
    final client = await auth.authedClient();
    if (client == null) {
      throw StateError('Chưa đăng nhập Google');
    }
    return SheetsApi(client);
  }

  Future<void> ensureHeader() async {
    final api = await _api();
    final res = await api.spreadsheets.values
        .get(spreadsheetId, '$sheetName!A1:I1');
    final hasHeader = (res.values?.isNotEmpty ?? false) &&
        (res.values!.first.isNotEmpty);
    if (hasHeader) return;
    await api.spreadsheets.values.update(
      ValueRange(values: [kHeader]),
      spreadsheetId,
      '$sheetName!A1',
      valueInputOption: 'RAW',
    );
  }

  Future<bool> cccdExists(String cccdNumber) async {
    final api = await _api();
    final res = await api.spreadsheets.values
        .get(spreadsheetId, '$sheetName!A2:A');
    final col = res.values ?? [];
    return col.any((row) => row.isNotEmpty && '${row.first}' == cccdNumber);
  }

  Future<void> appendRow(CccdData data, String scanDate) async {
    final api = await _api();
    await api.spreadsheets.values.append(
      ValueRange(values: [data.toSheetRow(scanDate)]),
      spreadsheetId,
      '$sheetName!A1',
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
  }
}
```

- [ ] **Step 2: Manual verification**

Create a blank test Google Sheet shared with the test account; copy its ID from the URL. Temporarily call `ensureHeader()` then `appendRow(sampleData, '28/06/2026')` from a debug button.
Expected: header row appears once; one data row appended; calling `cccdExists('012345678901')` returns true after append.
Revert the debug button.

- [ ] **Step 3: Commit**

```bash
git add lib/services/sheets_service.dart
git commit -m "feat: add Google Sheets service (header, dedup, append)"
```

---

### Task 11: OCR service wrapper

> Integration task — thin wrapper over ML Kit; logic already tested in Tasks 5–6.

**Files:**
- Create: `lib/services/ocr_service.dart`

**Interfaces:**
- Produces: `class OcrService` with `Future<List<String>> recognizeLines(InputImage image)` returning text lines top-to-bottom, and `void dispose()`.

- [ ] **Step 1: Implement**

`lib/services/ocr_service.dart`:
```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<List<String>> recognizeLines(InputImage image) async {
    final result = await _recognizer.processImage(image);
    final lines = <String>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        lines.add(line.text);
      }
    }
    return lines;
  }

  void dispose() => _recognizer.close();
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/services/ocr_service.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/services/ocr_service.dart
git commit -m "feat: add ML Kit OCR service wrapper"
```

---

### Task 12: Capture service (camera photo + gallery import → InputImage)

> Integration task — verified manually.

**Files:**
- Create: `lib/services/capture_service.dart`
- Modify: `android/app/src/main/AndroidManifest.xml` (camera permission), `ios/Runner/Info.plist` (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `class CaptureService` with `Future<InputImage?> pickFromGallery()` and `Future<InputImage?> captureFromCamera()`, both returning an ML Kit `InputImage` built from the picked file path (or `null` if cancelled). Picked temp files are **not** retained beyond OCR.

- [ ] **Step 1: Add permissions**

`ios/Runner/Info.plist` — add:
```xml
<key>NSCameraUsageDescription</key>
<string>Dùng camera để quét và chụp thẻ CCCD.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Chọn ảnh CCCD có sẵn để trích xuất thông tin.</string>
```
`android/app/src/main/AndroidManifest.xml` — add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

- [ ] **Step 2: Implement**

`lib/services/capture_service.dart`:
```dart
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CaptureService {
  final ImagePicker _picker = ImagePicker();

  Future<InputImage?> pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return InputImage.fromFilePath(file.path);
  }

  Future<InputImage?> captureFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    if (file == null) return null;
    return InputImage.fromFilePath(file.path);
  }
}
```

- [ ] **Step 3: Manual verification**

From a debug button, call `pickFromGallery()` then run `OcrService().recognizeLines(image)` and print the lines.
Expected: choosing a photo of a CCCD front prints recognizable text lines including a "Quê quán" line. Revert the debug button.

- [ ] **Step 4: Commit**

```bash
git add lib/services/capture_service.dart android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "feat: add capture service for camera + gallery import"
```

---

### Task 13: Sync service (flush offline queue when online)

> Integration task — orchestration over tested pieces.

**Files:**
- Create: `lib/services/sync_service.dart`

**Interfaces:**
- Consumes: `OfflineQueue` (Task 8), `SheetsService` (Task 10), `connectivity_plus`.
- Produces: `class SyncService(this.queue, this.sheets)` with `Future<int> flush()` — for each queued record, if online, `appendRow` then `remove`; returns count flushed. `void start()` subscribes to connectivity changes and calls `flush()` when connectivity returns.

- [ ] **Step 1: Implement**

`lib/services/sync_service.dart`:
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_queue.dart';
import 'sheets_service.dart';

class SyncService {
  final OfflineQueue queue;
  final SheetsService sheets;
  StreamSubscription? _sub;

  SyncService(this.queue, this.sheets);

  Future<bool> _online() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<int> flush() async {
    if (!await _online()) return 0;
    final pending = await queue.all();
    var count = 0;
    for (final r in pending) {
      try {
        await sheets.appendRow(r.data, r.scanDate);
        await queue.remove(r.id);
        count++;
      } catch (_) {
        break; // stop on first failure; retry later
      }
    }
    return count;
  }

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) flush();
    });
  }

  void dispose() => _sub?.cancel();
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/services/sync_service.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/services/sync_service.dart
git commit -m "feat: add sync service to flush offline queue"
```

---

### Task 14: Login screen

**Files:**
- Create: `lib/screens/login_screen.dart`

**Interfaces:**
- Consumes: `AuthService` (Task 9).
- Produces: `class LoginScreen extends StatelessWidget` taking `AuthService auth` and `VoidCallback onSignedIn`. Shows a big "Đăng nhập bằng Google" button; on success calls `onSignedIn`.

- [ ] **Step 1: Implement**

`lib/screens/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;
  final VoidCallback onSignedIn;
  const LoginScreen({super.key, required this.auth, required this.onSignedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final account = await widget.auth.signIn();
      if (account != null) widget.onSignedIn();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại, thử lại')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Quét CCCD',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _signIn,
                  icon: const Icon(Icons.login),
                  label: Text(_busy ? 'Đang đăng nhập...' : 'Đăng nhập bằng Google',
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/screens/login_screen.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/login_screen.dart
git commit -m "feat: add login screen"
```

---

### Task 15: Capture screen (live QR scan + guidance + gallery import)

**Files:**
- Create: `lib/screens/capture_screen.dart`, `lib/widgets/card_frame_overlay.dart`

**Interfaces:**
- Consumes: `mobile_scanner` (`MobileScanner`), `CaptureService` (Task 12), `OcrService` (Task 11), `parseQrFront` (Task 4), `parseFullFront` (Task 6), `extractHometown` (Task 5), `CccdData` (Task 1).
- Produces: `class CaptureScreen` taking `CaptureService capture`, `OcrService ocr`, and `void Function(CccdData, {bool fromFallback}) onExtracted`. Live scanner reads QR; "Chọn ảnh từ máy" button imports a gallery photo. On QR success → `parseQrFront`; then OCR the same/next frame for `hometown`. On QR failure path (gallery image with no readable QR) → `parseFullFront` with `fromFallback: true`.

- [ ] **Step 1: Implement the overlay widget**

`lib/widgets/card_frame_overlay.dart`:
```dart
import 'package:flutter/material.dart';

class CardFrameOverlay extends StatelessWidget {
  final String hint;
  const CardFrameOverlay({super.key, this.hint = 'Đưa thẻ vào trong khung'});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth * 0.85;
      final h = w * 54 / 85.6; // CCCD aspect ratio
      return Stack(children: [
        Center(
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          bottom: 120, left: 0, right: 0,
          child: Text(hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20,
                  backgroundColor: Colors.black54)),
        ),
      ]);
    });
  }
}
```

- [ ] **Step 2: Implement the capture screen**

`lib/screens/capture_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/cccd_data.dart';
import '../core/qr_parser.dart';
import '../core/full_ocr_parser.dart';
import '../core/hometown_extractor.dart';
import '../services/capture_service.dart';
import '../services/ocr_service.dart';
import '../widgets/card_frame_overlay.dart';

class CaptureScreen extends StatefulWidget {
  final CaptureService capture;
  final OcrService ocr;
  final void Function(CccdData data, {bool fromFallback}) onExtracted;
  const CaptureScreen({
    super.key,
    required this.capture,
    required this.ocr,
    required this.onExtracted,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false;

  Future<void> _onQrDetected(BarcodeCapture cap) async {
    if (_handling) return;
    final raw = cap.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _handling = true;
    try {
      final data = parseQrFront(raw);
      widget.onExtracted(data, fromFallback: false);
    } catch (_) {
      _handling = false; // not a valid CCCD QR; keep scanning
    }
  }

  Future<void> _importFromGallery() async {
    if (_handling) return;
    _handling = true;
    try {
      final image = await widget.capture.pickFromGallery();
      if (image == null) {
        _handling = false;
        return;
      }
      final lines = await widget.ocr.recognizeLines(image);
      // Try QR-less full OCR fallback (gallery photos rarely decode QR).
      final data = parseFullFront(lines);
      widget.onExtracted(data, fromFallback: true);
    } finally {
      _handling = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét CCCD')),
      body: Stack(children: [
        MobileScanner(controller: _controller, onDetect: _onQrDetected),
        const CardFrameOverlay(),
      ]),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _importFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Chọn ảnh từ máy', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}
```

> Note for implementer: after a successful live QR read you may additionally OCR a still capture (`widget.capture.captureFromCamera()` → `recognizeLines` → `extractHometown`) to fill `hometown` before navigating; keep this optional and behind the review screen's manual edit.

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/screens/capture_screen.dart lib/widgets/card_frame_overlay.dart`
Expected: No issues.

- [ ] **Step 4: Manual verification**

`flutter run`, sign in, reach the capture screen. Point at a CCCD QR → it should navigate (wired in Task 17). Tap "Chọn ảnh từ máy" → pick a front photo → fallback path runs.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/capture_screen.dart lib/widgets/card_frame_overlay.dart
git commit -m "feat: add capture screen with QR scan and gallery import"
```

---

### Task 16: Review screen (edit, consent, dedup, save/queue)

**Files:**
- Create: `lib/screens/review_screen.dart`

**Interfaces:**
- Consumes: `CccdData` (Task 1), `SheetsService` (Task 10), `OfflineQueue` (Task 8), `PendingRecord` (Task 7).
- Produces: `class ReviewScreen` taking `CccdData initial`, `bool fromFallback`, `SheetsService sheets`, `OfflineQueue queue`, and `VoidCallback onSaved`. Renders one editable `TextField` per field, a required consent checkbox, and a Save button. Save is disabled until consent is ticked. On save: dedup check (warn if exists), then append; on network error, enqueue and report "đã lưu tạm". `scanDate` = `dd/MM/yyyy` of now.

- [ ] **Step 1: Implement**

`lib/screens/review_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../models/cccd_data.dart';
import '../models/pending_record.dart';
import '../services/sheets_service.dart';
import '../services/offline_queue.dart';

class ReviewScreen extends StatefulWidget {
  final CccdData initial;
  final bool fromFallback;
  final SheetsService sheets;
  final OfflineQueue queue;
  final VoidCallback onSaved;
  const ReviewScreen({
    super.key,
    required this.initial,
    required this.fromFallback,
    required this.sheets,
    required this.queue,
    required this.onSaved,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final Map<String, TextEditingController> _c;
  bool _consent = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _c = {
      'Số CCCD': TextEditingController(text: d.cccdNumber),
      'Số CMND cũ': TextEditingController(text: d.oldIdNumber),
      'Họ và tên': TextEditingController(text: d.fullName),
      'Ngày sinh': TextEditingController(text: d.dateOfBirth),
      'Giới tính': TextEditingController(text: d.gender),
      'Địa chỉ thường trú': TextEditingController(text: d.permanentAddress),
      'Ngày cấp': TextEditingController(text: d.issueDate),
      'Quê quán': TextEditingController(text: d.hometown),
    };
  }

  CccdData _collect() => CccdData(
        cccdNumber: _c['Số CCCD']!.text.trim(),
        oldIdNumber: _c['Số CMND cũ']!.text.trim(),
        fullName: _c['Họ và tên']!.text.trim(),
        dateOfBirth: _c['Ngày sinh']!.text.trim(),
        gender: _c['Giới tính']!.text.trim(),
        permanentAddress: _c['Địa chỉ thường trú']!.text.trim(),
        issueDate: _c['Ngày cấp']!.text.trim(),
        hometown: _c['Quê quán']!.text.trim(),
      );

  String _today() {
    final n = DateTime.now();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(n.day)}/${two(n.month)}/${n.year}';
  }

  Future<void> _save() async {
    final data = _collect();
    final scanDate = _today();
    setState(() => _busy = true);
    try {
      bool exists = false;
      try {
        exists = await widget.sheets.cccdExists(data.cccdNumber);
      } catch (_) {/* offline: skip dedup, will queue */}
      if (exists && mounted) {
        final go = await _confirmDuplicate();
        if (go != true) {
          setState(() => _busy = false);
          return;
        }
      }
      await widget.sheets.appendRow(data, scanDate);
      _toast('Đã lưu ✅');
      widget.onSaved();
    } catch (_) {
      await widget.queue
          .enqueue(PendingRecord(data: data, scanDate: scanDate));
      _toast('Mất mạng — đã lưu tạm, sẽ tự gửi lại');
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmDuplicate() => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Khách đã tồn tại'),
          content: const Text('Số CCCD này đã có trong bảng. Vẫn lưu thêm?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Bỏ')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Vẫn lưu')),
          ],
        ),
      );

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xem lại thông tin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.fromFallback)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '⚠ Đọc bằng OCR (không có QR) — vui lòng kiểm tra kỹ từng dòng.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          for (final entry in _c.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                    labelText: entry.key, border: const OutlineInputBorder()),
              ),
            ),
          CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: const Text('Khách hàng đồng ý cho thu thập thông tin'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (_consent && !_busy) ? _save : null,
              child: Text(_busy ? 'Đang lưu...' : 'Lưu',
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/screens/review_screen.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/review_screen.dart
git commit -m "feat: add review screen with consent, dedup, and offline save"
```

---

### Task 17: Wire navigation in main.dart + end-to-end run

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: every screen and service above. Holds the configured `spreadsheetId` (const, replace with the real shared sheet ID). Auth gate: silent sign-in → Login or Capture. Capture → Review → back to Capture on save.

- [ ] **Step 1: Implement the app shell**

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/sheets_service.dart';
import 'services/ocr_service.dart';
import 'services/capture_service.dart';
import 'services/offline_queue.dart';
import 'services/sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/review_screen.dart';

// TODO: replace with the company's shared spreadsheet ID.
const String kSpreadsheetId = 'REPLACE_WITH_SHEET_ID';

void main() => runApp(const CccdScannerApp());

class CccdScannerApp extends StatefulWidget {
  const CccdScannerApp({super.key});
  @override
  State<CccdScannerApp> createState() => _CccdScannerAppState();
}

class _CccdScannerAppState extends State<CccdScannerApp> {
  final auth = AuthService();
  final ocr = OcrService();
  final capture = CaptureService();
  final queue = OfflineQueue();
  late final sheets = SheetsService(auth, kSpreadsheetId);
  late final sync = SyncService(queue, sheets);

  bool _checked = false;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    sync.start();
    auth.signInSilently().then((acc) {
      setState(() {
        _signedIn = acc != null;
        _checked = true;
      });
      if (_signedIn) sheets.ensureHeader();
    });
  }

  @override
  void dispose() {
    ocr.dispose();
    sync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCCD Scanner',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: !_checked
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_signedIn ? _capture() : _login()),
    );
  }

  Widget _login() => LoginScreen(
        auth: auth,
        onSignedIn: () async {
          await sheets.ensureHeader();
          setState(() => _signedIn = true);
        },
      );

  Widget _capture() => Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (context) => CaptureScreen(
            capture: capture,
            ocr: ocr,
            onExtracted: (data, {bool fromFallback = false}) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ReviewScreen(
                  initial: data,
                  fromFallback: fromFallback,
                  sheets: sheets,
                  queue: queue,
                  onSaved: () => Navigator.of(context).pop(),
                ),
              ));
            },
          ),
        ),
      );
}
```

- [ ] **Step 2: Full analyze + test**

Run: `flutter analyze && flutter test`
Expected: No analyzer issues; all unit tests pass.

- [ ] **Step 3: End-to-end manual verification (Android device)**

Set `kSpreadsheetId` to the test sheet. `flutter run`. Verify the full flow:
1. Login with Google.
2. Scan a CCCD QR → review screen pre-filled from QR; Quê quán editable.
3. Tick consent → Save → row appears in the sheet.
4. Import a gallery photo (no QR) → fallback warning shown → fields editable → save.
5. Toggle airplane mode → save → "đã lưu tạm"; turn network back on → row syncs.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire login -> capture -> review flow end to end"
```

---

## Self-Review

**Spec coverage:**
- §2 Android+iOS single codebase → Task 1 (`flutter create --platforms`).
- §2 QR front scan → Tasks 4, 15.
- §2 OCR Quê quán → Tasks 5, 11, 15.
- §2 full-OCR fallback (added in design review) → Tasks 6, 15, 16 (fallback warning).
- §2 gallery import (added in design review) → Tasks 12, 15.
- §2 Google login per staff → Tasks 9, 14.
- §2 shared Sheet, no card images → Tasks 10, 16 (only text appended).
- §4 QR 7-field format + date conversion + 12-digit validation → Tasks 2, 3, 4.
- §5 9 columns in order + header auto-create → Tasks 1 (`toSheetRow`), 10 (`kHeader`/`ensureHeader`).
- §6 flow (login → capture → OCR → review/edit → save) → Tasks 14–17.
- §7 guided capture (frame overlay, hints) → Task 15 (`CardFrameOverlay`). (Auto-capture/auto-crop/quality hints noted as optional enhancement on top of `mobile_scanner` + document scanner; the overlay + manual import deliver the testable baseline.)
- §8 error handling: bad QR → fallback OCR (Task 15/16); OCR mis-accents → editable review (Task 16); duplicate → dedup dialog (Tasks 10, 16); offline → queue + sync (Tasks 8, 13, 16); missing write permission → surfaced as save error → queued/toast (Task 16).
- §9 legal: consent checkbox required (Task 16), no image persisted (Global Constraints + Task 12), data only in company sheet.

**Gap noted:** §7's *fully automatic* capture (auto-shoot when sharp + auto background-crop via `google_mlkit_document_scanner`) is scoped as an enhancement layered on Task 15 after the baseline flow works end-to-end, to avoid blocking a shippable build. Implementer may promote it to its own task once Tasks 1–17 pass.

**Placeholder scan:** No "TBD"/"add error handling"/"similar to Task N" left; the only intentional placeholder is `kSpreadsheetId = 'REPLACE_WITH_SHEET_ID'`, which is a required runtime config value, flagged in Task 17.

**Type consistency:** `CccdData` field names, `toSheetRow(scanDate)`, `kHeader`, `parseQrFront`, `parseFullFront`, `extractHometown`, `OfflineQueue.{enqueue,all,remove}`, `PendingRecord.{data,scanDate,id}`, and `SheetsService.{ensureHeader,cccdExists,appendRow}` are used identically across producing and consuming tasks.
