# Web app (quét CCCD trên điện thoại) — deploy qua Vercel

Web app dùng **cùng Google Sheet** qua Google Apps Script.
Frontend được deploy trên **Vercel** để có HTTPS và mở camera ổn định trên mobile.

## 1. Cập nhật Apps Script
`docs/apps-script/Code.gs` đã có endpoint `doGet` JSONP cho webapp. Khi đổi `SECRET` hoặc logic sheet, phải deploy lại:
1. Mở Google Sheet → Tiện ích mở rộng → Apps Script.
2. Dán lại nội dung `docs/apps-script/Code.gs`.
3. **Deploy** → **Manage deployments** → chỉnh sửa deployment hiện tại.
4. Chọn **New version** → **Deploy**.

## 2. Cấu hình webapp
Mở `webapp/index.html`, sửa 2 dòng trong phần CẤU HÌNH để trỏ đúng Apps Script:
```js
const SCRIPT_URL = 'https://script.google.com/macros/s/REPLACE_ME/exec';
const SECRET = 'REPLACE_ME';
```

## 3. Deploy lên Vercel
1. Đưa thư mục `webapp` lên một repo Git.
2. Tạo project mới trên Vercel và import repo đó.
3. Giữ cấu hình mặc định nếu đây là static site.
4. Deploy, rồi lấy URL HTTPS do Vercel cấp.

## 4. Dùng trên điện thoại
1. Mở URL Vercel bằng Safari hoặc Chrome mobile.
2. Bấm **Bắt đầu quét** và cho phép camera.
3. Quét QR CCCD → webapp tự điền 7 trường.
4. Nhập **Quê quán**, tick đồng ý, rồi bấm **Lưu**.
5. Kiểm tra dòng mới trong Google Sheet.

## 5. Lưu ý
- Camera chỉ chạy khi site có HTTPS, vì vậy Vercel là đường deploy chính.
- Không lưu ảnh CCCD trong trình duyệt hay trên server.
- Nếu đổi `SECRET`, phải cập nhật cả Apps Script lẫn `webapp/index.html`.