// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:invoiceandbilling/views/messages/chat_screen.dart';
import 'package:invoiceandbilling/views/reviews/reviews.dart';

import '../../Widgets/customapp_bar.dart';
import '../bankkdetails/bankdetails.dart';
import '../billingchatassistant/chatasistant.dart';
import '../fraudmistakedetection/frauddetection.dart';
import '../taxrates/taxrates.dart';

// --- Placeholder Navigation Targets ---
// Assume these screens exist for navigation placeholders
// import 'profile_screen.dart'; // For Admin Smith tap
// import 'general_settings_screen.dart';
// import 'invoice_settings_screen.dart';
// import 'invoice_templates_screen.dart';
// import 'bank_details_screen.dart'; // From previous example
// import 'tax_rates_screen.dart'; // From previous example
// import 'login_screen.dart'; // For Logout

// --- Define Colors (Consider moving to a central theme file) ---
const Color kPrimaryPurple = Color(
  0xFF6A00F4,
); // AppBar background, potential accent
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5); // Icon background color
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54; // Default icon color
const Color kDisabledSwitchTrack = Colors.black26;
// --- End Color Definitions ---

class SettingsScreen extends StatefulWidget {
  // Need state for Dark Mode switch
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // TODO: Get actual dark mode status from theme provider or preferences
  // Placeholder user info
  final String _userName = "Admin Smith";
  final String _userImageUrl =
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1887&q=80"; // Example image URL

  // Function to handle navigation (placeholder)
  void _navigateTo(
    BuildContext context,
    String screenName,
    Widget? screenWidget,
  ) {
    if (screenWidget != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screenWidget),
      );

    } else {

    }
  }

  // Function to handle logout (placeholder)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use primary purple for AppBar background as shown

      body: SafeArea(
        child: ListView(
          // Use ListView for scrollability if settings list grows
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
          ), // Padding for the list
          children: [
            SizedBox(height: 0,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 0),
              child: const CustomAppBar(text: 'Settings', text1: ''),
            ),
            SizedBox(height: 10,),

            // Profile Section
            _buildProfileSection(context),
            const SizedBox(height: 10), // Space after profile
            // Settings Items
        
            _buildSettingsListItem(
              context: context,
              icon: Icons.account_balance_outlined, // Bank Details
              title: 'Bank Details',
              onTap: () => _navigateTo(
                context,
                '',
                const BankDetailsScreen(),
              ),
            ),
            _buildSettingsListItem(
              context: context,
              icon: Icons.receipt_long_outlined, // Tax Rates
              title: 'Tax Rates',
              onTap: () => _navigateTo(context, '', const TaxRatesScreen()),
            ),
            _buildSettingsListItem(
              context: context,
              icon: Icons.smart_toy_outlined, // AI Assistant
              title: 'AiAssistant',
              onTap: () => _navigateTo(context, '', InvoiceChatScreen()),
            ),
            _buildSettingsListItem(
              context: context,
              icon: Icons.shield_outlined, // Fraud Detection Assistant
              title: 'FraudDetectionAssistant',
              onTap: () => _navigateTo(context, '', FraudDetectionAssistant()),
            ),
            _buildSettingsListItem(
              context: context,
              icon: Icons.rate_review_outlined, // Reviews
              title: 'Reviews',
              onTap: () => _navigateTo(context, '', Reviews()),
            ),
            _buildSettingsListItem(
              context: context,
              icon: Icons.chat_bubble_outline, // Messages
              title: 'Messages',
              onTap: () => _navigateTo(context, '', ChatScreen()),
            ),
        
          ],
        ),
      ),
      // NO BottomNavigationBar or FloatingActionButton
    );
  }

  // --- Widget Builders ---

  Widget _buildProfileSection(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: CircleAvatar(
        radius: 28, // Adjust size as needed
        backgroundColor: kLightGray, // Placeholder background
        backgroundImage: NetworkImage(_userImageUrl), // Load image from URL
        onBackgroundImageError:
            (
              _,
              __,
            ) {}, // Handle image loading errors silently or show placeholder
        child:
            _userImageUrl
                    .isEmpty // Show initial if no image URL
                ? const Icon(Icons.person, size: 30, color: kMutedTextColor)
                : null,
      ),
      title: Text(
        _userName,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: kTextColor,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: kIconColor,
      ),
      onTap: () {
        // TODO: Navigate to Profile Screen
        _navigateTo(context, 'Profile', null /* ProfileScreen() */);
      },
    );
  }

  Widget _buildSettingsListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing, // Optional trailing widget (like Switch or arrow)
    VoidCallback? onTap,
    bool isLogout = false, // Flag for special styling
  }) {
    final Color titleColor =
        isLogout ? Color(0xFFF5F5F5) : kTextColor; // Example: Red for logout

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: kLightGray, // Circular background for icon
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: kIconColor), // Slightly smaller icon
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      // Use provided trailing widget or default arrow if onTap is present
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios, size: 16, color: kIconColor)
              : null),
      onTap: onTap,
    );
  }
} // End _SettingsScreenState
