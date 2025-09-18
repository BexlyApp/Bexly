import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:invoiceandbilling/constants/colors.dart';

import '../../Widgets/customapp_bar.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomAppBar(text: 'Billing Analytics', text1: ''),
              const SizedBox(height: 10),
              _buildRevenueCard(),
              const SizedBox(height: 7),
              _buildMonthlyRevenueChart(),
              const SizedBox(height: 6),
              _buildInvoiceStatusChart(),
              const SizedBox(height: 10),
              _buildTopClientsTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    final currentMonthRevenue = 12500.0;
    final lastMonthRevenue = 9800.0;
    final percentageChange = ((currentMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13,vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Month', style: TextStyle(color: Colors.grey.shade600)),
                  Text('\$${currentMonthRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('vs Last Month', style: TextStyle(color: Colors.grey.shade600)),
                  Text(
                    '${percentageChange.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: percentageChange >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    percentageChange >= 0 ? '↑ Increase' : '↓ Decrease',
                    style: TextStyle(color: percentageChange >= 0 ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMonthlyRevenueChart() {
    final monthlyData = [
      {'month': 'Jan', 'revenue': 8500.0},
      {'month': 'Feb', 'revenue': 9200.0},
      {'month': 'Mar', 'revenue': 10500.0},
      {'month': 'Apr', 'revenue': 9800.0},
      {'month': 'May', 'revenue': 11200.0},
      {'month': 'Jun', 'revenue': 12500.0},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Revenue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 15000,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.buttonColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month = monthlyData[group.x.toInt()]['month'];
                      final revenue = monthlyData[group.x.toInt()]['revenue'] as double?;
                      return BarTooltipItem(
                        '$month\n\$${revenue?.toStringAsFixed(2) ?? "0.00"}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(monthlyData[value.toInt()]['month'] as String),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value >= 1000 ? '\$${(value / 1000).toStringAsFixed(0)}K' : '\$$value');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: monthlyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data['revenue'] as double,
                        color: AppColors.buttonColor,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceStatusChart() {
    final invoiceStatusData = [
      {'status': 'Paid', 'count': 45, 'color': Colors.green},
      {'status': 'Pending', 'count': 18, 'color': Colors.orange},
      {'status': 'Overdue', 'count': 7, 'color': Colors.red},
      {'status': 'Draft', 'count': 5, 'color': Colors.grey},
    ];

    final totalInvoices = invoiceStatusData.fold(0, (sum, item) => sum + (item['count'] as int));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invoice Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: invoiceStatusData.map((data) {
                      return PieChartSectionData(
                        color: data['color'] as Color,
                        value: (data['count'] as int).toDouble(),
                        title: '${((data['count'] as int) / totalInvoices * 100).toStringAsFixed(1)}%',
                        radius: 25,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: invoiceStatusData.map((data) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, color: data['color'] as Color),
                          const SizedBox(width: 8),
                          Text('${data['status']}: ${data['count']}'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopClientsTable() {
    final topClients = [
      {'name': 'Acme Corp', 'invoices': 12, 'total': 8500.0},
      {'name': 'Globex Inc', 'invoices': 8, 'total': 6200.0},
      {'name': 'Wayne Enterprises', 'invoices': 6, 'total': 5400.0},
      {'name': 'Stark Industries', 'invoices': 5, 'total': 4800.0},
      {'name': 'Umbrella Corp', 'invoices': 4, 'total': 3200.0},
    ];

    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Clients by Revenue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 30,
              columns: const [
                DataColumn(label: Text('Client')),
                DataColumn(label: Text('Invoices'), numeric: true),
                DataColumn(label: Text('Total Revenue'), numeric: true),
              ],
              rows: topClients.map((client) {
                return DataRow(cells: [
                  DataCell(Text(client['name'] as String)),
                  DataCell(Text(client['invoices'].toString())),
                  DataCell(Text(currencyFormat.format(client['total']))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}