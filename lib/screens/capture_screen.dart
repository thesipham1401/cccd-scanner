import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/cccd_data.dart';
import '../core/qr_parser.dart';
import '../core/full_ocr_parser.dart';
import '../services/capture_service.dart';
import '../services/ocr_service.dart';
import '../widgets/card_frame_overlay.dart';

class CaptureScreen extends StatefulWidget {
  final CaptureService capture;
  final OcrService ocr;
  final void Function(CccdData data, {bool fromFallback}) onExtracted;
  const CaptureScreen({
    super.key,
    required this.capture,
    required this.ocr,
    required this.onExtracted,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false;

  void _onQrDetected(BarcodeCapture cap) {
    if (_handling) return;
    final raw = cap.barcodes.isEmpty ? null : cap.barcodes.first.rawValue;
    if (raw == null) return;
    _handling = true;
    try {
      final data = parseQrFront(raw);
      widget.onExtracted(data, fromFallback: false);
    } catch (_) {
      _handling = false; // not a valid CCCD QR; keep scanning
    }
  }

  Future<void> _importFromGallery() async {
    if (_handling) return;
    _handling = true;
    try {
      final image = await widget.capture.pickFromGallery();
      if (image == null) {
        _handling = false;
        return;
      }
      final lines = await widget.ocr.recognizeLines(image);
      // Gallery photos rarely decode a QR, so go straight to full OCR fallback.
      final data = parseFullFront(lines);
      widget.onExtracted(data, fromFallback: true);
    } finally {
      _handling = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét CCCD')),
      body: Stack(children: [
        MobileScanner(controller: _controller, onDetect: _onQrDetected),
        const CardFrameOverlay(),
      ]),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _importFromGallery,
            icon: const Icon(Icons.photo_library),
            label:
                const Text('Chọn ảnh từ máy', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}
