import 'package:flutter/material.dart';

import '../widgets/detailstext1.dart';

class CategoriesColumn extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor; // Added dynamic color for the icon

  const CategoriesColumn({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor = const Color(0xFF444B5D), // Default modern icon color (Slate Grey)
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: Colors.white, // White background for the container
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB((0.2 * 255).toInt(), 128, 128, 128),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // Subtle shadow for elevation
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 30,
                color: iconColor, // Use the provided or default modern color
              ),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text1(
            text1: text,
            size: 13,
            color: Colors.grey.shade700, // Slightly dark text for a modern look
          ),
        ],
      ),
    );
  }
}
