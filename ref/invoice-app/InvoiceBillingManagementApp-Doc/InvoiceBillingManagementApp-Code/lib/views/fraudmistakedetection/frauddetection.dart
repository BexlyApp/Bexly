import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import '../../core/apiconfig.dart';

class FraudDetectionAssistant extends StatefulWidget {
  const FraudDetectionAssistant({super.key});

  @override
  State<FraudDetectionAssistant> createState() => _FraudDetectionAssistantState();
}

class _FraudDetectionAssistantState extends State<FraudDetectionAssistant> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  bool showAnalysis = false;

  List<Map<String, dynamic>> bills = [
    {
      "id": "1",
      "description": "Office Supplies",
      "amount": 150.0,
      "date": "2025-04-10",
      "paidBy": "John Doe",
      "category": "Expenses",
      "receipt": false
    },
    {
      "id": "2",
      "description": "Client Dinner",
      "amount": 250.0,
      "date": "2025-04-09",
      "paidBy": "Jane Smith",
      "category": "Entertainment",
      "receipt": true
    },
    {
      "id": "3",
      "description": "Office Supplies",
      "amount": 150.0,
      "date": "2025-04-10",
      "paidBy": "John Doe",
      "category": "Expenses",
      "receipt": false
    },
    {
      "id": "4",
      "description": "Software Subscription",
      "amount": 499.0,
      "date": "2025-04-08",
      "paidBy": "Mike Johnson",
      "category": "Technology",
      "receipt": true
    },
  ];

  Map<String, dynamic> _analyzeBills() {
    // 1. Duplicate Detection
    final seenBills = <String, List<Map<String, dynamic>>>{};
    final duplicateBills = <Map<String, dynamic>>[];

    for (final bill in bills) {
      final key = "${bill['description']}_${bill['amount']}_${bill['date']}";
      if (seenBills.containsKey(key)) {
        seenBills[key]!.add(bill);
        if (seenBills[key]!.length == 2) {
          duplicateBills.addAll(seenBills[key]!);
        }
      } else {
        seenBills[key] = [bill];
      }
    }

    // 2. Fairness Check
    final userTotals = <String, double>{};
    for (var bill in bills) {
      final user = bill['paidBy'];
      userTotals[user] = (userTotals[user] ?? 0) + (bill['amount'] ?? 0);
    }

    final avg = userTotals.values.fold(0.0, (a, b) => a + b) / userTotals.length;
    final fairnessIssues = userTotals.entries
        .map((e) => {
      "user": e.key,
      "amount": e.value,
      "deviation": ((e.value - avg) / avg * 100).round(),
      "status": e.value > avg * 1.3
          ? "Overpaying"
          : e.value < avg * 0.7
          ? "Underpaying"
          : "Fair"
    })
        .toList();

    // 3. Missing Receipts
    final missingReceipts = bills.where((bill) => bill['receipt'] == false).toList();

    // 4. Unusual Amounts
    final avgAmount = bills.fold(0.0, (sum, bill) => sum + bill['amount']) / bills.length;
    final unusualBills = bills.where((bill) =>
    bill['amount'] > avgAmount * 3 ||
        bill['amount'] < avgAmount * 0.2).toList();

    return {
      "duplicates": duplicateBills,
      "fairness": fairnessIssues,
      "missingReceipts": missingReceipts,
      "unusualBills": unusualBills,
      "stats": {
        "totalBills": bills.length,
        "totalAmount": bills.fold(0.0, (sum, bill) => sum + bill['amount']),
        "averageBill": avgAmount,
      }
    };
  }

  Future<void> fetchGeminiResponse(String prompt) async {
    setState(() => isLoading = true);

    final analysis = _analyzeBills();

    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{
              "text": "You are a financial fraud detection assistant for an invoice and billing system. "
                  "Provide concise, actionable insights. Always format responses with clear headings and bullet points. "
                  "Current analysis: ${jsonEncode(analysis)}. "
                  "User question: $prompt"
            }]
          }],
          "generationConfig": {
            "temperature": 0.3,
            "topP": 0.8,
            "maxOutputTokens": 1500,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      final text = jsonDecode(response.body)["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
      if (text != null && text is String) {
        setState(() => messages.add({
          "role": "bot",
          "text": text,
          "timestamp": DateTime.now(),
          "analysis": analysis
        }));
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      setState(() => messages.add({
        "role": "bot",
        "text": "⚠️ Error processing your request. Please try again later.",
        "error": true
      }));
    } finally {
      setState(() => isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text("Bill Analysis", style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _buildAnalysisItem("Total Bills", analysis['stats']['totalBills'].toString()),
            _buildAnalysisItem("Total Amount", "\$${analysis['stats']['totalAmount'].toStringAsFixed(2)}"),
            _buildAnalysisItem("Average Bill", "\$${analysis['stats']['averageBill'].toStringAsFixed(2)}"),

            if (analysis['duplicates'].isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildAlertSection(
                  "⚠️ ${analysis['duplicates'].length} Potential Duplicates",
                  analysis['duplicates'].map((d) =>
                  "${d['description']} - \$${d['amount']} on ${d['date']}"
                  ).join("\n"),
                  Colors.orange
              ),
            ],

            if (analysis['missingReceipts'].isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildAlertSection(
                  "📄 ${analysis['missingReceipts'].length} Missing Receipts",
                  analysis['missingReceipts'].map((d) =>
                  "${d['description']} - \$${d['amount']}"
                  ).join("\n"),
                  Colors.blue
              ),
            ],

            if (analysis['unusualBills'].isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildAlertSection(
                  "🔍 ${analysis['unusualBills'].length} Unusual Amounts",
                  analysis['unusualBills'].map((d) =>
                  "${d['description']} - \$${d['amount']} (${(d['amount']/analysis['stats']['averageBill']).toStringAsFixed(1)}x average)"
                  ).join("\n"),
                  Colors.purple
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSection(String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withAlpha((0.2 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha((0.2 * 255).toInt()))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> message) {
    final isBot = message['role'] == 'bot';
    return Column(
      crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: isBot ? Colors.grey[100] : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isBot ? 0 : 12),
              bottomRight: Radius.circular(isBot ? 12 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.2 * 255).toInt()),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message['text'],
                style: TextStyle(
                  fontSize: 14,
                  color: isBot ? Colors.black87 : Colors.blue[900],
                ),
              ),
              if (isBot && message['analysis'] != null && showAnalysis)
                _buildAnalysisCard(message['analysis']),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: isBot ? 12 : 0,
            right: isBot ? 0 : 12,
          ),
          child: Text(
            message['timestamp'] != null
                ? "${message['timestamp'].hour}:${message['timestamp'].minute.toString().padLeft(2, '0')}"
                : "",
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraud Detection Assistant'),
        actions: [
          IconButton(
            icon: Icon(showAnalysis ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => showAnalysis = !showAnalysis),
            tooltip: showAnalysis ? 'Hide Analysis' : 'Show Analysis',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildChatBubble(messages[index]),
            ),
          ),
          if (isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask about duplicates, fairness...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      suffixIcon: IconButton(
                        icon: const Icon(Iconsax.scan_barcode),
                        onPressed: () {
                          // Add scan receipt functionality
                        },
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;

    setState(() {
      messages.add({
        "role": "user",
        "text": value,
        "timestamp": DateTime.now()
      });
    });

    fetchGeminiResponse(value);
    _controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }
}