import 'dart:typed_data';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';

/// Abstract base class for OCR providers
abstract class OcrProvider {
  Future<ReceiptScanResult> analyzeReceipt({
    required Uint8List imageBytes,
    String? additionalPrompt,
  });

  /// Analyze an image that may contain multiple transactions (e.g., banking app screenshot).
  /// Returns a list of results. For single receipts, returns a list with one item.
  /// Default implementation calls analyzeReceipt() and wraps in a list.
  Future<List<ReceiptScanResult>> analyzeScreenshot({
    required Uint8List imageBytes,
  }) async {
    final result = await analyzeReceipt(imageBytes: imageBytes);
    return [result];
  }

  String get providerName;
  bool get isConfigured;
}

enum OcrProviderType {
  dosAi,
  gemini,
  openai,
  claude,
}
