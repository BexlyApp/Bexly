// lib/screens/add_purchase_order_screen.dart
// Renamed from add_purchase_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:dotted_border/dotted_border.dart'; // Optional: for exact dashed border

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kErrorColor = Colors.red; // For required field indicators
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

class AddPurchaseOrderScreen extends StatefulWidget {
  const AddPurchaseOrderScreen({super.key});

  @override
  State<AddPurchaseOrderScreen> createState() => _AddPurchaseOrderScreenState();
}

class _AddPurchaseOrderScreenState extends State<AddPurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & State Variables
  final _referenceController = TextEditingController();
  final _orderDateController =
      TextEditingController(); // Renamed from _purchaseDateController
  final _dueDateController = TextEditingController(); // Added for Due Date
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String? _selectedVendor;
  String? _selectedBank;
  DateTime? _orderDate; // Renamed from _purchaseDate
  DateTime? _dueDate; // Added for Due Date
  // TODO: Add state for selected products list (e.g., List<Product> _selectedProducts = [];)

  // Placeholder data - Replace with actual data fetching later
  final List<String> _vendors = [
    'Emily',
    'Jerry',
    'Peter',
    'Lisa',
    'New Vendor 1',
    'New Vendor 2',
  ]; // Example vendors
  final List<String> _banks = [
    'Main Account',
    'Savings Account',
    'Business Credit',
  ]; // Example banks

  @override
  void dispose() {
    _referenceController.dispose();
    _orderDateController.dispose();
    _dueDateController.dispose(); // Dispose new controller
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  // Date Picker Function - Handles both Order and Due Date
  Future<void> _selectDate(BuildContext context, bool isOrderDate) async {
    final DateTime initial =
        isOrderDate
            ? (_orderDate ?? DateTime.now())
            : (_dueDate ?? DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      // Apply theme matching the app style
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: kPrimaryPurple, // Header background
                onPrimary: kWhiteColor, // Header text
                onSurface: kTextColor, // Body text
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: kPrimaryPurple,
                ), // Button text
              ), dialogTheme: DialogThemeData(backgroundColor: kWhiteColor), // Background of date picker
            ),
            child: child!,
          ),
    );
    if (picked != null && mounted) {
      setState(() {
        // Use a consistent date format (e.g., dd MMM yyyy)
        final formattedDate = DateFormat('dd MMM yyyy').format(picked);
        if (isOrderDate) {
          _orderDate = picked;
          _orderDateController.text = formattedDate;
        } else {
          _dueDate = picked;
          _dueDateController.text = formattedDate;
        }
      });
    }
  }

  // Function to handle Save action
  void _savePurchaseOrder() {
        Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Add Purchase Order'), // Updated title
        centerTitle: false, // Left-aligned title is common for Add/Edit screens
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor,
        elevation: 0.5, // Subtle elevation
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // No PO ID display at the top for 'Add' screen

              // Reference Number
              _buildTextField(
                label: 'Reference Number',
                controller: _referenceController,
                hint: 'Enter Reference Number',
                isRequired: true, // Required field
                // No validator needed here unless specific format is required
              ),
              const SizedBox(height: 16),

              // Vendor Name Dropdown
              _buildDropdownField(
                label: 'Vendor Name',
                value: _selectedVendor,
                items: _vendors,
                hint: 'Select Vendor Name',
                isRequired: true, // Required field
                onChanged: (value) => setState(() => _selectedVendor = value),
                suffixWidget: _buildAddNewButton(() {
                  /* TODO: Navigate to Add New Vendor Screen */
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add New Vendor (Not Implemented)'),
                    ),
                  );
                }),
                validator:
                    (value) => value == null ? 'Please select a vendor' : null,
              ),
              const SizedBox(height: 16),

              // Purchase Order Date Picker
              _buildDateField(
                label: 'Purchases Order Date', // Label from screenshot
                controller: _orderDateController,
                hint: 'Select Date',
                isRequired: true, // Required field
                onTap: () => _selectDate(context, true), // true for Order Date
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? 'Please select an order date'
                            : null,
              ),
              const SizedBox(height: 16),

              // Due Date Picker
              _buildDateField(
                label: 'Due Date', // Label from screenshot
                controller: _dueDateController,
                hint: 'Select Date',
                isRequired: true, // Required field
                onTap: () => _selectDate(context, false), // false for Due Date
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? 'Please select a due date'
                            : null,
              ),
              const SizedBox(height: 16),

              // Add Products Section
              _buildAddProductsSection(),
              const SizedBox(height: 16),

              // Select Bank Dropdown
              _buildDropdownField(
                label: 'Select Bank',
                value: _selectedBank,
                items: _banks,
                hint: 'Select Bank Account', // More specific hint
                isRequired: true, // Required field
                onChanged: (value) => setState(() => _selectedBank = value),
                suffixWidget: _buildAddNewButton(() {
                  /* TODO: Navigate to Add New Bank Screen */
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add New Bank (Not Implemented)'),
                    ),
                  );
                }),
                validator:
                    (value) => value == null ? 'Please select a bank' : null,
              ),
              const SizedBox(height: 16),

              // Notes Text Area
              _buildTextField(
                label: 'Notes',
                controller: _notesController,
                hint: 'Enter any relevant notes', // Better hint text
                isRequired:
                    false, // Notes might be optional, adjust as needed (Screenshot shows required '*')
                maxLines: 4, // Multi-line input
                // No validator needed if optional
                validator: (value) {
                  // Add validator if required
                  if (value == null || value.isEmpty) {
                    return 'Notes are required'; // Example required message
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Terms & Conditions Text Area
              _buildTextField(
                label: 'Terms & Conditions',
                controller: _termsController,
                hint: 'Enter terms and conditions', // Better hint text
                isRequired:
                    false, // Terms might be optional, adjust as needed (Screenshot shows required '*')
                maxLines: 3, // Multi-line input
                validator: (value) {
                  // Add validator if required
                  if (value == null || value.isEmpty) {
                    return 'Terms & Conditions are required'; // Example required message
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30), // Space before button
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePurchaseOrder, // Call save function
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryPurple, // Button color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Match field border radius
                    ),
                    elevation: 2, // Add slight elevation
                  ),
                  child: const Text(
                    'Save Purchase Order', // Button text matches screenshot
                    style: TextStyle(color: kWhiteColor),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Padding at the bottom
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  // Add Products Section with Dotted Border style
  Widget _buildAddProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Products',
          isRequired: true,
        ), // Products are required
        InkWell(
          onTap: () {
            /* TODO: Show product selection dialog/screen */
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add Product Action (Not Implemented)'),
              ),
            );
          },
          child: Container(
            // Using BoxDecoration to simulate dotted border if package not used
            // For exact look, use `DottedBorder` package:
            // return DottedBorder( borderType: BorderType.RRect, radius: Radius.circular(8), ...)
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            decoration: BoxDecoration(
              // Simulate dashed/dotted line with a solid border for now
              border: Border.all(
                color: kMutedTextColor.withAlpha((0.2 * 255).toInt()), // Use muted text color for border
                width: 1,
                // style: BorderStyle.dashed // This property is on BorderSide, not BoxDecoration border directly. Need DottedBorder package or custom painter for true dashes.
              ),
              borderRadius: BorderRadius.circular(8.0),
              color: kWhiteColor, // White background inside
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.add_circle_outline,
                  color: kPrimaryPurple,
                  size: 24,
                ), // Add icon
                SizedBox(height: 8),
                Text(
                  'Add Product',
                  style: TextStyle(
                    color: kPrimaryPurple, // Purple text color
                    fontWeight: FontWeight.w600, // Bold text
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        // TODO: Display added products list here below the button
        // e.g., if (_selectedProducts.isNotEmpty) ListView.builder(...)
      ],
    );
  }

  // "Add New" Text Button for Dropdowns
  Widget _buildAddNewButton(VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(40, 20), // Ensure tappable area
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerRight,
      ),
      child: const Text(
        'Add New',
        style: TextStyle(
          color: kPrimaryPurple,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --- Reusable Form Field Helpers ---

  // Builds the Section Title (Label) for form fields
  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600, // Bold label
              color: kTextColor,
            ),
          ),
          if (isRequired)
            const Text(
              '*', // Red asterisk for required fields
              style: TextStyle(
                color: kErrorColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // Builds a standard Text Form Field
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator, // Added validator parameter
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, isRequired: isRequired),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14.5), // Input text style
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: kBorderColor,
                width: 1.0,
              ), // Thinner enabled border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: kPrimaryPurple,
                width: 1.5,
              ), // Purple focus border
            ),
            errorBorder: OutlineInputBorder(
              // Style for error state
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kErrorColor, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              // Style for error state when focused
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kErrorColor, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical:
                  maxLines > 1
                      ? 12
                      : 14, // Adjust vertical padding for multi-line
            ),
            filled: true, // Add subtle background fill
            fillColor:
                kWhiteColor, // Or a very light gray kLightGray.withOpacity(0.3)
          ),
          validator:
              validator ?? // Use provided validator or default if required
              (isRequired
                  ? (value) =>
                      (value == null || value.isEmpty)
                          ? '$label is required' // Generic required message
                          : null
                  : null), // No validator if not required and none provided
          autovalidateMode:
              AutovalidateMode
                  .onUserInteraction, // Validate as user types/interacts
        ),
      ],
    );
  }

  // Builds a Date Picker Form Field
  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    required VoidCallback onTap,
    String? Function(String?)? validator, // Added validator parameter
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, isRequired: isRequired),
        TextFormField(
          controller: controller,
          readOnly: true, // Prevent manual text input
          onTap: onTap, // Show date picker on tap
          style: const TextStyle(fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kPrimaryPurple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kErrorColor, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kErrorColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            // Calendar Icon Suffix
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 10.0), // Adjust padding
              child: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: kMutedTextColor,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0, // Allow tight constraints
              minHeight: 0,
            ),
            filled: true,
            fillColor: kWhiteColor,
          ),
          validator: validator, // Use the provided validator
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

  // Builds a Dropdown Form Field
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    bool isRequired = false,
    required ValueChanged<String?> onChanged,
    Widget? suffixWidget, // For the 'Add New' button
    String? Function(String?)? validator, // Added validator parameter
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, isRequired: isRequired),
        DropdownButtonFormField<String>(
          value: value,
          items:
              items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14.5),
                      ), // Dropdown item text style
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
          isExpanded: true, // Ensure dropdown takes full width
          icon:
              suffixWidget ==
                      null // Hide default icon if suffixWidget exists
                  ? const Icon(
                    Icons.keyboard_arrow_down,
                    color: kMutedTextColor,
                    size: 22,
                  )
                  : const SizedBox.shrink(), // No default icon if Add New is present
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kPrimaryPurple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kErrorColor, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kErrorColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14, // Consistent vertical padding
            ),
            // Add New Button Suffix
            suffixIcon:
                suffixWidget != null
                    ? Padding(
                      padding: const EdgeInsets.only(
                        right: 12.0,
                      ), // Padding for Add New button
                      child: suffixWidget,
                    )
                    : null, // No suffix if button not provided
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0, // Allow tight constraints
              minHeight: 0,
            ),
            filled: true,
            fillColor: kWhiteColor,
          ),
          validator: validator, // Use the provided validator
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}
