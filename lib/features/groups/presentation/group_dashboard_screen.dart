import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/group_balance_calculator.dart';
import 'package:denk/features/expenses/presentation/add_expense_screen.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/features/expenses/presentation/expense_detail_screen.dart';
import 'package:denk/features/expenses/presentation/expense_item_tile.dart';
import 'package:denk/features/expenses/presentation/group_insights_sheet.dart';
import 'package:denk/features/settlements/domain/settlement_engine.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';
import 'package:denk/features/settlements/presentation/settlement_controller.dart';
import 'package:denk/features/groups/presentation/join_requests_sheet.dart';
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
  final TextEditingController _searchController = TextEditingController();
  ExpenseCategory? _selectedCategory;
  String? _selectedMemberUid;
  String? _selectedViewCurrency;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedMemberUid = null;
    });
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

  Future<void> _recordSettlement(SettlementTransaction tx) async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(userProfileControllerProvider).value;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.markAsSettled ?? 'Mark as Settled',
          style: AppTypography.h3,
        ),
        content: Text(
          'Confirm that ${tx.fromName} paid ${tx.toName}?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.commonCancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.commonConfirm ?? 'Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final record = SettlementRecord(
        id: const Uuid().v4(),
        groupId: widget.group.id,
        fromUid: tx.fromUid,
        fromName: tx.fromName,
        toUid: tx.toUid,
        toName: tx.toName,
        amountMinor: tx.amountMinor,
        currency: tx.currency,
        settledAt: DateTime.now(),
        createdBy: user.uid,
      );

      try {
        await ref
            .read(settlementControllerProvider.notifier)
            .recordSettlement(record);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.settlementCompleted ?? 'Settlement recorded successfully',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(userProfileControllerProvider).value;
    final currentUserId = user?.uid ?? '';

    final membersAsync = ref.watch(groupMembersStreamProvider(widget.group.id));
    final expensesAsync = ref.watch(
      groupExpensesStreamProvider(widget.group.id),
    );
    final settlementsAsync = ref.watch(
      groupSettlementsStreamProvider(widget.group.id),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
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
                '${members.length} ${l10n?.membersLabel ?? 'members'}',
                style: AppTypography.labelSmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          // Insights / Statistics Button
          membersAsync.when(
            data: (members) => expensesAsync.when(
              data: (expenses) => settlementsAsync.when(
                data: (settlements) {
                  final summaries = GroupBalanceCalculator.calculateAll(
                    expenses: expenses,
                    members: members,
                    defaultCurrency: widget.group.defaultCurrency,
                    settlements: settlements,
                  );
                  final activeCurrency = _selectedViewCurrency ?? widget.group.defaultCurrency;
                  final summary = summaries[activeCurrency]!;
                  return IconButton(
                    icon: const Icon(Icons.insights_rounded),
                    tooltip: l10n?.spendingInsights ?? 'Spending Overview',
                    onPressed: () {
                      GroupInsightsSheet.show(
                        context: context,
                        group: widget.group,
                        members: members,
                        expenses: expenses,
                        summary: summary,
                      );
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Join Requests Badge & Button (Creator only)
          if (widget.group.createdBy == currentUserId)
            Consumer(
              builder: (context, ref, _) {
                final reqsAsync = ref.watch(
                  groupJoinRequestsStreamProvider(widget.group.id),
                );
                final count = reqsAsync.value?.length ?? 0;
                return IconButton(
                  tooltip:
                      l10n?.manageJoinRequestsTooltip ?? 'Manage Join Requests',
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.person_add_outlined),
                  ),
                  onPressed: () {
                    JoinRequestsSheet.show(
                      context: context,
                      group: widget.group,
                    );
                  },
                );
              },
            ),

          // Invite Code Badge
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
              return settlementsAsync.when(
                data: (settlements) {
                  final summaries = GroupBalanceCalculator.calculateAll(
                    expenses: expenses,
                    members: members,
                    defaultCurrency: widget.group.defaultCurrency,
                    settlements: settlements,
                  );

                  final availableCurrencies = summaries.keys.toList()..sort();
                  final activeCurrencyCode = _selectedViewCurrency ?? widget.group.defaultCurrency;
                  final summary = summaries[activeCurrencyCode] ?? summaries[widget.group.defaultCurrency]!;

                  final currency = summary.currency;
                  final myNetMinor = summary.getUserNetMinor(currentUserId);
                  final isCreditor = myNetMinor > 0;
                  final isDebtor = myNetMinor < 0;

                  // Compute simplified settlement plan
                  final netBalances = <String, int>{
                    for (final m in members)
                      m.uid:
                          summary.memberBalances[m.uid]?.netBalanceMinor ?? 0,
                  };
                  final memberNames = <String, String>{
                    for (final m in members) m.uid: m.displayName,
                  };
                  final simplifiedTransactions = SettlementEngine.simplifyDebts(
                    netBalances: netBalances,
                    memberNames: memberNames,
                    currency: summary.currencyCode,
                  );

                  // Filter expenses based on search & filter selection
                  final query = _searchController.text.trim().toLowerCase();
                  final filteredExpenses = expenses.where((e) {
                    if (_selectedCategory != null &&
                        e.category != _selectedCategory) {
                      return false;
                    }
                    if (_selectedMemberUid != null) {
                      final isPayer = e.payers.containsKey(_selectedMemberUid);
                      final isParticipant = e.participants.contains(
                        _selectedMemberUid,
                      );
                      if (!isPayer && !isParticipant) return false;
                    }
                    if (query.isNotEmpty) {
                      final matchesTitle = e.title.toLowerCase().contains(
                        query,
                      );
                      final matchesNotes =
                          e.notes?.toLowerCase().contains(query) ?? false;
                      if (!matchesTitle && !matchesNotes) return false;
                    }
                    return true;
                  }).toList();

                  final hasActiveFilter =
                      query.isNotEmpty ||
                      _selectedCategory != null ||
                      _selectedMemberUid != null;

                  return Column(
                    children: [
                      // CURRENCY SELECTOR
                      if (availableCurrencies.length > 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(l10n?.currency ?? 'Currency:', style: AppTypography.labelSmall),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: activeCurrencyCode,
                                    isDense: true,
                                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                    items: availableCurrencies
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedViewCurrency = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // HERO BALANCE CARD
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Semantics(
                          label: isCreditor
                              ? '${l10n?.youAreOwed ?? 'You are owed'}: ${currency.formatMinor(myNetMinor)}'
                              : isDebtor
                              ? '${l10n?.youOwe ?? 'You owe'}: ${currency.formatMinor(myNetMinor.abs())}'
                              : (l10n?.allSettled ?? 'All settled up'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (isCreditor)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: Icon(
                                              Icons.arrow_upward_rounded,
                                              size: 16,
                                              color: isDark
                                                  ? AppColors.positiveBright
                                                  : AppColors.positive,
                                            ),
                                          )
                                        else if (isDebtor)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: Icon(
                                              Icons.arrow_downward_rounded,
                                              size: 16,
                                              color: isDark
                                                  ? AppColors.negativeBright
                                                  : AppColors.negative,
                                            ),
                                          )
                                        else
                                          const Padding(
                                            padding: EdgeInsets.only(right: 6),
                                            child: Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              size: 16,
                                              color: AppColors.settled,
                                            ),
                                          ),
                                        Text(
                                          isCreditor
                                              ? (l10n?.youAreOwed ??
                                                    'You are owed')
                                              : isDebtor
                                              ? (l10n?.youOwe ?? 'You owe')
                                              : (l10n?.allSettled ??
                                                    'All settled up'),
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isCreditor
                                                    ? (isDark
                                                          ? AppColors
                                                                .positiveBright
                                                          : AppColors.positive)
                                                    : isDebtor
                                                    ? (isDark
                                                          ? AppColors
                                                                .negativeBright
                                                          : AppColors.negative)
                                                    : theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                              ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${l10n?.totalSpending ?? 'Total Spending'}: ${currency.formatMinor(summary.totalGroupSpendingMinor)}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
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
                      ),

                      // TAB BAR (3 TABS)
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
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          tabs: [
                            Tab(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  expenses.isNotEmpty
                                      ? '${l10n?.expensesTab ?? 'Expenses'} (${expenses.length})'
                                      : (l10n?.expensesTab ?? 'Expenses'),
                                ),
                              ),
                            ),
                            Tab(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n?.balancesTab ?? 'Balances'),
                              ),
                            ),
                            Tab(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  simplifiedTransactions.isNotEmpty
                                      ? '${l10n?.settleTab ?? 'Settle'} (${simplifiedTransactions.length})'
                                      : (l10n?.settleTab ?? 'Settle'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TAB VIEWS
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // TAB 1: EXPENSES WITH SEARCH & FILTERS
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
                                : Column(
                                    children: [
                                      // Search Bar
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          8,
                                          16,
                                          4,
                                        ),
                                        child: SizedBox(
                                          height: 40,
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: (_) => setState(() {}),
                                            style: AppTypography.bodyMedium,
                                            decoration: InputDecoration(
                                              hintText:
                                                  l10n?.searchHint ??
                                                  'Search expenses...',
                                              hintStyle: AppTypography
                                                  .bodyMedium
                                                  .copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.4),
                                                  ),
                                              prefixIcon: const Icon(
                                                Icons.search_rounded,
                                                size: 20,
                                              ),
                                              suffixIcon:
                                                  _searchController
                                                      .text
                                                      .isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                        Icons.clear_rounded,
                                                        size: 18,
                                                      ),
                                                      onPressed: () {
                                                        _searchController
                                                            .clear();
                                                        setState(() {});
                                                      },
                                                    )
                                                  : null,
                                              contentPadding: EdgeInsets.zero,
                                              filled: true,
                                              fillColor: theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Filter Chips Bar
                                      SizedBox(
                                        height: 44,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          children: [
                                            // Reset chip if active
                                            if (hasActiveFilter) ...[
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                child: ActionChip(
                                                  avatar: const Icon(
                                                    Icons.close_rounded,
                                                    size: 14,
                                                  ),
                                                  label: Text(
                                                    l10n?.clearFilters ??
                                                        'Clear',
                                                    style: AppTypography
                                                        .labelSmall,
                                                  ),
                                                  onPressed: _clearFilters,
                                                ),
                                              ),
                                            ],

                                            // All Filter Chip
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: FilterChip(
                                                selected:
                                                    _selectedCategory == null &&
                                                    _selectedMemberUid == null,
                                                label: Text(
                                                  l10n?.filterAll ?? 'All',
                                                ),
                                                onSelected: (_) =>
                                                    _clearFilters(),
                                              ),
                                            ),

                                            // Category Filter Chips
                                            ...ExpenseCategory.values.map((
                                              cat,
                                            ) {
                                              final isSelected =
                                                  _selectedCategory == cat;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                child: FilterChip(
                                                  avatar: Icon(
                                                    cat.icon,
                                                    size: 14,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : cat.color,
                                                  ),
                                                  selected: isSelected,
                                                  showCheckmark: false,
                                                  label: Text(
                                                    cat.localizedName(l10n),
                                                    style: AppTypography
                                                        .labelSmall,
                                                  ),
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _selectedCategory =
                                                          selected ? cat : null;
                                                    });
                                                  },
                                                ),
                                              );
                                            }),

                                            // Member Filter Chips
                                            ...members.map((m) {
                                              final isSelected =
                                                  _selectedMemberUid == m.uid;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                child: FilterChip(
                                                  selected: isSelected,
                                                  label: Text(
                                                    m.uid == currentUserId
                                                        ? (l10n?.youLabel ?? 'You')
                                                        : m.displayName,
                                                    style: AppTypography
                                                        .labelSmall,
                                                  ),
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _selectedMemberUid =
                                                          selected
                                                          ? m.uid
                                                          : null;
                                                    });
                                                  },
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),

                                      // Expense List or No Matching State
                                      Expanded(
                                        child: filteredExpenses.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    DenkEmptyState(
                                                      icon: Icons
                                                          .search_off_rounded,
                                                      title:
                                                          l10n?.noMatchingExpenses ??
                                                          'No matching expenses',
                                                      subtitle:
                                                          l10n?.tryClearingSearchFilter ??
                                                          'Try clearing your search or filter options.',
                                                    ),
                                                    const SizedBox(height: 12),
                                                    TextButton.icon(
                                                      onPressed: _clearFilters,
                                                      icon: const Icon(
                                                        Icons.refresh_rounded,
                                                        size: 18,
                                                      ),
                                                      label: Text(
                                                        l10n?.clearFilters ??
                                                            'Clear Filters',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : ListView.builder(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                itemCount:
                                                    filteredExpenses.length,
                                                itemBuilder: (context, index) {
                                                  final expense =
                                                      filteredExpenses[index];
                                                  return ExpenseItemTile(
                                                    expense: expense,
                                                    members: members,
                                                    currentUserId:
                                                        currentUserId,
                                                    onTap: () {
                                                      Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              ExpenseDetailScreen(
                                                                expense:
                                                                    expense,
                                                                group: widget
                                                                    .group,
                                                                members:
                                                                    members,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
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
                                        backgroundColor: theme
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.12),
                                        child: Text(
                                          member.displayName.isNotEmpty
                                              ? member.displayName[0]
                                                    .toUpperCase()
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

                            // TAB 3: SETTLE UP
                            ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              children: [
                                if (simplifiedTransactions.isEmpty &&
                                    settlements.where((s) => s.currency.toUpperCase() == activeCurrencyCode).isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: DenkEmptyState(
                                      icon: Icons.check_circle_outline_rounded,
                                      title:
                                          l10n?.allSettled ?? 'All settled up',
                                      subtitle:
                                          l10n?.noSettlementsNeeded ??
                                          'Everyone is settled up! No payments needed.',
                                    ),
                                  ),

                                if (simplifiedTransactions.isNotEmpty) ...[
                                  Text(
                                    l10n?.settlementTitle ?? 'Settlement Plan',
                                    style: AppTypography.h3,
                                  ),
                                  const SizedBox(height: 10),
                                  ...simplifiedTransactions.map((tx) {
                                    final isMeDebtor =
                                        tx.fromUid == currentUserId;
                                    final isMeCreditor =
                                        tx.toUid == currentUserId;

                                    return DenkCard(
                                      padding: const EdgeInsets.all(16),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        isMeDebtor
                                                            ? 'You'
                                                            : tx.fromName,
                                                        style: AppTypography
                                                            .bodyMedium
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                      child: Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        size: 16,
                                                        color:
                                                            AppColors.settled,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        isMeCreditor
                                                            ? 'You'
                                                            : tx.toName,
                                                        style: AppTypography
                                                            .bodyMedium
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                currency.formatMinor(
                                                  tx.amountMinor,
                                                ),
                                                style: AppTypography.monetary(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: DenkButton(
                                              label:
                                                  l10n?.markAsSettled ??
                                                  'Mark as Settled',
                                              variant:
                                                  DenkButtonVariant.secondary,
                                              height: 40,
                                              onPressed: () =>
                                                  _recordSettlement(tx),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],

                                if (settlements.where((s) => s.currency.toUpperCase() == activeCurrencyCode).isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    l10n?.settlementHistory ??
                                        'Settlement History',
                                    style: AppTypography.h3,
                                  ),
                                  const SizedBox(height: 10),
                                  ...settlements.where((s) => s.currency.toUpperCase() == activeCurrencyCode).map((record) {
                                    final dateFormatted = DateFormat.yMMMd()
                                        .format(record.settledAt);
                                    return DenkCard(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.positive,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${record.fromName} paid ${record.toName}',
                                                  style: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                Text(
                                                  dateFormatted,
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            currency.formatMinor(
                                              record.amountMinor,
                                            ),
                                            style: AppTypography.monetary(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
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
                    onRetry: () => ref.refresh(
                      groupSettlementsStreamProvider(widget.group.id),
                    ),
                  ),
                ),
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
        tooltip: l10n?.addExpense ?? 'Add Expense',
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
