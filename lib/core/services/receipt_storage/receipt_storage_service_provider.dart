import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/services/receipt_storage/receipt_storage_service.dart';

final receiptStorageServiceProvider = Provider<ReceiptStorageService>((ref) {
  return ReceiptStorageService();
});



