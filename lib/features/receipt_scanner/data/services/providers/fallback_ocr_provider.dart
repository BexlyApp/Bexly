import 'dart:typed_data';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';

/// OCR provider that tries a primary provider first, then falls back
/// to a secondary provider on failure.
class FallbackOcrProvider implements OcrProvider {
  final OcrProvider _primary;
  final OcrProvider _fallback;

  /// Called when primary fails and fallback is attempted.
  final void Function(String providerName)? onFallback;

  FallbackOcrProvider({
    required OcrProvider primary,
    required OcrProvider fallback,
    this.onFallback,
  })  : _primary = primary,
        _fallback = fallback;

  @override
  String get providerName => '${_primary.providerName} → ${_fallback.providerName}';

  @override
  bool get isConfigured => _primary.isConfigured || _fallback.isConfigured;

  @override
  Future<ReceiptScanResult> analyzeReceipt({
    required Uint8List imageBytes,
    String? additionalPrompt,
  }) async {
    // Try primary first if configured
    if (_primary.isConfigured) {
      try {
        Log.d('Trying ${_primary.providerName} for OCR...', label: 'FallbackOCR');
        return await _primary.analyzeReceipt(
          imageBytes: imageBytes,
          additionalPrompt: additionalPrompt,
        );
      } catch (e) {
        Log.w(
          '${_primary.providerName} failed: $e — falling back to ${_fallback.providerName}',
          label: 'FallbackOCR',
        );
        onFallback?.call(_fallback.providerName);
      }
    }

    // Fallback
    if (!_fallback.isConfigured) {
      throw Exception('Neither ${_primary.providerName} nor ${_fallback.providerName} is configured.');
    }

    Log.d('Using ${_fallback.providerName} for OCR...', label: 'FallbackOCR');
    return await _fallback.analyzeReceipt(
      imageBytes: imageBytes,
      additionalPrompt: additionalPrompt,
    );
  }

  @override
  Future<List<ReceiptScanResult>> analyzeScreenshot({
    required Uint8List imageBytes,
  }) async {
    if (_primary.isConfigured) {
      try {
        Log.d('Trying ${_primary.providerName} for screenshot OCR...', label: 'FallbackOCR');
        return await _primary.analyzeScreenshot(imageBytes: imageBytes);
      } catch (e) {
        Log.w(
          '${_primary.providerName} screenshot failed: $e — falling back to ${_fallback.providerName}',
          label: 'FallbackOCR',
        );
        onFallback?.call(_fallback.providerName);
      }
    }

    if (!_fallback.isConfigured) {
      throw Exception('Neither ${_primary.providerName} nor ${_fallback.providerName} is configured.');
    }

    Log.d('Using ${_fallback.providerName} for screenshot OCR...', label: 'FallbackOCR');
    return await _fallback.analyzeScreenshot(imageBytes: imageBytes);
  }
}
