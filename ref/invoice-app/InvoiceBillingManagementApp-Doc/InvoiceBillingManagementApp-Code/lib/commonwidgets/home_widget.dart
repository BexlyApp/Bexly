// import 'package:flutter/material.dart';
//
// import '../Constants/colors.dart';
// import '../views/settings/Views/notifications.dart';
// import '../widgets/detailstext1.dart';
//
// class HomeWidgte extends StatelessWidget {
//   const HomeWidgte({
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Builder(builder: (context) {
//           return InkWell(
//             onTap: () {
//               Scaffold.of(context).openDrawer();
//             },
//             child: const Icon(
//               Icons.menu_outlined,
//               color: Colors.white,
//             ),
//           );
//         }),
//         const Text1(
//           text1: 'TIMESHEET',
//           size: 25,
//           color: Colors.white,
//
//         ),
//         GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (context) =>
//                   const GroceryNotifications()),
//             );
//           },
//           child: Container(
//             height: 42,
//             width: 42,
//             padding: const EdgeInsets.all(5),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Icon(
//               Icons.notification_important_rounded,
//               color: AppColors.buttonColor,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
