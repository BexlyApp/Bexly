// lib/screens/purchases_list_screen.dart (Example path)
import 'package:flutter/material.dart';

import 'add.dart';

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kErrorColor =
    Colors
        .red; // Used for potential error states, not directly in this list design
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

// --- Placeholder Navigation Targets ---
// import 'add_purchase_screen.dart'; // TODO: Create this screen
// import 'purchase_details_screen.dart'; // TODO: Create this screen

class PurchasesListScreen extends StatelessWidget {
  const PurchasesListScreen({super.key});

  // --- Placeholder Data ---
  final List<Map<String, dynamic>> allPurchasesData = const [
    {
      'id': '#CNV0021',
      'vendor': 'World Energy',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com',
    },
    {
      'id': '#CNV0022',
      'vendor': 'FedEX',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/fedex.com',
    },
    {
      'id': '#CNV0023',
      'vendor': 'Abbott',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/abbott.com',
    },
    {
      'id': '#CNV0024',
      'vendor': 'Whirlpool',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/whirlpool.com',
    },
    {
      'id': '#CNV0023',
      'vendor': 'Abbott',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/abbott.com',
    },
    {
      'id': '#CNV0024',
      'vendor': 'Whirlpool',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/whirlpool.com',
    },
    {
      'id': '#CNV0023',
      'vendor': 'Abbott',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/abbott.com',
    },
    {
      'id': '#CNV0024',
      'vendor': 'Whirlpool',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/whirlpool.com',
    },
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList =
        allPurchasesData; // Add filtering state if needed

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Purchases'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            onPressed: () {
              /* TODO: Search */
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _buildListHeader('Total Purchases', displayedList.length, context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0,
              ),
              itemCount: displayedList.length,
              itemBuilder:
                  (context, index) =>
                      PurchaseListItem(purchase: displayedList[index]),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to actual Add Purchase Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddSalesReturnScreen()),
          );
          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPurchaseScreen()));
        },
        backgroundColor: kPrimaryPurple,
        child: const Icon(Icons.add, color: kWhiteColor),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildListHeader(String title, int count, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kAccentGreen.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: kAccentGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildActionButton(
                icon: Icons.add,
                onTap: () {
                  // TODO: Navigate to actual Add Purchase Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddSalesReturnScreen()),
                  );

                  // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPurchaseScreen()));
                },
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.filter_list,
                onTap: () {
                  /* TODO: Filter Logic */
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimaryPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kWhiteColor, size: 18),
      ),
    );
  }
}

// --- Separate Item Widget ---
class PurchaseListItem extends StatelessWidget {
  final Map<String, dynamic> purchase;
  const PurchaseListItem({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    Color statusColor = kAccentGreen; // Default to Paid Green
    String statusText = purchase['status'] ?? 'Unknown';
    // Add more status cases if needed

    return Card(
      elevation: 0.5,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to actual Purchase Details Screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navigate to Purchase Details (Not Implemented)'),
            ),
          );
          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => PurchaseDetailsScreen(purchaseId: purchase['id'])));
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      purchase['logoUrl'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (ctx, err, st) => Container(
                            width: 40,
                            height: 40,
                            color: kLightGray,
                            child: const Icon(
                              Icons.business_center_outlined,
                              size: 20,
                              color: kMutedTextColor,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase['id'],
                          style: const TextStyle(
                            color: kPrimaryPurple,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          purchase['vendor'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Actions Row
                      _buildStatusTag(statusText, statusColor),
                      const SizedBox(width: 8),
                      _buildItemAction(
                        icon: Icons.edit_outlined,
                        onTap: () {
                          /* TODO: Edit Purchase */
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildItemAction(
                        icon: Icons.delete_outline,
                        onTap: () {
                          /* TODO: Delete Purchase */
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kLightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PurchaseDetailItem(
                      label: 'Amount',
                      value: '\$${purchase['amount'].toStringAsFixed(0)}',
                    ),
                    PurchaseDetailItem(
                      label: 'Mode of Payment',
                      value: purchase['mode'],
                    ),
                    PurchaseDetailItem(label: 'Date', value: purchase['date']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers specific to this list item ---
  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: kLightGray,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: kIconColor),
      ),
    );
  }
}

// --- Helper for bottom detail row ---
class PurchaseDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const PurchaseDetailItem({
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
        const SizedBox(height: 2),
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
}
