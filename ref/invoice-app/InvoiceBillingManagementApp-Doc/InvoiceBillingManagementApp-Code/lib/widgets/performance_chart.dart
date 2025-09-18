// import 'dart:math';
//
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
//
// import '../Constants/colors.dart';
//
// class PerformanceChart extends StatefulWidget {
//   const PerformanceChart({super.key});
//
//   @override
//   State<PerformanceChart> createState() => _PerformanceChartState();
// }
//
// class _PerformanceChartState extends State<PerformanceChart> {
//   @override
//   Widget build(BuildContext context) {
//     return BarChart(
//       mainBarData(),
//     );
//   }
//
//   BarChartGroupData makeGroupData(int x, double y) {
//     return BarChartGroupData(x: x, barRods: [
//       BarChartRodData(
//           toY: y,
//           gradient: const LinearGradient(colors: [
//             Colors.white,
//             Colors.white,
//             Colors.white,
//             Colors.white,
//
//             // Theme.of(context).colorScheme.primary,
//             // Theme.of(context).colorScheme.secondary,
//             // Theme.of(context).colorScheme.tertiary,
//           ], transform: GradientRotation(pi / 40)),
//           width: 25,
//           backDrawRodData: BackgroundBarChartRodData(
//               show: true, toY: 5, color:AppColors.text3Color
//           ))
//     ]);
//   }
//
//   List<BarChartGroupData> showingGroups() => List.generate(5, (i) {
//     switch (i) {
//       case 0:
//         return makeGroupData(0, 3);
//       case 1:
//         return makeGroupData(1, 4);
//       case 2:
//         return makeGroupData(2, 2);
//       case 3:
//         return makeGroupData(3, 4.5);
//       case 4:
//         return makeGroupData(4, 3.8);
//
//
//
//       default:
//         return throw Error;
//     }
//   });
//   BarChartData mainBarData() {
//     return BarChartData(
//
//       titlesData: FlTitlesData(
//           show: true,
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           bottomTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 reservedSize: 38,
//                 getTitlesWidget: getTiles,
//               )),
//           leftTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 reservedSize: 30,
//                 getTitlesWidget: leftTitles,
//               ))),
//       borderData: FlBorderData(show: false),
//       gridData: const FlGridData(show: false),
//       barGroups: showingGroups(),
//     );
//   }
//
//   Widget getTiles(double value, TitleMeta meta) {
//     const style = TextStyle(
//         color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12);
//     Widget text;
//     switch (value.toInt()) {
//       case 0:
//         text = const Text(
//           'Mon',
//           style: style,
//         );
//         break;
//       case 1:
//         text = const Text(
//           'Tu',
//           style: style,
//         );
//         break;
//       case 2:
//         text = const Text(
//           'Wed',
//           style: style,
//         );
//         break;
//       case 3:
//         text = const Text(
//           'Thurs',
//           style: style,
//         );
//         break;
//       case 4:
//         text = const Text(
//           'Frid',
//           style: style,
//         );
//         break;
//
//
//       default:
//         text = const Text(
//           '',
//           style: style,
//         );
//         break;
//     }
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 15,
//       child: text,
//     );
//   }
//
//   Widget leftTitles(double value, TitleMeta meta) {
//     const style = TextStyle(
//         color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12);
//     String text;
//     if (value == 0) {
//       text = '300';
//     } else if (value == 2) {
//       text = '400';
//     } else if (value == 3) {
//       text = '500';
//     } else if (value == 4) {
//       text = '600';
//     } else if (value == 5) {
//       text = '700';
//     } else {
//       return Container();
//     }
//     return SideTitleWidget(
//         space: 4,
//         axisSide: meta.axisSide,
//         child: Text(
//           text,
//           style: style,
//         ));
//   }
// }