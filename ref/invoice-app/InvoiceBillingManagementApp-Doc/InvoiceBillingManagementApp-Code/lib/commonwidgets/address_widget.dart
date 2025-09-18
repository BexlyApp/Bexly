import 'package:flutter/material.dart';

import '../widgets/detailstext1.dart';


class AddressWidget extends StatelessWidget {
  const AddressWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'images/MapPin.png',
          color: Colors.white,
        ),
        const SizedBox(
          width: 3,
        ),
        const Text1(
          text1: 'New York ,USA',
          size: 15,
          color: Colors.white,
        ),
        const SizedBox(
          width: 4,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Image.asset(
            'images/arrow.png',
            width: 12,
            color: Colors.white,
          ),
        ),


      ],
    );
  }
}
