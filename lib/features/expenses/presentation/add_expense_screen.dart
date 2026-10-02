import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_haptics.dart';
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
  bool _isSplitExpanded = false;
  String? _singlePayerUid;
  final Map<String, TextEditingController> _payerControllers = {};

  // Participants
  final Set<String> _selectedParticipants = {};

  // Custom / Percentage split controllers
  final Map<String, TextEditingController> _customSplitControllers = {};
  final Map<String, TextEditingController> _pctControllers = {};

  String? _errorMessage;
  bool _isSubmitting = false;

  late List<GroupMember> _activeMembers;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileControllerProvider).value;
    final edit = widget.initialExpense;

    if (edit != null) {
      _activeMembers = widget.members.where((m) => 
        !m.hasLeft || 
        edit.participants.contains(m.uid) || 
        edit.payers.containsKey(m.uid)
      ).toList();
    } else {
      _activeMembers = widget.members.where((m) => !m.hasLeft).toList();
    }

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
        for (final m in _activeMembers) {
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
      for (final m in _activeMembers) {
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
          (_activeMembers.isNotEmpty ? _activeMembers.first.uid : null);

      // Default: all group members participate
      for (final m in _activeMembers) {
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
    final l10n = AppLocalizations.of(context);
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
      for (final m in _activeMembers) {
        final text = _payerControllers[m.uid]?.text ?? '';
        final amt = _currency.parseToMinor(text) ?? 0;
        if (amt > 0) {
          payers[m.uid] = amt;
          sumPayers += amt;
        } else if (amt < 0) {
           setState(() => _errorMessage = 'Amounts must be positive.');
           return;
        }
      }
      if (payers.length > 5) {
        setState(() => _errorMessage = 'Too many payers (max 5).');
        return;
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
          if (amt > 0) {
             splits[uid] = amt;
             sumCustom += amt;
          } else if (amt < 0) {
             setState(() => _errorMessage = 'Amounts must be positive.');
             return;
          }
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
          final pct = double.tryParse(text) ?? 0.0;
          if (pct > 0) {
             pcts[uid] = pct;
          } else if (pct < 0) {
             setState(() => _errorMessage = 'Amounts must be positive.');
             return;
          }
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
    
    // Filter splits > 0 and update participants to only those who actually pay
    final int originalParticipantCount = _selectedParticipants.length;
    splits.removeWhere((key, value) => value <= 0);
    final finalParticipants = splits.keys.toList();
    if (finalParticipants.isEmpty) {
        setState(() => _errorMessage = 'At least one participant must have a share > 0.');
        return;
    }
    if (finalParticipants.length > 20) {
        setState(() => _errorMessage = 'Too many participants (max 20).');
        return;
    }

    final int removedCount = originalParticipantCount - finalParticipants.length;

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
      participants: finalParticipants,
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
        AppHaptics.medium();
        if (removedCount > 0) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n?.expenseZeroShareRemoved(removedCount) ?? '$removedCount participant(s) with 0 share removed.')),
           );
        }
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


  String _getSplitSummaryText(AppLocalizations? l10n) {
    final count = _selectedParticipants.length;
    if (_splitMethod == SplitMethod.equal) {
      return l10n?.expenseSplitSummaryEqually(count) ?? 'Equally · $count people ›';
    } else if (_splitMethod == SplitMethod.custom) {
      return l10n?.expenseSplitSummaryCustom(count) ?? 'Custom · $count people ›';
    } else {
      return l10n?.expenseSplitSummaryPercentage(count) ?? 'Percentage · $count people ›';
    }
  }

  String _getLiveSummaryText(AppLocalizations? l10n) {
    final count = _selectedParticipants.length;
    final total = _parsedTotalMinor;
    final formattedTotal = _currency.formatMinor(total);
    if (!_isMultiplePayers && _singlePayerUid != null) {
      final payerName = _activeMembers.firstWhere((m) => m.uid == _singlePayerUid, orElse: () => _activeMembers.first).displayName;
      return l10n?.expenseLiveSummary(payerName, formattedTotal, count) ?? '$payerName paid $formattedTotal · Split among $count people';
    } else {
      return l10n?.expenseLiveSummaryMultiple(formattedTotal, count) ?? 'Multiple paid $formattedTotal · Split among $count people';
    }
  }

  String? _getLiveErrorText(AppLocalizations? l10n) {
    final total = _parsedTotalMinor;
    if (total <= 0) return null;

    if (_isMultiplePayers) {
      int sum = 0;
      int count = 0;
      for (final m in _activeMembers) {
        final amt = _currency.parseToMinor(_payerControllers[m.uid]?.text ?? '') ?? 0;
        if (amt > 0) {
          sum += amt;
          count++;
        } else if (amt < 0) {
          return l10n?.errorNegativeAmount ?? 'Amounts must be positive';
        }
      }
      if (count > 5) {
        return l10n?.errorTooManyPayers ?? 'Too many payers (max 5)';
      }
      if (sum != total) {
        final diff = total - sum;
        final formattedDiff = _currency.formatMinor(diff.abs());
        return diff > 0 
           ? (l10n?.expenseLiveSummaryRemaining(formattedDiff) ?? '$formattedDiff remaining')
           : (l10n?.expenseLiveSummaryOver(formattedDiff) ?? '$formattedDiff over');
      }
    }

    if (_splitMethod == SplitMethod.custom) {
      int sum = 0;
      int count = 0;
      for (final uid in _selectedParticipants) {
        final amt = _currency.parseToMinor(_customSplitControllers[uid]?.text ?? '') ?? 0;
        if (amt > 0) {
          sum += amt;
          count++;
        } else if (amt < 0) {
          return l10n?.errorNegativeAmount ?? 'Amounts must be positive';
        }
      }
      if (count > 20) {
        return l10n?.errorTooManyParticipants ?? 'Too many participants (max 20)';
      }
      if (sum != total) {
        final diff = total - sum;
        final formattedDiff = _currency.formatMinor(diff.abs());
        return diff > 0 
           ? (l10n?.expenseLiveSummaryRemaining(formattedDiff) ?? '$formattedDiff remaining')
           : (l10n?.expenseLiveSummaryOver(formattedDiff) ?? '$formattedDiff over');
      }
    }
    
    if (_splitMethod == SplitMethod.percentage) {
      int count = 0;
      for (final uid in _selectedParticipants) {
        final pct = double.tryParse(_pctControllers[uid]?.text ?? '') ?? 0;
        if (pct > 0) {
          count++;
        } else if (pct < 0) {
          return l10n?.errorNegativeAmount ?? 'Amounts must be positive';
        }
      }
      if (count > 20) {
         return l10n?.errorTooManyParticipants ?? 'Too many participants (max 20)';
      }
    } else if (_splitMethod == SplitMethod.equal) {
       if (_selectedParticipants.length > 20) {
          return l10n?.errorTooManyParticipants ?? 'Too many participants (max 20)';
       }
    }

    return null;
  }

  bool _isSaveDisabled(AppLocalizations? l10n) {
    return _getLiveErrorText(l10n) != null || _parsedTotalMinor <= 0 || _selectedParticipants.isEmpty || _isSubmitting;
  }
  

  String _getDisplayName(GroupMember m, BuildContext context) {
    return m.hasLeft
        ? m.displayName + AppLocalizations.of(context)!.memberLeftSuffix
        : m.displayName;
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
                    DropdownButtonHideUnderline(
                      child: DropdownButton<Currency>(
                        value: _currency,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        style: AppTypography.monetary(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                        items: Currency.supportedCurrencies
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.code),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            AppHaptics.selection();
                            setState(() => _currency = val);
                          }
                        },
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
                      onTap: () {
                        AppHaptics.selection();
                        setState(() => _category = cat);
                      },
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
              Text(
                l10n?.expensePaidBy ?? 'Who paid?',
                style: AppTypography.h3,
              ),
              const SizedBox(height: 8),
              if (!_isMultiplePayers) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _activeMembers.map((m) {
                    final isSelected = m.uid == _singlePayerUid;
                    return ChoiceChip(
                      label: Text(_getDisplayName(m, context)),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _singlePayerUid = m.uid),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _isMultiplePayers = true),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n?.expensePaidByMultipleAdvanced ?? 'Multiple people paid...',
                      style: AppTypography.labelMedium.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.expensePaidByMultiple ?? 'Multiple people paid',
                      style: AppTypography.h3,
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isMultiplePayers = false),
                      child: Text(
                        l10n?.expenseSwitchToSinglePayer ?? 'Switch to Single Payer',
                        style: AppTypography.labelMedium.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                DenkCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _activeMembers.map((m) {
                      final controller = _payerControllers[m.uid]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getDisplayName(m, context),
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

              // 4. SPLIT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.expenseSplit ?? 'Split',
                    style: AppTypography.h3,
                  ),
                  if (!_isSplitExpanded)
                    TextButton(
                      onPressed: () => setState(() => _isSplitExpanded = true),
                      child: Text(
                        l10n?.expenseSplitCustomize ?? 'Customize',
                        style: AppTypography.labelMedium.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  if (_isSplitExpanded)
                    TextButton(
                      onPressed: () => setState(() => _isSplitExpanded = false),
                      child: Text(
                        l10n?.commonDone ?? 'Done',
                        style: AppTypography.labelMedium.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              if (!_isSplitExpanded) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setState(() => _isSplitExpanded = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pie_chart_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getSplitSummaryText(l10n),
                            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
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
                          if (_selectedParticipants.length == _activeMembers.length) {
                            _selectedParticipants.clear();
                          } else {
                            for (final m in _activeMembers) {
                              _selectedParticipants.add(m.uid);
                            }
                          }
                        });
                      },
                      child: Text(
                        _selectedParticipants.length == _activeMembers.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: AppTypography.labelMedium.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _activeMembers.map((m) {
                    final isIncluded = _selectedParticipants.contains(m.uid);
                    return FilterChip(
                      label: Text(_getDisplayName(m, context)),
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
                if (_splitMethod == SplitMethod.custom) ...[
                  DenkCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _activeMembers
                          .where((m) => _selectedParticipants.contains(m.uid))
                          .map((m) {
                            final controller = _customSplitControllers[m.uid]!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getDisplayName(m, context),
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
                                      onChanged: (_) => setState(() {}),
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
                      children: _activeMembers
                          .where((m) => _selectedParticipants.contains(m.uid))
                          .map((m) {
                            final controller = _pctControllers[m.uid]!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getDisplayName(m, context),
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
                                      onChanged: (_) => setState(() {}),
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
              ],
              const SizedBox(height: 32),
              // LIVE SUMMARY
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getLiveErrorText(l10n) != null ? AppColors.negativeLight : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _getLiveSummaryText(l10n),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: _getLiveErrorText(l10n) != null ? AppColors.negative : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_getLiveErrorText(l10n) != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getLiveErrorText(l10n)!,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.negative,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DenkButton(
                label: widget.initialExpense != null
                    ? (l10n?.commonSave ?? 'Save Changes')
                    : (l10n?.addExpense ?? 'Add Expense'),
                isLoading: _isSubmitting,
                onPressed: _isSaveDisabled(l10n) ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
