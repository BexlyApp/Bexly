// lib/screens/quotation_list_screen.dart (Example path)
import 'package:flutter/material.dart';

import 'add.dart';
import 'details.dart';

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50);
// const Color kErrorColor = Colors.red; // Not directly used in this list design
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

// --- Placeholder Navigation Targets ---

// import 'customer_details_screen.dart'; // If person icon navigates here

class QuotationListScreen extends StatelessWidget {
  // Use StatefulWidget for filtering/state
  const QuotationListScreen({super.key});

  // --- Placeholder Data ---
  final List<Map<String, dynamic>> allQuotationsData = const [
    {
      'id': 'QUO - 000015',
      'customer': 'BYD Groups',
      'phone': '+1 9754627382',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/byd.com',
    },
    {
      'id': 'QUO - 000014',
      'customer': 'World Energy',
      'phone': '+1 9754627528',
      'date': '21 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com',
    },
    {
      'id': 'QUO - 000013',
      'customer': 'FedEX',
      'phone': '+1 9754627386',
      'date': '12 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/fedex.com',
    },
    {
      'id': 'QUO - 000012',
      'customer': 'Abbott',
      'phone': '+1 9754627397',
      'date': '18 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/abbott.com',
    },
    {
      'id': 'QUO - 000011',
      'customer': 'Whirlpool',
      'phone': '+1 9754627399',
      'date': '15 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/whirlpool.com',
    }, // Example - not fully visible in screenshot
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList =
        allQuotationsData; // Add filtering state if needed

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quotation'),
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
          _buildListHeader('Total Quotations', displayedList.length, context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0,
              ),
              itemCount: displayedList.length,
              itemBuilder:
                  (context, index) =>
                      QuotationListItem(quotation: displayedList[index]),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddQuotationScreen()),
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
                      builder: (context) => const AddQuotationScreen(),
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
class QuotationListItem extends StatelessWidget {
  final Map<String, dynamic> quotation;
  const QuotationListItem({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
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
              builder: (context) => const QuotationDetailsScreen(),
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
                      quotation['logoUrl'],
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
                          quotation['customer'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone : ${quotation['phone']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: kMutedTextColor,
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
                      _buildItemAction(
                        icon: Icons.edit_outlined,
                        onTap: () {
                          /* TODO: Edit Quotation */
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildItemAction(
                        icon: Icons.delete_outline,
                        onTap: () {
                          /* TODO: Delete Quotation */
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildItemAction(
                        icon: Icons.person_outline,
                        onTap: () {
                          // TODO: Navigate to Customer Details?
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Navigate to Customer Details (Not Implemented)',
                              ),
                            ),
                          );
                          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerDetailsScreen(customerId: quotation['customerId']))); // Need customerId in data
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
                  color: kLightGray.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuotationDetailItem(
                      label: 'Quotation ID',
                      value: quotation['id'],
                    ),
                    QuotationDetailItem(
                      label: 'Created On',
                      value: quotation['date'],
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
class QuotationDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const QuotationDetailItem({
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
