/// One supported bank returned by Tingee `/v1/get-banks`.
///
/// `bin` is the numeric Bank Identification Number (e.g. "970418" for BIDV)
/// that Tingee's other endpoints accept as `bankBin`. `code` is the short
/// alias ("BIDV", "ACB") and is only useful for display.
class TingeeBank {
  final String code;
  final String bin;
  final String name;
  final String? shortName;
  final String? logoUrl;

  const TingeeBank({
    required this.code,
    required this.bin,
    required this.name,
    this.shortName,
    this.logoUrl,
  });

  String get displayName =>
      (shortName != null && shortName!.isNotEmpty) ? shortName! : name;

  factory TingeeBank.fromJson(Map<String, dynamic> json) {
    return TingeeBank(
      code: (json['bankCode'] ?? json['code'] ?? '') as String,
      bin: (json['bin'] ?? json['bankBin'] ?? '').toString(),
      name: (json['bankName'] ?? json['name'] ?? '') as String,
      shortName: json['shortName'] as String?,
      logoUrl: (json['logo'] ?? json['logoUrl']) as String?,
    );
  }
}
