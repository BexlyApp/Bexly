import 'package:flutter/cupertino.dart';

class HorizontalProgress extends StatelessWidget {
  final Color color1,color2;
  final double width;
  const HorizontalProgress({
    super.key, required this.color1, required this.color2,
    this.width=100
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      width: double.infinity,
      decoration: BoxDecoration(
          color: color1,
          borderRadius: BorderRadius.circular(32)),
      child: Row(
        children: [
          Container(
            height: 8,
            width: width,
            decoration: BoxDecoration(
                color: color2,
                borderRadius: BorderRadius.circular(32)),
          )
        ],
      ),
    );
  }
}
