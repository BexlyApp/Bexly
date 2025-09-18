// lib/screens/invoice_list_screen.dart (Example path)
import 'package:flutter/material.dart';

// Assuming other screens will handle their own constants or import from a central file if needed
import '../../Widgets/customapp_bar.dart';
import '../customerslist/invoicedetails.dart'; // Make sure this file ALSO doesn't define duplicate colors if imported elsewhere
import 'addinvoice.dart';

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kTagBgColor = Color(0xFFFFF0E0); // Orange tag bg (Used in helpers)
const Color kTagTextColor = Color(
  0xFFFA8100,
); // Orange tag text (Used in helpers)
const Color kAccentGreen = Color(0xFF4CAF50); // Green / Paid / Active count
const Color kErrorColor = Colors.red; // Overdue / Inactive / Discount red
const Color kWarningColor =
    Colors.orange; // Draft / Sent / Partially Paid / Outstanding
const Color kInfoColor = Colors.blue; // Total Invoice Color
const Color kIconColor = Colors.black54; // Default icon color (Used in helpers)
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  int _selectedTabIndex = 0; // 0: All, 1: Paid, 2: Overdue, 3: Part

  // --- Placeholder Data (Now uses locally defined constants) ---
  final List<Map<String, dynamic>> staticsData = const [
    {
      'icon': Icons.receipt_long_outlined,
      'amount': 784457,
      'label': 'Total Invoice',
      'count': 4,
      'color': kInfoColor,
    }, // Uses local kInfoColor
    {
      'icon': Icons.error_outline,
      'amount': 54487,
      'label': 'Overdue',
      'count': 20,
      'color': kErrorColor,
    }, // Uses local kErrorColor
    {
      'icon': Icons.drafts_outlined,
      'amount': 3654,
      'label': 'Draft',
      'count': 12,
      'color': kWarningColor,
    }, // Uses local kWarningColor
  ];

  final List<Map<String, dynamic>> allInvoicesData = const [
    // Data remains the same, widgets below will use local constants
    {
      'id': '#INV0021',
      'group': 'BYD Groups',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/byd.com',
    },
    {
      'id': '#INV0022',
      'group': 'World Energy',
      'status': 'Sent',
      'amount': 564.0,
      'mode': 'Cash',
      'date': '21 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com',
    },
    {
      'id': '#INV0022',
      'group': 'FedEX',
      'status': 'Partially Paid',
      'amount': 874.0,
      'mode': 'Cash',
      'date': '12 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/fedex.com',
    },
    {
      'id': '#INV0023',
      'group': 'Google',
      'status': 'Overdue',
      'amount': 1200.0,
      'mode': 'Card',
      'date': '10 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/google.com',
    },
    {
      'id': '#INV0024',
      'group': 'BYD Groups',
      'status': 'Paid',
      'amount': 350.0,
      'mode': 'Cash',
      'date': '05 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/byd.com',
    },
  ];
  // --- End Placeholder Data ---

  List<Map<String, dynamic>> getFilteredInvoices() {
    // Filtering logic remains the same
    switch (_selectedTabIndex) {
      case 1:
        return allInvoicesData.where((inv) => inv['status'] == 'Paid').toList();
      case 2:
        return allInvoicesData
            .where((inv) => inv['status'] == 'Overdue')
            .toList();
      case 3:
        return allInvoicesData
            .where(
              (inv) =>
                  inv['status'] == 'Partially Paid' || inv['status'] == 'Sent',
            )
            .toList();
      case 0:
      default:
        return allInvoicesData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = getFilteredInvoices();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 0),
              child: const CustomAppBar(text: 'Invoice', text1: ''),
            ),
            const SizedBox(height: 0),
            _buildInvoiceStaticsRow(staticsData),
            _buildFilterTabBar(),
            _buildListHeader('Total All Invoices', filteredList.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 0,
                ),
                itemCount: filteredList.length,
                // _InvoiceListItem will now use the locally defined colors
                itemBuilder:
                    (context, index) =>
                        InvoiceListItem(invoice: filteredList[index]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddInvoiceScreen()),
            ),
        // Uses local kPrimaryPurple, kWhiteColor
        backgroundColor: kPrimaryPurple,
        child: const Icon(Icons.add, color: kWhiteColor),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildInvoiceStaticsRow(List<Map<String, dynamic>> stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
      child: Row(
        children:
            stats
                .take(3)
                .map(
                  (stat) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      // _StatCard uses the color passed in, which comes from staticsData (using local constants)
                      child: StatCard(
                        icon: stat['icon'],
                        amount: stat['amount'],
                        label: stat['label'],
                        count: stat['count'],
                        color: stat['color'],
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildFilterTabBar() {
    final List<String> tabLabels = ['All Invoices', 'Paid', 'Overdue', 'Part'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabLabels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          bool isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                // Uses local kPrimaryPurple, kBorderColor
                color: isSelected ? kPrimaryPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
                border: isSelected ? null : Border.all(color: kBorderColor),
              ),
              alignment: Alignment.center,
              child: Text(
                tabLabels[index],
                style: TextStyle(
                  // Uses local kWhiteColor, kMutedTextColor
                  color: isSelected ? kWhiteColor : kMutedTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListHeader(String title, int count) {
    // Uses local kTextColor, kAccentGreen
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                        builder: (context) => const AddInvoiceScreen(),
                      ),
                    ),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.filter_list,
                onTap: () {
                  /* Filter Logic */
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
    // Uses local kPrimaryPurple, kWhiteColor
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
} // End of _InvoiceListScreenState

// --- Separate Item Widget ---
// This widget will now use the constants defined at the top of THIS file.
class InvoiceListItem extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const InvoiceListItem({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText = invoice['status'];
    // Determine color based on status using locally defined constants
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
      case 'Paid':
      default:
        statusColor = kAccentGreen;
        break;
    }

    return Card(
      color: Colors.white,
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12.0),
      // Uses local kBorderColor
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
      ),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InvoiceDetailsScreen(),
              ),
            ),
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
                      invoice['logoUrl'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (ctx, err, st) => Container(
                            // Uses local kLightGray, kMutedTextColor
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
                        // Uses local kPrimaryPurple
                        Text(
                          invoice['id'],
                          style: const TextStyle(
                            color: kPrimaryPurple,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Uses local kTextColor
                        Text(
                          invoice['group'],
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusTag(
                        statusText,
                        statusColor,
                      ), // Uses local statusColor derived from local constants
                      const SizedBox(height: 5),
                      // Uses local kMutedTextColor
                      const Icon(
                        Icons.more_vert,
                        color: kMutedTextColor,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Uses local kLightGray
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
                    // _InvoiceDetailItem uses local constants defined below
                    InvoiceDetailItem(
                      label: 'Amount',
                      value: '\$${invoice['amount'].toStringAsFixed(0)}',
                    ),
                    InvoiceDetailItem(
                      label: 'Mode of Payment',
                      value: invoice['mode'],
                    ),
                    InvoiceDetailItem(
                      label: 'Due Date',
                      value: invoice['date'],
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

  Widget _buildStatusTag(String text, Color color) {
    // Uses the passed color (derived from local constants)
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

// --- Placeholder Helper Widgets ---
// These are defined OUTSIDE the State class but INSIDE the same file,
// so they can access the top-level constants defined in this file.
class StatCard extends StatelessWidget {
  final IconData icon;
  final int amount;
  final String label;
  final int count;
  final Color color;
  const StatCard({
    super.key,
    required this.icon,
    required this.amount,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        // Uses local kBorderColor
        side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Consistent padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: color), // Use passed color
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // Uses local kTextColor implicitly
                    '\$${amount.toString()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ), // Use passed color
            // Uses local kMutedTextColor
            Text(
              'No of Invoice: $count',
              style: const TextStyle(fontSize: 11, color: kMutedTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const InvoiceDetailItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Uses local kMutedTextColor
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kMutedTextColor),
        ),
        const SizedBox(height: 2),
        // Uses local kTextColor
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
