// import 'package:flutter/material.dart';
// import '../Constants/colors.dart';
// import '../views/home/details.dart';
//
// class ProductCard extends StatefulWidget {
//   final String imagePath;
//   final String name;
//   final String price;
//   final VoidCallback? onTap;
//   final bool isFavorited;
//   final VoidCallback? onFavoriteTap;
//   final VoidCallback? onAddToCartTap;
//
//   // Additional Data (Without Changing Model)
//   final String description;
//   final double rating;
//   final bool stockAvailability;
//   final double discountPercentage;
//
//   const ProductCard({
//     super.key,
//     required this.imagePath,
//     required this.name,
//     required this.price,
//     this.onTap,
//     this.isFavorited = false,
//     this.onFavoriteTap,
//     this.onAddToCartTap,
//     this.description = '',
//     this.rating = 0.0,
//     this.stockAvailability = true,
//     this.discountPercentage = 0.0,
//   });
//
//   @override
//   State<ProductCard> createState() => _ProductCardState();
// }
//
// class _ProductCardState extends State<ProductCard> {
//   late bool _isFavorited;
//
//   @override
//   void initState() {
//     super.initState();
//     _isFavorited = widget.isFavorited;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//             context, MaterialPageRoute(builder: (_) => SolarPanelDetailsScreen()));
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Color.fromARGB((0.5 * 255).toInt(), 33, 150, 243),
//               spreadRadius: 2,
//               blurRadius: 7,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(child: _buildImageSection(context)),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.name,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//
//                   // **Rating Section**
//                   Row(
//                     children: [
//                       Icon(Icons.star, color: Colors.amber, size: 16),
//                       const SizedBox(width: 4),
//                       Text(
//                         widget.rating.toStringAsFixed(1),
//                         style: const TextStyle(
//                             fontSize: 14, fontWeight: FontWeight.w500),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//
//                   // **Stock Availability**
//                   Text(
//                     widget.stockAvailability ? "In Stock" : "Out of Stock",
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: widget.stockAvailability
//                           ? Colors.green
//                           : Colors.red,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//
//                   // **Price & Discount**
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: [
//                           if (widget.discountPercentage > 0)
//                             Text(
//                               '\$${(double.parse(widget.price) - (double.parse(widget.price) * widget.discountPercentage / 100)).toStringAsFixed(2)}',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: AppColors.buttonColor,
//                               ),
//                             ),
//                           if (widget.discountPercentage > 0)
//                             const SizedBox(width: 6),
//                           Text(
//                             '\$${widget.price}',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: widget.discountPercentage > 0
//                                   ? Colors.grey
//                                   : AppColors.buttonColor,
//                               decoration: widget.discountPercentage > 0
//                                   ? TextDecoration.lineThrough
//                                   : TextDecoration.none,
//                             ),
//                           ),
//                         ],
//                       ),
//                       GestureDetector(
//                         onTap: widget.onAddToCartTap,
//                         child: Container(
//                           padding: const EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: AppColors.buttonColor,
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: const Icon(Icons.add, size: 16, color: Colors.white),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImageSection(BuildContext context) {
//     return Stack(
//       children: [
//         ClipRRect(
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(12),
//             topRight: Radius.circular(12),
//           ),
//           child: Image.asset(
//             widget.imagePath,
//             width: double.infinity, // Full width of parent container
//             height: 120, // Fixed height to maintain consistency
//             fit: BoxFit.cover, // Ensures proper scaling
//           ),
//         ),
//         Positioned(
//           top: 8,
//           right: 8,
//           child: GestureDetector(
//             onTap: () {
//               setState(() {
//                 _isFavorited = !_isFavorited;
//               });
//               if (widget.onFavoriteTap != null) {
//                 widget.onFavoriteTap!();
//               }
//             },
//             child: CircleAvatar(
//               radius: 14,
//               backgroundColor: AppColors.buttonColor,
//               child: Icon(
//                 _isFavorited ? Icons.favorite : Icons.favorite_border,
//                 size: 18,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
