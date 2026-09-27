import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/domain/expense_split_engine.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/l10n/l10n.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final GroupModel group;
  final List<GroupMember> members;
  final ExpenseModel? initialExpense;

  const AddExpenseScreen({
    super.key,
    required this.group,
    required this.members,
    this.initialExpense,
  });

  static Future<void> show({
    required BuildContext context,
    required GroupModel group,
    required List<GroupMember> members,
    ExpenseModel? initialExpense,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddExpenseScreen(
        group: group,
        members: members,
        initialExpense: initialExpense,
      ),
    );
  }

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late Currency _currency;
  late ExpenseCategory _category;
  late DateTime _date;
  late SplitMethod _splitMethod;

  // Single vs Multiple Payers
  bool _isMultiplePayers = false;
  String? _singlePayerUid;
  final Map<String, TextEditingController> _payerControllers = {};

  // Participants
  final Set<String> _selectedParticipants = {};

  // Custom / Percentage split controllers
  final Map<String, TextEditingController> _customSplitControllers = {};
  final Map<String, TextEditingController> _pctControllers = {};

  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileControllerProvider).value;
    final edit = widget.initialExpense;

    _currency = Currency.fromCode(
      edit?.currency ?? widget.group.defaultCurrency,
    );
    _category = edit?.category ?? ExpenseCategory.food;
    _date = edit?.date ?? DateTime.now();
    _splitMethod = edit?.splitMethod ?? SplitMethod.equal;

    if (edit != null) {
      _amountController.text = _currency.formatMinor(
        edit.totalMinor,
        includeSymbol: false,
      );
      _titleController.text = edit.title;
      _notesController.text = edit.notes ?? '';

      // Initialize Payers
      if (edit.payers.length > 1) {
        _isMultiplePayers = true;
        for (final m in widget.members) {
          final amt = edit.payers[m.uid] ?? 0;
          _payerControllers[m.uid] = TextEditingController(
            text: amt > 0
                ? _currency.formatMinor(amt, includeSymbol: false)
                : '',
          );
        }
      } else {
        _isMultiplePayers = false;
        _singlePayerUid = edit.payers.keys.isNotEmpty
            ? edit.payers.keys.first
            : user?.uid;
      }

      // Initialize Participants
      _selectedParticipants.addAll(edit.participants);

      // Initialize Custom / Pct
      for (final m in widget.members) {
        final splitAmt = edit.splits[m.uid] ?? 0;
        _customSplitControllers[m.uid] = TextEditingController(
          text: splitAmt > 0
              ? _currency.formatMinor(splitAmt, includeSymbol: false)
              : '',
        );
      }
    } else {
      // Default: single payer is current user
      _singlePayerUid =
          user?.uid ??
          (widget.members.isNotEmpty ? widget.members.first.uid : null);

      // Default: all group members participate
      for (final m in widget.members) {
        _selectedParticipants.add(m.uid);
        _payerControllers[m.uid] = TextEditingController();
        _customSplitControllers[m.uid] = TextEditingController();
        _pctControllers[m.uid] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    for (final c in _payerControllers.values) {
      c.dispose();
    }
    for (final c in _customSplitControllers.values) {
      c.dispose();
    }
    for (final c in _pctControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _parsedTotalMinor {
    return _currency.parseToMinor(_amountController.text) ?? 0;
  }

  void _submit() async {
    final totalMinor = _parsedTotalMinor;

    if (totalMinor <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount.');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter what the expense was for.');
      return;
    }

    if (_selectedParticipants.isEmpty) {
      setState(
        () => _errorMessage = 'At least one participant must be selected.',
      );
      return;
    }

    // Build Payers map
    final Map<String, int> payers = {};
    if (!_isMultiplePayers) {
      if (_singlePayerUid == null) {
        setState(() => _errorMessage = 'Please select who paid.');
        return;
      }
      payers[_singlePayerUid!] = totalMinor;
    } else {
      int sumPayers = 0;
      for (final m in widget.members) {
        final text = _payerControllers[m.uid]?.text ?? '';
        final amt = _currency.parseToMinor(text) ?? 0;
        if (amt > 0) {
          payers[m.uid] = amt;
          sumPayers += amt;
        }
      }
      if (sumPayers != totalMinor) {
        final formattedTotal = _currency.formatMinor(totalMinor);
        final formattedSum = _currency.formatMinor(sumPayers);
        setState(() {
          _errorMessage =
              'Payer contributions ($formattedSum) must match total expense ($formattedTotal).';
        });
        return;
      }
    }

    // Build Splits map
    Map<String, int> splits = {};
    try {
      if (_splitMethod == SplitMethod.equal) {
        splits = ExpenseSplitEngine.calculateEqualSplits(
          totalMinor: totalMinor,
          participantUids: _selectedParticipants.toList(),
        );
      } else if (_splitMethod == SplitMethod.custom) {
        int sumCustom = 0;
        for (final uid in _selectedParticipants) {
          final text = _customSplitControllers[uid]?.text ?? '';
          final amt = _currency.parseToMinor(text) ?? 0;
          splits[uid] = amt;
          sumCustom += amt;
        }
        if (sumCustom != totalMinor) {
          final formattedTotal = _currency.formatMinor(totalMinor);
          final formattedSum = _currency.formatMinor(sumCustom);
          setState(() {
            _errorMessage =
                'Allocated splits ($formattedSum) must equal total expense ($formattedTotal).';
          });
          return;
        }
      } else if (_splitMethod == SplitMethod.percentage) {
        final Map<String, double> pcts = {};
        for (final uid in _selectedParticipants) {
          final text = _pctControllers[uid]?.text.trim() ?? '0';
          pcts[uid] = double.tryParse(text) ?? 0.0;
        }
        splits = ExpenseSplitEngine.calculatePercentageSplits(
          totalMinor: totalMinor,
          percentages: pcts,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      return;
    }

    final user = ref.read(userProfileControllerProvider).value;
    if (user == null) return;

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    final now = DateTime.now();
    final expense = ExpenseModel(
      id: widget.initialExpense?.id ?? const Uuid().v4(),
      groupId: widget.group.id,
      title: title,
      notes: _notesController.text.trim(),
      category: _category,
      currency: _currency.code,
      totalMinor: totalMinor,
      date: _date,
      splitMethod: _splitMethod,
      payers: payers,
      participants: _selectedParticipants.toList(),
      splits: splits,
      createdBy: widget.initialExpense?.createdBy ?? user.uid,
      createdAt: widget.initialExpense?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (widget.initialExpense != null) {
        await ref
            .read(expenseControllerProvider.notifier)
            .updateExpense(expense);
      } else {
        await ref.read(expenseControllerProvider.notifier).addExpense(expense);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.initialExpense != null
              ? (l10n?.commonEdit ?? 'Edit Expense')
              : (l10n?.addExpense ?? 'Add Expense'),
          style: AppTypography.h2,
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n?.commonSave ?? 'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: bottomInset + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.negativeLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.negative.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.negative,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.negative,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. AMOUNT HERO INPUT
              DenkCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _currency.symbol,
                      style: AppTypography.monetary(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTypography.monetary(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: AppTypography.monetary(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        autofocus: widget.initialExpense == null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. TITLE INPUT
              DenkTextField(
                controller: _titleController,
                label: l10n?.expenseTitle ?? 'What was it for?',
                hintText:
                    l10n?.expenseTitleHint ?? 'e.g. Groceries, Dinner, Rent',
              ),
              const SizedBox(height: 16),

              // CATEGORIES ROW
              Text(
                l10n?.expenseCategory ?? 'Category',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ExpenseCategory.values.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = ExpenseCategory.values[idx];
                    final isSelected = cat == _category;
                    return InkWell(
                      onTap: () => setState(() => _category = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withValues(alpha: 0.15)
                              : (isDark
                                    ? AppColors.darkSurfaceSubtle
                                    : AppColors.lightSurfaceSubtle),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? cat.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 16, color: cat.color),
                            const SizedBox(width: 6),
                            Text(
                              cat.localizedName(l10n),
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? cat.color
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. WHO PAID?
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.expensePaidBy ?? 'Who paid?',
                    style: AppTypography.h3,
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _isMultiplePayers = !_isMultiplePayers),
                    child: Text(
                      _isMultiplePayers ? 'Single Payer' : 'Multiple Payers',
                      style: AppTypography.labelMedium.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!_isMultiplePayers) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.members.map((m) {
                    final isSelected = m.uid == _singlePayerUid;
                    return ChoiceChip(
                      label: Text(m.displayName),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _singlePayerUid = m.uid),
                    );
                  }).toList(),
                ),
              ] else ...[
                DenkCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: widget.members.map((m) {
                      final controller = _payerControllers[m.uid]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.displayName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.right,
                                style: AppTypography.monetary(fontSize: 15),
                                decoration: InputDecoration(
                                  prefixText: _currency.symbol,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // 4. WHO PARTICIPATED?
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.expenseSplitWith ?? 'Who participated?',
                    style: AppTypography.h3,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedParticipants.length ==
                            widget.members.length) {
                          _selectedParticipants.clear();
                        } else {
                          for (final m in widget.members) {
                            _selectedParticipants.add(m.uid);
                          }
                        }
                      });
                    },
                    child: Text(
                      _selectedParticipants.length == widget.members.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: AppTypography.labelMedium.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.members.map((m) {
                  final isIncluded = _selectedParticipants.contains(m.uid);
                  return FilterChip(
                    label: Text(m.displayName),
                    selected: isIncluded,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedParticipants.add(m.uid);
                        } else {
                          _selectedParticipants.remove(m.uid);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 5. SPLIT METHOD
              Text(
                l10n?.expenseSplitMethod ?? 'Split Method',
                style: AppTypography.h3,
              ),
              const SizedBox(height: 10),
              SegmentedButton<SplitMethod>(
                segments: [
                  ButtonSegment(
                    value: SplitMethod.equal,
                    label: Text(l10n?.splitEqual ?? 'Equally'),
                  ),
                  ButtonSegment(
                    value: SplitMethod.custom,
                    label: Text(l10n?.splitCustom ?? 'Exact'),
                  ),
                  ButtonSegment(
                    value: SplitMethod.percentage,
                    label: Text(l10n?.splitPercentage ?? '%'),
                  ),
                ],
                selected: {_splitMethod},
                onSelectionChanged: (set) {
                  setState(() => _splitMethod = set.first);
                },
              ),
              const SizedBox(height: 16),

              // CUSTOM / PERCENTAGE ALLOCATION INPUTS
              if (_splitMethod == SplitMethod.custom) ...[
                DenkCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: widget.members
                        .where((m) => _selectedParticipants.contains(m.uid))
                        .map((m) {
                          final controller = _customSplitControllers[m.uid]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.displayName,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: TextField(
                                    controller: controller,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.right,
                                    style: AppTypography.monetary(fontSize: 15),
                                    decoration: InputDecoration(
                                      prefixText: _currency.symbol,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ] else if (_splitMethod == SplitMethod.percentage) ...[
                DenkCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: widget.members
                        .where((m) => _selectedParticipants.contains(m.uid))
                        .map((m) {
                          final controller = _pctControllers[m.uid]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.displayName,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    controller: controller,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.right,
                                    style: AppTypography.monetary(fontSize: 15),
                                    decoration: const InputDecoration(
                                      suffixText: '%',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              DenkButton(
                label: widget.initialExpense != null
                    ? (l10n?.commonSave ?? 'Save Changes')
                    : (l10n?.addExpense ?? 'Add Expense'),
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
