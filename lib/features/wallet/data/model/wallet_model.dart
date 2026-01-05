import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/data/sources/currency_local_source.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart'; // For currency formatting in the extension
import 'package:bexly/features/wallet/data/model/wallet_type.dart';

part 'wallet_model.freezed.dart';
part 'wallet_model.g.dart';

/// Represents a user's wallet or financial account.
@freezed
abstract class WalletModel with _$WalletModel {
  const factory WalletModel({
    /// The unique identifier for the wallet.
    int? id,

    /// Cloud ID (UUID v7) for syncing with Firestore
    String? cloudId,

    /// The name of the wallet (e.g., "Primary Checking", "Savings").
    @Default('My Wallet') String name,

    /// The current balance of the wallet.
    @Default(0.0) double balance,

    /// Initial balance when wallet was created (for tracking purposes)
    /// This value should never change after wallet creation
    @Default(0.0) double initialBalance,

    /// The currency code for the wallet's balance (e.g., "USD", "EUR", "NGN").
    @Default('IDR') String currency,

    /// Optional: The identifier or name of the icon associated with this wallet.
    String? iconName,

    /// Optional: The color associated with this wallet, stored as a hex string or int.
    String? colorHex, // Or int colorValue

    /// The type of wallet (cash, bank_account, credit_card, etc.)
    @Default(WalletType.cash) WalletType walletType,

    /// Credit limit for credit cards
    double? creditLimit,

    /// Billing day of month (1-31) for credit cards
    int? billingDay,

    /// Annual interest rate in percentage for credit cards/loans
    double? interestRate,

    /// Firebase UID of the wallet owner (for family sharing)
    String? ownerUserId,

    /// Whether this wallet is currently shared with a family group
    @Default(false) bool isShared,

    /// Timestamp when wallet was created
    DateTime? createdAt,

    /// Timestamp when wallet was last updated
    DateTime? updatedAt,
  }) = _WalletModel;

  /// Creates a `WalletModel` instance from a JSON map.
  factory WalletModel.fromJson(Map<String, dynamic> json) =>
      _$WalletModelFromJson(json);
}

/// Utility extensions for the [WalletModel].
extension WalletModelUtils on WalletModel {
  String get formattedBalance {
    return '$currency ${balance.toPriceFormat()}';
  }

  Currency currencyByIsoCode(WidgetRef ref) {
    final currencies = ref.read(currenciesStaticProvider);
    print('DEBUG currencyByIsoCode - Looking for: $currency in ${currencies.length} currencies');
    final found = currencies.fromIsoCode(currency);
    print('DEBUG currencyByIsoCode - Found: ${found?.isoCode ?? "null, using dummy"}');
    return found ?? CurrencyLocalDataSource.dummy;
  }
}
