import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/config/llm_config.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';

class GeminiOcrProvider implements OcrProvider {
  final String apiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  String get _model => LLMDefaultConfig.geminiModel;

  GeminiOcrProvider({required this.apiKey});

  @override
  String get providerName => 'Gemini';

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  @override
  Future<ReceiptScanResult> analyzeReceipt({
    required Uint8List imageBytes,
    String? additionalPrompt,
  }) async {
    if (!isConfigured) {
      throw Exception('Gemini API key not configured');
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
              Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                      {
                        'inlineData': {
                          'mimeType': 'image/jpeg',
                          'data': base64Image,
                        },
                      },
                    ],
                  },
                ],
                'generationConfig': {
                  'response_mime_type': 'application/json',
                  'temperature': 0.2,
                },
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);

          if (jsonResponse['candidates'] == null ||
              jsonResponse['candidates'].isEmpty ||
              jsonResponse['candidates'][0]['content'] == null ||
              jsonResponse['candidates'][0]['content']['parts'] == null ||
              jsonResponse['candidates'][0]['content']['parts'].isEmpty) {
            throw Exception('Invalid API response structure');
          }

          String content =
              jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          content = _sanitizeResponse(content);

          final resultJson = jsonDecode(content);
          _validateResponse(resultJson);

          Log.i('Receipt scanned: ${resultJson['merchant']}',
              label: 'GeminiOCR');

          // Create result with imageBytes included
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
            imageBytes: imageBytes, // Pass the receipt image
          );
        } else {
          String apiErrorMessage = 'API Error: ${response.statusCode}';
          try {
            final errorJson = jsonDecode(response.body);
            if (errorJson['error'] != null &&
                errorJson['error']['message'] != null) {
              apiErrorMessage = 'API Error: ${errorJson['error']['message']}';
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

  String _buildPrompt(String? additionalPrompt) {
    final basePrompt = '''
Analyze this receipt and extract information in JSON format:

{
  "amount": <total as number WITHOUT currency symbol>,
  "currency": "<ISO currency code like VND, USD, EUR>",
  "merchant": "<meaningful transaction description>",
  "category": "<Food & Dining | Transportation | Shopping | Entertainment | Healthcare | Utilities | Other>",
  "date": "<YYYY-MM-DD>",
  "payment_method": "<Cash | Credit Card | Debit Card | QR Code | E-Wallet | Other>",
  "items": ["<item 1>", "<item 2>"],
  "tax_amount": "<tax if available>",
  "tip_amount": "<tip if available>"
}

IMPORTANT:
- amount must be a number WITHOUT currency symbols or formatting (e.g., 1275000 not \$1,275,000)
- currency must be ISO code (VND for Vietnamese Dong, USD for US Dollar, etc.)
- Detect currency from receipt context (language, location, formatting)
- If Vietnamese text or location → use VND
- merchant field must be a MEANINGFUL DESCRIPTION of the transaction, NOT just the store name
  Examples for Vietnamese receipts:
  * Food & Dining: "Ăn tối tại [Store Name]", "Ăn trưa tại [Store Name]", "Cà phê tại [Store Name]"
  * Shopping: "Mua sắm tại [Store Name]", "Mua [item] tại [Store Name]"
  * Transportation: "Đi taxi [Route]", "Grab từ [A] đến [B]"
  * Entertainment: "Xem phim tại [Cinema]", "Karaoke tại [Store Name]"
  Examples for English receipts:
  * Food & Dining: "Dinner at [Store Name]", "Lunch at [Store Name]", "Coffee at [Store Name]"
  * Shopping: "Shopping at [Store Name]", "Bought [item] at [Store Name]"
  * Transportation: "Taxi ride [Route]", "Uber from [A] to [B]"
  * Use proper Title Case (e.g., "Ăn tối tại Ẩm Thực Phú Long" NOT "ĂN TỐI TẠI ÂM THỰC PHÚ LONG")
  * Infer meal time from receipt time if available (sáng/trưa/tối for Vietnamese, breakfast/lunch/dinner for English)
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
