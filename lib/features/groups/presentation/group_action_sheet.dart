import 'package:flutter/material.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/features/groups/presentation/create_group_sheet.dart';
import 'package:denk/features/groups/presentation/join_group_sheet.dart';
import 'package:denk/l10n/l10n.dart';

enum GroupActionType { create, join }

/// Action bottom sheet allowing users to choose between creating a new group
/// or joining an existing one with an invite code.
class GroupActionSheet extends StatelessWidget {
  const GroupActionSheet({super.key});

  /// Presents the bottom sheet and opens the selected creation/joining modal.
  static Future<void> show(BuildContext context) async {
    final action = await showModalBottomSheet<GroupActionType>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const GroupActionSheet(),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case GroupActionType.create:
        CreateGroupSheet.show(context);
        break;
      case GroupActionType.join:
        JoinGroupSheet.show(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.groupActionsTitle ?? 'Group Actions',
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
            _ActionTile(
              icon: Icons.group_add_rounded,
              iconColor: theme.colorScheme.primary,
              iconBgColor: theme.colorScheme.primary.withValues(
                alpha: isDark ? 0.2 : 0.1,
              ),
              title: l10n?.createGroup ?? 'Create Group',
              subtitle: l10n?.groupActionsCreateSubtitle ?? 'Start a new group and split expenses with friends',
              onTap: () => Navigator.of(context).pop(GroupActionType.create),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.key_rounded,
              iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              iconBgColor: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                  .withValues(alpha: isDark ? 0.2 : 0.1),
              title: l10n?.joinGroup ?? 'Join Group',
              subtitle: l10n?.groupActionsJoinSubtitle ?? 'Enter an invite code to join an existing group',
              onTap: () => Navigator.of(context).pop(GroupActionType.join),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          highlightColor: iconColor.withValues(alpha: 0.05),
          splashColor: iconColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor.withValues(alpha: isDark ? 0.25 : 0.15),
                        iconColor.withValues(alpha: isDark ? 0.1 : 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h3.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
