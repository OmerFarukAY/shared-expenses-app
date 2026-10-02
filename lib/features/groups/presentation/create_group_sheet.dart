import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:denk/core/errors/error_localizer.dart';
import 'package:denk/core/theme/app_haptics.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/l10n/l10n.dart';

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateGroupSheet(),
    );
  }

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 60) {
      setState(() {
        _errorText = l10n?.errorGroupNameLength ?? 'Group name must be between 1 and 60 characters';
      });
      return;
    }

    final user = ref.read(userProfileControllerProvider).value;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final repo = ref.read(groupRepositoryProvider);
      final newGroup = await repo.createGroup(
        name: name,
        description: _descController.text.trim(),
        defaultCurrency: user.preferredCurrency,
        creator: user,
      );

      ref.read(selectedGroupIdProvider.notifier).state = newGroup.id;
      AppHaptics.medium();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = context.localizedErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: bottomInset + 24,
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.createGroup ?? 'Create Group',
                style: AppTypography.h2,
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DenkTextField(
            controller: _nameController,
            label: l10n?.groupNameLabel ?? 'Group Name',
            hintText: l10n?.groupNameHint ?? 'e.g. Ankara Flat, Berlin Trip',
            errorText: _errorText,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
          const SizedBox(height: 16),

          DenkButton(
            label: l10n?.commonSave ?? 'Create Group',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
      ),
    );
  }
}
