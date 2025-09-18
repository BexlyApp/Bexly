import 'package:flutter/material.dart';

import 'addcustomers.dart';
import 'detials.dart';

// Assume constants.dart is imported or colors defined here
// import 'constants.dart';

// --- Reusing Colors (Define or Import) ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kTagBgColor = Color(0xFFFFF0E0); // Orange tag bg
const Color kTagTextColor = Color(0xFFFA8100); // Orange tag text
const Color kAccentGreen = Color(0xFF4CAF50); // Green count / Active
const Color kErrorColor = Colors.red; // Inactive
const Color kIconColor = Colors.black54;

class CustomersListScreen extends StatelessWidget {
  // Can be StatefulWidget if filtering/state needed
  const CustomersListScreen({super.key});

  // Placeholder Data
  final List<Map<String, dynamic>> _customers = const [
    {
      'name': 'FedEX',
      'invoiced': 9,
      'balance': 687,
      'status': 'Active',
      'logoUrl': 'https://logo.clearbit.com/fedex.com',
    },
    {
      'name': 'Google',
      'invoiced': 6,
      'balance': 608,
      'status': 'Inactive',
      'logoUrl': 'https://logo.clearbit.com/google.com',
    },
    {
      'name': 'World Energy',
      'invoiced': 7,
      'balance': 247,
      'status': 'Active',
      'logoUrl': 'https://logo.clearbit.com/worldenergy.com',
    }, // Placeholder logo
    {
      'name': 'Paloatte',
      'invoiced': 4,
      'balance': 248,
      'status': 'Active',
      'logoUrl': 'https://logo.clearbit.com/paloaltonetworks.com',
    }, // Placeholder logo
    {
      'name': 'FedEX',
      'invoiced': 8,
      'balance': 687,
      'status': 'Inactive',
      'logoUrl': 'https://logo.clearbit.com/fedex.com',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Customers'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            onPressed: () {
              /* Handle search */
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        foregroundColor: kTextColor,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _buildListHeader(
            context,
            'Total Customers',
            _customers.length,
          ), // Pass context
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0,
              ),
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return CustomerListItem(
                  logoUrl: customer['logoUrl'],
                  name: customer['name'],
                  invoicedCount: customer['invoiced'],
                  // --- FIX: Convert int to double ---
                  balance: customer['balance'].toDouble(),
                  // -----------------------------------
                  status: customer['status'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerDetailsScreen(),
                      ),
                    );
                  },
                  onAddInvoice: () {
                    /* Handle Add Invoice */
                  },
                  onEdit: () {
                    /* Handle Edit */
                  },
                  onDelete: () {
                    /* Handle Delete */
                  },
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerDetailsScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
        },
        backgroundColor: kPrimaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- Header Row --- (Similar to Product Catalog)
  Widget _buildListHeader(BuildContext context, String title, int count) {
    // Added context
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title, // Corrected label
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
                    context, // Use context here
                    MaterialPageRoute(
                      builder: (context) => const AddCustomerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.filter_list,
                onTap: () {
                  /* Filter Logic */
                },
              ), // Replace with specific filter icon if available
            ],
          ),
        ],
      ),
    );
  }

  // --- Action Button Helper ---
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
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// --- Customer List Item Widget ---
class CustomerListItem extends StatelessWidget {
  final String logoUrl;
  final String name;
  final int invoicedCount;
  final double balance;
  final String status;
  final VoidCallback onTap;
  final VoidCallback onAddInvoice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const CustomerListItem({
    super.key,
    required this.logoUrl,
    required this.name,
    required this.invoicedCount,
    required this.balance,
    required this.status,
    required this.onTap,
    required this.onAddInvoice,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == 'Active';
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
      ),
      color: Colors.white,
      child: InkWell(
        // Make the card tappable
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      logoUrl,
                      width: 45,
                      height: 45,
                      fit:
                          BoxFit
                              .contain, // Use contain to avoid stretching logos
                      errorBuilder:
                          (context, error, stackTrace) => Container(
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
                  // Name & Invoiced Count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invoiced : $invoicedCount',
                          style: const TextStyle(
                            fontSize: 11,
                            color: kMutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action Icons & Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildItemAction(
                            icon: Icons.edit_outlined,
                            onTap: onEdit,
                          ),
                          const SizedBox(width: 8),
                          _buildItemAction(
                            icon: Icons.delete_outline,
                            onTap: onDelete,
                          ),
                          const SizedBox(width: 8),
                          // Using person outline as placeholder for details icon
                          _buildItemAction(
                            icon: Icons.person_outline,
                            onTap: onViewDetails,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStatusTag(
                        status,
                        isActive ? kAccentGreen : kErrorColor,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Row: Balance and Add Invoice Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBalanceTag(balance),
                  ElevatedButton.icon(
                    onPressed: onAddInvoice,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'Add Invoice',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Specific Helpers for this Item
  Widget _buildItemAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    // Copied from previous example - make common if needed
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(5), // Slightly smaller padding
        decoration: BoxDecoration(
          color: kLightGray,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: kIconColor), // Smaller icon
      ),
    );
  }

  Widget _buildBalanceTag(double balance) {
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
}
