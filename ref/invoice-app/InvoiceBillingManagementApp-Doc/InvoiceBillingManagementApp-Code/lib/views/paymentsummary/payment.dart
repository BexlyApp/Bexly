// lib/screens/payment_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Placeholder Navigation Targets ---
// Assume AddPaymentScreen exists or reuse AddPurchaseScreen if applicable
// import 'add_payment_screen.dart'; // TODO: Uncomment when AddPaymentScreen is created
// Assume PaymentDetailsScreen exists
// import 'payment_details_screen.dart'; // TODO: Uncomment when PaymentDetailsScreen is created

// --- Define Colors Directly In This File ---
// Consider moving these to a central theme file for larger applications
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5); // Used for bottom section bg
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

class PaymentSummaryScreen extends StatefulWidget {
  // Made StatefulWidget for BottomNavBar index
  const PaymentSummaryScreen({super.key});

  @override
  State<PaymentSummaryScreen> createState() => _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends State<PaymentSummaryScreen> {

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic (e.g., from API, database, state management)
  final List<Map<String, dynamic>> allPaymentsData = const [
    {
      'customer': 'FedEX',
      'logoUrl': 'https://logo.clearbit.com/fedex.com', // Example placeholder
      'amount': 2000.0,
      'invoiceNo': '#INV0020',
      'date': '15 Mar 2024',
      'mode': 'Cash',
    },
    {
      'customer': 'Google',
      'logoUrl': 'https://logo.clearbit.com/google.com', // Example placeholder
      'amount': 1600.0,
      'invoiceNo': '#INV0019',
      'date': '10 Mar 2024',
      'mode': 'Cash',
    },
    {
      'customer': 'World Energy',
      'logoUrl':
          'https://logo.clearbit.com/worldenergy.com', // Example placeholder
      'amount': 1400.0,
      'invoiceNo': '#INV0018',
      'date': '24 Feb 2024',
      'mode': 'Cash',
    },
    {
      'customer': 'Paloatte', // Assuming 'Palo Alto Networks' or similar
      'logoUrl':
          'https://logo.clearbit.com/paloaltonetworks.com', // Example placeholder
      'amount': 1200.0,
      'invoiceNo': '#INV0017',
      'date': '18 Feb 2024', // Date was cut off, assuming Feb
      'mode': 'Cash',
    },
    {
      'customer': 'Microsoft',
      'logoUrl':
          'https://logo.clearbit.com/microsoft.com', // Example placeholder
      'amount': 2500.0,
      'invoiceNo': '#INV0016',
      'date': '15 Feb 2024',
      'mode': 'Card',
    },
    // Add more placeholder items if needed for testing scrolling
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    // In a real app, this list might be filtered based on search/filter criteria
    final List<Map<String, dynamic>> displayedList = allPaymentsData;
    final int totalCount = displayedList.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context), // Standard back action
        ),
        title: const Text('Payment Summary'), // Title as seen in image
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search Payments', // Accessibility
            onPressed: () {
              // TODO: Implement Search Functionality
              // This could involve showing a search bar or navigating to a search screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search Action (Not Implemented)'),
                ),
              );
            },
          ),
          const SizedBox(width: 8), // Spacing before edge
        ],
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor, // Color for title and icons
        elevation: 0.5, // Subtle shadow below AppBar
      ),
      body: Column(
        children: [
          // Header with Title, Count, and Filter Icon
          _buildListHeader(
            'Total Payments',
            totalCount,
            context,
          ), // Using a more relevant title
          // Scrollable List of Payments
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0, // Add a little top padding for the first item
              ),
              itemCount: displayedList.length,
              itemBuilder:
                  (context, index) =>
                      PaymentSummaryListItem(payment: displayedList[index]),
            ),
          ),
        ],
      ),
      // Floating Action Button centered in the BottomAppBar notch
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to Add Payment Screen
          // Example:
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPaymentScreen()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add Payment Action (Not Implemented)'),
            ),
          );
        },
        backgroundColor: kPrimaryPurple,
        tooltip: 'Add Payment', // Accessibility
        elevation: 2.0,
        child: const Icon(
          Icons.add,
          color: kWhiteColor,
        ), // Standard FAB elevation
      ),
      // Bottom Navigation Bar docked with FAB
    );
  }

  // --- Widget Builders ---

  // Builds the header section above the list
  Widget _buildListHeader(String title, int count, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        12.0,
      ), // Padding around the header
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
              color: kAccentGreen.withAlpha(
                (0.2 * 255).toInt(),
              ), // Light green background
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
            icon: const Icon(Icons.filter_list, size: 24, color: kIconColor),
            tooltip: 'Filter Payments', // Accessibility
            onPressed: () {
              // TODO: Implement Filter/Sort Action
              // This could show a bottom sheet or dialog for filter options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter/Sort Action (Not Implemented)'),
                ),
              );
            },
            padding: EdgeInsets.zero, // Remove default padding
            constraints:
                const BoxConstraints(), // Remove default size constraints
          ),
        ],
      ),
    );
  }

  // Builds individual items for the Bottom Navigation Bar
}

// --- Separate Item Widget for Payment Summary List ---
class PaymentSummaryListItem extends StatelessWidget {
  final Map<String, dynamic> payment;

  const PaymentSummaryListItem({super.key, required this.payment});

  // Currency formatting helper
  String _formatCurrency(double amount) {
    // Using USD formatting, adjust locale/symbol as needed (e.g., 'en_IN', '₹')
    final format = NumberFormat.currency(
      locale: 'en_US', // Example locale
      symbol: '\$', // Example currency symbol
      decimalDigits: 0, // No decimal places shown as per design
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Safely access data with null checks and default values
    final String customerName = payment['customer'] as String? ?? 'N/A';
    final String logoUrl = payment['logoUrl'] as String? ?? '';
    final double amount = (payment['amount'] as num? ?? 0.0).toDouble();
    final String invoiceNo = payment['invoiceNo'] as String? ?? '-';
    final String date = payment['date'] as String? ?? '-';
    final String mode = payment['mode'] as String? ?? '-';


    return Card(
      elevation: 0.5, // Subtle shadow
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0), // Spacing between cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: kBorderColor.withAlpha(50),
        ), // Very subtle border alpha ~20%
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Payment Details Screen, passing the payment ID
          // Example:
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => PaymentDetailsScreen(paymentId: paymentId),
          //   ),
          // );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('View Details for $invoiceNo (Not Implemented)'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(
          10.0,
        ), // Match card's border radius for ripple effect
        child: Column(
          // No Padding here, handled internally by sections
          children: [
            // Top Section: Logo, Customer Info, Amount
            Padding(
              padding: const EdgeInsets.only(
                top: 12.0,
                left: 12.0,
                right: 12.0,
                bottom: 10.0,
              ), // Padding for top section
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .center, // Align items vertically centered
                children: [
                  // Logo Area
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      8.0,
                    ), // Rounded corners for logo container
                    child: Container(
                      width: 45,
                      height: 45,
                      padding: const EdgeInsets.all(4), // Padding around logo
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: kBorderColor.withAlpha((0.2 * 255).toInt()),
                        ), // Subtle border around logo area
                      ),
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.contain, // Fit logo within the container
                        // Placeholder while loading
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child; // Image loaded
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null, // Indeterminate progress if total size unknown
                              strokeWidth: 1.5,
                              color: kPrimaryPurple.withAlpha(
                                (0.2 * 255).toInt(),
                              ),
                            ),
                          );
                        },
                        // Placeholder if image fails to load
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: kLightGray.withAlpha(
                                (0.2 * 255).toInt(),
                              ), // Light background for placeholder icon
                              child: const Icon(
                                Icons
                                    .business_center_outlined, // Placeholder icon
                                size: 24,
                                color: kMutedTextColor,
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Customer Name Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center, // Center align text vertically if needed
                      children: [
                        const Text(
                          'Customer', // Static Label
                          style: TextStyle(
                            fontSize: 11,
                            color: kMutedTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis, // Prevent long names from breaking layout
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
                  Text(
                    _formatCurrency(amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            const Divider(
              height: 1,
              thickness: 0.5,
              color: kBorderColor,
            ), // Subtle divider line
            // Bottom Section: Details (Invoice No, Date, Mode)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ), // Consistent padding
              decoration: const BoxDecoration(
                color: kLightGray, // Light gray background for contrast
                borderRadius: BorderRadius.only(
                  // Round only bottom corners to match card shape
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Space out details
                children: [
                  _buildDetailItem(label: 'Invoice No', value: invoiceNo),
                  _buildDetailItem(label: 'Date', value: date),
                  _buildDetailItem(label: 'Mode of Payment', value: mode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for building the small detail items in the bottom section
  Widget _buildDetailItem({required String label, required String value}) {
    return Flexible(
      // Allows items to shrink/wrap if needed on smaller screens
      // No explicit flex factor needed if Flexible used mainly for preventing overflow
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4.0,
        ), // Add horizontal padding between items
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align text to the left
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: kMutedTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(
              height: 3,
            ), // Slightly more space between label and value
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600, // Semi-bold value
                color: kTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
