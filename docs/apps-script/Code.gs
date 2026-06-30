/**
 * CCCD Scanner — Apps Script Web App.
 * Phục vụ frontend webapp deploy trên Vercel qua GET JSONP để tránh lỗi CORS của trình duyệt.
 *
 * Cách deploy: mở Google Sheet → Tiện ích mở rộng → Apps Script → dán file này →
 *   Triển khai → Ứng dụng web → Execute as: Me, Who has access: Anyone → copy URL.
 *
 * QUAN TRỌNG: đổi SECRET thành chuỗi ngẫu nhiên dài và dán y hệt vào cccdscanner/index.html.
 */

const SECRET = 'DOI_CHUOI_NAY_THANH_MAT_KHAU_NGAU_NHIEN_DAI';

const HEADER = [
  'Số CCCD', 'Số CMND cũ', 'Họ và tên', 'Ngày sinh', 'Giới tính',
  'Địa chỉ thường trú', 'Ngày cấp', 'Quê quán', 'Ngày quét',
];

// JSON POST legacy / internal use — { secret, force, row:[...9] }
function doPost(e) {
  const body = JSON.parse(e.postData.contents);
  return _json(_handle(body));
}

// Web app — GET ?secret=&force=&c0..c8=&callback=  → trả về JSONP
function doGet(e) {
  const p = e.parameter;
  const row = [p.c0, p.c1, p.c2, p.c3, p.c4, p.c5, p.c6, p.c7, p.c8];
  const result = _handle({
    secret: p.secret,
    force: (p.force === 'true' || p.force === '1'),
    row: row,
  });
  const cb = p.callback || 'callback';
  return ContentService
    .createTextOutput(cb + '(' + JSON.stringify(result) + ')')
    .setMimeType(ContentService.MimeType.JAVASCRIPT);
}

function _handle(body) {
  try {
    if (body.secret !== SECRET) {
      return { result: 'error', message: 'unauthorized' };
    }
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
    if (sheet.getLastRow() === 0) {
      sheet.appendRow(HEADER);
    }
    const row = body.row;
    const cccd = String(row[0]);
    if (!body.force && sheet.getLastRow() >= 2) {
      const colA = sheet.getRange(2, 1, sheet.getLastRow() - 1, 1).getValues();
      const exists = colA.some(function (r) { return String(r[0]) === cccd; });
      if (exists) {
        return { result: 'duplicate' };
      }
    }
    sheet.appendRow(row);
    return { result: 'appended' };
  } catch (err) {
    return { result: 'error', message: String(err) };
  }
}

function _json(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
