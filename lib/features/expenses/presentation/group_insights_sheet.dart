import 'package:flutter/material.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/domain/group_balance_calculator.dart';
import 'package:denk/l10n/l10n.dart';

class GroupInsightsSheet extends StatelessWidget {
  final GroupModel group;
  final List<GroupMember> members;
  final List<ExpenseModel> expenses;
  final GroupFinancialSummary summary;

  const GroupInsightsSheet({
    super.key,
    required this.group,
    required this.members,
    required this.expenses,
    required this.summary,
  });

  static Future<void> show({
    required BuildContext context,
    required GroupModel group,
    required List<GroupMember> members,
    required List<ExpenseModel> expenses,
    required GroupFinancialSummary summary,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GroupInsightsSheet(
        group: group,
        members: members,
        expenses: expenses,
        summary: summary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currency = Currency.fromCode(group.defaultCurrency);
    final totalSpending = summary.totalGroupSpendingMinor;

    // Calculate spending per category
    final Map<ExpenseCategory, int> categoryTotals = {};
    for (final exp in expenses) {
      if (exp.currency.toUpperCase() == group.defaultCurrency.toUpperCase()) {
        categoryTotals[exp.category] =
            (categoryTotals[exp.category] ?? 0) + exp.totalMinor;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n?.spendingInsights ?? 'Spending Overview',
              style: AppTypography.h3,
            ),
          ),
          body: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Spending Card
                DenkCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.totalSpending ?? 'Total Spending',
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currency.formatMinor(totalSpending),
                        style: AppTypography.monetary(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Across ${expenses.length} expenses in ${group.name}',
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 1. SPENDING BY CATEGORY
                Text(
                  l10n?.spendingByCategory ?? 'Spending by Category',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 12),

                if (sortedCategories.isEmpty)
                  DenkCard(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No category data available yet.',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  )
                else
                  DenkCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: sortedCategories.map((entry) {
                        final cat = entry.key;
                        final amount = entry.value;
                        final double fraction = totalSpending > 0
                            ? (amount / totalSpending).clamp(0.0, 1.0)
                            : 0.0;
                        final percentage = (fraction * 100).round();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: cat.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      cat.icon,
                                      size: 16,
                                      color: cat.color,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      cat.localizedName(l10n),
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$percentage%',
                                    style: AppTypography.caption.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currency.formatMinor(amount),
                                    style: AppTypography.monetary(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  minHeight: 6,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    cat.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 24),

                // 2. MEMBER CONTRIBUTIONS OVERVIEW
                Text(
                  l10n?.memberContributions ?? 'Member Contributions',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 12),

                DenkCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: members.map((m) {
                      final bal = summary.memberBalances[m.uid];
                      final paid = bal?.totalPaidMinor ?? 0;
                      final share = bal?.totalOwedMinor ?? 0;
                      final double paidFraction = totalSpending > 0
                          ? (paid / totalSpending).clamp(0.0, 1.0)
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  m.displayName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Paid: ${currency.formatMinor(paid)}',
                                  style: AppTypography.monetary(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Fair Share: ${currency.formatMinor(share)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                DenkBalancePill(
                                  balanceMinor: bal?.netBalanceMinor ?? 0,
                                  currency: currency,
                                  fontSize: 11,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: paidFraction,
                                minHeight: 6,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
