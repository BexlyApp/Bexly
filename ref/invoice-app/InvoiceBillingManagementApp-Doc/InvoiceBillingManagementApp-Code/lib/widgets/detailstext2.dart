import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

class Text2 extends StatelessWidget {
  final String text2;
  final Color color;
  const Text2({
    super.key, required this.text2,
      this.color=AppColors.text2Color
  });

  @override
  Widget build(BuildContext context) {
    return Text(text2,style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color

    ),
    );
  }
}