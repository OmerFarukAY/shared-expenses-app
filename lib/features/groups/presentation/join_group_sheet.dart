import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/errors/error_localizer.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/invite_code_generator.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
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
  JoinRequestModel? _existingRequest;
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
        JoinRequestModel? existingRequest;
        final user = await ref.read(userProfileControllerProvider.future);
        if (user != null) {
          existingRequest = await repo.getJoinRequest(
            groupId: group.id,
            uid: user.uid,
          );
        }
        if (mounted) {
          setState(() {
            _previewGroup = group;
            _existingRequest = existingRequest;
            _errorText = null;
          });
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _previewGroup = null;
            _existingRequest = null;
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
      if (_previewGroup != null || _existingRequest != null) {
        setState(() {
          _previewGroup = null;
          _existingRequest = null;
        });
      }
    }
  }

  void _submitJoinRequest() async {
    final user = await ref.read(userProfileControllerProvider.future);
    if (!mounted || user == null || _previewGroup == null) return;

    if (_existingRequest != null && _existingRequest!.isLimitReached) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _errorText =
            l10n?.joinRequestLimitReached ??
            'Bu gruba katılma sınırınızı doldurdunuz';
      });
      return;
    }

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                  l10n?.joinGroup ?? 'Join Group',
                  style: AppTypography.h2.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_requestSubmitted) ...[
              DenkCard(
                backgroundColor: isDark
                    ? AppColors.positive.withValues(alpha: 0.12)
                    : AppColors.positiveLight,
                borderColor: isDark
                    ? AppColors.positive.withValues(alpha: 0.35)
                    : AppColors.positive.withValues(alpha: 0.3),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.positive.withValues(alpha: 0.2)
                            : AppColors.positive,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: isDark ? AppColors.positive : Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n?.joinRequestSentTitle ?? 'Request Sent',
                      style: AppTypography.h3.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.joinRequestSentSubtitle(
                            _previewGroup?.name ?? 'the group',
                          ) ??
                          'Your request to join has been submitted. You will be able to access the group once an owner approves it.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
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
                autofocus: false,
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
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: isDark ? 0.35 : 0.5),
                  borderColor: theme.colorScheme.outlineVariant
                      .withValues(alpha: isDark ? 0.3 : 0.5),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _previewGroup!.name,
                              style: AppTypography.h3.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_previewGroup!.memberCount} ${l10n?.membersLabel ?? "members"} • ${_previewGroup!.defaultCurrency}',
                              style: AppTypography.bodySmall.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_existingRequest != null && _existingRequest!.isLimitReached) ...[
                  const SizedBox(height: 14),
                  DenkCard(
                    backgroundColor: isDark
                        ? AppColors.negative.withValues(alpha: 0.12)
                        : AppColors.negativeLight,
                    borderColor: isDark
                        ? AppColors.negative.withValues(alpha: 0.4)
                        : AppColors.negative.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.negative.withValues(alpha: 0.2)
                                : AppColors.negative.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.block_rounded,
                            color: AppColors.negative,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.joinRequestLimitReached ??
                                    'Bu gruba katılma sınırınızı doldurdunuz',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.negative,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_existingRequest!.rejectionCount}/3 ${l10n?.joinRequestAttemptsUsed(_existingRequest!.rejectionCount) != null ? "" : "attempts used"}',
                                style: AppTypography.caption.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_existingRequest != null && _existingRequest!.isPending) ...[
                  const SizedBox(height: 14),
                  DenkCard(
                    backgroundColor: isDark
                        ? const Color(0xFFFBBF24).withValues(alpha: 0.12)
                        : const Color(0xFFFEF3C7),
                    borderColor: isDark
                        ? const Color(0xFFFBBF24).withValues(alpha: 0.35)
                        : const Color(0xFFFCD34D),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          color: isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n?.pendingApprovalCardSubtitle ??
                                'Waiting for group owner approval.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFFB45309),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_existingRequest != null && _existingRequest!.isRejected) ...[
                  const SizedBox(height: 14),
                  DenkCard(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: isDark ? 0.3 : 0.5),
                    borderColor: theme.colorScheme.outlineVariant
                        .withValues(alpha: isDark ? 0.25 : 0.4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n?.joinRequestAttemptsUsed(
                                  _existingRequest!.rejectionCount,
                                ) ??
                                'Önceki talebiniz reddedildi (${_existingRequest!.rejectionCount}/3 hak kullanıldı). Tekrar katılma talebi gönderebilirsiniz.',
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_existingRequest != null && _existingRequest!.isLimitReached)
                  DenkButton(
                    label: l10n?.joinRequestLimitReached ??
                        'Bu gruba katılma sınırınızı doldurdunuz',
                    onPressed: null,
                  )
                else if (_existingRequest != null && _existingRequest!.isPending)
                  DenkButton(
                    label: l10n?.joinRequestPending ?? 'Pending Approval',
                    onPressed: null,
                  )
                else
                  DenkButton(
                    label: _existingRequest != null &&
                            _existingRequest!.isRejected
                        ? (l10n?.requestToJoinAgain ?? 'Tekrar İstek Gönder')
                        : '${l10n?.requestToJoinButton ?? "Request to Join"} ${_previewGroup!.name}',
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
