import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/config/llm_config.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';

/// OCR provider that sends images directly to DOS AI (vLLM) using
/// OpenAI-compatible vision API format.
/// Requires a VL (Vision-Language) model on the server.
class DosAiOcrProvider implements OcrProvider {
  DosAiOcrProvider();

  @override
  String get providerName => 'DOS AI';

  @override
  bool get isConfigured =>
      LLMDefaultConfig.customEndpoint.isNotEmpty &&
      LLMDefaultConfig.customApiKey.isNotEmpty;

  @override
  Future<ReceiptScanResult> analyzeReceipt({
    required Uint8List imageBytes,
    String? additionalPrompt,
  }) async {
    if (!isConfigured) {
      throw Exception('DOS AI not configured — missing endpoint or API key.');
    }

    final String base64Image = base64Encode(imageBytes);
    final String prompt = _buildPrompt(additionalPrompt);
    final endpoint = LLMDefaultConfig.customEndpoint;
    final timeout = LLMDefaultConfig.customVisionTimeoutSeconds;

    Log.d(
      'OCR request: ${(imageBytes.length / 1024).toStringAsFixed(0)}KB image, '
      'model=${LLMDefaultConfig.customModel}, timeout=${timeout}s',
      label: 'DosAI_OCR',
    );

    try {
      final response = await http
          .post(
            Uri.parse('$endpoint/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${LLMDefaultConfig.customApiKey}',
              'User-Agent': 'Bexly/1.0 (Dart; Flutter)',
            },
            body: jsonEncode({
              'model': LLMDefaultConfig.customModel,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': prompt},
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:image/jpeg;base64,$base64Image',
                      },
                    },
                  ],
                },
              ],
              'temperature': 0.2,
              'max_tokens': 1024,
              'enable_thinking': false,
            }),
          )
          .timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String content =
            jsonResponse['choices'][0]['message']['content'] as String;

        content = _sanitizeResponse(content);
        final resultJson = jsonDecode(content);
        _validateResponse(resultJson);

        Log.i('Receipt scanned via DOS AI: ${resultJson['merchant']}',
            label: 'DosAI_OCR');

        return ReceiptScanResult(
          amount: (resultJson['amount'] is num)
              ? (resultJson['amount'] as num).toDouble()
              : double.parse(resultJson['amount'].toString()),
          currency: resultJson['currency'] as String?,
          category: resultJson['category'] as String,
          date: resultJson['date'] as String,
          merchant: resultJson['merchant'] as String,
          paymentMethod: resultJson['payment_method'] as String,
          items: (resultJson['items'] as List<dynamic>).cast<String>(),
          taxAmount: resultJson['tax_amount'] as String?,
          tipAmount: resultJson['tip_amount'] as String?,
          imageBytes: imageBytes,
        );
      } else {
        String errorMsg = 'DOS AI OCR error: ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson['error'] != null) {
            final err = errorJson['error'];
            errorMsg = err is Map ? (err['message'] ?? errorMsg) : '$err';
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } on TimeoutException {
      throw Exception(
          'DOS AI timed out after ${timeout}s — falling back to Gemini.');
    } catch (e) {
      Log.e('DOS AI OCR error: $e', label: 'DosAI_OCR');
      rethrow;
    }
  }

  String _buildPrompt(String? additionalPrompt) {
    final basePrompt = '''
Analyze this image and extract transaction information in JSON format.

The image may be a receipt, invoice, bank statement screenshot, or banking app screenshot.
If multiple transactions are visible, extract the MOST RECENT or MOST PROMINENT one.

Return JSON:
{
  "amount": <total as number WITHOUT currency symbol>,
  "currency": "<ISO currency code like VND, USD, EUR>",
  "merchant": "<meaningful transaction description>",
  "category": "<Food & Dining | Transportation | Shopping | Entertainment | Healthcare | Utilities | Other>",
  "date": "<YYYY-MM-DD>",
  "payment_method": "<Cash | Credit Card | Debit Card | QR Code | E-Wallet | Bank Transfer | Other>",
  "items": ["<item 1>", "<item 2>"],
  "tax_amount": "<tax if available>",
  "tip_amount": "<tip if available>"
}

IMPORTANT:
- amount must be a number WITHOUT currency symbols (e.g., 1275000 not 1,275,000đ)
- Detect currency from context (Vietnamese text → VND, etc.)
- merchant: meaningful description like "Ăn tối tại [Store]", "Dinner at [Store]"
- Use proper Title Case
- date must be YYYY-MM-DD format
- Return ONLY JSON, no markdown
''';

    if (additionalPrompt != null && additionalPrompt.isNotEmpty) {
      return '$basePrompt\n\nAdditional: $additionalPrompt';
    }
    return basePrompt;
  }

  String _sanitizeResponse(String content) {
    // Remove thinking tags if present
    final thinkEnd = content.indexOf('</think>');
    if (thinkEnd != -1) {
      content = content.substring(thinkEnd + 8).trim();
    }

    // Remove markdown code blocks
    if (content.contains('```json')) {
      content = content.split('```json')[1].split('```')[0].trim();
    } else if (content.startsWith('```') && content.endsWith('```')) {
      content = content.substring(3, content.length - 3).trim();
    }

    // Extract JSON object
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      content = content.substring(jsonStart, jsonEnd + 1);
    }

    return content;
  }

  void _validateResponse(Map<String, dynamic> resultJson) {
    final requiredFields = [
      'amount',
      'category',
      'date',
      'merchant',
      'payment_method',
      'items'
    ];
    for (final field in requiredFields) {
      if (resultJson[field] == null) {
        throw Exception('Missing required field: $field');
      }
    }
  }
}
