import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../provider/provider.dart';

class ReceiptAnalysisScreen extends StatelessWidget {
  const ReceiptAnalysisScreen({super.key});

  // UI Theme Colors & Styles
  static const Color _scaffoldBackgroundColor = Color(0xFFF8F9FA);
  static const Color _appBarBackgroundColor = Colors.white;
  static const Color _primaryColor = Color(0xFF4CAF50); // Green for receipts
  static const Color _accentColor = Color(0xFF2E7D32); // Darker green
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _textColorPrimary = Color(0xFF2D3748);
  static const Color _textColorSecondary = Color(0xFF718096);
  static const Color _shadowColor = Color(0xFFE2E8F0);

  // Category colors
  static const Map<String, Color> _categoryColors = {
    'Food': Color(0xFFFF9800),
    'Transportation': Color(0xFF2196F3),
    'Shopping': Color(0xFFE91E63),
    'Entertainment': Color(0xFF9C27B0),
    'Utilities': Color(0xFF009688),
    'Healthcare': Color(0xFFF44336),
    'Education': Color(0xFF3F51B5),
    'Travel': Color(0xFF795548),
    'Groceries': Color(0xFF8BC34A),
    'Other': Color(0xFF607D8B),
    'Uncategorized': Color(0xFF9E9E9E),
  };

  // Predefined list of distinct colors for unknown categories
  static const List<Color> _distinctColors = [
    Color(0xFF8BC34A),
    Color(0xFFCDDC39),
    Color(0xFFFFEB3B),
    Color(0xFFFFC107),
    Color(0xFFFF9800),
    Color(0xFF607D8B),
    Color(0xFF795548),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarBackgroundColor,
        elevation: 1.5,
        shadowColor: _shadowColor.withAlpha((0.9 * 255).toInt()),
        title: const Text(
          'Expense Analysis',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textColorPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textColorPrimary),
      ),
      body: Consumer<ReceiptScanProvider>(
        builder: (context, provider, child) {
          if (provider.scanHistory.isEmpty) {
            return _buildEmptyState(context);
          }

          final categoryData = provider.getSpendingByCategory();
          final totalSpending = provider.getTotalSpending();
          final monthlyData = provider.getMonthlySpending();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Statistics", Icons.analytics_outlined),
                _buildSummaryCards(provider.scanHistory.length, categoryData.length, totalSpending),
                const SizedBox(height: 16),
                _buildSectionHeader("Spending by Category", Icons.pie_chart_outline_rounded),
                SizedBox(height: 230, child: _buildCategoryPieChart(categoryData)),
                const SizedBox(height: 14),
                _buildSectionHeader("Monthly Spending", Icons.timeline_outlined),
                SizedBox(height: 200, child: _buildMonthlyBarChart(monthlyData)),
                const SizedBox(height: 16),
                _buildSectionHeader("Spending Insights", Icons.insights_outlined),
                _buildSpendingInsights(categoryData, totalSpending),
                const SizedBox(height: 126),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper Widgets
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 90,
              color: _textColorSecondary.withAlpha((0.6 * 255).toInt()),
            ),
            const SizedBox(height: 24),
            Text(
              'No Receipts Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _textColorPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan some receipts to unlock your expense analysis dashboard and track your spending over time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: _textColorSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Scan a Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, color: _accentColor, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColorPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int totalReceipts, int uniqueCategories, double totalSpending) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSummaryCard(
                    title: "Total Receipts",
                    value: totalReceipts.toString(),
                    icon: Icons.receipt_outlined,
                    color: _primaryColor,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard(
                    title: "Categories",
                    value: uniqueCategories.toString(),
                    icon: Icons.category_outlined,
                    color: _categoryColors['Food']!,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              _buildSummaryCard(
                title: "Total Spending",
                value: '\$${totalSpending.toStringAsFixed(2)}',
                icon: Icons.attach_money_outlined,
                color: _categoryColors['Shopping']!,
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(
                title: "Total Receipts",
                value: totalReceipts.toString(),
                icon: Icons.receipt_outlined,
                color: _primaryColor,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildSummaryCard(
                title: "Categories",
                value: uniqueCategories.toString(),
                icon: Icons.category_outlined,
                color: _categoryColors['Food']!,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildSummaryCard(
                title: "Total Spending",
                value: '\$${totalSpending.toStringAsFixed(2)}',
                icon: Icons.attach_money_outlined,
                color: _categoryColors['Shopping']!,
              )),
            ],
          );
        }
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shadowColor: _shadowColor.withAlpha((0.8 * 255).toInt()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: _cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textColorSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.17 * 255).toInt()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(Map<String, double> categoryData) {
    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          "No category data available",
          style: TextStyle(color: _textColorSecondary),
        ),
      );
    }

    final displayCategories = _groupSmallCategories(categoryData, maxItems: 7);
    final total = displayCategories.fold(0.0, (sum, entry) => sum + entry.value);

    return Card(
      elevation: 3,
      shadowColor: _shadowColor.withAlpha((0.7 * 255).toInt()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: _cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 55,
                    sections: displayCategories.map((entry) {
                      final percentage = (entry.value / total) * 100;
                      return PieChartSectionData(
                        value: entry.value,
                        color: _getCategoryColor(entry.key),
                        title: '${percentage ~/ 1}%',
                        radius: 25,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: displayCategories.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(entry.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_capitalizeFirstLetter(entry.key)} (\$${entry.value.toStringAsFixed(2)})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textColorSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildMonthlyBarChart(Map<String, double> monthlyData) {
    if (monthlyData.isEmpty) {
      return Center(
        child: Text(
          "No monthly data available",
          style: TextStyle(color: _textColorSecondary),
        ),
      );
    }

    final sortedMonths = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxAmount = monthlyData.values.fold(0.0, (max, amount) => amount > max ? amount : max);

    return Card(
      elevation: 3,
      shadowColor: _shadowColor.withAlpha((0.7 * 255).toInt()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: _cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxAmount,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.white,
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final month = sortedMonths[groupIndex].key;
                  return BarTooltipItem(
                    '$month\n\$${rod.toY.toStringAsFixed(2)}',
                    TextStyle(
                      color: _textColorPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedMonths.length) {
                      final monthParts = sortedMonths[index].key.split('-');
                      final month = monthParts[1];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _getMonthAbbreviation(month),
                          style: TextStyle(
                            fontSize: 10,
                            color: _textColorSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 38,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxAmount > 5 ? (maxAmount / 5).ceilToDouble() : 1,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) {
                      return const Text('');
                    }
                    return Text(
                      '\$${value.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _textColorSecondary,
                      ),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxAmount > 5 ? (maxAmount / 5).ceilToDouble() : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: _shadowColor.withAlpha(51), // 20% opacity
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: sortedMonths.asMap().entries.map((entry) {
              final index = entry.key;
              final month = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: month.value,
                    color: _getMonthColor(index),
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingInsights(
      Map<String, double> categoryData,
      double totalSpending,
      ) {
    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          "No data available for analysis",
          style: TextStyle(color: _textColorSecondary),
        ),
      );
    }

    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).toList();

    return Card(
      elevation: 3,
      shadowColor: _shadowColor.withAlpha((0.8 * 255).toInt()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: _cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColorPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Based on your receipts, here are your spending patterns:',
              style: TextStyle(
                fontSize: 14,
                color: _textColorSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ...topCategories.map((category) {
              final percentage = (category.value / totalSpending * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_capitalizeFirstLetter(category.key)} ($percentage%)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _textColorPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Amount: \$${category.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getCategoryInsight(category.key, category.value, totalSpending),
                      style: TextStyle(
                        fontSize: 14,
                        color: _textColorSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (sortedCategories.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                'Other spending categories: ${sortedCategories.sublist(3).map((e) => '${_capitalizeFirstLetter(e.key)} (${(e.value / totalSpending * 100).toStringAsFixed(1)}%)').join(', ')}',
                style: TextStyle(
                  fontSize: 13,
                  color: _textColorSecondary.withAlpha(179), // 70% opacity
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper Methods
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Color _getCategoryColor(String category) {
    // First try exact match
    if (_categoryColors.containsKey(category)) {
      return _categoryColors[category]!;
    }

    // If not found, use a consistent color from predefined distinct colors
    return _getConsistentColorForCategory(category);
  }

  Color _getConsistentColorForCategory(String category) {
    // Use the hash code to get a consistent index for the category
    final hash = category.hashCode;
    final index = hash.abs() % _distinctColors.length;
    return _distinctColors[index];
  }

  Color _getMonthColor(int index) {
    const List<Color> monthColors = [
      Color(0xFF4CAF50),  // Green
      Color(0xFF2196F3),  // Blue
      Color(0xFF9C27B0),  // Purple
      Color(0xFFF44336),  // Red
      Color(0xFFFF9800),  // Orange
      Color(0xFF795548),  // Brown
      Color(0xFF607D8B),  // Blue Grey
      Color(0xFFE91E63),  // Pink
      Color(0xFF009688),  // Teal
      Color(0xFF673AB7),  // Deep Purple
      Color(0xFF3F51B5),  // Indigo
      Color(0xFF00BCD4),  // Cyan
    ];
    return monthColors[index % monthColors.length];
  }

  List<MapEntry<String, double>> _groupSmallCategories(
      Map<String, double> categories, {
        int maxItems = 5,
      }) {
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.length <= maxItems) return sorted;

    final mainCategories = sorted.sublist(0, maxItems - 1);
    final othersAmount = sorted
        .sublist(maxItems - 1)
        .fold(0.0, (sum, entry) => sum + entry.value);

    final result = <MapEntry<String, double>>[];
    result.addAll(mainCategories);
    result.add(MapEntry('Other', othersAmount));

    return result;
  }

  String _getCategoryInsight(String category, double amount, double total) {
    final percentage = (amount / total * 100).round();
    final normalized = category.toLowerCase();

    if (normalized.contains('food') || normalized.contains('groceries')) {
      return '$percentage% of your spending is on food. Consider meal planning to potentially reduce costs.';
    } else if (normalized.contains('transport')) {
      return '$percentage% of your spending is on transportation. Explore carpooling or public transit options.';
    } else if (normalized.contains('shop')) {
      return '$percentage% of your spending is on shopping. Try implementing a 24-hour rule for non-essential purchases.';
    } else if (normalized.contains('entertain')) {
      return '$percentage% of your spending is on entertainment. Look for free community events as alternatives.';
    } else if (normalized.contains('util')) {
      return '$percentage% of your spending is on utilities. Consider energy-saving measures to reduce costs.';
    } else if (normalized.contains('health')) {
      return '$percentage% of your spending is on healthcare. Review insurance options for potential savings.';
    } else if (normalized.contains('educat')) {
      return '$percentage% of your spending is on education. This is an investment in your future.';
    } else if (normalized.contains('travel')) {
      return '$percentage% of your spending is on travel. Booking in advance can often secure better rates.';
    } else {
      return '$percentage% of your spending is in this category. Review these expenses periodically.';
    }
  }

  String _getMonthAbbreviation(String monthNumber) {
    switch (monthNumber) {
      case '01': return 'Jan';
      case '02': return 'Feb';
      case '03': return 'Mar';
      case '04': return 'Apr';
      case '05': return 'May';
      case '06': return 'Jun';
      case '07': return 'Jul';
      case '08': return 'Aug';
      case '09': return 'Sep';
      case '10': return 'Oct';
      case '11': return 'Nov';
      case '12': return 'Dec';
      default: return monthNumber;
    }
  }
}