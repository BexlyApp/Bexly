import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/services/keyboard_service/virtual_keyboard_service.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';

class CurrencyPickerField extends HookConsumerWidget {
  final Currency? defaultCurrency;
  final bool enabled;
  const CurrencyPickerField({
    super.key,
    this.defaultCurrency,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, ref) {
    Currency currency = ref.watch(currencyProvider);
    final currencyController = useTextEditingController();

    useEffect(() {
      if (defaultCurrency != null) {
        currencyController.text = defaultCurrency!.symbolWithCountry;
      }
      return null;
    }, [defaultCurrency]);

    return Stack(
      children: [
        CustomTextField(
          context: context,
          controller: currencyController,
          label: 'Currency',
          hint: 'USD',
          prefixIcon: HugeIcons.strokeRoundedFlag01,
          readOnly: true,
          enabled: enabled,
          onTap: enabled
              ? () async {
                  KeyboardService.closeKeyboard();
                  final Currency? selectedCurrency = await context.push(
                    Routes.currencyListTile,
                  );
                  if (selectedCurrency != null) {
                    ref.read(currencyProvider.notifier).state = selectedCurrency;
                    currencyController.text = selectedCurrency.symbolWithCountry;
                  }
                }
              : null,
        ),
        Positioned(
          right: 10,
          bottom: 16,
          top: 16,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radius4),
              border: Border.all(color: AppColors.neutralAlpha25),
            ),
            child: currency.country.isEmpty
                ? Container(
                    width: 40,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.radius4),
                      color: AppColors.neutral100,
                    ),
                  )
                : CountryFlag.fromCountryCode(
                    currency.countryCode,
                    theme: const ImageTheme(
                      width: 40,
                      height: 32,
                      shape: RoundedRectangle(AppRadius.radius4),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
