import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
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

      // Replace commas (thousand separator) with empty for parsing
      sanitizedValue = sanitizedValue.replaceAll(',', '');

      // Split into integer and decimal parts
      List<String> parts = sanitizedValue.split('.');
      String integerPart = parts[0];
      String decimalPart = parts.length == 2 ? parts[1] : '';

      // Ensure the decimal part is no more than 2 digits
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }

      // Format the integer part with thousand separator
      final formatter = NumberFormat("#,##0", "en_US");
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
        formattedValue = "$defaultCurrency $negativePrefix$formattedInteger.$decimalPart";
      } else if (parts.length == 2 && sanitizedValue.endsWith('.')) {
        // User typed a dot but no decimal digits yet
        formattedValue = "$defaultCurrency $negativePrefix$formattedInteger.";
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
        final rawValue = isNegative && allowNegative ? '-$sanitizedValue' : sanitizedValue;
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
          allowNegative ? RegExp(r'[\d.\-]') : RegExp(r'[\d.]'),
        ),
        if (allowNegative) LeadingMinusInputFormatter(), // Only allow - at start
        SingleDotInputFormatter(),
        DecimalInputFormatter(),
        LengthLimitingTextInputFormatter(12),
      ],
      onChanged: handleTextChanged,
      isRequired: isRequired,
      autofocus: autofocus,
      enabled: enabled,
    );
  }
}

class SingleDotInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if the new input contains more than one dot
    if (newValue.text.split('.').length > 2) {
      return oldValue; // Reject the new input
    }
    return newValue;
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow only numbers, a single dot, and two digits after the dot
    // Also allow optional leading minus sign
    final regex = RegExp(r'^-?\d*\.?\d{0,2}$');

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
