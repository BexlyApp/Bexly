// lib/screens/quotation_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Placeholder Navigation Targets ---
// Assume AddQuotationScreen exists if "+" button is functional
// import 'add_quotation_screen.dart';
// Assume QuotationDetailsScreen exists if items were tappable for details
// import 'quotation_details_screen.dart';
// Assume other screens exist for bottom nav
// import 'home_screen.dart';
// import 'invoice_list_screen.dart';
// import 'settings_screen.dart';

// --- Define Colors (Consider moving to a central theme file) ---
const Color kPrimaryPurple = Color(0xFF6A00F4); // Used in FAB/Nav
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5); // For list item bottom section bg
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;
const Color kAccentGreen = Color(0xFF4CAF50); // For the count badge
// --- End Color Definitions ---

class QuotationReportScreen extends StatefulWidget { // StatefulWidget for BottomNavBar
  const QuotationReportScreen({super.key});

  @override
  State<QuotationReportScreen> createState() => _QuotationReportScreenState();
}

class _QuotationReportScreenState extends State<QuotationReportScreen> {

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic (e.g., from API filtered by date range)
  final List<Map<String, dynamic>> quotationData = const [
    {
      'customer': 'FedEX',
      'email': 'fedx@example.com',
      'logoUrl': 'https://logo.clearbit.com/fedex.com', // Placeholder logo
      'amount': 1500.0,
      'quotationId': 'QU-0014',
      'createdOn': '15 Mar 2024',
      'dueDate': '20 Mar 2024',
    },
    {
      'customer': 'Google',
      'email': 'google@example.com',
      'logoUrl': 'https://logo.clearbit.com/google.com', // Placeholder logo
      'amount': 1100.0,
      'quotationId': 'QU-0013',
      'createdOn': '10 Mar 2024',
      'dueDate': '10 Mar 2024', // Due date matches created date in image
    },
    {
      'customer': 'World Energy',
      'email': 'worldenergy@example.com',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com', // Placeholder logo
      'amount': 990.0,
      'quotationId': 'QU-0012',
      'createdOn': '26 Feb 2024',
      'dueDate': '05 Mar 2024',
    },{
      'customer': 'FedEX',
      'email': 'fedx@example.com',
      'logoUrl': 'https://logo.clearbit.com/fedex.com', // Placeholder logo
      'amount': 1500.0,
      'quotationId': 'QU-0014',
      'createdOn': '15 Mar 2024',
      'dueDate': '20 Mar 2024',
    },
    {
      'customer': 'Google',
      'email': 'google@example.com',
      'logoUrl': 'https://logo.clearbit.com/google.com', // Placeholder logo
      'amount': 1100.0,
      'quotationId': 'QU-0013',
      'createdOn': '10 Mar 2024',
      'dueDate': '10 Mar 2024', // Due date matches created date in image
    },
    {
      'customer': 'World Energy',
      'email': 'worldenergy@example.com',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com', // Placeholder logo
      'amount': 990.0,
      'quotationId': 'QU-0012',
      'createdOn': '26 Feb 2024',
      'dueDate': '05 Mar 2024',
    },
    {
      'customer': 'Paloatte', // As per image
      'email': 'paloatte@example.com',
      'logoUrl': 'https://logo.clearbit.com/paloaltonetworks.com', // Placeholder logo
      'amount': 1500.0, // Amount cut off in image, assuming 1500
      'quotationId': 'QU-0011', // Assuming next ID
      'createdOn': '18 Feb 2024', // Assuming date
      'dueDate': '25 Feb 2024', // Assuming date
    },
    // Add more items if needed
  ];
  // --- End Placeholder Data ---

  // Currency formatting helper
  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0, // No decimals shown in the image
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = quotationData.length; // Get count from data

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quotation Report'), // Updated Title
        centerTitle: true, // Title is centered in the image
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search Quotations',
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
              'Quotations by Last 30 Days', // Title from image
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semi-bold
                color: kTextColor.withAlpha((0.2 * 255).toInt()),
              ),
            ),
          ),

          // Total Quotation Row
          _buildListHeader('Total Quotation', totalCount, context),

          // Quotation List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              itemCount: quotationData.length,
              itemBuilder: (context, index) {
                return QuotationListItem( // Use specific list item widget
                  quotation: quotationData[index],
                  formatCurrency: _formatCurrency,
                );
              },
            ),
          ),
        ],
      ),
      // --- FloatingActionButton and BottomNavigationBar ---

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
            tooltip: 'Filter Quotations', // Accessibility
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

  // --- Helper for Bottom Navigation Items ---

} // End _QuotationReportScreenState

// --- Separate Widget for Quotation List Item ---
class QuotationListItem extends StatelessWidget {
  final Map<String, dynamic> quotation;
  final Function(double) formatCurrency; // Pass formatter

  const QuotationListItem({
    super.key,
    required this.quotation,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    // Safely access data
    final String customer = quotation['customer'] ?? 'N/A';
    final String email = quotation['email'] ?? 'N/A';
    final String logoUrl = quotation['logoUrl'] ?? '';
    final double amount = (quotation['amount'] as num? ?? 0.0).toDouble();
    final String quotationId = quotation['quotationId'] ?? '-';
    final String createdOn = quotation['createdOn'] ?? '-';
    final String dueDate = quotation['dueDate'] ?? '-';

    return Card(
      elevation: 1.0,
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column( // Use Column to stack top part and bottom part
        children: [
          // Top Section: Logo, Customer/Email, Amount (with padding)
          Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0, bottom: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: 45,
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
                // Amount
                Text(
                  formatCurrency(amount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
          ),

          // Dashed Divider (Only between top and bottom sections)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0), // Indent divider slightly
            child: _buildDashedDivider(),
          ),
          // const SizedBox(height: 10), // Space already handled by Container padding below

          // Bottom Section: ID, Created On, Due Date (with background)
          Container(
            width: double.infinity, // Ensure container takes full width
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: kLightGray, // Light gray background for contrast
              borderRadius: BorderRadius.only( // Round only bottom corners to match card shape
                bottomLeft: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
              children: [
                _buildDetailColumn('Quotation ID', quotationId),
                _buildDetailColumn('Created On', createdOn),
                _buildDetailColumn('Due Date', dueDate, alignment: CrossAxisAlignment.end),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for detail columns in list item bottom section
  Widget _buildDetailColumn(String label, String value, {CrossAxisAlignment alignment = CrossAxisAlignment.start}) {
    return Flexible( // Use Flexible to prevent overflow if text is long
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0), // Padding between items
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: kMutedTextColor),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
              overflow: TextOverflow.ellipsis,
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

} // End QuotationListItem