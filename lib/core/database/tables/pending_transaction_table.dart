import 'package:drift/drift.dart';

/// Source of the pending transaction
enum PendingTransactionSource {
  email,    // From email sync
  bank,     // From bank connection (Stripe)
  sms,      // From SMS parsing
  notification, // From notification parsing
}

/// Status of the pending transaction
enum PendingTransactionStatus {
  pendingReview,
  approved,
  rejected,
  imported,
}

/// Unified table for pending transactions from all sources.
/// Replaces multiple source-specific tables with a single unified table.
@DataClassName('PendingTransaction')
class PendingTransactions extends Table {
  /// Unique identifier (local ID)
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing
  TextColumn get cloudId => text().nullable().unique()();

  /// Source of this pending transaction
  TextColumn get source => text()(); // 'email', 'bank', 'sms', 'notification'

  /// Unique ID from source for deduplication
  /// - Email: Gmail message ID
  /// - Bank: Stripe transaction ID
  /// - SMS: Message hash
  /// - Notification: Notification hash
  TextColumn get sourceId => text()();

  /// Transaction amount (always positive)
  RealColumn get amount => real()();

  /// Currency code (VND, USD, etc.)
  TextColumn get currency => text().withDefault(const Constant('VND'))();

  /// Transaction type: 'income' or 'expense'
  TextColumn get transactionType => text()();

  /// Title/description of the transaction
  TextColumn get title => text()();

  /// Merchant or payee name (from source)
  TextColumn get merchant => text().nullable()();

  /// Date of the transaction
  DateTimeColumn get transactionDate => dateTime()();

  /// Confidence score (0-1) for auto-parsed transactions
  RealColumn get confidence => real().withDefault(const Constant(0.8))();

  /// Suggested category hint from parsing
  TextColumn get categoryHint => text().nullable()();

  /// Source display name (bank name, email sender, app name)
  TextColumn get sourceDisplayName => text()();

  /// Source icon URL (bank logo, app icon)
  TextColumn get sourceIconUrl => text().nullable()();

  /// Account identifier (last 4 digits, email address, etc.)
  TextColumn get accountIdentifier => text().nullable()();

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

  /// Raw source data as JSON (for debugging/reference)
  TextColumn get rawSourceData => text().nullable()();

  /// Created timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Updated timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {source, sourceId}, // Unique per source
  ];
}
