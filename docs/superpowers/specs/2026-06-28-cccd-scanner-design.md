# Thiết kế: App quét CCCD Việt Nam → Google Sheets

**Ngày:** 2026-06-28
**Trạng thái:** Đã duyệt thiết kế, sẵn sàng lập kế hoạch triển khai

---

## 1. Mục tiêu

App mobile giúp 2–10 nhân viên quét Căn cước công dân (CCCD gắn chip) của Việt Nam
để lấy thông tin khách hàng và lưu vào một **Google Sheet chung** của doanh nghiệp.
Ưu tiên **dễ dùng cho người low-tech** và **độ chính xác dữ liệu**.

## 2. Phạm vi

### Có làm
- App mobile chạy **Android + iOS** (1 codebase).
- Quét **QR mặt trước CCCD** (nguồn dữ liệu chính, chính xác).
- **OCR offline** lấy trường **Quê quán** (QR không có); và làm **dự phòng đọc toàn bộ trường** khi không có QR.
- **Chụp ảnh có hướng dẫn** + tự cắt nền cho người low-tech.
- **Chọn ảnh CCCD có sẵn trong máy** (thư viện ảnh, 1 ảnh mặt trước) để trích xuất thông tin — cùng luồng xử lý như quét trực tiếp.
- Đăng nhập Google theo từng nhân viên; ghi vào 1 Google Sheet chung.
- Màn hình xem lại + sửa tay trước khi lưu.

### KHÔNG làm (để sau)
- Không đọc chip **NFC**.
- Không lưu **ảnh thẻ** (chỉ lưu dữ liệu chữ).
- Không dựng backend/database riêng (dùng Google Sheet thay DB).
- Không OCR qua mạng (chỉ OCR trên máy).

## 3. Công nghệ

| Thành phần | Lựa chọn | Lý do |
|---|---|---|
| Framework | **Flutter** | 1 codebase cho Android + iOS |
| Đọc QR | `mobile_scanner` (Google ML Kit Barcode) | Đọc QR CCCD chính xác, nhanh |
| Chụp + cắt nền | **Google ML Kit Document Scanner** | Tự nhận viền thẻ, cắt nền, làm phẳng — miễn phí |
| OCR Quê quán | `google_mlkit_text_recognition` | Offline, miễn phí, đủ tốt với chữ có dấu |
| Đăng nhập + ghi Sheet | `google_sign_in` + Google Sheets API v4 (`values.append`) | Mỗi nhân viên 1 tài khoản, ghi dòng gọn |
| Chọn ảnh từ máy | `image_picker` | Lấy 1 ảnh mặt trước từ thư viện rồi đưa vào cùng luồng QR/OCR (`InputImage.fromFilePath`) |

## 4. Cấu trúc dữ liệu QR CCCD

QR mặt trước CCCD gắn chip gồm **7 trường** ngăn bởi dấu `|`:

```
<Số CCCD> | <Số CMND cũ> | <Họ và tên> | <Ngày sinh ddMMyyyy> | <Giới tính> | <Nơi thường trú> | <Ngày cấp ddMMyyyy>
```

- App tách 7 trường này.
- Ngày `ddMMyyyy` → hiển thị/lưu dạng `dd/MM/yyyy`.
- Nếu chuỗi QR không đủ 7 trường hoặc số CCCD không phải 12 chữ số → coi là QR không hợp lệ.

## 5. Các cột trong Google Sheet

Thứ tự cột:

```
Số CCCD | Số CMND cũ | Họ và tên | Ngày sinh | Giới tính | Địa chỉ thường trú | Ngày cấp | Quê quán | Ngày quét
```

- 7 cột đầu lấy từ QR; **Quê quán** từ OCR; **Ngày quét** do app tự tạo.
- (Không có cột "nhân viên quét" — theo yêu cầu.)
- Nếu Sheet còn trống, app tự tạo **dòng tiêu đề** trước khi ghi dòng đầu tiên.

## 6. Luồng sử dụng (6 bước)

1. **Đăng nhập Google** — 1 lần, app nhớ phiên.
2. **Lấy thẻ** — chọn 1 trong 2:
   - **Quét trực tiếp** mặt trước CCCD bằng camera, hoặc
   - **Chọn ảnh có sẵn** trong thư viện máy (1 ảnh mặt trước).
3. App **đọc QR** từ ảnh/khung quét → tự điền 7 trường. Nếu QR không đọc được →
   **OCR toàn bộ** đọc tạm các trường (xem mục 8).
4. **Chụp/đọc mặt trước** → OCR lấy **Quê quán**.
5. **Màn hình xem lại** — hiện đủ thông tin, nhân viên **sửa tay** nếu OCR sai dấu;
   tick ô **đồng ý thu thập thông tin**; bấm **Lưu**.
6. App **ghi 1 dòng** vào Google Sheet → báo *"Đã lưu ✅"*.

## 7. Chụp ảnh có hướng dẫn (cho người low-tech)

Mục tiêu: nhân viên không phải tự căn chỉnh; app dẫn dắt và tự xử lý nền.

1. **Khung định vị thẻ** — overlay hình chữ nhật đúng tỉ lệ CCCD (85.6 × 54 mm).
   Hướng dẫn chữ to: *"Đưa thẻ vào trong khung"*. Nền ngoài khung bị bỏ.
2. **Tự động chụp** — khi thẻ đúng khung + đủ sáng + không mờ → app tự đếm rồi chụp,
   không cần bấm nút.
3. **Tự cắt nền** — ML Kit Document Scanner nhận viền thẻ, cắt bỏ background,
   làm phẳng ảnh nghiêng, tăng tương phản trước khi OCR. (Xử lý trực tiếp vấn đề
   nhân viên chụp dính bàn/tay/nền.)
4. **Kiểm tra chất lượng + báo bằng lời đơn giản**:
   - Mờ → *"Giữ máy yên, chụp lại"*
   - Tối → tự **bật flash** + *"Ra chỗ sáng hơn"*
   - Lóa/chói → *"Nghiêng thẻ tránh ánh sáng phản chiếu"*
5. **Phản hồi rõ ràng** — khung chuyển **xanh + rung nhẹ + tiếng "tách"** khi chụp xong.

## 8. Xử lý lỗi & trường hợp đặc biệt

| Tình huống | Cách xử lý |
|---|---|
| QR không đọc được / sai định dạng | **OCR toàn bộ** đọc tạm các trường từ ảnh → màn hình xem lại bắt buộc kiểm/sửa tay; hoặc cho quét/chọn ảnh lại |
| Ảnh chọn từ máy bị mờ/thiếu sáng | Cảnh báo *"ảnh không rõ"*; vẫn thử OCR toàn bộ, hoặc cho chọn ảnh khác / chụp lại |
| OCR sai dấu | Màn hình xem lại cho sửa tay trước khi lưu |
| Trùng khách (cùng số CCCD đã có trong Sheet) | Cảnh báo *"đã tồn tại"*, cho chọn vẫn lưu hoặc bỏ |
| Mất mạng khi lưu | Giữ tạm bản ghi trong **hàng đợi offline**, tự gửi lại khi có mạng |
| Thiếu quyền ghi Sheet | Hướng dẫn chủ Sheet chia sẻ quyền ghi cho email nhân viên |

## 9. Tuân thủ pháp lý (Nghị định 13/2023/NĐ-CP)

- Màn hình lưu có ô tick **"Khách hàng đồng ý cho thu thập thông tin"** — bắt buộc tick mới lưu.
- **Không lưu ảnh thẻ**; chỉ lưu dữ liệu chữ cần thiết.
- Dữ liệu nằm trong Google Sheet do doanh nghiệp sở hữu; chỉ chia sẻ cho nhân viên cần dùng.

## 10. Quyền & cấu hình cần chuẩn bị

- **Google Cloud project** + bật **Google Sheets API**; cấu hình **OAuth consent**.
- **ID Sheet** mục tiêu (chủ Sheet chia sẻ quyền *Editor* cho email các nhân viên).
- Quyền **Camera** trên Android/iOS.

## 11. Cấu trúc module (để dễ test độc lập)

- `qr_parser` — nhận chuỗi QR → object 7 trường (thuần logic, dễ unit test).
- `ocr_quequan` — nhận ảnh đã cắt → trích trường Quê quán.
- `capture_guide` — camera overlay + auto-capture + document scanner.
- `sheets_repo` — ghi/đọc Google Sheet, tạo header, kiểm tra trùng, hàng đợi offline.
- `auth` — đăng nhập Google, giữ phiên.
- `review_screen` — hiển thị + sửa tay + ô đồng ý + nút Lưu.
