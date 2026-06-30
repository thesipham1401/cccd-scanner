# CCCD Scanner Webapp

Webapp quét QR CCCD trên điện thoại, rà lại dữ liệu rồi lưu vào Google Sheet chung.
Frontend được deploy trên Vercel, backend ghi Sheet dùng Google Apps Script.

## Cấu trúc

- `webapp/` - frontend tĩnh cho mobile.
- `docs/apps-script/Code.gs` - endpoint ghi dữ liệu vào Google Sheet.
- `docs/superpowers/specs/2026-06-28-cccd-scanner-design.md` - spec hiện tại đã chuyển sang webapp-only.
- `docs/superpowers/notes/webapp-setup.md` - hướng dẫn deploy Vercel.

## Luồng sử dụng

1. Mở link Vercel trên điện thoại.
2. Quét QR mặt trước CCCD.
3. Nhập Quê quán và kiểm tra lại thông tin.
4. Tick đồng ý và bấm Lưu.

## Triển khai

1. Cập nhật `webapp/index.html` với `SCRIPT_URL` và `SECRET` đúng.
2. Deploy frontend lên Vercel.
3. Deploy lại Apps Script nếu thay đổi `docs/apps-script/Code.gs`.
