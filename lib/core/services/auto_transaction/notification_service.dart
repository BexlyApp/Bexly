import 'dart:async';
import 'dart:io';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/auto_transaction/parsed_transaction.dart';
import 'package:bexly/core/services/auto_transaction/transaction_parser_service.dart';

/// Callback type for when a new transaction is parsed from notification
typedef OnNotificationTransactionParsed = void Function(ParsedTransaction transaction);

/// Known banking app package names
class BankingAppPackages {
  // Vietnam Banks
  static const vietcombank = 'com.VCB';
  static const techcombank = 'vn.com.techcombank.bb.app';
  static const tpbank = 'com.tpb.mb.gprsandroid';
  static const bidv = 'com.vnpay.bidv';
  static const vietinbank = 'com.vietinbank.ipay';
  static const agribank = 'com.vnpay.agribank';
  static const mbbank = 'com.mbmobile';
  static const acb = 'mobile.acb.com.vn';
  static const vpbank = 'com.vnpay.vpbankonline';
  static const sacombank = 'com.sacombank.ewallet';
  static const hdbank = 'com.vnpay.hdbank';

  // E-wallets Vietnam
  static const momo = 'com.mservice.momotransfer';
  static const zalopay = 'vn.com.vng.zalopay';
  static const vnpay = 'com.vnpay.vnpayewallet';
  static const shopeepay = 'com.beeasy.shopee';

  // International Banks
  static const hsbc = 'com.htsu.hsbcpersonalbanking';
  static const citibank = 'com.citi.citimobile';

  // Thailand Banks
  static const kbank = 'com.kasikorn.retail.mbanking.wap';
  static const scb = 'com.scb.phone';

  // Indonesia Banks
  static const bca = 'com.bca';
  static const mandiri = 'id.co.bankmandiri.livin';

  // Singapore Banks
  static const dbs = 'com.dbs.sg.dbsmbanking';
  static const ocbc = 'com.ocbc.mobile';

  /// All known banking package names
  static const List<String> allPackages = [
    vietcombank, techcombank, tpbank, bidv, vietinbank, agribank,
    mbbank, acb, vpbank, sacombank, hdbank,
    momo, zalopay, vnpay, shopeepay,
    hsbc, citibank,
    kbank, scb,
    bca, mandiri,
    dbs, ocbc,
  ];

  /// Get bank name from package name
  static String? getBankName(String packageName) {
    final mapping = {
      vietcombank: 'Vietcombank',
      techcombank: 'Techcombank',
      tpbank: 'TPBank',
      bidv: 'BIDV',
      vietinbank: 'VietinBank',
      agribank: 'Agribank',
      mbbank: 'MB Bank',
      acb: 'ACB',
      vpbank: 'VPBank',
      sacombank: 'Sacombank',
      hdbank: 'HDBank',
      momo: 'MoMo',
      zalopay: 'ZaloPay',
      vnpay: 'VNPay',
      shopeepay: 'ShopeePay',
      hsbc: 'HSBC',
      citibank: 'Citibank',
      kbank: 'Kasikorn Bank',
      scb: 'Siam Commercial Bank',
      bca: 'Bank Central Asia',
      mandiri: 'Bank Mandiri',
      dbs: 'DBS Bank',
      ocbc: 'OCBC Bank',
    };
    return mapping[packageName];
  }

  /// Check if package is a known banking app
  static bool isBankingApp(String packageName) {
    return allPackages.contains(packageName) ||
           packageName.toLowerCase().contains('bank') ||
           packageName.toLowerCase().contains('wallet') ||
           packageName.toLowerCase().contains('pay');
  }
}

/// Service to listen for notifications from banking apps
class NotificationListenerServiceWrapper {
  final TransactionParserService _parserService;
  final TransactionDeduplicationService _deduplicationService;

  StreamSubscription<ServiceNotificationEvent>? _subscription;
  OnNotificationTransactionParsed? _onTransactionParsed;

  bool _isListening = false;

  NotificationListenerServiceWrapper({
    required TransactionParserService parserService,
    TransactionDeduplicationService? deduplicationService,
  })  : _parserService = parserService,
        _deduplicationService = deduplicationService ?? TransactionDeduplicationService();

  /// Check if notification listener is available on this platform
  bool get isAvailable => Platform.isAndroid;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if notification listener permission is granted
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (e) {
      Log.e('Error checking notification permission: $e', label: 'NotificationService');
      return false;
    }
  }

  /// Request notification listener permission (opens system settings)
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      // This opens the notification access settings page
      await NotificationListenerService.requestPermission();
      // User needs to manually enable, so check after a delay
      await Future.delayed(const Duration(seconds: 1));
      return await hasPermission();
    } catch (e) {
      Log.e('Error requesting notification permission: $e', label: 'NotificationService');
      return false;
    }
  }

  /// Start listening for notifications
  Future<bool> startListening({
    required OnNotificationTransactionParsed onTransactionParsed,
  }) async {
    if (!Platform.isAndroid) {
      Log.w('Notification listening only available on Android', label: 'NotificationService');
      return false;
    }

    if (_isListening) {
      Log.d('Already listening for notifications', label: 'NotificationService');
      return true;
    }

    final hasPerms = await hasPermission();
    if (!hasPerms) {
      Log.w('Notification listener permission not granted', label: 'NotificationService');
      return false;
    }

    _onTransactionParsed = onTransactionParsed;

    try {
      _subscription = NotificationListenerService.notificationsStream.listen(
        _handleNotification,
        onError: (error) {
          Log.e('Notification stream error: $error', label: 'NotificationService');
        },
      );

      _isListening = true;
      Log.d('Started listening for notifications', label: 'NotificationService');
      return true;
    } catch (e) {
      Log.e('Error starting notification listener: $e', label: 'NotificationService');
      return false;
    }
  }

  /// Stop listening for notifications
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _onTransactionParsed = null;
    _isListening = false;
    Log.d('Stopped listening for notifications', label: 'NotificationService');
  }

  /// Handle incoming notification
  void _handleNotification(ServiceNotificationEvent event) async {
    final packageName = event.packageName ?? '';
    final title = event.title ?? '';
    final content = event.content ?? '';

    Log.d('Notification from: $packageName', label: 'NotificationService');

    // Check if it's from a banking app
    if (!BankingAppPackages.isBankingApp(packageName)) {
      Log.d('Not a banking app, ignoring', label: 'NotificationService');
      return;
    }

    final bankName = BankingAppPackages.getBankName(packageName) ?? packageName;
    Log.d('Banking notification from $bankName: $title', label: 'NotificationService');

    // Combine title and content for parsing
    final message = '$title\n$content';

    // Parse the notification
    final parsed = await _parserService.parseMessage(
      message: message,
      source: 'notification',
      senderId: packageName,
      bankName: bankName,
      messageTime: DateTime.now(),
    );

    if (parsed == null) {
      Log.d('Could not parse transaction from notification', label: 'NotificationService');
      return;
    }

    // Check for duplicates
    final isDuplicate = await _deduplicationService.isDuplicate(parsed);
    if (isDuplicate) {
      Log.d('Duplicate transaction detected, ignoring', label: 'NotificationService');
      return;
    }

    // Mark as processed
    await _deduplicationService.markProcessed(parsed);

    // Notify callback
    Log.d('New transaction parsed from notification: $parsed', label: 'NotificationService');
    _onTransactionParsed?.call(parsed);
  }
}
