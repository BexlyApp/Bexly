import 'package:go_router/go_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/transaction/presentation/screens/transaction_form.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';

class TransactionRouter {
  static final routes = <GoRoute>[
    GoRoute(
      path: Routes.transactionForm,
      builder: (context, state) {
        final receiptData = state.extra as ReceiptScanResult?;
        return TransactionForm(receiptData: receiptData);
      },
    ),
    GoRoute(
      path: '/transaction/:id', // Matches the path used in push
      builder: (context, state) {
        final int? transactionId = int.tryParse(
          state.pathParameters['id'] ?? '',
        ); // Access the ID
        // Pass the ID to your TransactionForm or a wrapper widget
        return TransactionForm(transactionId: transactionId);
      },
    ),
  ];
}
