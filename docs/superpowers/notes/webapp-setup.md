# Launch webapp bằng Vercel

Repo này đã có sẵn `vercel.json`, nên có thể import thẳng toàn bộ repo vào Vercel.

## 1. Điều kiện trước khi launch
- `cccdscanner/index.html` phải giữ đúng `SCRIPT_URL` và `SECRET` đang khớp với Apps Script.
- `docs/apps-script/Code.gs` phải đã deploy lại nếu có sửa logic hoặc đổi `SECRET`.

## 2. Launch trên Vercel
1. Push repo lên GitHub hoặc Git provider khác.
2. Tạo project mới trên Vercel và import repo này.
3. Deploy.
4. Mở URL Vercel ở điện thoại để dùng webapp.

## 3. Cách chạy
1. Mở URL Vercel bằng Safari hoặc Chrome mobile.
2. Bấm **Bắt đầu quét** và cho phép camera.
3. Quét QR CCCD → webapp tự điền 7 trường.
4. Nhập **Quê quán**, tick đồng ý, rồi bấm **Lưu**.
5. Kiểm tra dòng mới trong Google Sheet.

## 4. Khi cần đổi backend
- Sửa `docs/apps-script/Code.gs`.
- Deploy lại Apps Script.
- Cập nhật lại `SCRIPT_URL` hoặc `SECRET` trong `cccdscanner/index.html` nếu thay đổi.