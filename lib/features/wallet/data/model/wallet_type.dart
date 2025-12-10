/// Wallet type enumeration
///
/// Represents different types of financial accounts/wallets
/// that users can create to manage their money.
enum WalletType {
  /// Physical cash wallet
  cash,

  /// Traditional bank account (checking/savings)
  bankAccount,

  /// Credit card with credit limit and billing cycle
  creditCard,

  /// Digital wallet (PayPal, Venmo, Apple Pay, etc.)
  eWallet,

  /// Investment account (stocks, bonds, crypto)
  investment,

  /// Dedicated savings account or goal
  savings,

  /// Insurance policy account
  insurance,

  /// Other types not covered above
  other;

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case WalletType.cash:
        return 'Cash';
      case WalletType.bankAccount:
        return 'Bank Account';
      case WalletType.creditCard:
        return 'Credit Card';
      case WalletType.eWallet:
        return 'E-Wallet';
      case WalletType.investment:
        return 'Investment';
      case WalletType.savings:
        return 'Savings';
      case WalletType.insurance:
        return 'Insurance';
      case WalletType.other:
        return 'Other';
    }
  }

  /// Get icon name for UI
  String get iconName {
    switch (this) {
      case WalletType.cash:
        return 'cash';
      case WalletType.bankAccount:
        return 'bank';
      case WalletType.creditCard:
        return 'credit_card';
      case WalletType.eWallet:
        return 'phone_iphone';
      case WalletType.investment:
        return 'trending_up';
      case WalletType.savings:
        return 'savings';
      case WalletType.insurance:
        return 'security';
      case WalletType.other:
        return 'account_balance_wallet';
    }
  }

  /// Get description for UI
  String get description {
    switch (this) {
      case WalletType.cash:
        return 'Physical cash in hand or at home';
      case WalletType.bankAccount:
        return 'Checking or savings account at a bank';
      case WalletType.creditCard:
        return 'Credit card with limit and billing cycle';
      case WalletType.eWallet:
        return 'Digital wallet like PayPal, Venmo, or Apple Pay';
      case WalletType.investment:
        return 'Investment account for stocks, bonds, or crypto';
      case WalletType.savings:
        return 'Dedicated savings for specific goals';
      case WalletType.insurance:
        return 'Insurance policy account';
      case WalletType.other:
        return 'Other types of financial accounts';
    }
  }

  /// Check if this wallet type supports credit features
  bool get supportsCreditFeatures {
    return this == WalletType.creditCard;
  }

  /// Convert from string value (for database storage)
  static WalletType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cash':
        return WalletType.cash;
      case 'bankaccount':
      case 'bank_account':
        return WalletType.bankAccount;
      case 'creditcard':
      case 'credit_card':
        return WalletType.creditCard;
      case 'ewallet':
      case 'e_wallet':
        return WalletType.eWallet;
      case 'investment':
        return WalletType.investment;
      case 'savings':
        return WalletType.savings;
      case 'insurance':
        return WalletType.insurance;
      case 'other':
      default:
        return WalletType.other;
    }
  }

  /// Convert to string value (for database storage)
  String toDbString() {
    switch (this) {
      case WalletType.cash:
        return 'cash';
      case WalletType.bankAccount:
        return 'bank_account';
      case WalletType.creditCard:
        return 'credit_card';
      case WalletType.eWallet:
        return 'e_wallet';
      case WalletType.investment:
        return 'investment';
      case WalletType.savings:
        return 'savings';
      case WalletType.insurance:
        return 'insurance';
      case WalletType.other:
        return 'other';
    }
  }

  /// Get HugeIcon constant for UI display
  /// This is deprecated in hugeicons 1.x - icons are now List<List> instead of int codepoints
  @Deprecated('Use _getWalletIcon helper function instead')
  int get hugeIcon {
    switch (this) {
      case WalletType.cash:
        return 0xeb93; // HugeIcons.strokeRoundedMoney02
      case WalletType.bankAccount:
        return 0xe0bb; // HugeIcons.strokeRoundedBankAccount
      case WalletType.creditCard:
        return 0xe5f4; // HugeIcons.strokeRoundedCreditCard
      case WalletType.eWallet:
        return 0xeb96; // HugeIcons.strokeRoundedMoney04
      case WalletType.investment:
        return 0xf7f9; // HugeIcons.strokeRoundedStockMarket
      case WalletType.savings:
        return 0xebc1; // HugeIcons.strokeRoundedPiggyBank
      case WalletType.insurance:
        return 0xf306; // HugeIcons.strokeRoundedSecurityCheck
      case WalletType.other:
        return 0xf9d0; // HugeIcons.strokeRoundedWallet03
    }
  }
}
