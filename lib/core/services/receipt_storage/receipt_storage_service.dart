import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:pockaw/core/utils/logger.dart';
import 'package:uuid/uuid.dart';

class ReceiptUploadResult {
  final String storagePath;
  final String downloadUrl;

  ReceiptUploadResult({required this.storagePath, required this.downloadUrl});
}

class ReceiptStorageService {
  final FirebaseStorage _storage;

  ReceiptStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<ReceiptUploadResult> uploadReceipt({
    required File file,
    required String userId,
    required DateTime date,
  }) async {
    final String monthFolder = DateFormat('yyyy-MM').format(date);
    final String ext = _extensionOf(file.path);
    final String id = const Uuid().v4();
    final String path =
        'receipts/$userId/$monthFolder/receipt_$id$ext';

    final SettableMetadata metadata = SettableMetadata(
      contentType: _contentTypeOf(ext),
      cacheControl: 'public, max-age=31536000',
    );

    final Reference ref = _storage.ref().child(path);
    Log.i('Uploading receipt to $path', label: 'storage');
    await ref.putFile(file, metadata);
    final String url = await ref.getDownloadURL();
    Log.i('Uploaded receipt. URL: $url', label: 'storage');
    return ReceiptUploadResult(storagePath: path, downloadUrl: url);
  }

  String _extensionOf(String path) {
    final int dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    return path.substring(dot).toLowerCase();
  }

  String _contentTypeOf(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }
}



