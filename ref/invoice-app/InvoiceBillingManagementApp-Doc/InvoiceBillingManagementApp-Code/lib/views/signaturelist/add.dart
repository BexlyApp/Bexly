// lib/screens/add_signature_screen.dart
import 'package:flutter/material.dart';
import 'dart:io'; // Required for File operations if using image_picker
// import 'package:image_picker/image_picker.dart'; // Uncomment if image picking is implemented
// import 'package:dotted_border/dotted_border.dart'; // Optional for exact border style

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kErrorColor = Colors.red;
const Color kWhiteColor = Colors.white;
const Color kDeleteColor = Colors.red;
// --- End Color Definitions ---

class AddSignatureScreen extends StatefulWidget {
  final Map<String, dynamic>? signatureData; // Optional data for editing

  const AddSignatureScreen({super.key, this.signatureData});

  @override
  State<AddSignatureScreen> createState() => _AddSignatureScreenState();
}

class _AddSignatureScreenState extends State<AddSignatureScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & State Variables
  final _signatureNameController = TextEditingController();
  bool _isDefault = false;
  File? _selectedImageFile; // Holds the selected image file
  String? _existingImageUrl; // Holds URL if editing

  bool get _isEditing => widget.signatureData != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _signatureNameController.text = widget.signatureData?['name'] ?? '';
      _isDefault = widget.signatureData?['isDefault'] ?? false;
      _existingImageUrl = widget.signatureData?['imageUrl'];
      // Note: We don't load the image file automatically when editing,
      // only the URL. The user would need to upload a *new* image to replace it.
    }
  }

  @override
  void dispose() {
    _signatureNameController.dispose();
    super.dispose();
  }

  // --- TODO: Implement Image Picking Logic ---
  Future<void> _pickImage() async {


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image Picking (Not Implemented)')),
    );
  }

  void _deleteImage() {
    setState(() {
      _selectedImageFile = null;
      _existingImageUrl = null; // Also clear existing URL on delete
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
        title: Text(_isEditing ? 'Edit Signature' : 'Add Signature'),
        centerTitle: true,
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
              _buildTextField(
                label: 'Signature Name',
                controller: _signatureNameController,
                hint: 'Enter Signature Name',
                isRequired: true,
              ),
              const SizedBox(height: 20),
              _buildImageUploadSection(),
              const SizedBox(height: 16),
              _buildDefaultCheckbox(),
              const SizedBox(height: 40), // Spacer before buttons
              _buildActionButtons(),
              const SizedBox(height: 20), // Padding at the bottom
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildImageUploadSection() {
    bool hasImage =
        _selectedImageFile != null ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Signatures', isRequired: true), // Use helper
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: kWhiteColor, // White background inside card-like area
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Image Placeholder or Display
              Container(
                width: 120, // Fixed width for placeholder area
                height:
                    60, // Fixed height based on 100x100 aspect ratio (adjust if needed)
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
                  borderRadius: BorderRadius.circular(4),
                ),
                child:
                    hasImage
                        ? (_selectedImageFile != null
                            ? Image.file(
                              _selectedImageFile!,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (ctx, err, st) => const Icon(
                                    Icons.error_outline,
                                    color: kErrorColor,
                                  ),
                            )
                            : Image.network(
                              // Display existing image URL
                              _existingImageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (ctx, err, st) => const Icon(
                                    Icons.error_outline,
                                    color: kErrorColor,
                                  ),
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kPrimaryPurple,
                                  ),
                                );
                              },
                            ))
                        : const Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: kMutedTextColor,
                        ),
              ),

              const Text(
                'Size Should be below 100*100px',
                style: TextStyle(fontSize: 12, color: kMutedTextColor),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.cloud_upload_outlined,
                      size: 18,
                      color: hasImage ? kMutedTextColor : kPrimaryPurple,
                    ),
                    label: Text(hasImage ? 'Change Image' : 'Upload Image'),
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      foregroundColor:
                          hasImage ? kMutedTextColor : kPrimaryPurple,
                      backgroundColor: kWhiteColor,
                      elevation: 0,
                      side: BorderSide(
                        color: hasImage ? kMutedTextColor : kPrimaryPurple,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  if (hasImage) // Show delete only if there's an image
                    const SizedBox(width: 12),
                  if (hasImage)
                    TextButton.icon(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: kDeleteColor,
                      ),
                      label: const Text('Delete'),
                      onPressed: _deleteImage,
                      style: TextButton.styleFrom(
                        foregroundColor: kDeleteColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24, // Constrain checkbox size
          height: 24,
          child: Checkbox(
            value: _isDefault,
            onChanged: (bool? value) {
              setState(() {
                _isDefault = value ?? false;
              });
            },
            activeColor: kPrimaryPurple,
            materialTapTargetSize:
                MaterialTapTargetSize.shrinkWrap, // Reduce tap area
            visualDensity: VisualDensity.compact, // Make it smaller
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          // Make text tappable too
          onTap: () {
            setState(() {
              _isDefault = !_isDefault;
            });
          },
          child: const Text(
            'Mark as default',
            style: TextStyle(color: kTextColor, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: (){
              Navigator.pop(context);

            },
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryPurple,
              side: const BorderSide(color: kPrimaryPurple),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: (){
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryPurple,
              foregroundColor: kWhiteColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  // --- Reusable Form Field Helpers (Copied/Adapted from Example) ---
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
    String? Function(String?)? validator,
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
            filled: true, // Add fill color
            fillColor: kWhiteColor, // Use white or very light gray
          ),
          validator:
              validator ?? // Use provided validator or default required check
              (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return 'This field is required';
                }
                return null;
              },
        ),
      ],
    );
  }
} // End _AddSignatureScreenState
