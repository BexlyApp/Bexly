import 'package:flutter/material.dart';

class ChipText extends StatelessWidget {
  final String text1;
  const ChipText({
    super.key, required this.text1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text1,style: const TextStyle(color: Colors.white,fontSize: 12),);
  }
}