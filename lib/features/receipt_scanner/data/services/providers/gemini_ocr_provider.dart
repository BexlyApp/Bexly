import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/config/llm_config.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';

class GeminiOcrProvider implements OcrProvider {
  GeminiOcrProvider();

  @override
  String get providerName => 'Gemini';

  @override
  bool get isConfigured => LLMDefaultConfig.proxyAccessToken != null;

  @override
  Future<ReceiptScanResult> analyzeReceipt({
    required Uint8List imageBytes,
    String? additionalPrompt,
  }) async {
    final headers = LLMDefaultConfig.proxyHeaders;
    if (headers == null) {
      throw Exception('Not authenticated — please sign in to use receipt scanning.');
    }

    final String base64Image = base64Encode(imageBytes);
    final String prompt = _buildPrompt(additionalPrompt);

    int retryCount = 0;
    const maxRetries = 2;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse(LLMDefaultConfig.proxyUrl),
              headers: headers,
              body: jsonEncode({
                'provider': 'gemini',
                'action': 'ocr',
                'model': LLMDefaultConfig.geminiModel,
                'image': base64Image,
                'messages': [
                  {'role': 'user', 'content': prompt},
                ],
                'temperature': 0.2,
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);

          if (jsonResponse['error'] != null) {
            throw Exception(jsonResponse['error']);
          }

          String content = jsonResponse['content'] as String;
          content = _sanitizeResponse(content);

          final resultJson = jsonDecode(content);
          _validateResponse(resultJson);

          Log.i('Receipt scanned: ${resultJson['merchant']}',
              label: 'GeminiOCR');

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
          String apiErrorMessage = 'API Error: ${response.statusCode}';
          try {
            final errorJson = jsonDecode(response.body);
            if (errorJson['error'] != null) {
              apiErrorMessage = 'API Error: ${errorJson['error']}';
            }
          } catch (_) {}
          throw Exception(apiErrorMessage);
        }
      } on FormatException catch (e) {
        lastError = Exception('Failed to parse response: ${e.message}');
        Log.e('FormatException retry $retryCount: $e', label: 'GeminiOCR');
      } on TimeoutException catch (e) {
        lastError = Exception('Request timed out: ${e.message}');
        Log.e('TimeoutException retry $retryCount: $e', label: 'GeminiOCR');
      } catch (e) {
        lastError = Exception('Failed to analyze receipt: $e');
        Log.e('Exception retry $retryCount: $e', label: 'GeminiOCR');
      }

      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    throw lastError ??
        Exception('Failed after $maxRetries attempts');
  }

  @override
  Future<List<ReceiptScanResult>> analyzeScreenshot({
    required Uint8List imageBytes,
  }) async {
    final headers = LLMDefaultConfig.proxyHeaders;
    if (headers == null) {
      throw Exception('Not authenticated — please sign in to use receipt scanning.');
    }

    final String base64Image = base64Encode(imageBytes);
    final today = DateTime.now().toIso8601String().split('T')[0];
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

    final prompt = '''
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
- Extract ALL transactions, not just the first
- Return ONLY valid JSON, no markdown, no explanation
''';

    int retryCount = 0;
    const maxRetries = 2;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse(LLMDefaultConfig.proxyUrl),
              headers: headers,
              body: jsonEncode({
                'provider': 'gemini',
                'action': 'ocr',
                'model': LLMDefaultConfig.geminiModel,
                'image': base64Image,
                'messages': [
                  {'role': 'user', 'content': prompt},
                ],
                'temperature': 0.2,
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['error'] != null) {
            throw Exception(jsonResponse['error']);
          }

          String content = jsonResponse['content'] as String;
          content = _sanitizeScreenshotResponse(content);
          final parsed = jsonDecode(content);

          if (parsed is List) {
            Log.i('Screenshot: extracted ${parsed.length} transactions',
                label: 'GeminiOCR');
            return parsed
                .map((e) => ReceiptScanResult.fromJson(e as Map<String, dynamic>)
                    .copyWithImage(imageBytes))
                .toList();
          } else if (parsed is Map<String, dynamic>) {
            Log.i('Screenshot: single transaction', label: 'GeminiOCR');
            return [ReceiptScanResult.fromJson(parsed).copyWithImage(imageBytes)];
          }

          throw Exception('Unexpected response format');
        } else {
          throw Exception('API Error: ${response.statusCode}');
        }
      } on FormatException catch (e) {
        lastError = Exception('Failed to parse: ${e.message}');
      } on TimeoutException catch (e) {
        lastError = Exception('Timed out: ${e.message}');
      } catch (e) {
        lastError = Exception('Failed: $e');
      }

      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    throw lastError ?? Exception('Failed after $maxRetries attempts');
  }

  String _sanitizeScreenshotResponse(String content) {
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
      final arrayEnd = content.lastIndexOf(']');
      if (arrayEnd > arrayStart) {
        content = content.substring(arrayStart, arrayEnd + 1);
      }
    } else if (objStart != -1) {
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
- amount must be a number WITHOUT currency symbols or formatting (e.g., 1275000 not \$1,275,000)
- currency must be ISO code (VND for Vietnamese Dong, USD for US Dollar, etc.)
- Detect currency from context (language, location, formatting)
- If Vietnamese text or location → use VND
- merchant field must be a MEANINGFUL DESCRIPTION of the transaction, NOT just the store name
  Examples for Vietnamese:
  * Food & Dining: "Ăn tối tại [Store Name]", "Ăn trưa tại [Store Name]", "Cà phê tại [Store Name]"
  * Shopping: "Mua sắm tại [Store Name]", "Mua [item] tại [Store Name]"
  * Transportation: "Đi taxi [Route]", "Grab từ [A] đến [B]"
  * Entertainment: "Xem phim tại [Cinema]", "Karaoke tại [Store Name]"
  Examples for English:
  * Food & Dining: "Dinner at [Store Name]", "Lunch at [Store Name]", "Coffee at [Store Name]"
  * Shopping: "Shopping at [Store Name]", "Bought [item] at [Store Name]"
  * Transportation: "Taxi ride [Route]", "Uber from [A] to [B]"
  * Use proper Title Case (e.g., "Ăn tối tại Ẩm Thực Phú Long" NOT "ĂN TỐI TẠI ÂM THỰC PHÚ LONG")
  * Infer meal time from receipt time if available (sáng/trưa/tối for Vietnamese, breakfast/lunch/dinner for English)
- For banking app screenshots: extract the most recent/topmost transaction
- date must be YYYY-MM-DD format
- category must be one of the 7 types listed
- Return ONLY JSON, no markdown
''';

    if (additionalPrompt != null && additionalPrompt.isNotEmpty) {
      return '$basePrompt\n\nAdditional: $additionalPrompt';
    }

    return basePrompt;
  }

  String _sanitizeResponse(String content) {
    if (content.startsWith('```') && content.endsWith('```')) {
      content = content.substring(3, content.length - 3).trim();
      if (content.startsWith('json')) {
        content = content.substring(4).trim();
      }
    }

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

    final rawAmount = resultJson['amount'];
    if (rawAmount is! num && rawAmount is! String) {
      throw Exception('Invalid amount type');
    }
  }
}
