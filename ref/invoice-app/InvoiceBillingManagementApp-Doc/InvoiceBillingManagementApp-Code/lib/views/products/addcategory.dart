import 'dart:io'; // Needed for File type
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // Uncomment when implementing image picking

// --- Reusing Colors from previous example ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kErrorColor = Colors.red; // For required fields

// Enum for Item Type Radio Buttons
enum ItemType { products, services }

class AddNewProductScreen extends StatefulWidget {
  const AddNewProductScreen({super.key});

  @override
  State<AddNewProductScreen> createState() => _AddNewProductScreenState();
}

class _AddNewProductScreenState extends State<AddNewProductScreen> {
  final _formKey = GlobalKey<FormState>(); // For potential validation

  // Controllers for TextFields
  final _productNameController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _barcodeController = TextEditingController();

  // State variables
  ItemType _selectedItemType = ItemType.products;
  String? _selectedCategory;
  String? _selectedUnit;
  String? _selectedDiscountType;
  File? _imageFile; // To hold the selected image file

  // --- Dummy Data for Dropdowns (Replace with actual data) ---
  final List<String> _categories = ['Electronics', 'Clothing', 'Shoes', 'Books', 'Home Goods'];
  final List<String> _units = ['Piece (Pc)', 'Kilogram (kg)', 'Liter (L)', 'Pack (pk)'];
  final List<String> _discountTypes = ['Percentage (%)', 'Fixed Amount (\$)'];
  // --- ---

  @override
  void dispose() {
    // Dispose controllers
    _productNameController.dispose();
    _productCodeController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _discountValueController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic (Placeholder) ---
  Future<void> _pickImage() async {
    // Uncomment and implement using image_picker
    // final ImagePicker picker = ImagePicker();
    // final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    // if (pickedFile != null) {
    //   setState(() {
    //     _imageFile = File(pickedFile.path);
    //   });
    // }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picking not implemented yet.')),
    );
  }

  void _deleteImage() {
    setState(() {
      _imageFile = null;
    });
  }

  void _generateCode() {
    // Implement your SKU generation logic here
    _productCodeController.text = "SKU${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generated Dummy SKU')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add New Product'),
        centerTitle: true,
        backgroundColor: Colors.white,
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
              _buildImagePickerSection(),
              const SizedBox(height: 20),

              _buildSectionTitle('Item Type'),
              _buildRadioGroup(),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Product Name',
                controller: _productNameController,
                hint: 'Enter Product Name',
                isRequired: true,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                  label: 'Product Code(SKU)',
                  controller: _productCodeController,
                  hint: 'Enter Product Code',
                  isRequired: true,
                  suffixWidget: TextButton(
                    onPressed: _generateCode,
                    child: const Text('Generate Code', style: TextStyle(color: kPrimaryPurple)),
                  )
              ),
              const SizedBox(height: 20),

              _buildDropdownField(
                label: 'Product Category',
                value: _selectedCategory,
                items: _categories,
                hint: 'Product Category',
                isRequired: true,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Selling Price',
                      controller: _sellingPriceController,
                      hint: 'Add Selling Price',
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Purchase Price',
                      controller: _purchasePriceController,
                      hint: 'Enter Purchase Price',
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Units',
                      value: _selectedUnit,
                      items: _units,
                      hint: 'Select',
                      isRequired: true,
                      onChanged: (value) {
                        setState(() => _selectedUnit = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Discount Type',
                      value: _selectedDiscountType,
                      items: _discountTypes,
                      hint: 'Select',
                      isRequired: true,
                      onChanged: (value) {
                        setState(() => _selectedDiscountType = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Discount Value',
                controller: _discountValueController,
                hint: 'Enter Discount Value',
                keyboardType: TextInputType.number,
                isRequired: true, // Assuming discount is required if type is selected
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Barcode',
                controller: _barcodeController,
                hint: 'Enter Barcode',
                isRequired: true, // Mark as required if needed
              ),
              const SizedBox(height: 30),

              // Add Save Button Here if needed, or handle via AppBar action
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Add save logic here
                    // if (_formKey.currentState!.validate()) { ... }
                   Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      )
                  ),
                  child: const Text('Save Product', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for Form Fields ---

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextColor),
          ),
          if (isRequired)
            const Text('*', style: TextStyle(color: kErrorColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Image*', // Assuming image is required
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextColor),
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
                image: _imageFile != null
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : null,
              ),
              child: _imageFile == null
                  ? const Center(child: Icon(Icons.image_outlined, color: kMutedTextColor, size: 40))
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Upload Image', style: TextStyle(color: Colors.white)),
                  ),
                  if (_imageFile != null)
                    TextButton(
                      onPressed: _deleteImage,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      child: const Text('Delete', style: TextStyle(color: kErrorColor, fontSize: 13)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioGroup() {
    return Row(
      children: <Widget>[
        _buildRadioOption(ItemType.products, 'Products'),
        const SizedBox(width: 10),
        _buildRadioOption(ItemType.services, 'Services'),
      ],
    );
  }

  Widget _buildRadioOption(ItemType value, String label) {
    bool isSelected = _selectedItemType == value;
    return Flexible( // Allows options to share space
      child: InkWell(
        onTap: () => setState(() => _selectedItemType = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? kPrimaryPurple : kBorderColor, width: isSelected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? kPrimaryPurple.withAlpha((0.2 * 255).toInt()) : Colors.transparent,
          ),
          child: Row(
            children: [
              Radio<ItemType>(
                value: value,
                groupValue: _selectedItemType,
                onChanged: (ItemType? newValue) {
                  setState(() {
                    _selectedItemType = newValue!;
                  });
                },
                activeColor: kPrimaryPurple,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              //const SizedBox(width: 4), // Small space if needed
              Text(label, style: TextStyle(color: isSelected? kPrimaryPurple : kTextColor, fontSize: 14, fontWeight: isSelected ? FontWeight.bold: FontWeight.normal )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixWidget,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            suffixIcon: suffixWidget != null ? Padding(padding: const EdgeInsets.only(right: 8.0), child: suffixWidget) : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0), // Allow suffix to size naturally
          ),
          validator: isRequired ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          } : null,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, isRequired: isRequired),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: isRequired ? (value) {
            if (value == null) {
              return 'Please select an option';
            }
            return null;
          } : null,
          isExpanded: true, // Make dropdown take available width
          icon: const Icon(Icons.keyboard_arrow_down, color: kMutedTextColor),
        ),
      ],
    );
  }
}