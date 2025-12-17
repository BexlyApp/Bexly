import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_wallet_model.freezed.dart';
part 'shared_wallet_model.g.dart';

/// Model representing a wallet shared with a family group
@freezed
abstract class SharedWalletModel with _$SharedWalletModel {
  const factory SharedWalletModel({
    /// Local database ID
    int? id,

    /// Cloud ID (UUID v7) for syncing with Firestore
    String? cloudId,

    /// Local family group ID
    int? familyId,

    /// Local wallet ID
    int? walletId,

    /// Firebase UID of the user who shared the wallet
    required String sharedByUserId,

    /// Whether the wallet is currently being shared
    @Default(true) bool isActive,

    /// When the wallet was shared
    DateTime? sharedAt,

    /// When the wallet was unshared (if isActive = false)
    DateTime? unsharedAt,

    /// Timestamp when record was created
    DateTime? createdAt,

    /// Timestamp when record was last updated
    DateTime? updatedAt,
  }) = _SharedWalletModel;

  factory SharedWalletModel.fromJson(Map<String, dynamic> json) =>
      _$SharedWalletModelFromJson(json);
}
