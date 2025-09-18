import 'package:flutter/material.dart';

import '../../../widgets/detailstext1.dart';



class AuthTab extends StatelessWidget {
  final String image,text;
  const AuthTab({
    super.key, required this.image, required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 6),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Image.asset(
              image,
              scale: 1.5,
            ),
            const SizedBox(
              width: 10,
            ),
            Text1(
              text1:text,
              size: 16,
            )
          ],
        ),
      ),
    );
  }
}
