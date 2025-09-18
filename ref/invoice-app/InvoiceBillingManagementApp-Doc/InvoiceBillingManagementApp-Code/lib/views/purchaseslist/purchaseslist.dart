// lib/screens/purchases_list_v2_screen.dart (Example path)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add.dart';
import 'details.dart'; // For currency formatting

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50);
// const Color kErrorColor = Colors.red; // Not used directly
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

// --- Placeholder Navigation Targets ---

// import 'vendor_details_screen.dart'; // If needed

class PurchasesListVScreen extends StatelessWidget {
  // Changed name
  const PurchasesListVScreen({super.key});

  // --- Placeholder Data ---
  final List<Map<String, dynamic>> allPurchasesData = const [
    {
      'id': '#PUR0019',
      'vendor': 'Emily',
      'status': 'Paid',
      'date': '15 Mar 2024',
      'amount': 1500.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZW1wbG95ZWUlMjBwcm9maWxlfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '#PUR0018',
      'vendor': 'Jerry',
      'status': 'Paid',
      'date': '10 Mar 2024',
      'amount': 1200.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    // Assuming the 3rd item uses a different ID type like Debit Note
    {
      'id': '#DEBIT-0007',
      'vendor': 'Peter',
      'status': 'Paid',
      'date': '',
      'amount': 900.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '#PUR0016',
      'vendor': 'Lisa',
      'status': 'Paid',
      'date': '27 Feb 2024',
      'amount': 1350.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    }, {
      'id': '#DEBIT-0007',
      'vendor': 'Peter',
      'status': 'Paid',
      'date': '',
      'amount': 900.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '#PUR0016',
      'vendor': 'Lisa',
      'status': 'Paid',
      'date': '27 Feb 2024',
      'amount': 1350.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    }, {
      'id': '#DEBIT-0007',
      'vendor': 'Peter',
      'status': 'Paid',
      'date': '',
      'amount': 900.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '#PUR0016',
      'vendor': 'Lisa',
      'status': 'Paid',
      'date': '27 Feb 2024',
      'amount': 1350.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    },
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList = allPurchasesData;

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
                  (context, index) => PurchaseListItemV2(
                    purchase: displayedList[index],
                  ), // Use new item widget
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddPurchaseScreen(),
              ),
            ),
        backgroundColor: kPrimaryPurple,
        child: const Icon(Icons.add, color: kWhiteColor),
      ),
    );
  }

  // --- Widget Builders ---


}

// --- Separate Item Widget (Version 2 based on new screenshot) ---
class PurchaseListItemV2 extends StatelessWidget {
  final Map<String, dynamic> purchase;
  const PurchaseListItemV2({super.key, required this.purchase});

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = kAccentGreen; // Default Paid
    String statusText = purchase['status'] ?? 'Unknown';
    // Add logic for other statuses if needed

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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PurchaseDetailsScreen(),
            ),
          ); // Pass ID later
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
                      purchase['imageUrl'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (ctx, err, st) => Container(
                            width: 40,
                            height: 40,
                            color: kLightGray,
                            child: const Icon(
                              Icons.person_outline,
                              size: 24,
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
                        ), // ID first
                        const SizedBox(height: 2),
                        Text(
                          purchase['vendor'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ), // Then Vendor Name
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Tag and More Options
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusTag(statusText, statusColor),
                      const SizedBox(height: 5),
                      const Icon(
                        Icons.more_vert,
                        color: kMutedTextColor,
                        size: 20,
                      ), // TODO: Make tappable
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
                  color: kLightGray.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PurchaseDetailItemV2(
                      label: 'Date',
                      value: purchase['date'],
                    ),
                    PurchaseDetailItemV2(
                      label: 'Amount',
                      value: _formatCurrency(purchase['amount']),
                    ),
                    PurchaseDetailItemV2(
                      label: 'Mode of Payment',
                      value: purchase['mode'],
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

  // --- Helpers specific to this list item ---
  Widget _buildStatusTag(String text, Color color) {
    // Reusable status tag
    return Container(/* ... same implementation ... */);
  }
}

// --- Helper for bottom detail row (Version 2) ---
class PurchaseDetailItemV2 extends StatelessWidget {
  final String label;
  final String value;
  const PurchaseDetailItemV2({
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

// --- Placeholder implementations for reused helpers ---
Widget _buildListHeader(String title, int count, BuildContext context) =>
    Padding(padding: const EdgeInsets.all(16), child: Text('$title ($count)'));

