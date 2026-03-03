import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/config/llm_config.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';

class OpenAiOcrProvider implements OcrProvider {
  OpenAiOcrProvider();

  @override
  String get providerName => 'OpenAI GPT-4o';

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

    try {
      final response = await http.post(
        Uri.parse(LLMDefaultConfig.proxyUrl),
        headers: headers,
        body: jsonEncode({
          'provider': 'openai',
          'action': 'ocr',
          'model': 'gpt-4o',
          'image': base64Image,
          'messages': [
            {'role': 'user', 'content': _buildPrompt(additionalPrompt)},
          ],
          'temperature': 0.2,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['error'] != null) {
          throw Exception(jsonResponse['error']);
        }

        String content = jsonResponse['content'] as String;
        final resultJson = jsonDecode(content);
        Log.i('Receipt scanned: ${resultJson['merchant']}', label: 'OpenAI_OCR');

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
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'API Error: ${response.statusCode}');
      }
    } catch (e) {
      Log.e('OpenAI OCR error: $e', label: 'OpenAI_OCR');
      rethrow;
    }
  }

  String _buildPrompt(String? additionalPrompt) {
    return '''
Analyze this receipt and extract JSON:
{"amount": <number>, "currency": "ISO code like VND/USD", "merchant": "meaningful transaction description", "category": "Food & Dining|Transportation|Shopping|Entertainment|Healthcare|Utilities|Other", "date": "YYYY-MM-DD", "payment_method": "Cash|Credit Card|Debit Card|QR Code|E-Wallet|Other", "items": ["item1"], "tax_amount": "string", "tip_amount": "string"}

IMPORTANT:
- merchant must be a meaningful description, NOT just store name
- Vietnamese examples: "Ăn tối tại [Store]", "Ăn trưa tại [Store]", "Cà phê tại [Store]", "Mua sắm tại [Store]"
- English examples: "Dinner at [Store]", "Lunch at [Store]", "Coffee at [Store]", "Shopping at [Store]"
- Use Title Case (e.g., "Ăn tối tại Ẩm Thực Phú Long" NOT "ĂN TỐI TẠI ÂM THỰC PHÚ LONG")
- Infer meal time from receipt time if available
Return ONLY JSON.''';
  }
}
