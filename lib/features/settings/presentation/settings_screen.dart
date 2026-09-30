import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/settings/presentation/settings_controller.dart';
import 'package:denk/l10n/l10n.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeleting = false;

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.chooseDisplayName ?? 'Edit Display Name',
          style: AppTypography.h3,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: l10n?.displayNameHint ?? 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.commonCancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.length >= 2 && newName.length <= 50) {
                Navigator.of(ctx).pop();
                try {
                  await ref
                      .read(userProfileControllerProvider.notifier)
                      .updateDisplayName(newName);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
            child: Text(l10n?.commonSave ?? 'Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final currentLocale = ref.read(appLocaleProvider);
    final l10n = AppLocalizations.of(context);

    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'tr', 'name': 'Türkçe'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'it', 'name': 'Italiano'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.settingsLanguage ?? 'Language',
          style: AppTypography.h3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final code = lang['code']!;
            final name = lang['name']!;
            final isSelected = currentLocale?.languageCode == code;

            return ListTile(
              title: Text(name, style: AppTypography.bodyMedium),
              trailing: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                ref.read(appLocaleProvider.notifier).setLocale(Locale(code));
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    final currentMode = ref.read(appThemeModeProvider);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.themeTitle ?? 'Theme', style: AppTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                l10n?.themeSystem ?? 'System Default',
                style: AppTypography.bodyMedium,
              ),
              trailing: currentMode == ThemeMode.system
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                ref
                    .read(appThemeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: Text(
                l10n?.themeLight ?? 'Light',
                style: AppTypography.bodyMedium,
              ),
              trailing: currentMode == ThemeMode.light
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                ref
                    .read(appThemeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: Text(
                l10n?.themeDark ?? 'Dark',
                style: AppTypography.bodyMedium,
              ),
              trailing: currentMode == ThemeMode.dark
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                ref
                    .read(appThemeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyInfoDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.positive),
            const SizedBox(width: 10),
            Text(
              l10n?.settingsPrivacyInfo ?? 'Privacy Architecture',
              style: AppTypography.h3,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n?.privacyCalloutTitle ??
                    'Privacy-First, Data-Minimized Architecture',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '• No email, phone number, or password required.\n'
                '• No advertising identifiers or tracker SDKs.\n'
                '• No device contact book or GPS location permissions.\n'
                '• Authentication uses anonymous Firebase credentials.\n'
                '• Only group members you share your invite code with can view your group expenses.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.commonDone ?? 'Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.settingsDeleteAccount ?? 'Delete Local Account',
          style: AppTypography.h3,
        ),
        content: Text(
          l10n?.settingsDeleteWarning ??
              'This will remove your local anonymous identity on this device. You will lose access to groups unless invited back.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.commonCancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.commonDelete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await ref.read(userProfileControllerProvider.notifier).deleteAccount();
        if (mounted) {
          Navigator.of(context).pop(); // Back to AuthGate
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
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
    final profile = ref.watch(userProfileControllerProvider).value;
    final currentLocale = ref.watch(appLocaleProvider);
    final currentThemeMode = ref.watch(appThemeModeProvider);

    final langName = currentLocale?.languageCode == 'tr'
        ? 'Türkçe'
        : currentLocale?.languageCode == 'es'
        ? 'Español'
        : currentLocale?.languageCode == 'fr'
        ? 'Français'
        : currentLocale?.languageCode == 'it'
        ? 'Italiano'
        : 'English';

    final themeName = currentThemeMode == ThemeMode.light
        ? (l10n?.themeLight ?? 'Light')
        : currentThemeMode == ThemeMode.dark
        ? (l10n?.themeDark ?? 'Dark')
        : (l10n?.themeSystem ?? 'System');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settingsTitle ?? 'Settings', style: AppTypography.h2),
      ),
      body: _isDeleting
          ? const Center(child: DenkLoadingView())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PROFILE SECTION
                  Text(
                    l10n?.settingsProfile ?? 'Profile',
                    style: AppTypography.h3,
                  ),
                  const SizedBox(height: 12),
                  DenkCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              child: Text(
                                (profile?.displayName.isNotEmpty ?? false)
                                    ? profile!.displayName[0].toUpperCase()
                                    : '?',
                                style: AppTypography.h2.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile?.displayName ?? 'Anonymous User',
                                    style: AppTypography.h3,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n?.anonymousAccount ??
                                        'Anonymous Firebase Account',
                                    style: AppTypography.caption.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                if (profile != null) {
                                  _showEditNameDialog(profile.displayName);
                                }
                              },
                            ),
                          ],
                        ),
                        if (profile != null) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'UID: ${profile.uid.substring(0, profile.uid.length > 8 ? 8 : profile.uid.length)}...',
                                style: AppTypography.caption.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: profile.uid),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n?.uidCopiedSnackbar ??
                                            'UID copied to clipboard',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n?.copyId ?? 'Copy ID',
                                  style: AppTypography.caption.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PREFERENCES SECTION
                  Text(
                    l10n?.settingsPreferences ?? 'Preferences',
                    style: AppTypography.h3,
                  ),
                  const SizedBox(height: 12),
                  DenkCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.language_rounded),
                            title: Text(
                              l10n?.settingsLanguage ?? 'Language',
                              style: AppTypography.bodyMedium,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  langName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                            onTap: _showLanguageDialog,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.palette_outlined),
                            title: Text(
                              l10n?.themeTitle ?? 'Theme',
                              style: AppTypography.bodyMedium,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  themeName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                            onTap: _showThemeDialog,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PRIVACY & DATA SECTION
                  Text(
                    l10n?.settingsPrivacy ?? 'Privacy & Data',
                    style: AppTypography.h3,
                  ),
                  const SizedBox(height: 12),
                  DenkCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.positive,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n?.settingsPrivacyInfo ??
                                    'Privacy Information',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _showPrivacyInfoDialog,
                              child: Text(l10n?.readAction ?? 'Read'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.privacyCalloutBody ??
                              'No email, phone, or passwords collected. Only group members can view group balances.',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // DESTRUCTIVE DELETE ACCOUNT CARD
                  DenkCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: AppColors.negative.withValues(alpha: 0.3),
                    backgroundColor: AppColors.negative.withValues(alpha: 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.settingsDeleteAccount ?? 'Delete Local Account',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.negative,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.settingsDeleteWarning ??
                              'This will remove your local anonymous identity on this device. You will lose access to groups unless invited back.',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DenkButton(
                          label:
                              l10n?.settingsDeleteAccount ??
                              'Delete Local Account',
                          variant: DenkButtonVariant.destructive,
                          height: 42,
                          onPressed: _confirmDeleteAccount,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ABOUT & VERSION
                  Center(
                    child: Column(
                      children: [
                        const DenkLogo(size: 36),
                        const SizedBox(height: 8),
                        Text(l10n?.appName ?? 'Denk', style: AppTypography.h3),
                        Text(
                          l10n?.appTagline ?? 'Shared expenses, settled simply',
                          style: AppTypography.caption.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n?.settingsVersion ?? 'Version'} 1.0.0',
                          style: AppTypography.caption.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
