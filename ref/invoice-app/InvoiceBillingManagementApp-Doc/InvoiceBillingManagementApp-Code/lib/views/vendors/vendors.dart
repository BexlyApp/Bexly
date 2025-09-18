// lib/screens/vendor_list_screen.dart (Example path)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50);
// const Color kErrorColor = Colors.red; // Not used directly here
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

// --- Placeholder Navigation Targets ---
// import 'add_vendor_screen.dart'; // TODO: Create this screen
// import 'vendor_details_screen.dart'; // TODO: Create this screen
// import 'vendor_ledger_screen.dart'; // TODO: Create this screen

class VendorListScreen extends StatelessWidget {
  const VendorListScreen({super.key});

  // --- Placeholder Data ---
  // Using placeholder URLs - replace with real ones
  // Using double for balance for formatting
  final List<Map<String, dynamic>> allVendorsData = const [
    {
      'name': 'Emily',
      'email': 'emily23@gmail.com',
      'phone': '8920367183',
      'date': '29 Jan 2024',
      'balance': 9025000.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZW1wbG95ZWUlMjBwcm9maWxlfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
    }, // Example image
    {
      'name': 'Peter',
      'email': 'peter65@gmail.com',
      'phone': '7351689384',
      'date': '18 Jan 2024',
      'balance': 81100150.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    }, // Example image
    {
      'name': 'Jerry',
      'email': 'jerry121@gmail.com',
      'phone': '7361839618',
      'date': '12 Jan 2024',
      'balance': 71465000.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    }, // Example image
    {
      'name': 'Lisa',
      'email': 'lisa77@gmail.com',
      'phone': '8848146395',
      'date': '06 Jan 2024',
      'balance': 82470000.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    }, // Example image {'name': 'Jerry', 'email': 'jerry121@gmail.com', 'phone': '7361839618', 'date': '12 Jan 2024', 'balance': 71465000.0, 'imageUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bWFsZSUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60'}, // Example image
    {
      'name': 'Lisa',
      'email': 'lisa77@gmail.com',
      'phone': '8848146395',
      'date': '06 Jan 2024',
      'balance': 82470000.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZmVtYWxlJTIwcHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
    }, // Example image
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList =
        allVendorsData; // Add filtering state if needed

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Vendors'),
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
          // Changed title from "Total Expense" to "Total Vendors" as it seems more logical
          _buildListHeader('Total Vendors', displayedList.length, context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0,
              ),
              itemCount: displayedList.length,
              itemBuilder:
                  (context, index) =>
                      VendorListItem(vendor: displayedList[index]),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to actual Add Vendor Screen
         Navigator.pop(context);
          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVendorScreen()));
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
                  // TODO: Navigate to actual Add Vendor Screen
                   Navigator.pop(context);
                  // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVendorScreen()));
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
class VendorListItem extends StatelessWidget {
  final Map<String, dynamic> vendor;
  const VendorListItem({super.key, required this.vendor});

  // Currency Formatter (Indian Locale)
  String _formatCurrency(double amount) {

    // Custom formatting for Lakhs and Crores can be complex with NumberFormat alone.
    // This provides basic comma separation.
    // For 9,02,50,000 style, manual formatting might be needed.
    // Let's stick to standard international for simplicity here.
    final standardFormat = NumberFormat("#,##0", "en_US");
    return standardFormat.format(amount);
    // return format.format(amount); // Use this for basic Indian comma style if acceptable
  }

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
          // TODO: Navigate to actual Vendor Details Screen
         Navigator.pop(context);
          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => VendorDetailsScreen(vendorId: vendor['id']))); // Need vendor ID
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
                      vendor['imageUrl'] ?? '', // Handle potential null URL
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover, // Use cover for profile pics
                      errorBuilder:
                          (ctx, err, st) => Container(
                            width: 45,
                            height: 45,
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
                          vendor['name'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vendor['email'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: kMutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Actions Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLedgerButton(
                        onTap: () {
                          // TODO: Navigate to Ledger Screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Navigate to Ledger (Not Implemented)',
                              ),
                            ),
                          );
                          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => VendorLedgerScreen(vendorId: vendor['id'])));
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildItemAction(
                        icon: Icons.edit_outlined,
                        onTap: () {
                          /* TODO: Edit Vendor */
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildItemAction(
                        icon: Icons.delete_outline,
                        onTap: () {
                          /* TODO: Delete Vendor */
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dashed line separator (Visual approximation)
              // Use dotted_border package for actual dashed line
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final boxWidth = constraints.constrainWidth();
                    const dashWidth = 4.0;
                    const dashSpace = 3.0;
                    final dashCount =
                        (boxWidth / (dashWidth + dashSpace)).floor();
                    return Flex(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      direction: Axis.horizontal,
                      children: List.generate(dashCount, (_) {
                        return const SizedBox(
                          width: dashWidth,
                          height: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: kBorderColor),
                          ),
                        );
                      }),
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
                    VendorDetailItem(label: 'Phone', value: vendor['phone']),
                    VendorDetailItem(
                      label: 'Created On',
                      value: vendor['date'],
                    ),
                    VendorDetailItem(
                      label: 'Closing Balance',
                      value: _formatCurrency(vendor['balance']),
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

  Widget _buildLedgerButton({required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(
        Icons.visibility_outlined,
        size: 14,
        color: kWhiteColor,
      ), // Eye icon
      label: const Text(
        'Ledger',
        style: TextStyle(
          fontSize: 11,
          color: kWhiteColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryPurple,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        minimumSize: Size.zero, // Ensure button shrinks to content
        elevation: 1, // Subtle elevation
      ),
    );
  }
}

// --- Helper for bottom detail row ---
class VendorDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const VendorDetailItem({
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
        const SizedBox(height: 4), // Increased spacing slightly
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
