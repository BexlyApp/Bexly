import 'package:go_router/go_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/receipt_scanner/presentation/screens/receipt_scanner_screen.dart';

class ReceiptScannerRouter {
  static final routes = [
    GoRoute(
      path: Routes.scanReceipt,
      builder: (context, state) => const ReceiptScannerScreen(),
    ),
  ];
}
