import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/ai_chat/domain/models/chat_message.dart';
import 'package:bexly/features/ai_chat/presentation/riverpod/chat_provider.dart';

class AIChatScreen extends HookConsumerWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    // Auto scroll to bottom when new messages arrive
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      return null;
    }, [chatState.messages.length]);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary500, AppColors.primary700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppColors.light,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý AI Bexly',
                  style: AppTextStyles.body2,
                ),
                Text(
                  chatState.isTyping ? 'Đang nhập...' : 'Sẵn sàng hỗ trợ',
                  style: AppTextStyles.body4.copyWith(
                    color: chatState.isTyping
                        ? AppColors.green100
                        : AppColors.neutral400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa cuộc trò chuyện'),
                  content: const Text(
                    'Bạn có chắc chắn muốn xóa toàn bộ cuộc trò chuyện?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        chatNotifier.clearChat();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
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
                        'Đã có lỗi xảy ra. Vui lòng thử lại.',
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

            // Messages list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                itemCount: chatState.messages.length,
                itemBuilder: (context, index) {
                  final message = chatState.messages[index];
                  return _MessageBubble(
                    message: message,
                    isLast: index == chatState.messages.length - 1,
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
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLast;

  const _MessageBubble({
    required this.message,
    required this.isLast,
  });

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
                      : SelectableText(
                          message.content,
                          style: AppTextStyles.body2.copyWith(
                            color: isUser
                                ? AppColors.light
                                : AppColors.neutral900,
                          ),
                        ),
                ),

                const SizedBox(height: AppSpacing.spacing4),

                Text(
                  _formatTime(message.timestamp),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
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
                  decoration: InputDecoration(
                hintText: 'Nhập tin nhắn của bạn...',
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
                fillColor: AppColors.light,
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