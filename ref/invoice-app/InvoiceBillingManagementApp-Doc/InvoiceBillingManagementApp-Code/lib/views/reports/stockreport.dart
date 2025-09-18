// lib/screens/stock_report_screen.dart
import 'package:flutter/material.dart';

// --- Placeholder Navigation Targets ---
// Assume AddStockScreen exists if "+" button were present and functional
// import 'add_stock_screen.dart';
// Assume StockDetailsScreen exists if items were tappable for details
// import 'stock_details_screen.dart';

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
const Color kCategoryBadgeBg = Color(
  0xFFFFF3E0,
); // Light orange/peach background
const Color kCategoryBadgeText = Color(0xFFE65100); // Darker orange text
// --- End Color Definitions ---

class StockReportScreen extends StatelessWidget {
  // Changed to StatelessWidget
  const StockReportScreen({super.key});

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic (e.g., from API filtered by date range)
  final List<Map<String, dynamic>> stockData = const [
    {
      'id': '#P125390',
      'name': 'Beats Pro',
      'imageUrl':
          'https://img.icons8.com/fluency/96/headphones.png', // From previous
      'category': 'Electronics',
      'openingQty': 0,
      'qtyIn': 12,
      'qtyOut': 4,
      'closingQty': 8, // 0 + 12 - 4 = 8 (Matches)
    },
    {
      'id': '#P125389',
      'name': 'Nike Jordan',
      'imageUrl':
          'https://img.icons8.com/color/96/trainers.png', // From previous
      'category': 'Shoes',
      'openingQty': 0,
      'qtyIn': 15,
      'qtyOut': 6,
      'closingQty': 9, // 0 + 15 - 6 = 9 (Matches)
    },
    {
      'id': '#P125391',
      'name': 'Iphone 14 pro',
      'imageUrl':
          'https://img.icons8.com/fluency/96/iphone14-pro.png', // From previous
      'category': 'Mobile Phones',
      'openingQty': 0,
      'qtyIn': 12,
      'qtyOut': 6,
      'closingQty': 6, // 0 + 12 - 6 = 6 (Matches)
    },
    {
      'id': '#P125393',
      'name': 'Woodcraft Sandal',
      'imageUrl':
          'https://img.icons8.com/color/96/backpack.png', // From previous
      'category': 'Nike', // Brand?
      'openingQty': 0, // Value cut off, assuming 0
      'qtyIn': 25, // Value cut off, assuming 25
      'qtyOut': 5, // Value cut off, assuming 5
      'closingQty': 20, // Value cut off, assuming 20 (0+25-5=20)
    },
    {
      'id': '#P125390',
      'name': 'Beats Pro',
      'imageUrl':
          'https://img.icons8.com/fluency/96/headphones.png', // From previous
      'category': 'Electronics',
      'openingQty': 0,
      'qtyIn': 12,
      'qtyOut': 4,
      'closingQty': 8, // 0 + 12 - 4 = 8 (Matches)
    },
    {
      'id': '#P125389',
      'name': 'Nike Jordan',
      'imageUrl':
          'https://img.icons8.com/color/96/trainers.png', // From previous
      'category': 'Shoes',
      'openingQty': 0,
      'qtyIn': 15,
      'qtyOut': 6,
      'closingQty': 9, // 0 + 15 - 6 = 9 (Matches)
    },
    {
      'id': '#P125391',
      'name': 'Iphone 14 pro',
      'imageUrl':
          'https://img.icons8.com/fluency/96/iphone14-pro.png', // From previous
      'category': 'Mobile Phones',
      'openingQty': 0,
      'qtyIn': 12,
      'qtyOut': 6,
      'closingQty': 6, // 0 + 12 - 6 = 6 (Matches)
    },
    {
      'id': '#P125393',
      'name': 'Woodcraft Sandal',
      'imageUrl':
          'https://img.icons8.com/color/96/backpack.png', // From previous
      'category': 'Nike', // Brand?
      'openingQty': 0, // Value cut off, assuming 0
      'qtyIn': 25, // Value cut off, assuming 25
      'qtyOut': 5, // Value cut off, assuming 5
      'closingQty': 20, // Value cut off, assuming 20 (0+25-5=20)
    },
    // Add more items if needed
  ];
  // --- End Placeholder Data ---

  // Optional: Formatter for quantities if needed later
  // String _formatQuantity(int qty) => NumberFormat.decimalPattern().format(qty);

  @override
  Widget build(BuildContext context) {
    final int totalCount = stockData.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Stock Report'), // Updated Title
        centerTitle: true, // Title is centered in the image
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search Stock',
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
              'Stocks by Last 30 Days', // Title from image
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semi-bold
                color: kTextColor.withAlpha((0.2 * 255).toInt()),
              ),
            ),
          ),

          // Total Stocks Row
          _buildListHeader('Total Stocks', totalCount, context),

          // Stock List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              itemCount: stockData.length,
              itemBuilder: (context, index) {
                return StockListItem(
                  // Use specific list item widget
                  stock: stockData[index],
                  // formatQuantity: _formatQuantity, // Pass formatter if needed
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
            tooltip: 'Filter Stock', // Accessibility
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
} // End StockReportScreen

// --- Separate Widget for Stock List Item ---
class StockListItem extends StatelessWidget {
  final Map<String, dynamic> stock;
  // final Function(int) formatQuantity; // Pass formatter if needed

  const StockListItem({
    super.key,
    required this.stock,
    // required this.formatQuantity,
  });

  @override
  Widget build(BuildContext context) {
    // Safely access data
    final String id = stock['id'] ?? 'N/A';
    final String name = stock['name'] ?? 'N/A';
    final String imageUrl = stock['imageUrl'] ?? '';
    final String category = stock['category'] ?? '';
    final int openingQty = (stock['openingQty'] as num? ?? 0).toInt();
    final int qtyIn = (stock['qtyIn'] as num? ?? 0).toInt();
    final int qtyOut = (stock['qtyOut'] as num? ?? 0).toInt();
    final int closingQty = (stock['closingQty'] as num? ?? 0).toInt();

    return Card(
      elevation: 1.0,
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        // Add padding around the entire card content
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Top Row: Image, ID/Name, Category Badge
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
                // Category Badge
                if (category.isNotEmpty) // Show badge only if category exists
                  _buildCategoryBadge(category),
              ],
            ),
            const SizedBox(height: 10),

            // Dashed Divider
            _buildDashedDivider(),
            const SizedBox(height: 10),

            // Bottom Row: Quantities
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Distribute space evenly
              children: [
                _buildDetailColumn(
                  'Opening Qty',
                  openingQty.toString(),
                ), // Convert int to String
                _buildDetailColumn('Qty In', qtyIn.toString()),
                _buildDetailColumn('Qty Out', qtyOut.toString()),
                _buildDetailColumn(
                  'Closing Qty',
                  closingQty.toString(),
                  alignment: CrossAxisAlignment.end,
                ), // Align last item right
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for detail columns in list item bottom section
  Widget _buildDetailColumn(
    String label,
    String value, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Flexible(
      // Use flexible to allow columns to adjust width
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2.0,
        ), // Minimal padding between columns
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

  // Helper for Category Badge (same as Sales Return)
  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kCategoryBadgeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 11,
          color: kCategoryBadgeText,
          fontWeight: FontWeight.w500,
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
} // End StockListItem
