/// One row in `bexly.linked_bank_accounts` — a virtual account a user has
/// authorised through Tingee.
class LinkedBankAccount {
  final String id;
  final String userId;
  final String tingeeAccountId;
  final String bankCode;
  final String accountNumberMasked;
  final String? label;
  final int? defaultWalletId;
  final String status; // 'active' | 'unlinked' | 'expired'
  final DateTime linkedAt;
  final DateTime? unlinkedAt;

  const LinkedBankAccount({
    required this.id,
    required this.userId,
    required this.tingeeAccountId,
    required this.bankCode,
    required this.accountNumberMasked,
    this.label,
    this.defaultWalletId,
    required this.status,
    required this.linkedAt,
    this.unlinkedAt,
  });

  bool get isActive => status == 'active';

  String get displayLabel =>
      (label != null && label!.isNotEmpty) ? label! : '$bankCode $accountNumberMasked';

  factory LinkedBankAccount.fromJson(Map<String, dynamic> json) {
    return LinkedBankAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tingeeAccountId: json['tingee_account_id'] as String,
      bankCode: json['bank_code'] as String,
      accountNumberMasked: json['account_number_masked'] as String,
      label: json['label'] as String?,
      defaultWalletId: json['default_wallet_id'] as int?,
      status: json['status'] as String? ?? 'active',
      linkedAt: DateTime.parse(json['linked_at'] as String),
      unlinkedAt: json['unlinked_at'] != null
          ? DateTime.parse(json['unlinked_at'] as String)
          : null,
    );
  }
}
