

import 'package:flutter/cupertino.dart';

import 'detailstext1.dart';
import 'detailstext2.dart';

class ProductivityTab extends StatelessWidget {
  final String text1,text2;
  final Color color;
  const ProductivityTab({
    super.key, required this.text1, required this.text2, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height:10,
          width: 10,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle

          ),
        ),
        const SizedBox(width: 10,),
        Text2(text2: text1),
        const Spacer(),
        Text1(text1: text2)


      ],


    );
  }
}
