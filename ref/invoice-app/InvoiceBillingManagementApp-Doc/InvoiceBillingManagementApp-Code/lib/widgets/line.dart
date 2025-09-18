import 'package:flutter/material.dart';

class Line extends StatelessWidget {
  const Line({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal:2),
      decoration: const BoxDecoration(
        color: Colors.white,

      ),
      height: 2,
      width: 5,

    );
  }
}
