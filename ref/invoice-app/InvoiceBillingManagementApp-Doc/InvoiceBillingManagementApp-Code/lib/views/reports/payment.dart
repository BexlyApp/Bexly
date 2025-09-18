// lib/screens/payment_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Placeholder Navigation Targets ---
// Assume AddPaymentScreen exists if "+" button were present and functional
// import 'add_payment_screen.dart';
// Assume PaymentDetailsScreen exists if items were tappable for details
// import 'payment_details_screen.dart';


// --- Define Colors (Consider moving to a central theme file) ---
const Color kPrimaryPurple = Color(0xFF6A00F4); // Kept for potential future use
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;
const Color kAccentGreen = Color(0xFF4CAF50); // For the count badge
// --- End Color Definitions ---

class PaymentReportScreen extends StatelessWidget { // Changed to StatelessWidget
  const PaymentReportScreen({super.key});

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic (e.g., from API filtered by date range)
  final List<Map<String, dynamic>> paymentData = const [
    {
      'customer': 'FedEX',
      'email': 'fedx@example.com',
      'logoUrl': 'https://logo.clearbit.com/fedex.com', // Placeholder logo
      'netPayment': 1500.0, // Assuming Net = Received - Sent?
      'paymentReceived': 1500.0,
      'paymentSent': 400.0,
    },
    {
      'customer': 'Google',
      'email': 'google@example.com',
      'logoUrl': 'https://logo.clearbit.com/google.com', // Placeholder logo
      'netPayment': 1100.0, // Calculation doesn't match? 1700-500 = 1200. Using image value.
      'paymentReceived': 1700.0,
      'paymentSent': 500.0,
    },
    {
      'customer': 'World Energy',
      'email': 'worldenergy@example.com',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com', // Placeholder logo
      'netPayment': 990.0, // Calculation doesn't match? 1600-200 = 1400. Using image value.
      'paymentReceived': 1600.0,
      'paymentSent': 200.0,
    },
    {
      'customer': 'Paloatte', // As per image
      'email': 'paloatte@example.com',
      'logoUrl': 'https://logo.clearbit.com/paloaltonetworks.com', // Placeholder logo
      'netPayment': 1500.0, // Calculation doesn't match? 1400-100=1300. Using image value.
      'paymentReceived': 1400.0,
      'paymentSent': 100.0,
    },
    {
      'customer': 'World Energy', // Duplicate from image
      'email': 'worldenergy@example.com',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com', // Placeholder logo
      'netPayment': 990.0,
      'paymentReceived': 1190.0, // Example different values
      'paymentSent': 200.0, // Example different values
    }, {
      'customer': 'Google',
      'email': 'google@example.com',
      'logoUrl': 'https://logo.clearbit.com/google.com', // Placeholder logo
      'netPayment': 1100.0, // Calculation doesn't match? 1700-500 = 1200. Using image value.
      'paymentReceived': 1700.0,
      'paymentSent': 500.0,
    },
    {
      'customer': 'World Energy',
      'email': 'worldenergy@example.com',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com', // Placeholder logo
      'netPayment': 990.0, // Calculation doesn't match? 1600-200 = 1400. Using image value.
      'paymentReceived': 1600.0,
      'paymentSent': 200.0,
    },
    {
      'customer': 'Paloatte', // As per image
      'email': 'paloatte@example.com',
      'logoUrl': 'https://logo.clearbit.com/paloaltonetworks.com', // Placeholder logo
      'netPayment': 1500.0, // Calculation doesn't match? 1400-100=1300. Using image value.
      'paymentReceived': 1400.0,
      'paymentSent': 100.0,
    },
    {
      'customer': 'World Energy', // Duplicate from image
      'email': 'worldenergy@example.com',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com', // Placeholder logo
      'netPayment': 990.0,
      'paymentReceived': 1190.0, // Example different values
      'paymentSent': 200.0, // Example different values
    },
    // Add more items if needed
  ];
  // --- End Placeholder Data ---

  // Currency formatting helper
  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$', // Add space if needed: '\$ '
      decimalDigits: 0, // No decimals shown in the image
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = paymentData.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment Report'), // Updated Title
        centerTitle: true, // Title is centered in the image
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search Payments',
            onPressed: () {
              // TODO: Implement Search Functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search Action (Not Implemented)')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor,
        elevation: 0.5, // Subtle shadow
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              'Payments by Last 30 Days', // Title from image
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semi-bold
                color: kTextColor.withAlpha((0.2 * 255).toInt()),
              ),
            ),
          ),

          // Total Payments Row
          _buildListHeader('Total Payments', totalCount, context),

          // Payment List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              itemCount: paymentData.length,
              itemBuilder: (context, index) {
                return PaymentListItem( // Use specific list item widget
                  payment: paymentData[index],
                  formatCurrency: _formatCurrency,
                );
              },
            ),
          ),
        ],
      ),
      // --- Removed FloatingActionButton and BottomNavigationBar ---
    );
  }

  // Builds the header section above the list (Total Count + Filter)
  Widget _buildListHeader(String title, int count, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0), // Adjust padding
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600, // Semi-bold
              color: kTextColor,
            ),
          ),
          const SizedBox(width: 8),
          // Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kAccentGreen.withAlpha((0.2 * 255).toInt()), // Light green background
              borderRadius: BorderRadius.circular(12), // Pill shape
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: kAccentGreen, // Darker green text
              ),
            ),
          ),
          const Spacer(), // Pushes filter icon to the right end
          // Filter Button
          IconButton(
            icon: const Icon(Icons.filter_list_alt, size: 24, color: kIconColor),
            tooltip: 'Filter Payments', // Accessibility
            onPressed: () {
              // TODO: Implement Filter/Sort Action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter/Sort Action (Not Implemented)')),
              );
            },
            padding: EdgeInsets.zero, // Remove default padding
            constraints: const BoxConstraints(), // Remove default size constraints
          ),
        ],
      ),
    );
  }

} // End PaymentReportScreen

// --- Separate Widget for Payment List Item ---
class PaymentListItem extends StatelessWidget {
  final Map<String, dynamic> payment;
  final Function(double) formatCurrency; // Pass formatter

  const PaymentListItem({
    super.key,
    required this.payment,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    // Safely access data
    final String customer = payment['customer'] ?? 'N/A';
    final String email = payment['email'] ?? 'N/A';
    final String logoUrl = payment['logoUrl'] ?? '';
    final double netPayment = (payment['netPayment'] as num? ?? 0.0).toDouble();
    final double paymentReceived = (payment['paymentReceived'] as num? ?? 0.0).toDouble();
    final double paymentSent = (payment['paymentSent'] as num? ?? 0.0).toDouble();


    return Card(
      elevation: 1.0,
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding( // Add padding around the entire card content
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Top Row: Logo, Customer/Email, Net Payment
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: 45, // Consistent logo size
                    height: 45,
                    decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: kBorderColor.withAlpha((0.2 * 255).toInt()))
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, st) => Container(
                          color: kLightGray.withAlpha((0.2 * 255).toInt()),
                          child: const Icon(Icons.business_center_outlined, size: 24, color: kMutedTextColor),
                        ),
                        loadingBuilder:(context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 1.5,
                              color: kPrimaryPurple.withAlpha((0.2 * 255).toInt()),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Customer & Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 13, color: kMutedTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Net Payment
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Net Payment',
                      style: TextStyle(fontSize: 11, color: kMutedTextColor),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatCurrency(netPayment),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dashed Divider
            _buildDashedDivider(),
            const SizedBox(height: 10),

            // Bottom Row: Payment Received, Payment Sent
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  // Add space after colon for consistency
                  'Payment Received : ${formatCurrency(paymentReceived)}',
                  style: const TextStyle(fontSize: 13, color: kMutedTextColor),
                ),
                Text(
                  // Add space after colon for consistency
                  'Payment Sent : ${formatCurrency(paymentSent)}',
                  style: const TextStyle(fontSize: 13, color: kMutedTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to create a simple dashed/dotted line effect
  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 3.0;
        const dashHeight = 1.0;
        const dashSpace = 2.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: kBorderColor),
              ),
            );
          }),
        );
      },
    );
  }

} // End PaymentListItem