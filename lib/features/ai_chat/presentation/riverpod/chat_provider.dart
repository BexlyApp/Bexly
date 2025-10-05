import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/features/ai_chat/domain/models/chat_message.dart';
import 'package:bexly/features/ai_chat/data/services/ai_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/config/llm_config.dart';
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
import 'package:bexly/features/ai_chat/presentation/riverpod/chat_dao_provider.dart';
import 'package:bexly/core/database/pockaw_database.dart' as db;
import 'package:drift/drift.dart' as drift;
// import 'package:bexly/core/services/sync/data_sync_service.dart';

// AI Service Provider - Supports both OpenAI and Gemini
final aiServiceProvider = Provider<AIService>((ref) {
  // Get categories from database
  final categoriesAsync = ref.watch(hierarchicalCategoriesProvider);
  final List<String> categories = categoriesAsync.maybeWhen(
    data: (cats) {
      final categoryNames = cats.map((c) => c.title).toList();
      Log.d('Categories loaded for AI: ${categoryNames.join(", ")}', label: 'Chat Provider');
      return categoryNames;
    },
    orElse: () {
      Log.i('Categories not loaded yet, using empty list', label: 'Chat Provider');
      return <String>[];
    },
  );

  // Get wallet currency for context (use read to avoid rebuild)
  final wallet = ref.read(activeWalletProvider).valueOrNull;
  final walletCurrency = wallet?.currency ?? 'VND';

  // Check which AI provider to use
  final provider = LLMDefaultConfig.provider;

  if (provider == 'gemini') {
    // Use Gemini service
    final apiKey = LLMDefaultConfig.geminiApiKey.isEmpty
        ? 'USER_MUST_PROVIDE_API_KEY'
        : LLMDefaultConfig.geminiApiKey;

    if (apiKey != 'USER_MUST_PROVIDE_API_KEY' && apiKey.length > 10) {
      final maskedKey = '${apiKey.substring(0, 7)}...${apiKey.substring(apiKey.length - 4)}';
      Log.d('Using Gemini Service with API key: $maskedKey, model: ${LLMDefaultConfig.geminiModel}, currency: $walletCurrency', label: 'Chat Provider');
    } else {
      Log.e('Invalid or missing Gemini API key!', label: 'Chat Provider');
    }

    return GeminiService(
      apiKey: apiKey,
      model: LLMDefaultConfig.geminiModel,
      categories: categories,
    );
  } else {
    // Default to OpenAI service
    final apiKey = LLMDefaultConfig.apiKey.isEmpty
        ? 'USER_MUST_PROVIDE_API_KEY'
        : LLMDefaultConfig.apiKey;

    if (apiKey != 'USER_MUST_PROVIDE_API_KEY' && apiKey.length > 10) {
      final maskedKey = '${apiKey.substring(0, 7)}...${apiKey.substring(apiKey.length - 4)}';
      Log.d('Using OpenAI Service with API key: $maskedKey, model: ${LLMDefaultConfig.model}, currency: $walletCurrency', label: 'Chat Provider');
    } else {
      Log.e('Invalid or missing OpenAI API key!', label: 'Chat Provider');
    }

    return OpenAIService(
      apiKey: apiKey,
      model: LLMDefaultConfig.model,
      categories: categories,
    );
  }
});

// Chat State Provider - Using autoDispose to manage lifecycle
final chatProvider = StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  final aiService = ref.watch(aiServiceProvider);

  // Keep provider alive to preserve chat messages
  ref.keepAlive();

  return ChatNotifier(aiService, ref);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final AIService _aiService;
  final Ref _ref;
  final Uuid _uuid = const Uuid();
  StreamSubscription? _typingSubscription;

  ChatNotifier(this._aiService, this._ref) : super(const ChatState()) {
    _initializeChat();
  }

  void _initializeChat() async {
    // Load messages from database
    final dao = _ref.read(chatMessageDaoProvider);
    final savedMessages = await dao.getAllMessages();

    if (savedMessages.isNotEmpty) {
      // Convert database messages to ChatMessage model
      final messages = savedMessages.map((dbMsg) => ChatMessage(
        id: dbMsg.messageId,
        content: dbMsg.content,
        isFromUser: dbMsg.isFromUser,
        timestamp: dbMsg.timestamp,
        error: dbMsg.error,
        isTyping: dbMsg.isTyping,
      )).toList();

      state = state.copyWith(messages: messages);
    } else {
      // Add welcome message if no history
      final welcomeMessage = ChatMessage(
        id: _uuid.v4(),
        content: 'Welcome to Bexly AI Assistant! I can help you track expenses, record income, check balances, and view transaction summaries. Note: Budget creation is now supported via chat!',
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [welcomeMessage],
      );

      // Save welcome message to database
      await _saveMessageToDatabase(welcomeMessage);
    }
  }

  Future<void> _saveMessageToDatabase(ChatMessage message) async {
    final dao = _ref.read(chatMessageDaoProvider);
    await dao.addMessage(db.ChatMessagesCompanion(
      messageId: drift.Value(message.id),
      content: drift.Value(message.content),
      isFromUser: drift.Value(message.isFromUser),
      timestamp: drift.Value(message.timestamp),
      error: drift.Value(message.error),
      isTyping: drift.Value(message.isTyping),
    ));
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isLoading) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content.trim(),
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message and set loading state
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      isTyping: false,
      error: null,
    );

    // Save user message to database
    await _saveMessageToDatabase(userMessage);

    try {
      // Update AI with recent transactions context before sending message
      await _updateRecentTransactionsContext();

      // Start typing indicator
      _startTypingEffect();

      // Get AI response
      final response = await _aiService.sendMessage(content);

      Log.d('AI Response: $response', label: 'Chat Provider');

      // Cancel typing effect
      _cancelTypingEffect();

      // Extract JSON action if present
      String displayMessage = response;

      // Look for ACTION_JSON: prefix
      final actionIndex = response.indexOf('ACTION_JSON:');
      Log.d('ACTION_JSON index: $actionIndex', label: 'Chat Provider');

      if (actionIndex != -1) {
        // Extract the display message (everything before ACTION_JSON)
        displayMessage = response.substring(0, actionIndex).trim();

        // Extract JSON after ACTION_JSON:
        final jsonStr = response.substring(actionIndex + 12).trim();
        Log.d('Extracted JSON string: $jsonStr', label: 'Chat Provider');

        try {
          final action = jsonDecode(jsonStr);
          Log.d('Parsed action: $action', label: 'Chat Provider');

          // Parse the action
          final String actionType = (action['action'] ?? '').toString();
          switch (actionType) {
            case 'create_expense':
            case 'create_income':
              {
                // Get currency from AI action
                double amount = (action['amount'] as num).toDouble();
                final aiCurrency = action['currency'] ?? 'VND';

                Log.d('AI action: amount=$amount, currency=$aiCurrency', label: 'AI_CURRENCY');

                // Find wallet matching AI currency, or use active wallet
                final allWallets = await _ref.read(walletListProvider.future);
                WalletModel? wallet = allWallets.firstWhereOrNull((w) => w.currency == aiCurrency);

                if (wallet == null) {
                  // No wallet with matching currency, use active wallet
                  wallet = _ref.read(activeWalletProvider).valueOrNull;
                  Log.d('No wallet found for $aiCurrency, using active wallet: ${wallet?.currency}', label: 'AI_CURRENCY');
                } else {
                  Log.d('Found wallet "${wallet.name}" for currency $aiCurrency', label: 'AI_CURRENCY');
                }

                final walletCurrency = wallet?.currency ?? 'VND';

                final description = action['description'];
                final category = action['category'];
                Log.d('Creating transaction: action=${action['action']}, amount=$amount $walletCurrency, desc=$description, cat=$category', label: 'Chat Provider');

                await _createTransactionFromAction(action, wallet: wallet);

                final isIncome = actionType == 'create_income';
                final amountText = _formatAmount(amount, currency: walletCurrency);
                final dateText = _formatDatePhrase(DateTime.now());
                final walletName = wallet?.name ?? 'My Wallet';

                final confirmText = isIncome
                    ? 'Recorded income of ' + amountText + ' to "' + walletName + '" for ' + (action['description']).toString() + ' (Category: ' + (action['category']).toString() + ') on ' + dateText + '.'
                    : 'Recorded expense of ' + amountText + ' from "' + walletName + '" for ' + (action['description']).toString() + ' (Category: ' + (action['category']).toString() + ') on ' + dateText + '.';
                displayMessage += '\n\n✅ ' + confirmText;
                break;
              }
            case 'create_budget':
              {
                Log.d('Processing create_budget action: $action', label: 'Chat Provider');

                final wallet = _ref.read(activeWalletProvider).valueOrNull;
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

                await _createBudgetFromAction({
                  ...action,
                  'amount': amount,
                });

                final amountText = _formatAmount(amount, currency: walletCurrency);
                final categoryName = action['category']?.toString() ?? 'General';
                final period = action['period']?.toString() ?? 'monthly';

                displayMessage += '\n\n✅ Created $period budget of $amountText for $categoryName.';
                break;
              }
            case 'create_goal':
              {
                Log.d('Processing create_goal action: $action', label: 'Chat Provider');

                final wallet = _ref.read(activeWalletProvider).valueOrNull;
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

                final targetAmountText = _formatAmount(targetAmount, currency: walletCurrency);
                final goalTitle = action['title']?.toString() ?? 'New Goal';

                displayMessage += '\n\n✅ Created goal "$goalTitle" with target of $targetAmountText.';
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

                final wallet = _ref.read(activeWalletProvider).valueOrNull;
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

                final wallet = _ref.read(activeWalletProvider).valueOrNull;
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
            default:
              {
                Log.d('Unknown action: $actionType', label: 'Chat Provider');
              }
          }
        } catch (e) {
          Log.e('Failed to parse AI action: $e', label: 'Chat Provider');
          // If JSON parsing fails, just show original response without JSON
        }
      }
      // REMOVED: Fallback inference logic
      // The AI should explicitly return ACTION_JSON when user wants to create a transaction
      // Otherwise, responding to AI questions with numbers would incorrectly create transactions

      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: displayMessage,
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        isTyping: false,
      );

      // Save AI message to database
      await _saveMessageToDatabase(aiMessage);

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

      state = state.copyWith(
        isLoading: false,
        isTyping: false,
        error: errorString,
      );

      // Add error message to chat
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        content: userFriendlyMessage,
        isFromUser: false,
        timestamp: DateTime.now(),
        error: errorString,
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
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
      content: 'Đang nhập...',
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
    state = state.copyWith(error: null);
  }

  void clearChat() async {
    _cancelTypingEffect();

    // Clear messages from database
    final dao = _ref.read(chatMessageDaoProvider);
    await dao.clearAllMessages();

    // Reset state
    state = const ChatState();

    // Re-initialize with welcome message
    _initializeChat();
  }

  Future<void> _createTransactionFromAction(Map<String, dynamic> action, {WalletModel? wallet}) async {
    try {
      // Print to console for debugging
      print('========================================');
      print('[TRANSACTION_DEBUG] _createTransactionFromAction START');
      print('[TRANSACTION_DEBUG] Action received: $action');

      Log.d('========================================', label: 'TRANSACTION_DEBUG');
      Log.d('_createTransactionFromAction START', label: 'TRANSACTION_DEBUG');
      Log.d('Action received: $action', label: 'TRANSACTION_DEBUG');

      // Use provided wallet or get current wallet
      wallet ??= _ref.read(activeWalletProvider).valueOrNull;

      if (wallet == null || wallet.id == null) {
        Log.e('ERROR: No wallet available or wallet ID is null!', label: 'TRANSACTION_DEBUG');
        return;
      }

      Log.d('Using wallet: ${wallet.name} (id: ${wallet.id}, balance: ${wallet.balance} ${wallet.currency})', label: 'TRANSACTION_DEBUG');

      // Get categories and find matching one
      final categoriesAsync = _ref.read(hierarchicalCategoriesProvider);
      Log.d('Categories async state: $categoriesAsync', label: 'TRANSACTION_DEBUG');

      final categories = categoriesAsync.maybeWhen(
        data: (cats) => cats,
        orElse: () => [],
      );
      Log.d('Available categories count: ${categories.length}', label: 'TRANSACTION_DEBUG');

      if (categories.isEmpty) {
        Log.e('ERROR: No categories available!', label: 'TRANSACTION_DEBUG');
        return;
      }

      final categoryName = action['category'] as String;
      Log.d('Looking for category: "$categoryName"', label: 'TRANSACTION_DEBUG');
      Log.d('Available categories: ${categories.map((c) => c.title).join(", ")}', label: 'TRANSACTION_DEBUG');

      // Try exact match first, then fuzzy match, then default
      CategoryModel? category;

      // Exact match (case insensitive)
      category = categories.firstWhereOrNull(
        (c) => c.title.toLowerCase() == categoryName.toLowerCase(),
      );

      // If no exact match, try contains match
      if (category == null) {
        category = categories.firstWhereOrNull(
          (c) => c.title.toLowerCase().contains(categoryName.toLowerCase()) ||
                 categoryName.toLowerCase().contains(c.title.toLowerCase()),
        );
      }

      // If still no match, use "Others" or first category
      if (category == null) {
        category = categories.firstWhereOrNull((c) => c.title == 'Others') ??
                  categories.firstOrNull ??
                  categories.first;
        Log.d('Category "$categoryName" not found, using: ${category?.title}', label: 'TRANSACTION_DEBUG');
      }

      Log.d('Selected category: ${category?.title} (id: ${category?.id})', label: 'TRANSACTION_DEBUG');

      // Create transaction model
      final transactionType = action['action'] == 'create_income'
          ? TransactionType.income
          : TransactionType.expense;
      final amount = (action['amount'] as num).toDouble();
      final title = action['description'] as String;
      final date = DateTime.now();

      Log.d('Creating transaction model:', label: 'TRANSACTION_DEBUG');
      Log.d('  - Type: $transactionType', label: 'TRANSACTION_DEBUG');
      Log.d('  - Amount: $amount', label: 'TRANSACTION_DEBUG');
      Log.d('  - Title: "$title"', label: 'TRANSACTION_DEBUG');
      Log.d('  - Date: $date', label: 'TRANSACTION_DEBUG');
      Log.d('  - Category ID: ${category?.id}', label: 'TRANSACTION_DEBUG');
      Log.d('  - Wallet ID: ${wallet.id}', label: 'TRANSACTION_DEBUG');

      final transaction = TransactionModel(
        id: null, // Will be generated by database
        transactionType: transactionType,
        amount: amount,
        date: date,
        title: title,
        category: category!,
        wallet: wallet,
        notes: 'Created by AI Assistant',
      );

      // Insert to database
      Log.d('Getting database instance...', label: 'TRANSACTION_DEBUG');
      final db = _ref.read(databaseProvider);
      Log.d('Database instance obtained: $db', label: 'TRANSACTION_DEBUG');

      // Validate transaction before insert
      if (category?.id == null) {
        Log.e('ERROR: Category ID is null!', label: 'TRANSACTION_DEBUG');
        return;
      }
      if (wallet.id == null) {
        Log.e('ERROR: Wallet ID is null!', label: 'TRANSACTION_DEBUG');
        return;
      }

      Log.d('Calling db.transactionDao.addTransaction()...', label: 'TRANSACTION_DEBUG');
      final insertedId = await db.transactionDao.addTransaction(transaction);

      print('[TRANSACTION_DEBUG] TRANSACTION INSERTED! ID: $insertedId');
      Log.d('TRANSACTION INSERTED! ID: $insertedId', label: 'TRANSACTION_DEBUG');

      // Verify transaction was saved
      if (insertedId <= 0) {
        print('[TRANSACTION_ERROR] Invalid insert ID: $insertedId');
        Log.e('ERROR: Invalid insert ID: $insertedId', label: 'TRANSACTION_DEBUG');
        return;
      }

      // Adjust wallet balance
      Log.d('Adjusting wallet balance...', label: 'TRANSACTION_DEBUG');
      await _adjustWalletBalanceAfterCreate(transaction);
      Log.d('Wallet balance adjusted', label: 'TRANSACTION_DEBUG');

      // IMPORTANT: Force refresh transaction providers to update UI
      // This ensures the transaction list is refreshed after insert
      Log.d('Forcing transaction provider refresh...', label: 'TRANSACTION_DEBUG');

      // Invalidate both transaction providers to update UI
      // Wallet balance is already updated via _adjustWalletBalanceAfterCreate
      _ref.invalidate(transactionListProvider);
      _ref.invalidate(allTransactionsProvider);

      Log.d('Transaction list provider invalidated, UI should update', label: 'TRANSACTION_DEBUG');

      // TODO: Re-enable cloud sync after fixing data_sync_service.dart
      // try {
      //   Log.d('Triggering immediate cloud sync...', label: 'TRANSACTION_DEBUG');
      //   _ref.read(dataSyncServiceProvider.notifier).syncAll();
      //   Log.d('Cloud sync triggered successfully', label: 'TRANSACTION_DEBUG');
      // } catch (e) {
      //   Log.i('Cloud sync failed (may not be authenticated): $e', label: 'TRANSACTION_DEBUG');
      // }

      Log.d('_createTransactionFromAction COMPLETE', label: 'TRANSACTION_DEBUG');
      Log.d('========================================', label: 'TRANSACTION_DEBUG');
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
    }
  }

  Future<void> _createBudgetFromAction(Map<String, dynamic> action) async {
    Log.d('Creating budget from action: $action', label: 'BUDGET_DEBUG');

    try {
      final wallet = _ref.read(activeWalletProvider).valueOrNull;
      if (wallet == null) {
        Log.e('No active wallet for budget creation', label: 'BUDGET_DEBUG');
        return;
      }

      // Get category
      final categoryName = action['category']?.toString() ?? 'Others';
      final categories = _ref.read(hierarchicalCategoriesProvider).valueOrNull ?? [];

      // Find matching category (case-insensitive, partial match)
      var category = categories.firstWhereOrNull(
        (c) => c.title.toLowerCase().contains(categoryName.toLowerCase()) ||
               categoryName.toLowerCase().contains(c.title.toLowerCase())
      );

      // If no match, try exact match
      category ??= categories.firstWhereOrNull(
        (c) => c.title.toLowerCase() == categoryName.toLowerCase()
      );

      // If still no match, use "Others" or first category
      if (category == null) {
        category = categories.firstWhereOrNull((c) => c.title == 'Others') ??
                  categories.firstOrNull;
        if (category == null) {
          Log.e('No categories available for budget', label: 'BUDGET_DEBUG');
          return;
        }
      }

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

      // Save budget to database
      final budgetDao = _ref.read(budgetDaoProvider);
      await budgetDao.addBudget(budget);

      Log.d('Budget created successfully', label: 'BUDGET_DEBUG');

      // Invalidate budget list to refresh UI
      _ref.invalidate(budgetListProvider);

      // TODO: Re-enable cloud sync after fixing data_sync_service.dart
      // try {
      //   Log.d('Triggering immediate cloud sync...', label: 'BUDGET_DEBUG');
      //   _ref.read(dataSyncServiceProvider.notifier).syncAll();
      //   Log.d('Cloud sync triggered successfully', label: 'BUDGET_DEBUG');
      // } catch (e) {
      //   Log.i('Cloud sync failed (may not be authenticated): $e', label: 'BUDGET_DEBUG');
      // }

    } catch (e, stackTrace) {
      Log.e('Failed to create budget: $e', label: 'BUDGET_ERROR');
      Log.e('Stack trace: $stackTrace', label: 'BUDGET_ERROR');
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
      final database = _ref.read(databaseProvider);

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

      await database.goalDao.addGoal(companion);

      Log.d('Goal created successfully', label: 'GOAL_DEBUG');

      // Invalidate goal list to refresh UI
      _ref.invalidate(goalsListProvider);

      // TODO: Re-enable cloud sync after fixing data_sync_service.dart
      // try {
      //   Log.d('Triggering immediate cloud sync...', label: 'GOAL_DEBUG');
      //   _ref.read(dataSyncServiceProvider.notifier).syncAll();
      //   Log.d('Cloud sync triggered successfully', label: 'GOAL_DEBUG');
      // } catch (e) {
      //   Log.i('Cloud sync failed (may not be authenticated): $e', label: 'GOAL_DEBUG');
      // }

    } catch (e, stackTrace) {
      Log.e('Failed to create goal: $e', label: 'GOAL_ERROR');
      Log.e('Stack trace: $stackTrace', label: 'GOAL_ERROR');
    }
  }

  Future<String> _getActiveWalletBalanceText() async {
    final walletState = _ref.read(activeWalletProvider);
    final wallet = walletState.valueOrNull;
    if (wallet == null) {
      return 'No active wallet selected.';
    }
    final amount = (wallet.balance).toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => m.group(1)! + '.');
    return 'Current balance in "' + wallet.name + '": ' + amount + ' ' + wallet.currency;
  }

  Future<String> _getSummaryText(Map<String, dynamic> action) async {
    try {
      final db = _ref.read(databaseProvider);
      final wallet = _ref.read(activeWalletProvider).valueOrNull;
      if (wallet == null || wallet.id == null) return 'No active wallet selected.';

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
      return 'Tóm tắt ${range} (${start.toIso8601String().substring(0,10)} → ${end.toIso8601String().substring(0,10)}):\n'
          '• Thu: ${fmt(income)} ${wallet.currency}\n'
          '• Chi: ${fmt(expense)} ${wallet.currency}\n'
          '• Ròng: ${fmt(net)} ${wallet.currency}';
    } catch (e) {
      Log.e('Summary error: $e', label: 'Chat Provider');
      return 'Không tạo được tóm tắt.';
    }
  }

  Future<String> _getTransactionsListText(Map<String, dynamic> action) async {
    try {
      final db = _ref.read(databaseProvider);
      final wallet = _ref.read(activeWalletProvider).valueOrNull;
      if (wallet == null || wallet.id == null) return 'No active wallet selected.';

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
      if (take.isEmpty) return 'No transactions found in this time period.';

      String fmt(num v) => v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
      final lines = take.map((t) =>
          '- ${t.title} • ${(t.transactionType == TransactionType.expense ? '-' : '+')}${fmt(t.amount)} ${t.wallet.currency} • ${t.category.title}');
      return 'Recent transactions:\n' + lines.join('\n');
    } catch (e) {
      Log.e('List tx error: $e', label: 'Chat Provider');
      return 'Unable to retrieve transaction list.';
    }
  }

  String _formatAmount(num value, {String? currency}) {
    final intPart = value.round();
    final text = intPart.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => m.group(1)! + '.');
    if (currency != null && currency.isNotEmpty) {
      // Special formatting for currencies
      if (currency == 'VND' || currency == 'đ') {
        return text + ' đ';
      } else if (currency == 'USD') {
        return '\$' + text;
      }
      return text + ' ' + currency;
    }
    return text + ' đ';
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
      final wallet = _ref.read(activeWalletProvider).valueOrNull;
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
      final categoriesAsync = _ref.read(hierarchicalCategoriesProvider);
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

  Future<void> _adjustWalletBalanceAfterCreate(TransactionModel newTransaction) async {
    try {
      final db = _ref.read(databaseProvider);
      final wallet = _ref.read(activeWalletProvider).valueOrNull;
      if (wallet == null || wallet.id == null) return;
      double balanceChange = 0.0;
      if (newTransaction.transactionType == TransactionType.income) {
        balanceChange += newTransaction.amount;
      } else if (newTransaction.transactionType == TransactionType.expense) {
        balanceChange -= newTransaction.amount;
      }
      final updatedWallet = wallet.copyWith(balance: wallet.balance + balanceChange);
      await db.walletDao.updateWallet(updatedWallet);
      _ref.read(activeWalletProvider.notifier).setActiveWallet(updatedWallet);
    } catch (e) {
      Log.e('adjust wallet after create failed: $e', label: 'Chat Provider');
    }
  }

  Future<String> _updateTransactionFromAction(Map<String, dynamic> action) async {
    try {
      final transactionId = (action['transactionId'] as num).toInt();
      Log.d('Updating transaction ID: $transactionId', label: 'UPDATE_TRANSACTION');

      // Get transaction from database
      final db = _ref.read(databaseProvider);
      final transactions = await db.transactionDao.watchFilteredTransactionsWithDetails(
        walletId: _ref.read(activeWalletProvider).valueOrNull?.id ?? 0,
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
        final wallet = _ref.read(activeWalletProvider).valueOrNull;
        final walletCurrency = wallet?.currency ?? 'VND';
        final aiCurrency = action['currency'];

        if (aiCurrency == 'VND' && walletCurrency == 'USD') {
          newAmount = newAmount / 25000;
        }
      }

      // Get category if changed
      CategoryModel? newCategory;
      if (newCategoryName != null) {
        final categories = _ref.read(hierarchicalCategoriesProvider).valueOrNull ?? [];
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
      await db.transactionDao.updateTransaction(updatedTransaction);

      // Adjust wallet balance (reverse old, apply new)
      final wallet = _ref.read(activeWalletProvider).valueOrNull;
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
        await db.walletDao.updateWallet(updatedWallet);
        _ref.read(activeWalletProvider.notifier).setActiveWallet(updatedWallet);
      }

      // Invalidate providers to refresh UI
      _ref.invalidate(transactionListProvider);

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
      final db = _ref.read(databaseProvider);
      final walletId = await db.walletDao.addWallet(wallet);

      final createdWallet = wallet.copyWith(id: walletId);
      final amountText = _formatAmount(initialBalance, currency: currency);

      return '✅ Created wallet "$name" with initial balance of $amountText';
    } catch (e, stackTrace) {
      Log.e('Failed to create wallet: $e', label: 'CREATE_WALLET');
      Log.e('Stack trace: $stackTrace', label: 'CREATE_WALLET');
      return '❌ Failed to create wallet: $e';
    }
  }

  Future<String> _deleteTransactionFromAction(Map<String, dynamic> action) async {
    try {
      final transactionId = (action['transactionId'] as num).toInt();
      Log.d('Deleting transaction ID: $transactionId', label: 'DELETE_TRANSACTION');

      // Get transaction from database
      final db = _ref.read(databaseProvider);
      final transactions = await db.transactionDao.watchFilteredTransactionsWithDetails(
        walletId: _ref.read(activeWalletProvider).valueOrNull?.id ?? 0,
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
      await db.transactionDao.deleteTransaction(transactionId);

      // Adjust wallet balance (reverse the transaction)
      final wallet = _ref.read(activeWalletProvider).valueOrNull;
      if (wallet != null) {
        double balanceAdjustment = 0;

        if (type == TransactionType.income) {
          balanceAdjustment -= amount; // Remove income
        } else {
          balanceAdjustment += amount; // Remove expense (add back)
        }

        final updatedWallet = wallet.copyWith(balance: wallet.balance + balanceAdjustment);
        await db.walletDao.updateWallet(updatedWallet);
        _ref.read(activeWalletProvider.notifier).setActiveWallet(updatedWallet);
      }

      // Invalidate providers to refresh UI
      _ref.invalidate(transactionListProvider);

      final amountText = _formatAmount(amount, currency: wallet?.currency ?? 'VND');
      return '✅ Deleted transaction: $description ($amountText)';
    } catch (e, stackTrace) {
      Log.e('Failed to delete transaction: $e', label: 'DELETE_TRANSACTION');
      Log.e('Stack trace: $stackTrace', label: 'DELETE_TRANSACTION');
      return '❌ Failed to delete transaction: $e';
    }
  }

  /// Update AI service with recent transactions context
  Future<void> _updateRecentTransactionsContext() async {
    try {
      final wallet = _ref.read(activeWalletProvider).valueOrNull;
      if (wallet == null || wallet.id == null) {
        Log.d('No active wallet or wallet ID is null, skipping transaction context update', label: 'Chat Provider');
        return;
      }

      // Get recent 10 transactions
      final db = _ref.read(databaseProvider);
      final transactions = await db.transactionDao.watchFilteredTransactionsWithDetails(
        walletId: wallet.id!,
        filter: null,
      ).first;

      // Take only the 10 most recent
      final recentTransactions = transactions.take(10).toList();

      if (recentTransactions.isEmpty) {
        Log.d('No recent transactions to provide to AI', label: 'Chat Provider');
        _aiService.updateRecentTransactions('');
        return;
      }

      // Format transactions as context string
      final context = StringBuffer();
      for (final tx in recentTransactions) {
        final amountText = _formatAmount(tx.amount, currency: wallet.currency);
        final typeIcon = tx.transactionType == TransactionType.income ? '📈' : '📉';
        context.writeln('#${tx.id} - $typeIcon $amountText - ${tx.title} (${tx.category.title})');
      }

      final contextString = context.toString().trim();
      Log.d('Updating AI with recent transactions:\n$contextString', label: 'Chat Provider');
      _aiService.updateRecentTransactions(contextString);
    } catch (e, stackTrace) {
      Log.e('Failed to update recent transactions context: $e', label: 'Chat Provider');
      Log.e('Stack trace: $stackTrace', label: 'Chat Provider');
    }
  }

  @override
  void dispose() {
    _typingSubscription?.cancel();
    super.dispose();
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