import 'package:flutter/material.dart';

import '../constants/colors.dart';


class CustomButton extends StatelessWidget {
  final String text;
  final Function() onTap;
  final Color color;
  final double height;
  const CustomButton({
    super.key, required this.text, required this.onTap,
    this.color = AppColors.buttonColor,
    this.height=38

  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:onTap ,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 7,),
        width: double.infinity,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(child: Text(text,style: const TextStyle(
            color: AppColors.buttonTextColor,
            fontSize: 18
        ),)),


      ),
    );
  }
}
