import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/date_picker/date_time_picker_dialog.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/utils/logger.dart';

class CustomDatePicker {
  static final _datePickerConfig = CalendarDatePicker2WithActionButtonsConfig(
    calendarType: CalendarDatePicker2Type.single,
    lastDate: DateTime.now(),
    dayTextStyle: AppTextStyles.body4,
    selectedDayTextStyle: AppTextStyles.body4.copyWith(color: AppColors.light),
    monthTextStyle: AppTextStyles.body4,
    selectedMonthTextStyle: AppTextStyles.body4.copyWith(
      color: AppColors.light,
    ),
    yearTextStyle: AppTextStyles.body4,
    selectedYearTextStyle: AppTextStyles.body4.copyWith(color: AppColors.light),
    weekdayLabelTextStyle: AppTextStyles.body4,
    todayTextStyle: AppTextStyles.body4.copyWith(color: AppColors.primary),
  );

  static Future<DateTime?> selectSingleDate(
    BuildContext context, {
    required String title,
    DateTime? selectedDate,
    ValueChanged<DateTime>? onDateTimeChanged,
    ValueChanged<DateTime>? onDateSelected,
  }) async {
    return await context.openBottomSheet<DateTime?>(
      child: DateTimePickerDialog(
        title: title,
        initialdate: selectedDate,
        onDateSelected: onDateSelected,
        onDateTimeChanged: onDateTimeChanged,
      ),
    );
  }

  static Future<List<DateTime?>?> selectDateRange(
    BuildContext context,
    List<DateTime?> selectedDateRange, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    var dates = await context.openBottomSheet<List<DateTime?>>(
      child: _DateRangePickerSheet(
        config: _datePickerConfig.copyWith(
          calendarType: CalendarDatePicker2Type.range,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
        initialValue: selectedDateRange,
      ),
    );

    if (dates != null) {
      final duration = Duration(
        hours: DateTime.now().hour,
        minutes: DateTime.now().minute,
        seconds: DateTime.now().second,
      );

      DateTime? selectedStartDate;
      DateTime? selectedEndDate;

      if (dates.first != null) {
        selectedStartDate = dates.first!.add(duration);
      }

      if (dates.last != null) {
        selectedEndDate = dates.last!.add(duration);
      }

      Log.d([selectedStartDate, selectedEndDate], label: 'selected date range');
      return [selectedStartDate, selectedEndDate];
    }

    return null;
  }
}

/// Bottom sheet wrapper for CalendarDatePicker2 in range mode
class _DateRangePickerSheet extends StatefulWidget {
  final CalendarDatePicker2WithActionButtonsConfig config;
  final List<DateTime?> initialValue;

  const _DateRangePickerSheet({
    required this.config,
    required this.initialValue,
  });

  @override
  State<_DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<_DateRangePickerSheet> {
  late List<DateTime?> _selectedDates;

  @override
  void initState() {
    super.initState();
    _selectedDates = List.from(widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: 'Select Date Range',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalendarDatePicker2(
            config: widget.config,
            value: _selectedDates,
            onValueChanged: (dates) {
              setState(() => _selectedDates = dates);
            },
          ),
          PrimaryButton(
            label: 'Confirm',
            onPressed: () => context.pop(_selectedDates),
          ),
        ],
      ),
    );
  }
}
