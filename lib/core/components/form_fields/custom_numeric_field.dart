import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/config/number_format_config.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/data/sources/currency_local_source.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

class CustomNumericField extends ConsumerWidget {
  final String label;
  final String? defaultCurreny;
  final TextEditingController? controller;
  final String? hint;
  final Color? hintColor;
  final Color? background;
  final dynamic icon; // Changed to dynamic for hugeicons v1.x compatibility
  final dynamic suffixIcon; // Changed to dynamic for hugeicons v1.x compatibility
  final bool useSelectedCurrency;
  final bool appendCurrencySymbolToHint;
  final bool isRequired;
  final bool autofocus;
  final bool enabled;
  final bool allowNegative; // Allow negative numbers (for credit card debt)
  final ValueChanged<String>? onChanged;

  const CustomNumericField({
    super.key,
    required this.label,
    this.defaultCurreny,
    this.controller,
    this.hint,
    this.hintColor,
    this.background,
    this.icon,
    this.suffixIcon,
    this.useSelectedCurrency = false,
    this.appendCurrencySymbolToHint = false,
    this.isRequired = false,
    this.autofocus = false,
    this.enabled = true,
    this.allowNegative = false, // Default to not allowing negative
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, ref) {
    Currency currency = ref.watch(currencyProvider);
    String defaultCurrency =
        defaultCurreny ??
        ref.read(activeWalletProvider).value?.currencyByIsoCode(ref).symbol ??
        CurrencyLocalDataSource.dummy.symbol;

    if (useSelectedCurrency) {
      defaultCurrency = currency.symbol;
    }

    String hint =
        '${appendCurrencySymbolToHint ? defaultCurrency : ''} ${this.hint ?? ''}'
            .trim();

    // Get locale-aware separators
    final thousandSep = NumberFormatConfig.thousandSeparator;
    final decimalSep = NumberFormatConfig.decimalSeparator;
    final locale = NumberFormatConfig.locale;

    var lastFormattedValue = '';

    void handleTextChanged(String value) {
      if (value == lastFormattedValue) return;

      // Remove the currency prefix and sanitize input
      String sanitizedValue = value
          .replaceAll(defaultCurrency, '')
          .replaceAll(' ', '')
          .trim();

      // Check for negative sign
      bool isNegative = sanitizedValue.startsWith('-');
      if (isNegative) {
        sanitizedValue = sanitizedValue.substring(1); // Remove - for processing
      }

      // Remove thousand separators for parsing
      sanitizedValue = sanitizedValue.replaceAll(thousandSep, '');

      // Normalize decimal separator to '.' for parsing
      if (decimalSep != '.') {
        sanitizedValue = sanitizedValue.replaceAll(decimalSep, '.');
      }

      // Split into integer and decimal parts
      List<String> parts = sanitizedValue.split('.');
      String integerPart = parts[0];
      String decimalPart = parts.length == 2 ? parts[1] : '';

      // Ensure the decimal part is no more than 2 digits
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }

      // Format the integer part with locale-aware thousand separator
      final formatter = NumberFormat("#,##0", locale);
      String formattedInteger = integerPart.isNotEmpty
          ? formatter.format(int.parse(integerPart))
          : '';

      // Add negative sign back if needed
      String negativePrefix = isNegative && allowNegative ? '-' : '';

      // Combine integer and decimal parts
      // Only add decimal point if user explicitly typed it or there are decimal digits
      String formattedValue;
      if (decimalPart.isNotEmpty) {
        // User has decimal digits
        formattedValue = "$defaultCurrency $negativePrefix$formattedInteger$decimalSep$decimalPart";
      } else if (parts.length == 2 && sanitizedValue.endsWith('.')) {
        // User typed a decimal separator but no decimal digits yet
        formattedValue = "$defaultCurrency $negativePrefix$formattedInteger$decimalSep";
      } else {
        // No decimal point
        formattedValue = "$defaultCurrency $negativePrefix$formattedInteger";
      }

      if (formattedInteger.isEmpty) {
        formattedValue = negativePrefix.isNotEmpty ? '$defaultCurrency $negativePrefix' : '';
      }

      // Avoid infinite loop
      if (formattedValue != lastFormattedValue) {
        lastFormattedValue = formattedValue;

        // Update the controller with the formatted value
        controller?.value = TextEditingValue(
          text: formattedValue,
          selection: TextSelection.collapsed(offset: formattedValue.length),
        );

        // Notify parent widget with the raw numeric value (including negative sign)
        // Raw value uses '.' as decimal separator for consistent parsing
        final rawNumeric = decimalPart.isNotEmpty ? '$integerPart.$decimalPart' : integerPart;
        final rawValue = isNegative && allowNegative ? '-$rawNumeric' : rawNumeric;
        onChanged?.call(rawValue);
      }
    }

    // Use currency symbol as prefix icon when useSelectedCurrency is true
    final effectiveIcon = useSelectedCurrency
        ? Text(
            defaultCurrency,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          )
        : icon;

    // Allow locale-appropriate decimal separator in input
    final decimalPattern = decimalSep == ',' ? r'[\d,\-]' : r'[\d.\-]';
    final nonNegativePattern = decimalSep == ',' ? r'[\d,]' : r'[\d.]';

    return CustomTextField(
      controller: controller,
      label: label,
      prefixIcon: effectiveIcon,
      hint: hint,
      textInputAction: TextInputAction.done,
      suffixIcon: suffixIcon,
      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: allowNegative),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowNegative ? RegExp(decimalPattern) : RegExp(nonNegativePattern),
        ),
        if (allowNegative) LeadingMinusInputFormatter(), // Only allow - at start
        SingleSeparatorInputFormatter(decimalSep),
        DecimalInputFormatter(decimalSep),
        LengthLimitingTextInputFormatter(12),
      ],
      onChanged: handleTextChanged,
      isRequired: isRequired,
      autofocus: autofocus,
      enabled: enabled,
    );
  }
}

class SingleSeparatorInputFormatter extends TextInputFormatter {
  final String decimalSeparator;
  const SingleSeparatorInputFormatter(this.decimalSeparator);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if the new input contains more than one decimal separator
    if (newValue.text.split(decimalSeparator).length > 2) {
      return oldValue; // Reject the new input
    }
    return newValue;
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  final String decimalSeparator;
  const DecimalInputFormatter(this.decimalSeparator);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final escapedSep = RegExp.escape(decimalSeparator);

    // Allow only numbers, a single decimal separator, and two digits after it
    // Also allow optional leading minus sign
    final regex = RegExp('^-?\\d*$escapedSep?\\d{0,2}\$');

    if (!regex.hasMatch(text)) {
      return oldValue; // Reject invalid input
    }

    return newValue;
  }
}

class LeadingMinusInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Count minus signs in the text
    final minusCount = text.split('').where((c) => c == '-').length;

    // Reject if more than one minus, or minus is not at the start
    if (minusCount > 1 || (minusCount == 1 && !text.startsWith('-'))) {
      return oldValue;
    }

    return newValue;
  }
}
