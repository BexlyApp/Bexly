import 'package:flutter/material.dart';

import '../../Widgets/customapp_bar.dart';
import '../../Widgets/detailstext2.dart';
import '../../constants/colors.dart';
import '../../widgets/custombtn.dart';
import '../../widgets/detailstext1.dart';


class WriteReviews extends StatelessWidget {
  const WriteReviews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomAppBar(text: 'Write A Review', text1: ''),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textFormFieldBorderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'images/polycrystalline-panel.jpg',
                          width: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text1(text1: 'solar'),
                            const SizedBox(height: 6),
                            const Text2(
                              text2: 'Share your experience with this product.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add Photo or Video',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textFormFieldBorderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload),
                      SizedBox(height: 6),
                      Text2(text2: 'Click here to upload'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Write Your Review',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(3.0),
                  decoration: BoxDecoration(
                    color: AppColors.textFormFieldBorderColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextFormField(
                    style: const TextStyle(fontSize: 14),
                    maxLines: 8,
                    decoration: const InputDecoration(
                      fillColor: AppColors.bgColor,
                      filled: true,
                      hintText: 'Would you like to write anything about this product?',
                      hintStyle: TextStyle(
                        fontSize: 14,
                      ),
                      border: InputBorder.none, // Remove default border
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: CustomButton(
          text: 'Submit Review',
          onTap: () {
            // Handle review submission logic here
          },
        ),
      ),
    );
  }
}