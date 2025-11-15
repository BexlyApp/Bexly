import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/ai_chat/domain/models/chat_message.dart';
import 'package:bexly/features/ai_chat/presentation/riverpod/chat_provider.dart';

class AIChatScreen extends HookConsumerWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final textController = useTextEditingController();

    // Proactively fetch exchange rate when chat screen opens
    // This ensures AI has exchange rate data for currency conversion messages
    useEffect(() {
      Future.microtask(() async {
        try {
          final rate = await ref.read(exchangeRateCacheProvider.notifier).getRate('VND', 'USD');
          Log.d('📊 [ChatScreen] Exchange rate VND->USD pre-fetched: $rate', label: 'Chat Screen');

          // CRITICAL: Invalidate AI service to rebuild with exchange rate
          // This ensures next AI message will have conversion info
          ref.invalidate(aiServiceProvider);
          Log.d('🔄 [ChatScreen] AI service invalidated - will rebuild with exchange rate', label: 'Chat Screen');
        } catch (e) {
          Log.e('Failed to pre-fetch exchange rate: $e', label: 'Chat Screen');
        }
      });
      return null;
    }, []);

    return CustomScaffold(
      context: context,
      showBackButton: false,
      showBalance: false,
      title: AppLocalizations.of(context)?.aiAssistantTitle ?? 'Bexly AI Assistant',
      body: Column(
        children: [
          // Error banner
          if (chatState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              color: AppColors.redAlpha10,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.red600,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.spacing8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.errorOccurred ?? 'An error occurred. Please try again.',
                      style: AppTextStyles.body4.copyWith(
                        color: AppColors.red600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: chatNotifier.clearError,
                    icon: Icon(
                      Icons.close,
                      color: AppColors.red600,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

          // Messages list (reversed so newest message is at bottom)
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                // Reverse index to show newest at bottom
                final reversedIndex = chatState.messages.length - 1 - index;
                final message = chatState.messages[reversedIndex];

                // Add fade-in animation for smooth message appearance
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _MessageBubble(
                    key: ValueKey(message.id), // Key is important for AnimatedSwitcher
                    message: message,
                    isLast: index == 0, // First item in reversed list is last message
                  ),
                );
              },
            ),
          ),

          // Input field
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: _ChatInput(
              controller: textController,
              onSend: (message) {
                chatNotifier.sendMessage(message);
                textController.clear();
              },
              isLoading: chatState.isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLast;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isLast,
  });

  /// Parse markdown bold (**text**) and return TextSpan with formatting
  List<TextSpan> _parseMarkdownBold(String text, TextStyle baseStyle, Color highlightColor) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Add normal text before bold
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      // Add bold text with highlight color
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: highlightColor,
        ),
      ));

      lastIndex = match.end;
    }

    // Add remaining normal text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    final isTyping = message.isTyping;

    return Container(
      margin: EdgeInsets.only(
        bottom: isLast ? AppSpacing.spacing8 : AppSpacing.spacing16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary400, AppColors.primary600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppColors.light,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing8),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing16,
                    vertical: AppSpacing.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary600
                        : (isTyping ? AppColors.neutral100 : AppColors.neutral50),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      topRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: isTyping
                        ? Border.all(color: AppColors.neutral200)
                        : null,
                  ),
                  child: isTyping
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(3, (index) =>
                              Container(
                                margin: EdgeInsets.only(
                                  right: index < 2 ? 4 : 0,
                                ),
                                child: _TypingDot(
                                  delay: Duration(milliseconds: index * 200),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SelectableText.rich(
                          TextSpan(
                            children: _parseMarkdownBold(
                              message.content,
                              AppTextStyles.body2.copyWith(
                                color: isUser
                                    ? AppColors.light
                                    : AppColors.neutral900,
                              ),
                              // Highlight color for bold text
                              isUser
                                  ? AppColors.light
                                  : AppColors.primary600, // Use primary color for AI highlights
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: AppSpacing.spacing4),

                Text(
                  _formatTime(context, message.timestamp),
                  style: AppTextStyles.body5.copyWith(
                    color: AppColors.neutral400,
                  ),
                ),
              ],
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: AppSpacing.spacing8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary600,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.light,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final l10n = AppLocalizations.of(context);

    if (difference.inMinutes < 1) {
      return l10n?.justNow ?? 'Just now';
    } else if (difference.inHours < 1) {
      return l10n?.minutesAgo(difference.inMinutes) ?? '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return l10n?.hoursAgo(difference.inHours) ?? '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _TypingDot extends StatefulWidget {
  final Duration delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.neutral400,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }
}

class _ChatInput extends HookWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isLoading;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: 4,
                  minLines: 1,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.typeYourMessage ?? 'Type your message...',
                hintStyle: AppTextStyles.body2.copyWith(
                  color: AppColors.neutral400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing16,
                  vertical: AppSpacing.spacing8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppColors.neutral200,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppColors.neutral200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppColors.primary600,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty && !isLoading) {
                  onSend(value);
                }
              },
            ),
          ),

          const SizedBox(width: AppSpacing.spacing8),

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: controller.text.trim().isNotEmpty && !isLoading
                  ? const LinearGradient(
                      colors: [AppColors.primary500, AppColors.primary700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: controller.text.trim().isEmpty || isLoading
                  ? AppColors.neutral200
                  : null,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: controller.text.trim().isNotEmpty && !isLoading
                    ? () {
                        HapticFeedback.lightImpact();
                        onSend(controller.text);
                      }
                    : null,
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary600,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: controller.text.trim().isNotEmpty
                              ? AppColors.light
                              : AppColors.neutral400,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      );
      }),
    );
  }
}