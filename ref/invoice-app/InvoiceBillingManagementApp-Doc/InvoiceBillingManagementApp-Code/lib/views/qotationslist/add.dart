// lib/screens/add_quotation_screen.dart (Example path)
import 'package:flutter/material.dart';

import 'details.dart';
// import 'package:dotted_border/dotted_border.dart'; // Optional

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kTagBgColor = Color(0xFFFFF0E0); // Orange tag bg
const Color kTagTextColor = Color(0xFFFA8100); // Orange tag text
const Color kErrorColor = Colors.red;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

class AddQuotationScreen extends StatefulWidget {
  const AddQuotationScreen({super.key});

  @override
  State<AddQuotationScreen> createState() => _AddQuotationScreenState();
}

class _AddQuotationScreenState extends State<AddQuotationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & State Variables
  final _quotationDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String? _selectedCustomer;
  String? _selectedBank;

  final double _calculatedAmount = 0.0; // For Invoice Summary Placeholder

  // Placeholder data
  final List<String> _customers = ['BYD Groups', 'World Energy', 'Google'];
  final List<String> _banks = ['Bank X', 'Bank Y', 'Bank Z'];

  @override
  void dispose() {
    _quotationDateController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isQuotationDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      // Optional: Style the date picker
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: kPrimaryPurple,
                onPrimary: kWhiteColor,
                onSurface: kTextColor,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: kPrimaryPurple),
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null && mounted) {
      setState(() {
        final formattedDate =
            "${picked.day}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
        if (isQuotationDate) {
          _quotationDateController.text = formattedDate;
        } else {
          _dueDateController.text = formattedDate;
        }
      });
    }
  }

  // TODO: Add function to calculate amount based on selected products


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Quotations'),
        centerTitle: true, // Plural matches screenshot
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIdDisplay("Quotation Id :", "#QUO - 000016"), // Example ID
              const SizedBox(height: 20),
              _buildDropdownField(
                label: 'Customer Name',
                value: _selectedCustomer,
                items: _customers,
                hint: 'Enter Customer Name',
                isRequired: true,
                onChanged: (v) => setState(() => _selectedCustomer = v),
                suffixWidget: _buildAddNewButton(() {
                  /* TODO: Nav Add Customer */
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Quotation Date',
                      controller: _quotationDateController,
                      hint: 'Select Date',
                      isRequired: true,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'Due Date',
                      controller: _dueDateController,
                      hint: 'Select Date',
                      isRequired: true,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAddProductsSection(),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Select Bank',
                value: _selectedBank,
                items: _banks,
                hint: 'Select',
                isRequired: true,
                onChanged: (v) => setState(() => _selectedBank = v),
                suffixWidget: _buildAddNewButton(() {
                  /* TODO: Nav Add Bank */
                }),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Notes',
                controller: _notesController,
                hint: 'Notes',
                isRequired: true,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Terms & Conditions',
                controller: _termsController,
                hint: 'Terms',
                isRequired: true,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Invoice Summary'), // Title from screenshot
              _buildQuotationSummaryDisplay(_calculatedAmount), // Display area
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuotationDetailsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Quotation',
                    style: TextStyle(color: kWhiteColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildIdDisplay(String label, String id) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: kTagBgColor,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        '$label $id',
        style: const TextStyle(
          fontSize: 12,
          color: kTagTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAddProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Products', isRequired: true),
        InkWell(
          onTap: () {
            /* TODO: Show product selection */
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add Product Action (Not Implemented)'),
              ),
            );
          },
          child: Container(
            // Use dotted_border package for exact look
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: kMutedTextColor.withAlpha((0.2 * 255).toInt()),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_circle_outline, color: kPrimaryPurple, size: 24),
                SizedBox(height: 8),
                Text(
                  'Add Product',
                  style: TextStyle(
                    color: kPrimaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // TODO: Display added products list here (and update _calculatedAmount)
      ],
    );
  }

  Widget _buildQuotationSummaryDisplay(double amount) {
    // Simple display matching the screenshot's "Invoice Summary" section
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10.0,
      ), // Only vertical padding needed
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Amount',
            style: TextStyle(fontSize: 14, color: kTextColor),
          ),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kTextColor,
            ),
          ), // Show calculated/default amount
        ],
      ),
    );
  }

  Widget _buildAddNewButton(VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: const Text(
        'Add New',
        style: TextStyle(color: kPrimaryPurple, fontSize: 13),
      ),
    );
  }

  // --- Reusable Form Field Helpers ---
  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          if (isRequired)
            const Text(
              '*',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, isRequired: isRequired),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kPrimaryPurple, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 16 : 14,
            ),
          ),
          validator:
              isRequired
                  ? (value) =>
                      (value == null || value.isEmpty)
                          ? 'This field is required'
                          : null
                  : null,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, isRequired: isRequired),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kPrimaryPurple, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: kMutedTextColor,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          validator:
              isRequired
                  ? (value) =>
                      (value == null || value.isEmpty)
                          ? 'Please select a date'
                          : null
                  : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    bool isRequired = false,
    required ValueChanged<String?> onChanged,
    Widget? suffixWidget,
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
                      child: Text(item, style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
          isExpanded: true,
          icon:
              suffixWidget == null
                  ? const Icon(
                    Icons.keyboard_arrow_down,
                    color: kMutedTextColor,
                  )
                  : const SizedBox.shrink(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kPrimaryPurple, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon:
                suffixWidget != null
                    ? Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: suffixWidget,
                    )
                    : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          validator:
              isRequired
                  ? (value) =>
                      (value == null) ? 'Please select an option' : null
                  : null,
        ),
      ],
    );
  }
} // End _AddQuotationScreenState
