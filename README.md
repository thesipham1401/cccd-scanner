# CCCD Scanner Webapp

Webapp quét QR CCCD trên điện thoại, rà lại dữ liệu rồi lưu vào Google Sheet chung.
Frontend được deploy trên Vercel, backend ghi Sheet dùng Google Apps Script.

## Cấu trúc

- `/` - landing page chọn công cụ.
- `cccdscanner/` - frontend tĩnh cho mobile.
- `docs/apps-script/Code.gs` - endpoint ghi dữ liệu vào Google Sheet.
- `docs/superpowers/specs/2026-06-28-cccd-scanner-design.md` - spec hiện tại đã chuyển sang webapp-only.
- `docs/superpowers/notes/webapp-setup.md` - hướng dẫn deploy Vercel.

## Luồng sử dụng

1. Mở link Vercel trên điện thoại.
2. Quét QR mặt trước CCCD.
3. Nhập Quê quán và kiểm tra lại thông tin.
4. Tick đồng ý và bấm Lưu.

## Triển khai

1. Cập nhật `cccdscanner/index.html` với `SCRIPT_URL` và `SECRET` đúng.
2. Deploy frontend lên Vercel.
3. Deploy lại Apps Script nếu thay đổi `docs/apps-script/Code.gs`.

## Cách launch webapp

### 1. Local test

1. Chạy một web server tĩnh ở thư mục gốc của repo, ví dụ `python -m http.server 8080` hoặc `npx serve .`.
2. Mở `http://localhost:8080/` để vào landing page chọn công cụ.
3. Mở `http://localhost:8080/cccdscanner/` để vào scanner trực tiếp.
4. Nếu cần trỏ sang backend khác, mở kèm query string `?script_url=<URL>&secret=<SECRET>`.
5. Refresh lại trang, webapp sẽ ghi nhớ cấu hình đó bằng `localStorage`.
6. Không mở bằng `file://` vì camera cần `localhost` hoặc HTTPS.

### 2. Vercel preview

1. Import toàn bộ repo này vào Vercel.
2. Deploy project trên Vercel.
3. Dùng URL preview hoặc production của Vercel để test camera và QR.
4. Nếu cần test backend khác, thêm `?script_url=<URL>&secret=<SECRET>` vào URL.

### 3. Production

1. Đảm bảo `docs/apps-script/Code.gs` đã được deploy lại sau khi đổi `SECRET` hoặc logic ghi Sheet.
2. Đảm bảo `cccdscanner/index.html` đang dùng đúng `SCRIPT_URL` và `SECRET` mặc định.
3. Mở URL Vercel trên điện thoại để dùng webapp.

## Khi có thay đổi

- Nếu đổi backend Apps Script, cập nhật lại `SCRIPT_URL` hoặc `SECRET` trong `cccdscanner/index.html` và deploy lại Apps Script.
- Nếu chỉ đổi giao diện frontend, chỉ cần redeploy Vercel.
- Nếu chỉ muốn test một backend khác mà không sửa file, dùng `?script_url=<URL>&secret=<SECRET>` trên URL.
