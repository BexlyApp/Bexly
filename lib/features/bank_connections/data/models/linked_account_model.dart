/// Model representing a linked bank account from Stripe Financial Connections
class LinkedAccount {
  final String id;
  final String institutionName;
  final String? institutionIcon;
  final String? displayName;
  final String? last4;
  final String? category; // checking, savings, credit_card, etc.
  final String? status;
  final LinkedAccountBalance? balance;

  const LinkedAccount({
    required this.id,
    required this.institutionName,
    this.institutionIcon,
    this.displayName,
    this.last4,
    this.category,
    this.status,
    this.balance,
  });

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    return LinkedAccount(
      id: json['id'] as String,
      institutionName: json['institutionName'] as String,
      institutionIcon: json['institutionIcon'] as String?,
      displayName: json['displayName'] as String?,
      last4: json['last4'] as String?,
      category: json['category'] as String?,
      status: json['status'] as String?,
      balance: json['balance'] != null
          ? LinkedAccountBalance.fromJson(json['balance'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institutionName': institutionName,
      'institutionIcon': institutionIcon,
      'displayName': displayName,
      'last4': last4,
      'category': category,
      'status': status,
      'balance': balance?.toJson(),
    };
  }

  LinkedAccount copyWith({
    String? id,
    String? institutionName,
    String? institutionIcon,
    String? displayName,
    String? last4,
    String? category,
    String? status,
    LinkedAccountBalance? balance,
  }) {
    return LinkedAccount(
      id: id ?? this.id,
      institutionName: institutionName ?? this.institutionName,
      institutionIcon: institutionIcon ?? this.institutionIcon,
      displayName: displayName ?? this.displayName,
      last4: last4 ?? this.last4,
      category: category ?? this.category,
      status: status ?? this.status,
      balance: balance ?? this.balance,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkedAccount &&
        other.id == id &&
        other.institutionName == institutionName;
  }

  @override
  int get hashCode => id.hashCode ^ institutionName.hashCode;
}

class LinkedAccountBalance {
  final int? current;
  final int? available;
  final String? asOf; // ISO 8601 date

  const LinkedAccountBalance({
    this.current,
    this.available,
    this.asOf,
  });

  factory LinkedAccountBalance.fromJson(Map<String, dynamic> json) {
    return LinkedAccountBalance(
      current: json['current'] as int?,
      available: json['available'] as int?,
      asOf: json['asOf'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'available': available,
      'asOf': asOf,
    };
  }
}
