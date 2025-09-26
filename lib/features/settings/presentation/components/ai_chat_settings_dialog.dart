import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/components/dialogs/toast.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/config/api_config.dart';

class AIChatSettingsDialog extends ConsumerStatefulWidget {
  const AIChatSettingsDialog({super.key});

  @override
  ConsumerState<AIChatSettingsDialog> createState() => _AIChatSettingsDialogState();
}

class _AIChatSettingsDialogState extends ConsumerState<AIChatSettingsDialog> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await ApiConfig.getClaudeApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      _apiKeyController.text = apiKey;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      showToast(context, 'Please enter an API key', type: ToastType.error);
      return;
    }

    if (!apiKey.startsWith('sk-ant-')) {
      showToast(context, 'Invalid Claude API key format', type: ToastType.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiConfig.saveClaudeApiKey(apiKey);

      // Invalidate the provider to reload with new key
      ref.invalidate(claudeApiKeyProvider);

      showToast(context, 'API key saved successfully', type: ToastType.success);
      Navigator.of(context).pop();
    } catch (e) {
      showToast(context, 'Failed to save API key', type: ToastType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Chat Settings',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppSpacing.spacing16),

            Text(
              'Enter your Claude API key to enable AI chat features.',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: AppSpacing.spacing8),

            Text(
              'Get your API key from: console.anthropic.com',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.spacing16),

            CustomTextField(
              controller: _apiKeyController,
              hint: 'sk-ant-api...',
              label: 'Claude API Key',
              obscureText: !_isApiKeyVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isApiKeyVisible = !_isApiKeyVisible;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.spacing24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.spacing12),
                PrimaryButton(
                  onPressed: _isLoading ? null : _saveApiKey,
                  text: _isLoading ? 'Saving...' : 'Save',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}