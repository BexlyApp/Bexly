import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'detailstext1.dart';

class CustomAppBar extends StatelessWidget {
  final String text, text1;
  final Color backgroundColor;


  const CustomAppBar({super.key,required this.text,
    required this.text1,
    this.backgroundColor = AppColors.buttonColor,});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), // Decreased vertical padding for reduced height
      decoration: BoxDecoration(
        color: backgroundColor, // Use the background color passed or default to purpleAccent
        borderRadius: BorderRadius.circular(8), // Added border radius for rounded corners
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB((0.2 * 255).toInt(), 128, 128, 128),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color:AppColors.buttonColor,size: 20,),
                onPressed: () {
                  Navigator.of(context).pop(); // Back navigation
                },
              ),
            ),


          ),
          Text1(
            text1: text,
            color: Colors.white,
            size: 17,
          ),
          Text1(
            text1: text1,
            size: 16,
            color: Colors.grey, // Optional smaller text
          ),
        ],
      ),
    );
  }
}
