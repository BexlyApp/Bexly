// lib/screens/purchase_return_list_screen.dart (Example path)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add.dart';
import 'detials.dart'; // For currency formatting

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

// --- Placeholder Navigation Targets ---

class PurchaseReturnListScreen extends StatelessWidget {
  const PurchaseReturnListScreen({super.key});

  // --- Placeholder Data ---
  final List<Map<String, dynamic>> allReturnsData = const [
    {
      'po_id': '#DEBIT-0009',
      'vendor': 'Emily',
      'amount': 1500.0,
      'date': '15 Mar 2024',
      'imageUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZW1wbG95ZWUlMjBwcm9maWxlfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
    },
    {
      'po_id': '#DEBIT-0008',
      'vendor': 'Jerry',
      'amount': 1200.0,
      'date': '10 Mar 2024',
      'imageUrl':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'po_id': '#PO-0006',
      'vendor': 'Peter',
      'amount': 900.0,
      'date': '#DEBIT-0007',
      'imageUrl':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    }, // Date looks like an ID in screenshot? Using as is.
    {
      'po_id': '#DEBIT-0006',
      'vendor': 'Lisa',
      'amount': 1350.0,
      'date': '27 Feb 2024',
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    },  {
      'po_id': '#DEBIT-0009',
      'vendor': 'Emily',
      'amount': 1500.0,
      'date': '15 Mar 2024',
      'imageUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZW1wbG95ZWUlMjBwcm9maWxlfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
    },
    {
      'po_id': '#DEBIT-0008',
      'vendor': 'Jerry',
      'amount': 1200.0,
      'date': '10 Mar 2024',
      'imageUrl':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'po_id': '#PO-0006',
      'vendor': 'Peter',
      'amount': 900.0,
      'date': '#DEBIT-0007',
      'imageUrl':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    }, // Date looks like an ID in screenshot? Using as is.
    {
      'po_id': '#DEBIT-0006',
      'vendor': 'Lisa',
      'amount': 1350.0,
      'date': '27 Feb 2024',
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    },
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList =
        allReturnsData; // Add filtering state if needed

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Purchase Return'),
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
          _buildListHeader(
            'Total Purchase Return',
            displayedList.length,
            context,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0,
              ),
              itemCount: displayedList.length,
              itemBuilder:
                  (context, index) =>
                      PurchaseReturnListItem(returnData: displayedList[index]),
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
                builder: (context) => const AddPurchaseReturnScreen(),
              ),
            ),
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
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPurchaseReturnScreen(),
                      ),
                    ),
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
    // Reusing previous button style
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
class PurchaseReturnListItem extends StatelessWidget {
  final Map<String, dynamic> returnData;
  const PurchaseReturnListItem({super.key, required this.returnData});

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
    return Card(
      color: Colors.white,
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
      ),
      child: InkWell(
        onTap: () {
          // Assuming details are viewed in Debit Notes screen based on screenshot
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DebitNotesDetailsScreen(),
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
                      returnData['imageUrl'],
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
                          'Vendor',
                          style: const TextStyle(
                            fontSize: 11,
                            color: kMutedTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          returnData['vendor'],
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
                  // Actions Row: Edit, Delete, Duplicate/Copy
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildItemAction(
                        icon: Icons.edit_outlined,
                        onTap: () {
                          /* TODO: Edit Purchase Return */
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildItemAction(
                        icon: Icons.delete_outline,
                        onTap: () {
                          /* TODO: Delete Purchase Return */
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildItemAction(
                        icon: Icons.copy_outlined,
                        onTap: () {
                          /* TODO: Duplicate Purchase Return */
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dashed line separator (Visual approximation) - Optional
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    const dashWidth = 4.0;
                    const dashSpace = 3.0;
                    final dashCount =
                        (constraints.constrainWidth() / (dashWidth + dashSpace))
                            .floor();
                    return Flex(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      direction: Axis.horizontal,
                      children: List.generate(
                        dashCount,
                        (_) => const SizedBox(
                          width: dashWidth,
                          height: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: kBorderColor),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PurchaseReturnDetailItem(
                      label: 'Purchase Order ID',
                      value: returnData['po_id'],
                    ),
                    PurchaseReturnDetailItem(
                      label: 'Amount',
                      value: _formatCurrency(returnData['amount']),
                    ),
                    PurchaseReturnDetailItem(
                      label: 'Date',
                      value: returnData['date'],
                    ), // Shows Debit Note ID in one case?
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
class PurchaseReturnDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const PurchaseReturnDetailItem({
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
        const SizedBox(height: 4),
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
