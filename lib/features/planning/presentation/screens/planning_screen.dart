import "package:flutter/material.dart";

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Planning - Coming Soon",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
