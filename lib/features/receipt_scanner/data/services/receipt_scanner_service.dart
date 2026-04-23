import 'dart:typed_data';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/gemini_ocr_provider.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/openai_ocr_provider.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/claude_ocr_provider.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/dos_ai_ocr_provider.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/fallback_ocr_provider.dart';
import 'package:bexly/core/utils/logger.dart';

class ReceiptScannerService {
  final OcrProvider _provider;

  ReceiptScannerService({required OcrProvider provider}) : _provider = provider;

  factory ReceiptScannerService.dosAi() {
    return ReceiptScannerService(provider: DosAiOcrProvider());
  }

  factory ReceiptScannerService.gemini() {
    return ReceiptScannerService(provider: GeminiOcrProvider());
  }

  factory ReceiptScannerService.openai() {
    return ReceiptScannerService(provider: OpenAiOcrProvider());
  }

  factory ReceiptScannerService.claude() {
    return ReceiptScannerService(provider: ClaudeOcrProvider());
  }

  /// DOS AI first, fallback to Gemini on timeout/error.
  factory ReceiptScannerService.dosAiWithGeminiFallback({
    void Function(String providerName)? onFallback,
  }) {
    return ReceiptScannerService(
      provider: FallbackOcrProvider(
        primary: DosAiOcrProvider(),
        fallback: GeminiOcrProvider(),
        onFallback: onFallback,
      ),
    );
  }

  factory ReceiptScannerService.fromType({required OcrProviderType type}) {
    switch (type) {
      case OcrProviderType.dosAi:
        return ReceiptScannerService.dosAi();
      case OcrProviderType.gemini:
        return ReceiptScannerService.gemini();
      case OcrProviderType.openai:
        return ReceiptScannerService.openai();
      case OcrProviderType.claude:
        return ReceiptScannerService.claude();
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

  /// Analyze a screenshot that may contain multiple transactions.
  /// Returns a list of results (single item for receipts, multiple for banking screenshots).
  Future<List<ReceiptScanResult>> analyzeScreenshot({
    required Uint8List imageBytes,
  }) async {
    if (!_provider.isConfigured) {
      throw Exception('${_provider.providerName} not configured');
    }

    Log.i('Analyzing screenshot with ${_provider.providerName}',
        label: 'ReceiptScanner');

    final results = await _provider.analyzeScreenshot(imageBytes: imageBytes);

    Log.i('Screenshot: ${results.length} transactions extracted',
        label: 'ReceiptScanner');

    return results;
  }

  String get providerName => _provider.providerName;
  bool get isConfigured => _provider.isConfigured;
}
