import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/features/receipt_scanner/data/services/receipt_scanner_service.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';

class SelectedOcrProviderNotifier extends Notifier<OcrProviderType> {
  @override
  OcrProviderType build() => OcrProviderType.gemini;

  void setProvider(OcrProviderType provider) => state = provider;
}

final selectedOcrProviderProvider = NotifierProvider<SelectedOcrProviderNotifier, OcrProviderType>(
  SelectedOcrProviderNotifier.new,
);

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
  return ReceiptScannerService.fromType(type: providerType);
});
