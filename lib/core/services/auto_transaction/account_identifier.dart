import 'package:bexly/core/utils/logger.dart';

/// Utility class to extract account identifiers from bank messages
///
/// Account identifier is typically the last 4 digits of an account/card number.
/// This allows distinguishing between multiple accounts at the same bank:
/// - Checking account (****1234)
/// - Savings account (****5678)
/// - Credit card (****9012)
class AccountIdentifier {
  /// Extract account identifier from a message
  ///
  /// Returns the last 4 digits of the detected account/card number,
  /// or null if no identifier found.
  static String? extractFromMessage(String message) {
    if (message.isEmpty) return null;

    // Patterns to match account/card numbers
    // Priority: more specific patterns first
    final patterns = <RegExp>[
      // Vietnamese patterns
      // TK ****1234 or TK: ****1234 or TK *1234
      RegExp(r'TK[:\s]*\*+(\d{4})\b', caseSensitive: false),

      // TK: 1234567890 (full account, take last 4)
      RegExp(r'TK[:\s]*(\d{6,})\b', caseSensitive: false),

      // Số TK: ****1234
      RegExp(r'[Ss]ố\s*TK[:\s]*\*+(\d{4})\b'),

      // thẻ ****5678 or the ****5678
      RegExp(r'th[eẻ][:\s]*\*+(\d{4})\b', caseSensitive: false),

      // Thẻ TD (credit card) ****1234
      RegExp(r'th[eẻ]\s*TD[:\s]*\*+(\d{4})\b', caseSensitive: false),

      // Thẻ ATM ****1234
      RegExp(r'th[eẻ]\s*ATM[:\s]*\*+(\d{4})\b', caseSensitive: false),

      // STK: 1234 or STK ****1234
      RegExp(r'STK[:\s]*\*?(\d{4})\b', caseSensitive: false),

      // English patterns
      // Account ****1234 or Acct ****1234
      RegExp(r'Acc(?:ount|t)?[:\s]*\*+(\d{4})\b', caseSensitive: false),

      // Card ****5678
      RegExp(r'[Cc]ard[:\s]*\*+(\d{4})\b'),

      // Credit card ending 1234
      RegExp(r'ending\s+(?:in\s+)?(\d{4})\b', caseSensitive: false),

      // A/C or a/c followed by number
      RegExp(r'[Aa]/[Cc][:\s]*\*?(\d{4})\b'),

      // Generic patterns (lower priority)
      // xxxx1234 or XX1234 or ****1234 standalone
      RegExp(r'[xX*]{2,}(\d{4})\b'),

      // ...1234 format (some banks use dots)
      RegExp(r'\.{2,}(\d{4})\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        String digits = match.group(1)!;

        // If we matched a full account number (6+ digits), take last 4
        if (digits.length > 4) {
          digits = digits.substring(digits.length - 4);
        }

        Log.d(
          'Extracted account ID: $digits from pattern: ${pattern.pattern}',
          label: 'AccountIdentifier',
        );
        return digits;
      }
    }

    return null;
  }

  /// Detect the type of account from the message
  ///
  /// Returns one of: 'credit', 'debit', 'savings', 'checking', or null
  static String? detectAccountType(String message) {
    final messageLower = message.toLowerCase();

    // Credit card indicators
    if (messageLower.contains('thẻ td') ||
        messageLower.contains('credit') ||
        messageLower.contains('tín dụng') ||
        messageLower.contains('creditcard') ||
        messageLower.contains('visa') ||
        messageLower.contains('mastercard') ||
        messageLower.contains('jcb') ||
        messageLower.contains('amex')) {
      return 'credit';
    }

    // Debit card indicators
    if (messageLower.contains('thẻ atm') ||
        messageLower.contains('debit') ||
        messageLower.contains('ghi nợ') ||
        messageLower.contains('atm card')) {
      return 'debit';
    }

    // Savings account indicators
    if (messageLower.contains('tiết kiệm') ||
        messageLower.contains('savings') ||
        messageLower.contains('tkk') ||
        messageLower.contains('tk tiết kiệm')) {
      return 'savings';
    }

    // Checking/Current account indicators
    if (messageLower.contains('thanh toán') ||
        messageLower.contains('checking') ||
        messageLower.contains('current') ||
        messageLower.contains('tktg') ||
        messageLower.contains('tk thanh toán')) {
      return 'checking';
    }

    return null;
  }

  /// Generate a display name for the account
  ///
  /// Example: "Vietcombank ****1234" or "Vietcombank Credit ****1234"
  static String generateDisplayName(
    String bankName,
    String? accountId,
    String? accountType,
  ) {
    final buffer = StringBuffer(bankName);

    if (accountType != null) {
      final typeDisplay = _getAccountTypeDisplay(accountType);
      if (typeDisplay != null) {
        buffer.write(' $typeDisplay');
      }
    }

    if (accountId != null) {
      buffer.write(' ****$accountId');
    }

    return buffer.toString();
  }

  static String? _getAccountTypeDisplay(String accountType) {
    switch (accountType) {
      case 'credit':
        return 'Credit';
      case 'debit':
        return 'Debit';
      case 'savings':
        return 'Savings';
      case 'checking':
        return 'Checking';
      default:
        return null;
    }
  }

  /// Check if two messages refer to the same account
  static bool isSameAccount(String message1, String message2) {
    final id1 = extractFromMessage(message1);
    final id2 = extractFromMessage(message2);

    // If both have identifiers, compare them
    if (id1 != null && id2 != null) {
      return id1 == id2;
    }

    // If neither has identifier, assume same (legacy behavior)
    if (id1 == null && id2 == null) {
      return true;
    }

    // One has identifier, one doesn't - can't determine
    return false;
  }
}
