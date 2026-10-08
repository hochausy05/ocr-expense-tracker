import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  const ImageStorageService();

  Future<String> storeReceiptImage(File source) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final receiptsDirectory = Directory(
      path.join(documentsDirectory.path, 'receipts'),
    );
    await receiptsDirectory.create(recursive: true);

    final extension = path.extension(source.path);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final nonce = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    var suffix = 0;
    late File destination;

    do {
      final filename = suffix == 0
          ? 'receipt_${timestamp}_$nonce$extension'
          : 'receipt_${timestamp}_${nonce}_$suffix$extension';
      destination = File(path.join(receiptsDirectory.path, filename));
      suffix++;
    } while (await destination.exists());

    try {
      final storedFile = await source.copy(destination.path);
      return storedFile.path;
    } catch (_) {
      try {
        if (await destination.exists()) await destination.delete();
      } on FileSystemException {
        // Preserve the original copy error.
      }
      rethrow;
    }
  }
}
