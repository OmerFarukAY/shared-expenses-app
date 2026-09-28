import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';

import 'package:denk/l10n/l10n.dart';

class ExpenseItemTile extends StatelessWidget {
  final ExpenseModel expense;
  final List<GroupMember> members;
  final String currentUserId;
  final VoidCallback? onTap;

  const ExpenseItemTile({
    super.key,
    required this.expense,
    required this.members,
    required this.currentUserId,
    this.onTap,
  });

  String _getPayerSummary(AppLocalizations? l10n) {
    if (expense.payers.length == 1) {
      final payerUid = expense.payers.keys.first;
      if (payerUid == currentUserId) {
        return l10n?.youPaid ?? 'You paid';
      }
      final member = members.where((m) => m.uid == payerUid).firstOrNull;
      final paidByLabel = l10n?.paidBy ?? 'Paid by';
      return '$paidByLabel ${member?.displayName ?? 'Someone'}';
    }
    return '${l10n?.paidBy ?? "Paid by"} ${expense.payers.length}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currency = Currency.fromCode(expense.currency);

    final paidByMe = expense.payers[currentUserId] ?? 0;
    final owedByMe = expense.splits[currentUserId] ?? 0;
    final myNetMinor = paidByMe - owedByMe;

    final dateFormatted = DateFormat.MMMd().format(expense.date);
    final category = expense.category;
    final payerSummary = _getPayerSummary(l10n);
    final semanticLabel = myNetMinor > 0
        ? '${expense.title}, total ${currency.formatMinor(expense.totalMinor)}, $payerSummary, you are owed ${currency.formatMinor(myNetMinor)}'
        : myNetMinor < 0
        ? '${expense.title}, total ${currency.formatMinor(expense.totalMinor)}, $payerSummary, you owe ${currency.formatMinor(myNetMinor.abs())}'
        : '${expense.title}, total ${currency.formatMinor(expense.totalMinor)}, $payerSummary';

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: DenkCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // Category Icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: category.color, size: 22),
            ),
            const SizedBox(width: 14),

            // Title & Payer summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        payerSummary,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        ' • $dateFormatted',
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Total amount & personal net impact
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.formatMinor(expense.totalMinor),
                  style: AppTypography.monetary(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (myNetMinor > 0)
                  Text(
                    '+${currency.formatMinor(myNetMinor)}',
                    style: AppTypography.monetary(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.positive,
                    ),
                  )
                else if (myNetMinor < 0)
                  Text(
                    '-${currency.formatMinor(myNetMinor.abs())}',
                    style: AppTypography.monetary(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.negative,
                    ),
                  )
                else if (paidByMe > 0)
                  Text(
                    l10n?.settledBadge ?? 'Settled',
                    style: AppTypography.caption.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
