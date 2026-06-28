import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<List<String>> recognizeLines(InputImage image) async {
    final result = await _recognizer.processImage(image);
    final lines = <String>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        lines.add(line.text);
      }
    }
    return lines;
  }

  void dispose() => _recognizer.close();
}
