# Thiết lập Google (một lần) cho CCCD Scanner

Cần làm trước khi đăng nhập + ghi Google Sheet hoạt động trên thiết bị thật.

## 1. Google Cloud project
1. Vào https://console.cloud.google.com → tạo project (hoặc chọn project có sẵn).
2. **APIs & Services → Enable APIs** → bật **Google Sheets API**.
3. **OAuth consent screen**: chọn *External*, điền tên app, thêm **Test users** = email từng nhân viên (khi còn ở chế độ Testing).

## 2. OAuth client IDs
google_sign_in 7.x trên Android dùng Credential Manager và cần **Web client ID** để cấp quyền (authorization) cho scope Sheets.

- **Web application** client ID → dùng làm `kServerClientId` trong `lib/main.dart`.
- **Android** client ID: package `com.cccdscanner.cccd_scanner` + SHA-1.
  Lấy SHA-1: `cd android && ./gradlew signingReport` (cả debug và release).
- **iOS** client ID (khi build iOS): thêm *reversed client ID* vào `ios/Runner/Info.plist`
  (`CFBundleURLTypes`).

## 3. Cấu hình trong code
- `lib/main.dart`:
  - `kSpreadsheetId` = ID của Google Sheet dùng chung (lấy từ URL sheet:
    `https://docs.google.com/spreadsheets/d/<ID>/edit`).
  - `kServerClientId` = Web client ID ở bước 2.
- Chia sẻ (Share) Google Sheet với từng email nhân viên ở quyền **Editor**.

## 4. Kiểm tra
- `flutter doctor` phải ✓ Flutter + Android toolchain.
- Đăng nhập trên app → quét/chọn ảnh → Lưu → kiểm tra dòng mới xuất hiện trong sheet.

> Khi phát hành (release), nhớ thêm SHA-1 của **release keystore** vào Android OAuth client,
> nếu không đăng nhập sẽ lỗi trên bản APK release.
