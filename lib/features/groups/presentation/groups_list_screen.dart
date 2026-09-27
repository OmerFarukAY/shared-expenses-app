import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/presentation/create_group_sheet.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/group_dashboard_screen.dart';
import 'package:denk/features/groups/presentation/join_group_sheet.dart';
import 'package:denk/features/settings/presentation/settings_screen.dart';
import 'package:denk/l10n/l10n.dart';

class GroupsListScreen extends ConsumerWidget {
  final ValueChanged<GroupModel>? onGroupSelected;

  const GroupsListScreen({super.key, this.onGroupSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groupsAsync = ref.watch(userGroupsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const DenkLogo(size: 28, showBackground: false),
            const SizedBox(width: 10),
            Text(l10n?.appName ?? 'Denk', style: AppTypography.h2),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n?.joinGroup ?? 'Join Group',
            icon: const Icon(Icons.key_rounded, size: 20),
            onPressed: () => JoinGroupSheet.show(context),
          ),
          IconButton(
            tooltip: l10n?.createGroup ?? 'Create Group',
            icon: const Icon(Icons.add_rounded, size: 24),
            onPressed: () => CreateGroupSheet.show(context),
          ),
          IconButton(
            tooltip: l10n?.settingsTitle ?? 'Settings',
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DenkEmptyState(
                      icon: Icons.group_add_outlined,
                      title: l10n?.noGroupsTitle ?? 'No groups yet',
                      subtitle:
                          l10n?.noGroupsSubtitle ??
                          'Create a group or enter an invite code to start sharing expenses.',
                      actionLabel: l10n?.createGroup ?? 'Create Group',
                      onAction: () => CreateGroupSheet.show(context),
                    ),
                    const SizedBox(height: 8),
                    DenkButton(
                      label: l10n?.joinGroup ?? 'Join with Code',
                      variant: DenkButtonVariant.secondary,
                      onPressed: () => JoinGroupSheet.show(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupCard(
                group: group,
                onTap: () {
                  ref.read(selectedGroupIdProvider.notifier).state = group.id;
                  if (onGroupSelected != null) {
                    onGroupSelected!(group);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupDashboardScreen(group: group),
                      ),
                    );
                  }
                },
              );
            },
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

    return DenkCard(
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 2),
                    Text(
                      '${group.memberCount} ${group.memberCount == 1 ? "member" : "members"} • ${group.defaultCurrency}',
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
                        'Copy',
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
    );
  }
}
