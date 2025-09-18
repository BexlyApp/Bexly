import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'detailstext1.dart';

class TabContainer extends StatelessWidget {
  final String text;
  final String imagePath;
  final VoidCallback onTap;

  const TabContainer({super.key,
    required this.text,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.tabColor,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Container(
              color: Colors.white,
              height: 45,
              width: 1,

            ),
            const SizedBox(width: 10,),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,

                ),
                  height: 30,
                  width: 35,
                  child: Image.asset(imagePath)),
            ),
            const SizedBox(width: 10),
            Text1(text1: text),

            const Spacer(),
            const Icon(Icons.navigate_next, color: Colors.white70, size: 30),
            const SizedBox(width: 10,),
            Container(
              color: Colors.white,
              height: 45,
              width: 1,

            ),
          ],
        ),
      ),
    );
  }
}
