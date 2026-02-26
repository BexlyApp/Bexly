import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/ai_chat/data/services/speech_service.dart';
import 'package:bexly/features/ai_chat/domain/models/chat_message.dart';
import 'package:bexly/features/ai_chat/presentation/riverpod/chat_provider.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';

class AIChatScreen extends HookConsumerWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final textController = useTextEditingController(text: chatState.draftMessage);

    // DEBUG: Log messages count on every build
    print('[UI_DEBUG] AIChatScreen build() - messages count: ${chatState.messages.length}');
    print('[UI_DEBUG] isLoading: ${chatState.isLoading}, isTyping: ${chatState.isTyping}');

    // Sync draft message to state when user types
    useEffect(() {
      void listener() {
        chatNotifier.updateDraftMessage(textController.text);
      }
      textController.addListener(listener);
      return () => textController.removeListener(listener);
    }, [textController]);

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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Log.d('❌ Error dismiss button tapped', label: 'Chat Screen');
                        chatNotifier.clearError();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: AppColors.red600,
                          size: 18,
                        ),
                      ),
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
              onSend: (message, imageBytes) {
                chatNotifier.sendMessage(message, imageBytes: imageBytes);
                textController.clear();
                chatNotifier.updateDraftMessage(''); // Clear draft after sending
              },
              isLoading: chatState.isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

// Show bottom sheet to select image source
void _showImageSourceBottomSheet(
  BuildContext context,
  ImagePicker imagePicker,
  ValueNotifier<Uint8List?> selectedImage,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.camera_alt,
                color: AppColors.primary600,
              ),
            ),
            title: Text(
              'Camera',
              style: AppTextStyles.body2,
            ),
            subtitle: Text(
              'Capture receipt with camera',
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral400,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              try {
                final XFile? image = await imagePicker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  selectedImage.value = bytes;
                }
              } catch (e) {
                Log.e('Failed to pick image from camera: $e', label: 'ImagePicker');
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.greenAlpha10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.photo_library,
                color: AppColors.green200,
              ),
            ),
            title: Text(
              'Gallery',
              style: AppTextStyles.body2,
            ),
            subtitle: Text(
              'Choose from your photos',
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral400,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              try {
                final XFile? image = await imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  selectedImage.value = bytes;
                }
              } catch (e) {
                Log.e('Failed to pick image from gallery: $e', label: 'ImagePicker');
              }
            },
          ),
        ],
      ),
    ),
  );
}

class _MessageBubble extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isFromUser;
    final isTyping = message.isTyping;
    final hasPendingAction = message.hasPendingAction;
    final userPhotoUrl = ref.watch(authStateProvider).profilePicture;

    // DEBUG: Log pending action status for each message
    if (!isUser && message.pendingAction != null) {
      print('[UI_BUBBLE] Message ${message.id.substring(0, 8)}: pendingAction=${message.pendingAction != null}, isActionHandled=${message.isActionHandled}, hasPendingAction=$hasPendingAction');
    }

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
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show image thumbnail if present
                            if (message.imageBytes != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  message.imageBytes!,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (message.content.trim().isNotEmpty)
                                const SizedBox(height: AppSpacing.spacing8),
                            ],
                            // Show text content if present
                            if (message.content.trim().isNotEmpty)
                              SelectableText.rich(
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
                            // Show action buttons if pending action exists
                            if (hasPendingAction) ...[
                              const SizedBox(height: AppSpacing.spacing12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: message.pendingAction!.buttons.map((button) {
                                  final isConfirm = button.actionType == 'confirm';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
                                    child: Material(
                                      color: isConfirm
                                          ? AppColors.redAlpha10
                                          : AppColors.neutral100,
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          ref.read(chatProvider.notifier).handlePendingAction(
                                            message.id,
                                            button.actionType,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        splashColor: isConfirm
                                            ? AppColors.red.withValues(alpha: 0.2)
                                            : AppColors.neutral300.withValues(alpha: 0.3),
                                        highlightColor: isConfirm
                                            ? AppColors.red.withValues(alpha: 0.1)
                                            : AppColors.neutral200.withValues(alpha: 0.5),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.spacing16,
                                            vertical: AppSpacing.spacing8,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isConfirm
                                                  ? AppColors.red
                                                  : AppColors.neutral300,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            button.label,
                                            style: AppTextStyles.body4.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isConfirm
                                                  ? AppColors.red
                                                  : AppColors.neutral700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                ),

                const SizedBox(height: AppSpacing.spacing4),

                // Timestamp and model name row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(context, message.timestamp),
                      style: AppTextStyles.body5.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                    // Show model name for AI messages
                    if (!isUser && message.modelName != null) ...[
                      Text(
                        ' · ',
                        style: AppTextStyles.body5.copyWith(
                          color: AppColors.neutral400,
                        ),
                      ),
                      Text(
                        _formatModelName(message.modelName!),
                        style: AppTextStyles.body5.copyWith(
                          color: AppColors.primary400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
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
                // Only show background color when no avatar (to support transparent PNGs)
                color: userPhotoUrl == null ? AppColors.secondary600 : null,
                borderRadius: BorderRadius.circular(16),
                // Show user avatar if available
                image: userPhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(userPhotoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              // Only show icon if no avatar
              child: userPhotoUrl == null
                  ? const Icon(
                      Icons.person_outline,
                      color: AppColors.light,
                      size: 16,
                    )
                  : null,
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

  /// Format model name for display (e.g., "gemini-2.5-flash" -> "Gemini 2.5 Flash")
  String _formatModelName(String modelName) {
    // Common model name mappings
    final mappings = {
      'gemini-3-flash-preview': 'Gemini 3 Flash',
      'gemini-2.5-flash': 'Gemini 2.5 Flash',
      'gemini-2.0-flash': 'Gemini 2.0 Flash',
      'gemini-1.5-flash': 'Gemini 1.5 Flash',
      'gemini-1.5-pro': 'Gemini 1.5 Pro',
      'gpt-4o': 'GPT-4o',
      'gpt-4o-mini': 'GPT-4o Mini',
      'gpt-4-turbo': 'GPT-4 Turbo',
      'gpt-3.5-turbo': 'GPT-3.5 Turbo',
      'claude-sonnet-4-20250514': 'Claude Sonnet 4',
      'claude-3-opus': 'Claude 3 Opus',
      'claude-3-sonnet': 'Claude 3 Sonnet',
      'claude-3-haiku': 'Claude 3 Haiku',
      'Qwen/Qwen3-VL-30B-A3B-Instruct-FP8': 'Qwen3-VL',
      'Qwen/Qwen3.5-35B-A3B-FP8': 'Qwen3.5',
    };

    return mappings[modelName] ?? modelName;
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

class _ChatInput extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(String, Uint8List?) onSend;
  final bool isLoading;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedImage = useState<Uint8List?>(null);
    final imagePicker = ImagePicker();
    final speechState = ref.watch(speechStateProvider);
    final speechNotifier = ref.read(speechStateProvider.notifier);

    // Create focus node with onKeyEvent handler for Enter key on web/desktop
    final focusNode = useMemoized(() {
      final node = FocusNode();
      node.onKeyEvent = (FocusNode node, KeyEvent event) {
        // Only handle on web/desktop
        if (kIsWeb || context.isDesktopLayout) {
          // Check if Enter key pressed without Shift
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            // Send message if can send
            final hasText = controller.text.trim().isNotEmpty;
            final hasImage = selectedImage.value != null;
            if ((hasText || hasImage) && !isLoading) {
              onSend(controller.text, selectedImage.value);
              selectedImage.value = null;
              return KeyEventResult.handled; // Prevent newline
            }
          }
        }
        return KeyEventResult.ignored; // Let TextField handle other keys
      };
      return node;
    }, []);

    // Dispose focus node when widget is disposed
    useEffect(() {
      return () => focusNode.dispose();
    }, [focusNode]);

    // Update text field with partial speech results in real-time
    useEffect(() {
      if (speechState.isListening && speechState.partialText.isNotEmpty) {
        controller.text = speechState.partialText;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: speechState.partialText.length),
        );
      }
      // When final result comes in, update with recognized text
      if (!speechState.isListening && speechState.recognizedText.isNotEmpty) {
        controller.text = speechState.recognizedText;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: speechState.recognizedText.length),
        );
        // Clear the speech state after using the text
        Future.microtask(() => speechNotifier.clearText());
      }
      return null;
    }, [speechState.partialText, speechState.recognizedText, speechState.isListening]);

    // Get bottom padding for safe area (to avoid bottom nav bar overlap)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.spacing16,
        right: AppSpacing.spacing16,
        top: AppSpacing.spacing8,
        bottom: AppSpacing.spacing8 + bottomPadding,
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview if selected
          if (selectedImage.value != null)
            Container(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      selectedImage.value!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => selectedImage.value = null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Show recording UI when listening, otherwise show normal input
          if (speechState.isListening)
            _buildRecordingUI(
              context: context,
              speechState: speechState,
              speechNotifier: speechNotifier,
              controller: controller,
            )
          else
            ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final hasText = controller.text.trim().isNotEmpty;
              final canSend = hasText || selectedImage.value != null;

              return Row(
                children: [
                  // Add image button (left side)
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: AppSpacing.spacing8),
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: isLoading
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _showImageSourceBottomSheet(context, imagePicker, selectedImage);
                              },
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: AppColors.neutral600,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Text input with voice/send button inside
                  // On web/desktop: Enter sends (via FocusNode.onKeyEvent), Shift+Enter adds newline
                  // On mobile: Enter adds newline (use send button)
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: 4,
                      minLines: 1,
                      enabled: !isLoading,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.body3.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)?.typeYourMessage ?? 'Type your message...',
                        hintStyle: AppTextStyles.body3.copyWith(
                          color: AppColors.neutral400,
                        ),
                        contentPadding: const EdgeInsets.only(
                          left: AppSpacing.spacing16,
                          right: AppSpacing.spacing4,
                          top: AppSpacing.spacing8,
                          bottom: AppSpacing.spacing8,
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
                        // Voice/Send button inside the input field (right side)
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.spacing4),
                          child: canSend && !isLoading
                              // Send button when has text/image
                              ? GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onSend(controller.text, selectedImage.value);
                                    selectedImage.value = null;
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primary500, AppColors.primary700],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: AppColors.light,
                                      size: 20,
                                    ),
                                  ),
                                )
                              // Voice button when empty - shows recording state
                              : GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () async {
                                          HapticFeedback.lightImpact();
                                          if (speechState.isListening) {
                                            // Stop listening and use the text
                                            await speechNotifier.stopListening();
                                            final text = speechState.recognizedText.isNotEmpty
                                                ? speechState.recognizedText
                                                : speechState.partialText;
                                            if (text.isNotEmpty) {
                                              controller.text = text;
                                              controller.selection = TextSelection.fromPosition(
                                                TextPosition(offset: text.length),
                                              );
                                            }
                                          } else {
                                            // Start listening - speech_to_text handles permissions internally
                                            // Use Vietnamese locale by default for better recognition
                                            await speechNotifier.startListening(localeId: 'vi_VN');

                                            // Check if there was an error (permission denied or not available)
                                            // Need to wait a bit for the state to update
                                            await Future.delayed(const Duration(milliseconds: 300));
                                            final currentState = ref.read(speechStateProvider);
                                            if (currentState.error != null && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(currentState.error!),
                                                  action: SnackBarAction(
                                                    label: 'Settings',
                                                    onPressed: () => openAppSettings(),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  child: speechState.isListening
                                      ? _buildRecordingIndicator()
                                      : Icon(
                                          Icons.mic_none_rounded,
                                          color: isLoading ? AppColors.neutral300 : AppColors.neutral500,
                                          size: 24,
                                        ),
                                ),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      onSubmitted: (value) {
                        if ((value.trim().isNotEmpty || selectedImage.value != null) && !isLoading) {
                          onSend(value, selectedImage.value);
                          selectedImage.value = null;
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build recording UI with waveform animation and controls
  Widget _buildRecordingUI({
    required BuildContext context,
    required SpeechState speechState,
    required SpeechStateNotifier speechNotifier,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppColors.red.withAlpha(15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.red.withAlpha(50),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              await speechNotifier.cancelListening();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.neutral600,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.spacing12),

          // Waveform animation and text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated waveform
                _AnimatedWaveform(),

                const SizedBox(height: 4),

                // Partial text or listening indicator
                Text(
                  speechState.partialText.isNotEmpty
                      ? speechState.partialText
                      : 'Đang lắng nghe...',
                  style: AppTextStyles.body4.copyWith(
                    color: speechState.partialText.isNotEmpty
                        ? AppColors.neutral700
                        : AppColors.neutral500,
                    fontStyle: speechState.partialText.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.spacing12),

          // Stop/Done button
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              await speechNotifier.stopListening();
              final text = speechState.recognizedText.isNotEmpty
                  ? speechState.recognizedText
                  : speechState.partialText;
              if (text.isNotEmpty) {
                controller.text = text;
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: text.length),
                );
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stop_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build animated recording indicator (small, for suffix icon)
  Widget _buildRecordingIndicator() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.red.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Animated waveform widget for voice recording
class _AnimatedWaveform extends StatefulWidget {
  @override
  State<_AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<_AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(20, (index) {
              // Create wave effect with phase offset
              final phase = (index / 20) * 2 * 3.14159;
              final animValue = (_controller.value * 2 * 3.14159) + phase;
              final height = 8 + 12 * ((1 + _sin(animValue)) / 2);

              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.red.withAlpha((150 + 105 * ((1 + _sin(animValue)) / 2)).toInt()),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  double _sin(double x) {
    // Simple sine approximation
    x = x % (2 * 3.14159);
    if (x > 3.14159) x -= 2 * 3.14159;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}