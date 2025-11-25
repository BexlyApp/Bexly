import 'dart:typed_data';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';

/// Abstract base class for OCR providers
abstract class OcrProvider {
  Future<ReceiptScanResult> analyzeReceipt({
    required Uint8List imageBytes,
    String? additionalPrompt,
  });

  String get providerName;
  bool get isConfigured;
}

enum OcrProviderType {
  gemini,
  openai,
  claude,
}
