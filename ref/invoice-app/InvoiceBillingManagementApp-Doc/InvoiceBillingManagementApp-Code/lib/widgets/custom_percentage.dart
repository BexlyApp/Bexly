// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:percent_indicator/circular_percent_indicator.dart';
//
// import '../Constants/colors.dart';
// import 'detailstext1.dart';
// import 'detailstext2.dart';
//
// class CustomPercentage extends StatelessWidget {
//   final String text1;
//   final String text2;
//   final double radius;
//   final Color color;
//   final double width;
//
//   const CustomPercentage({
//     super.key,
//     required this.text1,
//     required this.text2,
//     this.radius = 37.0,
//     this.color=AppColors.buttonColor,
//     this.width=3.0,
//     // Default radius value
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircularPercentIndicator(
//           radius: radius,
//           lineWidth: width,
//           animation: true,
//           percent: 0.8,
//           center: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//              Text1(text1: text1,size: 30,),
//               const SizedBox(height: 7,),
//               Text2(text2: text2,)
//             ],
//           ),
//           circularStrokeCap: CircularStrokeCap.round,
//           progressColor: color,
//         ),
//
//       ],
//     );
//   }
// }
