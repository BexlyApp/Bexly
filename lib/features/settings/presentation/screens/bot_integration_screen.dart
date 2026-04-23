import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/core/services/telegram_bot_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/url_launcher/url_launcher.dart';

/// Screen for managing bot integrations (Telegram, etc.)
class BotIntegrationScreen extends HookConsumerWidget {
  const BotIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final isTelegramLinked = useState<bool?>(null);
    final telegramId = useState<String?>(null);

    // Check Telegram link status on mount
    useEffect(() {
      _checkTelegramStatus(isTelegramLinked, telegramId);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Integration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Telegram Bot Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.telegram,
                        size: 32,
                        color: const Color(0xFF0088CC),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Telegram Bot',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Gap(4),
                            Text(
                              'Track expenses via Telegram chat',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  const Divider(),
                  const Gap(16),
                  // Status
                  if (isTelegramLinked.value == null)
                    const Center(child: CircularProgressIndicator())
                  else if (isTelegramLinked.value == true)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '✅ Linked',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    if (telegramId.value != null)
                                      Text(
                                        'Telegram ID: ${telegramId.value}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        FilledButton.tonal(
                          onPressed: isLoading.value
                              ? null
                              : () => _unlinkTelegram(
                                    context,
                                    isLoading,
                                    isTelegramLinked,
                                    telegramId,
                                  ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: Theme.of(context).colorScheme.errorContainer,
                            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          child: const Text('Unlink Account'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange),
                              Gap(12),
                              Expanded(
                                child: Text(
                                  'Not linked yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        Text(
                          'How to link:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Gap(8),
                        const Text(
                          '1. Open Telegram and search for your bot\n'
                          '2. Send any message to the bot\n'
                          '3. Click the "🔗 Link Account" button\n'
                          '4. App will open and link automatically',
                          style: TextStyle(fontSize: 14),
                        ),
                        const Gap(16),
                        FilledButton.icon(
                          onPressed: () => _openTelegram(context),
                          icon: const Icon(Icons.telegram),
                          label: const Text('Open in Telegram'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: const Color(0xFF0088CC),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkTelegramStatus(
    ValueNotifier<bool?> isTelegramLinked,
    ValueNotifier<String?> telegramId,
  ) async {
    try {
      final isLinked = await TelegramBotService.isLinked();
      isTelegramLinked.value = isLinked;

      if (isLinked) {
        final id = await TelegramBotService.getLinkedTelegramId();
        telegramId.value = id;
      }
    } catch (e) {
      Log.e('Error checking Telegram status: $e', label: 'BotIntegration');
      isTelegramLinked.value = false;
    }
  }

  Future<void> _unlinkTelegram(
    BuildContext context,
    ValueNotifier<bool> isLoading,
    ValueNotifier<bool?> isTelegramLinked,
    ValueNotifier<String?> telegramId,
  ) async {
    isLoading.value = true;

    try {
      final success = await TelegramBotService.unlinkTelegramAccount();

      if (success) {
        isTelegramLinked.value = false;
        telegramId.value = null;

        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Telegram Unlinked'),
            description: const Text('Your Telegram account has been unlinked successfully.'),
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      } else {
        throw Exception('Failed to unlink');
      }
    } catch (e) {
      Log.e('Error unlinking Telegram: $e', label: 'BotIntegration');

      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: Text('Failed to unlink Telegram: $e'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _openTelegram(BuildContext context) async {
    // Open Telegram bot with pre-filled /link command
    const botUsername = 'BexlyBot';
    const url = 'https://t.me/$botUsername?text=/link';

    try {
      await LinkLauncher.launch(url);

      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Opening Telegram'),
          description: Text('Bot: @$botUsername'),
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Log.e('Error opening Telegram: $e', label: 'BotIntegration');

      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: const Text('Failed to open Telegram. Please open it manually.'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }
}
