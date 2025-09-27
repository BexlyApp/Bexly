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
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';
import 'package:bexly/features/ai_chat/presentation/riverpod/chat_dao_provider.dart';
import 'package:bexly/core/database/pockaw_database.dart' as db;
import 'package:drift/drift.dart' as drift;

// AI Service Provider
final aiServiceProvider = Provider<AIService>((ref) {
  // Get categories from database
  final categoriesAsync = ref.watch(hierarchicalCategoriesProvider);
  final List<String> categories = categoriesAsync.maybeWhen(
    data: (cats) => cats.map((c) => c.title).toList(),
    orElse: () => <String>[],
  );

  // Get wallet currency for context (use read to avoid rebuild)
  final wallet = ref.read(activeWalletProvider).valueOrNull;
  final walletCurrency = wallet?.currency ?? 'VND';

  // Always use OpenAI service - user must provide API key
  final apiKey = LLMDefaultConfig.apiKey.isEmpty
      ? 'USER_MUST_PROVIDE_API_KEY'
      : LLMDefaultConfig.apiKey;

  Log.d('Using OpenAI Service with wallet currency: $walletCurrency', label: 'Chat Provider');
  return OpenAIService(
    apiKey: apiKey,
    model: LLMDefaultConfig.model,
    categories: categories,
  );
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
                // Get wallet currency to handle amount conversion
                final wallet = _ref.read(activeWalletProvider).valueOrNull;
                final walletCurrency = wallet?.currency ?? 'VND';

                // Convert amount if needed (AI returns VND by default)
                double amount = (action['amount'] as num).toDouble();
                final aiCurrency = action['currency'] ?? 'VND';

                Log.d('AI action amount: $amount $aiCurrency, Wallet currency: $walletCurrency', label: 'AI_CURRENCY');

                // Convert VND to USD if wallet uses USD
                if (aiCurrency == 'VND' && walletCurrency == 'USD') {
                  amount = amount / 25000; // Simple conversion rate
                  Log.d('Converted VND to USD: $amount', label: 'AI_CURRENCY');
                }

                // Update action with converted amount
                action['amount'] = amount;

                final description = action['description'];
                final category = action['category'];
                Log.d('Creating transaction: action=${action['action']}, amount=$amount $walletCurrency, desc=$description, cat=$category', label: 'Chat Provider');

                await _createTransactionFromAction(action);

                final isIncome = actionType == 'create_income';
                final amountText = _formatAmount(amount, currency: walletCurrency);
                final dateText = _formatDatePhrase(DateTime.now());
                final walletName = wallet?.name ?? 'Ví mặc định';

                // Show conversion info if currency was converted
                String conversionNote = '';
                if (aiCurrency == 'VND' && walletCurrency == 'USD') {
                  final vndAmount = (action['amount'] as num) * 25000;
                  conversionNote = ' (from ${_formatAmount(vndAmount, currency: 'VND')})';
                }

                final confirmText = isIncome
                    ? 'Recorded income of ' + amountText + conversionNote + ' to "' + walletName + '" for ' + (action['description']).toString() + ' (Category: ' + (action['category']).toString() + ') on ' + dateText + '.'
                    : 'Recorded expense of ' + amountText + conversionNote + ' from "' + walletName + '" for ' + (action['description']).toString() + ' (Category: ' + (action['category']).toString() + ') on ' + dateText + '.';
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
            default:
              {
                Log.d('Unknown action: $actionType', label: 'Chat Provider');
              }
          }
        } catch (e) {
          Log.e('Failed to parse AI action: $e', label: 'Chat Provider');
          // If JSON parsing fails, just show original response without JSON
        }
      } else {
        // Fallback: Try to infer action directly from user's message when model didn't include ACTION_JSON
        final inferred = await _inferActionFromText(userMessage.content);
        if (inferred != null) {
          try {
            await _createTransactionFromAction(inferred);
            final isIncome = inferred['action'] == 'create_income';
            final wallet = _ref.read(activeWalletProvider).valueOrNull;
            // Use wallet currency or default to VND
            final currency = wallet?.currency ?? 'VND';
            final walletName = wallet?.name ?? 'Ví mặc định';
            final amountText = _formatAmount(inferred['amount'] as num, currency: currency);
            final dateText = _formatDatePhrase(DateTime.now());

            // Show conversion info if amount was parsed from VND but wallet uses different currency
            String conversionNote = '';
            if (currency == 'USD' && !userMessage.content.toLowerCase().contains(RegExp(r'\$|usd|dollar'))) {
              // Likely VND amount converted to USD
              final originalVnd = (inferred['amount'] as num) * 25000;
              conversionNote = ' (from ${_formatAmount(originalVnd, currency: 'VND')})';
            }

            final confirmText = isIncome
                ? 'Recorded income of ' + amountText + conversionNote + ' to "' + walletName + '" for ' + (inferred['description']).toString() + ' (Category: ' + (inferred['category']).toString() + ') on ' + dateText + '.'
                : 'Recorded expense of ' + amountText + conversionNote + ' from "' + walletName + '" for ' + (inferred['description']).toString() + ' (Category: ' + (inferred['category']).toString() + ') on ' + dateText + '.';
            displayMessage += '\n\n✅ ' + confirmText;
          } catch (e) {
            Log.e('Fallback create transaction failed: $e', label: 'Chat Provider');
          }
        }
      }

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

      state = state.copyWith(
        isLoading: false,
        isTyping: false,
        error: error.toString(),
      );

      // Add error message to chat
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        content: 'Sorry, an error occurred. Please try again later.',
        isFromUser: false,
        timestamp: DateTime.now(),
        error: error.toString(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
      );
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

  void clearChat() {
    _cancelTypingEffect();
    state = const ChatState();
    _initializeChat();
  }

  Future<void> _createTransactionFromAction(Map<String, dynamic> action) async {
    try {
      // Print to console for debugging
      print('========================================');
      print('[TRANSACTION_DEBUG] _createTransactionFromAction START');
      print('[TRANSACTION_DEBUG] Action received: $action');

      Log.d('========================================', label: 'TRANSACTION_DEBUG');
      Log.d('_createTransactionFromAction START', label: 'TRANSACTION_DEBUG');
      Log.d('Action received: $action', label: 'TRANSACTION_DEBUG');

      // Get current wallet - IMPORTANT: Use read to get current value
      final walletState = _ref.read(activeWalletProvider);
      Log.d('Wallet state: $walletState', label: 'TRANSACTION_DEBUG');

      final wallet = walletState.valueOrNull;
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

      // Only invalidate transaction list, not wallet providers
      // Wallet balance is already updated via _adjustWalletBalanceAfterCreate
      _ref.invalidate(transactionListProvider);

      Log.d('Transaction list provider invalidated, UI should update', label: 'TRANSACTION_DEBUG');

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

    } catch (e, stackTrace) {
      Log.e('Failed to create budget: $e', label: 'BUDGET_ERROR');
      Log.e('Stack trace: $stackTrace', label: 'BUDGET_ERROR');
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
      if (wallet == null || wallet.id == null) return 'Chưa chọn ví hoạt động.';

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
      if (wallet == null || wallet.id == null) return 'Chưa chọn ví hoạt động.';

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
      // Special formatting for VND (Vietnamese Dong)
      if (currency == 'VND' || currency == 'đ') {
        return text + ' đ';
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