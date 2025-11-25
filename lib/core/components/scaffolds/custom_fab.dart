import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/features/main/presentation/components/transaction_options_menu.dart';

class CustomFab extends StatelessWidget {
  const CustomFab({super.key});

  @override
  Widget build(BuildContext context) {
    void showTransactionOptions() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => const TransactionOptionsMenu(),
      );
    }

    return Center(
      child: FloatingActionButton(
        heroTag: 'main_fab',
        shape: const CircleBorder(),
        backgroundColor: AppColors.primary,
        onPressed: showTransactionOptions,
        child: const Icon(
          HugeIcons.strokeRoundedPlusSign,
          color: AppColors.light,
        ),
      ),
    );
  }
}
