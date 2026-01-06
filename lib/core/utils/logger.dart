import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:bexly/core/utils/storage_directory.dart';

class Log {
  static void _console(
    dynamic message, {
    String label = 'log',
    bool logToFile = true,
  }) {
    String trimmedLabel = label.toLowerCase().replaceAll(' ', '_');
    if (kDebugMode) {
      log('$message', name: trimmedLabel);
      // Also print to stdout so it shows in logcat
      // ignore: avoid_print
      print('[$trimmedLabel] $message');
    }

    if (logToFile) {
      _writeLogToFile('[$trimmedLabel] $message');
    }
  }

  static void d(
    dynamic message, {
    String label = 'log',
    bool logToFile = true,
  }) {
    _console('$message', label: 'debug_$label', logToFile: logToFile);
  }

  static void i(
    dynamic message, {
    String label = 'log',
    bool logToFile = true,
  }) {
    _console('$message', label: 'info_$label', logToFile: logToFile);
  }

  static void w(
    dynamic message, {
    String label = 'log',
    bool logToFile = true,
  }) {
    _console('$message', label: 'warning_$label', logToFile: logToFile);
  }

  static void e(
    dynamic message, {
    String label = 'log',
    bool logToFile = true,
  }) {
    _console('$message', label: 'error_$label', logToFile: logToFile);
  }

  /// Writes a log message to a file in Downloads (Android) or Documents (iOS).
  /// Returns the file path for reference.
  static Future<void> _writeLogToFile(String message) async {
    final file = await getLogFile();
    if (file != null) {
      final now = DateTime.now().toIso8601String();
      await file.writeAsString('[$now] $message\n', mode: FileMode.append);

      // i(file.path, label: 'log file path', logToFile: false);
    }
  }

  static Future<File?> getLogFile() async {
    final dir = await TemporaryStorageDirectory.getDirectory();
    if (dir == null) return null;
    final file = File('${dir.path}/bexly_log.txt');
    return file;
  }
}
