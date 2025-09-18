// import 'package:flutter/material.dart';
//
// import '../../../Constants/colors.dart';
//
// class SearchWidget extends StatelessWidget {
//   const SearchWidget({
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextFormField(
//             decoration: InputDecoration(
//               contentPadding: const EdgeInsets.symmetric(
//                   vertical: 1, horizontal: 10),
//               hintText: 'Search',
//               prefixIcon: const Icon(
//                 Icons.search,
//                 color: AppColors.buttonColor,
//                 size: 30,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: const BorderSide(color: Colors.white),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: const BorderSide(
//                     color: AppColors
//                         .buttonColor), // Red border when focused
//               ),
//               hintStyle: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w400,
//               ),
//               filled: true,
//               fillColor: Colors.white,
//             ),
//           ),
//         ),
//
//         const SizedBox(
//           width: 10,
//         ),
//         GestureDetector(
//           onTap: (){
//             // Navigator.push(
//             //   context,
//             //   MaterialPageRoute(builder: (context) =>  const SearchPets()),
//             // );
//           },
//           child: Container(
//             height: 46,
//             width: 46,
//             padding: const EdgeInsets.all(5),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Image.asset('images/filter.png',color: AppColors.buttonColor,),
//           ),
//         ),
//
//
//     ],
//     );
//   }
// }
