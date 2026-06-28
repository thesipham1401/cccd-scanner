# Web app (quét CCCD trên iPhone/Safari) — triển khai miễn phí

Web app dùng **cùng Google Sheet** với app Android, qua cùng Apps Script.
Không cần Mac, không cần tài khoản Apple, không mất phí.

## 1. Cập nhật Apps Script (làm 1 lần)
`Code.gs` đã được nâng cấp để phục vụ cả web (thêm `doGet` JSONP). Phải deploy lại:
1. Mở Google Sheet → Tiện ích mở rộng → Apps Script.
2. Dán lại toàn bộ `docs/apps-script/Code.gs` mới (giữ nguyên dòng `SECRET`).
3. **Triển khai (Deploy) → Quản lý triển khai (Manage deployments)** → bút chì ✎ →
   **Phiên bản: New version** → **Triển khai**. (Giữ Execute as: Me, Access: Anyone.)
   URL `/exec` không đổi.

## 2. Cấu hình trang web
Mở `webapp/index.html`, sửa 2 dòng trong phần CẤU HÌNH:
```js
const SCRIPT_URL = 'DÁN_WEB_APP_URL_/exec';
const SECRET = 'CHUỖI_SECRET_GIỐNG_HỆT_TRONG_Code.gs';
```

## 3. Đưa trang web lên mạng (cần HTTPS để mở camera)
Chọn 1 trong 2 cách, đều miễn phí:

**Cách A — Netlify Drop (nhanh nhất, không cần tài khoản):**
1. Vào https://app.netlify.com/drop
2. Kéo-thả **thư mục `webapp`** vào trang đó.
3. Nhận ngay 1 link HTTPS dạng `https://ten-ngau-nhien.netlify.app` → gửi cho nhân viên.

**Cách B — GitHub Pages:**
1. Tạo repo, đẩy nội dung thư mục `webapp` lên.
2. Settings → Pages → Branch = main, thư mục gốc → Save.
3. Nhận link `https://<user>.github.io/<repo>/`.

## 4. Dùng trên iPhone
1. Mở link bằng **Safari**.
2. Bấm **Bắt đầu quét** → Safari hỏi quyền camera → **Cho phép**.
3. Đưa mã QR mặt trước CCCD vào khung → tự điền 7 trường.
4. **Gõ Quê quán** + tick đồng ý → **Lưu** → kiểm tra dòng mới trong Sheet.
5. (Tùy chọn) Safari → nút Chia sẻ → **Thêm vào màn hình chính** để dùng như 1 app.

## Giới hạn của bản web (so với app Android)
- Không có OCR tự đọc Quê quán → **gõ tay** (1 ô).
- Không có "chọn ảnh có sẵn → tự đọc".
- Camera chỉ chạy khi mở qua **HTTPS** (các link ở bước 3 đều là HTTPS).
- Nếu Safari không xin quyền camera: vào Cài đặt → Safari → Camera → Cho phép.

## Lưu ý bảo mật
- `SECRET` nằm trong mã trang web (ai mở "View Source" đều thấy). Với công cụ nội bộ
  thì chấp nhận được — nó chỉ chặn người lạ tình cờ; đừng công khai link rộng rãi.
- Muốn an toàn hơn: đổi `SECRET` định kỳ (sửa Code.gs → deploy New version → sửa lại web).
