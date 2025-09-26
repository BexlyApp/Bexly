import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/menu_tile_button.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/backup_and_restore/presentation/components/backup_dialog.dart';
import 'package:bexly/features/backup_and_restore/presentation/components/restore_dialog.dart';

enum BackupSchedule { daily, weekly, monthly }

class BackupRestoreScreen extends HookConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return CustomScaffold(
      context: context,
      title: 'Backup & Restore',
      showBalance: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
        child: Column(
          spacing: AppSpacing.spacing8,
          children: [
            MenuTileButton(
              label: 'Backup Manually',
              icon: HugeIcons.strokeRoundedDatabaseExport,
              suffixIcon: null,
              onTap: () {
                context.openBottomSheet(
                  isScrollControlled: false,
                  child: BackupDialog(onSuccess: () => context.pop()),
                );
              },
            ),
            MenuTileButton(
              label: 'Restore Data',
              icon: HugeIcons.strokeRoundedDatabaseImport,
              onTap: () {
                context.openBottomSheet(
                  isScrollControlled: false,
                  child: Container(),
                  builder: (dialogContext) => CustomBottomSheet(
                    title: 'Restore Data',
                    child: RestoreDialog(
                      onSuccess: () async {
                        await Future.delayed(
                          const Duration(milliseconds: 1500),
                        );

                        if (context.mounted) {
                          dialogContext.pop();
                          context.replace(Routes.main);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
