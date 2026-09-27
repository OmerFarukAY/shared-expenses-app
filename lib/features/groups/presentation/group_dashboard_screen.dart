import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/expenses/domain/group_balance_calculator.dart';
import 'package:denk/features/expenses/presentation/add_expense_screen.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/features/expenses/presentation/expense_detail_screen.dart';
import 'package:denk/features/expenses/presentation/expense_item_tile.dart';
import 'package:denk/l10n/l10n.dart';

class GroupDashboardScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupDashboardScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDashboardScreen> createState() =>
      _GroupDashboardScreenState();
}

class _GroupDashboardScreenState extends ConsumerState<GroupDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyInviteCode(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: widget.group.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.inviteCodeCopied ?? 'Invite code copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(userProfileControllerProvider).value;
    final currentUserId = user?.uid ?? '';

    final membersAsync = ref.watch(groupMembersStreamProvider(widget.group.id));
    final expensesAsync = ref.watch(
      groupExpensesStreamProvider(widget.group.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.name,
              style: AppTypography.h3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            membersAsync.when(
              data: (members) => Text(
                '${members.length} members',
                style: AppTypography.caption.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _copyInviteCode(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.key_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.group.inviteCode,
                      style: AppTypography.monetary(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          return expensesAsync.when(
            data: (expenses) {
              final summary = GroupBalanceCalculator.calculate(
                expenses: expenses,
                members: members,
                defaultCurrency: widget.group.defaultCurrency,
              );

              final currency = summary.currency;
              final myNetMinor = summary.getUserNetMinor(currentUserId);
              final isCreditor = myNetMinor > 0;
              final isDebtor = myNetMinor < 0;

              return Column(
                children: [
                  // HERO BALANCE CARD
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isCreditor
                            ? (isDark
                                  ? AppColors.positiveDark.withValues(
                                      alpha: 0.5,
                                    )
                                  : AppColors.positiveLight)
                            : isDebtor
                            ? (isDark
                                  ? AppColors.negativeDark.withValues(
                                      alpha: 0.5,
                                    )
                                  : AppColors.negativeLight)
                            : (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCreditor
                              ? AppColors.positive.withValues(alpha: 0.25)
                              : isDebtor
                              ? AppColors.negative.withValues(alpha: 0.25)
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isCreditor
                                    ? (l10n?.youAreOwed ?? 'You are owed')
                                    : isDebtor
                                    ? (l10n?.youOwe ?? 'You owe')
                                    : (l10n?.allSettled ?? 'All settled up'),
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isCreditor
                                      ? (isDark
                                            ? AppColors.positiveBright
                                            : AppColors.positive)
                                      : isDebtor
                                      ? (isDark
                                            ? AppColors.negativeBright
                                            : AppColors.negative)
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                              Text(
                                '${l10n?.totalSpending ?? 'Total Spending'}: ${currency.formatMinor(summary.totalGroupSpendingMinor)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isCreditor
                                ? '+${currency.formatMinor(myNetMinor)}'
                                : isDebtor
                                ? '-${currency.formatMinor(myNetMinor.abs())}'
                                : currency.formatMinor(0),
                            style: AppTypography.monetary(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: isCreditor
                                  ? (isDark
                                        ? AppColors.positiveBright
                                        : AppColors.positive)
                                  : isDebtor
                                  ? (isDark
                                        ? AppColors.negativeBright
                                        : AppColors.negative)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // TAB BAR
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                      labelStyle: AppTypography.labelMedium,
                      tabs: [
                        Tab(
                          text: expenses.isNotEmpty
                              ? '${l10n?.expensesTab ?? 'Expenses'} (${expenses.length})'
                              : (l10n?.expensesTab ?? 'Expenses'),
                        ),
                        Tab(text: l10n?.balancesTab ?? 'Balances'),
                      ],
                    ),
                  ),

                  // TAB VIEWS
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // TAB 1: EXPENSES
                        expenses.isEmpty
                            ? Center(
                                child: DenkEmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  title:
                                      l10n?.noExpensesTitle ??
                                      'No expenses yet',
                                  subtitle:
                                      l10n?.noExpensesSubtitle ??
                                      'Tap the button below to add your first expense.',
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                itemCount: expenses.length,
                                itemBuilder: (context, index) {
                                  final expense = expenses[index];
                                  return ExpenseItemTile(
                                    expense: expense,
                                    members: members,
                                    currentUserId: currentUserId,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ExpenseDetailScreen(
                                            expense: expense,
                                            group: widget.group,
                                            members: members,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),

                        // TAB 2: BALANCES
                        ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final bal = summary.memberBalances[member.uid];
                            final net = bal?.netBalanceMinor ?? 0;
                            final paid = bal?.totalPaidMinor ?? 0;
                            final owed = bal?.totalOwedMinor ?? 0;

                            return DenkCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.12),
                                    child: Text(
                                      member.displayName.isNotEmpty
                                          ? member.displayName[0].toUpperCase()
                                          : '?',
                                      style: AppTypography.h3.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.uid == currentUserId
                                              ? '${member.displayName} (You)'
                                              : member.displayName,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Paid: ${currency.formatMinor(paid)} • Share: ${currency.formatMinor(owed)}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DenkBalancePill(
                                    balanceMinor: net,
                                    currency: currency,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: DenkLoadingView()),
            error: (err, _) => Center(
              child: DenkErrorView(
                message: err.toString(),
                onRetry: () =>
                    ref.refresh(groupExpensesStreamProvider(widget.group.id)),
              ),
            ),
          );
        },
        loading: () => const Center(child: DenkLoadingView()),
        error: (err, _) => Center(
          child: DenkErrorView(
            message: err.toString(),
            onRetry: () =>
                ref.refresh(groupMembersStreamProvider(widget.group.id)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          membersAsync.whenData((members) {
            AddExpenseScreen.show(
              context: context,
              group: widget.group,
              members: members,
            );
          });
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n?.addExpense ?? 'Add Expense'),
      ),
    );
  }
}
