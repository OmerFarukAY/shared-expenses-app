import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
import 'package:denk/features/groups/presentation/create_group_sheet.dart';
import 'package:denk/features/groups/presentation/group_action_sheet.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/group_dashboard_screen.dart';
import 'package:denk/features/groups/presentation/join_group_sheet.dart';
import 'package:denk/features/settings/presentation/settings_screen.dart';
import 'package:denk/l10n/l10n.dart';

class GroupsListScreen extends ConsumerWidget {
  final bool isTab;
  final ValueChanged<GroupModel>? onGroupSelected;

  const GroupsListScreen({super.key, this.onGroupSelected, this.isTab = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groupsAsync = ref.watch(userGroupsStreamProvider);
    final userRequestsAsync = ref.watch(userJoinRequestsStreamProvider);

    final pendingRequests =
        userRequestsAsync.asData?.value
            .where((r) => r.status == JoinRequestStatus.pending)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const DenkLogo(size: 32, showBackground: false),
        actions: [
          if (!NativeLiquidGlassUtils.supportsLiquidGlass || !isTab) ...[
            IconButton(
              tooltip: l10n?.createGroup ?? 'Group Actions',
              icon: const Icon(Icons.add_rounded, size: 24),
              onPressed: () => GroupActionSheet.show(context),
            ),
            if (!isTab)
              IconButton(
                tooltip: l10n?.settingsTitle ?? 'Settings',
                icon: const Icon(Icons.settings_outlined, size: 20),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    AppColors.darkBg,
                    AppColors.darkSurfaceSubtle.withValues(alpha: 0.3),
                  ]
                : [
                    AppColors.lightBg,
                    const Color(0xFFF8FAFC),
                  ],
          ),
        ),
        child: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty && pendingRequests.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.space_dashboard_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n?.noGroupsTitle ?? 'Welcome to Denk',
                      textAlign: TextAlign.center,
                      style: AppTypography.h1.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.noGroupsSubtitle ??
                          'Create a group or join an existing one to start splitting expenses.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _DashboardActionCard(
                      icon: Icons.group_add_rounded,
                      title: l10n?.createGroup ?? 'Create a New Group',
                      subtitle: l10n?.dashboardCreateGroupSubtitle ?? 'Start tracking shared expenses',
                      isPrimary: true,
                      onTap: () => CreateGroupSheet.show(context),
                    ),
                    const SizedBox(height: 16),
                    _DashboardActionCard(
                      icon: Icons.key_rounded,
                      title: l10n?.joinGroup ?? 'Join with Invite Code',
                      subtitle: l10n?.dashboardJoinGroupSubtitle ?? 'Enter a code from a friend',
                      isPrimary: false,
                      onTap: () => JoinGroupSheet.show(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, isTab ? 116 : 16),
            children: [
              if (pendingRequests.isNotEmpty) ...[
                _PendingRequestsSection(
                  requests: pendingRequests,
                  onCancel: (req) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          l10n?.cancelRequestButton ?? 'Cancel Request',
                        ),
                        content: Text(
                          l10n?.pendingApprovalCardSubtitle ??
                              'Waiting for group owner approval.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(l10n?.commonCancel ?? 'Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(
                              l10n?.commonDelete ?? 'Delete',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref
                          .read(groupRepositoryProvider)
                          .cancelJoinRequest(
                            groupId: req.groupId,
                            uid: req.uid,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.joinRequestCancelled ??
                                  'Join request cancelled.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          l10n?.noGroupsTitle ?? 'No joined groups yet',
                          style: AppTypography.h3,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.pendingApprovalCardSubtitle ??
                              'Waiting for group owner approval.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...groups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GroupCard(
                      group: group,
                      onTap: () {
                        ref.read(selectedGroupIdProvider.notifier).state =
                            group.id;
                        if (onGroupSelected != null) {
                          onGroupSelected!(group);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  GroupDashboardScreen(group: group),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: DenkLoadingView()),
        error: (err, _) => Center(
          child: DenkErrorView(
            message: err.toString(),
            onRetry: () => ref.refresh(userGroupsStreamProvider),
          ),
        ),
        ),
      ),
    );
  }
}

class _PendingRequestsSection extends StatelessWidget {
  final List<JoinRequestModel> requests;
  final ValueChanged<JoinRequestModel> onCancel;

  const _PendingRequestsSection({
    required this.requests,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.pending_actions_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.pendingApprovalCardTitle ?? 'Pending Approval',
              style: AppTypography.h3.copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...requests.map((req) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.joinRequestPending ?? 'Pending Approval',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.pendingApprovalCardSubtitle ??
                            'Waiting for group owner approval.',
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onCancel(req),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n?.cancelRequestButton ?? 'Cancel',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final memberText =
        '${group.memberCount} ${l10n?.membersLabel ?? "members"} • ${group.defaultCurrency}';

    return Semantics(
      button: true,
      label: '${group.name}, $memberText',
      child: DenkCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: AppTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memberText,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invite Code: ${group.inviteCode}',
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: group.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.inviteCodeCopied ?? 'Invite code copied',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n?.copyAction ?? 'Copy',
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color bgColor = isPrimary 
        ? theme.colorScheme.primary 
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
        
    final Color textColor = isPrimary 
        ? theme.colorScheme.onPrimary 
        : theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: !isPrimary ? Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ) : null,
        boxShadow: !isDark && isPrimary ? [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: isPrimary ? Colors.white.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.05),
          splashColor: isPrimary ? Colors.white.withValues(alpha: 0.2) : theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPrimary 
                        ? Colors.white.withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h3.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isPrimary 
                        ? Colors.white.withValues(alpha: 0.15) 
                        : (isDark ? AppColors.darkBg : AppColors.lightBg),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: isPrimary ? Colors.white : textColor.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
