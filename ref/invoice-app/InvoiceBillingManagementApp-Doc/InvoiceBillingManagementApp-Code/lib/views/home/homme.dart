import 'package:flutter/material.dart';

import '../creditnotes/creditnotes.dart';
import '../customerslist/customers.dart';
import '../deliverychalanlist/deliverychalan.dart';
import '../expenses/expenses.dart';
import '../inventorylist/inventory.dart';
import '../invoices/invoices.dart';
import '../payments/payments.dart';
import '../products/products.dart';
import '../purchaseorder/purchaseorder.dart';
import '../purchaseslist/purchaseslist.dart';
import '../qotationslist/qotations.dart';
import '../salesreturn/salesreturn.dart';
import '../signaturelist/signature.dart';
import '../templates/templates.dart';
import '../vendors/vendors.dart';

// --- Color Constants (Sampled from Image) ---
const Color kPrimaryPurple = Color(0xFF3A2C5F); // Dark purple background
const Color kLightPurpleBackground = Color(0xFFF4F2F9); // Icon backgrounds
const Color kIconColor = Color(0xFF6A5AA8); // Purple icon color
const Color kTextColor = Colors.black87;
const Color kMutedTextColor = Colors.black54;
const Color kWhiteColor = Colors.white;
const Color kGreenPaid = Color(0xFF4CAF50);
const Color kBlueDrafted = Color(0xFF2196F3);
const Color kYellowPartial = Color(0xFFFFC107);
const Color kRedOverdue = Color(0xFFF44336);
const Color kLightGrayBackground = Color(0xFFF8F9FA); // Card backgrounds
const Color kBorderColor = Colors.black12;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickAccess(context),
        const SizedBox(height: 20),
        _buildInvoiceStatics(),
        const SizedBox(height: 20),
        _buildRecentInvoices(),
        const SizedBox(height: 20), // Add some bottom padding
      ],
    );
  }

  // Optional: Mimic the status bar look if needed within the app body


  Widget _buildQuickAccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 25.0,
              runSpacing: 7.0,
              alignment: WrapAlignment.spaceBetween,
              children: [
                QuickAccessItem(
                  index: 0,
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>ProductCatalogScreen()));
                  },
                ),
                QuickAccessItem(
                  index: 1,
                  icon: Icons.people_outline,
                  label: 'Customers',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>CustomersListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 2,
                  icon: Icons.receipt_long_outlined,
                  label: 'Invoices',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>InvoiceListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 3,
                  icon: Icons.assignment_return_outlined,
                  label: 'Sales\nReturn',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>PurchasesListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 4,
                  icon: Icons.request_quote_outlined,
                  label: 'Quotation',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>QuotationListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 5,
                  icon: Icons.store_mall_directory_outlined,
                  label: 'Vendors',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>VendorListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 6,
                  icon: Icons.local_shipping_outlined,
                  label: 'Delivery\nChallan',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>DeliveryChallanListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 7,
                  icon: Icons.note_alt_outlined,
                  label: 'Credit\nNote',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>CreditNotesListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 8,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payments',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>PaymentsListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 9,
                  icon: Icons.add_shopping_cart_outlined,
                  label: 'Purchase',
                  onTap: () {},
                ),
                QuickAccessItem(
                  index: 10,
                  icon: Icons.assignment_return, // Purchase Return
                  label: 'Purchase Return',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>PurchasesListVScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 11,
                  icon: Icons.shopping_bag_outlined, // Purchase Order
                  label: 'Purchase Order',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>PurchaseOrderListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 12,
                  icon: Icons.inventory_2_outlined, // Inventory
                  label: 'Inventory',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>InventoryListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 13,
                  icon: Icons.money_off_csred_outlined, // Expense
                  label: 'Expense',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>ExpensesListScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 14,
                  icon: Icons.description_outlined, // Templates
                  label: 'Templates',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>TemplatesScreen()));

                  },
                ),
                QuickAccessItem(
                  index: 15,
                  icon: Icons.border_color_outlined, // Signatures
                  label: 'Signatures',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>SignaturesListScreen()));

                  },
                ),


              ],
            ),

            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_dot(true), const SizedBox(width: 6), _dot(false)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.black87 : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInvoiceStatics() {
    // Calculate total for flex calculation (approximation)
    const int paidFlex = 738; // Use amounts directly for flex
    const int draftedFlex = 4787;
    const int partialFlex = 150;
    const int overdueFlex = 645;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: kLightGrayBackground,
          borderRadius: BorderRadius.circular(12.0),
          // border: Border.all(color: kBorderColor) // Optional border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invoice Statics', // Corrected typo from 'Statics'
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Weekly', style: TextStyle(color: kMutedTextColor)),
                      SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: kMutedTextColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align items to top
              children: const [
                InvoiceStatusColumn(
                  color: kGreenPaid,
                  status: 'Paid',
                  amount: '\$738',
                ),
                InvoiceStatusColumn(
                  color: kBlueDrafted,
                  status: 'Drafted',
                  amount: '\$4787',
                ),
                InvoiceStatusColumn(
                  color: kYellowPartial,
                  status: 'Partially Paid',
                  amount: '\$150',
                ),
                InvoiceStatusColumn(
                  color: kRedOverdue,
                  status: 'Overdue',
                  amount: '\$645',
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Progress Bar Visualization
            ClipRRect(
              // Clip the corners of the row
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 8, // Height of the progress bar
                child: Row(
                  children: [
                    Expanded(
                      flex: paidFlex,
                      child: Container(color: kGreenPaid),
                    ),
                    Expanded(
                      flex: draftedFlex,
                      child: Container(color: kBlueDrafted),
                    ),
                    Expanded(
                      flex: partialFlex,
                      child: Container(color: kYellowPartial),
                    ),
                    Expanded(
                      flex: overdueFlex,
                      child: Container(color: kRedOverdue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Invoices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kWhiteColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  /* Handle View All */
                },
                child: const Text(
                  'View All',
                  style: TextStyle(color: kWhiteColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // List of Invoices (using Column for static example)
          _buildInvoiceCard(
            logoAsset:
                'placeholder', // Replace with your logo asset path or URL
            invoiceNumber: '#INV0021',
            groupName: 'BYD Groups',
            amount: '\$264',
            paymentMode: 'Cash',
            dueDate: '23 Apr 2024',
            status: 'Paid',
            statusColor: kGreenPaid,
          ),
          const SizedBox(height: 10),
          // Add more _buildInvoiceCard widgets here if needed
          _buildInvoiceCard(
            // Example of another card (partially visible)
            logoAsset: 'placeholder',
            invoiceNumber: '#INV0020',
            groupName: 'Another Group',
            amount: '\$1500',
            paymentMode: 'Card',
            dueDate: '30 Apr 2024',
            status: 'Drafted',
            statusColor: kBlueDrafted,
          ),
        ],
      ),
    );
  }

  // --- Reusable Helper Widgets ---

  Widget _buildInvoiceCard({
    required String logoAsset,
    required String invoiceNumber,
    required String groupName,
    required String amount,
    required String paymentMode,
    required String dueDate,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white, // White background for card
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200), // Subtle border
        boxShadow: [
          // Optional subtle shadow
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder for Logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300, // Placeholder color
                  borderRadius: BorderRadius.circular(8),
                  // image: DecorationImage(image: AssetImage(logoAsset), fit: BoxFit.contain) // Use this when you have the asset
                ),
                child: const Center(
                  child: Text(
                    'Logo',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ), // Placeholder text
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoiceNumber,
                      style: const TextStyle(
                        color: kPrimaryPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 16,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(
                        (0.2 * 255).toInt(),
                      ), // Lighter background
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Three dots icon
                  const Icon(Icons.more_vert, color: kMutedTextColor, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Divider (Optional)
          // Divider(color: Colors.grey.shade200, height: 10),
          // const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color:
                  kLightGrayBackground, // Very light gray for the details row
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InvoiceDetailItem(label: 'Amount', value: amount),
                InvoiceDetailItem(label: 'Mode of Payment', value: paymentMode),
                InvoiceDetailItem(label: 'Due Date', value: dueDate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper for Invoice Card Details
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

// Helper for Frequent Customer Avatar
class CustomerAvatar extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? imageUrl; // Optional: for actual images
  final bool isAddButton;

  const CustomerAvatar({
    super.key, // Add Key
    this.icon,
    required this.label,
    this.imageUrl,
    this.isAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the background image only if imageUrl is provided and valid
    ImageProvider? networkImageProvider;
    if (!isAddButton &&
        imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        Uri.tryParse(imageUrl!)?.hasAbsolutePath == true) {
      networkImageProvider = NetworkImage(imageUrl!);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10.0), // Spacing between items
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
                isAddButton
                    ? kWhiteColor
                    : Colors.grey.shade300, // Fallback/loading bg
            backgroundImage: networkImageProvider, // Use NetworkImage here
            // Optional: Handle image loading errors if needed
            onBackgroundImageError:
                networkImageProvider != null
                    ? (exception, stackTrace) {
                      // Simple error handling: print error and maybe show placeholder icon
                      // You could potentially use setState here if in a StatefulWidget to show an error icon
                    }
                    : null,
            child:
                isAddButton
                    ? Icon(
                      icon ?? Icons.add,
                      size: 24,
                      color: kPrimaryPurple,
                    ) // Ensure icon is not null
                    : networkImageProvider == null &&
                        !isAddButton // Show person icon ONLY if NO image AND not the add button
                    ? const Icon(Icons.person, size: 30, color: kMutedTextColor)
                    : null, // Otherwise, no child (let backgroundImage show)
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: kWhiteColor, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Helper for Quick Access Item
class QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int index; // Add this for assigning unique gradient

  const QuickAccessItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 32 - (4 * 10)) / 5;

    final List<List<Color>> gradientColors = [
      [Color(0xFF6A11CB), Color(0xFF2575FC)],
      [Color(0xFFFF512F), Color(0xFFDD2476)],
      [Color(0xFF36D1DC), Color(0xFF5B86E5)],
      [Color(0xFF0F2027), Color(0xFF2C5364)],
      [Color(0xFFF7971E), Color(0xFFFFD200)],
      [Color(0xFF4E54C8), Color(0xFF8F94FB)],
      [Color(0xFF00C9FF), Color(0xFF92FE9D)],
      [Color(0xFF43CEA2), Color(0xFF185A9D)],
      [Color(0xFFEF32D9), Color(0xFF89FFFD)],
    ];

    final List<Color> selectedGradient =
        gradientColors[index % gradientColors.length];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selectedGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selectedGradient.last.withAlpha((0.2 * 255).toInt()),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: kMutedTextColor,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for Invoice Statics Column
class InvoiceStatusColumn extends StatelessWidget {
  final Color color;
  final String status;
  final String amount;

  const InvoiceStatusColumn({
    super.key,
    required this.color,
    required this.status,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: const TextStyle(fontSize: 12, color: kMutedTextColor),
              overflow:
                  TextOverflow
                      .ellipsis, // Handle potential overflow on small screens
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 16.0), // Indent amount slightly
          child: Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
        ),
      ],
    );
  }
}
