import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/features/settings/presentation/screens/bot_integration_screen.dart';
import 'package:bexly/core/services/telegram_deep_link_handler.dart';
import 'package:bexly/core/utils/logger.dart';

/// Wrapper for BotIntegrationScreen that handles deep link token
class BotIntegrationScreenWrapper extends HookConsumerWidget {
  const BotIntegrationScreenWrapper({super.key, this.telegramLinkToken});

  final String? telegramLinkToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProcessedToken = useState(false);

    // Auto-link if token is provided via deep link
    useEffect(() {
      if (telegramLinkToken != null &&
          telegramLinkToken!.isNotEmpty &&
          !hasProcessedToken.value) {
        hasProcessedToken.value = true;
        _handleDeepLinkToken(context, telegramLinkToken!);
      }
      return null;
    }, [telegramLinkToken]);

    return const BotIntegrationScreen();
  }

  Future<void> _handleDeepLinkToken(BuildContext context, String token) async {
    try {
      Log.i('Processing deep link token', label: 'BotIntegration');

      // Show loading indicator
      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Linking Account'),
          description: const Text('Verifying token...'),
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }

      // Link account using token
      final telegramId = await TelegramDeepLinkHandler.linkWithToken(token);

      if (context.mounted) {
        if (telegramId != null) {
          // Success
          toastification.show(
            context: context,
            title: const Text('Account Linked'),
            description: Text('Telegram account $telegramId linked successfully!'),
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else {
          // Failed
          toastification.show(
            context: context,
            title: const Text('Link Failed'),
            description: const Text('Could not verify token. Please try manual code.'),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      Log.e('Error handling deep link token: $e', label: 'BotIntegration');

      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: Text('Failed to link account: $e'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    }
  }
}
