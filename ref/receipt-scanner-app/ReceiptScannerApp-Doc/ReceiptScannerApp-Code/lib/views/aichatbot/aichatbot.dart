import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io'; // For SocketException

import '../../core/config.dart'; // Ensure this file exists and is properly configured

class AISmartReceiptExpenseScreen extends StatefulWidget {
  const AISmartReceiptExpenseScreen({super.key});

  @override
  State<AISmartReceiptExpenseScreen> createState() => _AISmartReceiptExpenseScreenState();
}

class _AISmartReceiptExpenseScreenState extends State<AISmartReceiptExpenseScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showTypingIndicator = false;
  final String _apiKey = ApiConfig.geminiApiKey;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        "role": "bot",
        "text": "💰 Welcome to your Smart Receipt & Expense Assistant! I can help you:\n\n"
            "• Analyze receipt images (describe or upload)\n"
            "• Categorize expenses\n"
            "• Track spending patterns\n"
            "• Generate expense reports\n"
            "• Answer financial questions\n\n"
            "Examples:\n"
            "- \"Categorize this receipt: \$12.50 at Starbucks\"\n"
            "- \"How much did I spend on groceries last month?\"\n"
            "- \"What's my entertainment budget for this week?\"",
        "timestamp": DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  Future<String> _getFinanceResponse(String userInput) async {
    if (_apiKey.isEmpty) {
      return "API Key not configured. Please contact support.";
    }

    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey");
    // Note: Replaced 'gemini-2.0-flash' with 'gemini-pro' as a placeholder. Verify the correct model name.

    final messages = [
      {
        "role": "user",
        "parts": [
          {
            "text": """You are a professional financial assistant specializing in receipt analysis and expense management. Your role is to:
- Analyze receipt information (either described or from images)
- Categorize expenses accurately (food, transportation, utilities, etc.)
- Provide spending insights and trends
- Answer personal finance questions
- Suggest budgeting strategies
- Maintain a professional, helpful tone
- Format monetary values clearly (\$12.50 instead of 12.5)
- For receipt analysis, always include: [Amount] [Category] [Date if available] [Merchant]

User query: $userInput"""
          }
        ]
      }
    ];

    final body = jsonEncode({
      "contents": messages,
      "generationConfig": {
        "temperature": 0.5,
        "maxOutputTokens": 400,
      },
      "safetySettings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_ONLY_HIGH"
        },
        {
          "category": "HARM_CATEGORY_HATE_SPEECH",
          "threshold": "BLOCK_ONLY_HIGH"
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_ONLY_HIGH"
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_ONLY_HIGH"
        }
      ]
    });

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
    };

    try {
      final response = await http
          .post(
        url,
        headers: headers, // Fixed syntax
        body: body,
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        try {
          final String responseBody = utf8.decode(response.bodyBytes);
          final data = json.decode(responseBody);

          if (data['candidates'] != null &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['content'] != null &&
              data['candidates'][0]['content']['parts'] != null &&
              data['candidates'][0]['content']['parts'].isNotEmpty) {
            return data['candidates'][0]['content']['parts'][0]['text'] ??
                "I couldn't process that financial request. Please try again.";
          } else {
            return "Sorry, I couldn't process the response. Please try again.";
          }
        } on FormatException catch (e) {
          debugPrint('UTF-8 Decode Error: $e');
          return "Error processing server response. Please try again.";
        }
      } else {
        final errorBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        debugPrint('API Error: ${response.statusCode} - $errorBody');
        return "Sorry, I'm having trouble with financial analysis right now (Error ${response.statusCode}). Please try again later.";
      }
    } on TimeoutException {
      debugPrint('API Timeout');
      return "The request timed out. Please check your internet connection and try again.";
    } on SocketException {
      debugPrint('Network Error');
      return "Network error. Please check your internet connection and try again.";
    } catch (e) {
      debugPrint('Unexpected API Error: $e');
      return "An unexpected error occurred. Please try again.";
    }
  }

  void _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _messages.add({
        "role": "user",
        "text": userInput,
        "timestamp": DateTime.now()
      });
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    // Show typing indicator after a short delay to mimic processing
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _showTypingIndicator = true;
      });
    }

    try {
      final botReply = await _getFinanceResponse(userInput);

      // Ensure typing indicator shows for at least 1 second
      await Future.delayed(Duration(milliseconds: 1000 + (botReply.length * 5).clamp(500, 2000)));

      if (mounted) {
        setState(() {
          _messages.add({
            "role": "bot",
            "text": botReply,
            "timestamp": DateTime.now()
          });
          _isLoading = false;
          _showTypingIndicator = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showTypingIndicator = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _sendMessage(),
            ),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
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

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final timestamp = message['timestamp'] as DateTime;
    final timeString = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 20),
              child: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.attach_money_rounded, color: Colors.blue, size: 20),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.07 * 255).toInt()),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                    message['text'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  )
                      : MarkdownBody(
                    data: message['text'] ?? "...",
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: Colors.grey[850],
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    timeString,
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 20),
              child: CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: Icon(Icons.person_outline, color: Colors.blue[700], size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 0),
            child: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.attach_money_rounded, color: Colors.blue, size: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TypingDot(delay: 0),
                SizedBox(width: 5),
                TypingDot(delay: 200),
                SizedBox(width: 5),
                TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Smart Receipt & Expense",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Capture Receipt',
            onPressed: () {
              // TODO: Implement receipt image capture using image_picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Receipt capture functionality coming soon")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("About Smart Receipt & Expense"),
                  content: const Text(
                    "This assistant helps you track expenses by analyzing receipts. "
                        "You can either describe receipts or upload images. I'll categorize expenses, "
                        "track spending patterns, and help with budgeting.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK", style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length + (_showTypingIndicator ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _showTypingIndicator) {
                  return _buildTypingIndicator();
                }
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.09 * 255).toInt()),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Semantics(
                        label: 'Expense input field',
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Describe a receipt or ask about expenses...",
                            hintStyle: TextStyle(color: Colors.grey),
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 16),
                          maxLines: 5,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      onPressed: _isLoading ? null : _sendMessage,
                      tooltip: "Send Message",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingDot extends StatefulWidget {
  final int delay;
  const TypingDot({super.key, required this.delay});

  @override
  TypingDotState createState() => TypingDotState();
}

class TypingDotState extends State<TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInQuad),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}