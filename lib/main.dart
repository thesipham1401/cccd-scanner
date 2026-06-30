import 'package:flutter/material.dart';
import 'services/sheets_service.dart';
import 'services/ocr_service.dart';
import 'services/capture_service.dart';
import 'services/offline_queue.dart';
import 'services/sync_service.dart';
import 'screens/capture_screen.dart';
import 'screens/review_screen.dart';

// TODO: dán "Web app URL" lấy từ Apps Script (Triển khai → Ứng dụng web).
// Xem docs/apps-script/Code.gs và docs/superpowers/notes/apps-script-setup.md.
const String kScriptUrl = 'https://script.google.com/macros/s/AKfycbzrCtO5MF3Y9N_PtYttaKQo88byK_IBtVF_IXyNiTYrupmt9CRMesPKLzY2JyTFy4pV/exec';

// TODO: dán ĐÚNG chuỗi SECRET đã đặt trong Apps Script (Code.gs).
const String kSharedSecret = 'gUhHDyL4wSiwrCFRCTrhsgRn';

void main() => runApp(const CccdScannerApp());

class CccdScannerApp extends StatefulWidget {
  const CccdScannerApp({super.key});
  @override
  State<CccdScannerApp> createState() => _CccdScannerAppState();
}

class _CccdScannerAppState extends State<CccdScannerApp> {
  final ocr = OcrService();
  final capture = CaptureService();
  final queue = OfflineQueue();
  late final sheets = SheetsService(kScriptUrl, kSharedSecret);
  late final sync = SyncService(queue, sheets);

  @override
  void initState() {
    super.initState();
    sync.start();
  }

  @override
  void dispose() {
    ocr.dispose();
    sync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCCD Scanner',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (context) => CaptureScreen(
            capture: capture,
            ocr: ocr,
            onExtracted: (data, {bool fromFallback = false}) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ReviewScreen(
                  initial: data,
                  fromFallback: fromFallback,
                  sheets: sheets,
                  queue: queue,
                  onSaved: () => Navigator.of(context).pop(),
                ),
              ));
            },
          ),
        ),
      ),
    );
  }
}
