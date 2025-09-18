// lib/screens/payments_list_screen.dart (Example path)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting

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
// import 'add_payment_screen.dart'; // TODO: Create this screen
// import 'payment_details_screen.dart'; // TODO: Create this screen
// import 'customer_details_screen.dart'; // If logo/name navigates here

class PaymentsListScreen extends StatelessWidget {
  const PaymentsListScreen({super.key});

  // --- Placeholder Data ---
  final List<Map<String, dynamic>> allPaymentsData = const [
    {
      'customer': 'BYD Groups',
      'phone': '+1 9754627382',
      'amount': 1400.0,
      'date': '23 Apr 2024',
      'payment_id': '6iag827bdi8vgueede343',
      'mode': 'Cash',
      'logoUrl': 'https://logo.clearbit.com/byd.com',
    },
    {
      'customer': 'World Energy',
      'phone': '+1 9754627528',
      'amount': 950.0,
      'date': '21 Apr 2024',
      'payment_id': '34g6ygss22179afgha9',
      'mode': 'Bank',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com',
    },
    {
      'customer': 'FedEX',
      'phone': '+1 9754627386',
      'amount': 1100.0,
      'date': '12 Apr 2024',
      'payment_id': '9776vhuug679afgha9',
      'mode': 'Cash',
      'logoUrl': 'https://logo.clearbit.com/fedex.com',
    },
    {
      'customer': 'BYD Groups',
      'phone': '+1 9754627382',
      'amount': 1400.0,
      'date': '23 Apr 2024',
      'payment_id': '6iag827bdi8vgueede343',
      'mode': 'Cash',
      'logoUrl': 'https://logo.clearbit.com/byd.com',
    },
    {
      'customer': 'World Energy',
      'phone': '+1 9754627528',
      'amount': 950.0,
      'date': '21 Apr 2024',
      'payment_id': '34g6ygss22179afgha9',
      'mode': 'Bank',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com',
    },
    {
      'customer': 'FedEX',
      'phone': '+1 9754627386',
      'amount': 1100.0,
      'date': '12 Apr 2024',
      'payment_id': '9776vhuug679afgha9',
      'mode': 'Cash',
      'logoUrl': 'https://logo.clearbit.com/fedex.com',
    },
    {
      'customer': 'Abbott',
      'phone': '+1 9754627397',
      'amount': 700.0,
      'date': '18 Apr 2024',
      'payment_id': '8765yfysog679afgha9',
      'mode': 'Cash',
      'logoUrl': 'https://logo.clearbit.com/abbott.com',
    },
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList =
        allPaymentsData; // Add filtering state if needed

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payments'),
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
            'Total Payments',
            displayedList.length,
            context,
          ), // Adjusted title
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0,
              ),
              itemCount: displayedList.length,
              itemBuilder:
                  (context, index) =>
                      PaymentListItem(payment: displayedList[index]),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to actual Add Payment Screen
         Navigator.pop(context);
          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPaymentScreen()));
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
              // Removed Add button from header as FAB is present
              // _buildActionButton(icon: Icons.add, onTap: () { /* ... */ }),
              // const SizedBox(width: 10),
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
    // Reusing the filter button style from previous screens
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20), // Make it circular
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kLightGray, // Use light gray like the search background
          shape: BoxShape.circle, // Make it circular
          border: Border.all(
            color: kBorderColor.withAlpha((0.2 * 255).toInt()),
          ), // Optional border
        ),
        child: Icon(icon, color: kIconColor, size: 18),
      ),
    );
  }
}

// --- Separate Item Widget ---
class PaymentListItem extends StatelessWidget {
  final Map<String, dynamic> payment;
  const PaymentListItem({super.key, required this.payment});

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
        // Make item tappable for details view?
        onTap: () {
          // TODO: Navigate to actual Payment Details Screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navigate to Payment Details (Not Implemented)'),
            ),
          );
          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentDetailsScreen(paymentId: payment['payment_id'])));
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
                      payment['logoUrl'],
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
                          payment['customer'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone : ${payment['phone']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: kMutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount and Date Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(payment['amount']),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment['date'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: kMutedTextColor,
                        ),
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
              // Bottom Details Row
              Container(
                padding: const EdgeInsets.only(
                  top: 4.0,
                ), // Only top padding needed
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PaymentDetailItem(
                      label: 'Payment ID',
                      value: payment['payment_id'],
                    ),
                    PaymentDetailItem(
                      label: 'Mode of Payment',
                      value: payment['mode'],
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

// --- Helper for bottom detail row ---
class PaymentDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const PaymentDetailItem({
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
