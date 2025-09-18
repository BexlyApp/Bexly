import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';

class Text1 extends StatelessWidget {
  final String text1;
  final Color color;
  final double size;
  const Text1({
    super.key,
    required this.text1,
    this.color = AppColors.text1Color,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text1,
      style: GoogleFonts.roboto( // You can change 'Roboto' to any other Google Font
        textStyle: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: size,
        ),
      ),
    );
  }
}
