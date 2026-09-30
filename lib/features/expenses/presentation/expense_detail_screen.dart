import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/presentation/add_expense_screen.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/l10n/l10n.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  final GroupModel group;
  final List<GroupMember> members;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.group,
    required this.members,
  });

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  bool _isDeleting = false;

  String _getMemberName(String uid) {
    final member = widget.members.where((m) => m.uid == uid).firstOrNull;
    return member?.displayName ?? 'Member';
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.deleteExpenseConfirmTitle ?? 'Delete Expense',
          style: AppTypography.h3,
        ),
        content: Text(
          l10n?.deleteExpenseConfirmMessage ??
              'Are you sure you want to delete this expense? This will recalculate all group balances.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.commonCancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.commonDelete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await ref
            .read(expenseControllerProvider.notifier)
            .deleteExpense(
              groupId: widget.group.id,
              expenseId: widget.expense.id,
            );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.negative,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final expense = widget.expense;
    final currency = Currency.fromCode(expense.currency);
    final category = expense.category;
    final dateFormatted = DateFormat.yMMMMEEEEd().format(expense.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.expenseDetailTitle ?? 'Expense Details',
          style: AppTypography.h3,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n?.commonEdit ?? 'Edit',
            onPressed: () async {
              final nav = Navigator.of(context);
              await nav.push(
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(
                    group: widget.group,
                    members: widget.members,
                    initialExpense: expense,
                  ),
                ),
              );
              if (mounted) {
                nav.pop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: l10n?.commonDelete ?? 'Delete',
            color: AppColors.negative,
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: _isDeleting
          ? const Center(child: DenkLoadingView())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Expense Card
                  DenkCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          category.localizedName(l10n),
                          style: AppTypography.caption.copyWith(
                            color: category.color,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          expense.title,
                          style: AppTypography.h2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currency.formatMinor(expense.totalMinor),
                          style: AppTypography.monetary(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateFormatted,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Optional Notes
                  if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    DenkCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.expenseNotes ?? 'Notes',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  expense.notes!,
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Paid By Breakdown
                  Text(l10n?.paidBy ?? 'Paid by', style: AppTypography.h3),
                  const SizedBox(height: 12),
                  DenkCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: expense.payers.entries.map((entry) {
                        final name = _getMemberName(entry.key);
                        final amt = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                currency.formatMinor(amt),
                                style: AppTypography.monetary(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Split Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.splitBetween ?? 'Split between',
                        style: AppTypography.h3,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          expense.splitMethod == SplitMethod.equal
                              ? (l10n?.splitEqual ?? 'Equally')
                              : expense.splitMethod == SplitMethod.custom
                              ? (l10n?.splitCustom ?? 'Exact Amounts')
                              : (l10n?.splitPercentage ?? 'Percentage'),
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DenkCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: expense.splits.entries.map((entry) {
                        final name = _getMemberName(entry.key);
                        final amt = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                currency.formatMinor(amt),
                                style: AppTypography.monetary(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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
  }
}
