/// Bank sender whitelist for SMS parsing
/// Contains known SMS senders from various banks in Vietnam and internationally

class BankSender {
  final String senderId;
  final String bankName;
  final String? bankCode;
  final String country;

  const BankSender({
    required this.senderId,
    required this.bankName,
    this.bankCode,
    required this.country,
  });
}

/// List of known bank SMS senders
/// Senders are matched case-insensitively
const List<BankSender> knownBankSenders = [
  // Vietnam Banks
  BankSender(senderId: 'Vietcombank', bankName: 'Vietcombank', bankCode: 'VCB', country: 'VN'),
  BankSender(senderId: 'VCB', bankName: 'Vietcombank', bankCode: 'VCB', country: 'VN'),
  BankSender(senderId: 'Techcombank', bankName: 'Techcombank', bankCode: 'TCB', country: 'VN'),
  BankSender(senderId: 'TCB', bankName: 'Techcombank', bankCode: 'TCB', country: 'VN'),
  BankSender(senderId: 'TPBank', bankName: 'TPBank', bankCode: 'TPB', country: 'VN'),
  BankSender(senderId: 'BIDV', bankName: 'BIDV', bankCode: 'BIDV', country: 'VN'),
  BankSender(senderId: 'VietinBank', bankName: 'VietinBank', bankCode: 'CTG', country: 'VN'),
  BankSender(senderId: 'Agribank', bankName: 'Agribank', bankCode: 'AGR', country: 'VN'),
  BankSender(senderId: 'MBBank', bankName: 'MB Bank', bankCode: 'MB', country: 'VN'),
  BankSender(senderId: 'MB', bankName: 'MB Bank', bankCode: 'MB', country: 'VN'),
  BankSender(senderId: 'ACB', bankName: 'ACB', bankCode: 'ACB', country: 'VN'),
  BankSender(senderId: 'VPBank', bankName: 'VPBank', bankCode: 'VPB', country: 'VN'),
  BankSender(senderId: 'Sacombank', bankName: 'Sacombank', bankCode: 'STB', country: 'VN'),
  BankSender(senderId: 'HDBank', bankName: 'HDBank', bankCode: 'HDB', country: 'VN'),
  BankSender(senderId: 'SHB', bankName: 'SHB', bankCode: 'SHB', country: 'VN'),
  BankSender(senderId: 'MSB', bankName: 'Maritime Bank', bankCode: 'MSB', country: 'VN'),
  BankSender(senderId: 'SeABank', bankName: 'SeABank', bankCode: 'SEAB', country: 'VN'),
  BankSender(senderId: 'OCB', bankName: 'OCB', bankCode: 'OCB', country: 'VN'),
  BankSender(senderId: 'VIB', bankName: 'VIB', bankCode: 'VIB', country: 'VN'),
  BankSender(senderId: 'LienVietPostBank', bankName: 'LienVietPostBank', bankCode: 'LPB', country: 'VN'),

  // More Vietnam Banks
  BankSender(senderId: 'Eximbank', bankName: 'Eximbank', bankCode: 'EIB', country: 'VN'),
  BankSender(senderId: 'ABBank', bankName: 'ABBank', bankCode: 'ABB', country: 'VN'),
  BankSender(senderId: 'NCB', bankName: 'NCB', bankCode: 'NCB', country: 'VN'),
  BankSender(senderId: 'PVcomBank', bankName: 'PVcomBank', bankCode: 'PVCB', country: 'VN'),
  BankSender(senderId: 'NamABank', bankName: 'Nam A Bank', bankCode: 'NAB', country: 'VN'),
  BankSender(senderId: 'KienLongBank', bankName: 'Kien Long Bank', bankCode: 'KLB', country: 'VN'),
  BankSender(senderId: 'BaoVietBank', bankName: 'BaoViet Bank', bankCode: 'BVB', country: 'VN'),
  BankSender(senderId: 'VietABank', bankName: 'VietA Bank', bankCode: 'VAB', country: 'VN'),
  BankSender(senderId: 'GPBank', bankName: 'GP Bank', bankCode: 'GPB', country: 'VN'),
  BankSender(senderId: 'Cake', bankName: 'Cake by VPBank', bankCode: 'CAKE', country: 'VN'),
  BankSender(senderId: 'Timo', bankName: 'Timo', bankCode: 'TIMO', country: 'VN'),
  BankSender(senderId: 'TNEX', bankName: 'TNEX', bankCode: 'TNEX', country: 'VN'),

  // E-wallets Vietnam (MoMo removed - only sends ads, not transaction SMS)
  BankSender(senderId: 'ZaloPay', bankName: 'ZaloPay', bankCode: 'ZALO', country: 'VN'),
  BankSender(senderId: 'VNPay', bankName: 'VNPay', bankCode: 'VNPAY', country: 'VN'),
  BankSender(senderId: 'ShopeePay', bankName: 'ShopeePay', bankCode: 'SPAY', country: 'VN'),
  BankSender(senderId: 'VTMONEY', bankName: 'Viettel Money', bankCode: 'VTMONEY', country: 'VN'),
  BankSender(senderId: 'ViettelPay', bankName: 'Viettel Money', bankCode: 'VTMONEY', country: 'VN'),
  BankSender(senderId: 'Grab', bankName: 'GrabPay', bankCode: 'GRAB', country: 'VN'),

  // International Banks
  BankSender(senderId: 'HSBC', bankName: 'HSBC', bankCode: 'HSBC', country: 'INTL'),
  BankSender(senderId: 'Citibank', bankName: 'Citibank', bankCode: 'CITI', country: 'INTL'),
  BankSender(senderId: 'StandardChartered', bankName: 'Standard Chartered', bankCode: 'SCB', country: 'INTL'),

  // Thailand Banks
  BankSender(senderId: 'KBANK', bankName: 'Kasikorn Bank', bankCode: 'KBANK', country: 'TH'),
  BankSender(senderId: 'SCB', bankName: 'Siam Commercial Bank', bankCode: 'SCB', country: 'TH'),
  BankSender(senderId: 'BBL', bankName: 'Bangkok Bank', bankCode: 'BBL', country: 'TH'),
  BankSender(senderId: 'KTB', bankName: 'Krung Thai Bank', bankCode: 'KTB', country: 'TH'),

  // Indonesia Banks
  BankSender(senderId: 'BCA', bankName: 'Bank Central Asia', bankCode: 'BCA', country: 'ID'),
  BankSender(senderId: 'BRI', bankName: 'Bank Rakyat Indonesia', bankCode: 'BRI', country: 'ID'),
  BankSender(senderId: 'Mandiri', bankName: 'Bank Mandiri', bankCode: 'MANDIRI', country: 'ID'),
  BankSender(senderId: 'BNI', bankName: 'Bank Negara Indonesia', bankCode: 'BNI', country: 'ID'),

  // Singapore Banks
  BankSender(senderId: 'DBS', bankName: 'DBS Bank', bankCode: 'DBS', country: 'SG'),
  BankSender(senderId: 'OCBC', bankName: 'OCBC Bank', bankCode: 'OCBC', country: 'SG'),
  BankSender(senderId: 'UOB', bankName: 'United Overseas Bank', bankCode: 'UOB', country: 'SG'),

  // US Banks
  BankSender(senderId: 'Chase', bankName: 'Chase Bank', bankCode: 'CHASE', country: 'US'),
  BankSender(senderId: 'BofA', bankName: 'Bank of America', bankCode: 'BOFA', country: 'US'),
  BankSender(senderId: 'WellsFargo', bankName: 'Wells Fargo', bankCode: 'WF', country: 'US'),
];

/// Check if a sender is a known bank sender
BankSender? findBankSender(String sender) {
  final normalizedSender = sender.toLowerCase().trim();

  for (final bank in knownBankSenders) {
    if (bank.senderId.toLowerCase() == normalizedSender) {
      return bank;
    }
    // Also check if sender contains bank name
    if (normalizedSender.contains(bank.senderId.toLowerCase()) ||
        normalizedSender.contains(bank.bankName.toLowerCase())) {
      return bank;
    }
  }

  return null;
}

/// Check if sender matches any known bank pattern
bool isBankSender(String sender) {
  return findBankSender(sender) != null;
}
