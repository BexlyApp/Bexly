import 'package:drift/drift.dart';

/// Represents parsed transactions from banking emails.
/// These are pending review before being imported to the main transactions table.
@DataClassName('ParsedEmailTransaction')
class ParsedEmailTransactions extends Table {
  /// Unique identifier (local ID)
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing
  TextColumn get cloudId => text().nullable().unique()();

  /// Gmail message ID (for deduplication)
  TextColumn get emailId => text()();

  /// Email subject
  TextColumn get emailSubject => text()();

  /// Sender email address
  TextColumn get fromEmail => text()();

  /// Transaction amount (always positive)
  RealColumn get amount => real()();

  /// Currency code (VND, USD, etc.)
  TextColumn get currency => text().withDefault(const Constant('VND'))();

  /// Transaction type: 'income' or 'expense'
  TextColumn get transactionType => text()();

  /// Merchant or payee name
  TextColumn get merchant => text().nullable()();

  /// Last 4 digits of account number
  TextColumn get accountLast4 => text().nullable()();

  /// Balance after transaction
  RealColumn get balanceAfter => real().nullable()();

  /// Date of the transaction
  DateTimeColumn get transactionDate => dateTime()();

  /// Date the email was received
  DateTimeColumn get emailDate => dateTime()();

  /// Confidence score (0-1)
  RealColumn get confidence => real().withDefault(const Constant(0.8))();

  /// Raw amount text from email
  TextColumn get rawAmountText => text()();

  /// Suggested category
  TextColumn get categoryHint => text().nullable()();

  /// Bank or e-wallet name
  TextColumn get bankName => text()();

  /// Status: 'pending_review', 'approved', 'rejected', 'imported'
  TextColumn get status => text().withDefault(const Constant('pending_review'))();

  /// ID of the imported transaction (if imported)
  IntColumn get importedTransactionId => integer().nullable()();

  /// User's wallet ID to import to
  IntColumn get targetWalletId => integer().nullable()();

  /// User's selected category ID
  IntColumn get selectedCategoryId => integer().nullable()();

  /// User's notes/edits
  TextColumn get userNotes => text().nullable()();

  /// Created timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Updated timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
