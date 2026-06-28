/**
 * CCCD Scanner — Apps Script Web App.
 *
 * Gắn vào chính Google Sheet sẽ lưu dữ liệu:
 *   Tiện ích mở rộng (Extensions) → Apps Script → dán file này → Lưu.
 *   Triển khai (Deploy) → Ứng dụng web (Web app):
 *     - Execute as: Me (chính bạn)
 *     - Who has access: Anyone (Bất kỳ ai)
 *   → Copy "Web app URL" và dán vào app (kScriptUrl).
 *
 * QUAN TRỌNG: đổi SECRET bên dưới thành một chuỗi ngẫu nhiên dài, rồi dán y
 * hệt chuỗi đó vào app (kSharedSecret). Đây là "mật khẩu" chống người lạ ghi bậy.
 */

const SECRET = 'DOI_CHUOI_NAY_THANH_MAT_KHAU_NGAU_NHIEN_DAI';

const HEADER = [
  'Số CCCD', 'Số CMND cũ', 'Họ và tên', 'Ngày sinh', 'Giới tính',
  'Địa chỉ thường trú', 'Ngày cấp', 'Quê quán', 'Ngày quét',
];

function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    if (body.secret !== SECRET) {
      return _json({ result: 'error', message: 'unauthorized' });
    }

    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];

    // Tạo dòng tiêu đề nếu sheet đang trống.
    if (sheet.getLastRow() === 0) {
      sheet.appendRow(HEADER);
    }

    const row = body.row;
    const cccd = String(row[0]);

    // Kiểm tra trùng theo cột A (Số CCCD), trừ khi force = true.
    if (!body.force && sheet.getLastRow() >= 2) {
      const colA = sheet
        .getRange(2, 1, sheet.getLastRow() - 1, 1)
        .getValues();
      const exists = colA.some(function (r) { return String(r[0]) === cccd; });
      if (exists) {
        return _json({ result: 'duplicate' });
      }
    }

    sheet.appendRow(row);
    return _json({ result: 'appended' });
  } catch (err) {
    return _json({ result: 'error', message: String(err) });
  }
}

function _json(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
