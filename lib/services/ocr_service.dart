import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  const OcrService();

  Future<String> recognizeText(String imagePath) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw FileSystemException('Receipt image was not found', imagePath);
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(image);
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
