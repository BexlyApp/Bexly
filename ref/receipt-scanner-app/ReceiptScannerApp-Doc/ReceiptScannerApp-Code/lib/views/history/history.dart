import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../database/database.dart';
import '../../models/model.dart';
import '../../provider/provider.dart';

class ReceiptHistoryScreen extends StatelessWidget {
  const ReceiptHistoryScreen({super.key});

  // Color constants
  static const Color _scaffoldBackgroundColor = Color(0xFFF8F9FA);
  static const Color _appBarBackgroundColor = Colors.white;
  static const Color _primaryColor = Color(0xFF4CAF50); // Green for money
  static const Color _accentColor = Color(0xFF2E7D32); // Darker green
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _textColorPrimary = Color(0xFF2C3E50);
  static const Color _textColorSecondary = Color(0xFF7F8C8D);
  static const Color _iconColorActive = _primaryColor;
  static const Color _iconColorInactive = Color(0xFFBDC3C7);
  static const Color _errorColor = Color(0xFFE74C3C);
  static const Color _shadowColor = Color(0xFFE0E0E0);

  // Category colors palette
  static const List<Color> _categoryColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF607D8B), // Blue Gray
    Color(0xFF795548), // Brown
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarBackgroundColor,
        elevation: 2,
        shadowColor: _shadowColor.withAlpha(0x70),
        iconTheme: const IconThemeData(color: _textColorPrimary),
        centerTitle: true,
        title: const Text(
          'Receipt History',
          style: TextStyle(
            color: _textColorPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded, color: _iconColorActive),
            onPressed: () => _showAnalytics(context),
            tooltip: 'View Analytics',
          ),
        ],
      ),
      body: Consumer<ReceiptScanProvider>(
        builder: (context, provider, child) {
          if (provider.scanHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: _iconColorInactive,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Receipts Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scan receipts to see your expense history here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _textColorSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: provider.scanHistory.length,
                  itemBuilder: (context, index) {
                    final entry = provider.scanHistory[index];
                    return FutureBuilder<Uint8List?>(
                      future: provider.getScanImage(entry[DatabaseHelper.columnId] as int),
                      builder: (context, snapshot) {
                        return _buildHistoryCard(
                          context,
                          entry,
                          snapshot.data,
                          snapshot.connectionState == ConnectionState.waiting,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 110),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(
      BuildContext context,
      Map<String, dynamic> entry,
      Uint8List? imageBytes,
      bool isLoading,
      ) {
    final result = jsonDecode(entry[DatabaseHelper.columnResult] as String);
    final scan = ReceiptScanResult.fromJson(result);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      entry[DatabaseHelper.columnTimestamp] as int,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shadowColor: _shadowColor.withAlpha(0x80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBackgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetails(context, entry, scan, imageBytes),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _scaffoldBackgroundColor,
                ),
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: _primaryColor,
                    strokeWidth: 3,
                  ),
                )
                    : (imageBytes != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes,
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                  ),
                )
                    : Center(
                  child: Icon(
                    Icons.receipt_outlined,
                    size: 36,
                    color: _iconColorInactive,
                  ),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.merchant,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textColorPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withAlpha(0x30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '\$${scan.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: _textColorSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, hh:mm a').format(timestamp),
                            style: TextStyle(
                              color: _textColorSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickMetric(
                            'Category',
                            scan.category,
                            Icons.category_outlined,
                          ),
                          if (scan.paymentMethod.isNotEmpty)
                            _buildQuickMetric(
                              'Payment',
                              scan.paymentMethod,
                              Icons.credit_card_outlined,
                            ),
                          if (scan.date.isNotEmpty)
                            _buildQuickMetric(
                              'Date',
                              scan.date,
                              Icons.date_range_outlined,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _confirmDelete(context, entry[DatabaseHelper.columnId] as int),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.delete_sweep_outlined,
                      color: _errorColor.withAlpha(0xE6),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _primaryColor.withAlpha(0x18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: _primaryColor.withAlpha(0xCC),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              color: _accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(
      BuildContext context,
      Map<String, dynamic> entry,
      ReceiptScanResult scan,
      Uint8List? imageBytes,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: _scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(0x30),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _iconColorInactive.withAlpha(0xB3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              scan.merchant,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _textColorPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: _textColorSecondary,
                              size: 26,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryColor.withAlpha(0x30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '\$${scan.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _accentColor.withAlpha(0x30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                scan.category,
                                style: TextStyle(
                                  color: _accentColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (imageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            imageBytes,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _iconColorInactive.withAlpha(0x80),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.receipt_outlined,
                              size: 60,
                              color: _iconColorInactive,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: _textColorSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM d, yyyy  hh:mm a').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                entry[DatabaseHelper.columnTimestamp] as int,
                              ),
                            ),
                            style: TextStyle(
                              color: _textColorSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        height: 36,
                        thickness: 1,
                        color: _iconColorInactive.withAlpha(0x80),
                      ),
                      _buildSectionTitle('Transaction Details', Icons.receipt_long_outlined),
                      _buildDetailRow('Merchant', scan.merchant),
                      _buildDetailRow('Amount', '\$${scan.amount.toStringAsFixed(2)}'),
                      _buildDetailRow('Category', scan.category),
                      _buildDetailRow('Payment Method', scan.paymentMethod),
                      _buildDetailRow('Date', scan.date),
                      if (scan.items.isNotEmpty) ...[
                        Divider(
                          height: 36,
                          thickness: 1,
                          color: _iconColorInactive.withAlpha(0x80),
                        ),
                        _buildSectionTitle('Items Purchased', Icons.shopping_basket_outlined),
                        ...scan.items.map(
                              (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, right: 10),
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 18,
                                    color: _primaryColor,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: _textColorPrimary.withAlpha(0xE6),
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (scan.taxAmount != null) ...[
                        Divider(
                          height: 36,
                          thickness: 1,
                          color: _iconColorInactive.withAlpha(0x80),
                        ),
                        _buildDetailRow('Tax', '\$${scan.taxAmount}'),
                      ],
                      if (scan.tipAmount != null) ...[
                        Divider(
                          height: 36,
                          thickness: 1,
                          color: _iconColorInactive.withAlpha(0x80),
                        ),
                        _buildDetailRow('Tip', '\$${scan.tipAmount}'),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: _textColorSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _textColorPrimary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: _accentColor, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: _textColorPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _errorColor.withAlpha(0xE6),
              size: 26,
            ),
            const SizedBox(width: 10),
            const Text(
              'Confirm Deletion',
              style: TextStyle(
                color: _textColorPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete this receipt?',
          style: TextStyle(color: _textColorSecondary),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _textColorSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final provider = Provider.of<ReceiptScanProvider>(context, listen: false);
              await provider.deleteScan(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAnalytics(BuildContext context) {
    final provider = Provider.of<ReceiptScanProvider>(context, listen: false);
    if (provider.scanHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No data available for analytics yet.'),
          backgroundColor: _textColorSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final byCategory = provider.getSpendingByCategory();
    final monthlySpending = provider.getMonthlySpending();
    final totalSpending = provider.getTotalSpending();


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: _scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(0x30),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _iconColorInactive.withAlpha(0xB3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSectionTitle('Statistics', Icons.analytics_outlined),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Receipts',
                              provider.scanHistory.length.toString(),
                              Icons.receipt_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              'Categories',
                              byCategory.length.toString(),
                              Icons.category_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Spending',
                              '\$${totalSpending.toStringAsFixed(2)}',
                              Icons.attach_money_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        height: 1,
                        color: _iconColorInactive.withAlpha(0x80),
                      ),
                      const SizedBox(height: 20),
                      if (byCategory.isNotEmpty) ...[
                        _buildSectionTitle('Spending by Category', Icons.pie_chart_outline),
                        const SizedBox(height: 10),
                        ..._buildCategoryDistributionItems(byCategory),
                        const SizedBox(height: 24),
                      ],
                      if (monthlySpending.isNotEmpty) ...[
                        _buildSectionTitle('Monthly Spending', Icons.calendar_today),
                        const SizedBox(height: 10),
                        ...monthlySpending.entries.map((e) {
                          final percentage = totalSpending > 0 ? (e.value / totalSpending) : 0.0;
                          return _buildAnalyticsBar(
                            context,
                            e.key,
                            e.value,
                            percentage,
                            _categoryColors[e.key.hashCode.abs() % _categoryColors.length],
                            isCurrency: true,
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryDistributionItems(Map<String, double> byCategory) {
    final categoryEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = byCategory.values.fold(0.0, (sum, item) => sum + item);

    return categoryEntries
        .map((e) => _buildCategoryDistributionItem(e.key, e.value, total))
        .toList();
  }

  Widget _buildCategoryDistributionItem(String category, double amount, double total) {
    final percentage = total > 0 ? (amount / total) : 0.0;
    final colorIndex = category.hashCode.abs() % _categoryColors.length;
    final color = _categoryColors[colorIndex];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        category,
        style: TextStyle(
          fontSize: 14,
          color: _textColorPrimary,
        ),
      ),
      trailing: Text(
        '\$${amount.toStringAsFixed(2)} (${(percentage * 100).toStringAsFixed(0)}%)',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _textColorPrimary,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withAlpha(0x33),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: _primaryColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _textColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColorPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsBar(
      BuildContext context,
      String label,
      double amount,
      double percentage,
      Color barColor, {
        bool isCurrency = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _textColorSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isCurrency
                      ? '\$${amount.toStringAsFixed(2)} (${(percentage * 100).toStringAsFixed(0)}%)'
                      : '${amount.toStringAsFixed(2)} (${(percentage * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textColorPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: barColor.withAlpha(0x66),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}