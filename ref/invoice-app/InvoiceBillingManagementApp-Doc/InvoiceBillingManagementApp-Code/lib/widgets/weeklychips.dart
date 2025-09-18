import 'package:flutter/material.dart';

import '../../../../../../widgets/chiptext.dart';
import '../constants/colors.dart';

class WeaklyChips extends StatelessWidget {
  const WeaklyChips({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Chip(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            backgroundColor: AppColors.tabColor,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.yellow), // Change the color here
              borderRadius: BorderRadius.circular(10), // Adjust border radius if needed
            ),
            label: const ChipText(text1: 'Week',)
        ),
        const SizedBox(width: 18,),
        const Chip(
            padding: EdgeInsets.symmetric(horizontal: 30),

            backgroundColor: AppColors.tabColor,
            label: ChipText(text1: 'Month',)),
        const SizedBox(width: 18,),

        const Chip(
            padding: EdgeInsets.symmetric(horizontal: 25),
            backgroundColor: AppColors.tabColor,

            label: ChipText(text1: 'Year',)
        ),


      ],
    );
  }
}


