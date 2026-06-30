# Thiết kế: Webapp quét CCCD → Google Sheets

**Ngày:** 2026-07-01
**Trạng thái:** Đã chuyển hướng sang webapp-only, sẵn sàng triển khai trên Vercel

---

## 1. Mục tiêu

Xây một webapp tối giản, chạy tốt trên điện thoại, để nhân viên quét QR mặt trước CCCD,
kiểm tra lại dữ liệu và lưu thẳng vào một Google Sheet chung của doanh nghiệp.
Ưu tiên là thao tác ít bước, chữ lớn, và deploy không cần app store.

## 2. Phạm vi

### Có làm
- Webapp chạy trên trình duyệt hiện đại, tối ưu cho iPhone Safari và Android Chrome.
- Quét QR mặt trước CCCD bằng camera trong web.
- Màn hình xem lại để sửa tay các trường trước khi lưu.
- Bắt buộc tick ô đồng ý thu thập thông tin trước khi lưu.
- Ghi dữ liệu vào Google Sheet chung qua Apps Script Web App.
- Deploy frontend trên Vercel.

### Không làm
- Không còn Flutter / native mobile app.
- Không đọc chip NFC.
- Không OCR toàn thẻ, không lưu ảnh thẻ, không dựng backend riêng.
- Không đăng nhập từng nhân viên bằng Google Account trong app web.

## 3. Công nghệ

| Thành phần | Lựa chọn | Lý do |
|---|---|---|
| Frontend | HTML/CSS/Vanilla JS | Nhẹ, dễ deploy trên Vercel |
| QR camera | `html5-qrcode` | Chạy trực tiếp trong trình duyệt |
| Lưu Sheet | Google Apps Script Web App | Không cần backend riêng |
| Hosting | Vercel | HTTPS mặc định, phù hợp camera trên mobile |

## 4. Dữ liệu QR CCCD

QR mặt trước CCCD gồm 7 trường ngăn bởi dấu `|`:

```
<Số CCCD>|<Số CMND cũ>|<Họ và tên>|<Ngày sinh ddMMyyyy>|<Giới tính>|<Nơi thường trú>|<Ngày cấp ddMMyyyy>
```

- Số CCCD phải là 12 chữ số.
- `ddMMyyyy` được đổi sang `dd/MM/yyyy` trước khi hiển thị và lưu.
- Nếu QR sai định dạng thì webapp báo lỗi và tiếp tục quét.

## 5. Cột Google Sheet

Thứ tự cột cố định:

```
Số CCCD | Số CMND cũ | Họ và tên | Ngày sinh | Giới tính | Địa chỉ thường trú | Ngày cấp | Quê quán | Ngày quét
```

- 7 cột đầu lấy từ QR.
- Quê quán do nhân viên nhập tay.
- Ngày quét do webapp tự tạo.
- Nếu sheet còn trống, Apps Script tự chèn dòng tiêu đề.

## 6. Luồng sử dụng

1. Người dùng mở link Vercel trên điện thoại.
2. Bấm bắt đầu quét và cấp quyền camera.
3. Đưa QR CCCD vào khung quét.
4. Webapp điền sẵn 7 trường dữ liệu.
5. Người dùng nhập Quê quán, rà lại các trường và tick đồng ý.
6. Bấm Lưu để gửi dữ liệu qua Apps Script vào Google Sheet.
7. Nếu trùng CCCD, webapp hỏi xác nhận trước khi lưu tiếp.

## 7. Cấu trúc triển khai

- Frontend tĩnh đặt trong thư mục `cccdscanner/`.
- Vercel chỉ phục vụ giao diện và HTTPS.
- Apps Script giữ vai trò backend cực mỏng để ghi Google Sheet.
- Toàn bộ luồng phải dùng được trên trình duyệt mobile mà không cần cài app.

## 8. Ràng buộc

- Camera chỉ hoạt động qua HTTPS.
- Không lưu ảnh thẻ và không lưu dữ liệu ngoài Google Sheet.
- Tất cả chữ hiển thị cho người dùng đều bằng tiếng Việt.
- Nếu cần đổi endpoint Sheet, chỉ sửa URL/SECRET của webapp và redeploy Apps Script.