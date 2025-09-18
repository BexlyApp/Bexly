import 'package:flutter/material.dart';

class RangeSliderExample extends StatefulWidget {
  const RangeSliderExample({super.key});

  @override
  RangeSliderExampleState createState() => RangeSliderExampleState();
}

class RangeSliderExampleState extends State<RangeSliderExample> {
  RangeValues _values = const RangeValues(0.0, 100.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horizontal Range Slider Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: -90 * 3.14 / 180, // Rotate the slider 90 degrees counter-clockwise
              child: RangeSlider(
                values: _values,
                min: 0.0,
                max: 100.0,
                onChanged: (RangeValues values) {
                  setState(() {
                    _values = values;
                  });
                },
                activeColor: Colors.blue, // Color of the selected range
                inactiveColor: Colors.grey, // Color of the inactive range
                divisions: 10, // Number of divisions between min and max
                labels: RangeLabels(
                  _values.start.round().toString(),
                  _values.end.round().toString(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Selected Range: ${_values.start.round()} - ${_values.end.round()}',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}


