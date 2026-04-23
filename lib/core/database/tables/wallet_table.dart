import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';

@DataClassName('Wallet')
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  /// Null for offline-only data, generated when first synced
  TextColumn get cloudId => text().nullable().unique()();

  TextColumn get name => text().withDefault(const Constant('My Wallet')).unique()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();

  /// Initial balance when wallet was created (for tracking purposes)
  /// This value should never change after wallet creation
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();

  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();

  /// Wallet type (cash, bank_account, credit_card, etc.)
  TextColumn get walletType =>
      text().withDefault(const Constant('cash'))();

  /// Credit limit (for credit cards only)
  RealColumn get creditLimit => real().nullable()();

  /// Billing day of month (1-31, for credit cards only)
  IntColumn get billingDay => integer().nullable()();

  /// Annual interest rate in percentage (for credit cards/loans)
  RealColumn get interestRate => real().nullable()();

  /// Firebase UID of the wallet owner (for family sharing - tracks original owner)
  /// Null for wallets created before family sharing was enabled
  TextColumn get ownerUserId => text().nullable()();

  /// Whether this wallet is currently shared with a family group
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

extension WalletExtension on Wallet {
  /// Creates a [Wallet] instance from a map, typically from JSON deserialization.
  Wallet fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as int,
      cloudId: json['cloudId'] as String?,
      name: json['name'] as String,
      balance: json['balance'] as double,
      initialBalance: json['initialBalance'] as double? ?? 0.0,
      currency: json['currency'] as String,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      walletType: json['walletType'] as String? ?? 'cash',
      creditLimit: json['creditLimit'] as double?,
      billingDay: json['billingDay'] as int?,
      interestRate: json['interestRate'] as double?,
      ownerUserId: json['ownerUserId'] as String?,
      isShared: json['isShared'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

extension WalletTableExtensions on Wallet {
  WalletModel toModel() {
    return WalletModel(
      id: id,
      cloudId: cloudId,
      name: name,
      balance: balance,
      initialBalance: initialBalance,
      currency: currency,
      iconName: iconName,
      colorHex: colorHex,
      walletType: WalletType.fromString(walletType),
      creditLimit: creditLimit,
      billingDay: billingDay,
      interestRate: interestRate,
      ownerUserId: ownerUserId,
      isShared: isShared,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension WalletModelExtensions on WalletModel {
  WalletsCompanion toCompanion({bool isInsert = false}) {
    return WalletsCompanion(
      // If it's a true insert (like initial population), ID should be absent
      // so the database can auto-increment.
      id: isInsert
          ? const Value.absent()
          : (id == null ? const Value.absent() : Value(id!)),
      cloudId: cloudId == null ? const Value.absent() : Value(cloudId),
      name: Value(name),
      balance: Value(balance),
      initialBalance: Value(initialBalance),
      currency: Value(currency),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
      walletType: Value(walletType.toDbString()),
      creditLimit: creditLimit == null ? const Value.absent() : Value(creditLimit),
      billingDay: billingDay == null ? const Value.absent() : Value(billingDay),
      interestRate: interestRate == null ? const Value.absent() : Value(interestRate),
      ownerUserId: ownerUserId == null ? const Value.absent() : Value(ownerUserId),
      isShared: Value(isShared),
      // createdAt: use provided value or current time on insert
      createdAt: createdAt != null
          ? Value(createdAt!)
          : (isInsert ? Value(DateTime.now()) : const Value.absent()),
      updatedAt: updatedAt != null ? Value(updatedAt!) : Value(DateTime.now()),
    );
  }
}
