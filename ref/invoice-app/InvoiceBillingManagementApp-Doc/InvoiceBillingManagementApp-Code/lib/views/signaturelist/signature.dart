// lib/screens/signatures_list_screen.dart
import 'package:flutter/material.dart';

import 'add.dart';

// import 'signature_details_screen.dart'; // Placeholder for details screen

// --- Define Colors Directly In This File ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kInactiveColor = Colors.red; // For inactive status
const Color kIconColor = Colors.black54;
const Color kWhiteColor = Colors.white;
const Color kStarColor = Color(0xFFFFC107); // Example star color
// --- End Color Definitions ---

class SignaturesListScreen extends StatelessWidget {
  const SignaturesListScreen({super.key});

  // --- Placeholder Data ---
  // TODO: Replace with actual data fetching logic
  final List<Map<String, dynamic>> allSignaturesData = const [
    {
      'id': 'sig_001',
      'name': 'Allen',
      'imageUrl': 'https://via.placeholder.com/100x50.png?text=Allen+Sig', // Placeholder
      'isDefault': true,
      'isActive': true,
    },
    {
      'id': 'sig_002',
      'name': 'Julie',
      'imageUrl': 'https://via.placeholder.com/100x50.png?text=Julie+Sig', // Placeholder
      'isDefault': false,
      'isActive': false,
    },
    {
      'id': 'sig_003',
      'name': 'Leslie',
      'imageUrl': 'https://via.placeholder.com/100x50.png?text=Leslie+Sig', // Placeholder
      'isDefault': false,
      'isActive': true,
    },
    // Add more signatures as needed
  ];
  // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    // In a real app, filter/fetch data here
    final List<Map<String, dynamic>> displayedList = allSignaturesData;
    final int totalSignatures = displayedList.length; // Use the actual count

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Signatures'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
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
        children: [
          // Use the generic header builder
          _buildListHeader('Total Signatures', totalSignatures, context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0, // Add some vertical padding
              ),
              itemCount: displayedList.length,
              itemBuilder: (context, index) => SignatureListItem(
                signature: displayedList[index],
              ),
            ),
          ),
        ],
      ),
      // Using a standard FAB like the example, placed centrally
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddSignatureScreen(),
          ),
        ),
        backgroundColor: kPrimaryPurple,
        child: const Icon(Icons.add, color: kWhiteColor),
      ),
      // If you prefer the exact bottom nav bar look from the screenshot:
      // bottomNavigationBar: BottomNavigationBar( ... implementation ... ),
      // And remove the floatingActionButton/Location above.
      // The central button in the BottomNav would perform the same navigation.
    );
  }

  // --- Reusing the Header Builder ---
  Widget _buildListHeader(String title, int count, BuildContext context) {
    // Matching the style from the screenshot more closely
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
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
        ],
      ),
    );
  }
}

// --- Separate Item Widget for Signature ---
class SignatureListItem extends StatelessWidget {
  final Map<String, dynamic> signature;

  const SignatureListItem({super.key, required this.signature});

  @override
  Widget build(BuildContext context) {
    final bool isDefault = signature['isDefault'] ?? false;
    final bool isActive = signature['isActive'] ?? false;
    final Color statusColor = isActive ? kAccentGreen : kInactiveColor;
    final String statusText = isActive ? 'Active' : 'Inactive';

    return Card(
      elevation: 0.5, // Subtle shadow
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt())),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Signature Details Screen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => SignatureDetailsScreen(signatureId: signature['id']),
          //   ),
          // );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details View (Not Implemented)')),
          );
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align content left
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Signature Name
                  Expanded(
                    child: Text(
                      signature['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action Icons
                  _buildActionButton(
                    icon: isDefault ? Icons.star : Icons.star_border,
                    color: isDefault ? kStarColor : kIconColor,
                    onTap: () {
                      // TODO: Implement Set Default Action
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Set Default for ${signature['name']} (Not Implemented)')),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.edit_outlined, // Use outlined edit icon
                    color: kIconColor,
                    onTap: () {
                      // TODO: Navigate to Edit Signature Screen (Maybe reuse Add screen?)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Pass signature data to prefill the form
                          builder: (context) => AddSignatureScreen(signatureData: signature),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.delete_outline, // Use outlined delete icon
                    color: kIconColor, // Could use kErrorColor potentially
                    onTap: () {
                      // TODO: Implement Delete Action (show confirmation dialog)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Delete ${signature['name']} (Not Implemented)')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Signature Image
              Center( // Center the image if it doesn't fill width
                child: Image.network(
                  signature['imageUrl'] ?? '',
                  height: 50, // Adjust height as needed
                  fit: BoxFit.contain, // Contain ensures the whole image is visible
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 50,
                    width: 100, // Match placeholder size roughly
                    color: kLightGray,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: kMutedTextColor,
                        size: 24,
                      ),
                    ),
                  ),
                  loadingBuilder:(context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 50,
                      width: 100,
                      color: kLightGray,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: kPrimaryPurple,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Status Tag - Align left
              Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusTag(statusText, statusColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper for action icons ---
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell( // Use InkWell for larger tap area
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(4.0), // Padding around icon
        child: Icon(
          icon,
          size: 20, // Icon size from screenshot
          color: color,
        ),
      ),
    );
  }

  // --- Reusing the status tag builder ---
  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).toInt()), // Lighter background
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color, // Text color matches tag color
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}