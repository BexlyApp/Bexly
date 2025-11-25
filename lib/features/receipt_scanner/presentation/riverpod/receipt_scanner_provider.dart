import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bexly/features/receipt_scanner/data/services/receipt_scanner_service.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';

final selectedOcrProviderProvider =
    StateProvider<OcrProviderType>((ref) => OcrProviderType.gemini);

final ocrProviderNameProvider = Provider<String>((ref) {
  final providerType = ref.watch(selectedOcrProviderProvider);
  switch (providerType) {
    case OcrProviderType.gemini:
      return 'Gemini 2.5 Flash';
    case OcrProviderType.openai:
      return 'OpenAI GPT-4o';
    case OcrProviderType.claude:
      return 'Claude Sonnet 4';
  }
});

final receiptScannerServiceProvider = Provider<ReceiptScannerService>((ref) {
  final providerType = ref.watch(selectedOcrProviderProvider);

  final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final openaiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final claudeKey = dotenv.env['CLAUDE_API_KEY'] ?? '';

  return ReceiptScannerService.fromType(
    type: providerType,
    apiKey: _getApiKey(providerType, geminiKey, openaiKey, claudeKey),
  );
});

String _getApiKey(
  OcrProviderType type,
  String geminiKey,
  String openaiKey,
  String claudeKey,
) {
  switch (type) {
    case OcrProviderType.gemini:
      return geminiKey;
    case OcrProviderType.openai:
      return openaiKey;
    case OcrProviderType.claude:
      return claudeKey;
  }
}
