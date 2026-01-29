import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_api_service.dart';

/// Parsed transaction from email
class ParsedEmail {
  final String emailId;
  final String emailSubject;
  final String fromEmail;
  final double amount;
  final String currency;
  final String transactionType; // 'income' or 'expense'
  final String? merchant;
  final String? accountLast4;
  final double? balanceAfter;
  final DateTime transactionDate;
  final DateTime emailDate;
  final double confidence;
  final String rawAmountText;
  final String? categoryHint;
  final String bankName;

  const ParsedEmail({
    required this.emailId,
    required this.emailSubject,
    required this.fromEmail,
    required this.amount,
    required this.currency,
    required this.transactionType,
    this.merchant,
    this.accountLast4,
    this.balanceAfter,
    required this.transactionDate,
    required this.emailDate,
    required this.confidence,
    required this.rawAmountText,
    this.categoryHint,
    required this.bankName,
  });

  @override
  String toString() =>
      'ParsedEmail(amount: $amount $currency, type: $transactionType, merchant: $merchant, bank: $bankName)';
}

/// Service for parsing banking emails into transactions
class EmailParserService {
  static const _label = 'EmailParser';

  /// Parse a Gmail message into a transaction
  ParsedEmail? parseEmail(GmailMessage email) {
    final from = email.from.toLowerCase();

    // Try each bank parser
    for (final parser in _bankParsers) {
      if (parser.matches(from)) {
        try {
          final result = parser.parse(email);
          if (result != null) {
            Log.d('Parsed email from ${parser.bankName}: $result', label: _label);
            return result;
          }
        } catch (e) {
          Log.w('Error parsing ${parser.bankName} email: $e', label: _label);
        }
      }
    }

    // No parser matched
    Log.d('No parser matched for email from: $from', label: _label);
    return null;
  }

  /// List of bank-specific parsers
  static final List<BankEmailParser> _bankParsers = [
    VietcombankParser(),
    TechcombankParser(),
    MBBankParser(),
    BIDVParser(),
    VPBankParser(),
    ACBParser(),
    TPBankParser(),
    SacombankParser(),
    MomoParser(),
    ZaloPayParser(),
    GenericVNBankParser(), // Fallback for other VN banks
  ];
}

/// Base class for bank-specific email parsers
abstract class BankEmailParser {
  String get bankName;
  List<String> get domains;

  bool matches(String fromEmail) {
    return domains.any((domain) => fromEmail.contains(domain));
  }

  ParsedEmail? parse(GmailMessage email);

  /// Helper to extract amount from Vietnamese format
  /// Examples: "150,000 VND", "1.500.000 VND", "+500,000đ", "-200.000 đ"
  double? parseVNDAmount(String text) {
    // Pattern for VND amounts
    final patterns = [
      // "150,000 VND" or "150.000 VND"
      RegExp(r'([+-]?\s*[\d.,]+)\s*(?:VND|VNĐ|đ|d)', caseSensitive: false),
      // "So tien: 150,000"
      RegExp(r'(?:số tiền|so tien|amount)[:\s]*([+-]?\s*[\d.,]+)', caseSensitive: false),
      // "PS: +1,000,000"
      RegExp(r'(?:PS|GD)[:\s]*([+-]?\s*[\d.,]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!
            .replaceAll(' ', '')
            .replaceAll('.', '')
            .replaceAll(',', '');
        return double.tryParse(amountStr);
      }
    }

    return null;
  }

  /// Helper to detect transaction type from text
  String detectTransactionType(String text, double? amount) {
    final lowerText = text.toLowerCase();

    // Check for explicit indicators
    if (lowerText.contains('nhận') ||
        lowerText.contains('nhan') ||
        lowerText.contains('có') ||
        lowerText.contains('credit') ||
        lowerText.contains('nạp') ||
        lowerText.contains('deposit')) {
      return 'income';
    }

    if (lowerText.contains('chi') ||
        lowerText.contains('thanh toán') ||
        lowerText.contains('thanh toan') ||
        lowerText.contains('trừ') ||
        lowerText.contains('tru') ||
        lowerText.contains('debit') ||
        lowerText.contains('rút') ||
        lowerText.contains('rut') ||
        lowerText.contains('chuyển') ||
        lowerText.contains('chuyen')) {
      return 'expense';
    }

    // Check amount sign
    if (amount != null) {
      return amount > 0 ? 'income' : 'expense';
    }

    return 'expense'; // Default to expense
  }

  /// Helper to extract balance after transaction
  double? parseBalance(String text) {
    final patterns = [
      RegExp(r'(?:số dư|so du|balance|SD)[:\s]*([+-]?\s*[\d.,]+)', caseSensitive: false),
      RegExp(r'(?:còn lại|con lai)[:\s]*([+-]?\s*[\d.,]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!
            .replaceAll(' ', '')
            .replaceAll('.', '')
            .replaceAll(',', '');
        return double.tryParse(amountStr);
      }
    }

    return null;
  }

  /// Helper to extract account last 4 digits
  String? parseAccountLast4(String text) {
    // Pattern: "xxx1234", "****1234", "TK: 1234"
    final patterns = [
      RegExp(r'(?:TK|STK|Account)[:\s]*(?:\*+|x+)?(\d{4})', caseSensitive: false),
      RegExp(r'(?:\*{4}|x{4})(\d{4})'),
      RegExp(r'(?:tài khoản|tai khoan)[:\s]*\S*(\d{4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Helper to extract merchant/description
  String? parseMerchant(String text) {
    final patterns = [
      RegExp(r'(?:tại|tai|at|từ|tu|from|đến|den|to)[:\s]*([^\n\r.]+)', caseSensitive: false),
      RegExp(r'(?:ND|nội dung|noi dung|description)[:\s]*([^\n\r]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final merchant = match.group(1)?.trim();
        if (merchant != null && merchant.length > 2 && merchant.length < 100) {
          return merchant;
        }
      }
    }

    return null;
  }

  /// Helper to parse date from text
  DateTime? parseTransactionDate(String text) {
    final patterns = [
      // DD/MM/YYYY HH:mm:ss
      RegExp(r'(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2}):?(\d{2})?'),
      // DD-MM-YYYY HH:mm
      RegExp(r'(\d{2})-(\d{2})-(\d{4})\s+(\d{2}):(\d{2})'),
      // YYYY-MM-DD HH:mm:ss
      RegExp(r'(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):?(\d{2})?'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (pattern.pattern.startsWith(r'(\d{4})')) {
            // YYYY-MM-DD format
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
              int.parse(match.group(4)!),
              int.parse(match.group(5)!),
              int.tryParse(match.group(6) ?? '0') ?? 0,
            );
          } else {
            // DD/MM/YYYY or DD-MM-YYYY format
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(2)!),
              int.parse(match.group(1)!),
              int.parse(match.group(4)!),
              int.parse(match.group(5)!),
              int.tryParse(match.group(6) ?? '0') ?? 0,
            );
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// Helper to suggest category based on merchant
  String? suggestCategory(String? merchant, String type) {
    if (merchant == null) return null;

    final lowerMerchant = merchant.toLowerCase();

    // Food & Dining
    if (_matchesAny(lowerMerchant, ['highland', 'starbuck', 'coffee', 'cafe', 'cà phê',
        'grab food', 'shopee food', 'now.vn', 'baemin', 'gofood', 'nhà hàng', 'restaurant',
        'ăn', 'com', 'pho', 'bun', 'mi', 'banh', 'tra sua', 'bubble tea'])) {
      return 'Food & Dining';
    }

    // Transportation
    if (_matchesAny(lowerMerchant, ['grab', 'be', 'gojek', 'xăng', 'petrol', 'gas',
        'uber', 'taxi', 'xe', 'parking', 'đỗ xe'])) {
      return 'Transportation';
    }

    // Shopping
    if (_matchesAny(lowerMerchant, ['shopee', 'lazada', 'tiki', 'sendo', 'thegioididong',
        'fpt shop', 'cellphones', 'con cung', 'guardian', 'watsons', 'vinmart', 'coopmart',
        'bigc', 'lotte', 'aeon', 'circle k', 'ministop', 'bach hoa xanh'])) {
      return 'Shopping';
    }

    // Bills & Utilities
    if (_matchesAny(lowerMerchant, ['điện', 'dien', 'nước', 'nuoc', 'internet', 'wifi',
        'viettel', 'mobifone', 'vinaphone', 'fpt', 'vnpt', 'evn', 'điện lực'])) {
      return 'Bills & Utilities';
    }

    // Entertainment
    if (_matchesAny(lowerMerchant, ['cgv', 'lotte cinema', 'beta cinema', 'galaxy',
        'netflix', 'spotify', 'youtube', 'game', 'steam'])) {
      return 'Entertainment';
    }

    // Health
    if (_matchesAny(lowerMerchant, ['bệnh viện', 'hospital', 'pharmacity', 'long chau',
        'an khang', 'medicare', 'clinic', 'phòng khám', 'thuốc', 'pharmacy'])) {
      return 'Health';
    }

    // Education
    if (_matchesAny(lowerMerchant, ['school', 'trường', 'university', 'đại học', 'học phí',
        'course', 'khóa học', 'udemy', 'coursera'])) {
      return 'Education';
    }

    // Transfer
    if (_matchesAny(lowerMerchant, ['chuyển tiền', 'transfer', 'chuyển khoản'])) {
      return type == 'income' ? 'Transfer In' : 'Transfer Out';
    }

    return null;
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}

/// Vietcombank parser
class VietcombankParser extends BankEmailParser {
  @override
  String get bankName => 'Vietcombank';

  @override
  List<String> get domains => ['vietcombank.com.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: parseAccountLast4(content),
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.85,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// Techcombank parser
class TechcombankParser extends BankEmailParser {
  @override
  String get bankName => 'Techcombank';

  @override
  List<String> get domains => ['techcombank.com.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: parseAccountLast4(content),
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.85,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// MB Bank parser
class MBBankParser extends BankEmailParser {
  @override
  String get bankName => 'MB Bank';

  @override
  List<String> get domains => ['mbbank.com.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    // MB uses PS: +/- for amount
    final psPattern = RegExp(r'PS[:\s]*([+-][\d.,]+)', caseSensitive: false);
    final psMatch = psPattern.firstMatch(content);

    double? amount;
    if (psMatch != null) {
      final amountStr = psMatch.group(1)!
          .replaceAll('.', '')
          .replaceAll(',', '');
      amount = double.tryParse(amountStr);
    } else {
      amount = parseVNDAmount(content);
    }

    if (amount == null) return null;

    final type = amount > 0 ? 'income' : 'expense';
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: parseAccountLast4(content),
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.9,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// BIDV parser
class BIDVParser extends BankEmailParser {
  @override
  String get bankName => 'BIDV';

  @override
  List<String> get domains => ['bidv.com.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: parseAccountLast4(content),
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.85,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// VPBank parser
class VPBankParser extends BankEmailParser {
  @override
  String get bankName => 'VPBank';

  @override
  List<String> get domains => ['vpbank.com.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: parseAccountLast4(content),
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.85,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// ACB parser
class ACBParser extends BankEmailParser {
  @override
  String get bankName => 'ACB';

  @override
  List<String> get domains => ['acb.com.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: parseAccountLast4(content),
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.85,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// TPBank parser
class TPBankParser extends BankEmailParser {
  @override
  String get bankName => 'TPBank';

  @override
  List<String> get domains => ['tpb.vn', 'tpbank.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: parseAccountLast4(content),
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.85,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// Sacombank parser
class SacombankParser extends BankEmailParser {
  @override
  String get bankName => 'Sacombank';

  @override
  List<String> get domains => ['sacombank.com.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: parseAccountLast4(content),
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.85,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// MoMo e-wallet parser
class MomoParser extends BankEmailParser {
  @override
  String get bankName => 'MoMo';

  @override
  List<String> get domains => ['momo.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: null,
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.8,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// ZaloPay e-wallet parser
class ZaloPayParser extends BankEmailParser {
  @override
  String get bankName => 'ZaloPay';

  @override
  List<String> get domains => ['zalopay.vn'];

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: null,
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.8,
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankName,
    );
  }
}

/// Generic Vietnamese bank parser (fallback)
class GenericVNBankParser extends BankEmailParser {
  @override
  String get bankName => 'Unknown Bank';

  @override
  List<String> get domains => GmailApiService.vietnamBankDomains;

  @override
  ParsedEmail? parse(GmailMessage email) {
    final content = '${email.subject}\n${email.body}';

    final amount = parseVNDAmount(content);
    if (amount == null) return null;

    final type = detectTransactionType(content, amount);
    final absAmount = amount.abs();

    // Try to extract bank name from domain
    final bankNameFromDomain = _extractBankName(email.from);

    return ParsedEmail(
      emailId: email.id,
      emailSubject: email.subject,
      fromEmail: email.from,
      amount: absAmount,
      currency: 'VND',
      transactionType: type,
      merchant: parseMerchant(content),
      accountLast4: parseAccountLast4(content),
      balanceAfter: parseBalance(content),
      transactionDate: parseTransactionDate(content) ?? email.date,
      emailDate: email.date,
      confidence: 0.7, // Lower confidence for generic parser
      rawAmountText: '${amount.toStringAsFixed(0)} VND',
      categoryHint: suggestCategory(parseMerchant(content), type),
      bankName: bankNameFromDomain,
    );
  }

  String _extractBankName(String from) {
    // Extract domain from email
    final domainMatch = RegExp(r'@([^>]+)').firstMatch(from);
    if (domainMatch != null) {
      final domain = domainMatch.group(1)!.toLowerCase();

      // Known bank domains
      final bankNames = {
        'shb.com.vn': 'SHB',
        'eximbank.com.vn': 'Eximbank',
        'abbank.vn': 'ABBank',
        'pvcombank.com.vn': 'PVcomBank',
        'baovietbank.com.vn': 'BaoViet Bank',
        'kienlongbank.com.vn': 'KienLong Bank',
        'vietbank.com.vn': 'VietBank',
        'ncb-bank.vn': 'NCB',
        'gpbank.com.vn': 'GPBank',
        'oceanbank.vn': 'OceanBank',
        'saigonbank.com.vn': 'SaigonBank',
        'bvbank.net.vn': 'BVBank',
        'hdbank.com.vn': 'HDBank',
        'vib.com.vn': 'VIB',
        'msb.com.vn': 'MSB',
        'seabank.com.vn': 'SeABank',
        'lpbank.com.vn': 'LPBank',
        'namabank.com.vn': 'Nam A Bank',
        'ocb.com.vn': 'OCB',
      };

      for (final entry in bankNames.entries) {
        if (domain.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    return 'Unknown Bank';
  }
}
