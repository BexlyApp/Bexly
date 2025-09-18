// lib/screens/add_sales_return_screen.dart (Example path)
import 'package:flutter/material.dart';

import 'details.dart';
// import 'package:dotted_border/dotted_border.dart'; // Optional: for dashed border

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

class AddSalesReturnScreen extends StatefulWidget {
  const AddSalesReturnScreen({super.key});

  @override
  State<AddSalesReturnScreen> createState() => _AddSalesReturnScreenState();
}

class _AddSalesReturnScreenState extends State<AddSalesReturnScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & State Variables
  final _salesReturnDateController = TextEditingController();
  final _dueDateController =
      TextEditingController(); // Keep or remove based on requirement
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String? _selectedCustomer;
  String? _selectedBank;

  // TODO: Add state for selected products list

  // Placeholder data
  final List<String> _customers = ['Naveen Bansel', 'Customer B', 'Customer C'];
  final List<String> _banks = ['Bank A', 'Bank B', 'Bank C'];

  @override
  void dispose() {
    _salesReturnDateController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isSalesReturnDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      // Optional: Style the date picker
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryPurple, // Header background color
              onPrimary: kWhiteColor, // Header text color
              onSurface: kTextColor, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryPurple,
              ), // Button text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        // Simple formatting, use intl package for better localization
        final formattedDate =
            "${picked.day}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
        if (isSalesReturnDate) {
          _salesReturnDateController.text = formattedDate;
        } else {
          _dueDateController.text = formattedDate;
        }
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
        title: const Text('Add Sales Return'),
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
              _buildIdDisplay("Sales Return ID :", "#CN-000030"), // Example ID
              const SizedBox(height: 20),
              _buildDropdownField(
                label: 'Customer',
                value: _selectedCustomer,
                items: _customers,
                hint: 'Select Customer',
                isRequired: true,
                onChanged: (v) => setState(() => _selectedCustomer = v),
                suffixWidget: _buildAddNewButton(() {
                  /* TODO: Nav Add Customer */
                }),
              ),
              const SizedBox(height: 16),
              _buildDateField(
                label: 'Sales Return Date',
                controller: _salesReturnDateController,
                hint: 'Select Date',
                isRequired: true,
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 16),
              _buildDateField(
                label: 'Due Date',
                controller: _dueDateController,
                hint: 'Select Date',
                isRequired: true,
                onTap: () => _selectDate(context, false),
              ), // Keep if needed
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalesReturnDetailsScreen(),
                      ),
                    );

                    {
                      /* TODO: Save Sales Return */
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Save Sales Return (Not Implemented)'),
                        ),
                      );
                    }
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
                    'Save Sales Return',
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
              ), // Simple border
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
} // End _AddSalesReturnScreenState
