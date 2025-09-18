import 'package:flutter/material.dart';

import '../constants/colors.dart';

class Text11 extends StatelessWidget {
  final String text2;
  final Color color;
  const Text11({
    super.key, required this.text2,
    this.color=AppColors.text1Color
  });

  @override
  Widget build(BuildContext context) {
    return Text(text2,style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color

    ),);
  }
}