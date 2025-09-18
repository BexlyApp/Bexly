// lib/screens/tax_rates_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for input formatters

// --- Placeholder Navigation Targets ---
// None needed directly for this screen structure

// --- Define Colors (Consider moving to a central theme file) ---
const Color kPrimaryPurple = Color(0xFF6A00F4); // Used for buttons/icons
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;
const Color kAccentGreen = Color(0xFF4CAF50); // For the count badge & Active status
const Color kErrorColor = Colors.redAccent; // For delete icon maybe
const Color kDisabledSwitchTrack = Colors.black26; // Color for inactive switch track
// --- End Color Definitions ---

class TaxRatesScreen extends StatelessWidget { // Changed to StatelessWidget
  const TaxRatesScreen({super.key});

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic (e.g., from API, database)
  final List<Map<String, dynamic>> taxRatesData = const [
    {'id': '1', 'name': 'SGST', 'rate': 8.0, 'status': 'Active', 'type': 'Percentage'},
    {'id': '2', 'name': 'NO TAX', 'rate': 5.0, 'status': 'Active', 'type': 'Percentage'}, // Rate seems unusual for "NO TAX"
    {'id': '3', 'name': 'GST', 'rate': 8.0, 'status': 'Active', 'type': 'Percentage'},
    {'id': '4', 'name': 'CGST', 'rate': 18.0, 'status': 'Active', 'type': 'Percentage'},
    {'id': '5', 'name': 'Service Charge', 'rate': 18.0, 'status': 'Active', 'type': 'Percentage'},
    {'id': '6', 'name': 'VAT Standard rate', 'rate': 20.0, 'status': 'Inactive', 'type': 'Percentage'}, {'id': '1', 'name': 'SGST', 'rate': 8.0, 'status': 'Active', 'type': 'Percentage'},
    {'id': '2', 'name': 'NO TAX', 'rate': 5.0, 'status': 'Active', 'type': 'Percentage'}, // Rate seems unusual for "NO TAX"
    {'id': '3', 'name': 'GST', 'rate': 8.0, 'status': 'Active', 'type': 'Percentage'},
    {'id': '4', 'name': 'CGST', 'rate': 18.0, 'status': 'Active', 'type': 'Percentage'},
    {'id': '5', 'name': 'Service Charge', 'rate': 18.0, 'status': 'Active', 'type': 'Percentage'},
    {'id': '6', 'name': 'VAT Standard rate', 'rate': 20.0, 'status': 'Inactive', 'type': 'Percentage'}, // Example Inactive
    // Add more tax rates if needed
  ];
  // --- End Placeholder Data ---

  // Function to show the Add/Edit Dialog
  void _showAddEditTaxDialog(BuildContext context, {Map<String, dynamic>? taxData}) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: AddEditTaxForm(
            taxData: taxData,
            onSave: (newTaxData) {
              // TODO: Implement save logic (API call, DB update)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${taxData == null ? "Adding" : "Updating"} Tax Rate (Not Implemented)')),
              );
              Navigator.of(dialogContext).pop(); // Close dialog on save
            },
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final int totalCount = taxRatesData.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tax Rates'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search Tax Rates',
            onPressed: () {
              // TODO: Implement Search Functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search Action (Not Implemented)')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor,
        elevation: 0.5,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Tax Rates Row (Header)
          _buildListHeader(
            'Total Tax Rates',
            totalCount,
            context,
            onAddTap: () => _showAddEditTaxDialog(context), // Call dialog on Add tap
          ),

          // Tax Rate List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              itemCount: taxRatesData.length,
              itemBuilder: (ctx, index) {
                final tax = taxRatesData[index];
                return TaxListItem(
                  tax: tax,
                  onViewTap: () {
                    // TODO: Implement View Action (maybe show details if different from edit?)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('View ${tax['name']} (Not Implemented)')),
                    );
                  },
                  onEditTap: () => _showAddEditTaxDialog(context, taxData: tax), // Pass data for edit
                  onDeleteTap: () {
                    // TODO: Implement Delete Confirmation and Logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Delete ${tax['name']} (Not Implemented)')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // --- Removed FloatingActionButton and BottomNavigationBar ---
    );
  }

  // Builds the header section above the list (Total Count, Add, Filter)
  Widget _buildListHeader(String title, int count, BuildContext context, {required VoidCallback onAddTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0), // Adjust padding
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
          const SizedBox(width: 8),
          // Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kAccentGreen.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: kAccentGreen,
              ),
            ),
          ),
          const Spacer(), // Pushes buttons to the right end
          // Add Button (Moved to header)
          InkWell(
            onTap: onAddTap, // Use passed callback
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: kPrimaryPurple, // Solid color for Add button
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: kPrimaryPurple.withAlpha((0.2 * 255).toInt()), blurRadius: 4, offset: Offset(0, 2))
                  ]
              ),
              child: const Icon(Icons.add, color: kWhiteColor, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Filter Button
          InkWell(
            onTap: () {
              // TODO: Implement Filter/Sort Action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter/Sort Action (Not Implemented)')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimaryPurple.withAlpha((0.2 * 255).toInt()), // Lighter bg for Filter
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.filter_list_alt, color: kPrimaryPurple, size: 20),
            ),
          ),
        ],
      ),
    );
  }

} // End TaxRatesScreen


// --- Widget for individual Tax Rate List Item ---
class TaxListItem extends StatelessWidget {
  final Map<String, dynamic> tax;
  final VoidCallback onViewTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const TaxListItem({super.key,
    required this.tax,
    required this.onViewTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = tax['name'] ?? 'N/A';
    final double rate = (tax['rate'] as num? ?? 0.0).toDouble();
    final String status = tax['status'] ?? 'Inactive';
    final bool isActive = status == 'Active';


    return Card(
      elevation: 1.0,
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt()))
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tax Rate : $rate%', // Display rate with %
                    style: const TextStyle(fontSize: 13, color: kMutedTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action Icons & Status Badge
            Row(
              mainAxisSize: MainAxisSize.min, // Prevent row from taking extra space
              children: [
                // View Icon
                _buildActionButton(
                  icon: Icons.remove_red_eye_outlined,
                  tooltip: 'View Tax Rate',
                  onTap: onViewTap,
                ),
                const SizedBox(width: 4),
                // Edit Icon
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit Tax Rate',
                  onTap: onEditTap,
                ),
                const SizedBox(width: 4),
                // Delete Icon
                _buildActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete Tax Rate',
                  color: kErrorColor, // Use error color for delete
                  onTap: onDeleteTap,
                ),
                const SizedBox(width: 10),
                // Status Badge
                _buildStatusBadge(status, isActive),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = kIconColor, // Default icon color
  }) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      onPressed: onTap,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      splashRadius: 18, // Smaller splash radius
    );
  }

  // Helper for status badge
  Widget _buildStatusBadge(String status, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? kAccentGreen.withAlpha((0.2 * 255).toInt()) : kMutedTextColor.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: isActive ? kAccentGreen : kMutedTextColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? kAccentGreen : kMutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

}


// --- Stateful Widget for the Add/Edit Tax Form inside the Dialog ---
class AddEditTaxForm extends StatefulWidget {
  final Map<String, dynamic>? taxData; // Null if adding, populated if editing
  final Function(Map<String, dynamic>) onSave;

  const AddEditTaxForm({super.key, this.taxData, required this.onSave});

  @override
  State<AddEditTaxForm> createState() => _AddEditTaxFormState();
}

class _AddEditTaxFormState extends State<AddEditTaxForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _taxNameController;
  late TextEditingController _taxRateController;
  String? _selectedType;
  late bool _isActive;

  // TODO: Populate with actual tax types from your system
  final List<String> _taxTypes = ['Percentage', 'Fixed Amount'];

  bool get _isEditing => widget.taxData != null;

  @override
  void initState() {
    super.initState();
    final initialData = widget.taxData;
    _taxNameController = TextEditingController(text: initialData?['name'] ?? '');
    _taxRateController = TextEditingController(text: initialData?['rate']?.toString() ?? '');
    _selectedType = initialData?['type'];
    // Ensure initial type exists in the list, otherwise default to null or first item
    if (_selectedType != null && !_taxTypes.contains(_selectedType)) {
      _selectedType = null;
    }
    _isActive = initialData?['status'] == 'Active'; // Default to Active when adding
  }

  @override
  void dispose() {
    _taxNameController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha((0.2 * 255).toInt()),
                blurRadius: 10,
                offset: Offset(0, 4)
            )
          ]
      ),
      child: SingleChildScrollView( // Make form scrollable
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Make dialog height fit content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header with Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Tax' : 'Add Tax',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                  ),
                  Row( // Group Switch and Close button
                    children: [
                      // Active/Inactive Switch
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: kWhiteColor, // Thumb color when active
                        activeTrackColor: kPrimaryPurple, // Track color when active
                        inactiveThumbColor: kWhiteColor, // Thumb color when inactive
                        inactiveTrackColor: kDisabledSwitchTrack, // Track color when inactive
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap area slightly
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: kIconColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form Fields
              _buildLabeledTextField(
                label: 'Tax Name',
                controller: _taxNameController,
                hintText: 'Enter Tax Name',
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Tax Name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              _buildLabeledTextField(
                  label: 'Tax Rates',
                  controller: _taxRateController,
                  hintText: 'Enter Tax Rate',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true), // Allow decimal input
                  inputFormatters: [ // Optional: Allow only numbers and one decimal point
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Example: max 2 decimal places
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Tax Rate cannot be empty';
                    if (double.tryParse(value.trim()) == null) return 'Please enter a valid number';
                    return null;
                  }
              ),
              const SizedBox(height: 16),
              // Type Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Type',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextColor),
                      ),
                      Text(' *', style: TextStyle(color: kErrorColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    hint: const Text('Choose Type', style: TextStyle(color: kMutedTextColor, fontSize: 14)),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: kIconColor),
                    decoration: _inputDecoration(''), // Use helper for styling, empty hint
                    items: _taxTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (value) => value == null ? 'Please choose a type' : null,
                    style: const TextStyle(color: kTextColor, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align buttons to right
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kMutedTextColor,
                      side: const BorderSide(color: kBorderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryPurple,
                      foregroundColor: kWhiteColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper for Text Field with Label
  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextColor),
            ),
            const Text(' *', style: TextStyle(color: kErrorColor)), // Red asterisk
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          decoration: _inputDecoration(hintText),
          style: const TextStyle(color: kTextColor, fontSize: 14),
        ),
      ],
    );
  }

  // Helper for Input Decoration (shared by text fields and dropdown)
  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
      filled: true,
      fillColor: kWhiteColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: kBorderColor, width: 1.0),
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
    );
  }

} // End _AddEditTaxForm