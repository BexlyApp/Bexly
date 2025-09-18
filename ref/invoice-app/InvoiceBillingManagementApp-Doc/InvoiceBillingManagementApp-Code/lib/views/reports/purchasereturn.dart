// lib/screens/purchase_return_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Placeholder Navigation Targets ---
// Assume AddPurchaseReturnScreen exists if "+" button were present and functional
// import 'add_purchase_return_screen.dart';
// Assume PurchaseReturnDetailsScreen exists if items were tappable for details
// import 'purchase_return_details_screen.dart';

// --- Define Colors (Consider moving to a central theme file) ---
const Color kPrimaryPurple = Color(0xFF6A00F4); // Kept for potential future use
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;
const Color kAccentGreen = Color(0xFF4CAF50); // For the count badge
const Color kProductIdColor = kPrimaryPurple; // Color for product ID text
// --- End Color Definitions ---

class PurchaseReturnReportScreen extends StatelessWidget {
  // Changed to StatelessWidget
  const PurchaseReturnReportScreen({super.key});

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic (e.g., from API filtered by date range)
  final List<Map<String, dynamic>> purchaseReturnData = const [
    {
      'id': '#P125390',
      'name': 'Beats Pro',
      'imageUrl': 'https://img.icons8.com/fluency/96/headphones.png',
      'price': 1100.0,
      'purchaseQty': 10, // Assuming this is Return Qty for this screen
      'instockQty':
          10, // Maybe original Instock or remaining after return? Label unclear.
      'dueDate':
          '15 Mar 2024', // Label seems wrong for return report, maybe Return Date? Using label from image.
    },
    {
      'id': '#P125389',
      'name': 'Nike Jordan',
      'imageUrl': 'https://img.icons8.com/color/96/trainers.png',
      'price': 1200.0,
      'purchaseQty': 15, // Return Qty
      'instockQty': 12,
      'dueDate': '10 Mar 2024', // Return Date?
    },
    {
      'id': '#P125391',
      'name': 'Iphone 14 pro',
      'imageUrl': 'https://img.icons8.com/fluency/96/iphone14-pro.png',
      'price': 1450.0,
      'purchaseQty': 15, // Return Qty
      'instockQty': 30,
      'dueDate': '27 Feb 2024', // Return Date?
    },
    {
      'id': '#P125393',
      'name': 'Woodcraft Sandal',
      'imageUrl': 'https://img.icons8.com/color/96/backpack.png',
      'price': 248.0,
      'purchaseQty': 20, // Return Qty
      'instockQty': 25,
      'dueDate': '18 Feb 2024', // Example Return Date
    },{
      'id': '#P125389',
      'name': 'Nike Jordan',
      'imageUrl': 'https://img.icons8.com/color/96/trainers.png',
      'price': 1200.0,
      'purchaseQty': 15, // Return Qty
      'instockQty': 12,
      'dueDate': '10 Mar 2024', // Return Date?
    },
    {
      'id': '#P125391',
      'name': 'Iphone 14 pro',
      'imageUrl': 'https://img.icons8.com/fluency/96/iphone14-pro.png',
      'price': 1450.0,
      'purchaseQty': 15, // Return Qty
      'instockQty': 30,
      'dueDate': '27 Feb 2024', // Return Date?
    },
    {
      'id': '#P125393',
      'name': 'Woodcraft Sandal',
      'imageUrl': 'https://img.icons8.com/color/96/backpack.png',
      'price': 248.0,
      'purchaseQty': 20, // Return Qty
      'instockQty': 25,
      'dueDate': '18 Feb 2024', // Example Return Date
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
    // Title in the list header should reflect the screen context
    final String listTitle = 'Total Returns'; // Or 'Total Purchase Returns'
    final int totalCount = purchaseReturnData.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Purchase Return Report'), // Updated Title
        centerTitle: true, // Title is centered in the image
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search Returns',
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
            // Title could be more specific, e.g., "Returns in Last 30 Days"
            child: Text(
              'Purchases by Last 30 Days', // Title from image (might need adjustment for returns context)
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semi-bold
                color: kTextColor.withAlpha((0.2 * 255).toInt()),
              ),
            ),
          ),

          // Total Purchase Row (Adjust title if needed)
          _buildListHeader(listTitle, totalCount, context),

          // Purchase Return List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              itemCount: purchaseReturnData.length,
              itemBuilder: (context, index) {
                return PurchaseReturnListItem(
                  // Use specific list item widget
                  purchaseReturn: purchaseReturnData[index],
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
            icon: const Icon(
              Icons.filter_list_alt,
              size: 24,
              color: kIconColor,
            ),
            tooltip: 'Filter Returns', // Accessibility
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
} // End PurchaseReturnReportScreen

// --- Separate Widget for Purchase Return List Item ---
class PurchaseReturnListItem extends StatelessWidget {
  final Map<String, dynamic> purchaseReturn;
  final Function(double) formatCurrency; // Pass formatter

  const PurchaseReturnListItem({
    super.key,
    required this.purchaseReturn,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    // Safely access data
    final String id = purchaseReturn['id'] ?? 'N/A';
    final String name = purchaseReturn['name'] ?? 'N/A';
    final String imageUrl =
        purchaseReturn['imageUrl'] ?? ''; // Handle missing URL
    final double price = (purchaseReturn['price'] as num? ?? 0.0).toDouble();
    final int purchaseQty =
        (purchaseReturn['purchaseQty'] as num? ?? 0)
            .toInt(); // Assuming Return Qty
    final int instockQty = (purchaseReturn['instockQty'] as num? ?? 0).toInt();
    final String dueDate =
        purchaseReturn['dueDate'] ?? '-'; // Assuming Return Date

    return Card(
      elevation: 1.0,
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 9.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Top Row: Image, ID/Name, Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: kLightGray.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child:
                          imageUrl.isNotEmpty
                              ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
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
                                      color: kPrimaryPurple.withAlpha(
                                        (0.2 * 255).toInt(),
                                      ),
                                    ),
                                  );
                                },
                              )
                              : const Icon(
                                Icons.inventory_2_outlined,
                                size: 24,
                                color: kMutedTextColor,
                              ),
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
                          fontSize: 12,
                          color: kProductIdColor,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Price (assuming price of returned item)
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
            const SizedBox(height: 10),

            // Dashed Divider
            _buildDashedDivider(),
            const SizedBox(height: 10),

            // Bottom Row: Purchase Qty, Instock Qty, Due Date (Return Date?)
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Distribute space
              children: [
                _buildDetailColumn(
                  'Purchase Qty',
                  purchaseQty.toString(),
                ), // Or Return Qty
                _buildDetailColumn('Instock Qty', instockQty.toString()),
                _buildDetailColumn(
                  'Due Date',
                  dueDate,
                  alignment: CrossAxisAlignment.end,
                ), // Or Return Date
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for detail columns in list item (New for this layout)
  Widget _buildDetailColumn(
    String label,
    String value, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kMutedTextColor),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextColor,
          ),
        ),
      ],
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
} // End PurchaseReturnListItem
