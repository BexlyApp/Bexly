// lib/screens/income_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Placeholder Navigation Targets ---
// Assume AddIncomeScreen exists if "+" button were present
// import 'add_income_screen.dart';
// Assume IncomeDetailsScreen exists if items were tappable for details
// import 'income_details_screen.dart';

// --- Define Colors (Consider moving to a central theme file) ---
const Color kPrimaryPurple = Color(0xFF6A00F4); // Used in original FAB/Nav
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;
const Color kAccentGreen = Color(0xFF4CAF50); // For the count badge
// --- End Color Definitions ---

class IncomeReportScreen extends StatelessWidget {
  const IncomeReportScreen({super.key});

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic (e.g., from API filtered by date range)
  final List<Map<String, dynamic>> incomeData = const [
    {
      'customer': 'FedEX',
      'email': 'fedx@example.com',
      'logoUrl': 'https://logo.clearbit.com/fedex.com', // Placeholder logo
      'amount': 2000.0,
      'date': '15 Mar 2024',
      'mode': 'cash', // Lowercase to match image
    },
    {
      'customer': 'Google',
      'email': 'google@example.com',
      'logoUrl': 'https://logo.clearbit.com/google.com', // Placeholder logo
      'amount': 1200.0,
      'date': '10 Mar 2024', // Corrected date from image typo "110Mar"
      'mode': 'cash',
    },
    {
      'customer': 'World Energy',
      'email': 'worldenergy@example.com',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com', // Placeholder logo
      'amount': 1600.0,
      'date': '27 Feb 2024',
      'mode': 'cash',
    },
    {
      'customer': 'Paloatte', // As per image
      'email': 'paloatte@example.com',
      'logoUrl': 'https://logo.clearbit.com/paloaltonetworks.com', // Placeholder logo
      'amount': 1100.0,
      'date': '15 Feb 2024',
      'mode': 'cash',
    }, {
      'customer': 'FedEX',
      'email': 'fedx@example.com',
      'logoUrl': 'https://logo.clearbit.com/fedex.com', // Placeholder logo
      'amount': 2000.0,
      'date': '15 Mar 2024',
      'mode': 'cash', // Lowercase to match image
    },
    {
      'customer': 'Google',
      'email': 'google@example.com',
      'logoUrl': 'https://logo.clearbit.com/google.com', // Placeholder logo
      'amount': 1200.0,
      'date': '10 Mar 2024', // Corrected date from image typo "110Mar"
      'mode': 'cash',
    },
    {
      'customer': 'World Energy',
      'email': 'worldenergy@example.com',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com', // Placeholder logo
      'amount': 1600.0,
      'date': '27 Feb 2024',
      'mode': 'cash',
    },
    {
      'customer': 'Paloatte', // As per image
      'email': 'paloatte@example.com',
      'logoUrl': 'https://logo.clearbit.com/paloaltonetworks.com', // Placeholder logo
      'amount': 1100.0,
      'date': '15 Feb 2024',
      'mode': 'cash',
    },
    {
      'customer': 'World Energy', // Duplicate entry from image
      'email': 'worldenergy@example.com',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com', // Placeholder logo
      'amount': 1500.0,
      'date': '10 Feb 2024', // Assuming a different date for variety
      'mode': 'card', // Assuming a different mode for variety
    },
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
    final int totalCount = incomeData.length; // Get count from data

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Income Report'),
        centerTitle: true, // Title is centered in the image
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search Income',
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
              'Income by Last 30 Days', // Title from image
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semi-bold
                color: kTextColor.withAlpha((0.2 * 255).toInt()),
              ),
            ),
          ),

          // Total Income Row
          _buildListHeader('Total Income', totalCount, context),

          // Income List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              itemCount: incomeData.length,
              itemBuilder: (context, index) {
                return IncomeListItem(
                  income: incomeData[index],
                  formatCurrency: _formatCurrency,
                );
              },
            ),
          ),
        ],
      ),
      // NO BottomNavigationBar or FloatingActionButton
    );
  }

  // Builds the header section above the list (Total Income + Filter)
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
            icon: const Icon(Icons.filter_list_alt, size: 24, color: kIconColor), // Filter icon used in image
            tooltip: 'Filter Income', // Accessibility
            onPressed: () {
              // TODO: Implement Filter/Sort Action
              // This could show a bottom sheet or dialog for filter options
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

} // End IncomeReportScreen

// --- Separate Widget for Income List Item ---
class IncomeListItem extends StatelessWidget {
  final Map<String, dynamic> income;
  final Function(double) formatCurrency; // Pass formatter

  const IncomeListItem({
    super.key,
    required this.income,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    // Safely access data
    final String customer = income['customer'] ?? 'N/A';
    final String email = income['email'] ?? 'N/A';
    final String logoUrl = income['logoUrl'] ?? '';
    final double amount = (income['amount'] as num? ?? 0.0).toDouble();
    final String date = income['date'] ?? '-';
    final String mode = income['mode'] ?? '-';

    return Card(
      elevation: 1.0, // Slightly more elevation than previous examples based on image shadow
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 9.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        // No border seems visible in the image for these cards
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Top Row: Logo, Customer/Email, Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align top for logo and text columns
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                        color: kWhiteColor, // Ensure background for transparent logos
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: kBorderColor.withAlpha((0.2 * 255).toInt())) // Optional subtle border
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0), // Padding around the logo itself
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
                // Income Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Income Amount',
                      style: TextStyle(fontSize: 11, color: kMutedTextColor),
                    ),
                    const SizedBox(height: 3),
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
              ],
            ),
            const SizedBox(height: 10), // Space before divider line

            // Dashed Divider (Using simple dots as a substitute)
            _buildDashedDivider(),
            const SizedBox(height: 10), // Space after divider line

            // Bottom Row: Date, Mode of Payment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date : $date',
                  style: const TextStyle(fontSize: 13, color: kMutedTextColor),
                ),
                Text(
                  'Mode of Payment : $mode',
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
                decoration: BoxDecoration(color: kBorderColor), // Use border color for dashes
              ),
            );
          }),
        );
      },
    );
  }

} // End IncomeListItem