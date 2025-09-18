// lib/screens/add_purchase_screen.dart (Example path)
import 'package:flutter/material.dart';
// import 'package:dotted_border/dotted_border.dart'; // Optional

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
// const Color kTagBgColor = Color(0xFFFFF0E0); // Not directly used in this form
// const Color kTagTextColor = Color(0xFFFA8100); // Not directly used in this form
const Color kErrorColor = Colors.red;
const Color kWhiteColor = Colors.white;
// --- End Color Definitions ---

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & State Variables
  final _purchaseDateController = TextEditingController();
  final _referenceController = TextEditingController();
  final _supplierInvoiceController =
      TextEditingController(); // Controller for the new field
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String? _selectedVendor;
  String? _selectedBank;

  // TODO: Add state for selected products list

  // Placeholder data
  final List<String> _vendors = [
    'Emily',
    'Jerry',
    'Peter',
    'Lisa',
  ]; // Vendor names
  final List<String> _banks = ['Bank A', 'Bank B', 'Bank C'];

  @override
  void dispose() {
    _purchaseDateController.dispose();
    _referenceController.dispose();
    _supplierInvoiceController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
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
        // Simple formatting, use intl package for better localization
        final formattedDate =
            "${picked.day}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
        if (isPurchaseDate) {
          _purchaseDateController.text = formattedDate;
        } else {
          _supplierInvoiceController.text = formattedDate;
        } // Assuming Supplier Invoice SN is a date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Purchase'),
        centerTitle: true,
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
              // No ID display needed at the top for Add screen generally
              _buildDropdownField(
                label: 'Vendor Name',
                value: _selectedVendor,
                items: _vendors,
                hint: 'Select Vendor Name',
                isRequired: true,
                onChanged: (v) => setState(() => _selectedVendor = v),
                suffixWidget: _buildAddNewButton(() {
                  /* TODO: Nav Add Vendor */
                }),
              ),
              const SizedBox(height: 16),
              _buildDateField(
                label: 'Purchases Date',
                controller: _purchaseDateController,
                hint: 'Select Date',
                isRequired: true,
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Reference Number',
                controller: _referenceController,
                hint: 'Enter Reference Number',
                isRequired: true,
              ),
              const SizedBox(height: 16),
              // Changed to Supplier Invoice Serial Number (Assuming Date Picker for now, might need TextField)
              _buildDateField(
                label: 'Supplier Invoice Serial Number',
                controller: _supplierInvoiceController,
                hint: 'Select Date',
                isRequired: true,
                onTap: () => _selectDate(context, false),
              ),
              // If it's truly a serial *number* or text, use _buildTextField instead:
              // _buildTextField(label: 'Supplier Invoice Serial Number', controller: _supplierInvoiceController, hint: 'Enter Serial Number', isRequired: true),
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
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
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
                    'Save Purchase',
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
        // TODO: Display added products list here
      ],
    );
  }

  Widget _buildAddNewButton(VoidCallback onPressed) {
    // Fully implemented helper
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

  // --- Reusable Form Field Helpers (Full Implementations) ---
  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    // Fully implemented helper
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
    // Fully implemented helper
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
    // Fully implemented helper
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
    // Fully implemented helper
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
} // End _AddPurchaseScreenState
