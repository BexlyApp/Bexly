import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/services/demo_data_service.dart';

/// Bottom sheet for selecting a demo persona.
/// Each persona card shows name, role, income, and which features it showcases.
class DemoPersonaSelectorSheet extends ConsumerStatefulWidget {
  const DemoPersonaSelectorSheet({super.key});

  /// Show the persona selector and return the selected persona (or null).
  static Future<DemoPersona?> show(BuildContext context) async {
    return showModalBottomSheet<DemoPersona>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const DemoPersonaSelectorSheet(),
    );
  }

  @override
  ConsumerState<DemoPersonaSelectorSheet> createState() =>
      _DemoPersonaSelectorSheetState();
}

class _DemoPersonaSelectorSheetState
    extends ConsumerState<DemoPersonaSelectorSheet> {
  bool _isLoading = false;
  DemoPersona? _loadingPersona;

  Future<void> _selectPersona(DemoPersona persona) async {
    setState(() {
      _isLoading = true;
      _loadingPersona = persona;
    });

    try {
      final demoService = ref.read(demoDataServiceProvider);
      final txCount = await demoService.seedPersona(persona);

      if (mounted) {
        Navigator.of(context).pop(persona);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${persona.icon} ${persona.displayName} loaded - $txCount transactions',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingPersona = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load demo data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: 'Select Demo Account',
      subtitle:
          'Choose a persona to load pre-built financial data. Previous demo data will be cleared.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...DemoPersona.values.map((persona) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
                child: _PersonaCard(
                  persona: persona,
                  isLoading: _isLoading && _loadingPersona == persona,
                  isDisabled: _isLoading && _loadingPersona != persona,
                  onTap: _isLoading ? null : () => _selectPersona(persona),
                ),
              )),
          const Gap(AppSpacing.spacing8),
        ],
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  final DemoPersona persona;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _PersonaCard({
    required this.persona,
    this.isLoading = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  persona.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const Gap(AppSpacing.spacing12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.displayName,
                      style: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      persona.subtitle,
                      style: AppTextStyles.body4.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      persona.description,
                      style: AppTextStyles.body5.copyWith(
                        color: AppColors.neutral500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(8),
                    // Feature tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: persona.demoFeatures
                          .map((f) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  f,
                                  style: AppTextStyles.body5.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              // Loading or arrow
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppColors.neutral400,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
