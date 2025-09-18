import 'package:flutter/material.dart';

class ScrollableDatePicker extends StatefulWidget {
  const ScrollableDatePicker({super.key});

  @override
  ScrollableDatePickerState createState() => ScrollableDatePickerState();
}

class ScrollableDatePickerState extends State<ScrollableDatePicker> {
  late int selectedMonth;
  late int selectedDay;
  late int selectedYear;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController dayController;
  late FixedExtentScrollController yearController;

  @override
  void initState() {
    super.initState();
    // Initialize selected date with current date
    DateTime now = DateTime.now();
    selectedMonth = now.month;
    selectedDay = now.day;
    selectedYear = now.year;

    // Initialize scroll controllers with initial offset to center the selected item
    monthController = FixedExtentScrollController(initialItem: selectedMonth - 1);
    dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
    yearController = FixedExtentScrollController(initialItem: selectedYear - 1900);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ListWheelScrollView(
                  diameterRatio: 1.5,
                  itemExtent: 60,
                  physics: const FixedExtentScrollPhysics(),
                  controller: monthController,
                  children: [
                    for (int month = 1; month <= 12; month++)
                      _buildMonthItem(month),
                  ],
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedMonth = index + 1; // Update selected month
                    });
                  },
                ),
              ),
              Expanded(
                child: ListWheelScrollView(
                  diameterRatio: 1.5,
                  itemExtent: 60,
                  physics: const FixedExtentScrollPhysics(),
                  controller: dayController,
                  children: [
                    for (int day = 1; day <= 31; day++)
                      _buildDayItem(day),
                  ],
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedDay = index + 1; // Update selected day
                    });
                  },
                ),
              ),
              Expanded(
                child: ListWheelScrollView(
                  diameterRatio: 1.5,
                  itemExtent: 60,
                  physics: const FixedExtentScrollPhysics(),
                  controller: yearController,
                  children: [
                    for (int year = 1900; year <= DateTime.now().year; year++)
                      _buildYearItem(year),
                  ],
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedYear = index + 1900; // Update selected year
                    });
                  },
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }

  // Helper function to get month name from its number
  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }

  // Helper function to build month item
  Widget _buildMonthItem(int month) {
    bool isSelected = month == selectedMonth;
    return Column(
      children: [
        Text(
          _getMonthName(month),
          style: TextStyle(
            fontSize:isSelected ? 20 : 15,
            color: isSelected ? Colors.white : Colors.white70, // Change color based on selection
          ),
        ),
        const Divider(
          color: Colors.white,
          thickness: 1,
          height: 10,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }

  // Helper function to build day item
  Widget _buildDayItem(int day) {
    bool isSelected = day == selectedDay;
    return Column(
      children: [
        Text(
          '$day',
          style: TextStyle(
            fontSize:isSelected ? 20 : 15,
            color: isSelected ? Colors.white : Colors.white70, // Change color based on selection
          ),
        ),
        const Divider(
          color: Colors.white,
          thickness: 1,
          height: 10,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }

  // Helper function to build year item
  Widget _buildYearItem(int year) {
    bool isSelected = year == selectedYear;
    return Column(
      children: [
        Text(
          '$year',
          style: TextStyle(
            fontSize:isSelected ? 20 : 15,
            color: isSelected ? Colors.white : Colors.white70, // Change color based on selection
          ),
        ),
        const Divider(
          color: Colors.white,
          thickness: 1,
          height: 10,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }
}
