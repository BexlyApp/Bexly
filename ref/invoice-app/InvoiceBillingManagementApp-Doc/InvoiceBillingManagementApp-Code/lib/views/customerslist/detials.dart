import 'package:flutter/material.dart';

import 'invoicedetails.dart';

// --- Reusing Colors (Define or Import) ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kTagBgColor = Color(0xFFFFF0E0); // Orange tag bg
const Color kTagTextColor = Color(0xFFFA8100); // Orange tag text
const Color kAccentGreen = Color(0xFF4CAF50); // Green / Paid
const Color kErrorColor = Colors.red; // Overdue / Inactive
const Color kInfoColor = Colors.blue; // Total Invoice Color
const Color kWarningColor = Colors.orange; // Draft / Outstanding Color

class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({super.key});

  // --- Placeholder Data ---
  final Map<String, dynamic> customerData = const {
    'name': 'FedEX',
    'invoiced': 8,
    'balance': 687,
    'logoUrl': 'https://logo.clearbit.com/fedex.com',
  };

  final List<Map<String, dynamic>> staticsData = const [
    {
      'icon': Icons.receipt_long_outlined,
      'amount': 784457,
      'label': 'Total Invoice',
      'count': 4,
      'color': kInfoColor,
    },
    {
      'icon': Icons.error_outline,
      'amount': 54487,
      'label': 'Overdue',
      'count': 20,
      'color': kErrorColor,
    },
    {
      'icon': Icons.drafts_outlined,
      'amount': 3654,
      'label': 'Draft',
      'count': 12,
      'color': kWarningColor,
    },
    {
      'icon': Icons.hourglass_empty_outlined,
      'amount': 3632,
      'label': 'Outstanding',
      'count': 4,
      'color': kWarningColor,
    },
  ];

  final List<Map<String, dynamic>> invoicesData = const [
    {
      'id': '#INV0021',
      'group': 'BYD Groups',
      'status': 'Paid',
      'amount': 264.0,
      'mode': 'Cash',
      'date': '23 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/byd.com',
    }, // Placeholder logo
    {
      'id': '#INV0022',
      'group': 'World Energy',
      'status': 'Sent',
      'amount': 564.0,
      'mode': 'Cash',
      'date': '21 Apr 2024',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com',
    }, // Placeholder logo
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Customer Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kTextColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(customerData),
            _buildSectionTitle('Invoice Statics'),
            _buildInvoiceStaticsGrid(staticsData),
            _buildSectionTitle('Invoice'),
            _buildInvoicesList(context, invoicesData), // Pass context
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Likely "Add Invoice" for this customer
          Navigator.pop(context);
        },
        backgroundColor: kPrimaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.white,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  data['logoUrl'],
                  width: 45,
                  height: 45,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (ctx, err, st) => Container(
                        width: 45,
                        height: 45,
                        color: kLightGray,
                        child: const Icon(
                          Icons.business,
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
                      data['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoiced : ${data['invoiced']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kMutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildBalanceTag(data['balance'].toDouble()), // Reuse tag helper
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
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

  Widget _buildInvoiceStaticsGrid(List<Map<String, dynamic>> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true, // Important for GridView inside SingleChildScrollView
        physics:
            const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.9, // Adjust aspect ratio
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _statCard(
            icon: stat['icon'],
            amount: stat['amount'],
            label: stat['label'],
            count: stat['count'],
            color: stat['color'],
          );
        },
      ),
    );
  }

  Widget _buildInvoicesList(
    BuildContext context,
    List<Map<String, dynamic>> invoices,
  ) {
    // Added context
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: invoices.length,
      itemBuilder: (ctx, index) {
        final invoice = invoices[index];
        // --- Reusing the Invoice Card logic from the *first* dashboard example ---
        // --- Adapt status colors/text as needed ---
        Color statusColor = kAccentGreen; // Default to Paid Green
        if (invoice['status'] == 'Sent') {
          statusColor = kWarningColor; // Orange for Sent
        } else if (invoice['status'] == 'Overdue') {
          statusColor = kErrorColor; // Red for Overdue
        } // Add more states if necessary

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
                context, // Use passed context
                MaterialPageRoute(
                  builder: (context) => const InvoiceDetailsScreen(),
                ), // Pass invoice ID later
              );
            },
            borderRadius: BorderRadius.circular(10.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo Placeholder
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          invoice['logoUrl'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (ctx, err, st) => Container(
                                width: 40,
                                height: 40,
                                color: kLightGray,
                                child: const Icon(
                                  Icons.business,
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
                              invoice['id'],
                              style: const TextStyle(
                                color: kPrimaryPurple,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                            invoice['status'],
                            statusColor,
                          ), // Use status helper
                          const SizedBox(height: 5),
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
                        _invoiceDetailItem(
                          label: 'Amount',
                          value: '\$${invoice['amount'].toStringAsFixed(0)}',
                        ),
                        _invoiceDetailItem(
                          label: 'Mode of Payment',
                          value: invoice['mode'],
                        ),
                        _invoiceDetailItem(
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
        // --- End Reused Invoice Card ---
      },
    );
  }

  // --- Helper Widgets ---
  Widget _buildBalanceTag(double balance) {
    // Copied from Customer List Item - make common if needed
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: kTagBgColor, // Orange background
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        'Balance : \$${balance.toStringAsFixed(0)}', // No decimals shown
        style: const TextStyle(
          fontSize: 10,
          color: kTagTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    // Copied from Customer List Item - make common if needed
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).toInt()), // Background tint
        borderRadius: BorderRadius.circular(10.0), // More rounded
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

  // --- Stat Card Widget ---
  Widget _statCard({
    required IconData icon,
    required int amount,
    required String label,
    required int count,
    required Color color,
  }) {
    return Card(
      color: Colors.white,

      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  // Allows amount to wrap if needed, though unlikely
                  child: Text(
                    '\$${amount.toString()}', // Formatting can be added later
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            //const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            //const SizedBox(height: 4),
            Text(
              'No of Invoice : $count',
              style: const TextStyle(fontSize: 11, color: kMutedTextColor),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Invoice Card Details Row (from first example)
  Widget _invoiceDetailItem({required String label, required String value}) {
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
