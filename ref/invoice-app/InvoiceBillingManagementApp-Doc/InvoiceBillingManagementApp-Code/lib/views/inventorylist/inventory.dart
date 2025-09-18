// lib/screens/inventory_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for FilteringTextInputFormatter
import 'package:intl/intl.dart';

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50); // For count badge background
const Color kErrorColor = Color(
  0xFFD32F2F,
); // For required fields and Stock Out button
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;
const Color kStockInBlue = Color(0xFF3B82F6); // Blue similar to screenshots
const Color kStockOutRed = kErrorColor; // Reuse error color
// --- End Color Definitions ---

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  // --- Placeholder Data (Matches Inventory List Screenshot) ---
  final List<Map<String, dynamic>> allInventoryData = const [
    {
      'id': '#P125390',
      'name': 'Beats Pro',
      'price1': 130.0,
      'price2': null, // Only one price shown
      'alertQuantity': 10,
      'units': 'PC', // Needed for dialogs
      'imageUrl':
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aGVhZHBob25lc3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60', // Example image
    },
    {
      'id': '#P125389',
      'name': 'Nike Jordan',
      'price1': 253.0, // First price (assuming Selling?)
      'price2': 248.0, // Second price (assuming Purchase?)
      'alertQuantity': 10,
      'units': 'PC',
      'imageUrl':
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8c2hvZXN8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60', // Example image
    },
    {
      'id': '#P125390',
      'name': 'Beats Pro',
      'price1': 130.0,
      'price2': null, // Only one price shown
      'alertQuantity': 10,
      'units': 'PC', // Needed for dialogs
      'imageUrl':
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aGVhZHBob25lc3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60', // Example image
    },
    {
      'id': '#P125389',
      'name': 'Nike Jordan',
      'price1': 253.0, // First price (assuming Selling?)
      'price2': 248.0, // Second price (assuming Purchase?)
      'alertQuantity': 10,
      'units': 'PC',
      'imageUrl':
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8c2hvZXN8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60', // Example image
    },
    {
      'id': '#P125390',
      'name': 'Beats Pro',
      'price1': 130.0,
      'price2': null, // Only one price shown
      'alertQuantity': 10,
      'units': 'PC', // Needed for dialogs
      'imageUrl':
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aGVhZHBob25lc3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60', // Example image
    },
    {
      'id': '#P125389',
      'name': 'Nike Jordan',
      'price1': 253.0, // First price (assuming Selling?)
      'price2': 248.0, // Second price (assuming Purchase?)
      'alertQuantity': 10,
      'units': 'PC',
      'imageUrl':
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8c2hvZXN8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60', // Example image
    },

    // Add more items to test scrolling
  ];
  // --- End Placeholder Data ---

  // --- Dialog Functions ---
  void _showStockDialog(
    BuildContext context,
    Map<String, dynamic> item,
    bool isAddingStock,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return StockAdjustmentDialog(item: item, isAddingStock: isAddingStock);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedList = allInventoryData;
    final int totalCount =
        displayedList.length; // Or sum of quantities if needed

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
        title: Row(
          // Title with count badge
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Inventory'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kAccentGreen.withAlpha(
                  (0.2 * 255).toInt(),
                ), // Use accent green for badge
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                totalCount.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kWhiteColor, // White text on badge
                ),
              ),
            ),
          ],
        ),
        centerTitle: false, // Left-align title
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26, color: kTextColor),
            onPressed: () {
              /* TODO: Search Implementation */
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search Action (Not Implemented)'),
                ),
              );
            },
          ),
          IconButton(
            // Filter/Sort Icon
            icon: const Icon(
              Icons.tune_outlined,
              size: 24,
              color: kTextColor,
            ), // Or Icons.filter_list
            onPressed: () {
              /* TODO: Filter/Sort Implementation */
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter/Sort Action (Not Implemented)'),
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemCount: displayedList.length,
        itemBuilder:
            (context, index) => InventoryListItem(
              item: displayedList[index],
              onStockIn:
                  () => _showStockDialog(
                    context,
                    displayedList[index],
                    true,
                  ), // Pass item and flag
              onStockOut:
                  () => _showStockDialog(
                    context,
                    displayedList[index],
                    false,
                  ), // Pass item and flag
            ),
      ),
      // Assuming the standard purple FAB is for adding a NEW inventory item
      // If it's not needed based on workflow, remove it.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          /* TODO: Navigate to Add New Inventory Item Screen */
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add New Item Action (Not Implemented)'),
            ),
          );
        },
        backgroundColor: kPrimaryPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        elevation: 2.0,
        child: const Icon(Icons.add, color: kWhiteColor),
      ),
    );
  }
}

// --- Separate Inventory List Item Widget ---
class InventoryListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onStockIn;
  final VoidCallback onStockOut;

  const InventoryListItem({
    super.key,
    required this.item,
    required this.onStockIn,
    required this.onStockOut,
  });

  // Helper to format currency
  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$', // Using $ symbol
      decimalDigits: 0, // No decimals shown in screenshot price
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0, // Slightly more elevation for distinct cards
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        // side: BorderSide(color: kBorderColor.withOpacity(0.5)), // Optional border
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image, ID/Name, Price(s)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    item['imageUrl'] ?? '', // Handle null image URL
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (ctx, err, st) => Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: kLightGray,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(
                            Icons
                                .image_not_supported_outlined, // Placeholder icon
                            size: 24,
                            color: kMutedTextColor,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                // ID and Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['id'] ?? 'No ID', // Item ID
                        style: const TextStyle(
                          color: kMutedTextColor, // Muted color for ID
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['name'] ?? 'Unnamed Item', // Item Name
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Price(s) - Aligned Right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item['price1'] != null)
                      Text(
                        _formatCurrency(item['price1']), // Format first price
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                    if (item['price2'] != null) ...[
                      // If second price exists
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(item['price2']), // Format second price
                        style: const TextStyle(
                          fontSize: 13, // Slightly smaller second price
                          fontWeight: FontWeight.w500,
                          color:
                              kMutedTextColor, // Muted color for second price
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12), // Space before bottom row
            // Bottom Row: Alert Quantity, Stock In/Out Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Alert Quantity Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alert Quantity',
                      style: TextStyle(fontSize: 11, color: kMutedTextColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['alertQuantity']?.toString() ?? '0',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextColor,
                      ),
                    ),
                  ],
                ),
                // Stock Action Buttons
                Row(
                  children: [
                    _buildStockButton(
                      text: 'Stock In',
                      icon: Icons.add_circle_outline,
                      color: kStockInBlue,
                      onPressed: onStockIn,
                    ),
                    const SizedBox(width: 10),
                    _buildStockButton(
                      text: 'Stock Out',
                      icon: Icons.remove_circle_outline,
                      color: kStockOutRed,
                      onPressed: onStockOut,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build Stock In/Out buttons
  Widget _buildStockButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(
          (0.2 * 255).toInt(),
        ), // Light background tint
        foregroundColor: color, // Icon and text color
        elevation: 0, // No shadow
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        minimumSize: const Size(0, 28), // Control button height
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// --- Stock Adjustment Dialog Widget ---
class StockAdjustmentDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isAddingStock; // True for Add Stock, False for Remove Stock

  const StockAdjustmentDialog({
    super.key,
    required this.item,
    required this.isAddingStock,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController =
      TextEditingController(); // For 'Name' / 'Reason' field
  final _quantityController = TextEditingController(
    text: '0',
  ); // Start quantity at 0
  final _notesController = TextEditingController();
  final _unitsController = TextEditingController(); // To display units

  @override
  void initState() {
    super.initState();
    // Pre-fill fields based on context
    _nameController.text =
        widget.isAddingStock
            ? 'Stock Added'
            : 'Stock Removed'; // Default reason
    _notesController.text =
        widget.isAddingStock
            ? 'Added new quantity via manual entry'
            : 'Removed quantity via manual entry'; // Default note
    _unitsController.text =
        widget.item['units'] ?? 'N/A'; // Display unit from item data
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  // --- Form Field Builders (Specific to Dialog) ---

  Widget _buildDialogTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            if (isRequired)
              const Text(
                '*',
                style: TextStyle(
                  color: kErrorColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: 14,
            color: readOnly ? kMutedTextColor : kTextColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: kBorderColor.withAlpha((0.2 * 255).toInt()),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kPrimaryPurple, width: 1.5),
            ),
            filled: true,
            fillColor:
                readOnly
                    ? kLightGray.withAlpha((0.2 * 255).toInt())
                    : kWhiteColor, // Different background if read-only
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 12 : 10,
            ), // Compact padding
            isDense: true,
          ),
          validator:
              validator ??
              (isRequired
                  ? (value) =>
                      (value == null || value.isEmpty)
                          ? '$label is required'
                          : null
                  : null),
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Quantity',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            Text(
              '*',
              style: TextStyle(
                color: kErrorColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center, // Center the quantity number
          style: const TextStyle(fontSize: 14, color: kTextColor),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: kBorderColor.withAlpha((0.2 * 255).toInt()),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kPrimaryPurple, width: 1.5),
            ),
            filled: true,
            fillColor: kWhiteColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 10,
            ), // Adjust padding
            isDense: true,
            // Simple +/- buttons (could be improved with NumberPicker package)
            prefixIcon: InkWell(
              onTap: () {
                int currentVal = int.tryParse(_quantityController.text) ?? 0;
                if (currentVal > 0) {
                  _quantityController.text = (currentVal - 1).toString();
                }
              },
              child: const Icon(
                Icons.remove_circle_outline,
                color: kMutedTextColor,
                size: 20,
              ),
            ),
            suffixIcon: InkWell(
              onTap: () {
                int currentVal = int.tryParse(_quantityController.text) ?? 0;
                _quantityController.text = (currentVal + 1).toString();
              },
              child: const Icon(
                Icons.add_circle_outline,
                color: kMutedTextColor,
                size: 20,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Quantity is required';
            }
            final int? qty = int.tryParse(value);
            if (qty == null || qty <= 0) {
              return 'Must be > 0';
            }
            // Optional: Check if removing more than available stock in a real app
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isAddingStock ? 'Add Stock' : 'Remove Stock';
    final String buttonText =
        widget.isAddingStock ? 'Add Quantity' : 'Remove Quantity';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      backgroundColor: kWhiteColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Make dialog height fit content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: kMutedTextColor,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form Fields
              _buildDialogTextField(
                label: 'Name', // Label changed from screenshot hint
                controller: _nameController,
                hint: 'Enter reason or reference', // Better hint
                isRequired: true,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align tops of fields
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildQuantityField(),
                  ), // Quantity takes more space
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1, // Units takes less space
                    child: _buildDialogTextField(
                      label: 'Units',
                      controller: _unitsController,
                      hint: 'Unit', // Should not be editable generally
                      isRequired: true,
                      readOnly: true, // Make units read-only
                      validator: null, // No validation needed if read-only
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDialogTextField(
                label: 'Notes',
                controller: _notesController,
                hint: 'Add any relevant notes...', // Better hint
                isRequired: false, // Notes are often optional
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMutedTextColor,
                        side: const BorderSide(color: kBorderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: Implement stock adjustment logic here

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Stock ${widget.isAddingStock ? "Added" : "Removed"} (Simulated)',
                              ),
                            ),
                          );
                          Navigator.of(
                            context,
                          ).pop(); // Close dialog on success
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryPurple,
                        foregroundColor: kWhiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: Text(buttonText),
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
}
