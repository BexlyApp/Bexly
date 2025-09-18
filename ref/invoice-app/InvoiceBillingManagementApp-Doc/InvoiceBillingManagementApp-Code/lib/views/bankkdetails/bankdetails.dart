// lib/screens/bank_details_screen.dart
import 'package:flutter/material.dart';

// --- Placeholder Navigation Targets ---
// None needed directly, but interaction might trigger navigation elsewhere

// --- Define Colors (Consider moving to a central theme file) ---
const Color kPrimaryPurple = Color(0xFF6A00F4); // Used for buttons/icons
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5); // For list item bottom section bg
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;
const Color kAccentGreen = Color(0xFF4CAF50); // For the count badge
const Color kErrorColor = Colors.redAccent; // For delete icon maybe
// --- End Color Definitions ---

class BankDetailsScreen extends StatelessWidget {
  // Changed to StatelessWidget
  const BankDetailsScreen({super.key});

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic (e.g., from API, database)
  final List<Map<String, dynamic>> bankAccountsData = const [
    {
      'accountHolderName': 'Emily',
      'accountNumber': '54213236132', // Mask sensitive data in real apps
      'bankName': 'Federal Bank',
      'branch': 'Brooklyn',
      'ifscCode': '65485', // IFSC usually alphanumeric, use string
    },
    {
      'accountHolderName': 'David Lee',
      'accountNumber': '98765432100',
      'bankName': 'City Bank',
      'branch': 'Manhattan',
      'ifscCode': 'CITI12345',
    },
    {
      'accountHolderName': 'Sarah Chen',
      'accountNumber': '11223344556',
      'bankName': 'State Bank',
      'branch': 'Queens',
      'ifscCode': 'SBIN000987',
    },
    {
      'accountHolderName': 'Emily',
      'accountNumber': '54213236132', // Mask sensitive data in real apps
      'bankName': 'Federal Bank',
      'branch': 'Brooklyn',
      'ifscCode': '65485', // IFSC usually alphanumeric, use string
    },
    {
      'accountHolderName': 'David Lee',
      'accountNumber': '98765432100',
      'bankName': 'City Bank',
      'branch': 'Manhattan',
      'ifscCode': 'CITI12345',
    },
    {
      'accountHolderName': 'Sarah Chen',
      'accountNumber': '11223344556',
      'bankName': 'State Bank',
      'branch': 'Queens',
      'ifscCode': 'SBIN000987',
    },
    // Add more accounts if needed
  ];
  // --- End Placeholder Data ---

  // Function to show the Add/Edit Dialog
  void _showAddEditBankDialog(
    BuildContext context, {
    Map<String, dynamic>? bankData,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor:
              Colors.transparent, // Make dialog background transparent
          child: AddEditBankForm(
            bankData: bankData,
            onSave: (newBankData) {
              // TODO: Implement save logic (API call, DB update)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${bankData == null ? "Adding" : "Updating"} Bank Details (Not Implemented)',
                  ),
                ),
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
    final int totalCount = bankAccountsData.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bank Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search Bank Accounts',
            onPressed: () {
              // TODO: Implement Search Functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search Action (Not Implemented)'),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Bank Accounts Row (Header)
          _buildListHeader(
            'Total Bank Accounts',
            totalCount,
            context,
            onAddTap:
                () => _showAddEditBankDialog(context), // Call dialog on Add tap
          ),

          // Bank Account List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              itemCount: bankAccountsData.length,
              itemBuilder: (ctx, index) {
                final account = bankAccountsData[index];
                return BankListItem(
                  account: account,
                  onEditTap:
                      () => _showAddEditBankDialog(
                        context,
                        bankData: account,
                      ), // Pass data for edit
                  onDeleteTap: () {
                    // TODO: Implement Delete Confirmation and Logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Delete ${account['accountHolderName']} (Not Implemented)',
                        ),
                      ),
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
  Widget _buildListHeader(
    String title,
    int count,
    BuildContext context, {
    required VoidCallback onAddTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        12.0,
      ), // Adjust padding
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
                  BoxShadow(
                    color: kPrimaryPurple.withAlpha((0.2 * 255).toInt()),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
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
                const SnackBar(
                  content: Text('Filter/Sort Action (Not Implemented)'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimaryPurple.withAlpha(
                  (0.2 * 255).toInt(),
                ), // Lighter bg for Filter
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list_alt,
                color: kPrimaryPurple,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
} // End BankDetailsScreen

// --- Widget for individual Bank Account List Item ---
class BankListItem extends StatelessWidget {
  final Map<String, dynamic> account;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const BankListItem({
    super.key,
    required this.account,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final String accountHolderName = account['accountHolderName'] ?? 'N/A';
    final String accountNumber = account['accountNumber'] ?? 'N/A';
    // Consider masking account number: e.g., '**** **** ${accountNumber.substring(accountNumber.length - 4)}'
    final String bankName = account['bankName'] ?? '-';
    final String branch = account['branch'] ?? '-';
    final String ifscCode = account['ifscCode'] ?? '-';

    return Card(
      elevation: 1.0,
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
      ),
      child: Column(
        children: [
          // Top Section: Name, Account Number, Edit/Delete
          Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
              right: 8.0,
              top: 12.0,
              bottom: 8.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountHolderName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Account Number : $accountNumber',
                        style: const TextStyle(
                          fontSize: 13,
                          color: kMutedTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Edit Icon
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: kIconColor,
                  ),
                  tooltip: 'Edit Bank Details',
                  onPressed: onEditTap,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                // Delete Icon
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: kErrorColor,
                  ),
                  tooltip: 'Delete Bank Account',
                  onPressed: onDeleteTap,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Divider (Optional, can use background color instead)
          // Divider(height: 1, thickness: 0.5, color: kBorderColor.withOpacity(0.5)),

          // Bottom Section: Bank Name, Branch, IFSC (with background)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: kLightGray.withAlpha(
                (0.9 * 255).toInt(),
              ), // Use light gray background
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailColumn('Bank Name', bankName),
                _buildDetailColumn('Branch', branch),
                _buildDetailColumn(
                  'IFSC Code',
                  ifscCode,
                  alignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for detail columns in list item bottom section
  Widget _buildDetailColumn(
    String label,
    String value, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: kMutedTextColor),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Stateful Widget for the Add/Edit Bank Form inside the Dialog ---
class AddEditBankForm extends StatefulWidget {
  final Map<String, dynamic>? bankData; // Null if adding, populated if editing
  final Function(Map<String, dynamic>) onSave;

  const AddEditBankForm({super.key, this.bankData, required this.onSave});

  @override
  State<AddEditBankForm> createState() => _AddEditBankFormState();
}

class _AddEditBankFormState extends State<AddEditBankForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountHolderNameController;
  late TextEditingController _branchNameController;
  late TextEditingController _ifscCodeController;

  bool get _isEditing => widget.bankData != null;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(
      text: widget.bankData?['bankName'] ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.bankData?['accountNumber'] ?? '',
    );
    _accountHolderNameController = TextEditingController(
      text: widget.bankData?['accountHolderName'] ?? '',
    );
    _branchNameController = TextEditingController(
      text: widget.bankData?['branch'] ?? '',
    );
    _ifscCodeController = TextEditingController(
      text: widget.bankData?['ifscCode'] ?? '',
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _branchNameController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13.0),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).toInt()),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        // Make form scrollable if content overflows
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
                    _isEditing ? 'Edit Bank Details' : 'Add Bank Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
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
              const SizedBox(height: 20),

              // Form Fields
              _buildLabeledTextField(
                label: 'Bank Name',
                controller: _bankNameController,
                hintText: 'Enter Bank Name',
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Bank Name cannot be empty'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildLabeledTextField(
                label: 'Account Number',
                controller: _accountNumberController,
                hintText: 'Enter Account Number',
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Account Number cannot be empty'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildLabeledTextField(
                label: 'Account Holder Name',
                controller: _accountHolderNameController,
                hintText: 'Enter Account Holder Name',
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Holder Name cannot be empty'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildLabeledTextField(
                label: 'Branch Name',
                controller: _branchNameController,
                hintText: 'Enter Branch Name',
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Branch Name cannot be empty'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildLabeledTextField(
                label: 'IFSC Code',
                controller: _ifscCodeController,
                hintText: 'Enter IFSC Code',
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'IFSC Code cannot be empty'
                            : null,
                // Add more specific IFSC validation if needed
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Align buttons to right
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kMutedTextColor,
                      side: const BorderSide(color: kBorderColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryPurple,
                      foregroundColor: kWhiteColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
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
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kTextColor,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: kErrorColor),
            ), // Red asterisk
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: kMutedTextColor, fontSize: 14),
            filled: true,
            fillColor: kWhiteColor, // Or kLightGray.withOpacity(0.5)
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 14.0,
            ),
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
          ),
          style: const TextStyle(color: kTextColor, fontSize: 14),
        ),
      ],
    );
  }
} // End _AddEditBankForm
