import 'package:flutter/material.dart';

import '../constants/colors.dart';



class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final Function() onTap;
  const CustomOutlinedButton({
    super.key, required this.text, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:onTap ,
      child: Container(
        height: 38,
        margin: const EdgeInsets.symmetric(vertical: 7,),
        width: double.infinity,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.buttonColor,width: 1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(text,style: const TextStyle(
              color:AppColors.buttonColor,fontSize: 18
          ),),
        ),


      ),
    );
  }
}
