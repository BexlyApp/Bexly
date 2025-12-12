import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/bottom_sheets/alert_bottom_sheet.dart';
import 'package:bexly/core/components/dialogs/toast.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/tables/category_table.dart'; // For Category.toModel() extension
import 'package:bexly/core/extensions/date_time_extension.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/extensions/string_extension.dart';
import 'package:bexly/core/services/image_service/riverpod/image_notifier.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/core/services/receipt_storage/receipt_storage_service_provider.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';
import 'package:bexly/core/services/transaction_sync/transaction_sync_service_provider.dart';

class TransactionFormState {
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController notesController;
  final TextEditingController categoryController;
  final TextEditingController walletController;
  final TextEditingController dateFieldController;
  final ValueNotifier<TransactionType> selectedTransactionType;
  final ValueNotifier<CategoryModel?> selectedCategory;
  final ValueNotifier<WalletModel?> selectedWallet;
  final String defaultCurrency;
  final bool isEditing;
  final TransactionModel? initialTransaction;

  TransactionFormState({
    required this.titleController,
    required this.amountController,
    required this.notesController,
    required this.categoryController,
    required this.walletController,
    required this.selectedTransactionType,
    required this.selectedCategory,
    required this.selectedWallet,
    required this.dateFieldController,
    required this.defaultCurrency,
    required this.isEditing,
    this.initialTransaction,
  });

  String getCategoryText({CategoryModel? parentCategory}) {
    final category = selectedCategory.value;
    if (category == null) return '';

    if (parentCategory != null) {
      // It's a subcategory, find its parent to display "Parent • Sub"
      return '${parentCategory.title} • ${category.title}';
    } else {
      // It's a parent category
      return category.title;
    }
  }

  String getWalletText() {
    final wallet = selectedWallet.value;
    if (wallet == null) return '';
    return '${wallet.name} (${wallet.currency})';
  }

  Future<void> saveTransaction(WidgetRef ref, BuildContext context) async {
    Log.d('💾 === SAVE TRANSACTION START ===', label: 'TransactionForm');
    Log.d('💾 Title: "${titleController.text}"', label: 'TransactionForm');
    Log.d('💾 Amount: "${amountController.text}"', label: 'TransactionForm');
    Log.d('💾 Category: ${selectedCategory.value?.title ?? "null"}', label: 'TransactionForm');
    Log.d('💾 Wallet: ${selectedWallet.value?.name ?? "null"}', label: 'TransactionForm');

    if (titleController.text.isEmpty ||
        amountController.text.isEmpty ||
        selectedCategory.value == null ||
        selectedWallet.value == null) {
      Log.e('❌ Validation failed: missing required fields', label: 'TransactionForm');
      Toast.show(
        'Please fill all required fields.',
        type: ToastificationType.error,
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final imagePickerState = ref.read(imageProvider);
    final wallet = selectedWallet.value!;

    Log.d('💾 Wallet ID: ${wallet.id}', label: 'TransactionForm');

    if (wallet.id == null) {
      Log.e('❌ Wallet ID is null', label: 'TransactionForm');
      Toast.show(
        'Invalid wallet selected.',
        type: ToastificationType.warning,
      );
      return;
    }

    String imagePath = '';
    Log.d('💾 Image savedPath: ${imagePickerState.savedPath}', label: 'TransactionForm');
    // Check if image exists (skip File check on web)
    if (imagePickerState.savedPath != null && imagePickerState.savedPath!.isNotEmpty) {
      if (kIsWeb) {
        // On web, trust that the path exists if it's not empty
        imagePath = imagePickerState.savedPath!;
        Log.d('💾 Web image path set: $imagePath', label: 'TransactionForm');
      } else {
        // On native platforms, check if file exists
        final fileExists = await File(imagePickerState.savedPath!).exists();
        Log.d('💾 Image file exists: $fileExists', label: 'TransactionForm');
        if (fileExists) {
          imagePath = imagePickerState.savedPath!;
          Log.d('💾 Image path set: $imagePath', label: 'TransactionForm');
        }
      }
    }

    // --- FIX: Use the correct date ---
    DateTime dateToSave = DateTime.now();
    if (dateFieldController.text.isNotEmpty) {
      dateToSave = dateFieldController.text
          .toDateTimeFromDayMonthYearTime12Hour();
    }

    final transactionToSave = TransactionModel(
      id: isEditing ? initialTransaction?.id : null,
      transactionType: selectedTransactionType.value,
      amount: amountController.text.takeNumericAsDouble(),
      date: dateToSave,
      title: titleController.text,
      category: selectedCategory.value!,
      wallet: wallet,
      notes: notesController.text.isNotEmpty ? notesController.text : null,
      imagePath: imagePath,
      isRecurring: false,
    );

    Log.d(
      transactionToSave.toJson(),
      label: isEditing ? 'Updating transaction' : 'Saving new transaction',
    );

    try {
      Log.d('💾 Entering try block', label: 'TransactionForm');
      int? savedTransactionId;
      if (!isEditing) {
        Log.d('💾 Adding new transaction to database...', label: 'TransactionForm');
        savedTransactionId = await db.transactionDao.addTransaction(
          transactionToSave,
        );
        Log.d('💾 Transaction saved with ID: $savedTransactionId', label: 'TransactionForm');

        if (savedTransactionId > 0) {
          Log.d('💾 Adjusting wallet balance...', label: 'TransactionForm');
          await _adjustWalletBalance(ref, null, transactionToSave);
          Log.d('💾 Wallet balance adjusted', label: 'TransactionForm');
        }
      } else {
        // This is the update case
        // For updates, the ID is already in transactionToSave.id
        if (transactionToSave.id == null) {
          Log.e('Error: Attempting to update transaction without an ID.');
          toastification.show(
            description: Text('Error updating transaction: Missing ID.'),
          );
          return;
        }
        await db.transactionDao.updateTransaction(transactionToSave);
        savedTransactionId = transactionToSave.id;
        await _adjustWalletBalance(ref, initialTransaction, transactionToSave);
      }

      // Upload receipt to Firebase Storage if there is a local image
      final user = ref.read(authStateProvider);
      final String? userId = user.id?.toString();
      String? receiptUrl;
      String? receiptStoragePath;
      if (userId != null && imagePath.isNotEmpty && !kIsWeb) {
        // Skip Firebase Storage upload on web for now
        try {
          final receiptStorage = ref.read(receiptStorageServiceProvider);
          final result = await receiptStorage.uploadReceipt(
            file: File(imagePath),
            userId: userId,
            date: transactionToSave.date,
          );
          receiptUrl = result.downloadUrl;
          receiptStoragePath = result.storagePath;
          Log.i(
            {
              'storagePath': receiptStoragePath,
              'downloadUrl': receiptUrl,
            },
            label: 'receipt uploaded',
          );
        } catch (e) {
          Log.e('Receipt upload failed: $e', label: 'storage');
        }
      }

      // Sync to Firestore only for logged-in premium users
      if (userId != null && user.isPremium == true && savedTransactionId != null) {
        try {
          final syncService = ref.read(transactionSyncServiceProvider);
          await syncService.upsertTransaction(
            userId: userId,
            transactionId: savedTransactionId,
            transaction: transactionToSave.copyWith(id: savedTransactionId),
            receiptUrl: receiptUrl,
            receiptStoragePath: receiptStoragePath,
            isCreate: !isEditing,
          );
        } catch (e) {
          Log.e('Firestore sync failed: $e', label: 'firestore');
        }
      }

      Log.d('💾 Transaction save completed successfully', label: 'TransactionForm');
      if (context.mounted) {
        Log.d('💾 Popping context', label: 'TransactionForm');
        context.pop();
        Log.d('💾 Context popped', label: 'TransactionForm');
      }
    } catch (e, stackTrace) {
      Log.e('❌ Error saving transaction: $e', label: 'TransactionForm');
      Log.e('❌ Stack trace: $stackTrace', label: 'TransactionForm');
      if (context.mounted) {
        Toast.show(
          'Failed to save transaction: $e',
          type: ToastificationType.error,
        );
      }
    }
    Log.d('💾 === SAVE TRANSACTION END ===', label: 'TransactionForm');
  }

  Future<void> deleteTransaction(WidgetRef ref, BuildContext context) async {
    // Skip if not editing just in case
    if (!isEditing) return;

    context.openBottomSheet(
      child: AlertBottomSheet(
        context: context,
        title: 'Delete Transaction',
        content: Text(
          'Continue to delete this transaction?',
          style: AppTextStyles.body2,
        ),
        onConfirm: () async {
          if (context.mounted) {
            context.pop(); // close dialog
            context.pop(); // close form
          }

          await _adjustWalletBalance(
            ref,
            initialTransaction!,
            null,
          ); // Pass null for newTransaction to indicate deletion

          final db = ref.read(databaseProvider);
          final id = await db.transactionDao.deleteTransaction(
            initialTransaction!.id!,
          );

          Log.d(id, label: 'deleted transaction id');
        },
      ),
    );
  }

  // This function will handle all balance adjustments: add, update, delete
  Future<void> _adjustWalletBalance(
    WidgetRef ref,
    TransactionModel?
    oldTransaction, // The original transaction (null for new additions)
    TransactionModel?
    newTransaction, // The new transaction (null for deletions)
  ) async {
    final db = ref.read(databaseProvider);

    // Determine which wallet to adjust
    // Priority: newTransaction.wallet > oldTransaction.wallet
    WalletModel? targetWallet = newTransaction?.wallet ?? oldTransaction?.wallet;

    if (targetWallet == null || targetWallet.id == null) {
      Log.i(
        'No wallet found to adjust balance.',
        label: 'wallet adjustment',
      );
      return;
    }

    double balanceChange = 0.0;

    // 1. Reverse the effect of the old transaction (if it exists)
    if (oldTransaction != null) {
      if (oldTransaction.transactionType == TransactionType.income) {
        balanceChange -= oldTransaction.amount;
      } else if (oldTransaction.transactionType == TransactionType.expense) {
        balanceChange += oldTransaction.amount;
      }
      // Transfers are ignored for single wallet balance adjustment
    }

    // 2. Apply the effect of the new transaction (if it exists)
    if (newTransaction != null) {
      if (newTransaction.transactionType == TransactionType.income) {
        balanceChange += newTransaction.amount;
      } else if (newTransaction.transactionType == TransactionType.expense) {
        balanceChange -= newTransaction.amount;
      }
      // Transfers are ignored
    }

    double newWalletBalance = targetWallet.balance + balanceChange;

    final updatedWallet = targetWallet.copyWith(balance: newWalletBalance);
    await db.walletDao.updateWallet(updatedWallet);

    // Update activeWallet provider if the adjusted wallet is the active one
    final activeWallet = ref.read(activeWalletProvider).value;
    if (activeWallet?.id == targetWallet.id) {
      ref.read(activeWalletProvider.notifier).setActiveWallet(updatedWallet);
    }

    Log.d(
      'Wallet balance updated for ${targetWallet.name}. Old balance: ${targetWallet.balance}, Change: $balanceChange, New balance: $newWalletBalance',
      label: 'wallet adjustment',
    );
  }

  void dispose() {
    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
    categoryController.dispose();
    selectedTransactionType.dispose();
    selectedCategory.dispose();
  }
}

TransactionFormState useTransactionFormState({
  required WidgetRef ref,
  required String defaultCurrency,
  required bool isEditing,
  TransactionModel? transaction,
  ReceiptScanResult? receiptData,
}) {
  final titleController = useTextEditingController(
    text: isEditing
        ? transaction?.title
        : receiptData?.merchant ?? '',
  );
  final amountController = useTextEditingController(
    text: isEditing && transaction != null
        ? '$defaultCurrency ${transaction.amount.toPriceFormat()}'
        : receiptData != null
            ? '${receiptData.currency ?? defaultCurrency} ${receiptData.amount.toPriceFormat()}'
            : '',
  );
  final notesController = useTextEditingController(
    text: isEditing
        ? transaction?.notes ?? ''
        : receiptData != null && receiptData.items.isNotEmpty
            ? receiptData.items.join(', ')
            : '',
  );
  final categoryController = useTextEditingController();
  final walletController = useTextEditingController();
  final dateFieldController = useTextEditingController();

  final selectedTransactionType = useState<TransactionType>(
    isEditing && transaction != null
        ? transaction.transactionType
        : TransactionType.expense,
  );
  final selectedCategory = useState<CategoryModel?>(
    isEditing ? transaction?.category : null,
  );

  // For new transactions, default to active wallet
  final activeWallet = ref.watch(activeWalletProvider).value;
  final selectedWallet = useState<WalletModel?>(
    isEditing ? transaction?.wallet : activeWallet,
  );

  final formState = useMemoized(
    () => TransactionFormState(
      titleController: titleController,
      amountController: amountController,
      notesController: notesController,
      categoryController: categoryController,
      walletController: walletController,
      selectedTransactionType: selectedTransactionType,
      selectedCategory: selectedCategory,
      selectedWallet: selectedWallet,
      dateFieldController: dateFieldController,
      defaultCurrency: defaultCurrency,
      isEditing: isEditing,
      initialTransaction: transaction,
    ),
    [defaultCurrency, isEditing, transaction],
  );

  useEffect(
    () {
      void initializeForm() {
        if (isEditing && transaction != null) {
          // Controllers are initialized with text in their declaration if transaction is available.
          // If transaction was initially null (e.g., during loading) and then becomes available,
          // we need to update them here.
          if (titleController.text != transaction.title) {
            titleController.text = transaction.title;
          }
          if (amountController.text !=
              '$defaultCurrency ${transaction.amount.toPriceFormat()}') {
            amountController.text =
                '$defaultCurrency ${transaction.amount.toPriceFormat()}';
          }
          if (notesController.text != (transaction.notes ?? '')) {
            notesController.text = transaction.notes ?? '';
          }
          if (selectedTransactionType.value != transaction.transactionType) {
            selectedTransactionType.value = transaction.transactionType;
          }
          if (selectedCategory.value != transaction.category) {
            selectedCategory.value = transaction.category;
          }
          if (selectedWallet.value != transaction.wallet) {
            selectedWallet.value = transaction.wallet;
          }
          // categoryController.text and walletController.text are handled by other useEffects

          dateFieldController.text = transaction.date.toRelativeDayFormatted(
            showTime: true,
          );

          final imagePath = transaction.imagePath;
          if (imagePath != null && imagePath.isNotEmpty) {
            Future.microtask(
              () => ref.read(imageProvider.notifier).loadImagePath(imagePath),
            );
          } else {
            Future.microtask(
              () => ref.read(imageProvider.notifier).clearImage(),
            );
          }
        } else if (!isEditing) {
          // Only reset for new, not if transaction is just null during edit loading
          titleController.clear();
          amountController.clear();
          notesController.clear();
          selectedTransactionType.value = TransactionType.expense;
          selectedCategory.value = null;
          selectedWallet.value = activeWallet;
          // Clear image for new transaction form
          Future.microtask(() => ref.read(imageProvider.notifier).clearImage());
        }
        // categoryController and walletController text are updated by separate effects below
      }

      initializeForm();
      // No need to return formState.dispose here if we want the hook's lifecycle
      // to be tied to the widget using it. The controllers are disposed by useTextEditingController.
      // ValueNotifiers from useState are also handled.
      // If formState.dispose did more, we'd return it.
      return null;
    },
    [
      isEditing,
      transaction,
      defaultCurrency,
      ref,
      titleController,
      amountController,
      notesController,
      selectedTransactionType,
      selectedCategory,
    ],
  );

  // Handle receipt data population
  useEffect(
    () {
      if (receiptData != null && !isEditing) {
        Future.microtask(() async {
          // Populate title from merchant
          titleController.text = receiptData.merchant;

          // Populate amount with currency prefix for UI display
          final currency = receiptData.currency ?? 'VND';
          amountController.text = '$currency ${receiptData.amount.toPriceFormat()}';

          // Populate notes from items
          if (receiptData.items.isNotEmpty) {
            notesController.text = receiptData.items.join(', ');
          }

          // Use receipt date with fallback to current date, include time component
          try {
            final receiptDate = DateTime.parse(receiptData.date);
            dateFieldController.text = receiptDate.toRelativeDayFormatted(showTime: true);
          } catch (e) {
            // Fallback to current date if receipt date cannot be parsed
            dateFieldController.text = DateTime.now().toRelativeDayFormatted(showTime: true);
          }

          // Auto-select wallet matching receipt currency
          if (receiptData.currency != null) {
            final db = ref.read(databaseProvider);
            final wallets = await db.walletDao.watchAllWallets().first;

            // Find wallet with matching currency
            WalletModel? matchingWallet;
            try {
              matchingWallet = wallets.firstWhere(
                (w) => w.currency.toUpperCase() == receiptData.currency!.toUpperCase(),
              );
            } catch (e) {
              // No matching wallet found, use first available
              matchingWallet = wallets.firstOrNull;
            }

            if (matchingWallet != null && matchingWallet.id != null) {
              selectedWallet.value = matchingWallet;
            }
          }

          // Auto-select category from receipt category text
          // Map receipt category to DB category
          final categoryMapping = {
            'Food & Dining': ['Food', 'Dining', 'Restaurant', 'Ăn uống'],
            'Transportation': ['Transport', 'Travel', 'Di chuyển'],
            'Shopping': ['Shopping', 'Mua sắm'],
            'Entertainment': ['Entertainment', 'Giải trí'],
            'Healthcare': ['Health', 'Medical', 'Y tế'],
            'Utilities': ['Utilities', 'Bills', 'Hóa đơn'],
          };

          // Get all categories from DB
          final db = ref.read(databaseProvider);
          final allCategories = await db.categoryDao.watchAllCategories().first;

          CategoryModel? matchedCategory;
          for (final entry in categoryMapping.entries) {
            if (receiptData.category.contains(entry.key)) {
              // Try to find matching category in DB
              for (final dbCat in allCategories) {
                for (final keyword in entry.value) {
                  if (dbCat.title.toLowerCase().contains(keyword.toLowerCase()) ||
                      keyword.toLowerCase().contains(dbCat.title.toLowerCase())) {
                    matchedCategory = dbCat.toModel();
                    break;
                  }
                }
                if (matchedCategory != null) break;
              }
            }
            if (matchedCategory != null) break;
          }

          // Only set category if there's a match, don't auto-fill if no match
          if (matchedCategory != null) {
            selectedCategory.value = matchedCategory;
          }

          // Set receipt image if available
          if (receiptData.imageBytes != null) {
            final imageNotifier = ref.read(imageProvider.notifier);
            await imageNotifier.setImageFromBytes(receiptData.imageBytes!);
            // Save image to persistent storage so it can be used when saving transaction
            await imageNotifier.saveImage();
          }
        });
      }
      return null;
    },
    [receiptData],
  );

  useEffect(
    () {
      Future.microtask(() {
        selectedCategory.value?.getParentCategory(ref).then((parentCategory) {
          categoryController.text = formState.getCategoryText(
            parentCategory: parentCategory,
          );
        });
      });
      return null;
    },
    [selectedCategory.value, formState],
  ); // formState is stable due to useMemoized

  // Update walletController text when selectedWallet changes
  useEffect(
    () {
      walletController.text = formState.getWalletText();
      return null;
    },
    [selectedWallet.value, formState],
  );

  // The main dispose for controllers created by useTextEditingController
  // and ValueNotifiers from useState is handled automatically by flutter_hooks.
  // The custom `formState.dispose()` might be redundant if it only disposes these.
  // If it has other specific cleanup, it should be called.
  // For now, assuming standard hook cleanup is sufficient.

  return formState;
}
