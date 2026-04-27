import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/features/ai_chat/domain/models/chat_message.dart';
import 'package:bexly/features/ai_chat/data/services/ai_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/config/llm_config.dart';
import 'package:bexly/core/services/ai/ai_quota_state.dart';
import 'package:bexly/features/category/presentation/riverpod/category_providers.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';
import 'package:bexly/features/goal/data/model/goal_model.dart';
import 'package:bexly/features/goal/presentation/riverpod/goals_list_provider.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/ai_chat/presentation/riverpod/chat_dao_provider.dart';
import 'package:bexly/core/database/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/core/utils/category_translation_map.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/features/receipt_scanner/presentation/riverpod/receipt_scanner_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/pending_transactions/data/models/pending_transaction_model.dart';
import 'package:bexly/core/database/daos/pending_transaction_dao.dart';
import 'package:bexly/core/services/image_service/riverpod/image_notifier.dart';
import 'package:bexly/core/services/subscription/subscription.dart';
import 'package:bexly/features/settings/presentation/riverpod/ai_model_provider.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';
import 'package:bexly/core/services/spending_anomaly_service.dart';
import 'package:bexly/features/ai_chat/presentation/widgets/nps_survey_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple category info for AI
class CategoryInfo {
  final String title;
  final String? keywords; // from description field
  final int? parentId;
  final List<CategoryInfo> subCategories;

  CategoryInfo({
    required this.title,
    this.keywords,
    this.parentId,
    this.subCategories = const [],
  });

  /// Build hierarchy text for LLM
  String toHierarchyText({int indent = 0}) {
    final buffer = StringBuffer();
    final prefix = indent == 0 ? '-' : '  ' * indent + '→';

    // Category name with keywords if available
    if (keywords != null && keywords!.isNotEmpty) {
      buffer.write('$prefix $title ($keywords)');
    } else {
      buffer.write('$prefix $title');
    }

    // Add subcategories
    if (subCategories.isNotEmpty) {
      for (final sub in subCategories) {
        buffer.write('\n${sub.toHierarchyText(indent: indent + 1)}');
      }
    }

    return buffer.toString();
  }

  /// Build hierarchy for all categories
  /// Optimized for LLM reasoning - clear structure with step-by-step guidance
  static String buildCategoryHierarchy(List<CategoryInfo> categories) {
    if (categories.isEmpty) return '';

    final buffer = StringBuffer();

    // Header with clear instruction
    buffer.write('CATEGORY SELECTION PROCESS:\n');
    buffer.write('Step 1: Read the transaction description\n');
    buffer.write('Step 2: Find the matching category group below\n');
    buffer.write('Step 3: Choose the SPECIFIC subcategory (marked with →)\n');
    buffer.write('Step 4: Return ONLY the subcategory name in your JSON\n\n');

    buffer.write('AVAILABLE CATEGORIES:\n\n');

    for (final cat in categories) {
      if (cat.subCategories.isNotEmpty) {
        // Parent category with subcategories
        final parentDesc = cat.keywords != null && cat.keywords!.isNotEmpty ? ' - ${cat.keywords}' : '';
        buffer.write('📁 ${cat.title}$parentDesc\n');
        for (final sub in cat.subCategories) {
          final subDesc = sub.keywords != null && sub.keywords!.isNotEmpty ? ' (${sub.keywords})' : '';
          buffer.write('   → ${sub.title}$subDesc\n');
        }
        buffer.write('\n');
      } else {
        // Standalone category
        final desc = cat.keywords != null && cat.keywords!.isNotEmpty ? ' (${cat.keywords})' : '';
        buffer.write('→ ${cat.title}$desc\n');
      }
    }

    // Clear examples at the end
    buffer.write('\nEXAMPLES - Learn from these:\n');
    buffer.write('✅ "Spotify subscription" → Answer: "Streaming" (NOT "Entertainment")\n');
    buffer.write('✅ "Netflix monthly" → Answer: "Streaming" (NOT "Entertainment")\n');
    buffer.write('✅ "Buy groceries" → Answer: "Groceries" (specify from which group)\n');
    buffer.write('❌ NEVER return "Entertainment" or "Shopping" - these are groups, not categories!\n');
    buffer.write('❌ NEVER make up category names - ONLY use names marked with →\n');

    return buffer.toString().trim();
  }
}

// AI Service Provider - Supports both OpenAI and Gemini
// CRITICAL: Use read() instead of watch() to prevent rebuild when categories change
// Rebuilding destroys AI service instance and loses conversation history!
final aiServiceProvider = Provider<AIService>((ref) {
  // Get categories from database with hierarchy and keywords
  // IMPORTANT: Use read() not watch() to prevent rebuild when categories change
  final categoriesAsync = ref.read(hierarchicalCategoriesProvider);

  // Keep provider alive permanently to preserve conversation history
  ref.keepAlive();

  // CRITICAL: Wait for categories to load before building AI service
  // If we build with empty categories, AI won't be able to create transactions!
  final List<CategoryInfo> categoryInfos = categoriesAsync.when(
    data: (cats) {
      return cats.map((c) => CategoryInfo(
        title: c.title,
        keywords: c.description,
        parentId: c.parentId,
        subCategories: c.subCategories?.map((sub) => CategoryInfo(
          title: sub.title,
          keywords: sub.description,
          parentId: sub.parentId,
        )).toList() ?? [],
      )).toList();
    },
    loading: () {
      // During loading, return empty list but provider will rebuild when data arrives
      Log.d('Categories still loading, AI service will rebuild when ready', label: 'Chat Provider');
      return <CategoryInfo>[];
    },
    error: (err, stack) {
      Log.e('Failed to load categories for AI: $err', label: 'Chat Provider');
      return <CategoryInfo>[];
    },
  );

  // Build category names list - ONLY include leaf categories (subcategories or standalone)
  final List<String> categories = categoryInfos.expand((cat) {
    if (cat.subCategories.isNotEmpty) {
      // Parent with subcategories - ONLY include subcategories, NOT parent
      return cat.subCategories.map((sub) => sub.title);
    } else {
      // Standalone category - include it
      return [cat.title];
    }
  }).toList();

  // Build dynamic hierarchy text from database
  final categoryHierarchy = CategoryInfo.buildCategoryHierarchy(categoryInfos);

  // CRITICAL: If categories are empty, the provider will rebuild when data arrives
  // This ensures AI always has access to categories
  if (categoryInfos.isEmpty) {
    Log.w('Categories not loaded yet, AI service will rebuild when ready', label: 'Chat Provider');
    print('========== CATEGORY DEBUG ==========');
    print('⚠️ Categories still loading... AI service will rebuild');
    print('====================================');
  } else {
    Log.d('Categories loaded for AI: ${categories.length} categories', label: 'Chat Provider');
    print('========== CATEGORY DEBUG ==========');
    print('✅ categoryInfos count: ${categoryInfos.length}');
    print('✅ categories list length: ${categories.length}');
    print('====================================');
    if (categoryHierarchy.isNotEmpty) {
      Log.d('Category Hierarchy loaded successfully', label: 'Chat Provider');
    }
  }

  // Get wallet info for context (use read to avoid rebuild)
  final walletAsync = ref.read(activeWalletProvider);
  final wallet = walletAsync.when(
    data: (data) => data,
    loading: () => null,
    error: (_, _) => null,
  );

  // Get all wallets for fallback when activeWallet is null (multi-wallet case)
  final allWalletsAsync = ref.read(allWalletsStreamProvider);
  final allWallets = allWalletsAsync.when(
    data: (data) => data,
    loading: () => <WalletModel>[],
    error: (_, _) => <WalletModel>[],
  );

  // Get default wallet for fallback (when activeWallet is null in multi-wallet mode)
  final defaultWalletAsync = ref.read(defaultWalletProvider);
  final defaultWallet = defaultWalletAsync.when(
    data: (data) => data,
    loading: () => null,
    error: (_, _) => null,
  );

  // If activeWallet is null (multi-wallet), use default wallet for AI context
  final contextWallet = wallet ?? defaultWallet ?? (allWallets.isNotEmpty ? allWallets.first : null);
  final walletCurrency = contextWallet?.currency ?? 'VND';
  final walletName = contextWallet?.name ?? 'Active Wallet';

  // Format: "Wallet Name (CURRENCY, Type)" so AI knows each wallet's currency and type
  // This helps AI match Vietnamese keywords like "thẻ tín dụng" to "Credit Card" type
  final walletNames = allWallets.map((w) => '${w.name} (${w.currency}, ${w.walletType.displayName})').toList();

  Log.d('Available wallets for AI: ${walletNames.join(", ")}', label: 'Chat Provider');

  // Get exchange rate for AI currency conversion display
  // Try cache first - if empty, AI will work without conversion message
  final exchangeRateCache = ref.read(exchangeRateCacheProvider);
  final String rateKey = 'VND_USD';
  final cachedRate = exchangeRateCache[rateKey];
  final double? exchangeRateVndToUsd = cachedRate?.rate;

  if (exchangeRateVndToUsd != null) {
    Log.d('✅ Exchange rate VND to USD for AI (from cache): $exchangeRateVndToUsd', label: 'Chat Provider');
  } else {
    Log.w('⚠️ No cached exchange rate - AI will work without conversion display', label: 'Chat Provider');
    // Note: Cache will be populated on first transaction view, then AI will have rate on next init
  }

  // Check which AI provider to use from user settings
  final selectedModel = ref.read(aiModelProvider);

  // Map AIModel setting to service
  switch (selectedModel) {
    case AIModel.gemini:
      Log.d('Using Gemini Service via proxy, model: ${LLMDefaultConfig.geminiModel}, wallet: "$walletName" ($walletCurrency)', label: 'Chat Provider');

      return GeminiService(
        apiKey: '', // API key managed server-side via proxy
        model: LLMDefaultConfig.geminiModel,
        categories: categories,
        categoryHierarchy: categoryHierarchy,
        walletCurrency: walletCurrency,
        walletName: walletName,
        exchangeRateVndToUsd: exchangeRateVndToUsd,
        wallets: walletNames,
      );

    case AIModel.openAI:
      Log.d('Using OpenAI Service via proxy, model: ${LLMDefaultConfig.model}, wallet: "$walletName" ($walletCurrency)', label: 'Chat Provider');

      return OpenAIService(
        apiKey: '', // API key managed server-side via proxy
        model: LLMDefaultConfig.model,
        categories: categories,
        categoryHierarchy: categoryHierarchy,
        walletCurrency: walletCurrency,
        walletName: walletName,
        exchangeRateVndToUsd: exchangeRateVndToUsd,
        wallets: walletNames,
      );

    case AIModel.dosAI:
      // DOS AI via DOS.AI Gateway. Auth is the user's Supabase JWT;
      // gateway reads tier from public.billing_accounts and enforces quota.
      final endpoint = LLMDefaultConfig.customEndpoint;
      final apiKey = LLMDefaultConfig.customApiKey;
      final model = LLMDefaultConfig.customModel;

      Log.d('Using DOS AI Gateway: endpoint=$endpoint, model=$model, wallet: "$walletName" ($walletCurrency)', label: 'Chat Provider');

      return CustomLLMService(
        baseUrl: endpoint,
        apiKey: apiKey,
        model: model,
        categories: categories,
        categoryHierarchy: categoryHierarchy,
        walletCurrency: walletCurrency,
        walletName: walletName,
        exchangeRateVndToUsd: exchangeRateVndToUsd,
        wallets: walletNames,
        onResponseHeaders: (headers) =>
            ref.read(aiQuotaProvider.notifier).updateFromHeaders(headers),
      );
  }
});

// Chat State Provider - Using regular provider to prevent dispose
// IMPORTANT: Don't watch aiServiceProvider here to avoid rebuild/dispose!
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class ChatNotifier extends Notifier<ChatState> {
  final Uuid _uuid = const Uuid();
  StreamSubscription? _typingSubscription;

  // Store current receipt image for attaching to transactions
  Uint8List? _currentReceiptImage;

  // Store pending screenshot transactions for quick action handling
  List<ReceiptScanResult>? _pendingScreenshotTransactions;

  // Get AI service when needed to avoid provider rebuilds
  AIService get _aiService => ref.read(aiServiceProvider);

  // Track if we're using fallback model
  bool _usingFallback = false;
  String? _fallbackModelName;

  // Cache fallback Gemini service to preserve conversation history
  GeminiService? _fallbackGeminiService;

  /// Send message with fallback: DOS AI (api.dos.ai handles local→Qwen Cloud) → Gemini
  Future<String> _sendMessageWithFallback(String message) async {
    final selectedModel = ref.read(aiModelProvider);

    // If using DOS AI, try with Gemini fallback
    if (selectedModel == AIModel.dosAI) {
      try {
        Log.d('🚀 Trying DOS AI first...', label: 'AI_FALLBACK');
        _usingFallback = false;
        _fallbackModelName = null;
        return await _aiService.sendMessage(message);
      } catch (e) {
        // DOS AI failed (server handles its own Qwen Cloud fallback) — fall back to Gemini
        Log.w('⚠️ DOS AI failed: $e, falling back to Gemini...', label: 'AI_FALLBACK');
        _usingFallback = true;

        final geminiService = _getOrCreateFallbackGeminiService();
        _fallbackModelName = geminiService.modelName;

        // Update context for current wallet
        final activeWallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
        final allWalletsAsync = ref.read(allWalletsStreamProvider);
        final allWallets = _unwrapAsyncValue(allWalletsAsync) ?? [];
        final walletNames = allWallets.map((w) => '${w.name} (${w.currency}, ${w.walletType.displayName})').toList();
        final exchangeRateCache = ref.read(exchangeRateCacheProvider);
        final cachedRate = exchangeRateCache['VND_USD'];

        geminiService.updateContext(
          walletName: activeWallet?.name,
          walletCurrency: activeWallet?.currency,
          wallets: walletNames,
          exchangeRate: cachedRate?.rate,
        );

        // Propagate spending insights and budgets to fallback service
        if (_aiService is AIServicePromptMixin) {
          final mixin = _aiService as AIServicePromptMixin;
          geminiService.updateSpendingInsights(mixin.spendingInsightsContext);
          geminiService.updateBudgetsContext(mixin.budgetsContext);
          geminiService.updateRecentTransactions(mixin.recentTransactionsContext);
        }

        Log.d('✅ Using Gemini fallback: ${geminiService.modelName}', label: 'AI_FALLBACK');
        return await geminiService.sendMessage(message);
      }
    }

    // Not DOS AI - use primary service directly
    _usingFallback = false;
    _fallbackModelName = null;
    return await _aiService.sendMessage(message);
  }

  /// Get or create cached fallback Gemini service (preserves conversation history)
  GeminiService _getOrCreateFallbackGeminiService() {
    if (_fallbackGeminiService != null) {
      return _fallbackGeminiService!;
    }

    final categoriesAsync = ref.read(hierarchicalCategoriesProvider);
    final categories = categoriesAsync.when(
      data: (cats) => cats.expand((c) {
        if (c.subCategories != null && c.subCategories!.isNotEmpty) {
          return c.subCategories!.map((sub) => sub.title);
        }
        return [c.title];
      }).toList(),
      loading: () => <String>[],
      error: (_, _) => <String>[],
    );

    _fallbackGeminiService = GeminiService(
      apiKey: '', // API key managed server-side via proxy
      model: LLMDefaultConfig.geminiModel,
      categories: categories,
    );

    return _fallbackGeminiService!;
  }

  /// Get the actual model name used (considering fallback)
  String get _actualModelName {
    if (_usingFallback && _fallbackModelName != null) {
      return _fallbackModelName!;
    }
    return _aiService.modelName;
  }

  // Helper method to unwrap AsyncValue
  T? _unwrapAsyncValue<T>(AsyncValue<T> asyncValue) {
    return asyncValue.when(
      data: (data) => data,
      loading: () => null,
      error: (_, _) => null,
    );
  }

  @override
  ChatState build() {
    // Register dispose callback for cleanup
    ref.onDispose(() {
      _typingSubscription?.cancel();
    });

    _initializeChat();
    return const ChatState();
  }

  /// Helper method to add error message to chat
  void _addErrorMessage(String errorContent) {
    final errorMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: errorContent,
      isFromUser: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, errorMsg],
    );
  }

  void _initializeChat() async {
    final dao = ref.read(chatMessageDaoProvider);
    // Cloud sync removed - chat messages stored locally only
    // TODO: Implement Supabase chat message sync

    // STEP 1: Load messages from local database
    try {
      final localMessages = await dao.getAllMessages();
      if (localMessages.isNotEmpty) {
        Log.d('Loaded ${localMessages.length} messages from local database', label: 'Chat Provider');
      }
    } catch (e) {
      Log.w('Failed to load messages: $e', label: 'Chat Provider');
    }

    // Load all saved messages
    final savedMessages = await dao.getAllMessages();

    if (savedMessages.isNotEmpty) {
      // Convert database messages to ChatMessage model and DEDUP by messageId
      final Map<String, ChatMessage> uniqueMessages = {};
      for (final dbMsg in savedMessages) {
        // Load image from file if path is stored
        Uint8List? imageBytes;
        if (dbMsg.imagePath != null) {
          try {
            final file = File(dbMsg.imagePath!);
            if (file.existsSync()) {
              imageBytes = await file.readAsBytes();
            }
          } catch (e) {
            Log.w('Failed to load chat image: $e', label: 'Chat Provider');
          }
        }

        final message = ChatMessage(
          id: dbMsg.messageId,
          content: dbMsg.content,
          isFromUser: dbMsg.isFromUser,
          timestamp: dbMsg.timestamp,
          error: dbMsg.error,
          isTyping: dbMsg.isTyping,
          imageBytes: imageBytes,
        );
        // Keep only the first occurrence (or latest if you prefer)
        if (!uniqueMessages.containsKey(dbMsg.messageId)) {
          uniqueMessages[dbMsg.messageId] = message;
        }
      }

      final messages = uniqueMessages.values.toList();
      Log.d('Loaded ${messages.length} unique messages (filtered ${savedMessages.length - messages.length} duplicates)', label: 'Chat Provider');

      state = state.copyWith(messages: messages);
    } else {
      // Add welcome message if no history
      // Use fixed ID to prevent duplicates when syncing
      const welcomeMessageId = 'welcome_message_v1';
      final welcomeMessage = ChatMessage(
        id: welcomeMessageId,
        content: 'Welcome to Bexly AI Assistant! I can help you track expenses, record income, check balances, and view transaction summaries. Note: Budget creation is now supported via chat!',
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [welcomeMessage],
      );

      // Save welcome message to database (local only, don't sync)
      await _saveMessageToDatabase(welcomeMessage, shouldSync: false);
    }
  }

  Future<void> _saveMessageToDatabase(ChatMessage message, {bool shouldSync = true}) async {
    // Save image to file if present
    String? imagePath;
    if (message.imageBytes != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final chatImagesDir = Directory('${dir.path}/chat_images');
        if (!chatImagesDir.existsSync()) {
          chatImagesDir.createSync(recursive: true);
        }
        final file = File('${chatImagesDir.path}/${message.id}.jpg');
        await file.writeAsBytes(message.imageBytes!);
        imagePath = file.path;
        Log.d('Saved chat image: $imagePath', label: 'Chat Provider');
      } catch (e) {
        Log.e('Failed to save chat image: $e', label: 'Chat Provider');
      }
    }

    final dao = ref.read(chatMessageDaoProvider);
    await dao.addMessage(db.ChatMessagesCompanion(
      messageId: drift.Value(message.id),
      content: drift.Value(message.content),
      isFromUser: drift.Value(message.isFromUser),
      timestamp: drift.Value(message.timestamp),
      error: drift.Value(message.error),
      isTyping: drift.Value(message.isTyping),
      imagePath: drift.Value(imagePath),
    ));

    // Sync to cloud (if authenticated)
    // Cloud sync removed - messages stored locally only
    // TODO: Implement Supabase chat message sync
    if (shouldSync && !message.isTyping) {
      Log.d('Message saved locally (cloud sync not implemented)', label: 'Chat Provider');
    }
  }

  Future<void> sendMessage(String content, {Uint8List? imageBytes}) async {
    print('🚀 [DEBUG] sendMessage() CALLED with content: ${content.substring(0, content.length > 30 ? 30 : content.length)}... imageBytes: ${imageBytes != null ? "${imageBytes.length} bytes" : "null"}');
    if ((content.trim().isEmpty && imageBytes == null) || state.isLoading) return;

    // Check AI message limit (skip in debug mode for testing)
    final aiUsageService = ref.read(aiUsageServiceProvider);
    final limits = ref.read(subscriptionLimitsProvider);
    const isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    if (!isDebugMode && !aiUsageService.canSendMessage(limits)) {
      Log.w('AI message limit reached: 0 remaining', label: 'Chat');

      // Add user message first
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        content: content.trim(),
        isFromUser: true,
        timestamp: DateTime.now(),
        imageBytes: imageBytes,
      );

      // Create limit reached message in chat (not as error toast)
      final used = aiUsageService.getUsedMessagesThisMonth();
      final max = limits.maxAiMessagesPerMonth;
      final limitMessage = ChatMessage(
        id: _uuid.v4(),
        content: '⚠️ **Đã hết lượt chat AI tháng này**\n\n'
            'Bạn đã sử dụng **$used/$max** tin nhắn AI trong tháng.\n\n'
            '💡 Nâng cấp lên **Plus** để có 240 tin nhắn/tháng, hoặc **Pro** để không giới hạn.',
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, userMessage, limitMessage],
      );
      return;
    }

    // NOTE: DO NOT invalidate aiServiceProvider here!
    // Invalidating destroys the service instance and loses conversation history
    // Categories are watched by the provider and will auto-update when changed

    // Refresh wallet providers to ensure latest data
    ref.invalidate(activeWalletProvider);
    ref.read(activeWalletProvider); // Force rebuild active wallet

    ref.invalidate(allWalletsStreamProvider);
    ref.read(allWalletsStreamProvider); // Force rebuild all wallets

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content.trim(),
      isFromUser: true,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
    );

    // Add user message and set loading state
    print('[CHAT_DEBUG] Adding user message. Current count: ${state.messages.length}');

    // If image is provided, show analyzing indicator immediately (before any async ops)
    // so user sees feedback right away without waiting for DB save.
    final List<ChatMessage> initialMessages = [
      ...state.messages,
      userMessage,
      if (imageBytes != null)
        ChatMessage(
          id: 'typing_indicator',
          content: 'Đang phân tích hình ảnh...',
          isFromUser: false,
          timestamp: DateTime.now(),
          isTyping: true,
        ),
    ];
    state = state.copyWith(
      messages: initialMessages,
      isLoading: true,
      isTyping: imageBytes != null,
      error: null,
    );
    print('[CHAT_DEBUG] User message added. New count: ${state.messages.length}');

    // Save user message to database in background (non-blocking for UX)
    unawaited(_saveMessageToDatabase(userMessage));

    try {
      // If image is provided, analyze it (receipt or banking screenshot)
      String enhancedContent = content;
      if (imageBytes != null) {
        print('📸 [RECEIPT] Image detected, analyzing...');
        Log.d('Image detected, analyzing...', label: 'Chat Provider');

        try {
          final receiptService = ref.read(receiptScannerServiceProvider);
          final results = await receiptService.analyzeScreenshot(imageBytes: imageBytes);

          if (results.length > 1) {
            // Multi-transaction: banking screenshot
            Log.d('Banking screenshot: ${results.length} transactions extracted', label: 'Chat Provider');

            // Deduplicate against existing transactions
            final deduped = await _deduplicateScreenshotResults(results);
            final skipped = results.length - deduped.length;

            // Remove analyzing indicator
            final messagesWithoutAnalyzing = state.messages
                .where((msg) => !msg.isTyping)
                .toList();

            if (deduped.isEmpty) {
              // All duplicates
              final aiMsg = ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content: '🔍 Đã quét **${results.length} giao dịch** nhưng tất cả đã có trong ví. Không có giao dịch mới.',
                isFromUser: false,
                timestamp: DateTime.now(),
              );
              state = state.copyWith(
                messages: [...messagesWithoutAnalyzing, aiMsg],
                isLoading: false,
                isTyping: false,
              );
              unawaited(_saveMessageToDatabase(aiMsg));
              return;
            }

            // Store for quick action handling
            _pendingScreenshotTransactions = deduped;

            final walletName = ref.read(activeWalletProvider).value?.name ?? 'My VND Wallet';
            final summaryLines = deduped.take(5).map((r) =>
              '• ${r.merchant} — ${_formatAmount(r.amount, currency: r.currency ?? 'VND')}'
            ).join('\n');
            final moreText = deduped.length > 5 ? '\n• ... và ${deduped.length - 5} giao dịch khác' : '';

            final aiMsg = ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: '🔍 Đã quét **${results.length} giao dịch**${skipped > 0 ? ' (bỏ $skipped trùng)' : ''}. '
                  '**${deduped.length} giao dịch mới**:\n\n$summaryLines$moreText',
              isFromUser: false,
              timestamp: DateTime.now(),
              pendingAction: PendingAction(
                actionType: 'screenshot_transactions',
                actionData: {
                  'count': deduped.length,
                  'walletName': walletName,
                },
                buttons: [
                  ChatActionButton(
                    label: '✅ Thêm tất cả ${deduped.length} vào $walletName',
                    actionType: 'screenshot_bulk_create',
                  ),
                  ChatActionButton(
                    label: '📋 Duyệt ở danh sách chờ',
                    actionType: 'screenshot_to_pending',
                  ),
                ],
              ),
            );

            state = state.copyWith(
              messages: [...messagesWithoutAnalyzing, aiMsg],
              isLoading: false,
              isTyping: false,
            );
            unawaited(_saveMessageToDatabase(aiMsg));
            return;
          }

          // Single receipt — existing flow
          final receiptResult = results.first;
          print('📸 [RECEIPT] Receipt analyzed: ${receiptResult.merchant}, ${receiptResult.amount} ${receiptResult.currency}');
          Log.d('Receipt analyzed: ${receiptResult.merchant}, ${receiptResult.amount} ${receiptResult.currency}', label: 'Chat Provider');

          _currentReceiptImage = imageBytes;

          enhancedContent = '''${content.trim()}

RECEIPT_DATA:
- Merchant: ${receiptResult.merchant}
- Amount: ${receiptResult.amount} ${receiptResult.currency ?? 'VND'}
- Date: ${receiptResult.date}
- Category: ${receiptResult.category}
- Payment Method: ${receiptResult.paymentMethod}
- Items: ${receiptResult.items.join(', ')}
${receiptResult.taxAmount != null ? '- Tax: ${receiptResult.taxAmount}' : ''}
${receiptResult.tipAmount != null ? '- Tip: ${receiptResult.tipAmount}' : ''}

Please create a transaction based on this receipt data.''';

          print('📸 [RECEIPT] Enhanced content prepared');
        } catch (e) {
          print('❌ [RECEIPT] Failed to analyze image: $e');
          Log.e('Failed to analyze image: $e', label: 'Chat Provider');
          enhancedContent = '${content.trim()}\n\n[Failed to analyze image. Please try again or enter transaction details manually.]';
          _currentReceiptImage = null;
        }

        // Remove "analyzing image" indicator
        final messagesWithoutAnalyzing = state.messages
            .where((msg) => !msg.isTyping)
            .toList();
        state = state.copyWith(
          messages: messagesWithoutAnalyzing,
          isTyping: false,
        );
      }

      // Update AI with recent transactions, budgets, and spending insights before sending message
      await _updateRecentTransactionsContext();
      await _updateBudgetsContext();
      await _updateSpendingInsightsContext();

      // Update AI with current wallet context (CRITICAL: wallet list must be current!)
      print('🔧 [CHAT_DEBUG] About to update AI context...');
      final activeWallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      print('🔧 [CHAT_DEBUG] Active wallet: ${activeWallet?.name} (${activeWallet?.currency})');
      final allWalletsAsync = ref.read(allWalletsStreamProvider);
      final allWallets = _unwrapAsyncValue(allWalletsAsync) ?? [];
      print('🔧 [CHAT_DEBUG] All wallets count: ${allWallets.length}');
      final walletNames = allWallets.map((w) => '${w.name} (${w.currency}, ${w.walletType.displayName})').toList();
      print('🔧 [CHAT_DEBUG] Wallet names: ${walletNames.join(", ")}');
      final exchangeRateCache = ref.read(exchangeRateCacheProvider);
      final cachedRate = exchangeRateCache['VND_USD'];
      print('🔧 [CHAT_DEBUG] Exchange rate from cache: ${cachedRate?.rate} (key: VND_USD, cache size: ${exchangeRateCache.length})');

      // If no active wallet, use default wallet as fallback
      final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
      final fallbackWallet = activeWallet ?? defaultWallet ?? (allWallets.isNotEmpty ? allWallets.first : null);
      print('🔧 [CHAT_DEBUG] Using wallet for context: ${fallbackWallet?.name} (${fallbackWallet?.currency})');
      print('🔧 [CHAT_DEBUG] Calling updateContext()...');

      _aiService.updateContext(
        walletName: fallbackWallet?.name ?? 'Active Wallet',
        walletCurrency: fallbackWallet?.currency ?? 'VND',
        wallets: walletNames,
        exchangeRate: cachedRate?.rate,
      );

      print('🔧 [CHAT_DEBUG] updateContext() completed!');

      // Start typing indicator
      _startTypingEffect();

      // Get AI response with fallback (DOS AI -> Gemini if timeout)
      final response = await _sendMessageWithFallback(enhancedContent);

      print('📱 [DEBUG] AI Response received, length: ${response.length}');
      print('📱 [DEBUG] Used fallback: $_usingFallback, model: $_actualModelName');
      print('📱 [DEBUG] Response FULL: $response');
      print('📱 [DEBUG] Contains ACTION_JSON: ${response.contains('ACTION_JSON')}');
      Log.d('AI Response: $response', label: 'Chat Provider');

      // NOTE: Do NOT cancel typing effect here - we'll replace the typing message instead
      // This creates a smooth transition from "..." to actual message

      // Extract JSON action if present
      String displayMessage = response;
      PendingAction? pendingAction; // For destructive actions requiring confirmation

      // Extract ACTION_JSON by finding balanced braces (handles any JSON structure)
      final List<Map<String, dynamic>> actions = [];
      int? firstJsonStart;

      final actionPrefix = 'ACTION_JSON:';
      int searchStart = 0;
      while (true) {
        final prefixIndex = response.indexOf(actionPrefix, searchStart);
        if (prefixIndex == -1) break;

        firstJsonStart ??= prefixIndex;

        // Find the opening brace
        final braceStart = response.indexOf('{', prefixIndex);
        if (braceStart == -1) break;

        // Find matching closing brace by counting braces
        int braceCount = 0;
        int? jsonEnd;
        for (int i = braceStart; i < response.length; i++) {
          if (response[i] == '{') braceCount++;
          if (response[i] == '}') braceCount--;
          if (braceCount == 0) {
            jsonEnd = i + 1;
            break;
          }
        }

        if (jsonEnd != null) {
          final jsonStr = response.substring(braceStart, jsonEnd);
          print('📱 [DEBUG] Extracted JSON: $jsonStr');
          Log.d('🔍 Extracted JSON: $jsonStr', label: 'Chat Provider');

          try {
            final decoded = jsonDecode(jsonStr);
            if (decoded is Map<String, dynamic>) {
              actions.add(decoded);
              print('📱 [DEBUG] Parsed action: ${decoded['action']}, requiresConfirmation: ${decoded['requiresConfirmation']}');
            }
          } catch (e) {
            Log.e('Failed to parse ACTION_JSON: $e', label: 'Chat Provider');
          }
        }

        searchStart = prefixIndex + actionPrefix.length;
      }

      print('📱 [DEBUG] Found ${actions.length} ACTION_JSON actions');
      Log.d('🔍 Found ${actions.length} ACTION_JSON actions', label: 'Chat Provider');

      // Strip any "ACTION_JSON: null" or bare "ACTION_JSON:" lines from display message
      // This happens when the model outputs it literally instead of omitting it
      displayMessage = displayMessage.replaceAll(RegExp(r'ACTION_JSON:\s*null', caseSensitive: false), '').trim();

      if (actions.isNotEmpty) {
        print('📱 [DEBUG] Processing ${actions.length} actions...');

        // Extract the display message (everything before first ACTION_JSON)
        if (firstJsonStart != null) {
          displayMessage = response.substring(0, firstJsonStart).trim();
        }

        Log.d('🔍 Total actions parsed: ${actions.length}', label: 'Chat Provider');

        try {
          // Process each action
          for (final action in actions) {
          // Parse the action
          String actionType = (action['action'] ?? '').toString();
          Log.d('🔍 Action type: $actionType', label: 'Chat Provider');

          // SAFETY NET: LLM (especially smaller models like Qwen3.5) often misses
          // recurring indicators and creates one-time transactions instead.
          // Auto-upgrade to create_recurring when user message contains frequency keywords.
          if (actionType == 'create_expense' || actionType == 'create_income') {
            final lowerMsg = content.toLowerCase();
            final hasRecurringKeyword = RegExp(
              r'\b(mỗi tháng|hàng tháng|hằng tháng|mỗi tuần|hàng tuần|hằng tuần|mỗi ngày|hàng ngày|hằng ngày|mỗi năm|hàng năm|hằng năm|monthly|weekly|daily|yearly|every\s+(month|week|day|year)|định kỳ|recurring|subscription)\b',
              caseSensitive: false,
            ).hasMatch(lowerMsg);

            if (hasRecurringKeyword) {
              Log.w('⚠️ SAFETY NET: LLM returned $actionType but user message contains recurring keywords. Upgrading to create_recurring.', label: 'Chat Provider');

              // Detect frequency from user message
              String frequency = 'monthly'; // default
              if (RegExp(r'mỗi ngày|hàng ngày|hằng ngày|daily|every\s+day', caseSensitive: false).hasMatch(lowerMsg)) {
                frequency = 'daily';
              } else if (RegExp(r'mỗi tuần|hàng tuần|hằng tuần|weekly|every\s+week', caseSensitive: false).hasMatch(lowerMsg)) {
                frequency = 'weekly';
              } else if (RegExp(r'mỗi năm|hàng năm|hằng năm|yearly|every\s+year', caseSensitive: false).hasMatch(lowerMsg)) {
                frequency = 'yearly';
              }

              // Detect if income based on original action type or category
              final isIncome = actionType == 'create_income';

              // Convert action to create_recurring
              actionType = 'create_recurring';
              action['action'] = 'create_recurring';
              action['frequency'] = action['frequency'] ?? frequency;
              action['name'] = action['description'] ?? action['name'] ?? 'Recurring Payment';
              action['autoCreate'] = action['autoCreate'] ?? true;
              if (isIncome) action['isIncome'] = true;

              // Try to parse due day from message (e.g., "vào ngày 5", "on the 25th")
              final dayMatch = RegExp(r'(?:ngày|on\s+(?:the\s+)?|day\s+)(\d{1,2})').firstMatch(lowerMsg);
              if (dayMatch != null && action['nextDueDate'] == null) {
                final day = int.parse(dayMatch.group(1)!);
                if (day >= 1 && day <= 31) {
                  final now = DateTime.now();
                  var nextDate = DateTime(now.year, now.month, day);
                  if (nextDate.isBefore(now)) {
                    nextDate = DateTime(now.year, now.month + 1, day);
                  }
                  action['nextDueDate'] = nextDate.toIso8601String().split('T')[0];
                }
              }

              Log.d('Upgraded action: frequency=$frequency, isIncome=$isIncome, name=${action['name']}', label: 'Chat Provider');
            }
          }

          switch (actionType) {
            case 'create_expense':
            case 'create_income':
              {
                // Get currency from AI action
                final double amount = (action['amount'] as num).toDouble();
                final String aiCurrency = action['currency'] ?? 'VND';
                final String? aiWalletName = action['wallet']; // Get wallet name from AI

                Log.d('AI action: amount=$amount, currency=$aiCurrency, wallet=${aiWalletName ?? "not specified"}', label: 'AI_CURRENCY');

                // IMPORTANT: Query wallets directly from database instead of using Stream provider
                // Stream providers may not have latest data immediately after invalidate
                final walletDao = ref.read(walletDaoProvider);
                final walletEntities = await walletDao.getAllWallets();
                final allWallets = walletEntities.map((w) => WalletModel(
                  id: w.id,
                  cloudId: w.cloudId,
                  name: w.name,
                  balance: w.balance,
                  currency: w.currency,
                  createdAt: w.createdAt,
                  updatedAt: w.updatedAt,
                )).toList();

                Log.d('Fetched ${allWallets.length} wallets from database', label: 'Chat Provider');

                WalletModel? wallet;

                // Priority 1: If AI specified a wallet name, use it
                if (aiWalletName != null && aiWalletName.isNotEmpty) {
                  final aiWalletLower = aiWalletName.toLowerCase();

                  // Try exact match first
                  wallet = allWallets.firstWhereOrNull((w) =>
                    w.name.toLowerCase() == aiWalletLower);

                  // Try partial match (e.g., "Credit Card" matches "Credit Card 1")
                  if (wallet == null) {
                    wallet = allWallets.firstWhereOrNull((w) =>
                      w.name.toLowerCase().contains(aiWalletLower) ||
                      aiWalletLower.contains(w.name.toLowerCase()));
                  }

                  // Try wallet type match (e.g., "Credit Card" matches walletType.creditCard)
                  if (wallet == null) {
                    wallet = allWallets.firstWhereOrNull((w) {
                      final typeName = w.walletType.displayName.toLowerCase();
                      return typeName == aiWalletLower ||
                             typeName.contains(aiWalletLower) ||
                             aiWalletLower.contains(typeName);
                    });
                  }

                  if (wallet != null) {
                    Log.d('Using AI-specified wallet: "${wallet.name}" (${wallet.currency})', label: 'AI_CURRENCY');
                  } else {
                    Log.w('AI specified wallet "$aiWalletName" not found, falling back to currency matching', label: 'AI_CURRENCY');
                  }
                }

                // Priority 2: Match wallet by currency
                if (wallet == null) {
                  wallet = allWallets.firstWhereOrNull((w) => w.currency == aiCurrency);

                  if (wallet != null) {
                    Log.d('Found wallet "${wallet.name}" for currency $aiCurrency (no conversion needed)', label: 'AI_CURRENCY');
                  }
                }

                // Priority 3: Use default wallet, then first available wallet
                if (wallet == null && allWallets.isNotEmpty) {
                  final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
                  wallet = defaultWallet ?? allWallets.first;
                  Log.d('No wallet found for $aiCurrency, using ${defaultWallet != null ? "default" : "first"} wallet: ${wallet.name} (${wallet.currency}) - will convert', label: 'AI_CURRENCY');
                }

                if (wallet == null) {
                  Log.e('No wallet available', label: 'Chat Provider');
                  displayMessage += '\n\n❌ No wallet available.';
                  break;
                }

                final description = action['description'];
                final category = action['category'];
                Log.d('Creating transaction: action=${action['action']}, amount=$amount $aiCurrency, desc=$description, cat=$category', label: 'Chat Provider');

                // Get the actual amount saved (after currency conversion if needed)
                final actualAmount = await _createTransactionFromAction(action, wallet: wallet, userMessage: content);

                // If transaction creation failed, don't show success message from AI
                // Error message was already added by _createTransactionFromAction via _addErrorMessage
                if (actualAmount == null) {
                  displayMessage = ''; // Clear success message, error is already shown
                  break;
                }

                // IMPORTANT: Replace "Active Wallet" with actual wallet name in AI response
                // AI service was built with potentially stale wallet info, so we fix it here
                displayMessage = displayMessage.replaceAll('Active Wallet', wallet.name);

                // Add conversion info if currency was converted
                // Show wallet currency amount first, with note about original amount
                if (aiCurrency != wallet.currency) {
                  // Format amounts with proper separators
                  final convertedFormatted = _formatAmount(actualAmount, currency: wallet.currency);
                  final originalFormatted = _formatAmount(amount, currency: aiCurrency);

                  // Build conversion note: "(Quy đổi từ 333.000 đ)"
                  String conversionNote;
                  if (displayMessage.contains('已记录') || displayMessage.contains('记录')) {
                    conversionNote = '(兑换自 $originalFormatted)';
                  } else if (displayMessage.contains('Đã ghi nhận') || displayMessage.contains('đã ghi nhận')) {
                    conversionNote = '(Quy đổi từ $originalFormatted)';
                  } else {
                    conversionNote = '(Converted from $originalFormatted)';
                  }

                  // AI response contains original amount in various formats:
                  // - "500,000 VND" (AI format with comma separator)
                  // We need to REPLACE it with wallet currency amount + conversion note
                  bool replaced = false;

                  // Build AI format for VND (AI uses comma separator)
                  String aiFormatAmount = '';
                  if (aiCurrency == 'VND') {
                    final amountInt = amount.round();
                    aiFormatAmount = '${amountInt.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} VND';
                  }

                  // Pattern 1: Try AI format with bold markdown (e.g., **500,000 VND**)
                  // Replace with wallet currency: **$19** (Quy đổi từ 500.000 đ)
                  if (aiFormatAmount.isNotEmpty) {
                    final boldAiPattern = '**$aiFormatAmount**';
                    if (displayMessage.contains(boldAiPattern)) {
                      displayMessage = displayMessage.replaceFirst(
                        boldAiPattern,
                        '**$convertedFormatted** $conversionNote'
                      );
                      replaced = true;
                      Log.d('Replaced bold AI pattern with wallet currency: $boldAiPattern → $convertedFormatted', label: 'Chat Provider');
                    }
                  }

                  // Pattern 2: Try AI format plain (e.g., 500,000 VND)
                  if (!replaced && aiFormatAmount.isNotEmpty && displayMessage.contains(aiFormatAmount)) {
                    displayMessage = displayMessage.replaceFirst(
                      aiFormatAmount,
                      '$convertedFormatted $conversionNote'
                    );
                    replaced = true;
                    Log.d('Replaced plain AI pattern with wallet currency: $aiFormatAmount → $convertedFormatted', label: 'Chat Provider');
                  }

                  // Pattern 3: Try our format with bold markdown (e.g., **500.000 đ**)
                  if (!replaced) {
                    final boldPattern = '**$originalFormatted**';
                    if (displayMessage.contains(boldPattern)) {
                      displayMessage = displayMessage.replaceFirst(
                        boldPattern,
                        '**$convertedFormatted** $conversionNote'
                      );
                      replaced = true;
                      Log.d('Replaced bold pattern with wallet currency: $boldPattern → $convertedFormatted', label: 'Chat Provider');
                    }
                  }

                  // Pattern 4: Try our format plain (e.g., 500.000 đ)
                  if (!replaced && displayMessage.contains(originalFormatted)) {
                    displayMessage = displayMessage.replaceFirst(
                      originalFormatted,
                      '$convertedFormatted $conversionNote'
                    );
                    replaced = true;
                    Log.d('Replaced plain pattern with wallet currency: $originalFormatted → $convertedFormatted', label: 'Chat Provider');
                  }

                  // Pattern 5: If still not found, prepend wallet amount after emoji
                  if (!replaced) {
                    if (displayMessage.startsWith('✅')) {
                      final afterEmoji = displayMessage.substring(1).trimLeft();
                      displayMessage = '✅ $convertedFormatted $conversionNote - $afterEmoji';
                    } else {
                      displayMessage = '$convertedFormatted $conversionNote - $displayMessage';
                    }
                    Log.d('Prepended wallet currency at start', label: 'Chat Provider');
                  }

                  Log.d('Converted display: $originalFormatted → $convertedFormatted', label: 'Chat Provider');
                }

                break;
              }
            case 'create_budget':
              {
                Log.d('Processing create_budget action: $action', label: 'Chat Provider');

                var wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
                if (wallet == null) {
                  final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
                  if (defaultWallet != null) {
                    wallet = defaultWallet;
                  } else {
                    final allWallets = _unwrapAsyncValue(ref.read(allWalletsStreamProvider)) ?? [];
                    if (allWallets.isNotEmpty) wallet = allWallets.first;
                  }
                }
                if (wallet == null) {
                  displayMessage += '\n\n❌ No active wallet selected.';
                  break;
                }

                // Handle currency conversion if needed
                final walletCurrency = wallet.currency ?? 'VND';
                double amount = (action['amount'] as num).toDouble();
                final aiCurrency = action['currency'] ?? 'VND';

                // Convert VND to USD if wallet uses USD
                if (aiCurrency == 'VND' && walletCurrency == 'USD') {
                  amount = amount / 25000;
                }

                final budgetCreated = await _createBudgetFromAction({
                  ...action,
                  'amount': amount,
                });

                // If budget creation failed, don't show success message from AI
                // Error message was already added by _createBudgetFromAction via _addErrorMessage
                if (!budgetCreated) {
                  displayMessage = ''; // Clear success message, error is already shown
                }
                break;
              }
            case 'create_goal':
              {
                Log.d('Processing create_goal action: $action', label: 'Chat Provider');

                var wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
                if (wallet == null) {
                  final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
                  if (defaultWallet != null) {
                    wallet = defaultWallet;
                  } else {
                    final allWallets = _unwrapAsyncValue(ref.read(allWalletsStreamProvider)) ?? [];
                    if (allWallets.isNotEmpty) wallet = allWallets.first;
                  }
                }
                if (wallet == null) {
                  displayMessage += '\n\n❌ No active wallet selected.';
                  break;
                }

                // Handle currency conversion if needed
                final walletCurrency = wallet.currency ?? 'VND';
                double targetAmount = (action['targetAmount'] as num).toDouble();
                double currentAmount = ((action['currentAmount'] ?? 0) as num).toDouble();
                final aiCurrency = action['currency'] ?? 'VND';

                // Convert VND to USD if wallet uses USD
                if (aiCurrency == 'VND' && walletCurrency == 'USD') {
                  targetAmount = targetAmount / 25000;
                  currentAmount = currentAmount / 25000;
                }

                await _createGoalFromAction({
                  ...action,
                  'targetAmount': targetAmount,
                  'currentAmount': currentAmount,
                });
                // AI already provides confirmation in user's language
                break;
              }
            case 'get_balance':
              {
                final balanceText = await _getActiveWalletBalanceText();
                displayMessage += '\n\n' + balanceText;
                break;
              }
            case 'get_summary':
              {
                final summaryText = await _getSummaryText(action);
                displayMessage += '\n\n' + summaryText;
                break;
              }
            case 'list_transactions':
              {
                final listText = await _getTransactionsListText(action);
                displayMessage += '\n\n' + listText;
                break;
              }
            case 'update_transaction':
              {
                Log.d('Processing update_transaction action: $action', label: 'Chat Provider');

                var wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
                if (wallet == null) {
                  final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
                  if (defaultWallet != null) {
                    wallet = defaultWallet;
                  } else {
                    final allWallets = _unwrapAsyncValue(ref.read(allWalletsStreamProvider)) ?? [];
                    if (allWallets.isNotEmpty) wallet = allWallets.first;
                  }
                }
                if (wallet == null) {
                  displayMessage += '\n\n❌ No active wallet selected.';
                  break;
                }

                final updateResult = await _updateTransactionFromAction(action);
                displayMessage += '\n\n' + updateResult;
                break;
              }
            case 'delete_transaction':
              {
                Log.d('Processing delete_transaction action: $action', label: 'Chat Provider');

                var wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
                if (wallet == null) {
                  final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
                  if (defaultWallet != null) {
                    wallet = defaultWallet;
                  } else {
                    final allWallets = _unwrapAsyncValue(ref.read(allWalletsStreamProvider)) ?? [];
                    if (allWallets.isNotEmpty) wallet = allWallets.first;
                  }
                }
                if (wallet == null) {
                  displayMessage += '\n\n❌ No active wallet selected.';
                  break;
                }

                final deleteResult = await _deleteTransactionFromAction(action);
                displayMessage += '\n\n' + deleteResult;
                break;
              }
            case 'create_wallet':
              {
                Log.d('Processing create_wallet action: $action', label: 'Chat Provider');

                final createResult = await _createWalletFromAction(action);
                displayMessage += '\n\n' + createResult;
                break;
              }
            case 'create_recurring':
              {
                Log.d('🔵 Processing create_recurring action: $action', label: 'Chat Provider');
                Log.d('🔵 AI Response: $response', label: 'Chat Provider');

                // CRITICAL: Query categories directly from database instead of relying on provider state
                // This avoids timing issues where StreamProvider hasn't emitted yet
                final categoryDao = ref.read(databaseProvider).categoryDao;
                final categoryEntities = await categoryDao.watchAllCategories().first;

                if (categoryEntities.isEmpty) {
                  Log.w('⚠️ Categories not loaded yet, skipping recurring creation. Action: $action', label: 'Chat Provider');
                  print('⚠️ [CREATE_RECURRING] Categories not ready, action skipped');
                  displayMessage += '\n\n⚠️ Error: Categories not loaded yet. Please try again in a few seconds.';
                  break;
                }

                Log.d('🔵 Loaded ${categoryEntities.length} categories from database', label: 'Chat Provider');

                // Get wallet used by recurring (query directly from database)
                final walletDao = ref.read(walletDaoProvider);
                final walletEntities = await walletDao.getAllWallets();
                final allWallets = walletEntities.map((w) => WalletModel(
                  id: w.id,
                  cloudId: w.cloudId,
                  name: w.name,
                  balance: w.balance,
                  currency: w.currency,
                  createdAt: w.createdAt,
                  updatedAt: w.updatedAt,
                )).toList();

                final aiCurrency = action['currency'] ?? 'VND';
                final originalAmount = (action['amount'] as num?)?.toDouble() ?? 0.0;
                final String? aiWalletName = action['wallet']; // Get wallet name from AI

                WalletModel? usedWallet;

                // Priority 1: If AI specified a wallet name, use it
                if (aiWalletName != null && aiWalletName.isNotEmpty) {
                  final aiWalletLower = aiWalletName.toLowerCase();

                  // Try exact match first
                  usedWallet = allWallets.firstWhereOrNull((w) =>
                    w.name.toLowerCase() == aiWalletLower);

                  // Try partial match (e.g., "Credit Card" matches "Credit Card 1")
                  if (usedWallet == null) {
                    usedWallet = allWallets.firstWhereOrNull((w) =>
                      w.name.toLowerCase().contains(aiWalletLower) ||
                      aiWalletLower.contains(w.name.toLowerCase()));
                  }

                  // Try wallet type match (e.g., "Credit Card" matches walletType.creditCard)
                  if (usedWallet == null) {
                    usedWallet = allWallets.firstWhereOrNull((w) {
                      final typeName = w.walletType.displayName.toLowerCase();
                      return typeName == aiWalletLower ||
                             typeName.contains(aiWalletLower) ||
                             aiWalletLower.contains(typeName);
                    });
                  }

                  if (usedWallet != null) {
                    Log.d('Using AI-specified wallet for recurring: "${usedWallet.name}" (${usedWallet.currency})', label: 'CREATE_RECURRING');
                  } else {
                    Log.w('AI specified wallet "$aiWalletName" not found for recurring, falling back to currency matching', label: 'CREATE_RECURRING');
                  }
                }

                // Priority 2: Match wallet by currency
                if (usedWallet == null) {
                  usedWallet = allWallets.firstWhereOrNull((w) => w.currency == aiCurrency);
                }

                // Priority 3: Use default wallet, then first available wallet
                if (usedWallet == null && allWallets.isNotEmpty) {
                  final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
                  usedWallet = defaultWallet ?? allWallets.first;
                }

                Log.d('🔵 Calling _createRecurringFromAction...', label: 'Chat Provider');
                double? convertedAmount;
                try {
                  convertedAmount = await _createRecurringFromAction(action, userMessage: content);
                  Log.d('✅ _createRecurringFromAction completed', label: 'Chat Provider');
                } catch (e) {
                  Log.e('❌ _createRecurringFromAction failed: $e', label: 'Chat Provider');
                  _addErrorMessage('❌ $e');
                  displayMessage = ''; // Clear success message, error is already shown
                  break;
                }

                // IMPORTANT: Replace "Active Wallet" with actual wallet name in AI response
                if (usedWallet != null) {
                  displayMessage = displayMessage.replaceAll('Active Wallet', usedWallet.name);

                  // Add conversion info if currency was converted
                  if (aiCurrency != usedWallet.currency && convertedAmount != null) {
                    // Format amounts with proper separators
                    final convertedFormatted = _formatAmount(convertedAmount, currency: usedWallet.currency);
                    final originalFormatted = _formatAmount(originalAmount, currency: aiCurrency);

                    // Build conversion text in user's language (detect from AI response)
                    String conversionText;
                    if (displayMessage.contains('已记录') || displayMessage.contains('记录')) {
                      // Chinese
                      conversionText = ' (自动从 $originalFormatted 转换)';
                    } else if (displayMessage.contains('Đã ghi nhận') || displayMessage.contains('đã ghi nhận')) {
                      // Vietnamese
                      conversionText = ' (tự động quy đổi từ $originalFormatted)';
                    } else {
                      // English (default)
                      conversionText = ' (auto-converted from $originalFormatted)';
                    }

                    // Insert conversion info after the converted amount in displayMessage
                    displayMessage = displayMessage.replaceFirst(
                      convertedFormatted,
                      '$convertedFormatted$conversionText'
                    );

                    Log.d('Added conversion info to display message: $originalFormatted → $convertedFormatted', label: 'Chat Provider');
                  }
                }

                // Note: No need to add confirmation message here because AI already provides
                // a natural language confirmation in its response with wallet name
                break;
              }
            case 'list_budgets':
              {
                Log.d('Processing list_budgets action: $action', label: 'Chat Provider');
                final listText = await _getBudgetsListText(action);
                displayMessage += '\n\n' + listText;
                break;
              }
            case 'list_goals':
              {
                Log.d('Processing list_goals action: $action', label: 'Chat Provider');
                final listText = await _getGoalsListText();
                displayMessage += '\n\n' + listText;
                break;
              }
            case 'list_recurring':
              {
                Log.d('Processing list_recurring action: $action', label: 'Chat Provider');
                final listText = await _getRecurringListText(action);
                displayMessage += '\n\n' + listText;
                break;
              }
            case 'delete_budget':
              {
                Log.d('Processing delete_budget action: $action', label: 'Chat Provider');
                // ALWAYS require confirmation for destructive actions - don't trust AI
                pendingAction = PendingAction(
                  actionType: 'delete_budget',
                  actionData: action,
                  buttons: [
                    ChatActionButton(label: 'Delete', actionType: 'confirm', actionData: action),
                    ChatActionButton(label: 'Cancel', actionType: 'cancel'),
                  ],
                );
                break;
              }
            case 'delete_all_budgets':
              {
                Log.d('Processing delete_all_budgets action: $action', label: 'Chat Provider');
                // ALWAYS require confirmation for destructive actions - don't trust AI
                pendingAction = PendingAction(
                  actionType: 'delete_all_budgets',
                  actionData: action,
                  buttons: [
                    ChatActionButton(label: 'Delete All', actionType: 'confirm', actionData: action),
                    ChatActionButton(label: 'Cancel', actionType: 'cancel'),
                  ],
                );
                break;
              }
            case 'update_budget':
              {
                Log.d('Processing update_budget action: $action', label: 'Chat Provider');
                // ALWAYS require confirmation for destructive actions - don't trust AI
                pendingAction = PendingAction(
                  actionType: 'update_budget',
                  actionData: action,
                  buttons: [
                    ChatActionButton(label: 'Update', actionType: 'confirm', actionData: action),
                    ChatActionButton(label: 'Cancel', actionType: 'cancel'),
                  ],
                );
                break;
              }
            case 'open_savings_account':
              {
                Log.d('Processing open_savings_account action: $action', label: 'Chat Provider');
                pendingAction = PendingAction(
                  actionType: 'open_savings_account',
                  actionData: action,
                  buttons: [
                    ChatActionButton(label: '✅ Open Account', actionType: 'confirm', actionData: action),
                    ChatActionButton(label: 'Cancel', actionType: 'cancel'),
                  ],
                );
                break;
              }
            case 'transfer_to_savings':
              {
                Log.d('Processing transfer_to_savings action: $action', label: 'Chat Provider');
                pendingAction = PendingAction(
                  actionType: 'transfer_to_savings',
                  actionData: action,
                  buttons: [
                    ChatActionButton(label: '✅ Transfer', actionType: 'confirm', actionData: action),
                    ChatActionButton(label: 'Cancel', actionType: 'cancel'),
                  ],
                );
                break;
              }
            case 'apply_credit_card':
              {
                Log.d('Processing apply_credit_card action: $action', label: 'Chat Provider');
                pendingAction = PendingAction(
                  actionType: 'apply_credit_card',
                  actionData: action,
                  buttons: [
                    ChatActionButton(label: '✅ Apply Now', actionType: 'confirm', actionData: action),
                    ChatActionButton(label: 'Cancel', actionType: 'cancel'),
                  ],
                );
                break;
              }
            case 'apply_loan':
              {
                Log.d('Processing apply_loan action: $action', label: 'Chat Provider');
                pendingAction = PendingAction(
                  actionType: 'apply_loan',
                  actionData: action,
                  buttons: [
                    ChatActionButton(label: '✅ Apply', actionType: 'confirm', actionData: action),
                    ChatActionButton(label: 'Cancel', actionType: 'cancel'),
                  ],
                );
                break;
              }
            default:
              {
                Log.d('Unknown action: $actionType', label: 'Chat Provider');
              }
          }
          } // end for loop
        } catch (e, stackTrace) {
          print('📱 [DEBUG] Exception caught while parsing: $e');
          print('📱 [DEBUG] Stack trace: $stackTrace');
          Log.e('Failed to parse AI action: $e', label: 'Chat Provider');
          // If JSON parsing fails, just show original response without JSON
        }
      }
      // REMOVED: Fallback inference logic
      // The AI should explicitly return ACTION_JSON when user wants to create a transaction
      // Otherwise, responding to AI questions with numbers would incorrectly create transactions

      print('[CHAT_DEBUG] pendingAction before create message: $pendingAction');
      print('[CHAT_DEBUG] pendingAction buttons: ${pendingAction?.buttons.length ?? 0}');
      print('[CHAT_DEBUG] displayMessage FINAL: $displayMessage');

      // Skip creating AI message if displayMessage is empty
      // This happens when transaction creation fails and error was already shown via _addErrorMessage
      if (displayMessage.isEmpty) {
        print('[CHAT_DEBUG] displayMessage is empty, skipping AI message creation (error already shown)');
        // Just remove typing indicator and update loading state
        try {
          final messagesWithoutTyping = state.messages
              .where((msg) => !msg.isTyping)
              .toList();
          state = state.copyWith(
            messages: messagesWithoutTyping,
            isLoading: false,
            isTyping: false,
          );
        } catch (e) {
          print('[CHAT_DEBUG] ⚠️ Failed to update state: $e');
        }
        return;
      }

      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: displayMessage,
        isFromUser: false,
        timestamp: DateTime.now(),
        pendingAction: pendingAction,
        modelName: _actualModelName, // Use actual model (considering fallback)
      );

      print('[CHAT_DEBUG] Created AI message: ${aiMessage.content.length > 50 ? aiMessage.content.substring(0, 50) + '...' : aiMessage.content}');
      print('[CHAT_DEBUG] AI message hasPendingAction: ${aiMessage.hasPendingAction}, model: ${aiMessage.modelName}, fallback: $_usingFallback');

      // Update state - wrap ALL state access in try-catch to handle dispose
      try {
        print('[CHAT_DEBUG] Current messages count: ${state.messages.length}');
        print('[CHAT_DEBUG] Replacing typing message with AI response...');

        // Replace typing message with actual AI message for smooth transition
        final messagesWithoutTyping = state.messages
            .where((msg) => !msg.isTyping)
            .toList();

        state = state.copyWith(
          messages: [...messagesWithoutTyping, aiMessage],
          isLoading: false,
          isTyping: false,
        );

        print('[CHAT_DEBUG] State updated! New messages count: ${state.messages.length}');
      } catch (e) {
        // Ignore dispose errors - message is saved to database below
        print('[CHAT_DEBUG] ⚠️ Failed to update state (likely disposed): $e');
        print('[CHAT_DEBUG] Message will be saved to DB and appear on next screen visit');
      }

      // Save AI message to database
      await _saveMessageToDatabase(aiMessage);

      // Increment AI message usage count
      await ref.read(aiUsageServiceProvider).incrementMessageCount();

      // NPS survey: increment counter and check if survey should show
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        NpsSurveyBottomSheet.incrementMessageCount(prefs);
        if (NpsSurveyBottomSheet.shouldShow(prefs)) {
          state = state.copyWith(showNpsSurvey: true);
        }
      } catch (e) {
        Log.e('NPS survey check failed: $e', label: 'Chat Provider');
      }

      Log.d('Message sent and response received successfully', label: 'Chat Provider');
    } catch (error) {
      _cancelTypingEffect();

      Log.e('Error sending message: $error', label: 'Chat Provider');

      // Show detailed error message for debugging
      String errorString = error.toString();
      String userFriendlyMessage = 'Error: $errorString';

      // Parse error message for user-friendly display
      if (errorString.contains('Invalid API key')) {
        userFriendlyMessage = 'Invalid API key: $errorString';
      } else if (errorString.contains('Rate limit')) {
        userFriendlyMessage = 'Rate limit: $errorString';
      } else if (errorString.contains('temporarily unavailable')) {
        userFriendlyMessage = 'Service unavailable: $errorString';
      } else if (errorString.contains('Failed host lookup') || errorString.contains('SocketException')) {
        userFriendlyMessage = 'Network error: $errorString';
      }

      // Add error message to chat
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        content: userFriendlyMessage,
        isFromUser: false,
        timestamp: DateTime.now(),
        error: errorString,
      );

      // Update state - remove typing message first, then add error message
      final messagesWithoutTyping = state.messages
          .where((msg) => !msg.isTyping)
          .toList();

      state = state.copyWith(
        messages: [...messagesWithoutTyping, errorMessage],
        isLoading: false,
        isTyping: false,
        error: errorString,
      );

      // Save error message to database
      await _saveMessageToDatabase(errorMessage);
    }
  }

  void _startTypingEffect() {
    state = state.copyWith(isTyping: true);

    // Add typing message
    final typingMessage = ChatMessage(
      id: 'typing_indicator',
      content: 'Typing...',
      isFromUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );

    state = state.copyWith(
      messages: [...state.messages, typingMessage],
    );
  }

  void _cancelTypingEffect() {
    if (!state.isTyping) return;

    // Remove typing message
    final messagesWithoutTyping = state.messages
        .where((message) => !message.isTyping)
        .toList();

    state = state.copyWith(
      messages: messagesWithoutTyping,
      isTyping: false,
    );

    _typingSubscription?.cancel();
  }

  void clearError() {
    Log.d('🗑️ clearError called - clearing error state', label: 'Chat Provider');
    state = state.copyWith(error: null);
    Log.d('✅ Error state cleared - error is now: ${state.error}', label: 'Chat Provider');
  }

  /// Dismiss the NPS survey trigger flag
  void dismissNpsSurvey() {
    state = state.copyWith(showNpsSurvey: false);
  }

  /// Update draft message (preserves user's typing when navigating away)
  void updateDraftMessage(String draft) {
    state = state.copyWith(draftMessage: draft);
  }

  void clearChat() async {
    _cancelTypingEffect();

    // Clear messages from database
    final dao = ref.read(chatMessageDaoProvider);
    await dao.clearAllMessages();

    // Cloud sync removed - messages cleared locally only
    Log.d('Chat messages cleared from local database', label: 'Chat Provider');

    // Clear AI conversation history
    _aiService.clearHistory();
    _fallbackGeminiService?.clearHistory();
    _fallbackGeminiService = null; // Reset fallback service
    Log.d('AI conversation history cleared', label: 'Chat Provider');

    // Reset state
    state = const ChatState();

    // Re-initialize with welcome message
    _initializeChat();
  }

  /// Returns the actual amount saved (after currency conversion if needed)
  Future<double?> _createTransactionFromAction(Map<String, dynamic> action, {WalletModel? wallet, String userMessage = ''}) async {
    try {
      // Print to console for debugging
      print('========================================');
      print('[TRANSACTION_DEBUG] _createTransactionFromAction START');
      print('[TRANSACTION_DEBUG] Action received: $action');

      Log.d('========================================', label: 'TRANSACTION_DEBUG');
      Log.d('_createTransactionFromAction START', label: 'TRANSACTION_DEBUG');
      Log.d('Action received: $action', label: 'TRANSACTION_DEBUG');

      // Use provided wallet or get current wallet
      if (wallet == null) {
        wallet = ref.read(activeWalletProvider).value;

        // If still no wallet, try to get default wallet, then first available wallet
        if (wallet == null) {
          final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
          if (defaultWallet != null) {
            wallet = defaultWallet;
            Log.d('No active wallet, using default wallet: ${wallet.name}', label: 'TRANSACTION_DEBUG');
          } else {
            final walletsAsync = ref.read(allWalletsStreamProvider);
            final allWallets = _unwrapAsyncValue(walletsAsync) ?? [];
            if (allWallets.isNotEmpty) {
              wallet = allWallets.first;
              Log.d('No active wallet, using first available: ${wallet.name}', label: 'TRANSACTION_DEBUG');
            }
          }
        }
      }

      print('[TRANSACTION_DEBUG] Wallet after checks: $wallet');

      if (wallet == null) {
        print('[TRANSACTION_DEBUG] ❌ ERROR: No wallet available!');
        Log.e('ERROR: No wallet available!', label: 'TRANSACTION_DEBUG');
        _addErrorMessage('❌ Cannot create transaction: No wallet available. Please create a wallet first.');
        return null;
      }

      print('[TRANSACTION_DEBUG] Wallet is not null, checking IDs...');
      print('[TRANSACTION_DEBUG] wallet.id = ${wallet.id}');
      print('[TRANSACTION_DEBUG] wallet.cloudId = ${wallet.cloudId}');

      // Wallet from cloud might not have local ID yet, only cloudId
      if (wallet.id == null && wallet.cloudId == null) {
        print('[TRANSACTION_DEBUG] ❌ ERROR: Wallet has neither local ID nor cloud ID!');
        Log.e('ERROR: Wallet has neither local ID nor cloud ID!', label: 'TRANSACTION_DEBUG');
        _addErrorMessage('❌ Cannot create transaction: Wallet configuration error. Please try again.');
        return null;
      }

      print('[TRANSACTION_DEBUG] ✅ Wallet validation passed!');
      print('[TRANSACTION_DEBUG] Using wallet: ${wallet.name} (id: ${wallet.id}, balance: ${wallet.balance} ${wallet.currency})');
      Log.d('Using wallet: ${wallet.name} (id: ${wallet.id}, balance: ${wallet.balance} ${wallet.currency})', label: 'TRANSACTION_DEBUG');

      // Get categories and find matching one
      // IMPORTANT: Query categories directly from database instead of using async provider
      // Async providers may not have latest data immediately
      final categoryDao = ref.read(categoryDaoProvider);
      final categoryEntities = await categoryDao.getAllCategories();

      // Convert entities to CategoryModel using built-in toModel() extension
      final List<CategoryModel> allCategories = categoryEntities.map((e) => e.toModel()).toList();

      print('[TRANSACTION_DEBUG] Fetched ${allCategories.length} categories directly from database');
      Log.d('Fetched ${allCategories.length} categories from database', label: 'TRANSACTION_DEBUG');

      final categoryName = action['category'] as String;
      Log.d('Looking for category: "$categoryName"', label: 'TRANSACTION_DEBUG');
      Log.d('Available flattened categories: ${allCategories.map((c) => c.title).join(", ")}', label: 'TRANSACTION_DEBUG');

      // Step 1: Exact match (case insensitive)
      CategoryModel? category = allCategories.firstWhereOrNull(
        (c) => c.title.toLowerCase() == categoryName.toLowerCase(),
      );

      if (category != null) {
        Log.d('✅ Category matched (exact): "${category.title}" (id: ${category.id})', label: 'TRANSACTION_DEBUG');
      }

      // Step 2: Translation map fallback (AI returns English, DB may have localized names)
      if (category == null) {
        final availableTitles = allCategories.map((c) => c.title).toList();
        final matchedTitle = CategoryTranslationMap.findMatchingCategory(
          categoryName,
          availableTitles,
        );
        if (matchedTitle != null) {
          category = allCategories.firstWhereOrNull((c) => c.title == matchedTitle);
          Log.d('✅ Category matched (translation): "$categoryName" → "${category?.title}"', label: 'TRANSACTION_DEBUG');
        }
      }

      // Step 3: Partial/contains match (e.g. "Coffee & Tea" matches "Coffee")
      if (category == null) {
        category = allCategories.firstWhereOrNull(
          (c) => c.title.toLowerCase().contains(categoryName.toLowerCase()) ||
                 categoryName.toLowerCase().contains(c.title.toLowerCase()),
        );
        if (category != null) {
          Log.d('✅ Category matched (partial): "$categoryName" → "${category.title}" (id: ${category.id})', label: 'TRANSACTION_DEBUG');
        }
      }

      // Step 4: If matched a parent category, use first subcategory
      if (category != null && category.subCategories != null && category.subCategories!.isNotEmpty) {
        Log.w('⚠️ Matched parent category "${category.title}", using first subcategory', label: 'TRANSACTION_DEBUG');
        category = category.subCategories!.first;
        Log.d('   → Switched to: "${category.title}" (id: ${category.id})', label: 'TRANSACTION_DEBUG');
      }

      // Step 5: Fallback to "Others"
      if (category == null) {
        final availableCategories = allCategories.map((c) => c.title).join(', ');
        Log.e('❌ Invalid category "$categoryName" from LLM. Available: $availableCategories', label: 'TRANSACTION_DEBUG');
        category = allCategories.firstWhereOrNull((c) => c.title == 'Others' && (c.subCategories == null || c.subCategories!.isEmpty));
        category ??= allCategories.firstWhereOrNull((c) => c.subCategories == null || c.subCategories!.isEmpty);
        if (category == null) {
          _addErrorMessage('❌ Category "$categoryName" not found. Please try again with a valid category.');
          return null;
        }
        Log.w('⚠️ Using fallback category: "${category.title}" (id: ${category.id})', label: 'TRANSACTION_DEBUG');
      }

      // Create transaction model
      // IMPORTANT: Get transaction type from CATEGORY, not from action
      // This ensures consistency - category.transactionType is the source of truth
      final transactionType = category.transactionType == 'income'
          ? TransactionType.income
          : TransactionType.expense;

      // Log for debugging
      Log.d('Transaction type from category "${category.title}": ${category.transactionType} → $transactionType', label: 'TRANSACTION_DEBUG');
      final rawLlmAmount = (action['amount'] as num).toDouble();
      final String? actionCurrency = action['currency'] as String?;
      final String walletCurrency = wallet.currency;
      // Sanity check: LLM often returns wrong VND amounts (e.g., 100tr → 100B instead of 100M)
      double amount = _sanitizeVndAmount(rawLlmAmount, userMessage, actionCurrency ?? walletCurrency);
      final rawTitle = action['description'] as String;
      // Capitalize first letter of title
      final title = rawTitle.isEmpty
          ? rawTitle
          : rawTitle[0].toUpperCase() + rawTitle.substring(1);

      // Parse date and time from action JSON
      // - date: "YYYY-MM-DD" format (e.g., "2024-12-01")
      // - time: "HH:MM" format (e.g., "19:00" for dinner, "07:00" for breakfast)
      final now = DateTime.now();
      DateTime date;
      final String? actionDate = action['date'] as String?;
      final String? actionTime = action['time'] as String?;

      if (actionDate != null && actionDate.isNotEmpty) {
        try {
          final parsedDate = DateTime.parse(actionDate);

          // Parse time if provided, otherwise use current time
          int hour = now.hour;
          int minute = now.minute;
          int second = now.second;

          if (actionTime != null && actionTime.isNotEmpty) {
            // Parse "HH:MM" format
            final timeParts = actionTime.split(':');
            if (timeParts.length >= 2) {
              hour = int.tryParse(timeParts[0]) ?? now.hour;
              minute = int.tryParse(timeParts[1]) ?? now.minute;
              second = 0; // Reset seconds when explicit time is given
            }
            Log.d('Parsed time from action: $actionTime → $hour:$minute', label: 'TRANSACTION_DEBUG');
          }

          date = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            hour,
            minute,
            second,
          );
          Log.d('Parsed datetime from action: $actionDate $actionTime → $date', label: 'TRANSACTION_DEBUG');
        } catch (e) {
          Log.w('Failed to parse date "$actionDate", using now: $e', label: 'TRANSACTION_DEBUG');
          date = now;
        }
      } else {
        // No date specified - use current datetime
        date = now;
      }

      // Debug currency detection
      Log.d('Action currency: $actionCurrency, Wallet currency: $walletCurrency', label: 'TRANSACTION_DEBUG');
      print('[TRANSACTION_DEBUG] 🔍 Action currency: $actionCurrency, Wallet currency: $walletCurrency');

      // Currency conversion if needed
      if (actionCurrency != null && actionCurrency != walletCurrency) {
        Log.d('Currency mismatch detected! Action: $actionCurrency, Wallet: $walletCurrency', label: 'TRANSACTION_DEBUG');
        print('[TRANSACTION_DEBUG] 💱 Currency conversion needed: $amount $actionCurrency → $walletCurrency');

        try {
          final exchangeRateService = ref.read(exchangeRateServiceProvider);
          // Use convertAmount() instead of getExchangeRate() - it has fallback logic
          final convertedAmount = await exchangeRateService.convertAmount(
            amount: amount,
            fromCurrency: actionCurrency,
            toCurrency: walletCurrency,
          );

          Log.d('Converted: $amount $actionCurrency → $convertedAmount $walletCurrency', label: 'TRANSACTION_DEBUG');
          print('[TRANSACTION_DEBUG] ✅ Converted: $amount $actionCurrency → $convertedAmount $walletCurrency');

          amount = convertedAmount;
        } catch (e) {
          Log.e('Currency conversion failed completely (no fallback available): $e', label: 'TRANSACTION_DEBUG');
          print('[TRANSACTION_DEBUG] ❌ Currency conversion failed: $e');
          _addErrorMessage('⚠️ Warning: Currency conversion from $actionCurrency to $walletCurrency failed. Using original amount.');
          // Continue with original amount as last resort
        }
      } else {
        Log.d('No currency conversion needed (both $walletCurrency)', label: 'TRANSACTION_DEBUG');
        print('[TRANSACTION_DEBUG] No currency conversion needed');
      }

      Log.d('Creating transaction model:', label: 'TRANSACTION_DEBUG');
      Log.d('  - Type: $transactionType', label: 'TRANSACTION_DEBUG');
      Log.d('  - Amount: $amount $walletCurrency', label: 'TRANSACTION_DEBUG');
      Log.d('  - Title: "$title"', label: 'TRANSACTION_DEBUG');
      Log.d('  - Date: $date', label: 'TRANSACTION_DEBUG');
      Log.d('  - Category ID: ${category.id}', label: 'TRANSACTION_DEBUG');
      Log.d('  - Wallet ID: ${wallet.id}', label: 'TRANSACTION_DEBUG');

      final transaction = TransactionModel(
        id: null, // Will be generated by database
        transactionType: transactionType,
        amount: amount,
        date: date,
        title: title,
        category: category,
        wallet: wallet,
        notes: 'Created by AI Assistant',
      );

      // Insert to database
      Log.d('Getting database instance...', label: 'TRANSACTION_DEBUG');
      final db = ref.read(databaseProvider);
      Log.d('Database instance obtained: $db', label: 'TRANSACTION_DEBUG');

      // Validate transaction before insert
      if (category.id == null) {
        Log.e('ERROR: Category ID is null!', label: 'TRANSACTION_DEBUG');
        _addErrorMessage('❌ Cannot create transaction: Category validation error. Please try again.');
        return null;
      }
      // Wallet must have either local ID or cloud ID (this should never happen after earlier checks)
      if (wallet.id == null && wallet.cloudId == null) {
        Log.e('ERROR: Wallet has neither local ID nor cloud ID!', label: 'TRANSACTION_DEBUG');
        _addErrorMessage('❌ Cannot create transaction: Wallet validation error. Please try again.');
        return null;
      }

      Log.d('Calling transactionDao.addTransaction()...', label: 'TRANSACTION_DEBUG');
      final transactionDao = ref.read(transactionDaoProvider);
      final insertedId = await transactionDao.addTransaction(transaction);

      print('[TRANSACTION_DEBUG] TRANSACTION INSERTED! ID: $insertedId');
      Log.d('TRANSACTION INSERTED! ID: $insertedId', label: 'TRANSACTION_DEBUG');

      // Verify transaction was saved
      if (insertedId <= 0) {
        print('[TRANSACTION_ERROR] Invalid insert ID: $insertedId');
        Log.e('ERROR: Invalid insert ID: $insertedId', label: 'TRANSACTION_DEBUG');
        _addErrorMessage('❌ Failed to save transaction to database. Please try again.');
        return null;
      }

      // Attach receipt image if available
      if (_currentReceiptImage != null) {
        try {
          print('📸 [RECEIPT] Attaching receipt image to transaction $insertedId');
          Log.d('Attaching receipt image to transaction $insertedId', label: 'TRANSACTION_DEBUG');

          final imageNotifier = ref.read(imageProvider.notifier);
          await imageNotifier.setImageFromBytes(_currentReceiptImage!);
          final savedPath = await imageNotifier.saveImage();

          if (savedPath != null) {
            // Update transaction with image path
            final updatedTransaction = transaction.copyWith(
              id: insertedId,
              imagePath: savedPath,
            );
            await transactionDao.updateTransaction(updatedTransaction);

            print('📸 [RECEIPT] Receipt image attached successfully: $savedPath');
            Log.d('Receipt image attached successfully: $savedPath', label: 'TRANSACTION_DEBUG');
          }

          // Clear receipt image after attaching
          _currentReceiptImage = null;
          imageNotifier.clearImage();
        } catch (e) {
          print('❌ [RECEIPT] Failed to attach receipt image: $e');
          Log.e('Failed to attach receipt image: $e', label: 'TRANSACTION_DEBUG');
          // Don't fail transaction creation if image attachment fails
        }
      }

      // NOTE: Wallet balance is already adjusted inside transactionDao.addTransaction()
      // Do NOT call _adjustWalletBalanceAfterCreate() here - it would cause double deduction!
      Log.d('Wallet balance already adjusted by DAO', label: 'TRANSACTION_DEBUG');

      // IMPORTANT: Force refresh providers to update UI
      // This ensures the transaction list and wallet balance are refreshed after insert
      Log.d('Forcing provider refresh...', label: 'TRANSACTION_DEBUG');

      // Invalidate transaction providers
      ref.invalidate(transactionListProvider);
      ref.invalidate(allTransactionsProvider);

      // Invalidate wallet providers to refresh balance in UI (dashboard, wallet selector, etc.)
      ref.invalidate(activeWalletProvider);
      ref.invalidate(allWalletsStreamProvider);

      Log.d('Transaction and wallet providers invalidated, UI should update', label: 'TRANSACTION_DEBUG');

      // Note: Success message is NOT added here because AI already provides
      // natural language confirmation in its response (e.g., "Đã ghi nhận chi tiêu...")
      // Adding another success message would create duplicate messages in the chat UI

      // TODO: Re-enable cloud sync after fixing data_sync_service.dart
      // try {
      //   Log.d('Triggering immediate cloud sync...', label: 'TRANSACTION_DEBUG');
      //   ref.read(dataSyncServiceProvider.notifier).syncAll();
      //   Log.d('Cloud sync triggered successfully', label: 'TRANSACTION_DEBUG');
      // } catch (e) {
      //   Log.i('Cloud sync failed (may not be authenticated): $e', label: 'TRANSACTION_DEBUG');
      // }

      Log.d('_createTransactionFromAction COMPLETE', label: 'TRANSACTION_DEBUG');
      Log.d('========================================', label: 'TRANSACTION_DEBUG');

      // Check for spending anomalies (async, non-blocking)
      try {
        final anomalyService = ref.read(spendingAnomalyServiceProvider);
        final anomaly = await anomalyService.checkTransaction(transaction);
        if (anomaly != null) {
          Log.w('Spending anomaly detected: ${anomaly.message}', label: 'SpendingAnomaly');
        }
      } catch (e) {
        Log.e('Anomaly check error: $e', label: 'SpendingAnomaly');
      }

      // Return the actual amount that was saved (after currency conversion)
      return amount;
    } catch (e, stackTrace) {
      print('========================================');
      print('[TRANSACTION_ERROR] CRITICAL ERROR in _createTransactionFromAction');
      print('[TRANSACTION_ERROR] Error: $e');
      print('[TRANSACTION_ERROR] Stack trace: $stackTrace');
      print('========================================');

      Log.e('========================================', label: 'TRANSACTION_ERROR');
      Log.e('CRITICAL ERROR in _createTransactionFromAction', label: 'TRANSACTION_ERROR');
      Log.e('Error type: ${e.runtimeType}', label: 'TRANSACTION_ERROR');
      Log.e('Error message: $e', label: 'TRANSACTION_ERROR');
      Log.e('Stack trace:\n$stackTrace', label: 'TRANSACTION_ERROR');
      Log.e('========================================', label: 'TRANSACTION_ERROR');

      return null;
    }
  }

  /// Returns true if budget was created successfully, false otherwise
  Future<bool> _createBudgetFromAction(Map<String, dynamic> action) async {
    Log.d('Creating budget from action: $action', label: 'BUDGET_DEBUG');

    try {
      var wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      if (wallet == null) {
        // Fallback: try default wallet, then first available
        final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
        if (defaultWallet != null) {
          wallet = defaultWallet;
          Log.d('No active wallet for budget, using default: ${wallet.name}', label: 'BUDGET_DEBUG');
        } else {
          final allWallets = _unwrapAsyncValue(ref.read(allWalletsStreamProvider)) ?? [];
          if (allWallets.isNotEmpty) {
            wallet = allWallets.first;
            Log.d('No active wallet for budget, using first available: ${wallet.name}', label: 'BUDGET_DEBUG');
          }
        }
      }
      if (wallet == null) {
        Log.e('No active wallet for budget creation', label: 'BUDGET_DEBUG');
        _addErrorMessage('❌ Cannot create budget: No wallet available. Please create a wallet first.');
        return false;
      }

      // Get category
      final categoryName = action['category']?.toString() ?? 'Others';
      Log.d('🔍 Searching for category: "$categoryName"', label: 'BUDGET_DEBUG');

      // CRITICAL FIX: Fetch categories directly from database to avoid provider race condition
      // (same issue as transaction creation - provider may not be loaded yet)
      final db = ref.read(databaseProvider);
      final categoryEntities = await db.categoryDao.getAllCategories();
      Log.d('📦 Fetched ${categoryEntities.length} categories directly from database', label: 'BUDGET_DEBUG');

      if (categoryEntities.isEmpty) {
        Log.e('❌ No categories available for budget', label: 'BUDGET_DEBUG');
        _addErrorMessage('❌ Cannot create budget: No categories available. Please create categories first.');
        return false;
      }

      // Convert to models and flatten hierarchy
      final List<CategoryModel> allCategories = [];
      final Map<String, CategoryModel> parentToFirstSubcategory = {};
      final Map<int?, List<CategoryModel>> childrenByParentIdMap = {};

      // Convert all entities to models
      final allModels = categoryEntities.map((e) => e.toModel()).toList();

      // Group by parentId
      for (final model in allModels) {
        childrenByParentIdMap.putIfAbsent(model.parentId, () => []).add(model);
      }

      // Get top-level categories (parentId == null)
      final topLevelCategories = childrenByParentIdMap[null] ?? [];

      // Flatten: Add all categories and build parent-to-subcategory mapping
      for (final parent in topLevelCategories) {
        allCategories.add(parent);
        final children = childrenByParentIdMap[parent.id] ?? [];
        if (children.isNotEmpty) {
          Log.d('  📁 ${parent.title} has ${children.length} subcategories: ${children.map((s) => s.title).join(", ")}', label: 'BUDGET_DEBUG');
          parentToFirstSubcategory[parent.title.toLowerCase()] = children.first;
          allCategories.addAll(children);
        } else {
          Log.d('  📄 ${parent.title} (no subcategories)', label: 'BUDGET_DEBUG');
        }
      }

      Log.d('📊 Total ${allCategories.length} categories available (including subcategories)', label: 'BUDGET_DEBUG');

      // Find matching category - PRIORITY ORDER:
      // 1. Exact match (case-insensitive)
      var category = allCategories.firstWhereOrNull(
        (c) => c.title.toLowerCase() == categoryName.toLowerCase()
      );

      if (category != null) {
        Log.d('✅ Step 1: Found EXACT match: "${category.title}" (ID: ${category.id})', label: 'BUDGET_DEBUG');
      }

      // 2. Partial match (case-insensitive)
      if (category == null) {
        category = allCategories.firstWhereOrNull(
          (c) => c.title.toLowerCase().contains(categoryName.toLowerCase()) ||
                 categoryName.toLowerCase().contains(c.title.toLowerCase())
        );
        if (category != null) {
          Log.d('✅ Step 2: Found PARTIAL match: "${category.title}" (ID: ${category.id})', label: 'BUDGET_DEBUG');
        }
      }

      // 3. If matched a parent category with subcategories, use first subcategory
      if (category != null && category.subCategories != null && category.subCategories!.isNotEmpty) {
        final originalCategory = category.title;
        Log.w('⚠️ Step 3: Matched PARENT category "$originalCategory" with subcategories, using first subcategory instead', label: 'BUDGET_DEBUG');
        category = category.subCategories!.first;
        Log.d('   → Switched to: "${category.title}" (ID: ${category.id})', label: 'BUDGET_DEBUG');
      }

      // 4. If still no match, try parent-to-subcategory map
      if (category == null) {
        category = parentToFirstSubcategory[categoryName.toLowerCase()];
        if (category != null) {
          Log.d('✅ Step 4: Found via parent mapping: "${category.title}" (ID: ${category.id})', label: 'BUDGET_DEBUG');
        }
      }

      // 4.5. Special case: "Bills" → search in Utilities subcategories
      if (category == null && categoryName.toLowerCase().contains('bill')) {
        Log.d('🔍 Step 4.5: Detected "bills" keyword, searching in Utilities subcategories...', label: 'BUDGET_DEBUG');
        final utilitiesParent = topLevelCategories.firstWhereOrNull(
          (c) => c.title.toLowerCase() == 'utilities'
        );
        if (utilitiesParent != null) {
          final subcategories = childrenByParentIdMap[utilitiesParent.id] ?? [];
          if (subcategories.isNotEmpty) {
            // Default to first utility (usually Electricity)
            category = subcategories.first;
            Log.d('✅ Step 4.5: Mapped "Bills" → "${category.title}" from Utilities', label: 'BUDGET_DEBUG');
          }
        }
      }

      // 5. Fallback to "Others" or first non-parent category
      if (category == null) {
        category = allCategories.firstWhereOrNull((c) => c.title == 'Others' && (c.subCategories == null || c.subCategories!.isEmpty));
        category ??= allCategories.firstWhereOrNull((c) => c.subCategories == null || c.subCategories!.isEmpty);
        if (category == null) {
          Log.e('❌ Step 5: No categories available for budget (even after fallback)', label: 'BUDGET_DEBUG');
          _addErrorMessage('❌ Cannot create budget: No valid category found.');
          return false;
        }
        Log.w('⚠️ Step 5: Using FALLBACK category: "${category.title}" (ID: ${category.id})', label: 'BUDGET_DEBUG');
      }

      Log.d('🎯 FINAL category for budget: "${category.title}" (ID: ${category.id})', label: 'BUDGET_DEBUG');

      // Determine budget period dates
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      final period = action['period']?.toString() ?? 'monthly';
      switch (period) {
        case 'weekly':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = startDate.add(Duration(days: 7));
          break;
        case 'custom':
          startDate = action['startDate'] != null
              ? DateTime.parse(action['startDate'])
              : DateTime(now.year, now.month, now.day);
          endDate = action['endDate'] != null
              ? DateTime.parse(action['endDate'])
              : startDate.add(Duration(days: 30));
          break;
        case 'monthly':
        default:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1).subtract(Duration(days: 1));
          break;
      }

      final amount = (action['amount'] as num).toDouble();
      final isRoutine = action['isRoutine'] ?? false;

      // Check for overlapping budget before creating
      // CRITICAL FIX: Fetch budgets directly from database to avoid provider race condition
      final budgetDao = ref.read(budgetDaoProvider);
      final existingBudgetEntities = await budgetDao.getAllBudgets();
      Log.d('📦 Fetched ${existingBudgetEntities.length} existing budgets from database', label: 'BUDGET_DEBUG');

      final categoryId = category.id;
      final walletId = wallet.id;

      // Check for overlapping periods: Budget periods should NOT overlap
      // Two periods overlap if: period1.start < period2.end AND period1.end > period2.start
      final hasOverlap = existingBudgetEntities.any((b) =>
          b.categoryId == categoryId &&
          b.walletId == walletId &&
          // Check if time periods overlap
          (b.startDate.isBefore(endDate) || b.startDate.isAtSameMomentAs(endDate)) &&
          (b.endDate.isAfter(startDate) || b.endDate.isAtSameMomentAs(startDate)));

      if (hasOverlap) {
        Log.w('⚠️ Budget period overlaps with existing budget for ${category.title}', label: 'BUDGET_DEBUG');
        _addErrorMessage('⚠️ Đã có ngân sách cho "${category.title}" trong khoảng thời gian này rồi. Vui lòng chọn thời gian khác.');
        return false; // CRITICAL: Return false to indicate failure, caller will skip success message
      }

      // Import budget model and providers
      final BudgetModel budget = BudgetModel(
        id: null,
        wallet: wallet,
        category: category,
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        isRoutine: isRoutine,
      );

      Log.d('Creating budget: amount=$amount, category=${category.title}, period=$period', label: 'BUDGET_DEBUG');

      // Save budget to database (budgetDao already fetched above for duplicate check)
      await budgetDao.addBudget(budget);

      Log.d('Budget created successfully', label: 'BUDGET_DEBUG');

      // Invalidate budget list to refresh UI
      ref.invalidate(budgetListProvider);

      // TODO: Re-enable cloud sync after fixing data_sync_service.dart
      // try {
      //   Log.d('Triggering immediate cloud sync...', label: 'BUDGET_DEBUG');
      //   ref.read(dataSyncServiceProvider.notifier).syncAll();
      //   Log.d('Cloud sync triggered successfully', label: 'BUDGET_DEBUG');
      // } catch (e) {
      //   Log.i('Cloud sync failed (may not be authenticated): $e', label: 'BUDGET_DEBUG');
      // }

      return true; // Success!

    } catch (e, stackTrace) {
      Log.e('Failed to create budget: $e', label: 'BUDGET_ERROR');
      Log.e('Stack trace: $stackTrace', label: 'BUDGET_ERROR');
      _addErrorMessage('❌ Lỗi khi tạo ngân sách: $e');
      return false;
    }
  }

  Future<void> _createGoalFromAction(Map<String, dynamic> action) async {
    Log.d('Creating goal from action: $action', label: 'GOAL_DEBUG');

    try {
      final title = action['title']?.toString() ?? 'New Goal';
      final targetAmount = (action['targetAmount'] as num).toDouble();
      final currentAmount = ((action['currentAmount'] ?? 0) as num).toDouble();
      final notes = action['notes']?.toString();

      // Parse deadline if provided
      final now = DateTime.now();
      DateTime endDate;

      if (action['deadline'] != null) {
        try {
          endDate = DateTime.parse(action['deadline']);
        } catch (e) {
          // Default to 1 year from now if parsing fails
          endDate = DateTime(now.year + 1, now.month, now.day);
        }
      } else {
        // Default to 1 year from now
        endDate = DateTime(now.year + 1, now.month, now.day);
      }

      final goal = GoalModel(
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        startDate: now,
        endDate: endDate,
        description: notes,
        createdAt: now,
      );

      Log.d('Creating goal: title=$title, target=$targetAmount, deadline=$endDate', label: 'GOAL_DEBUG');

      // Save goal to database
      final database = ref.read(databaseProvider);

      // Convert GoalModel to GoalsCompanion for insert
      final companion = db.GoalsCompanion(
        title: drift.Value(goal.title),
        targetAmount: drift.Value(goal.targetAmount),
        currentAmount: drift.Value(goal.currentAmount),
        startDate: drift.Value(goal.startDate),
        endDate: drift.Value(goal.endDate),
        iconName: drift.Value(goal.iconName),
        description: drift.Value(goal.description),
        createdAt: drift.Value(goal.createdAt ?? now),
        associatedAccountId: drift.Value(goal.associatedAccountId),
        pinned: drift.Value(goal.pinned),
      );

      final goalId = await database.goalDao.addGoal(companion);

      Log.d('Goal created successfully with ID: $goalId', label: 'GOAL_DEBUG');

      // Parse and create checklist items if provided
      if (action['checklist'] != null && action['checklist'] is List) {
        final checklistData = action['checklist'] as List;
        Log.d('Creating ${checklistData.length} checklist items...', label: 'GOAL_DEBUG');

        for (final item in checklistData) {
          if (item is Map<String, dynamic>) {
            final itemTitle = item['title']?.toString() ?? 'Checklist Item';
            final itemAmount = ((item['amount'] ?? 0) as num).toDouble();

            final checklistCompanion = db.ChecklistItemsCompanion(
              goalId: drift.Value(goalId),
              title: drift.Value(itemTitle),
              amount: drift.Value(itemAmount),
              completed: const drift.Value(false),
            );

            final checklistItemId = await database.checklistItemDao.addChecklistItem(checklistCompanion);
            Log.d('  ✅ Created checklist item "$itemTitle" (amount: $itemAmount) with ID: $checklistItemId', label: 'GOAL_DEBUG');
          }
        }

        Log.d('All checklist items created successfully', label: 'GOAL_DEBUG');
      }

      // Invalidate goal list to refresh UI
      ref.invalidate(goalsListProvider);

      // TODO: Re-enable cloud sync after fixing data_sync_service.dart
      // try {
      //   Log.d('Triggering immediate cloud sync...', label: 'GOAL_DEBUG');
      //   ref.read(dataSyncServiceProvider.notifier).syncAll();
      //   Log.d('Cloud sync triggered successfully', label: 'GOAL_DEBUG');
      // } catch (e) {
      //   Log.i('Cloud sync failed (may not be authenticated): $e', label: 'GOAL_DEBUG');
      // }

    } catch (e, stackTrace) {
      Log.e('Failed to create goal: $e', label: 'GOAL_ERROR');
      Log.e('Stack trace: $stackTrace', label: 'GOAL_ERROR');
    }
  }

  /// Detect language from user's last message
  /// Returns 'vi' for Vietnamese, 'en' for English (default)
  String _detectUserLanguage() {
    // Find last user message
    final userMessages = state.messages.where((m) => m.isFromUser).toList();
    if (userMessages.isEmpty) return 'en';

    final lastUserMessage = userMessages.last.content.toLowerCase();

    // Vietnamese character patterns
    final vietnamesePattern = RegExp(r'[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]');

    // Vietnamese common words
    final vietnameseWords = ['tháng', 'năm', 'tuần', 'hôm', 'ngày', 'tiền', 'chi', 'thu', 'ví', 'của', 'trong', 'cho', 'với', 'và', 'là', 'có', 'không', 'được', 'này', 'đó', 'tôi', 'mình', 'bạn', 'xem', 'kiểm', 'tra'];

    // Check for Vietnamese characters
    if (vietnamesePattern.hasMatch(lastUserMessage)) {
      return 'vi';
    }

    // Check for Vietnamese words
    for (final word in vietnameseWords) {
      if (lastUserMessage.contains(word)) {
        return 'vi';
      }
    }

    return 'en';
  }

  Future<String> _getActiveWalletBalanceText() async {
    final lang = _detectUserLanguage();
    final walletState = ref.read(activeWalletProvider);
    final wallet = _unwrapAsyncValue(walletState);
    if (wallet == null) {
      return lang == 'vi' ? 'Chưa chọn ví.' : 'No active wallet selected.';
    }
    final amount = (wallet.balance).toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => m.group(1)! + '.');
    return lang == 'vi'
        ? 'Số dư ví "${wallet.name}": $amount ${wallet.currency}'
        : 'Current balance in "${wallet.name}": $amount ${wallet.currency}';
  }

  Future<String> _getSummaryText(Map<String, dynamic> action) async {
    final lang = _detectUserLanguage();
    try {
      final db = ref.read(databaseProvider);
      WalletModel? wallet = ref.read(activeWalletProvider).value;

      // Fallback to default wallet or first available wallet
      if (wallet == null || wallet.id == null) {
        final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
        if (defaultWallet != null) {
          wallet = defaultWallet;
        } else {
          final walletsAsync = ref.read(allWalletsStreamProvider);
          final allWallets = _unwrapAsyncValue(walletsAsync) ?? [];
          if (allWallets.isNotEmpty) {
            wallet = allWallets.first;
          }
        }
      }

      if (wallet == null || wallet.id == null) {
        return lang == 'vi' ? 'Chưa chọn ví.' : 'No active wallet selected.';
      }

      final now = DateTime.now();
      final String range = (action['range'] ?? 'month').toString();
      DateTime start;
      DateTime end;
      switch (range) {
        case 'today':
          start = DateTime(now.year, now.month, now.day);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          final weekday = now.weekday; // 1=Mon..7=Sun
          start = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
          end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
          break;
        case 'quarter':
          final q = ((now.month - 1) ~/ 3) + 1;
          final startMonth = (q - 1) * 3 + 1;
          start = DateTime(now.year, startMonth, 1);
          end = DateTime(now.year, startMonth + 3, 1).subtract(const Duration(seconds: 1));
          break;
        case 'year':
          start = DateTime(now.year, 1, 1);
          end = DateTime(now.year + 1, 1, 1).subtract(const Duration(seconds: 1));
          break;
        case 'custom':
          start = DateTime.parse(action['startDate']);
          end = DateTime.parse(action['endDate']).add(const Duration(hours: 23, minutes: 59, seconds: 59));
          break;
        case 'month':
        default:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
      }

      final rowsStream = db.transactionDao.watchFilteredTransactionsWithDetails(
        walletId: wallet.id!,
        filter: null,
      );
      final rows = await rowsStream.first;
      final filtered = rows.where((t) => t.date.isAfter(start.subtract(const Duration(milliseconds: 1))) && t.date.isBefore(end.add(const Duration(milliseconds: 1)))).toList();
      final income = filtered.where((t) => t.transactionType == TransactionType.income).fold<double>(0, (s, t) => s + t.amount);
      final expense = filtered.where((t) => t.transactionType == TransactionType.expense).fold<double>(0, (s, t) => s + t.amount);
      final net = income - expense;

      String fmt(num v) => v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

      // Localized range labels
      final rangeLabels = {
        'vi': {'today': 'hôm nay', 'week': 'tuần này', 'month': 'tháng này', 'quarter': 'quý này', 'year': 'năm nay', 'custom': 'tùy chỉnh'},
        'en': {'today': 'today', 'week': 'this week', 'month': 'this month', 'quarter': 'this quarter', 'year': 'this year', 'custom': 'custom'},
      };
      final rangeLabel = rangeLabels[lang]?[range] ?? range;

      if (lang == 'vi') {
        return 'Tổng kết $rangeLabel (${start.toIso8601String().substring(0,10)} → ${end.toIso8601String().substring(0,10)}):\n'
            '• Thu nhập: ${fmt(income)} ${wallet.currency}\n'
            '• Chi tiêu: ${fmt(expense)} ${wallet.currency}\n'
            '• Còn lại: ${fmt(net)} ${wallet.currency}';
      } else {
        return 'Summary $rangeLabel (${start.toIso8601String().substring(0,10)} → ${end.toIso8601String().substring(0,10)}):\n'
            '• Income: ${fmt(income)} ${wallet.currency}\n'
            '• Expense: ${fmt(expense)} ${wallet.currency}\n'
            '• Net: ${fmt(net)} ${wallet.currency}';
      }
    } catch (e) {
      Log.e('Summary error: $e', label: 'Chat Provider');
      return lang == 'vi' ? 'Không thể tạo báo cáo tổng kết.' : 'Could not generate summary.';
    }
  }

  Future<String> _getTransactionsListText(Map<String, dynamic> action) async {
    final lang = _detectUserLanguage();
    try {
      final db = ref.read(databaseProvider);
      WalletModel? wallet = ref.read(activeWalletProvider).value;

      // Fallback to default wallet or first available wallet
      if (wallet == null || wallet.id == null) {
        final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
        if (defaultWallet != null) {
          wallet = defaultWallet;
        } else {
          final walletsAsync = ref.read(allWalletsStreamProvider);
          final allWallets = _unwrapAsyncValue(walletsAsync) ?? [];
          if (allWallets.isNotEmpty) {
            wallet = allWallets.first;
          }
        }
      }

      if (wallet == null || wallet.id == null) {
        return lang == 'vi' ? 'Chưa chọn ví.' : 'No active wallet selected.';
      }

      final now = DateTime.now();
      final String range = (action['range'] ?? 'month').toString();
      DateTime start;
      DateTime end;
      switch (range) {
        case 'today':
          start = DateTime(now.year, now.month, now.day);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          final weekday = now.weekday;
          start = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
          end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
          break;
        case 'custom':
          start = DateTime.parse(action['startDate']);
          end = DateTime.parse(action['endDate']).add(const Duration(hours: 23, minutes: 59, seconds: 59));
          break;
        case 'month':
        default:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
      }

      final rowsStream = db.transactionDao.watchFilteredTransactionsWithDetails(
        walletId: wallet.id!,
        filter: null,
      );
      final rows = await rowsStream.first;
      final filtered = rows.where((t) => t.date.isAfter(start.subtract(const Duration(milliseconds: 1))) && t.date.isBefore(end.add(const Duration(milliseconds: 1)))).toList();
      filtered.sort((a, b) => b.date.compareTo(a.date));
      final int limit = (action['limit'] is num) ? (action['limit'] as num).toInt() : 5;
      final take = filtered.take(limit).toList();
      if (take.isEmpty) {
        return lang == 'vi' ? 'Không có giao dịch nào trong khoảng thời gian này.' : 'No transactions found in this time period.';
      }

      String fmt(num v) => v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
      final lines = take.map((t) =>
          '- ${t.title} • ${(t.transactionType == TransactionType.expense ? '-' : '+')}${fmt(t.amount)} ${t.wallet.currency} • ${t.category.title}');
      final header = lang == 'vi' ? 'Giao dịch gần đây:' : 'Recent transactions:';
      return '$header\n${lines.join('\n')}';
    } catch (e) {
      Log.e('List tx error: $e', label: 'Chat Provider');
      return lang == 'vi' ? 'Không thể lấy danh sách giao dịch.' : 'Unable to retrieve transaction list.';
    }
  }

  /// Sanity check for VND amounts from LLM.
  /// LLMs often multiply "tr" (triệu/million) by 1B instead of 1M,
  /// resulting in amounts 1000x too large.
  /// Re-parse from user message to get the correct amount.
  /// Deduplicate screenshot OCR results against existing transactions in DB.
  /// Match by: amount exact + date ±1 day + description fuzzy match.
  Future<List<ReceiptScanResult>> _deduplicateScreenshotResults(
    List<ReceiptScanResult> results,
  ) async {
    try {
      final db = ref.read(databaseProvider);
      // Get recent transactions (last 7 days) for matching
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final allTxEntities = await db.transactionDao.getAllTransactions();
      final recentTransactions = allTxEntities.where((t) =>
          t.date.isAfter(weekAgo)).toList();

      return results.where((result) {
        for (final tx in recentTransactions) {
          // 1. Amount must match exactly
          if (result.amount != tx.amount) continue;

          // 2. Date within ±1 day
          DateTime resultDate;
          try {
            resultDate = DateTime.parse(result.date);
          } catch (_) {
            continue;
          }
          final dayDiff = resultDate.difference(tx.date).inDays.abs();
          if (dayDiff > 1) continue;

          // 3. Description similarity
          final a = result.merchant.toLowerCase();
          final b = tx.title.toLowerCase();
          if (a.contains(b) || b.contains(a) || _fuzzyMatchStrings(a, b)) {
            Log.d('Dedupe: skipping "${result.merchant}" (matches "${tx.title}")',
                label: 'SCREENSHOT_DEDUPE');
            return false; // Duplicate found
          }
        }
        return true; // Not a duplicate
      }).toList();
    } catch (e) {
      Log.e('Dedupe error: $e', label: 'SCREENSHOT_DEDUPE');
      return results; // On error, keep all
    }
  }

  /// Simple fuzzy match: check if words overlap significantly
  bool _fuzzyMatchStrings(String a, String b) {
    final wordsA = a.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    final wordsB = b.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) return false;
    final overlap = wordsA.intersection(wordsB).length;
    final minLen = wordsA.length < wordsB.length ? wordsA.length : wordsB.length;
    return minLen > 0 && overlap / minLen >= 0.5;
  }

  double _sanitizeVndAmount(double llmAmount, String userMessage, String currency) {
    if (currency != 'VND') return llmAmount;

    // Try to parse amount from user message directly
    final lower = userMessage.toLowerCase();
    final amountPattern = RegExp(r'(\d+[\.,]?\d*)\s*(ty|tỷ|tr|trieu|triệu|k|nghin|nghìn|ngan|ngàn)?');
    final match = amountPattern.firstMatch(lower);
    if (match == null) return llmAmount;

    final numStr = match.group(1)?.replaceAll('.', '').replaceAll(',', '.') ?? '0';
    final unit = match.group(2) ?? '';
    final base = double.tryParse(numStr) ?? 0.0;

    int multiplier = 1;
    switch (unit) {
      case 'k':
      case 'nghin':
      case 'nghìn':
      case 'ngan':
      case 'ngàn':
        multiplier = 1000;
        break;
      case 'tr':
      case 'trieu':
      case 'triệu':
        multiplier = 1000000;
        break;
      case 'ty':
      case 'tỷ':
        multiplier = 1000000000;
        break;
    }

    final parsed = base * multiplier;
    if (parsed > 0 && (llmAmount / parsed).abs() > 100) {
      Log.w('⚠️ VND SANITY CHECK: LLM returned $llmAmount but parsed "$userMessage" as $parsed. Using parsed value.', label: 'AMOUNT_SANITY');
      return parsed;
    }
    return llmAmount;
  }

  String _formatAmount(num value, {String? currency}) {
    if (currency != null && currency.isNotEmpty) {
      // Special formatting for currencies
      if (currency == 'VND' || currency == 'đ') {
        // VND: round to integer, use dot as thousand separator
        final intPart = value.round();
        final text = intPart.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        return '$text đ';
      } else if (currency == 'USD') {
        // USD: show 2 decimal places
        final formatted = value.toStringAsFixed(2);
        return '\$$formatted';
      }
      // Other currencies: show 2 decimal places
      return '${value.toStringAsFixed(2)} $currency';
    }
    // Default: VND format
    final intPart = value.round();
    final text = intPart.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$text đ';
  }

  String _formatDatePhrase(DateTime date) {
    final now = DateTime.now();
    String dayPhrase;
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      dayPhrase = 'today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      dayPhrase = 'yesterday';
    } else {
      dayPhrase = 'on';
    }
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return dayPhrase + ' ' + dd + '/' + mm + '/' + yyyy;
  }

  Future<Map<String, dynamic>?> _inferActionFromText(String text) async {
    try {
      final lower = text.toLowerCase();

      // Skip if user is trying to update/set balance directly
      if (RegExp(r'\b(update|set|change|thay doi|thay đổi|cap nhat|cập nhật)\s*(vi|ví|balance|wallet)').hasMatch(lower)) {
        Log.d('Skipping balance update request in fallback', label: 'AI_FALLBACK');
        return null;
      }

      // Decide income vs expense by keywords (simple heuristic)
      final isIncome = RegExp(r'\b(luong|lương|thu nhap|thu nhập|nhan|nhận|ban|bán|thu)\b').hasMatch(lower);

      // Get wallet currency to handle conversion
      final wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      final walletCurrency = wallet?.currency ?? 'VND';
      Log.d('Wallet currency: $walletCurrency', label: 'AI_CURRENCY');

      // Extract amount patterns: e.g., 500tr, 2.5tr, 300k, 1.2 tỷ, 7000000, $100, 100 USD
      // Check for USD patterns first
      final usdPattern = RegExp(r'\$\s*(\d+[\.,]?\d*)|(\d+[\.,]?\d*)\s*(?:usd|dollar)');
      final usdMatch = usdPattern.firstMatch(lower);

      double amount;

      if (usdMatch != null) {
        // USD amount detected
        final numStr = usdMatch.group(1) ?? usdMatch.group(2) ?? '0';
        amount = double.tryParse(numStr.replaceAll(',', '')) ?? 0.0;
        Log.d('USD amount detected: $amount', label: 'AI_CURRENCY');
      } else {
        // VND amount patterns
        final amountPattern = RegExp(r'(\d+[\.,]?\d*)\s*(ty|tỷ|tr|tri?eu|triệu|k|nghin|nghìn|ngan|ngàn)?');
        final match = amountPattern.firstMatch(lower);
        if (match == null) return null;

        final numPart = match.group(1) ?? '0';
        final unit = match.group(2) ?? '';
        double base = double.tryParse(numPart.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
        int multiplier = 1;

        switch (unit) {
          case 'k':
          case 'nghin':
          case 'nghìn':
          case 'ngan':
          case 'ngàn':
            multiplier = 1000; break;
          case 'tr':
          case 'trieu':
          case 'tri?eu':
          case 'triệu':
            multiplier = 1000000; break;
          case 'ty':
          case 'tỷ':
            multiplier = 1000000000; break;
          default:
            multiplier = 1; break;
        }

        double vndAmount = base * multiplier;
        Log.d('VND amount parsed: $vndAmount', label: 'AI_CURRENCY');

        // Convert VND to wallet currency if needed
        if (walletCurrency == 'USD') {
          // Simple conversion: 1 USD ≈ 25,000 VND
          amount = vndAmount / 25000;
          Log.d('Converted to USD: $amount', label: 'AI_CURRENCY');
        } else {
          amount = vndAmount;
        }
      }

      amount = amount.round().toDouble();

      // Guess description: remove amount token
      String description = text;
      if (usdMatch != null) {
        description = text.replaceFirst(usdMatch.group(0) ?? '', '').trim();
      } else {
        final amountPattern = RegExp(r'(\d+[\.,]?\d*)\s*(ty|tỷ|tr|tri?eu|triệu|k|nghin|nghìn|ngan|ngàn)?');
        final match = amountPattern.firstMatch(lower);
        if (match != null) {
          description = text.replaceFirst(match.group(0) ?? '', '').trim();
        }
      }
      if (description.isEmpty) description = isIncome ? 'Thu nhập' : 'Chi tiêu';

      // Guess category: try to match any known category title substring
      final categoriesAsync = ref.read(hierarchicalCategoriesProvider);
      final categories = categoriesAsync.maybeWhen(data: (cats) => cats, orElse: () => <CategoryModel>[]);
      String categoryTitle = 'Others';
      for (final c in categories) {
        if (lower.contains(c.title.toLowerCase())) { categoryTitle = c.title; break; }
      }

      return {
        'action': isIncome ? 'create_income' : 'create_expense',
        'amount': amount,
        'description': description,
        'category': categoryTitle,
      };
    } catch (_) {
      return null;
    }
  }

  Future<String> _updateTransactionFromAction(Map<String, dynamic> action) async {
    try {
      final transactionId = (action['transactionId'] as num).toInt();
      Log.d('Updating transaction ID: $transactionId', label: 'UPDATE_TRANSACTION');

      // Get transaction from database
      final db = ref.read(databaseProvider);
      final transactions = await db.transactionDao.watchFilteredTransactionsWithDetails(
        walletId: _unwrapAsyncValue(ref.read(activeWalletProvider))?.id ?? 0,
        filter: null,
      ).first;

      final transaction = transactions.firstWhereOrNull((t) => t.id == transactionId);
      if (transaction == null) {
        return '❌ Transaction not found (ID: $transactionId).';
      }

      // Store old values for wallet balance adjustment
      final oldAmount = transaction.amount;
      final oldType = transaction.transactionType;

      // Update fields if provided
      double? newAmount = action['amount'] != null ? (action['amount'] as num).toDouble() : null;
      String? newDescription = action['description'];
      String? newCategoryName = action['category'];
      DateTime? newDate = action['date'] != null ? DateTime.parse(action['date']) : null;

      // Handle currency conversion
      if (newAmount != null && action['currency'] != null) {
        final wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
        final walletCurrency = wallet?.currency ?? 'VND';
        final aiCurrency = action['currency'];

        if (aiCurrency == 'VND' && walletCurrency == 'USD') {
          newAmount = newAmount / 25000;
        }
      }

      // Get category if changed
      CategoryModel? newCategory;
      if (newCategoryName != null) {
        final categories = _unwrapAsyncValue(ref.read(hierarchicalCategoriesProvider)) ?? [];
        newCategory = categories.firstWhereOrNull(
          (c) => c.title.toLowerCase() == newCategoryName.toLowerCase(),
        );
        newCategory ??= categories.firstWhereOrNull(
          (c) => c.title.toLowerCase().contains(newCategoryName.toLowerCase()) ||
                 newCategoryName.toLowerCase().contains(c.title.toLowerCase()),
        );
        newCategory ??= transaction.category; // Keep old category if not found
      }

      // Create updated transaction
      final updatedTransaction = transaction.copyWith(
        amount: newAmount ?? transaction.amount,
        title: newDescription ?? transaction.title,
        category: newCategory ?? transaction.category,
        date: newDate ?? transaction.date,
      );

      // Update in database
      final transactionDao = ref.read(transactionDaoProvider);
      await transactionDao.updateTransaction(updatedTransaction);

      // Adjust wallet balance (reverse old, apply new)
      final wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      if (wallet != null) {
        double balanceAdjustment = 0;

        // Reverse old transaction
        if (oldType == TransactionType.income) {
          balanceAdjustment -= oldAmount;
        } else {
          balanceAdjustment += oldAmount;
        }

        // Apply new transaction
        if (updatedTransaction.transactionType == TransactionType.income) {
          balanceAdjustment += updatedTransaction.amount;
        } else {
          balanceAdjustment -= updatedTransaction.amount;
        }

        final updatedWallet = wallet.copyWith(balance: wallet.balance + balanceAdjustment);
        final walletDao = ref.read(walletDaoProvider);
        await walletDao.updateWallet(updatedWallet);
        ref.read(activeWalletProvider.notifier).setActiveWallet(updatedWallet);
      }

      // Invalidate providers to refresh UI
      ref.invalidate(transactionListProvider);

      final amountText = _formatAmount(updatedTransaction.amount, currency: wallet?.currency ?? 'VND');
      return '✅ Updated transaction: ${updatedTransaction.title} → $amountText (${updatedTransaction.category.title})';
    } catch (e, stackTrace) {
      Log.e('Failed to update transaction: $e', label: 'UPDATE_TRANSACTION');
      Log.e('Stack trace: $stackTrace', label: 'UPDATE_TRANSACTION');
      return '❌ Failed to update transaction: $e';
    }
  }

  Future<String> _createWalletFromAction(Map<String, dynamic> action) async {
    try {
      final name = (action['name'] as String?) ?? 'New Wallet';
      final currency = (action['currency'] as String?) ?? 'VND';
      final initialBalance = (action['initialBalance'] as num?)?.toDouble() ?? 0.0;
      final iconName = (action['iconName'] as String?) ?? 'wallet';
      final colorHex = (action['colorHex'] as String?) ?? '#4CAF50';

      Log.d('Creating wallet: $name, currency: $currency, balance: $initialBalance', label: 'CREATE_WALLET');

      // Create wallet model
      final wallet = WalletModel(
        name: name,
        currency: currency,
        balance: initialBalance,
        iconName: iconName,
        colorHex: colorHex,
      );

      // Save to database
      final walletDao = ref.read(walletDaoProvider);
      final walletId = await walletDao.addWallet(wallet);

      final createdWallet = wallet.copyWith(id: walletId);
      final amountText = _formatAmount(initialBalance, currency: currency);

      return '✅ Created wallet "$name" with initial balance of $amountText';
    } catch (e, stackTrace) {
      Log.e('Failed to create wallet: $e', label: 'CREATE_WALLET');
      Log.e('Stack trace: $stackTrace', label: 'CREATE_WALLET');
      return '❌ Failed to create wallet: $e';
    }
  }

  /// Returns the converted amount in wallet currency
  Future<double> _createRecurringFromAction(Map<String, dynamic> action, {String userMessage = ''}) async {
    try {
      Log.d('🔵 _createRecurringFromAction() START', label: 'CREATE_RECURRING');

      final name = (action['name'] as String?) ?? 'New Recurring';
      final aiCurrency = (action['currency'] as String?) ?? 'VND';
      // Sanity check: LLM often returns wrong VND amounts (e.g., 100tr → 100B instead of 100M)
      final rawAmount = (action['amount'] as num?)?.toDouble() ?? 0.0;
      final amount = _sanitizeVndAmount(rawAmount, userMessage, aiCurrency);
      final categoryName = (action['category'] as String?) ?? 'Others';
      final frequencyString = (action['frequency'] as String?) ?? 'monthly';
      final nextDueDateString = action['nextDueDate'] as String?;
      final enableReminder = (action['enableReminder'] as bool?) ?? true;
      final autoCreate = (action['autoCreate'] as bool?) ?? true; // Default to true (charge immediately)
      final notes = action['notes'] as String?;

      Log.d('Creating recurring: $name, amount: $amount, aiCurrency: $aiCurrency, frequency: $frequencyString', label: 'CREATE_RECURRING');
      Log.d('AI Action received: ${action.toString()}', label: 'CREATE_RECURRING');

      // Find wallet - Priority: AI specified wallet name > currency match > active wallet > default
      final walletsAsync = ref.read(allWalletsStreamProvider);
      final allWallets = _unwrapAsyncValue(walletsAsync) ?? [];
      WalletModel? wallet;

      // Priority 1: If AI specified a wallet name, try EXACT match only
      // Partial matches are unreliable and can cause wrong wallet selection
      final aiWalletName = action['wallet'] as String?;
      if (aiWalletName != null && aiWalletName.isNotEmpty) {
        final aiWalletLower = aiWalletName.toLowerCase();

        // Try exact match ONLY - partial matches are too risky
        wallet = allWallets.firstWhereOrNull((w) =>
          w.name.toLowerCase() == aiWalletLower);

        if (wallet != null) {
          Log.d('Using AI-specified wallet (exact match): "${wallet.name}" (${wallet.currency})', label: 'CREATE_RECURRING');
        } else {
          // Check if wallet name contains currency hint (e.g., "My USD Wallet", "ví USD")
          final walletNameUpper = aiWalletName.toUpperCase();
          String? hintedCurrency;
          if (walletNameUpper.contains('USD') || walletNameUpper.contains('DOLLAR') || walletNameUpper.contains('ĐÔ')) {
            hintedCurrency = 'USD';
          } else if (walletNameUpper.contains('VND') || walletNameUpper.contains('ĐỒNG')) {
            hintedCurrency = 'VND';
          }

          if (hintedCurrency != null) {
            wallet = allWallets.firstWhereOrNull((w) => w.currency == hintedCurrency);
            if (wallet != null) {
              Log.d('Using currency-hinted wallet from name "$aiWalletName": "${wallet.name}" (${wallet.currency})', label: 'CREATE_RECURRING');
            }
          }

          if (wallet == null) {
            Log.w('AI specified wallet "$aiWalletName" not found (no exact match), falling back to currency matching', label: 'CREATE_RECURRING');
          }
        }
      }

      // Priority 2: Match wallet by currency from AI action
      if (wallet == null) {
        wallet = allWallets.firstWhereOrNull((w) => w.currency == aiCurrency);
        if (wallet != null) {
          Log.d('Using currency-matched wallet: "${wallet.name}" (${wallet.currency})', label: 'CREATE_RECURRING');
        }
      }

      // Priority 3: Use active wallet
      if (wallet == null) {
        wallet = ref.read(activeWalletProvider).value;
        if (wallet != null) {
          Log.d('Using active wallet: "${wallet.name}" (${wallet.currency})', label: 'CREATE_RECURRING');
        }
      }

      // Priority 4: Use default wallet, then first available wallet
      if (wallet == null) {
        final defaultWallet = _unwrapAsyncValue(ref.read(defaultWalletProvider));
        if (defaultWallet != null) {
          wallet = defaultWallet;
          Log.d('Using default wallet: ${wallet.name}', label: 'CREATE_RECURRING');
        } else if (allWallets.isNotEmpty) {
          wallet = allWallets.first;
          Log.d('Using first available wallet: ${wallet.name}', label: 'CREATE_RECURRING');
        }
      }

      if (wallet == null) {
        throw Exception('No wallet found. Please create a wallet first.');
      }

      // Find category with fallback logic
      // CRITICAL: Query directly from database to avoid StreamProvider timing issues
      final categoryDao = ref.read(databaseProvider).categoryDao;
      final categoryEntities = await categoryDao.watchAllCategories().first;

      if (categoryEntities.isEmpty) {
        throw Exception('No categories available.');
      }

      // Convert to CategoryModel and flatten for matching
      // IMPORTANT: Add subcategories FIRST for higher matching priority
      final List<CategoryModel> allCategories = [];
      final Map<int?, List<CategoryModel>> childrenByParentIdMap = {};

      // Convert all entities to models
      final allModels = categoryEntities.map((e) => e.toModel()).toList();

      // Group by parentId
      for (final model in allModels) {
        childrenByParentIdMap.putIfAbsent(model.parentId, () => []).add(model);
      }

      // Get top-level categories (parentId == null)
      final topLevelCategories = childrenByParentIdMap[null] ?? [];

      // Flatten: Add subcategories first, then parent
      for (final parent in topLevelCategories) {
        final children = childrenByParentIdMap[parent.id] ?? [];
        allCategories.addAll(children); // Subcategories first (higher priority)
        allCategories.add(parent); // Then parent as fallback
      }

      Log.d('Flattened categories for matching: ${allCategories.map((c) => c.title).join(", ")}', label: 'CREATE_RECURRING');
      Log.d('Looking for category: "$categoryName" (AI returned in English)', label: 'CREATE_RECURRING');

      // Step 1: Try exact match (case insensitive) first
      CategoryModel? category = allCategories.firstWhereOrNull(
        (c) => c.title.toLowerCase() == categoryName.toLowerCase(),
      );

      // Step 2: If no exact match, try translation mapping
      // AI returns English names, but DB may have localized names
      if (category == null) {
        Log.d('No exact match, trying translation mapping...', label: 'CREATE_RECURRING');
        final availableTitles = allCategories.map((c) => c.title).toList();
        final matchedTitle = CategoryTranslationMap.findMatchingCategory(
          categoryName,
          availableTitles,
        );

        if (matchedTitle != null) {
          category = allCategories.firstWhereOrNull((c) => c.title == matchedTitle);
          Log.d('✅ Category matched via translation: "$categoryName" → "${category?.title}"', label: 'CREATE_RECURRING');
        }
      } else {
        Log.d('✅ Category matched exactly: "${category.title}"', label: 'CREATE_RECURRING');
      }

      // Step 3: If still no match, try fallback to "General" or "Other"
      if (category == null) {
        Log.d('No translation match, trying fallback to General/Other...', label: 'CREATE_RECURRING');
        category = allCategories.firstWhereOrNull((c) =>
          c.title.toLowerCase().contains('general') ||
          c.title.toLowerCase().contains('other') ||
          c.title.toLowerCase().contains('khác') ||
          c.title.toLowerCase().contains('其他') ||
          c.title.toLowerCase().contains('chung')
        );

        if (category != null) {
          Log.d('✅ Using fallback category: "${category.title}"', label: 'CREATE_RECURRING');
        }
      }

      // Step 4: If everything fails, throw error
      if (category == null) {
        final availableCategories = allCategories.map((c) => c.title).join(', ');
        Log.e('❌ Invalid category "$categoryName" from LLM. Available: $availableCategories', label: 'CREATE_RECURRING');
        throw Exception('Category "$categoryName" not found. Please choose from available categories or create it first.');
      }

      // Parse frequency
      RecurringFrequency frequency;
      switch (frequencyString.toLowerCase()) {
        case 'daily':
          frequency = RecurringFrequency.daily;
          break;
        case 'weekly':
          frequency = RecurringFrequency.weekly;
          break;
        case 'yearly':
          frequency = RecurringFrequency.yearly;
          break;
        case 'monthly':
        default:
          frequency = RecurringFrequency.monthly;
      }

      // Parse First Billing Date (nextDueDate)
      DateTime nextDueDate = DateTime.now();
      if (nextDueDateString != null) {
        try {
          nextDueDate = DateTime.parse(nextDueDateString);
        } catch (e) {
          Log.w('Failed to parse next due date, using current date', label: 'CREATE_RECURRING');
        }
      }

      // startDate kept for backward compatibility, set to same as nextDueDate
      final startDate = nextDueDate;

      // Convert amount if currencies don't match
      // IMPORTANT: Recurring should always be stored in wallet currency!
      double recurringAmount = amount;

      if (aiCurrency != wallet.currency) {
        try {
          final exchangeService = ref.read(exchangeRateServiceProvider);
          recurringAmount = await exchangeService.convertAmount(
            amount: amount,
            fromCurrency: aiCurrency,
            toCurrency: wallet.currency,
          );
          Log.d('Converted $amount $aiCurrency to $recurringAmount ${wallet.currency}', label: 'CREATE_RECURRING');
        } catch (e) {
          Log.e('Failed to convert currency: $e', label: 'CREATE_RECURRING');
          throw Exception('Failed to convert currency from $aiCurrency to ${wallet.currency}. Please check your internet connection or try again.');
        }
      }

      // Check if we should charge immediately
      final today = DateTime.now();
      final isDueToday = nextDueDate.year == today.year &&
                         nextDueDate.month == today.month &&
                         nextDueDate.day == today.day;
      final isPastDue = nextDueDate.isBefore(today);
      final shouldChargeNow = autoCreate && (isDueToday || isPastDue);

      // CRITICAL FIX: If shouldChargeNow, advance nextDueDate BEFORE saving recurring
      // This prevents RecurringChargeService from auto-charging the same payment again
      DateTime recurringNextDueDate = nextDueDate;
      if (shouldChargeNow) {
        switch (frequency) {
          case RecurringFrequency.daily:
            recurringNextDueDate = nextDueDate.add(const Duration(days: 1));
            break;
          case RecurringFrequency.weekly:
            recurringNextDueDate = nextDueDate.add(const Duration(days: 7));
            break;
          case RecurringFrequency.monthly:
            recurringNextDueDate = DateTime(
              nextDueDate.year,
              nextDueDate.month + 1,
              nextDueDate.day,
            );
            break;
          case RecurringFrequency.quarterly:
            recurringNextDueDate = DateTime(
              nextDueDate.year,
              nextDueDate.month + 3,
              nextDueDate.day,
            );
            break;
          case RecurringFrequency.yearly:
            recurringNextDueDate = DateTime(
              nextDueDate.year + 1,
              nextDueDate.month,
              nextDueDate.day,
            );
            break;
          case RecurringFrequency.custom:
            // Keep same nextDueDate for custom frequency
            break;
        }
        Log.d('shouldChargeNow = true, advancing nextDueDate: $nextDueDate → $recurringNextDueDate', label: 'CREATE_RECURRING');
      }

      // Create recurring model with converted amount and wallet currency
      final recurring = RecurringModel(
        name: name,
        amount: recurringAmount,
        wallet: wallet,
        category: category,
        currency: wallet.currency,  // Use wallet currency, not AI currency!
        frequency: frequency,
        startDate: startDate,
        nextDueDate: recurringNextDueDate,  // Use advanced date if shouldChargeNow
        status: RecurringStatus.active,
        enableReminder: enableReminder,
        reminderDaysBefore: 1,
        autoCreate: autoCreate,
        notes: notes,
        lastChargedDate: shouldChargeNow ? DateTime.now() : null,  // Mark as charged if shouldChargeNow
        totalPayments: shouldChargeNow ? 1 : 0,  // Set totalPayments if shouldChargeNow
      );

      // Save to database
      final db = ref.read(databaseProvider);
      final recurringId = await db.recurringDao.addRecurring(recurring);

      // Upload to cloud immediately after creation
      try {
        final recurringWithId = recurring.copyWith(id: recurringId);
        final syncService = ref.read(supabaseSyncServiceProvider);
        await syncService.uploadRecurring(recurringWithId);
        Log.d('Recurring uploaded to cloud: ${recurringWithId.cloudId}', label: 'CREATE_RECURRING');
      } catch (e) {
        Log.w('Failed to upload recurring to cloud: $e', label: 'CREATE_RECURRING');
        // Don't fail the entire operation if cloud sync fails
      }

      if (shouldChargeNow) {
        Log.d('shouldChargeNow = true, will create initial transaction', label: 'CREATE_RECURRING');
        Log.d('Transaction details: amount=$recurringAmount, currency=${wallet.currency}, date=${nextDueDate.toIso8601String()}', label: 'CREATE_RECURRING');

        // Determine transaction type from category or action hint
        final isIncome = (action['isIncome'] == true) ||
            category.transactionType == 'income';
        final txnType = isIncome ? TransactionType.income : TransactionType.expense;

        // Build descriptive title based on frequency and type
        String transactionTitle = name;
        final prefix = isIncome ? 'Monthly Income' : 'Subscription';
        switch (frequency) {
          case RecurringFrequency.daily:
            transactionTitle = 'Daily: $name';
            break;
          case RecurringFrequency.weekly:
            transactionTitle = 'Weekly: $name';
            break;
          case RecurringFrequency.monthly:
            transactionTitle = '$prefix: $name';
            break;
          case RecurringFrequency.yearly:
            transactionTitle = 'Yearly: $name';
            break;
          default:
            transactionTitle = name;
        }

        // Build notes with conversion info if currency mismatch
        String transactionNotes = notes ?? 'Auto-charged from recurring payment';
        if (aiCurrency != wallet.currency) {
          // Add conversion info to notes
          transactionNotes = '$transactionNotes\nConverted: $amount $aiCurrency → ${recurringAmount.toStringAsFixed(2)} ${wallet.currency}';
        }

        // Use the converted amount (same as recurring)
        // IMPORTANT: Use nextDueDate as transaction date (not current date)
        // This ensures transaction appears on correct date even if created later
        final transaction = TransactionModel(
          transactionType: txnType,
          amount: recurringAmount,
          date: nextDueDate, // Use due date, not DateTime.now()!
          title: transactionTitle,
          category: category,
          wallet: wallet,
          notes: transactionNotes,
        );
        final transactionDao = ref.read(transactionDaoProvider);
        final transactionId = await transactionDao.addTransaction(transaction);
        Log.d('Created initial transaction (ID: $transactionId) for recurring payment on date: ${nextDueDate.toIso8601String()}', label: 'CREATE_RECURRING');
      }

      // Recurring created successfully - AI will provide the confirmation message
      Log.d('✅ _createRecurringFromAction() END - Recurring created successfully: $name', label: 'CREATE_RECURRING');

      // Return the converted amount in wallet currency
      return recurringAmount;
    } catch (e, stackTrace) {
      Log.e('❌ _createRecurringFromAction() FAILED: $e', label: 'CREATE_RECURRING');
      Log.e('Stack trace: $stackTrace', label: 'CREATE_RECURRING');
      rethrow;
    }
  }

  Future<String> _deleteTransactionFromAction(Map<String, dynamic> action) async {
    try {
      final transactionId = (action['transactionId'] as num).toInt();
      Log.d('Deleting transaction ID: $transactionId', label: 'DELETE_TRANSACTION');

      // Get transaction from database
      final db = ref.read(databaseProvider);
      final transactions = await db.transactionDao.watchFilteredTransactionsWithDetails(
        walletId: _unwrapAsyncValue(ref.read(activeWalletProvider))?.id ?? 0,
        filter: null,
      ).first;

      final transaction = transactions.firstWhereOrNull((t) => t.id == transactionId);
      if (transaction == null) {
        return '❌ Transaction not found (ID: $transactionId).';
      }

      // Store info for confirmation message
      final amount = transaction.amount;
      final description = transaction.title;
      final type = transaction.transactionType;

      // Delete from database
      final transactionDao = ref.read(transactionDaoProvider);
      await transactionDao.deleteTransaction(transactionId);

      // Adjust wallet balance (reverse the transaction)
      final wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      if (wallet != null) {
        double balanceAdjustment = 0;

        if (type == TransactionType.income) {
          balanceAdjustment -= amount; // Remove income
        } else {
          balanceAdjustment += amount; // Remove expense (add back)
        }

        final updatedWallet = wallet.copyWith(balance: wallet.balance + balanceAdjustment);
        final walletDao = ref.read(walletDaoProvider);
        await walletDao.updateWallet(updatedWallet);
        ref.read(activeWalletProvider.notifier).setActiveWallet(updatedWallet);
      }

      // Invalidate providers to refresh UI
      ref.invalidate(transactionListProvider);

      final amountText = _formatAmount(amount, currency: wallet?.currency ?? 'VND');
      return '✅ Deleted transaction: $description ($amountText)';
    } catch (e, stackTrace) {
      Log.e('Failed to delete transaction: $e', label: 'DELETE_TRANSACTION');
      Log.e('Stack trace: $stackTrace', label: 'DELETE_TRANSACTION');
      return '❌ Failed to delete transaction: $e';
    }
  }

  /// Update AI service with recent transactions context
  /// Aggregates across ALL user wallets so the coach has the full picture
  /// (matches dashboard behavior which also shows cross-wallet totals).
  Future<void> _updateRecentTransactionsContext() async {
    try {
      print('[AI_CONTEXT] _updateRecentTransactionsContext START');
      final db = ref.read(databaseProvider);
      final transactions = await db.transactionDao
          .watchAllTransactionsWithDetails()
          .first
          .timeout(const Duration(seconds: 5), onTimeout: () {
        print('[AI_CONTEXT] Transaction fetch TIMEOUT');
        return [];
      });
      print('[AI_CONTEXT] Got ${transactions.length} transactions across all wallets');

      // Take only the 10 most recent
      final recentTransactions = transactions.take(10).toList();

      if (recentTransactions.isEmpty) {
        Log.d('No recent transactions to provide to AI', label: 'Chat Provider');
        _aiService.updateRecentTransactions('');
        return;
      }

      // Format transactions as context string (include wallet name so AI knows source)
      final context = StringBuffer();
      for (final tx in recentTransactions) {
        final amountText = _formatAmount(tx.amount, currency: tx.wallet.currency);
        final typeIcon = tx.transactionType == TransactionType.income ? '📈' : '📉';
        context.writeln('#${tx.id} - $typeIcon $amountText - ${tx.title} (${tx.category.title}) [${tx.wallet.name}]');
      }

      final contextString = context.toString().trim();
      Log.d('Updating AI with recent transactions:\n$contextString', label: 'Chat Provider');
      _aiService.updateRecentTransactions(contextString);
    } catch (e, stackTrace) {
      Log.e('Failed to update recent transactions context: $e', label: 'Chat Provider');
      Log.e('Stack trace: $stackTrace', label: 'Chat Provider');
    }
  }

  /// Get list of budgets for AI context
  Future<String> _getBudgetsListText(Map<String, dynamic> action) async {
    try {
      // Use DAO directly instead of provider to avoid autoDispose issues
      final budgetDao = ref.read(budgetDaoProvider);
      final budgets = await budgetDao.watchAllBudgets().first;
      final wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      final currency = wallet?.currency ?? 'VND';

      if (budgets.isEmpty) {
        return '📋 Không có budget nào.';
      }

      final period = action['period'] ?? 'current';
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0);

      List<BudgetModel> filteredBudgets;
      if (period == 'current') {
        filteredBudgets = budgets.where((b) {
          return (b.startDate.isBefore(currentMonthEnd) || b.startDate.isAtSameMomentAs(currentMonthEnd)) &&
              (b.endDate.isAfter(currentMonthStart) || b.endDate.isAtSameMomentAs(currentMonthStart));
        }).toList();
      } else {
        filteredBudgets = budgets;
      }

      if (filteredBudgets.isEmpty) {
        return '📋 Không có budget nào trong tháng này.';
      }

      final buffer = StringBuffer('📋 Danh sách budget:\n');
      for (final budget in filteredBudgets) {
        final amountText = _formatAmount(budget.amount, currency: currency);
        buffer.writeln('• #${budget.id} - ${budget.category?.title ?? 'Unknown'}: $amountText');
      }

      return buffer.toString().trim();
    } catch (e) {
      Log.e('Failed to get budgets list: $e', label: 'BUDGET_LIST');
      return '❌ Lỗi khi lấy danh sách budget.';
    }
  }

  /// Get list of goals for AI
  Future<String> _getGoalsListText() async {
    final lang = _detectUserLanguage();
    try {
      final db = ref.read(databaseProvider);
      final goals = await db.goalDao.getAllGoals();
      final wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      final currency = wallet?.currency ?? 'VND';

      if (goals.isEmpty) {
        return lang == 'vi' ? '🎯 Không có mục tiêu nào.' : '🎯 No goals found.';
      }

      String fmt(num v) => v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

      final header = lang == 'vi' ? '🎯 Danh sách mục tiêu:' : '🎯 Goals list:';
      final buffer = StringBuffer('$header\n');
      for (final goal in goals) {
        final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount * 100).toInt() : 0;
        final currentText = fmt(goal.currentAmount);
        final targetText = fmt(goal.targetAmount);
        final deadlineText = ' (${goal.endDate.toIso8601String().substring(0, 10)})';
        buffer.writeln('• ${goal.title}: $currentText / $targetText $currency ($progress%)$deadlineText');
      }

      return buffer.toString().trim();
    } catch (e) {
      Log.e('Failed to get goals list: $e', label: 'GOALS_LIST');
      return lang == 'vi' ? '❌ Lỗi khi lấy danh sách mục tiêu.' : '❌ Failed to get goals list.';
    }
  }

  /// Get list of recurring payments for AI
  Future<String> _getRecurringListText(Map<String, dynamic> action) async {
    final lang = _detectUserLanguage();
    try {
      final db = ref.read(databaseProvider);
      final allRecurring = await db.recurringDao.watchAllRecurrings().first;
      final wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      final currency = wallet?.currency ?? 'VND';

      final status = action['status'] ?? 'active';
      final recurring = status == 'active'
          ? allRecurring.where((r) => r.isActive).toList()
          : allRecurring;

      if (recurring.isEmpty) {
        return lang == 'vi'
            ? '🔄 Không có thanh toán định kỳ nào${status == 'active' ? ' đang hoạt động' : ''}.'
            : '🔄 No ${status == 'active' ? 'active ' : ''}recurring payments found.';
      }

      String fmt(num v) => v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

      final frequencyLabels = {
        'vi': {'daily': 'hàng ngày', 'weekly': 'hàng tuần', 'monthly': 'hàng tháng', 'yearly': 'hàng năm'},
        'en': {'daily': 'daily', 'weekly': 'weekly', 'monthly': 'monthly', 'yearly': 'yearly'},
      };

      final header = lang == 'vi' ? '🔄 Danh sách thanh toán định kỳ:' : '🔄 Recurring payments:';
      final buffer = StringBuffer('$header\n');
      for (final r in recurring) {
        final amountText = fmt(r.amount);
        final freqText = frequencyLabels[lang]?[r.frequency.name] ?? r.frequency.name;
        final nextDue = r.nextDueDate.toIso8601String().substring(0, 10);
        final statusText = r.isActive
            ? ''
            : (lang == 'vi' ? ' [Tạm dừng]' : ' [Paused]');
        buffer.writeln('• ${r.name}: $amountText $currency ($freqText) - ${lang == 'vi' ? 'Kỳ tiếp' : 'Next'}: $nextDue$statusText');
      }

      return buffer.toString().trim();
    } catch (e) {
      Log.e('Failed to get recurring list: $e', label: 'RECURRING_LIST');
      return lang == 'vi' ? '❌ Lỗi khi lấy danh sách thanh toán định kỳ.' : '❌ Failed to get recurring payments list.';
    }
  }

  /// Delete a single budget
  Future<String> _deleteBudgetFromAction(Map<String, dynamic> action) async {
    try {
      final budgetId = (action['budgetId'] as num).toInt();
      Log.d('Deleting budget ID: $budgetId', label: 'DELETE_BUDGET');

      final budgetDao = ref.read(budgetDaoProvider);
      await budgetDao.deleteBudget(budgetId);

      // Invalidate providers to refresh UI
      ref.invalidate(budgetListProvider);

      return '✅ Đã xoá budget thành công.';
    } catch (e, stackTrace) {
      Log.e('Failed to delete budget: $e', label: 'DELETE_BUDGET');
      Log.e('Stack trace: $stackTrace', label: 'DELETE_BUDGET');
      return '❌ Lỗi khi xoá budget: $e';
    }
  }

  /// Delete all budgets
  Future<String> _deleteAllBudgetsFromAction(Map<String, dynamic> action) async {
    try {
      print('🗑️ [DELETE_ALL] Starting delete all budgets...');
      final period = action['period'] ?? 'all'; // Default to 'all' to delete everything
      // Use DAO directly instead of provider to avoid autoDispose issues
      final budgetDao = ref.read(budgetDaoProvider);
      final budgets = await budgetDao.watchAllBudgets().first;

      print('🗑️ [DELETE_ALL] period=$period, total budgets=${budgets.length}');
      Log.d('Delete all budgets: period=$period, total budgets=${budgets.length}', label: 'DELETE_ALL_BUDGETS');

      if (budgets.isEmpty) {
        return '📋 Không có budget nào để xoá.';
      }

      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0);

      int deletedCount = 0;
      for (final budget in budgets) {
        bool shouldDelete = false;
        if (period == 'all') {
          shouldDelete = true;
        } else {
          // current month only
          shouldDelete = (budget.startDate.isBefore(currentMonthEnd) || budget.startDate.isAtSameMomentAs(currentMonthEnd)) &&
              (budget.endDate.isAfter(currentMonthStart) || budget.endDate.isAtSameMomentAs(currentMonthStart));
        }

        Log.d('Budget ${budget.id}: shouldDelete=$shouldDelete, startDate=${budget.startDate}, endDate=${budget.endDate}', label: 'DELETE_ALL_BUDGETS');

        if (shouldDelete && budget.id != null) {
          print('🗑️ [DELETE_ALL] Deleting budget id=${budget.id}');
          await budgetDao.deleteBudget(budget.id!);
          deletedCount++;
          print('🗑️ [DELETE_ALL] Deleted budget id=${budget.id}, total deleted=$deletedCount');
        }
      }

      // Invalidate providers to refresh UI
      ref.invalidate(budgetListProvider);

      return '✅ Đã xoá $deletedCount budget thành công.';
    } catch (e, stackTrace) {
      Log.e('Failed to delete all budgets: $e', label: 'DELETE_ALL_BUDGETS');
      Log.e('Stack trace: $stackTrace', label: 'DELETE_ALL_BUDGETS');
      return '❌ Lỗi khi xoá budgets: $e';
    }
  }

  /// Update a budget
  Future<String> _updateBudgetFromAction(Map<String, dynamic> action) async {
    try {
      final budgetId = (action['budgetId'] as num).toInt();
      Log.d('Updating budget ID: $budgetId', label: 'UPDATE_BUDGET');

      // Use DAO directly instead of provider to avoid autoDispose issues
      final budgetDao = ref.read(budgetDaoProvider);
      final budget = await budgetDao.getBudgetById(budgetId);

      if (budget == null) {
        return '❌ Không tìm thấy budget #$budgetId.';
      }

      // Update fields if provided
      double newAmount = budget.amount;
      if (action['amount'] != null) {
        newAmount = (action['amount'] as num).toDouble();
      }

      final updatedBudget = budget.copyWith(
        amount: newAmount,
        updatedAt: DateTime.now(),
      );

      await budgetDao.updateBudget(updatedBudget);

      // Invalidate providers to refresh UI
      ref.invalidate(budgetListProvider);

      final amountText = _formatAmount(newAmount, currency: _unwrapAsyncValue(ref.read(activeWalletProvider))?.currency ?? 'VND');
      return '✅ Đã cập nhật budget thành $amountText.';
    } catch (e, stackTrace) {
      Log.e('Failed to update budget: $e', label: 'UPDATE_BUDGET');
      Log.e('Stack trace: $stackTrace', label: 'UPDATE_BUDGET');
      return '❌ Lỗi khi cập nhật budget: $e';
    }
  }

  /// Handle pending action confirmation
  Future<void> handlePendingAction(String messageId, String actionType) async {
    try {
      // Find message with pending action
      final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
      if (messageIndex == -1) return;

      final message = state.messages[messageIndex];
      if (message.pendingAction == null) return;

      String resultMessage = '';

      if (actionType == 'screenshot_bulk_create') {
        resultMessage = await _handleScreenshotBulkCreate();
      } else if (actionType == 'screenshot_to_pending') {
        resultMessage = await _handleScreenshotToPending();
      } else if (actionType == 'confirm') {
        // Execute the action
        switch (message.pendingAction!.actionType) {
          case 'delete_budget':
            resultMessage = await _deleteBudgetFromAction(message.pendingAction!.actionData);
            break;
          case 'delete_all_budgets':
            resultMessage = await _deleteAllBudgetsFromAction(message.pendingAction!.actionData);
            break;
          case 'update_budget':
            resultMessage = await _updateBudgetFromAction(message.pendingAction!.actionData);
            break;
          case 'open_savings_account':
            resultMessage = _mockOpenSavingsAccount(message.pendingAction!.actionData);
            break;
          case 'transfer_to_savings':
            resultMessage = _mockTransferToSavings(message.pendingAction!.actionData);
            break;
          case 'apply_credit_card':
            resultMessage = _mockApplyCreditCard(message.pendingAction!.actionData);
            break;
          case 'apply_loan':
            resultMessage = _mockApplyLoan(message.pendingAction!.actionData);
            break;
        }
      } else if (actionType == 'cancel') {
        resultMessage = '❌ Đã huỷ thao tác.';
      } else {
        resultMessage = '❌ Đã huỷ thao tác.';
      }

      // Mark action as handled and add result to message
      final updatedMessage = message.copyWith(
        content: '${message.content}\n\n$resultMessage',
        isActionHandled: true,
        pendingAction: null, // Clear pending action after handling
      );

      final updatedMessages = [...state.messages];
      updatedMessages[messageIndex] = updatedMessage;

      state = state.copyWith(messages: updatedMessages);

      // Save updated message to database
      await _updateMessageInDatabase(updatedMessage);
      Log.d('Updated message saved to database: ${updatedMessage.id}', label: 'Chat Provider');
    } catch (e) {
      Log.e('Failed to handle pending action: $e', label: 'Chat Provider');
    }
  }

  /// Bulk create all pending screenshot transactions
  Future<String> _handleScreenshotBulkCreate() async {
    final transactions = _pendingScreenshotTransactions;
    if (transactions == null || transactions.isEmpty) {
      return '❌ Không có giao dịch nào để thêm.';
    }

    try {
      var wallet = ref.read(activeWalletProvider).value;
      if (wallet == null) {
        final defaultWalletAsync = ref.read(defaultWalletProvider);
        wallet = defaultWalletAsync.value;
      }
      if (wallet == null) {
        final walletsAsync = ref.read(allWalletsStreamProvider);
        final allWallets = _unwrapAsyncValue(walletsAsync) ?? [];
        wallet = allWallets.isNotEmpty ? allWallets.first : null;
      }
      if (wallet == null) return '❌ Không tìm thấy ví.';

      int created = 0;
      for (final result in transactions) {
        try {
          final action = _receiptToActionMap(result);
          await _createTransactionFromAction(action, wallet: wallet);
          created++;
        } catch (e) {
          Log.e('Failed to create transaction: ${result.merchant}: $e',
              label: 'SCREENSHOT_BULK');
        }
      }

      _pendingScreenshotTransactions = null;
      ref.invalidate(transactionListProvider);

      return '✅ Đã thêm **$created giao dịch** vào ví **${wallet.name}**.';
    } catch (e) {
      Log.e('Bulk create failed: $e', label: 'SCREENSHOT_BULK');
      return '❌ Lỗi khi tạo giao dịch: $e';
    }
  }

  /// Add all pending screenshot transactions to pending queue
  Future<String> _handleScreenshotToPending() async {
    final transactions = _pendingScreenshotTransactions;
    if (transactions == null || transactions.isEmpty) {
      return '❌ Không có giao dịch nào để thêm.';
    }

    try {
      final database = ref.read(databaseProvider);
      int added = 0;

      for (final result in transactions) {
        try {
          DateTime txDate;
          try {
            txDate = DateTime.parse(result.date);
          } catch (_) {
            txDate = DateTime.now();
          }

          await database.pendingTransactionDao.insertPending(
            db.PendingTransactionsCompanion.insert(
              source: PendingSource.bank,
              sourceId: 'screenshot_${DateTime.now().millisecondsSinceEpoch}_$added',
              amount: result.amount,
              currency: drift.Value(result.currency ?? 'VND'),
              transactionType: 'expense',
              title: result.merchant,
              merchant: drift.Value(result.merchant),
              transactionDate: txDate,
              confidence: drift.Value(0.85),
              categoryHint: drift.Value(result.category),
              sourceDisplayName: 'Screenshot',
              status: drift.Value(PendingStatus.pendingReview),
            ),
          );
          added++;
        } catch (e) {
          Log.e('Failed to add pending: ${result.merchant}: $e',
              label: 'SCREENSHOT_PENDING');
        }
      }

      _pendingScreenshotTransactions = null;

      return '📋 Đã đưa **$added giao dịch** vào danh sách chờ duyệt.';
    } catch (e) {
      Log.e('Add to pending failed: $e', label: 'SCREENSHOT_PENDING');
      return '❌ Lỗi: $e';
    }
  }

  /// Convert ReceiptScanResult to action map for _createTransactionFromAction
  Map<String, dynamic> _receiptToActionMap(ReceiptScanResult result) {
    return {
      'action': 'create_expense',
      'amount': result.amount,
      'currency': result.currency ?? 'VND',
      'description': result.merchant,
      'category': result.category,
      'date': result.date,
    };
  }

  /// Update existing message in database
  Future<void> _updateMessageInDatabase(ChatMessage message) async {
    try {
      final dao = ref.read(chatMessageDaoProvider);
      Log.d('Updating message ${message.id} with content: ${message.content}', label: 'Chat Provider');
      final rowsAffected = await dao.updateMessageContent(
        message.id,
        message.content,
      );
      Log.d('Updated $rowsAffected rows in database', label: 'Chat Provider');
    } catch (e) {
      Log.e('Failed to update message in database: $e', label: 'Chat Provider');
    }
  }

  /// Update AI with current budgets context
  Future<void> _updateBudgetsContext() async {
    try {
      print('[AI_CONTEXT] _updateBudgetsContext START');
      // Use DAO directly instead of provider to avoid autoDispose issues
      final budgetDao = ref.read(budgetDaoProvider);
      final allBudgets = await budgetDao.watchAllBudgets().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('[AI_CONTEXT] Budget fetch TIMEOUT');
          return <BudgetModel>[];
        },
      );
      print('[AI_CONTEXT] Got ${allBudgets.length} budgets total');

      // Filter to current month only (same logic as _getBudgetsListText)
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
      final budgets = allBudgets.where((b) {
        return (b.startDate.isBefore(currentMonthEnd) || b.startDate.isAtSameMomentAs(currentMonthEnd)) &&
            (b.endDate.isAfter(currentMonthStart) || b.endDate.isAtSameMomentAs(currentMonthStart));
      }).toList();
      print('[AI_CONTEXT] Got ${budgets.length} budgets for current month');

      final wallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      final currency = wallet?.currency ?? 'VND';

      if (budgets.isEmpty) {
        _aiService.updateBudgetsContext('');
        print('[AI_CONTEXT] _updateBudgetsContext END (empty)');
        return;
      }

      final buffer = StringBuffer();
      for (final budget in budgets) {
        final amountText = _formatAmount(budget.amount, currency: currency);
        buffer.writeln('#${budget.id} - ${budget.category?.title ?? 'Unknown'}: $amountText');
      }

      final contextString = buffer.toString().trim();
      Log.d('Updating AI with budgets context:\n$contextString', label: 'Chat Provider');
      _aiService.updateBudgetsContext(contextString);
    } catch (e) {
      Log.e('Failed to update budgets context: $e', label: 'Chat Provider');
    }
  }

  /// Build spending insights context for AI financial coaching
  /// Aggregates across ALL user wallets (matches dashboard behavior).
  Future<void> _updateSpendingInsightsContext() async {
    try {
      final dbInstance = ref.read(databaseProvider);
      final allWalletsAsync = ref.read(allWalletsStreamProvider);
      final allWallets = _unwrapAsyncValue(allWalletsAsync) ?? [];
      if (allWallets.isEmpty) {
        _aiService.updateSpendingInsights('');
        return;
      }

      // Use active wallet's currency if available, else first wallet's currency.
      // When wallets have mixed currencies we still aggregate amounts as-is
      // (same approximation the dashboard uses).
      final activeWallet = _unwrapAsyncValue(ref.read(activeWalletProvider));
      final primaryWallet = activeWallet ?? allWallets.first;
      final currency = primaryWallet.currency;
      final walletLabel = allWallets.length == 1
          ? allWallets.first.name
          : 'All wallets (${allWallets.length})';
      final totalBalance = allWallets.fold<double>(0, (s, w) => s + w.balance);

      final now = DateTime.now();

      // Current month range
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));

      // Previous month range
      final prevMonthStart = DateTime(now.year, now.month - 1, 1);
      final prevMonthEnd = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));

      // Fetch all transactions across all wallets
      final allTransactions = await dbInstance.transactionDao
          .watchAllTransactionsWithDetails()
          .first
          .timeout(const Duration(seconds: 5), onTimeout: () => []);

      // Filter by month
      final currentMonthTx = allTransactions.where((t) =>
          !t.date.isBefore(currentMonthStart) && !t.date.isAfter(currentMonthEnd)).toList();
      final prevMonthTx = allTransactions.where((t) =>
          !t.date.isBefore(prevMonthStart) && !t.date.isAfter(prevMonthEnd)).toList();

      // Current month totals
      final currentIncome = currentMonthTx
          .where((t) => t.transactionType == TransactionType.income)
          .fold<double>(0, (s, t) => s + t.amount);
      final currentExpense = currentMonthTx
          .where((t) => t.transactionType == TransactionType.expense)
          .fold<double>(0, (s, t) => s + t.amount);

      // Previous month totals
      final prevExpense = prevMonthTx
          .where((t) => t.transactionType == TransactionType.expense)
          .fold<double>(0, (s, t) => s + t.amount);

      // Category breakdown (current month expenses, top 5)
      final categorySpending = <String, double>{};
      for (final tx in currentMonthTx.where((t) => t.transactionType == TransactionType.expense)) {
        final catName = tx.category.title;
        categorySpending[catName] = (categorySpending[catName] ?? 0) + tx.amount;
      }
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCategories = sortedCategories.take(5);

      // Budget usage
      final budgetDao = ref.read(budgetDaoProvider);
      final allBudgets = await budgetDao.watchAllBudgets().first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => <BudgetModel>[],
      );
      final currentBudgets = allBudgets.where((b) =>
          b.startDate.isBefore(currentMonthEnd) && b.endDate.isAfter(currentMonthStart)).toList();

      // Build context string
      String fmt(num v) => v.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

      final buffer = StringBuffer();

      // Monthly overview
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysElapsed = now.day;
      buffer.writeln('This month ($daysElapsed/$daysInMonth days): Income ${fmt(currentIncome)} $currency, Expense ${fmt(currentExpense)} $currency, Net ${fmt(currentIncome - currentExpense)} $currency');

      // Month-over-month comparison
      if (prevExpense > 0) {
        final changePercent = ((currentExpense - prevExpense) / prevExpense * 100).round();
        final direction = changePercent > 0 ? 'UP' : (changePercent < 0 ? 'DOWN' : 'SAME');
        buffer.writeln('vs last month: Spending $direction ${changePercent.abs()}% (was ${fmt(prevExpense)} $currency)');
      }

      // Top spending categories
      if (topCategories.isNotEmpty) {
        buffer.write('Top categories: ');
        buffer.writeln(topCategories.map((e) => '${e.key} ${fmt(e.value)} $currency').join(', '));
      }

      // Budget status
      for (final budget in currentBudgets) {
        final catName = budget.category?.title ?? 'Unknown';
        final spent = categorySpending[catName] ?? 0;
        final pct = budget.amount > 0 ? (spent / budget.amount * 100).round() : 0;
        if (pct >= 50) {
          buffer.writeln('Budget "$catName": ${fmt(spent)}/${fmt(budget.amount)} $currency ($pct% used)');
        }
      }

      // Savings potential and wallet balance (for CASA coaching)
      final savingsPotential = currentIncome - currentExpense;
      if (savingsPotential > 0) {
        final interestEarnings6mo = (savingsPotential * 0.055 * 6 / 12);
        buffer.writeln('Savings potential: ${fmt(savingsPotential)} $currency idle this month → ${fmt(interestEarnings6mo)} $currency interest if saved 6 months at 5.5%');
      }
      buffer.writeln('$walletLabel total balance: ${fmt(totalBalance)} $currency');

      // Financial Health Score
      try {
        final savingsRate = currentIncome > 0
            ? ((currentIncome - currentExpense) / currentIncome).clamp(-1.0, 1.0)
            : 0.0;
        final healthScore = _computeQuickHealthScore(
          savingsRate: savingsRate,
          budgetAdherence: currentBudgets.isEmpty
              ? 1.0
              : currentBudgets.where((b) =>
                  (categorySpending[b.category?.title ?? ''] ?? 0) <= b.amount
                ).length / currentBudgets.length,
          expenseTrend: prevExpense > 0
              ? ((currentExpense - prevExpense) / prevExpense).clamp(-1.0, 1.0)
              : 0.0,
        );
        buffer.writeln('Financial Health Score: $healthScore/100 (savings rate ${(savingsRate * 100).round()}%)');
      } catch (_) {}

      // Active recurring payments (for subscription optimization coaching)
      try {
        final allRecurring = await dbInstance.recurringDao.watchAllRecurrings().first
            .timeout(const Duration(seconds: 3), onTimeout: () => []);
        final activeRecurring = allRecurring.where((r) => r.isActive).toList();
        if (activeRecurring.isNotEmpty) {
          final monthlyTotal = activeRecurring.fold<double>(0, (sum, r) {
            switch (r.frequency) {
              case RecurringFrequency.daily: return sum + r.amount * 30;
              case RecurringFrequency.weekly: return sum + r.amount * 4;
              case RecurringFrequency.monthly: return sum + r.amount;
              case RecurringFrequency.yearly: return sum + r.amount / 12;
              default: return sum + r.amount;
            }
          });
          buffer.writeln('Active recurring (${activeRecurring.length}): ${activeRecurring.map((r) => '${r.name} ${fmt(r.amount)} $currency/${r.frequency.name}').join(', ')} → Total ~${fmt(monthlyTotal)} $currency/month');
        }
      } catch (_) {}

      // Spending forecast (end-of-month projection)
      try {
        final dailyBurnRate = daysElapsed > 0 ? currentExpense / daysElapsed : 0.0;
        final projectedExpense = currentExpense + dailyBurnRate * (daysInMonth - daysElapsed);
        final dailyEarnRate = daysElapsed > 0 ? currentIncome / daysElapsed : 0.0;
        final projectedIncome = currentIncome + dailyEarnRate * (daysInMonth - daysElapsed);
        if (projectedExpense > 0 || projectedIncome > 0) {
          buffer.writeln('End-of-month forecast: projected expense ${fmt(projectedExpense)} $currency, projected income ${fmt(projectedIncome)} $currency, daily burn rate ${fmt(dailyBurnRate)} $currency/day (${daysInMonth - daysElapsed} days remaining)');
        }
      } catch (_) {}

      final contextString = buffer.toString().trim();
      if (contextString.isNotEmpty) {
        Log.d('Updating AI with spending insights:\n$contextString', label: 'Chat Provider');
        _aiService.updateSpendingInsights(contextString);
      } else {
        _aiService.updateSpendingInsights('');
      }
    } catch (e) {
      Log.e('Failed to update spending insights: $e', label: 'Chat Provider');
      _aiService.updateSpendingInsights('');
    }
  }

  /// Mock: Open Shinhan savings account (hackathon demo)
  String _mockOpenSavingsAccount(Map<String, dynamic> action) {
    final amount = (action['amount'] as num?)?.toDouble() ?? 0;
    final currency = action['currency'] ?? 'VND';
    final termMonths = (action['termMonths'] as num?)?.toInt() ?? 6;
    final rate = (action['interestRate'] as num?)?.toDouble() ?? 5.5;
    final interest = (amount * rate / 100 * termMonths / 12);
    String fmt(num v) => v.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '✅ **Shinhan Savings Account opened!**\n'
        '• Amount: ${fmt(amount)} $currency\n'
        '• Term: $termMonths months at ${rate}% annual\n'
        '• Estimated interest: ${fmt(interest)} $currency\n'
        '• Account: SOL-SAV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}\n'
        '_(Demo mode — in production, this connects to Shinhan Banking API)_';
  }

  /// Mock: Apply for Shinhan credit card (hackathon demo)
  String _mockApplyCreditCard(Map<String, dynamic> action) {
    final cardType = action['cardType'] ?? 'cashback';
    final cardNames = {
      'cashback': 'Shinhan Cashback Credit Card',
      'fx': 'Shinhan FX Multi-Currency Card',
      'premium': 'Shinhan Premium Card',
    };
    final cardBenefits = {
      'cashback': '5% cashback on dining, 3% on shopping',
      'fx': '0% FX markup, free international ATM',
      'premium': 'Airport lounge access, travel insurance',
    };
    return '✅ **Credit card application submitted!**\n'
        '• Card: ${cardNames[cardType] ?? cardNames['cashback']}\n'
        '• Benefits: ${cardBenefits[cardType] ?? cardBenefits['cashback']}\n'
        '• Status: Under review (1-3 business days)\n'
        '• Ref: CC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}\n'
        '_(Demo mode — in production, this connects to Shinhan Banking API)_';
  }

  /// Mock: Apply for Shinhan loan (hackathon demo)
  String _mockApplyLoan(Map<String, dynamic> action) {
    final amount = (action['amount'] as num?)?.toDouble() ?? 0;
    final currency = action['currency'] ?? 'VND';
    final termMonths = (action['termMonths'] as num?)?.toInt() ?? 24;
    final purpose = action['purpose'] ?? 'Personal';
    String fmt(num v) => v.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    final monthlyPayment = amount > 0 ? (amount * (1 + 0.079 * termMonths / 12) / termMonths) : 0;
    return '✅ **Loan application submitted!**\n'
        '• Amount: ${fmt(amount)} $currency\n'
        '• Term: $termMonths months at 7.9% annual\n'
        '• Purpose: $purpose\n'
        '• Est. monthly payment: ~${fmt(monthlyPayment)} $currency\n'
        '• Status: Under review (3-5 business days)\n'
        '• Ref: LN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}\n'
        '_(Demo mode — in production, this connects to Shinhan Banking API)_';
  }

  /// Quick health score computation for AI context (simplified version)
  int _computeQuickHealthScore({
    required double savingsRate,
    required double budgetAdherence,
    required double expenseTrend,
  }) {
    // Savings (30 pts)
    final savingsScore = savingsRate >= 0.2 ? 30.0
        : savingsRate >= 0 ? 10.0 + (savingsRate / 0.2) * 20.0
        : 0.0;
    // Budget (25 pts)
    final budgetScore = budgetAdherence * 25.0;
    // Trend (20 pts)
    final trendScore = expenseTrend <= -0.1 ? 20.0
        : expenseTrend <= 0 ? 10.0 + (expenseTrend.abs() / 0.1) * 10.0
        : (10.0 - (expenseTrend / 0.2) * 10.0).clamp(0.0, 10.0);
    // Base activity (25 pts assumed for simplicity in AI context)
    return (savingsScore + budgetScore + trendScore + 15).round().clamp(0, 100);
  }

  /// Mock: Transfer to Shinhan savings (hackathon demo)
  String _mockTransferToSavings(Map<String, dynamic> action) {
    final amount = (action['amount'] as num?)?.toDouble() ?? 0;
    final currency = action['currency'] ?? 'VND';
    final fromWallet = action['fromWallet'] ?? 'Current Account';
    String fmt(num v) => v.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '✅ **Transfer to savings completed!**\n'
        '• From: $fromWallet\n'
        '• To: Shinhan Savings Account\n'
        '• Amount: ${fmt(amount)} $currency\n'
        '• Ref: TRF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}\n'
        '_(Demo mode — in production, this connects to Shinhan Banking API)_';
  }

}

// Helper provider to get the last message
final lastMessageProvider = Provider<ChatMessage?>((ref) {
  final chatState = ref.watch(chatProvider);
  if (chatState.messages.isEmpty) return null;
  return chatState.messages.last;
});

// Helper provider to check if chat is empty (only welcome message)
final isChatEmptyProvider = Provider<bool>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.messages.length <= 1;
});

// Helper provider to get message count
final messageCountProvider = Provider<int>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.messages.length;
});
