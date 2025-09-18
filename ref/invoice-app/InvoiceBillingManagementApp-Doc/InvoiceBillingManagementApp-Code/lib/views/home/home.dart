import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import 'homme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F1D61),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Total Balance",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "\$4,587,946",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("+45%", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
                            ),
              ),
                const SizedBox(height: 5),
                _buildStatsCards(),
                const SizedBox(height: 10),
                _buildPaymentStats(),
                const SizedBox(height: 11),
                DashboardScreen(),

              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildPaymentStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Payment Statics", style: GoogleFonts.poppins(fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [Text("Weekly"), Icon(Icons.arrow_drop_down)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Total Invoice Amount \$9765"),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.6,
            child: BarChart(
              BarChartData(
                barGroups: _barGroups(),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _barGroups() {
    final purpleBars = [8.0, 4.0, 6.0, 3.0, 7.0, 6.0, 9.0];
    final blackBars = [3.0, 9.0, 5.0, 2.0, 4.0, 3.0, 2.0];

    return List.generate(purpleBars.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: purpleBars[index],
            color: Colors.deepPurple,
            width: 13,
          ),
          BarChartRodData(
            toY: blackBars[index],
            color: Colors.black87,
            width: 13,
          ),
        ],
      );
    });
  }
}

// The main widget for the horizontally scrolling cards
Widget _buildStatsCards() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    // Add padding for space before the first and after the last card
    padding: const EdgeInsets.symmetric(horizontal: 0.0),
    child: Row(
      children: [
        _buildCard(
          title: "Invoices",
          value: "\$125,467",
          subtitle: "This Week",
          percentageValue: 12.53, // Pass numeric value for logic
          icon: Icons.receipt_long,
          iconBgColor: Colors.orangeAccent.shade100,
          iconColor: Colors.orangeAccent.shade700,
        ),
        const SizedBox(width: 6), // Increased spacing
        _buildCard(
          title: "Customers",
          value: "125",
          subtitle: "This Week",
          percentageValue: -2.15, // Example negative percentage
          icon: Icons.people_outline,
          iconBgColor: Colors.lightBlue.shade100,
          iconColor: Colors.lightBlue.shade700,
        ),
        const SizedBox(width: 16), // Keep spacing consistent
        _buildCard(
          title: "Avg. Sale",
          value: "\$1,003",
          subtitle: "This Month",
          // No percentage change
          icon: Icons.attach_money,
          iconBgColor: Colors.greenAccent.shade100,
          iconColor: Colors.greenAccent.shade700,
        ),
        // Add more cards as needed...
      ],
    ),
  );
}

// The refined card widget
Widget _buildCard({
  required String title,
  required String value,
  String? subtitle,
  double? percentageValue, // Use double for +/- check
  IconData? icon,
  Color iconBgColor = Colors.grey, // Default icon background
  Color iconColor = Colors.black, // Default icon color
}) {
  // Determine percentage style based on value
  bool isPositive = percentageValue != null && percentageValue >= 0;
  Color percentageColor =
      isPositive ? Colors.green.shade700 : Colors.red.shade700;
  IconData percentageIcon =
      isPositive ? Icons.arrow_upward : Icons.arrow_downward;
  String percentageText =
      percentageValue != null
          ? "${isPositive ? '+' : ''}${percentageValue.toStringAsFixed(2)}%"
          : "";

  return Container(
    height: 140, // Slightly adjusted height
    width: 180, // Slightly adjusted width
    padding: const EdgeInsets.all(16), // Consistent padding
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        // Add a subtle shadow for depth
        BoxShadow(
          color: Colors.grey.withAlpha((0.2 * 255).toInt()),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 3), // changes position of shadow
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Top Row: Title, Subtitle, and Icon ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align icon top
          children: [
            // --- Title and Subtitle ---
            Expanded(
              // Takes available space, pushing icon right
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w500, // Slightly less bold than value
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // --- Icon ---
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor, // Use the specified background color
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ), // Use specified icon color
              ),
          ],
        ),

        // --- Spacer ---
        // --- Value ---
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 28, // Larger value
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4), // Small space before percentage
        // --- Percentage Change ---
        if (percentageValue != null)
          Row(
            children: [
              Icon(percentageIcon, size: 16, color: percentageColor),
              const SizedBox(width: 4),
              Text(
                percentageText,
                style: GoogleFonts.poppins(
                  color: percentageColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        else
          const SizedBox(
            height: 2,
          ), // Placeholder to keep height consistent if no percentage
      ],
    ),
  );
}
