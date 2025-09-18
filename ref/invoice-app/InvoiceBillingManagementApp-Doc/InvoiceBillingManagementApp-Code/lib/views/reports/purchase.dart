// lib/screens/purchase_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Placeholder Navigation Targets ---
// Assume AddPurchaseScreen exists if "+" button is functional
// import 'add_purchase_screen.dart';
// Assume PurchaseDetailsScreen exists if items were tappable for details
// import 'purchase_details_screen.dart';
// Assume other screens exist for bottom nav
// import 'home_screen.dart';
// import 'invoice_list_screen.dart'; // Or relevant screen for 'Invoices'
// import 'settings_screen.dart';

// --- Define Colors (Consider moving to a central theme file) ---
const Color kPrimaryPurple = Color(0xFF6A00F4); // Used in FAB/Nav
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;
const Color kAccentGreen = Color(0xFF4CAF50); // For the count badge
const Color kProductIdColor = kPrimaryPurple; // Color for product ID text
// --- End Color Definitions ---

class PurchaseReportScreen extends StatefulWidget {
  // Changed to StatefulWidget for BottomNavBar
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  // Added State class

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic (e.g., from API filtered by date range)
  // ***** IMAGE URLs UPDATED HERE *****
  final List<Map<String, dynamic>> purchaseData = const [
    {
      'id': '#P125390',
      'name': 'Beats Pro',
      'imageUrl':
          'https://img.icons8.com/fluency/96/headphones.png', // Updated URL
      'price': 1100.0,
      'purchaseQty': 10,
      'instockQty': 10,
    },
    {
      'id': '#P125389',
      'name': 'Nike Jordan',
      'imageUrl': 'https://img.icons8.com/color/96/trainers.png', // Updated URL
      'price': 1200.0,
      'purchaseQty': 15,
      'instockQty': 12,
    },
    {
      'id': '#P125391',
      'name': 'Iphone 14 pro',
      'imageUrl':
          'https://img.icons8.com/fluency/96/iphone14-pro.png', // Updated URL
      'price': 1450.0,
      'purchaseQty': 15,
      'instockQty': 30,
    },
    {
      'id': '#P125393',
      'name':
          'Woodcraft Sandal', // Name from original image ( Backpack icon provided though)
      'imageUrl': 'https://img.icons8.com/color/96/backpack.png', // Updated URL
      'price': 248.0,
      'purchaseQty': 20,
      'instockQty': 25,
    },
    {
      'id': '#P125392',
      'name':
          'Amazon Echo Dot', // Name from original image (iPhone icon provided though)
      'imageUrl':
          'https://img.icons8.com/fluency/96/iphone14-pro.png', // Updated URL (Using 5th URL)
      'price': 1200.0,
      'purchaseQty': 8, // Example different qty
      'instockQty': 12,
    },
    // Add more items here if you want to use the rest of the URLs
    // {
    //   'id': '#P125394',
    //   'name': 'Samsung Product', // Example Name
    //   'imageUrl': 'https://img.icons8.com/fluency/96/samsung.png', // 6th URL
    //   'price': 999.0,
    //   'purchaseQty': 5,
    //   'instockQty': 5,
    // },
    // ... and so on for the remaining URLs
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
    final int totalCount = purchaseData.length; // Get count from data

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Purchase Report'),
        centerTitle: true, // Title is centered in the image
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search Purchases',
            onPressed: () {
              // TODO: Implement Search Functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search Action (Not Implemented)'),
                ),
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
              'Purchases by Last 30 Days', // Title from image
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semi-bold
                color: kTextColor.withAlpha((0.2 * 255).toInt()),
              ),
            ),
          ),

          // Total Purchase Row
          _buildListHeader('Total Purchase', totalCount, context),

          // Purchase List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              itemCount: purchaseData.length,
              itemBuilder: (context, index) {
                return PurchaseListItem(
                  purchase: purchaseData[index],
                  formatCurrency: _formatCurrency,
                );
              },
            ),
          ),
        ],
      ),
      // --- FloatingActionButton and BottomNavigationBar ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to Add Purchase Screen or relevant action
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPurchaseScreen()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Action (Not Implemented)')),
          );
        },
        backgroundColor: kPrimaryPurple,
        tooltip: 'Add Purchase', // Adjust tooltip as needed
        elevation: 2.0,
        child: const Icon(Icons.add, color: kWhiteColor),
      ),
    );
  }

  // Builds the header section above the list (Total Purchase + Filter)
  Widget _buildListHeader(String title, int count, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        4.0,
        16.0,
        12.0,
      ), // Adjust padding
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
            // Use Icons.filter_list_alt to match the image better
            icon: const Icon(
              Icons.filter_list_alt,
              size: 24,
              color: kIconColor,
            ),
            tooltip: 'Filter Purchases', // Accessibility
            onPressed: () {
              // TODO: Implement Filter/Sort Action
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

  // --- Helper for Bottom Navigation Items ---
} // End _PurchaseReportScreenState

// --- Separate Widget for Purchase List Item ---
// (Code remains the same, uses the updated imageUrl from purchaseData)
class PurchaseListItem extends StatelessWidget {
  final Map<String, dynamic> purchase;
  final Function(double) formatCurrency; // Pass formatter

  const PurchaseListItem({
    super.key,
    required this.purchase,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    // Safely access data
    final String id = purchase['id'] ?? 'N/A';
    final String name = purchase['name'] ?? 'N/A';
    final String imageUrl = purchase['imageUrl'] ?? ''; // Handle missing URL
    final double price = (purchase['price'] as num? ?? 0.0).toDouble();
    final int purchaseQty = (purchase['purchaseQty'] as num? ?? 0).toInt();
    final int instockQty = (purchase['instockQty'] as num? ?? 0).toInt();

    return Card(
      elevation: 1.0,
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Top Row: Image, ID/Name, Price
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start, // Align top for image and text columns
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: 50, // Slightly larger image container
                    height: 50,
                    decoration: BoxDecoration(
                      color: kLightGray.withAlpha(
                        (0.2 * 255).toInt(),
                      ), // Background for image area
                      borderRadius: BorderRadius.circular(8.0),
                      // border: Border.all(color: kBorderColor.withOpacity(0.5)) // Optional border
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        5.0,
                      ), // Padding inside the container
                      child:
                          imageUrl.isNotEmpty
                              ? Image.network(
                                // Use Image.network only if URL is present
                                imageUrl,
                                fit: BoxFit.contain, // Fit image within padding
                                errorBuilder:
                                    (ctx, err, st) => const Icon(
                                      Icons.broken_image_outlined,
                                      size: 24,
                                      color: kMutedTextColor,
                                    ),
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      strokeWidth: 1.5,
                                      color: kPrimaryPurple.withAlpha((0.2 * 255).toInt()),
                                    ),
                                  );
                                },
                              )
                              : const Icon(
                                Icons.inventory_2_outlined,
                                size: 24,
                                color: kMutedTextColor,
                              ), // Placeholder if no URL
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // ID & Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id,
                        style: const TextStyle(
                          fontSize: 12, // Smaller size for ID
                          color: kProductIdColor, // Specific color for ID
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                        maxLines: 1, // Prevent wrapping for name
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Price
                Text(
                  formatCurrency(price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Space before divider line
            // Dashed Divider
            _buildDashedDivider(),
            const SizedBox(height: 10), // Space after divider line
            // Bottom Row: Purchase Qty, Instock Qty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Purchase Quantity : $purchaseQty',
                  style: const TextStyle(fontSize: 13, color: kMutedTextColor),
                ),
                Text(
                  'Instock Quantity : $instockQty',
                  style: const TextStyle(fontSize: 13, color: kMutedTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to create a simple dashed/dotted line effect (same as Income Report)
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
} // End PurchaseListItem
