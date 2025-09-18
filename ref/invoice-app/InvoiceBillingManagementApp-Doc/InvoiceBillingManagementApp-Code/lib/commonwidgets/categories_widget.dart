import 'package:flutter/material.dart';
import 'categories_column.dart';

class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CategoriesColumn(icon: Icons.build, text: 'Tools'),
          CategoriesColumn(icon: Icons.car_repair, text: 'Car Repair'),
          CategoriesColumn(
              icon: Icons.battery_charging_full, text: 'Batteries'),
          CategoriesColumn(icon: Icons.tire_repair, text: 'Tires'),
          CategoriesColumn(icon: Icons.oil_barrel, text: 'Oil'),
          CategoriesColumn(
              icon: Icons.miscellaneous_services, text: 'Services'),
          CategoriesColumn(icon: Icons.engineering, text: 'Engine Parts'),
        ],
      ),
    );
  }
}
