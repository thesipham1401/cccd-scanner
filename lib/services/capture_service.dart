import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CaptureService {
  final ImagePicker _picker = ImagePicker();

  Future<InputImage?> pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return InputImage.fromFilePath(file.path);
  }

  Future<InputImage?> captureFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file == null) return null;
    return InputImage.fromFilePath(file.path);
  }
}
