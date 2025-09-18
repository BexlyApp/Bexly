// lib/screens/add_invoice_screen.dart (Example path)
import 'package:flutter/material.dart';

import '../../constants/colorsss.dart';
// import 'package:dotted_border/dotted_border.dart'; // Import if using this package

class AddInvoiceScreen extends StatefulWidget {
  const AddInvoiceScreen({super.key});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & State Variables
  final _referenceController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String? _selectedCustomer;
  String? _selectedPaymentMethod;
  String? _selectedBank;

  // TODO: Add state for selected products list

  // Placeholder data
  final List<String> _customers = [
    'BYD Groups',
    'World Energy',
    'Google',
    'FedEX',
  ];
  final List<String> _paymentMethods = ['Cash', 'Card', 'Bank Transfer', 'UPI'];
  final List<String> _banks = ['Bank A', 'Bank B', 'Bank C'];

  @override
  void dispose() {
    _referenceController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isInvoiceDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        final formattedDate =
            "${picked.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][picked.month - 1]} ${picked.year}";
        if (isInvoiceDate) {
          _invoiceDateController.text = formattedDate;
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
        title: const Text('Add Invoice'),
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
              _buildInvoiceNumberDisplay("#INV1244544"), // Example ID
              const SizedBox(height: 20),
              _buildDropdownField(
                label: 'Customer Name',
                value: _selectedCustomer,
                items: _customers,
                hint: 'Enter Customer Name',
                isRequired: true,
                onChanged: (v) => setState(() => _selectedCustomer = v),
                suffixWidget: _buildAddNewButton(() {
                  /* Nav Add Customer */
                }),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Reference Number',
                controller: _referenceController,
                hint: 'Enter Reference Number',
                isRequired: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Invoice Date',
                      controller: _invoiceDateController,
                      hint: 'Enter Invoice Date',
                      isRequired: true,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'Due Date',
                      controller: _dueDateController,
                      hint: 'Enter Due Date',
                      isRequired: true,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Payment Method',
                value: _selectedPaymentMethod,
                items: _paymentMethods,
                hint: 'Enter Payment Method',
                isRequired: true,
                onChanged: (v) => setState(() => _selectedPaymentMethod = v),
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
                  /* Nav Add Bank */
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
                    if (_formKey.currentState?.validate() ?? false) {
                      /* Save */
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Save Invoice (Not Implemented)'),
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
                    'Save Invoice',
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

  Widget _buildInvoiceNumberDisplay(String invoiceNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: kTagBgColor,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        'Invoice no : $invoiceNumber',
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
            // Using dashed border package is better visually
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            decoration: BoxDecoration(
              // Using simple border as placeholder for dashed
              border: Border.all(
                color: kMutedTextColor.withAlpha((0.2 * 255).toInt()),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            // DottedBorder( // Example with dotted_border package
            //    color: kMutedTextColor, strokeWidth: 1, radius: const Radius.circular(8), borderType: BorderType.RRect, dashPattern: const [6, 4],
            //    child: Container( width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 25.0), ...)
            //  )
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
                  : const SizedBox.shrink(), // Hide default icon if suffix is present
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
                    : null, // Use suffixWidget here
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
} // End _AddInvoiceScreenState
