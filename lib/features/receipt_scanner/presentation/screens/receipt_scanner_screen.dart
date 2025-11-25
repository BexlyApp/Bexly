import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/receipt_scanner/data/services/providers/ocr_provider.dart';
import 'package:bexly/features/receipt_scanner/presentation/riverpod/receipt_scanner_provider.dart';
import 'package:bexly/core/utils/logger.dart';

class ReceiptScannerScreen extends HookConsumerWidget {
  const ReceiptScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedImageBytes = useState<Uint8List?>(null);
    final isProcessing = useState(false);
    final errorMessage = useState<String?>(null);
    final scanResult = useState<ReceiptScanResult?>(null);

    final selectedProvider = ref.watch(selectedOcrProviderProvider);
    final providerName = ref.watch(ocrProviderNameProvider);
    final scannerService = ref.watch(receiptScannerServiceProvider);

    final ImagePicker picker = ImagePicker();

    Future<void> _autoAnalyzeReceipt() async {
      if (selectedImageBytes.value == null) return;

      isProcessing.value = true;
      errorMessage.value = null;
      scanResult.value = null;

      try {
        if (!scannerService.isConfigured) {
          throw Exception(
              '$providerName not configured. Add API key to .env file.');
        }

        final result = await scannerService.analyzeReceipt(
          imageBytes: selectedImageBytes.value!,
        );

        scanResult.value = result;
      } catch (e) {
        errorMessage.value = e.toString();
        Log.e('Analyze error: $e', label: 'ReceiptScanner');
      } finally {
        isProcessing.value = false;
      }
    }

    Future<void> pickImageFromGallery() async {
      try {
        final XFile? pickedFile =
            await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          final bytes = await File(pickedFile.path).readAsBytes();
          selectedImageBytes.value = bytes;
          scanResult.value = null;
          errorMessage.value = null;
          // Auto-scan after picking image
          await _autoAnalyzeReceipt();
        }
      } catch (e) {
        errorMessage.value = 'Failed to pick image: ${e.toString()}';
        Log.e('Pick image error: $e', label: 'ReceiptScanner');
      }
    }

    Future<void> takePhoto() async {
      try {
        final XFile? pickedFile =
            await picker.pickImage(source: ImageSource.camera);
        if (pickedFile != null) {
          final bytes = await File(pickedFile.path).readAsBytes();
          selectedImageBytes.value = bytes;
          scanResult.value = null;
          errorMessage.value = null;
          // Auto-scan after taking photo
          await _autoAnalyzeReceipt();
        }
      } catch (e) {
        errorMessage.value = 'Failed to take photo: ${e.toString()}';
        Log.e('Take photo error: $e', label: 'ReceiptScanner');
      }
    }

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        centerTitle: true,
        actions: [
          PopupMenuButton<OcrProviderType>(
            icon: const Icon(Icons.settings),
            onSelected: (type) {
              ref.read(selectedOcrProviderProvider.notifier).state = type;
              errorMessage.value = null;
            },
            itemBuilder: (context) => [
              _buildMenuItem(OcrProviderType.gemini, 'Gemini 2.5 Flash',
                  selectedProvider),
              _buildMenuItem(
                  OcrProviderType.openai, 'OpenAI GPT-4o', selectedProvider),
              _buildMenuItem(
                  OcrProviderType.claude, 'Claude Sonnet 4', selectedProvider),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Provider indicator
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacing12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.spacing8),
                  Text('Using: $providerName',
                      style: AppTextStyles.body3
                          .copyWith(color: AppColors.primary)),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.spacing16),

            // Image preview
            AspectRatio(
              aspectRatio: 1.1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Stack(
                  children: [
                    if (selectedImageBytes.value != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.memory(
                            selectedImageBytes.value!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 70, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Take or select receipt photo',
                                style: AppTextStyles.body2
                                    .copyWith(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    // Loading overlay
                    if (isProcessing.value)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Scanning receipt...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.spacing16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: pickImageFromGallery,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: takePhoto,
                  ),
                ),
              ],
            ),

            if (errorMessage.value != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.spacing12),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: AppSpacing.spacing8),
                      Expanded(
                        child: Text(errorMessage.value!,
                            style: AppTextStyles.body3
                                .copyWith(color: Colors.red.shade700)),
                      ),
                    ],
                  ),
                ),
              ),

            if (scanResult.value != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.spacing16),
                child: _buildResultsCard(context, scanResult.value!),
              ),
                ],
              ),
            ),
          ),
          // Fixed bottom button when result is available
          if (scanResult.value != null)
            Builder(
              builder: (context) {
                Log.d('📍 CREATE TRANSACTION BUTTON IS VISIBLE', label: 'ReceiptScanner');
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.spacing16),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Transaction'),
                        onPressed: () {
                          Log.d('🔵 BUTTON CLICKED! Navigating directly to transaction form',
                              label: 'ReceiptScanner');
                          // Navigate directly to transaction form instead of popping with result
                          // First pop the scanner screen
                          Navigator.of(context).pop();
                          // Then push to transaction form with the scan result
                          context.push(Routes.transactionForm, extra: scanResult.value);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  PopupMenuItem<OcrProviderType> _buildMenuItem(
      OcrProviderType type, String label, OcrProviderType selected) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(
            type == selected
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildResultsCard(BuildContext context, ReceiptScanResult result) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Details', style: AppTextStyles.heading5),
            const SizedBox(height: AppSpacing.spacing12),
            _buildInfoRow(Icons.store, 'Merchant', result.merchant),
            _buildInfoRow(Icons.attach_money, 'Amount',
                _formatCurrency(result.amount, result.currency)),
            _buildInfoRow(Icons.category, 'Category', result.category),
            _buildInfoRow(Icons.date_range, 'Date', result.date),
            _buildInfoRow(
                Icons.credit_card, 'Payment', result.paymentMethod),
            if (result.taxAmount != null)
              _buildInfoRow(Icons.receipt, 'Tax', '${result.taxAmount} ${result.currency ?? ""}'),
            if (result.tipAmount != null)
              _buildInfoRow(Icons.thumb_up, 'Tip', '${result.tipAmount} ${result.currency ?? ""}'),
            const Divider(height: 24),
            Text('Items:',
                style:
                    AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.spacing8),
            ...result.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: AppSpacing.spacing8),
                    Expanded(child: Text(item, style: AppTextStyles.body3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount, String? currency) {
    final currencyCode = currency?.toUpperCase() ?? '';

    // For VND and other zero-decimal currencies, show without decimals
    final zeroDecimalCurrencies = ['VND', 'JPY', 'KRW', 'IDR'];
    final hasDecimals = !zeroDecimalCurrencies.contains(currencyCode);

    // Format with thousand separators
    final parts = amount.toStringAsFixed(hasDecimals ? 2 : 0).split('.');
    final integerPart = parts[0];
    final decimalPart = hasDecimals && parts.length > 1 ? '.${parts[1]}' : '';

    // Add thousand separators
    final buffer = StringBuffer();
    final reversed = integerPart.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(',');
      buffer.write(reversed[i]);
    }
    final formattedInteger = buffer.toString().split('').reversed.join();

    return '$formattedInteger$decimalPart ${currencyCode.isEmpty ? "" : currencyCode}';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.spacing8),
          Text('$label: ',
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: AppTextStyles.body2)),
        ],
      ),
    );
  }
}
