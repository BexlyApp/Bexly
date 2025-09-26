import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

class AuthRequiredDialog extends StatelessWidget {
  final String featureName;
  final String description;

  const AuthRequiredDialog({
    super.key,
    required this.featureName,
    required this.description,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String featureName,
    required String description,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AuthRequiredDialog(
        featureName: featureName,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.lock_outline,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        'Sign In Required',
        style: theme.textTheme.headlineSmall,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            featureName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Sign in to sync your data across devices and enable cloud backup',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context, true);
            context.push('/login');
          },
          icon: const Icon(Icons.login, size: 18),
          label: const Text('Sign In'),
        ),
      ],
    );
  }
}