/// Auto Transaction Services
///
/// This module provides automatic transaction creation from:
/// - SMS messages from banks (Android only)
/// - Push notifications from banking apps (Android only)
///
/// Usage:
/// ```dart
/// final autoService = ref.read(autoTransactionServiceProvider);
/// await autoService.initialize();
/// ```

export 'auto_transaction_service.dart';
export 'bank_senders.dart';
export 'bank_wallet_mapping.dart';
export 'notification_service.dart';
export 'parsed_transaction.dart';
export 'sms_service.dart';
export 'transaction_parser_service.dart';
