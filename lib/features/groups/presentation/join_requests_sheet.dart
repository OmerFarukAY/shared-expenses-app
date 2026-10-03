import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:denk/app.dart';
import 'package:denk/core/errors/error_localizer.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/l10n/l10n.dart';

class JoinRequestsSheet extends ConsumerWidget {
  final GroupModel group;

  const JoinRequestsSheet({super.key, required this.group});

  static Future<void> show({
    required BuildContext context,
    required GroupModel group,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => JoinRequestsSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentUser = ref.watch(userProfileControllerProvider).value;
    final requestsAsync = ref.watch(groupJoinRequestsStreamProvider(group.id));

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.joinRequestsTitle ?? 'Join Requests',
                style: AppTypography.h2,
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 40,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n?.noPendingRequests ?? 'No pending requests',
                          style: AppTypography.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final req = requests[index];
                  final dateFormatted = DateFormat.MMMd().format(req.createdAt);

                  return DenkCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            req.displayName.isNotEmpty
                                ? req.displayName[0].toUpperCase()
                                : '?',
                            style: AppTypography.h3.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req.displayName, style: AppTypography.h3),
                              const SizedBox(height: 2),
                              Text(
                                dateFormatted,
                                style: AppTypography.caption.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n?.rejectButton ?? 'Reject',
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.negative,
                              ),
                              onPressed: () async {
                                if (currentUser == null) return;
                                try {
                                  final repo = ref.read(
                                    groupRepositoryProvider,
                                  );
                                  await repo.rejectJoinRequest(
                                    groupId: group.id,
                                    requestUid: req.uid,
                                    rejectedBy: currentUser.uid,
                                  );
                                  if (context.mounted &&
                                      requests.length <= 1 &&
                                      Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }

                                  final messenger =
                                      rootScaffoldMessengerKey.currentState ??
                                          (context.mounted
                                              ? ScaffoldMessenger.maybeOf(context)
                                              : null);
                                  messenger?.clearSnackBars();
                                  messenger?.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n?.joinRequestRejectedSnackbar ??
                                            'Talep reddedildi',
                                      ),
                                      duration: const Duration(seconds: 4),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: l10n?.undoAction ?? 'Geri Al',
                                        textColor:
                                            theme.colorScheme.inversePrimary,
                                        onPressed: () async {
                                          try {
                                            await repo.undoRejectJoinRequest(
                                              groupId: group.id,
                                              requestUid: req.uid,
                                            );
                                          } catch (e) {
                                            final currentCtx =
                                                rootScaffoldMessengerKey
                                                    .currentContext;
                                            final errorMsg =
                                                currentCtx != null &&
                                                        currentCtx.mounted
                                                    ? currentCtx
                                                        .localizedErrorMessage(
                                                          e,
                                                        )
                                                    : e.toString();
                                            final errMessenger =
                                                rootScaffoldMessengerKey
                                                        .currentState ??
                                                    (context.mounted
                                                        ? ScaffoldMessenger
                                                            .maybeOf(context)
                                                        : null);
                                            errMessenger?.showSnackBar(
                                              SnackBar(
                                                content: Text(errorMsg),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  final currentCtx =
                                      rootScaffoldMessengerKey.currentContext;
                                  final errorMsg =
                                      currentCtx != null && currentCtx.mounted
                                          ? currentCtx.localizedErrorMessage(e)
                                          : e.toString();
                                  final errMessenger =
                                      rootScaffoldMessengerKey.currentState ??
                                          (context.mounted
                                              ? ScaffoldMessenger.maybeOf(context)
                                              : null);
                                  errMessenger?.showSnackBar(
                                    SnackBar(
                                      content: Text(errorMsg),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: l10n?.approveButton ?? 'Approve',
                              icon: const Icon(
                                Icons.check_rounded,
                                color: AppColors.positive,
                              ),
                              onPressed: () async {
                                if (currentUser == null) return;
                                try {
                                  final repo = ref.read(
                                    groupRepositoryProvider,
                                  );
                                  await repo.approveJoinRequest(
                                    groupId: group.id,
                                    request: req,
                                    approvedBy: currentUser.uid,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(context.localizedErrorMessage(e))),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: DenkLoadingView()),
            error: (err, _) => Center(
              child: DenkErrorView(
                message: err.toString(),
                onRetry: () =>
                    ref.refresh(groupJoinRequestsStreamProvider(group.id)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
