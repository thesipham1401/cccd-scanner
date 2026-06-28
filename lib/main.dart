import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/sheets_service.dart';
import 'services/ocr_service.dart';
import 'services/capture_service.dart';
import 'services/offline_queue.dart';
import 'services/sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/review_screen.dart';

// TODO: replace with the company's shared spreadsheet ID (from the sheet URL).
const String kSpreadsheetId = 'REPLACE_WITH_SHEET_ID';

// TODO: set after Google Cloud setup — Web OAuth client ID (needed on Android
// for Sheets authorization). See docs/superpowers/notes/google-setup.md.
const String? kServerClientId = null;

void main() => runApp(const CccdScannerApp());

class CccdScannerApp extends StatefulWidget {
  const CccdScannerApp({super.key});
  @override
  State<CccdScannerApp> createState() => _CccdScannerAppState();
}

class _CccdScannerAppState extends State<CccdScannerApp> {
  final auth = AuthService(serverClientId: kServerClientId);
  final ocr = OcrService();
  final capture = CaptureService();
  final queue = OfflineQueue();
  late final sheets = SheetsService(auth, kSpreadsheetId);
  late final sync = SyncService(queue, sheets);

  bool _checked = false;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    sync.start();
    auth.signInSilently().then((acc) {
      if (!mounted) return;
      setState(() {
        _signedIn = acc != null;
        _checked = true;
      });
      if (_signedIn) sheets.ensureHeader();
    }).catchError((_) {
      if (mounted) setState(() => _checked = true);
    });
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
      home: !_checked
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_signedIn ? _capture() : _login()),
    );
  }

  Widget _login() => LoginScreen(
        auth: auth,
        onSignedIn: () async {
          await sheets.ensureHeader();
          setState(() => _signedIn = true);
        },
      );

  Widget _capture() => Navigator(
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
      );
}
