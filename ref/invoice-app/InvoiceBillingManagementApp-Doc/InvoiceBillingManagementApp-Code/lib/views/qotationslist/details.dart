// lib/screens/quotation_details_screen.dart (Example path)
import 'package:flutter/material.dart';

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50); // Paid status
const Color kErrorColor = Colors.red; // Discount color
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

class QuotationDetailsScreen extends StatelessWidget {
  const QuotationDetailsScreen({super.key});

  // --- Placeholder Data ---
  // Assuming a structure similar to Invoice/Sales Return
  final Map<String, dynamic> quotationHeader = const {
    'quotation_name': 'Quotation Name',
    'id': '#QUO-000015',
    'status': 'Paid',
  }; // Example, adjust as needed
  final Map<String, dynamic> quotationInfo = const {
    'date': '15 Mar 2024',
    'quotation_no': 'QUO - 000015',
  };
  final Map<String, dynamic> quotationAddresses = const {
    'to_name': 'Naveen Bansel',
    'to_details': 'yodha@gmail.com\n987654321',
    'pay_name': 'KanakkuLLC',
    'pay_details': 'Brooklyn, NY 333\nUSA',
  };
  final List<Map<String, dynamic>> quotationItems = const [
    // Same as invoice details for example
    {
      'name': 'Nike Shoe',
      'unit': 'Pc',
      'qty': 10,
      'rate': 7000.0,
      'discount': 2000.0,
      'amount': 5000.0,
    },
    {
      'name': 'Iphone 15 pro',
      'unit': 'Pc',
      'qty': 10,
      'rate': 4547.0,
      'discount': 1047.0,
      'amount': 5450.0,
    },
  ];
  final Map<String, dynamic> quotationSummary = const {
    // Same as sales return details for example
    'amount': 11500.00, 'discount': 1000.00, 'tax': 500.00, 'total': 11000.00,
  };
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    Color statusColor = kAccentGreen; // Default Paid
    // Add logic for other statuses if needed

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quotation Details'),
        centerTitle: true,
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuotationHeader(quotationHeader, statusColor),
            const SizedBox(height: 20),
            _buildDateAndQuotationNoSection(quotationInfo),
            const SizedBox(height: 16),
            _buildAddressSection(quotationAddresses),
            const SizedBox(height: 20),
            _buildSectionTitle('Items'),
            _buildItemsList(quotationItems),
            const SizedBox(height: 10),
            _buildItemsTotal(
              quotationItems.fold(
                0.0,
                (sum, item) => sum + (item['amount'] ?? 0.0),
              ),
            ),
            const SizedBox(height: 20),
            // Title adjusted slightly from screenshot
            _buildSectionTitle('Quotation Summary'),
            _buildQuotationSummary(quotationSummary),
            const SizedBox(height: 20),
            _buildBottomButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildQuotationHeader(Map<String, dynamic> header, Color statusColor) {
    // Displaying Quotation Name below actions, similar to Invoice ID placement
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Empty space for alignment if needed, or adjust layout
            const Text(
              'Quotation Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ), // Title text
            Row(
              children: [
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
                _buildStatusTag(header['status'], statusColor),
              ],
            ),
          ],
        ),
        // if (header['id'] != null) ... // Optionally display ID if needed
      ],
    );
  }

  Widget _buildDateAndQuotationNoSection(Map<String, dynamic> info) {
    return Row(
      children: [
        Expanded(child: _buildInfoBox('Date', info['date'])),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoBox('Quotation No', info['quotation_no'])),
      ],
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> addresses) {
    // Renaming titles
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInfoBox(
            'Quotation To',
            '${addresses['to_name']}\n${addresses['to_details']}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoBox(
            'Pay To',
            '${addresses['pay_name']}\n${addresses['pay_details']}',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: kBorderColor),
        borderRadius: BorderRadius.circular(8.0),
        color: kWhiteColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: kMutedTextColor),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: kTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: kTextColor,
        ),
      ),
    );
  }

  Widget _buildItemsList(List<Map<String, dynamic>> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    double displayAmount = item['amount'] ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: kWhiteColor,
        border: Border.all(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['name'],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _itemDetailColumn('Unit', item['unit']),
              _itemDetailColumn('Quantity', item['qty'].toString()),
              _itemDetailColumn('Rate', '\$${item['rate'].toStringAsFixed(0)}'),
              _itemDetailColumn(
                'Discount',
                '\$${item['discount'].toStringAsFixed(0)}',
                valueColor: kErrorColor,
              ),
              _itemDetailColumn(
                'Amount',
                '\$${displayAmount.toStringAsFixed(0)}',
                valueColor: kErrorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemDetailColumn(
    String label,
    String value, {
    Color valueColor = kTextColor,
  }) {
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
          style: TextStyle(
            fontSize: 13,
            color: valueColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTotal(double total) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, right: 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Text(
              '\$${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationSummary(Map<String, dynamic> summary) {
    // Using same structure as sales return summary
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kLightGray.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          _summaryRow('Amount', summary['amount']),
          const SizedBox(height: 10),
          _summaryRow('Discount', summary['discount']),
          const SizedBox(height: 10),
          _summaryRow('Tax', summary['tax']),
          const Divider(height: 20, thickness: 1, color: kBorderColor),
          _summaryRow('Total', summary['total'], isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: kTextColor,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: kTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    // Same as Sales Return Details
    return Row(
      children: [
        Expanded(child: _termsButton('Terms & Conditions')),
        const SizedBox(width: 16),
        Expanded(child: _notesButton('Notes')),
      ],
    );
  }

  Widget _termsButton(String label) {
    return OutlinedButton.icon(
      onPressed: () {
        /* TODO: Handle Terms Tap */
      },
      icon: const Icon(
        Icons.description_outlined,
        size: 18,
        color: kMutedTextColor,
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: kMutedTextColor),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _notesButton(String label) {
    return OutlinedButton.icon(
      onPressed: () {
        /* TODO: Handle Notes Tap */
      },
      icon: const Icon(
        Icons.note_alt_outlined,
        size: 18,
        color: kMutedTextColor,
      ), // Notes icon
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: kMutedTextColor),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  // --- Common Helper Widgets ---
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
