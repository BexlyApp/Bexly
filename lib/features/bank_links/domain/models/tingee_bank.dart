/// One supported bank returned by Tingee `/v1/get-banks`.
///
/// Field names follow Tingee's response shape (subject to change once we
/// see live responses). Unknown fields are ignored on parse.
class TingeeBank {
  final String code;
  final String name;
  final String? shortName;
  final String? logoUrl;

  const TingeeBank({
    required this.code,
    required this.name,
    this.shortName,
    this.logoUrl,
  });

  String get displayName =>
      (shortName != null && shortName!.isNotEmpty) ? shortName! : name;

  factory TingeeBank.fromJson(Map<String, dynamic> json) {
    return TingeeBank(
      code: (json['bankCode'] ?? json['code'] ?? '') as String,
      name: (json['bankName'] ?? json['name'] ?? '') as String,
      shortName: json['shortName'] as String?,
      logoUrl: (json['logo'] ?? json['logoUrl']) as String?,
    );
  }
}
