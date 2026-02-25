part of '../screens/settings_screen.dart';

class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use local auth state (with offline support)
    final auth = ref.watch(authStateProvider);
    final displayName = auth.name;
    final profilePicture = auth.profilePicture;

    // Use base currency for text display
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final currencies = ref.watch(currenciesStaticProvider);
    final currencyObj = currencies.fromIsoCode(baseCurrency);

    // Use language for flag display
    final currentLanguage = ref.watch(languageProvider);
    final countryCode = _getCountryCodeFromLanguage(currentLanguage.code);

    return Row(
      children: [
        _ProfileAvatar(profilePicture: profilePicture, colorScheme: colorScheme),
        const Gap(AppSpacing.spacing12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName, style: AppTextStyles.body1),
            Text(
              'The Clever Squirrel', // This text color will adapt via DefaultTextStyle or explicit style
              style: AppTextStyles
                  .body2, // Use onSurfaceVariant for secondary text
            ),
            const Gap(AppSpacing.spacing8),
            CustomCurrencyChip(
              currencyCode: baseCurrency,
              countryCodeOverride: countryCode,
              label: '${currencyObj?.symbol ?? baseCurrency} - ${currencyObj?.name ?? baseCurrency}',
              background: context.purpleBackground,
              borderColor: context.purpleBorderLighter,
              foreground: context.purpleText,
            ),
          ],
        ),
      ],
    );
  }

  String _getCountryCodeFromLanguage(String languageCode) {
    // Map language codes to country codes
    switch (languageCode.toLowerCase()) {
      case 'vi':
        return 'VN'; // Vietnam
      case 'en':
        return 'US'; // United States
      case 'zh':
        return 'CN'; // China
      case 'ja':
        return 'JP'; // Japan
      case 'ko':
        return 'KR'; // Korea
      case 'th':
        return 'TH'; // Thailand
      case 'id':
        return 'ID'; // Indonesia
      default:
        return 'US'; // Default to US
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profilePicture, required this.colorScheme});

  final String? profilePicture;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: colorScheme.surfaceContainerHighest,
      radius: 50,
      child: ClipOval(
        child: _buildInner(),
      ),
    );
  }

  Widget _buildInner() {
    if (profilePicture == null) return _fallback();

    if (!profilePicture!.startsWith('http')) {
      return CircleAvatar(
        backgroundImage: FileImage(File(profilePicture!)),
        radius: 49,
      );
    }

    // Network image with error fallback for 404/broken URLs
    return Image.network(
      profilePicture!,
      width: 98,
      height: 98,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _fallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _fallback();
      },
    );
  }

  Widget _fallback() => const CircleIconButton(
        icon: HugeIcons.strokeRoundedUser,
        radius: 49,
        iconSize: 40,
        backgroundColor: AppColors.secondary100,
        foregroundColor: AppColors.secondary800,
      );
}
