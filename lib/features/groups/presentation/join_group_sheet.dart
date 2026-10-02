import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/errors/error_localizer.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/invite_code_generator.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/l10n/l10n.dart';

class JoinGroupSheet extends ConsumerStatefulWidget {
  const JoinGroupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const JoinGroupSheet(),
    );
  }

  @override
  ConsumerState<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends ConsumerState<JoinGroupSheet> {
  final _codeController = TextEditingController();
  GroupModel? _previewGroup;
  String? _errorText;
  bool _isSearching = false;
  bool _isRequesting = false;
  bool _requestSubmitted = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) async {
    final clean = InviteCodeGenerator.sanitize(value);
    if (_errorText != null) {
      setState(() => _errorText = null);
    }

    if (InviteCodeGenerator.isValidFormat(clean)) {
      setState(() => _isSearching = true);
      try {
        final repo = ref.read(groupRepositoryProvider);
        final group = await repo.resolveInviteCode(clean);
        if (mounted) {
          setState(() {
            _previewGroup = group;
            _errorText = null;
          });
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _previewGroup = null;
            _errorText =
                l10n?.invalidOrInactiveInvite ??
                'Invite code not found or inactive';
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    } else {
      if (_previewGroup != null) {
        setState(() => _previewGroup = null);
      }
    }
  }

  void _submitJoinRequest() async {
    final user = ref.read(userProfileControllerProvider).value;
    if (user == null || _previewGroup == null) return;

    setState(() => _isRequesting = true);

    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.createJoinRequest(
        inviteCode: _previewGroup!.inviteCode,
        user: user,
      );

      if (mounted) {
        setState(() {
          _requestSubmitted = true;
          _errorText = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = context.localizedErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
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
                Text(l10n?.joinGroup ?? 'Join Group', style: AppTypography.h2),
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
            if (_requestSubmitted) ...[
              DenkCard(
                backgroundColor: AppColors.positiveLight,
                borderColor: AppColors.positive.withValues(alpha: 0.3),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.positive,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n?.joinRequestSentTitle ?? 'Request Sent',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.joinRequestSentSubtitle(
                            _previewGroup?.name ?? 'the group',
                          ) ??
                          'Your request to join has been submitted. You will be able to access the group once an owner approves it.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DenkButton(
                label: l10n?.commonDone ?? 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ] else ...[
              DenkTextField(
                controller: _codeController,
                label: l10n?.inviteCodeLabel ?? 'Invite Code',
                hintText: l10n?.inviteCodeHint ?? 'e.g. DNK-7X2K',
                errorText: _errorText,
                autofocus: true,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                onChanged: _onCodeChanged,
              ),
              if (_isSearching) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
              if (_previewGroup != null) ...[
                const SizedBox(height: 16),
                DenkCard(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.06),
                  borderColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_previewGroup!.name, style: AppTypography.h3),
                            const SizedBox(height: 2),
                            Text(
                              '${_previewGroup!.memberCount} ${l10n?.membersLabel ?? "members"} • ${_previewGroup!.defaultCurrency}',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DenkButton(
                  label:
                      '${l10n?.requestToJoinButton ?? "Request to Join"} ${_previewGroup!.name}',
                  isLoading: _isRequesting,
                  onPressed: _submitJoinRequest,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
