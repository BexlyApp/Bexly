import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../core/apiconfig.dart'; // Keep your existing import

// Define App Colors (Example - Adjust as needed)
const Color chatPrimaryColor = Color(0xFF3F51B5); // Indigo
const Color chatAccentColor = Color(0xFF5C6BC0); // Lighter Indigo
const Color chatUserBubbleColor = Color(0xFF5C6BC0); // Lighter Indigo for User
const Color chatBotBubbleColor = Color(0xFF455A64); // Blue Grey Dark
const Color chatInputBgColor = Color(0xFF263238); // Blue Grey Darker
const Color chatInputFillColor = Color(0xFF37474F); // Blue Grey Medium Dark
const Color chatTextColorLight = Colors.white;
const Color chatTextColorHint = Colors.white70;
const Color chatErrorColor = Colors.redAccent; // Use accent for errors

class InvoiceChatScreen extends StatefulWidget {
  const InvoiceChatScreen({super.key});

  @override
  State<InvoiceChatScreen> createState() => _InvoiceChatScreenState();
}

class _InvoiceChatScreenState extends State<InvoiceChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Add scroll controller
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  String _errorMessage = '';

  // --- Sample Data (Unchanged) ---
  List<Map<String, dynamic>> invoices = [
    {
      'invoiceId': 'INV-001',
      'client': 'Alice Johnson',
      'amount': 250.0,
      'status': 'Paid',
      'dueDate': '2024-12-10',
      'issuedDate': '2024-11-20',
      'description': 'UI Design Services'
    },
    {
      'invoiceId': 'INV-002',
      'client': 'Bob Smith',
      'amount': 500.0,
      'status': 'Pending',
      'dueDate': '2024-12-20',
      'issuedDate': '2024-11-25',
      'description': 'Mobile App Development'
    },
    {
      'invoiceId': 'INV-003',
      'client': 'Charlie Lee',
      'amount': 300.0,
      'status': 'Overdue',
      'dueDate': '2024-11-30',
      'issuedDate': '2024-11-01',
      'description': 'Web Hosting & Maintenance'
    },
  ];
  // --- End Sample Data ---

  // --- API & Message Handling Logic (Minor Updates for Scrolling) ---
  Future<void> sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty || isLoading) return; // Prevent empty/concurrent sends

    setState(() {
      messages.add({"role": "user", "text": userMessage});
      isLoading = true;
      _errorMessage = '';
    });
    _scrollToBottom(); // Scroll after adding user message

    _controller.clear();

    try {
      // Local handling for specific queries
      if (userMessage.toLowerCase().contains('pending') ||
          userMessage.toLowerCase().contains('overdue') ||
          userMessage.toLowerCase().contains('unpaid') ||
          userMessage.toLowerCase().contains('outstanding')) { // Added 'outstanding'
        handleInvoiceQuery();
      } else {
        await fetchGeminiResponse(userMessage);
      }
    } catch (e) {
      setState(() {
        // Hide sensitive info like API key from user-facing error
        String displayError = e.toString();
        if (displayError.contains(geminiApiKey)) {
          displayError = 'API configuration error.';
        }
        _errorMessage = 'Error: $displayError';
        messages.add({
          "role": "bot",
          "text": "Sorry, I encountered an error. Please try again."
        });
      });
    } finally {
      setState(() {
        isLoading = false;
      });
      _scrollToBottom(); // Scroll after bot response or error
    }
  }

  void handleInvoiceQuery() {
    // Call this within setState to trigger UI update
    setState(() {
      List<Map<String, dynamic>> unpaid = invoices.where((inv) => inv['status'] != 'Paid').toList();
      double totalDue = unpaid.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));

      String response;
      if (unpaid.isEmpty) {
        response = "✨ All invoices appear to be paid. Great work!";
      } else {
        response = "Here are the unpaid invoices:\n\n${unpaid.map((inv) {
              return "• ${inv['client']} - \$${inv['amount']} (${inv['status']}) "
                  "Due: ${inv['dueDate']}\n  Desc: ${inv['description']}"; // Improved formatting
            }).join('\n\n')}\n\nTotal outstanding: \$${totalDue.toStringAsFixed(2)}";
      }
      messages.add({"role": "bot", "text": response});
    });
  }

  Future<void> fetchGeminiResponse(String prompt) async {
    try {
      final response = await http.post(
        // Ensure geminiApiKey is correctly sourced from your apiconfig.dart
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "You are a smart assistant specialized in invoice and billing management. "
                      "Use the provided invoice data to answer user questions concisely about status, due dates, clients, amounts, or descriptions. "
                      "If asked generally about unpaid invoices, provide a summary. "
                      "Invoice Data Context: ${jsonEncode(invoices)}. " // Pass context
                      "User query: $prompt"
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.3,
            "topP": 0.8,
            "maxOutputTokens": 1000, // Adjusted token limit
          },
          // Add safety settings if desired
          // "safetySettings": [ ... ]
        }),
      ).timeout(const Duration(seconds: 40)); // Adjusted timeout

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text = jsonResponse["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

        if (text != null && text is String && text.trim().isNotEmpty) {
          setState(() {
            messages.add({"role": "bot", "text": text.trim()});
          });
        } else {
          final blockReason = jsonResponse["promptFeedback"]?["blockReason"];
          if (blockReason != null) {
            throw Exception('API request blocked: $blockReason');
          } else {
            // Handle cases where the response is valid but empty
            setState(() {
              messages.add({"role": "bot", "text": "I couldn't find specific information for that request based on the available data."});
            });
          }
        }
      } else {
        // Provide more specific error feedback if possible
        String errorBody = response.body;
        try {
          final decodedBody = jsonDecode(errorBody);
          errorBody = decodedBody['error']?['message'] ?? errorBody;
        } catch (_) { /* Ignore if body is not JSON */ }
        throw Exception('API Error: ${response.statusCode} - ${errorBody.length > 100 ? '${errorBody.substring(0,100)}...' : errorBody}'); // Limit error message length
      }
    } catch (e) {
      // Rethrow the exception to be caught by the sendMessage method's catch block
      rethrow;
    }
  }

  void _scrollToBottom() {
    // Use addPostFrameCallback to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  // --- Widget Building Logic (Updated Colors) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Invoice Assistant",
            style: GoogleFonts.poppins( // Keep Google Fonts if desired
                fontSize: 20, fontWeight: FontWeight.w600, color: chatTextColorLight)),
        backgroundColor: chatPrimaryColor, // Use Indigo
        centerTitle: true,
        elevation: 2.0, // Add subtle elevation
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: chatTextColorLight), // Outlined icon
            onPressed: handleInvoiceQuery, // Directly call the handler
            tooltip: "Check Unpaid Invoices",
          ),
        ],
      ),
      backgroundColor: chatInputBgColor, // Dark background for the body
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Assign controller
              padding: const EdgeInsets.all(12), // Adjusted padding
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ChatBubble(
                    text: msg["text"],
                    isUser: msg["role"] == "user"
                );
              },
            ),
          ),
          // Error Message Area
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_errorMessage, style: GoogleFonts.poppins(color: chatErrorColor, fontSize: 12)),
            ),
          // Loading Indicator Area
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              // Use LinearProgressIndicator for cleaner look at bottom
              child: LinearProgressIndicator(
                color: chatAccentColor,
                backgroundColor: chatBotBubbleColor,
                minHeight: 3,
              ),
            ),
          // Input Field
          MessageInputField(
              controller: _controller,
              sendMessage: sendMessage,
              isLoading: isLoading // Pass loading state
          ),
        ],
      ),
    );
  }
}

// --- ChatBubble Widget (Updated Colors) ---
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const ChatBubble({required this.text, required this.isUser, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // Adjusted padding
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4), // Adjusted margin
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78), // Max width
        decoration: BoxDecoration(
          color: isUser ? chatUserBubbleColor : chatBotBubbleColor, // Use new colors
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 18 : 4), // More distinct rounding
            topRight: Radius.circular(isUser ? 4 : 18),
            bottomLeft: const Radius.circular(18),
            bottomRight: const Radius.circular(18),
          ),
          boxShadow: [ // Add subtle shadow
            BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
              blurRadius: 3,
              offset: const Offset(1, 1),
            )
          ],
        ),
        child: Text(
            text,
            style: GoogleFonts.poppins( // Keep Google Fonts
                fontSize: 15, // Slightly smaller font
                color: chatTextColorLight,
                height: 1.4 // Improve line spacing
            )
        ),
      ),
    );
  }
}

// --- MessageInputField Widget (Updated Colors) ---
class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback sendMessage;
  final bool isLoading; // Receive loading state

  const MessageInputField({
    required this.controller,
    required this.sendMessage,
    required this.isLoading, // Require loading state
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
      color: chatInputBgColor, // Use dark background
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.poppins(fontSize: 15, color: chatTextColorLight), // Keep font
              decoration: InputDecoration(
                hintText: "Ask about invoices...",
                hintStyle: GoogleFonts.poppins(color: chatTextColorHint), // Use hint color
                filled: true,
                fillColor: chatInputFillColor, // Use input fill color
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25), // Rounded border
                  borderSide: BorderSide.none, // No visible border initially
                ),
                enabledBorder: OutlineInputBorder( // Keep border consistent
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder( // Highlight border on focus
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: chatAccentColor, width: 1.5), // Accent border
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // Padding inside text field
              ),
              textInputAction: TextInputAction.send, // Keyboard action
              onSubmitted: (_) => sendMessage(), // Send on keyboard action
              enabled: !isLoading, // Disable text field while loading
            ),
          ),
          const SizedBox(width: 8), // Space between text field and button
          // Send Button
          InkWell(
            onTap: isLoading ? null : sendMessage, // Disable tap while loading
            borderRadius: BorderRadius.circular(25), // Match button shape
            child: CircleAvatar(
              backgroundColor: isLoading ? Colors.grey.shade600 : chatAccentColor, // Use Accent color, grey out when loading
              radius: 24, // Slightly smaller radius
              child: isLoading
                  ? const SizedBox( // Show spinner inside button when loading
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: chatTextColorLight)
              )
                  : const Icon(Icons.send, color: chatTextColorLight, size: 22), // Send Icon
            ),
          ),
        ],
      ),
    );
  }
}