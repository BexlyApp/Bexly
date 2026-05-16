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
    final linkCode = useState<String?>(null);
    final deepLink = useState<String?>(null);

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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                  'Chưa liên kết',
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
                        if (linkCode.value == null) ...[
                          const Text(
                            'Tạo mã liên kết, mở Telegram và gửi mã cho bot '
                            '(hoặc bấm nút mở sẵn). Sau khi bot xác nhận, bấm '
                            '"Kiểm tra".',
                            style: TextStyle(fontSize: 14),
                          ),
                          const Gap(16),
                          FilledButton.icon(
                            onPressed: isLoading.value
                                ? null
                                : () => _generateCode(
                                      context,
                                      isLoading,
                                      linkCode,
                                      deepLink,
                                    ),
                            icon: const Icon(Icons.link),
                            label: const Text('Tạo mã liên kết'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: const Color(0xFF0088CC),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Mã liên kết của bạn:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Gap(8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SelectableText(
                                  linkCode.value!,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Sao chép mã',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: linkCode.value!),
                                    );
                                    toastification.show(
                                      context: context,
                                      title: const Text('Đã sao chép mã'),
                                      type: ToastificationType.success,
                                      style: ToastificationStyle.fillColored,
                                      autoCloseDuration:
                                          const Duration(seconds: 2),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          const Text(
                            'Hết hạn sau 10 phút. Mở Telegram, gửi mã này cho '
                            'bot (hoặc bấm nút bên dưới), rồi bấm "Kiểm tra".',
                            style: TextStyle(fontSize: 13),
                          ),
                          const Gap(16),
                          if (deepLink.value != null)
                            FilledButton.icon(
                              onPressed: () =>
                                  _openDeepLink(context, deepLink.value!),
                              icon: const Icon(Icons.telegram),
                              label: const Text('Mở Telegram'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: const Color(0xFF0088CC),
                              ),
                            ),
                          const Gap(8),
                          OutlinedButton.icon(
                            onPressed: isLoading.value
                                ? null
                                : () => _checkTelegramStatus(
                                      isTelegramLinked,
                                      telegramId,
                                    ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tôi đã gửi xong - Kiểm tra'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
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

  Future<void> _generateCode(
    BuildContext context,
    ValueNotifier<bool> isLoading,
    ValueNotifier<String?> linkCode,
    ValueNotifier<String?> deepLink,
  ) async {
    isLoading.value = true;
    try {
      final result = await TelegramBotService.generateLinkCode();
      if (result != null && result['code'] is String) {
        linkCode.value = result['code'] as String;
        deepLink.value = result['deep_link'] as String?;
      } else {
        throw Exception('No code returned');
      }
    } catch (e) {
      Log.e('Error generating link code: $e', label: 'BotIntegration');
      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Lỗi'),
          description: const Text('Không tạo được mã liên kết. Thử lại sau.'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _openDeepLink(BuildContext context, String url) async {
    try {
      await LinkLauncher.launch(url);
    } catch (e) {
      Log.e('Error opening Telegram: $e', label: 'BotIntegration');
      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Lỗi'),
          description: const Text('Không mở được Telegram. Vui lòng mở thủ công.'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }
}
