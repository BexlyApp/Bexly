import 'dart:async';

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import 'package:bexly/core/config/number_format_config.dart';

class CustomKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final int? maxLength;
  const CustomKeyboard({
    super.key,
    this.maxLength,
    required this.controller,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  Timer? _backspaceHoldTimer;

  NumberFormat get _numberFormat => NumberFormat("#,##0.###", NumberFormatConfig.locale);
  String get _thousandSep => NumberFormatConfig.thousandSeparator;
  String get _decimalSep => NumberFormatConfig.decimalSeparator;

  List<String> get keys => [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    _decimalSep, '0', '{backspace}',
  ];

  List<String> get quickAmount {
    final t = _thousandSep;
    return [
      '10${t}000',
      '50${t}000',
      '100${t}000',
      '500${t}000',
      '1${t}000${t}000',
    ];
  }

  // Method to format input with thousand separators and custom symbols
  void _formatAndSetText(String input) {
    // Remove all separators to get the raw number
    String sanitizedText = input
        .replaceAll(_thousandSep, '')
        .replaceAll(_decimalSep, '.');

    // Limit input to a maximum of 14 characters
    if (sanitizedText.length > 15) {
      sanitizedText = sanitizedText.substring(0, 14);
    }

    double? value = double.tryParse(sanitizedText);

    if (value != null) {
      // Format the number using locale-aware formatter
      String formattedText = _numberFormat.format(value);

      widget.controller.text = formattedText;
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    }
  }

  // Called on each key press to update the value
  void _onKeyPressed(String key) {
    Vibration.vibrate(duration: 50);
    // Remove thousand separators for processing
    String currentText = widget.controller.text.replaceAll(_thousandSep, '');

    setState(() {
      if (key == '{backspace}') {
        if (currentText.isNotEmpty) {
          currentText = currentText.substring(0, currentText.length - 1);
          if (currentText.isEmpty) {
            currentText = "0"; // Set to "0" if no characters are left
          }
          debugPrint('$key: $currentText');
          _formatAndSetText(currentText);
        }
      } else if (key == _decimalSep && currentText.contains(_decimalSep)) {
        // Prevent adding another decimal separator
        return;
      } else {
        currentText += key;
        _formatAndSetText(currentText);
      }
    });
  }

  void _onQuickAmountPressed(String input) {
    Vibration.vibrate(duration: 50);
    _formatAndSetText(input);
  }

  void _startBackspaceHold(String key) {
    if (key != '{backspace}') return;

    _backspaceHoldTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        _onKeyPressed('{backspace}');
      },
    );
  }

  void _stopBackspaceHold(String key) {
    if (key != '{backspace}') return;

    _backspaceHoldTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: quickAmount.length,
            itemBuilder: (context, index) => InkWell(
              onTap: () => _onQuickAmountPressed(quickAmount[index]),
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade500),
                ),
                child: Center(child: Text(quickAmount[index])),
              ),
            ),
            separatorBuilder: (context, index) => const Gap(10),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () => _onKeyPressed(keys[index]),
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: GestureDetector(
                onLongPressStart: (details) => _startBackspaceHold(keys[index]),
                onLongPressEnd: (details) => _stopBackspaceHold(keys[index]),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.grey.shade500),
                  ),
                  child: Center(
                    child: keys[index] == '{backspace}'
                        ? const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft04,
                            size: 30,
                          )
                        : Text(
                            keys[index],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
