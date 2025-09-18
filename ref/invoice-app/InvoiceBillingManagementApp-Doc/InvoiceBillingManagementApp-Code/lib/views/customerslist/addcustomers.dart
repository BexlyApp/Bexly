import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // Uncomment when needed

// --- Reusing Colors (Define or Import) ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kErrorColor = Colors.red;

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  int _currentIndex = 0; // 0: Basic, 1: Address, 2: Bank
  late PageController _pageController;

  // Controllers for Basic Details Tab
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();
  File? _imageFile;

  // Add controllers for Address and Bank Details tabs as needed

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    // Dispose other controllers
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // --- Placeholder Image Logic ---
  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picking not implemented yet.')),
    );
  }

  void _deleteImage() {
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Customer'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kTextColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCustomTabBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildBasicDetailsTab(),
                _buildAddressTab(), // Placeholder tab content
                _buildBankDetailsTab(), // Placeholder tab content
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Custom Tab Bar --- (Similar to Product Catalog)
  Widget _buildCustomTabBar() {
    // Using slightly different styling to match Add Customer screenshot
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      child: Row(
        children: [
          _buildTabItem(index: 0, label: 'Basic Details'),
          const SizedBox(width: 10),
          _buildTabItem(index: 1, label: 'Address'),
          const SizedBox(width: 10),
          _buildTabItem(index: 2, label: 'Bank Details'),
        ],
      ),
    );
  }

  Widget _buildTabItem({required int index, required String label}) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0), // Less rounded
            border:
                isSelected
                    ? null
                    : Border.all(color: kBorderColor), // Border for inactive
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : kMutedTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13, // Slightly smaller font
            ),
          ),
        ),
      ),
    );
  }

  // --- Tab Content Widgets ---
  Widget _buildBasicDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagePickerSection(), // Reuse helper
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Name',
            controller: _nameController,
            hint: 'Enter Name',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email Address',
            controller: _emailController,
            hint: 'Enter Email Address',
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone',
            controller: _phoneController,
            hint: 'Enter Phone',
            isRequired: true,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Website',
            controller: _websiteController,
            hint: 'Add Website',
            keyboardType: TextInputType.url,
          ), // Optional
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Notes',
            controller: _notesController,
            hint: 'Notes',
            isRequired: true,
            maxLines: 4,
          ), // Required as per screenshot
          const SizedBox(height: 30),
          SizedBox(
            // Make button full width
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Validate Basic Details and move to next tab
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
              // Change button text based on tab? Or keep it 'Next' / 'Save'
              child: Text(
                _currentIndex < 2 ? 'Next' : 'Save Customer',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    // Placeholder content - Build similar to Basic Details
    return const Center(child: Text('Address Details Form Goes Here'));
  }

  Widget _buildBankDetailsTab() {
    // Placeholder content - Build similar to Basic Details
    return const Center(child: Text('Bank Details Form Goes Here'));
  }

  // --- Helper Widgets (Reused from Add Product/Category) ---
  Widget _buildImagePickerSection() {
    // Copied & adapted slightly - make common if needed
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Image*',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kLightGray,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorderColor),
                image:
                    _imageFile != null
                        ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  _imageFile == null
                      ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: kMutedTextColor,
                          size: 40,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Size Should be below 4 MB.',
                    style: TextStyle(fontSize: 12, color: kMutedTextColor),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Upload Image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  if (_imageFile != null)
                    TextButton(
                      onPressed: _deleteImage,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: kErrorColor, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    // Copied - make common if needed
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
    // Copied - make common if needed
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
            ), // Adjust padding for multiline
          ),
          validator:
              isRequired
                  ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    // Add more specific validation (e.g., email format) if needed
                    return null;
                  }
                  : null,
        ),
      ],
    );
  }
} // End of _AddCustomerScreenState
