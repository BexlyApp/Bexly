// lib/screens/purchase_order_list_screen.dart
// Renamed from purchases_list_v2_screen.dart to be more specific

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add.dart';
import 'details.dart';

// Import placeholder screens for navigation

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4); // Matches screenshots
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50); // For status tags if needed later
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

class PurchaseOrderListScreen extends StatelessWidget {
  // Changed name
  const PurchaseOrderListScreen({super.key});

  // --- Placeholder Data (Adjusted for Purchase Order List Screenshot) ---
  final List<Map<String, dynamic>> allPurchaseOrdersData = const [
    {
      'po_id': '#PO-0008', // Changed ID format
      'vendor': 'Emily',
      'date': '15 Mar 2024',
      'amount': 1500.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZW1wbG95ZWUlMjBwcm9maWxlfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
    },
    {
      'po_id': '#PO-0007',
      'vendor': 'Jerry',
      'date': '10 Mar 2024',
      'amount': 1200.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'po_id': '#PO-0006',
      'vendor': 'Peter',
      'date': '05 Mar 2024', // Added date based on screenshot pattern
      'amount': 900.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      // Assuming the ID #361039 is also a PO ID for consistency
      'po_id': '#361039',
      'vendor': 'Lisa',
      'date': '27 Feb 2024',
      'amount': 1350.0, // Adjusted amount slightly if needed
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    },{
      'po_id': '#PO-0007',
      'vendor': 'Jerry',
      'date': '10 Mar 2024',
      'amount': 1200.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'po_id': '#PO-0006',
      'vendor': 'Peter',
      'date': '05 Mar 2024', // Added date based on screenshot pattern
      'amount': 900.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      // Assuming the ID #361039 is also a PO ID for consistency
      'po_id': '#361039',
      'vendor': 'Lisa',
      'date': '27 Feb 2024',
      'amount': 1350.0, // Adjusted amount slightly if needed
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    },
    // Add more items if needed to test scrolling
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList = allPurchaseOrdersData;
    final int totalCount = displayedList.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: kTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          // Changed title to match screenshot
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Purchase Order'),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kLightGray, // Background color for the count
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                totalCount.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kTextColor, // Text color for the count
                ),
              ),
            ),
          ],
        ),
        centerTitle: true, // Keep centered if desired
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26, color: kTextColor),
            onPressed: () {
              /* TODO: Search Implementation */
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search Action (Not Implemented)'),
                ),
              );
            },
          ),
          IconButton(
            // Added Filter/Sort Icon
            icon: const Icon(
              Icons.tune_outlined,
              size: 24,
              color: kTextColor,
            ), // Or Icons.filter_list
            onPressed: () {
              /* TODO: Filter/Sort Implementation */
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter/Sort Action (Not Implemented)'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor, // Default text color for AppBar
        elevation: 0.5,
      ),
      body: ListView.builder(
        // Removed Column and Header Widget
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0, // Add some top padding
        ),
        itemCount: displayedList.length,
        itemBuilder:
            (context, index) => PurchaseOrderListItem(
              // Use renamed item widget
              purchaseOrder: displayedList[index],
            ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        const AddPurchaseOrderScreen(), // Navigate to Add Purchase Order screen
              ),
            ),
        backgroundColor: kPrimaryPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ), // Make it circular
        elevation: 2.0,
        child: const Icon(Icons.add, color: kWhiteColor), // Add slight elevation
      ),
    );
  }
}

// --- Separate Item Widget (Adapted for Purchase Order List Screenshot) ---
class PurchaseOrderListItem extends StatelessWidget {
  final Map<String, dynamic> purchaseOrder;
  const PurchaseOrderListItem({super.key, required this.purchaseOrder});

  // Helper to format currency consistently
  String _formatCurrency(double amount) {
    // Using '$' symbol and no decimal places as per screenshot
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Determine tap target based on data (e.g., navigate to details)
    // Using DebitNoteDetailsScreen as the target based on the first screenshot provided
    // You might need logic here if different IDs go to different detail screens
    detailScreenBuilder(context) => const DebitNoteDetailsScreen(); // Default navigation

    return Card(
      elevation: 0.5, // Subtle shadow
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        // Keep subtle border if desired, matching the provided code
        // side: BorderSide(color: kBorderColor.withAlpha((0.1 * 255).toInt())),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: detailScreenBuilder,
            ), // Pass ID later if needed
          );
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Top Row: Image, Vendor/ID, More Icon
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align items to top
                children: [
                  // Vendor Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      8.0,
                    ), // Rounded corners for image
                    child: Image.network(
                      purchaseOrder['imageUrl'],
                      width: 45, // Slightly larger image
                      height: 45,
                      fit: BoxFit.cover,
                      // Error handling for image loading
                      errorBuilder:
                          (ctx, err, st) => Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: kLightGray,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 24,
                              color: kMutedTextColor,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Vendor Name and PO ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 4,
                        ), // Adjust vertical alignment slightly
                        Text(
                          purchaseOrder['vendor'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 4), // Space between name and ID
                        Text(
                          'Vendor', // Label as per screenshot
                          style: const TextStyle(
                            color: kMutedTextColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // More Options Icon
                  // TODO: Implement Popup Menu or Action Sheet
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: kMutedTextColor,
                      size: 22,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('More Actions (Not Implemented)'),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12), // Space before bottom details
              // Bottom Row: Details in a light gray container
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, // Adjust padding
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  // Use a very light gray, almost white, or kLightGray with alpha
                  color: kLightGray.withAlpha((0.2 * 255).toInt()), // Lighter gray background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Use the detail item widget
                    ListItemDetailItem(
                      // Renamed for clarity potentially
                      label: 'Purchase Order ID', // Label from screenshot
                      value: purchaseOrder['po_id'], // Use po_id key
                    ),
                    ListItemDetailItem(
                      label: 'Amount',
                      value: _formatCurrency(
                        purchaseOrder['amount'],
                      ), // Format amount
                    ),
                    ListItemDetailItem(
                      label: 'Date',
                      value: purchaseOrder['date'], // Use date key
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper for bottom detail row in the list item ---
class ListItemDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const ListItemDetailItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kMutedTextColor),
        ),
        const SizedBox(height: 3), // Reduced space
        Text(
          value,
          style: const TextStyle(
            fontSize: 13, // Slightly larger value text
            fontWeight: FontWeight.w600, // Bold value
            color: kTextColor,
          ),
        ),
      ],
    );
  }
}
