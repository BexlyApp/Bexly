import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

@DataClassName('Wallet')
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Cloud ID (UUID v7) for syncing with Firestore
  /// Null for offline-only data, generated when first synced
  TextColumn get cloudId => text().nullable().unique()();

  TextColumn get name => text().withDefault(const Constant('My Wallet'))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

extension WalletExtension on Wallet {
  /// Creates a [Wallet] instance from a map, typically from JSON deserialization.
  Wallet fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as int,
      name: json['name'] as String,
      balance: json['balance'] as double,
      currency: json['currency'] as String,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
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
      currency: currency,
      iconName: iconName,
      colorHex: colorHex,
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
      currency: Value(currency),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
      // createdAt: use provided value or current time on insert
      createdAt: createdAt != null
          ? Value(createdAt!)
          : (isInsert ? Value(DateTime.now()) : const Value.absent()),
      updatedAt: updatedAt != null ? Value(updatedAt!) : Value(DateTime.now()),
    );
  }
}
