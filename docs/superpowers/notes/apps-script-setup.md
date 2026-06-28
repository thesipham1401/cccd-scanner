# Thiết lập ghi Google Sheet bằng Apps Script (đơn giản, ~5 phút)

Không cần Google Cloud, không cần đăng nhập trên app. Làm 1 lần.

## Bước 1 — Tạo Google Sheet
- Tạo 1 Google Sheet trống để lưu dữ liệu (đặt tên tùy ý).

## Bước 2 — Dán script
1. Trong sheet đó: menu **Tiện ích mở rộng → Apps Script** (Extensions → Apps Script).
2. Xóa code mẫu, **dán toàn bộ nội dung** file `docs/apps-script/Code.gs`.
3. Ở dòng `const SECRET = '...'`, **đổi** thành một chuỗi ngẫu nhiên dài (ví dụ
   bấm phím lung tung: `k7Qz9_mau-tho1-bi-mat-2026`). **Nhớ chuỗi này.**
4. Bấm biểu tượng **Lưu** (Save).

## Bước 3 — Triển khai thành link
1. Góc trên phải bấm **Triển khai (Deploy) → Tùy chọn triển khai mới (New deployment)**.
2. Bánh răng ⚙ → chọn **Ứng dụng web (Web app)**.
3. Đặt:
   - **Execute as / Thực thi bằng**: *Me (chính bạn)*
   - **Who has access / Ai có quyền truy cập**: *Anyone (Bất kỳ ai)*
4. Bấm **Triển khai (Deploy)**. Lần đầu Google hỏi cấp quyền → bấm
   *Authorize/Cho phép* → chọn tài khoản → *Advanced → Go to … (unsafe)* →
   *Allow*. (Bình thường vì đây là script của chính bạn.)
5. Copy **Web app URL** (dạng `https://script.google.com/macros/s/AKfyc.../exec`).

## Bước 4 — Điền vào app
Mở `lib/main.dart`, sửa 2 dòng:
```dart
const String kScriptUrl = 'DÁN_WEB_APP_URL_Ở_ĐÂY';
const String kSharedSecret = 'CHUỖI_SECRET_GIỐNG_HỆT_TRONG_Code.gs';
```
> `kSharedSecret` phải **trùng khít** với `SECRET` trong Code.gs, nếu không app
> sẽ bị từ chối ghi.

## Xong
- Build app → quét/chọn ảnh → Lưu → dòng mới xuất hiện trong sheet.
- Trùng số CCCD: script trả về "duplicate", app hỏi "Vẫn lưu?".
- Mất mạng: app lưu tạm, có mạng lại tự gửi.

## Đổi mật khẩu / link sau này
- Sửa `SECRET` trong Code.gs → **Triển khai lại** (Deploy → Manage deployments →
  bút chì ✎ → New version). Cập nhật lại `kSharedSecret` trong app.
