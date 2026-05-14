import 'package:flutter/material.dart';

import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/ai_chat/presentation/riverpod/chat_provider.dart'
    show AgentToolEvent;

/// A small inline badge rendered beneath the last assistant message to
/// surface completed server-side tool calls from the Bexly Agent (Phase 3.4B).
///
/// Because the agent already executes tools on the server before streaming
/// the reply, this badge is purely retrospective (no confirm/cancel UI).
class AgentToolBadge extends StatelessWidget {
  const AgentToolBadge({
    super.key,
    required this.label,
    this.isError = false,
  });

  final String label;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    // Use red50/red600 for errors; green100/green200 for success.
    // AppColors has red50+red600 but only green100+green200 (no green50/600).
    final iconColor = isError ? AppColors.red600 : AppColors.green200;
    final bgColor = isError ? AppColors.red50 : AppColors.greenAlpha10;
    final borderColor = isError
        ? AppColors.red600.withValues(alpha: 0.3)
        : AppColors.green200.withValues(alpha: 0.4);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.spacing4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing8,
        vertical: AppSpacing.spacing4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: AppSpacing.spacing4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.body4.copyWith(color: iconColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Derives a human-readable badge label from an [AgentToolEvent].
///
/// Covers the 21 MCP tools registered in Phase 2; defaults to a generic
/// label for any new tool names introduced later.
String agentToolBadgeLabel(AgentToolEvent tool) {
  if (tool.isError) {
    switch (tool.name) {
      case 'record_transaction':
        final desc = tool.args['description'] as String? ?? 'giao dich';
        return 'Loi ghi: $desc';
      case 'create_budget':
        return 'Loi tao budget: ${tool.args['name'] ?? ''}';
      case 'create_goal':
        return 'Loi tao goal: ${tool.args['name'] ?? ''}';
      default:
        return 'Loi: ${tool.name}';
    }
  }

  switch (tool.name) {
    case 'record_transaction':
      final amt = (tool.args['amount'] as num?)?.toInt() ?? 0;
      final desc = tool.args['description'] as String? ?? 'giao dich';
      return 'Da ghi $amt d ($desc)';
    case 'update_transaction':
      return 'Da cap nhat giao dich';
    case 'delete_transaction':
      return 'Da xoa giao dich';
    case 'create_budget':
      return 'Da tao budget: ${tool.args['name'] ?? ''}';
    case 'update_budget':
      return 'Da cap nhat budget';
    case 'delete_budget':
      return 'Da xoa budget';
    case 'create_goal':
      return 'Da tao goal: ${tool.args['name'] ?? ''}';
    case 'update_goal':
      return 'Da cap nhat goal';
    case 'delete_goal':
      return 'Da xoa goal';
    case 'analyze_spending':
      return 'Da phan tich chi tieu';
    case 'get_transactions':
      return 'Da lay danh sach giao dich';
    case 'get_wallets':
      return 'Da lay danh sach vi';
    case 'get_budgets':
      return 'Da lay danh sach budget';
    case 'get_goals':
      return 'Da lay danh sach goal';
    case 'get_categories':
      return 'Da lay danh sach danh muc';
    default:
      return 'Da chay: ${tool.name}';
  }
}
