import 'dart:typed_data';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/gemini_ocr_provider.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/openai_ocr_provider.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/claude_ocr_provider.dart';
import 'package:bexly/core/utils/logger.dart';

class ReceiptScannerService {
  final OcrProvider _provider;

  ReceiptScannerService({required OcrProvider provider}) : _provider = provider;

  factory ReceiptScannerService.gemini({required String apiKey}) {
    return ReceiptScannerService(provider: GeminiOcrProvider(apiKey: apiKey));
  }

  factory ReceiptScannerService.openai({required String apiKey}) {
    return ReceiptScannerService(provider: OpenAiOcrProvider(apiKey: apiKey));
  }

  factory ReceiptScannerService.claude({required String apiKey}) {
    return ReceiptScannerService(provider: ClaudeOcrProvider(apiKey: apiKey));
  }

  factory ReceiptScannerService.fromType({
    required OcrProviderType type,
    required String apiKey,
  }) {
    switch (type) {
      case OcrProviderType.gemini:
        return ReceiptScannerService.gemini(apiKey: apiKey);
      case OcrProviderType.openai:
        return ReceiptScannerService.openai(apiKey: apiKey);
      case OcrProviderType.claude:
        return ReceiptScannerService.claude(apiKey: apiKey);
    }
  }

  Future<ReceiptScanResult> analyzeReceipt({
    required Uint8List imageBytes,
    String? additionalPrompt,
  }) async {
    if (!_provider.isConfigured) {
      throw Exception('${_provider.providerName} not configured');
    }

    Log.i('Analyzing receipt with ${_provider.providerName}',
        label: 'ReceiptScanner');

    final result = await _provider.analyzeReceipt(
      imageBytes: imageBytes,
      additionalPrompt: additionalPrompt,
    );

    Log.i('Scanned: ${result.merchant} - \$${result.amount}',
        label: 'ReceiptScanner');

    return result;
  }

  String get providerName => _provider.providerName;
  bool get isConfigured => _provider.isConfigured;
}
