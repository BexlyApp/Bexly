import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:receiptscanner/core/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/model.dart';
import '../../provider/provider.dart';

class ReceiptScannerScreen extends StatelessWidget {
  const ReceiptScannerScreen({super.key});

  static const Color _scaffoldBackgroundColor = Color(0xFFF5F7FA);
  static const Color _appBarTitleColor = Color(0xFF2E7D32);
  static const Color _appBarIconColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Receipt Expense Scanner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: _appBarTitleColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, color: _appBarIconColor),
            onPressed: () => Navigator.pushNamed(context, '/receipt_scan_history'),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.0),
        child: ReceiptScannerModule(),
      ),
    );
  }
}

class ReceiptScannerModule extends StatefulWidget {
  const ReceiptScannerModule({super.key});

  @override
  State<ReceiptScannerModule> createState() => _ReceiptScannerModuleState();
}

class _ReceiptScannerModuleState extends State<ReceiptScannerModule> {
  static const Color _primaryColor = Color(0xFF4CAF50);
  static const Color _lightPrimaryColor = Color(0xFFC8E6C9);
  static const Color _accentColor = Color(0xFF2E7D32);
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _textColorPrimary = Color(0xFF333333);
  static const Color _textColorSecondary = Color(0xFF666666);
  static const Color _iconColorActive = _primaryColor;
  static const Color _iconColorInactive = Colors.grey;
  static const Color _errorColor = Color(0xFFD32F2F);
  static const Color _errorBackgroundColor = Color(0xFFFFEBEE);

  final String apiKey = ApiConfig.geminiApiKey;
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  bool _isProcessing = false;
  String? _errorMessage;
  ReceiptScanResult? _scanResult;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Receipt Expense Scanner',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: _textColorPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1.1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _selectedImageBytes != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 70,
                    color: _iconColorInactive,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Take or select a photo of a receipt',
                    style: TextStyle(
                      color: _textColorSecondary.withAlpha((0.9 * 255).toInt()),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text('Gallery'),
                onPressed: _pickImageFromGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lightPrimaryColor,
                  foregroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('Camera'),
                onPressed: _takePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lightPrimaryColor,
                  foregroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _selectedImageBytes != null && !_isProcessing ? _analyzeReceipt : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 52),
            elevation: 3,
            disabledBackgroundColor: _primaryColor.withAlpha((0.7 * 255).toInt()),
          ),
          child: _isProcessing
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          )
              : const Text('Scan Receipt'),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _errorBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _errorColor.withAlpha((0.7 * 255).toInt()),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: _errorColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: _errorColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_scanResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: _buildResultsCard(),
          ),
        SizedBox(height: 120,)
      ],
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value, {
        Color? valueColor,
        FontWeight? valueWeight,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _iconColorActive, size: 22),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _textColorPrimary,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor ?? _textColorSecondary,
                fontWeight: valueWeight ?? FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: _cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
                bottom: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildInfoRow(
                    Icons.store,
                    'Merchant',
                    _scanResult!.merchant,
                    valueWeight: FontWeight.w600,
                  ),
                  _buildInfoRow(
                    Icons.attach_money,
                    'Amount',
                    '\$${_scanResult!.amount.toStringAsFixed(2)}',
                    valueWeight: FontWeight.w500,
                  ),
                  _buildInfoRow(
                    Icons.category,
                    'Category',
                    _scanResult!.category,
                  ),
                  _buildInfoRow(
                    Icons.date_range,
                    'Date',
                    _scanResult!.date,
                  ),
                  _buildInfoRow(
                    Icons.credit_card,
                    'Payment Method',
                    _scanResult!.paymentMethod,
                  ),
                  if (_scanResult!.taxAmount != null)
                    _buildInfoRow(
                      Icons.receipt,
                      'Tax',
                      '\$${_scanResult!.taxAmount}',
                    ),
                  if (_scanResult!.tipAmount != null)
                    _buildInfoRow(
                      Icons.thumb_up,
                      'Tip',
                      '\$${_scanResult!.tipAmount}',
                    ),
                  Divider(
                    height: 22,
                    thickness: 0.8,
                    color: Colors.grey.shade200,
                  ),
                  Text(
                    'Purchased Items:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _scanResult!.items
                        .map(
                          (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: _primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: _textColorSecondary,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _scanResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to pick image: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _scanResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to take photo: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _analyzeReceipt() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _scanResult = null;
    });

    int retryCount = 0;
    const maxRetries = 2;
    bool success = false;

    while (retryCount < maxRetries && !success) {
      try {
        final String base64Image = base64Encode(_selectedImageBytes!);

        final response = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text': 'Analyze this receipt image and extract expense details:\n'
                        'Your response MUST be valid JSON following EXACTLY this format:\n'
                        '{\n'
                        '  "amount": number,\n'
                        '  "category": "string",\n'
                        '  "date": "string",\n'
                        '  "merchant": "string",\n'
                        '  "payment_method": "string",\n'
                        '  "items": ["string"],\n'
                        '  "tax_amount": "string",\n'
                        '  "tip_amount": "string"\n'
                        '}\n'
                        'Do NOT include any additional text or markdown formatting outside the JSON object.',
                  },
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
            },
          }),
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);

          if (jsonResponse['candidates'] == null ||
              jsonResponse['candidates'].isEmpty ||
              jsonResponse['candidates'][0]['content'] == null ||
              jsonResponse['candidates'][0]['content']['parts'] == null ||
              jsonResponse['candidates'][0]['content']['parts'].isEmpty) {
            throw Exception('Invalid API response structure: Missing candidates or content parts.');
          }

          String content = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          content = _sanitizeApiResponse(content);

          final resultJson = jsonDecode(content);
          _validateResponse(resultJson);

          if (mounted) {
            setState(() {
              _scanResult = ReceiptScanResult.fromJson(resultJson);
            });
          }

          if (mounted) {
            final provider = Provider.of<ReceiptScanProvider>(context, listen: false);
            await provider.saveScan(
              _scanResult!.merchant,
              _selectedImageBytes!,
              content,
              amount: _scanResult!.amount,
              category: _scanResult!.category,
              date: _scanResult!.date,
              merchant: _scanResult!.merchant,
              paymentMethod: _scanResult!.paymentMethod,
            );
          }

          success = true;
        } else {
          String apiErrorMessage = 'API Error: ${response.statusCode}';
          try {
            final errorJson = jsonDecode(response.body);
            if (errorJson['error'] != null && errorJson['error']['message'] != null) {
              apiErrorMessage = 'API Error: ${errorJson['error']['message']}';
            }
          } catch (_) {}
          throw Exception(apiErrorMessage);
        }
      } on FormatException {
        if (retryCount >= maxRetries - 1) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to parse API response. Please try again with a different receipt.';
            });
          }
        }
        await Future.delayed(const Duration(seconds: 1));
      } on TimeoutException {
        if (retryCount >= maxRetries - 1) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Request timed out. Please check your internet connection.';
            });
          }
        }
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        if (retryCount >= maxRetries - 1) {
          if (mounted) {
            setState(() {
              _errorMessage = 'An error occurred: ${e.toString()}';
            });
          }
        }
        await Future.delayed(const Duration(seconds: 1));
      } finally {
        retryCount++;
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _sanitizeApiResponse(String content) {
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
      throw Exception('Invalid amount type. Expected number or string.');
    }
  }
}