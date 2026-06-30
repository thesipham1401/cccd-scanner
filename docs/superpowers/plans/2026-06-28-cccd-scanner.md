# CCCD Scanner Webapp Plan

> Đây là kế hoạch đã chuyển sang webapp-only. Flutter/mobile plan cũ không còn áp dụng.

**Goal:** Xây webapp mobile-first để quét QR CCCD, cho nhân viên rà lại dữ liệu, rồi lưu một dòng vào Google Sheet chung.

**Architecture:** Frontend tĩnh trên Vercel. Google Apps Script Web App làm backend mỏng để ghi dữ liệu vào Sheet. Luồng chính là quét QR → điền form → nhập Quê quán → tick đồng ý → lưu.

**Tech Stack:** HTML/CSS/Vanilla JS, `html5-qrcode`, Google Apps Script Web App, Google Sheets, Vercel.

## Global Constraints

- Chỉ làm webapp, không còn Flutter / native mobile app.
- Tất cả UI và thông báo đều bằng tiếng Việt.
- Không lưu ảnh CCCD.
- Camera chỉ chạy qua HTTPS, nên frontend phải deploy trên Vercel hoặc host HTTPS tương đương.
- Sheet vẫn giữ đúng thứ tự cột: `Số CCCD | Số CMND cũ | Họ và tên | Ngày sinh | Giới tính | Địa chỉ thường trú | Ngày cấp | Quê quán | Ngày quét`.

## Delivery Plan

- [ ] Xác nhận lại luồng webapp hiện tại trong `webapp/index.html`.
- [ ] Chuyển toàn bộ tài liệu tham chiếu từ app mobile sang webapp-only.
- [ ] Cập nhật Apps Script endpoint để nhận đúng payload từ webapp.
- [ ] Deploy frontend lên Vercel và kiểm tra quét QR trên điện thoại.
- [ ] Kiểm tra lưu Sheet, xử lý trùng CCCD, và thông báo lỗi tiếng Việt.

## Definition of Done

- Mở link Vercel trên điện thoại là dùng được ngay.
- Quét QR CCCD xong có thể sửa tay và lưu vào Google Sheet.
- Không còn tài liệu nào mô tả Flutter, Android/iOS native, hay store deployment như luồng chính.