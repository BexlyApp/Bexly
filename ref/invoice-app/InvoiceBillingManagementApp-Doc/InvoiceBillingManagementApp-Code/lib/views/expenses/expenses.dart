// lib/screens/expenses_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(
  0xFF4CAF50,
); // For count badge and 'Paid' status
const Color kErrorColor = Color(0xFFD32F2F); // For 'Cancelled' status
const Color kPendingColor = Color(
  0xFF2196F3,
); // Blue for 'Pending' status (adjust if needed)
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;
// --- End Color Definitions ---

// --- Placeholder Navigation Targets ---
// TODO: import 'add_expense_screen.dart';
// TODO: import 'expense_details_screen.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {



  // --- Placeholder Data (Matches Expenses List Screenshot) ---
  final List<Map<String, dynamic>> allExpensesData = const [
    {
      'id': 'EXP - 0014',
      'status': 'Paid',
      'reference': '62914',
      'amount': 1500.0,
      'mode': 'Cash',
    },
    {
      'id': 'EXP - 0013',
      'status': 'Pending',
      'reference': '62914',
      'amount': 1100.0,
      'mode': 'Cheque',
    },
    {
      'id': 'EXP - 0012',
      'status': 'Paid',
      'reference': '51892',
      'amount': 750.0,
      'mode': 'Cash',
    },
    {
      'id': 'EXP - 0011',
      'status': 'Cancelled',
      'reference': '41932',
      'amount': 1200.0,
      'mode': 'Cheque',
    },
    {
      'id': 'EXP - 0003', // Added from screenshot bottom card
      'status': 'Paid',
      'reference': '38765', // Example reference
      'amount': 950.0, // Example amount
      'mode': 'Online', // Example mode
    },
    {
      'id': 'EXP - 0014',
      'status': 'Paid',
      'reference': '62914',
      'amount': 1500.0,
      'mode': 'Cash',
    },
    {
      'id': 'EXP - 0013',
      'status': 'Pending',
      'reference': '62914',
      'amount': 1100.0,
      'mode': 'Cheque',
    },
    {
      'id': 'EXP - 0012',
      'status': 'Paid',
      'reference': '51892',
      'amount': 750.0,
      'mode': 'Cash',
    },
    {
      'id': 'EXP - 0011',
      'status': 'Cancelled',
      'reference': '41932',
      'amount': 1200.0,
      'mode': 'Cheque',
    },
    {
      'id': 'EXP - 0003', // Added from screenshot bottom card
      'status': 'Paid',
      'reference': '38765', // Example reference
      'amount': 950.0, // Example amount
      'mode': 'Online', // Example mode
    },
    // Add more items to test scrolling
  ];
  // --- End Placeholder Data ---

  // --- Dialog Functions or Navigation ---
  void _navigateToAddExpense() {
    // TODO: Replace with actual navigation
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AddExpenseScreen()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList = allExpensesData;
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
        title: const Text('Expenses'),
        centerTitle: false, // Left-aligned title
        actions: [
          // Action buttons matching the Purchase Order screen's AppBar
          IconButton(
            // Add (+) Button in AppBar (as per PO screen)
            icon: const Icon(
              Icons.add_circle_outline,
              size: 26,
              color: kPrimaryPurple,
            ), // Or just Icons.add
            tooltip: 'Add Expense',
            onPressed: _navigateToAddExpense,
          ),
          IconButton(
            // Filter/Sort Icon
            icon: const Icon(Icons.tune_outlined, size: 24, color: kTextColor),
            tooltip: 'Filter/Sort',
            onPressed: () {
              /* TODO: Filter/Sort Implementation */
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter/Sort Action (Not Implemented)'),
                ),
              );
            },
          ),
          IconButton(
            // Search Icon
            icon: const Icon(Icons.search, size: 26, color: kTextColor),
            tooltip: 'Search',
            onPressed: () {
              /* TODO: Search Implementation */
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
        elevation: 0.5,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeader('Total Payments', totalCount), // Header added here
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0,
              ), // Remove vertical padding
              itemCount: displayedList.length,
              itemBuilder:
                  (context, index) => ExpenseListItem(
                    expense: displayedList[index],
                    onTap: () {
                      // TODO: Navigate to Expense Details Screen
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => ExpenseDetailsScreen(expenseId: displayedList[index]['id'])));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tapped on ${displayedList[index]['id']}',
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
      // Floating Action Button for adding (matches previous screens)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        backgroundColor: kPrimaryPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        elevation: 2.0,
        child: const Icon(Icons.add, color: kWhiteColor),
      ),
      // Bottom Navigation Bar mimicking the screenshot
    );
  }

  // Helper to build list header
  Widget _buildListHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        10.0,
      ), // Adjust padding
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: kAccentGreen.withAlpha((0.2 * 255).toInt()), // Badge color
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: kWhiteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build Bottom Navigation Items consistently
}

// --- Separate Expense List Item Widget ---
class ExpenseListItem extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onTap;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.onTap,
  });

  // Helper to format currency
  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0, // No decimals in screenshot amounts
    );
    return format.format(amount);
  }

  // Helper to determine status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return kAccentGreen;
      case 'pending':
        return kPendingColor;
      case 'cancelled':
        return kErrorColor;
      default:
        return Colors.grey; // Default color for unknown status
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor(expense['status'] ?? '');

    return Card(
      elevation: 0.5, // Subtle shadow
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        // side: BorderSide(color: kBorderColor.withOpacity(0.3)), // Optional faint border
      ),
      child: InkWell(
        // Make the card tappable
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: ID, Status Tag, More Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Expense ID
                  Text(
                    expense['id'] ?? 'No ID',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  // Status Tag and More Icon
                  Row(
                    children: [
                      _buildStatusTag(
                        expense['status'] ?? 'Unknown',
                        statusColor,
                      ),
                      const SizedBox(width: 8),
                      // More Options Icon (make tappable if needed)
                      InkWell(
                        onTap: () {
                          // TODO: Implement More Actions (e.g., Edit, Delete, Share)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'More actions for ${expense['id']}',
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: const Icon(
                          Icons.more_vert,
                          color: kMutedTextColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10), // Space before details section
              // Bottom Details Container
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kLightGray.withAlpha(
                    (1 * 255).toInt(),
                  ), // Very light gray background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Use the detail item helper
                    _buildDetailItem(
                      label: 'Reference',
                      value: expense['reference'] ?? 'N/A',
                    ),
                    _buildDetailItem(
                      label: 'Amount',
                      value: _formatCurrency(expense['amount'] ?? 0.0),
                    ),
                    _buildDetailItem(
                      label: 'Mode of Payment',
                      value: expense['mode'] ?? 'N/A',
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

  // Helper for bottom detail items (Reference, Amount, Mode)
  Widget _buildDetailItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kMutedTextColor),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600, // Bold value
            color: kTextColor,
          ),
        ),
      ],
    );
  }

  // Helper for Status Tag
  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ), // Adjust padding
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).toInt()), // Background tint
        borderRadius: BorderRadius.circular(6.0), // Rounded corners
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // Status indicator dot
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color, // Text color matches dot
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
