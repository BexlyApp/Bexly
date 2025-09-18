// lib/screens/credit_notes_list_screen.dart (Example path)
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
const Color kAccentGreen = Color(0xFF4CAF50); // Paid status
const Color kErrorColor = Colors.red; // Overdue/Unpaid status
const Color kWarningColor = Colors.orange; // Sent/Partially Paid status
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

// --- Placeholder Navigation Targets ---

// import 'vendor_details_screen.dart'; // If needed for vendor info

class CreditNotesListScreen extends StatelessWidget {
  const CreditNotesListScreen({super.key});

  // --- Placeholder Data ---
  final List<Map<String, dynamic>> allCreditNotesData = const [
    {
      'id': '#CN - 4567',
      'vendor': 'BYD Groups',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZW1wbG95ZWUlMjBwcm9maWxlfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '#CN - 9876',
      'vendor': 'World Energy',
      'status': 'Sent',
      'amount': 564.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '#CN - 2345',
      'vendor': 'FedEX',
      'status': 'Partially Paid',
      'amount': 874.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '#CN - 0987',
      'vendor': 'Abbott',
      'status': 'Overdue',
      'amount': 324.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '#CN - 5555',
      'vendor': 'Whirlpool',
      'status': 'Unpaid',
      'amount': 150.0,
      'mode': 'Cash',
      'imageUrl':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8cHJvZmlsZSUyMHBob3RvfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
    },
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList =
        allCreditNotesData; // Add filtering state if needed

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Credit Notes'),
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
          _buildListHeader('Total Credit Notes', displayedList.length, context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0,
              ),
              itemCount: displayedList.length,
              itemBuilder:
                  (context, index) =>
                      CreditNoteListItem(creditNote: displayedList[index]),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCreditNoteScreen(),
            ),
          );
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddCreditNoteScreen(),
                    ),
                  );
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
class CreditNoteListItem extends StatelessWidget {
  final Map<String, dynamic> creditNote;
  const CreditNoteListItem({super.key, required this.creditNote});

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
    Color statusColor;
    String statusText = creditNote['status'] ?? 'Unknown';

    switch (statusText) {
      case 'Sent':
        statusColor = kWarningColor;
        break;
      case 'Overdue':
        statusColor = kErrorColor;
        break;
      case 'Partially Paid':
        statusColor = kWarningColor;
        break;
      case 'Unpaid':
        statusColor = kErrorColor;
        break; // Using red for Unpaid
      case 'Paid':
      default:
        statusColor = kAccentGreen;
        break;
    }

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
              builder: (context) => const CreditNotesDetailsScreen(),
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
                      creditNote['imageUrl'],
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
                        ), // Label added
                        const SizedBox(height: 2),
                        Text(
                          creditNote['vendor'],
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
                    CreditNoteDetailItem(
                      label: 'Credit Notes ID',
                      value: creditNote['id'],
                    ),
                    CreditNoteDetailItem(
                      label: 'Amount',
                      value: _formatCurrency(creditNote['amount']),
                    ),
                    CreditNoteDetailItem(
                      label: 'Mode of Payment',
                      value: creditNote['mode'],
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
}

// --- Helper for bottom detail row ---
class CreditNoteDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const CreditNoteDetailItem({
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
