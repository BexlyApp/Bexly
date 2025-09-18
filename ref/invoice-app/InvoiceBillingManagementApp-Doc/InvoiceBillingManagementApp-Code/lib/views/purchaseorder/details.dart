// lib/screens/debit_note_details_screen.dart
// Renamed from purchase_details_screen.dart to match the first screenshot's title

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting if needed later

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50); // Color for 'Paid' status
const Color kErrorColor = Color(
  0xFFD32F2F,
); // Using a standard red for Discount/Amount in items
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

class DebitNoteDetailsScreen extends StatelessWidget {
  const DebitNoteDetailsScreen({super.key});

  // --- Placeholder Data (Matches Debit Note Details Screenshot) ---
  final Map<String, dynamic> debitNoteHeader = const {
    'title': 'Debit Notes Details', // Main title for the section below AppBar
    'status': 'Paid', // Status text
  };
  final Map<String, dynamic> debitNoteInfo = const {
    'date': '15 Mar 2024',
    'dn_no': 'QUO - 000015', // Debit Note Number
  };
  final Map<String, dynamic> debitNoteAddresses = const {
    'order_to_name': 'Naveen Bansel',
    'order_to_details': 'yodha@gmail.com\n987654321', // Multi-line
    'pay_to_name': 'KanakkuLLC',
    'pay_to_details': 'Brooklyn, NY 333\nUSA', // Multi-line
  };
  final List<Map<String, dynamic>> debitNoteItems = const [
    {
      'name': 'Nike Shoe',
      'unit': 'Pc',
      'qty': 10,
      'rate': 7000.0,
      'discount': 2000.0,
      'amount':
          5000.0, // This seems calculated (Rate*Qty - Discount?), but using screenshot value directly
    },
    {
      'name': 'Iphone 15 pro',
      'unit': 'Pc',
      'qty': 10,
      'rate': 4547.0,
      'discount': 1047.0, // Screenshot shows 1047 discount
      'amount': 5450.0, // Screenshot shows 5450 amount
      // Note: 10 * 4547 = 45470. 45470 - 1047 = 44423. The amount 5450 doesn't match simple calculation.
      // We will display the values *exactly* as shown in the screenshot.
    },
  ];
  final Map<String, dynamic> debitNoteSummary = const {
    'amount':
        11500.00, // Sum of item amounts? (5000+5450 = 10450 - doesn't match screenshot 11500) - Using screenshot value
    'discount':
        1000.00, // Total discount? (2000+1047 = 3047 - doesn't match screenshot 1000) - Using screenshot value
    'tax': 500.00,
    'total':
        11000.00, // Calculation: 11500 - 1000 + 500 = 11000. This matches screenshot logic.
  };
  // --- End Placeholder Data ---

  // Helper to format currency
  String _formatCurrency(double amount, {int decimalDigits = 0}) {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$', // Using $ as per screenshot
      decimalDigits: decimalDigits,
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Determine status color based on text
    Color statusColor;
    switch (debitNoteHeader['status']?.toLowerCase()) {
      case 'paid':
        statusColor = kAccentGreen;
        break;
      // Add other cases like 'pending', 'overdue', etc.
      default:
        statusColor = Colors.grey; // Default color
    }

    // Calculate total amount from items list for the "Items Total" section
    // Note: The summary 'amount' field seems different from the sum of item amounts in the screenshot.
    // We'll use the sum of items for the "Items Total" row, and the summary data for the "Summary" section.
    double itemsActualTotal = debitNoteItems.fold(
      0.0,
      (sum, item) => sum + (item['amount'] ?? 0.0),
    );

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
        title: const Text(
          'Debit Notes Details',
        ), // AppBar title matches screenshot
        centerTitle: false, // Title usually left-aligned on details screens
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor,
        elevation: 0.5, // Subtle elevation
        actions: [
          _buildAppBarAction(
            // Edit Icon
            icon: Icons.edit_outlined,
            onTap: () {
              /* TODO: Edit Debit Note Action */
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Action (Not Implemented)')),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildAppBarAction(
            // Delete Icon
            icon: Icons.delete_outline,
            onTap: () {
              /* TODO: Delete Debit Note Action */
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete Action (Not Implemented)'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Status Tag in AppBar
          Padding(
            padding: const EdgeInsets.only(
              right: 16.0,
              top: 8.0,
              bottom: 8.0,
            ), // Adjust padding
            child: _buildStatusTag(debitNoteHeader['status'], statusColor),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed the header row from here as it's now in the AppBar actions
            _buildDateAndDNSection(debitNoteInfo), // Date and DN No section
            const SizedBox(height: 16),
            _buildAddressSection(debitNoteAddresses), // Address section
            const SizedBox(height: 24), // More space before items

            _buildSectionTitle('Items'),
            const SizedBox(height: 4),
            _buildItemsList(debitNoteItems),
            const SizedBox(height: 12),
            _buildItemsTotal(
              itemsActualTotal,
            ), // Display total calculated from items
            const SizedBox(height: 24), // More space before summary

            _buildSectionTitle('Summary'),
            const SizedBox(height: 4),
            _buildDebitNoteSummary(
              debitNoteSummary,
            ), // Use summary data from map
            const SizedBox(height: 24),

            _buildBottomButtons(), // Terms and Notes buttons
            const SizedBox(height: 20), // Padding at the bottom
          ],
        ),
      ),
    );
  }

  // --- Widget Builders (Adapted for Debit Note Details) ---

  // Builds the action icons in the AppBar
  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: 22,
        color: kIconColor,
      ), // Standard icon size and color
      onPressed: onTap,
      splashRadius: 20, // Smaller splash radius
      constraints: const BoxConstraints(), // Remove default padding
      padding: const EdgeInsets.symmetric(horizontal: 8), // Add custom padding
    );
  }

  // Builds Date and Debit Note Number section
  Widget _buildDateAndDNSection(Map<String, dynamic> info) {
    return Row(
      children: [
        Expanded(child: _buildInfoBox('Date', info['date'] ?? 'N/A')),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoBox('Debit Note No', info['dn_no'] ?? 'N/A')),
      ],
    );
  }

  // Builds Address section
  Widget _buildAddressSection(Map<String, dynamic> addresses) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align boxes to the top
      children: [
        Expanded(
          child: _buildInfoBox(
            'Purchase Order To', // Label from screenshot
            '${addresses['order_to_name'] ?? ''}\n${addresses['order_to_details'] ?? ''}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoBox(
            'Pay To', // Label from screenshot
            '${addresses['pay_to_name'] ?? ''}\n${addresses['pay_to_details'] ?? ''}',
          ),
        ),
      ],
    );
  }

  // Reusable info box for Date/DN/Addresses
  Widget _buildInfoBox(String title, String content) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 10.0,
      ), // Adjust padding
      decoration: BoxDecoration(
        color: kLightGray.withAlpha((0.2 * 255).toInt()), // Lighter background
        // border: Border.all(color: kBorderColor.withAlpha((0.4 * 255).toInt())), // Optional subtle border
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Fit content height
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: kMutedTextColor,
              fontWeight: FontWeight.w500,
            ), // Slightly bolder title
          ),
          const SizedBox(height: 5), // Adjust spacing
          Text(
            content.trim(), // Trim potential whitespace
            style: const TextStyle(
              fontSize: 13.5, // Slightly larger content text
              color: kTextColor,
              height: 1.4, // Line height for multi-line text
            ),
          ),
        ],
      ),
    );
  }

  // Section Title (Items, Summary)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Space below title
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold, // Bold title
          color: kTextColor,
        ),
      ),
    );
  }

  // Builds the list of item cards
  Widget _buildItemsList(List<Map<String, dynamic>> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling within the list
      itemCount: items.length,
      separatorBuilder:
          (context, index) => const SizedBox(height: 10), // Space between cards
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  // Builds a single item card
  Widget _buildItemCard(Map<String, dynamic> item) {
    // Use values directly from the map, matching the screenshot
    double displayAmount = item['amount'] ?? 0.0;
    double displayDiscount = item['discount'] ?? 0.0;
    double displayRate = item['rate'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: kWhiteColor, // White background for card
        border: Border.all(
          color: kBorderColor.withAlpha((0.2 * 255).toInt()),
        ), // Subtle border
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          // Optional: Add a very subtle shadow
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Name (Top Left) and Amount (Top Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['name'] ?? 'Unknown Item',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              Text(
                // Format Amount with $ sign and 0 decimal places
                _formatCurrency(displayAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold, // Bold amount
                  color:
                      kErrorColor, // Use red/error color for amount as per screenshot
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Space before details row
          // Details Row (Unit, Qty, Rate, Discount)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _itemDetailColumn('Unit', item['unit']?.toString() ?? '-'),
              _itemDetailColumn('Quantity', item['qty']?.toString() ?? '0'),
              _itemDetailColumn(
                'Rate',
                _formatCurrency(displayRate),
              ), // Format Rate
              _itemDetailColumn(
                'Discount',
                _formatCurrency(displayDiscount), // Format Discount
                // Use red/error color for discount value as per screenshot
                valueColor: kErrorColor,
              ),
              // Amount is now displayed at the top right
            ],
          ),
        ],
      ),
    );
  }

  // Helper for item detail columns (Unit, Qty, Rate, Discount)
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
            color: valueColor, // Apply custom color if provided
            fontWeight: FontWeight.w500, // Semi-bold value
          ),
        ),
      ],
    );
  }

  // Builds the "Total" line below the items list
  Widget _buildItemsTotal(double total) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 0.0,
          right: 8.0,
        ), // Reduced top padding
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(width: 24), // Wider space before total amount
            Text(
              _formatCurrency(total), // Format total amount
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the Summary section box
  Widget _buildDebitNoteSummary(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ), // Adjust padding
      decoration: BoxDecoration(
        color: kLightGray.withAlpha((0.2 * 255).toInt()), // Lighter gray background
        borderRadius: BorderRadius.circular(8.0),
        // border: Border.all(color: kBorderColor.withOpacity(0.5)), // Optional border
      ),
      child: Column(
        children: [
          _summaryRow('Amount', summary['amount'] ?? 0.0),
          const SizedBox(height: 10),
          _summaryRow('Discount', summary['discount'] ?? 0.0),
          const SizedBox(height: 10),
          _summaryRow('Tax', summary['tax'] ?? 0.0),
          const Divider(
            height: 24,
            thickness: 1,
            color: kBorderColor,
          ), // Divider line
          _summaryRow(
            'Total',
            summary['total'] ?? 0.0,
            isTotal: true,
          ), // Bold Total row
        ],
      ),
    );
  }

  // Helper for a single row in the Summary section
  Widget _summaryRow(String label, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14, // Larger text for total label
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: kTextColor,
          ),
        ),
        Text(
          // Format currency with 2 decimal places for summary
          _formatCurrency(value, decimalDigits: 2),
          style: TextStyle(
            fontSize: isTotal ? 15 : 14, // Larger text for total value
            fontWeight:
                isTotal
                    ? FontWeight.bold
                    : FontWeight.w500, // Bolder total value
            color: kTextColor,
          ),
        ),
      ],
    );
  }

  // Builds the bottom row with Terms & Conditions and Notes buttons
  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: _customOutlinedButton(
            label: 'Terms & Conditions',
            icon: Icons.description_outlined,
            onTap: () {
              /* TODO: Handle Terms Tap */
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _customOutlinedButton(
            label: 'Notes',
            icon: Icons.note_alt_outlined,
            onTap: () {
              /* TODO: Handle Notes Tap */
            },
          ),
        ),
      ],
    );
  }

  // Reusable Outlined Button for Terms/Notes
  Widget _customOutlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: kMutedTextColor, // Icon color
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: kMutedTextColor,
          fontWeight: FontWeight.w500,
        ), // Text style
        overflow: TextOverflow.ellipsis, // Prevent overflow
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kBorderColor), // Border color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 10,
        ), // Padding
        foregroundColor: kMutedTextColor, // Text and icon color
      ),
    );
  }

  // --- Common Helper Widgets --- (Status Tag)
  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 5.0,
      ), // Adjusted padding
      decoration: BoxDecoration(
        // Use a lighter version of the status color for the background
        color: color.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(6.0), // Less rounded corners
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Fit content
        children: [
          // Small colored dot indicating status
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6), // Space between dot and text
          // Status text itself
          Text(
            text,
            style: TextStyle(
              fontSize: 11, // Slightly larger text
              color: color, // Text color matches the status color
              fontWeight: FontWeight.w600, // Bold status text
            ),
          ),
        ],
      ),
    );
  }
}
