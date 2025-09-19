import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TemporaryStorageDirectory {
  static Future<Directory?> getDirectory() async {
    if (kIsWeb) {
      // Web doesn't use file system directories
      return null;
    }

    Directory? dir;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getTemporaryDirectory();
    }
    return dir;
  }
}
