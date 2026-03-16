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

  @override
  Future<List<ReceiptScanResult>> analyzeScreenshot({
    required Uint8List imageBytes,
  }) async {
    if (!isConfigured) {
      throw Exception('DOS AI not configured — missing endpoint or API key.');
    }

    final String base64Image = base64Encode(imageBytes);
    final endpoint = LLMDefaultConfig.customEndpoint;
    final timeout = LLMDefaultConfig.customVisionTimeoutSeconds;

    Log.d(
      'Screenshot OCR: ${(imageBytes.length / 1024).toStringAsFixed(0)}KB image, '
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
                    {'type': 'text', 'text': _buildScreenshotPrompt()},
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
              'max_tokens': 2048,
              'enable_thinking': false,
            }),
          )
          .timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String content =
            jsonResponse['choices'][0]['message']['content'] as String;

        content = _sanitizeScreenshotResponse(content);
        final parsed = jsonDecode(content);

        if (parsed is List) {
          Log.i('Screenshot: extracted ${parsed.length} transactions',
              label: 'DosAI_OCR');
          return parsed
              .map((e) => _parseResult(e as Map<String, dynamic>, imageBytes))
              .toList();
        } else if (parsed is Map<String, dynamic>) {
          Log.i('Screenshot: single transaction (receipt)',
              label: 'DosAI_OCR');
          return [_parseResult(parsed, imageBytes)];
        }

        throw Exception('Unexpected response format');
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
      Log.e('DOS AI Screenshot OCR error: $e', label: 'DosAI_OCR');
      rethrow;
    }
  }

  ReceiptScanResult _parseResult(Map<String, dynamic> json, Uint8List imageBytes) {
    return ReceiptScanResult(
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] as String?,
      category: (json['category'] as String?) ?? 'Other',
      date: (json['date'] as String?) ?? DateTime.now().toIso8601String().split('T')[0],
      merchant: (json['merchant'] as String?) ?? 'Unknown',
      paymentMethod: (json['payment_method'] as String?) ?? 'Bank Transfer',
      items: json['items'] is List
          ? (json['items'] as List<dynamic>).cast<String>()
          : <String>[],
      taxAmount: json['tax_amount'] as String?,
      tipAmount: json['tip_amount'] as String?,
      imageBytes: imageBytes,
    );
  }

  String _buildScreenshotPrompt() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    return '''
Analyze this image and extract ALL transaction information.

CASE 1 — Banking app screenshot (list of transactions):
Return a JSON ARRAY of ALL visible transactions:
[
  {"amount": 261590, "currency": "VND", "merchant": "Apple.com/Bill", "category": "Entertainment", "date": "$today", "payment_method": "Bank Transfer", "items": []},
  {"amount": 9000, "currency": "VND", "merchant": "Grab Taxi", "category": "Transportation", "date": "$today", "payment_method": "Bank Transfer", "items": []}
]

CASE 2 — Receipt or invoice (single transaction):
Return a single JSON OBJECT:
{"amount": 5727200, "currency": "VND", "merchant": "Restaurant Dinner", "category": "Food & Dining", "date": "$today", "payment_method": "Cash", "items": ["Item 1"]}

RULES:
- amount: number only, NO currency symbols, NO dots/commas (e.g., 261590 not 261.590)
- currency: ISO code from context (VND, USD, etc.)
- merchant: clean readable name (Title Case, complete truncated words)
- category: one of [Food & Dining, Transportation, Shopping, Entertainment, Healthcare, Utilities, Software, Streaming, Education, Housing, Other]
- date: YYYY-MM-DD. Use "$today" for "HÔM NAY"/"TODAY", "$yesterday" for "HÔM QUA"/"YESTERDAY"
- payment_method: one of [Cash, Credit Card, Debit Card, QR Code, E-Wallet, Bank Transfer, Other]
- Extract ALL transactions, not just the first or most prominent
- Return ONLY valid JSON, no markdown, no explanation
''';
  }

  String _sanitizeScreenshotResponse(String content) {
    // Remove thinking tags
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

    // Detect array or object
    final arrayStart = content.indexOf('[');
    final objStart = content.indexOf('{');

    if (arrayStart != -1 && (objStart == -1 || arrayStart < objStart)) {
      // Array response
      final arrayEnd = content.lastIndexOf(']');
      if (arrayEnd > arrayStart) {
        content = content.substring(arrayStart, arrayEnd + 1);
      }
    } else if (objStart != -1) {
      // Object response
      final objEnd = content.lastIndexOf('}');
      if (objEnd > objStart) {
        content = content.substring(objStart, objEnd + 1);
      }
    }

    return content;
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
