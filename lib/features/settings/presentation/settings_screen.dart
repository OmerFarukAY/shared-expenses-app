import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show GoogleAuthProvider, AppleAuthProvider;
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_haptics.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/domain/account_deletion_service.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/settings/presentation/settings_controller.dart';
import 'package:denk/core/constants/legal_urls.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const SettingsScreen({super.key, this.isTab = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeleting = false;
  bool _isLinking = false;
  bool _isUpdatingName = false;
  bool _isUidCopied = false;
  String? _activeLinkingProvider;

  Future<void> _handleLinkGoogle() async {
    if (_isLinking) return;
    setState(() {
      _isLinking = true;
      _activeLinkingProvider = 'google.com';
    });

    try {
      await ref.read(userProfileControllerProvider.notifier).linkGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.accountLinkingSuccess ??
                  'Account linked successfully!',
            ),
            backgroundColor: AppColors.positive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AuthCancelledException {
      // User cancelled; no action required
    } on AuthConflictException catch (conflict) {
      if (mounted) {
        setState(() {
          _isLinking = false;
          _activeLinkingProvider = null;
        });
        await _showAccountConflictDialog(conflict, isGoogle: true);
      }
    } catch (e) {
      if (mounted) {
        final message = e is AppException
            ? e.message
            : (AppLocalizations.of(context)?.accountLinkErrorGeneric ??
                'Failed to link account. Please try again.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.negative,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLinking = false;
          _activeLinkingProvider = null;
        });
      }
    }
  }

  Future<void> _handleLinkApple() async {
    if (_isLinking) return;
    setState(() {
      _isLinking = true;
      _activeLinkingProvider = 'apple.com';
    });

    try {
      await ref.read(userProfileControllerProvider.notifier).linkApple();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.accountLinkingSuccess ??
                  'Account linked successfully!',
            ),
            backgroundColor: AppColors.positive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AuthCancelledException {
      // User cancelled; no action required
    } on AuthConflictException catch (conflict) {
      if (mounted) {
        setState(() {
          _isLinking = false;
          _activeLinkingProvider = null;
        });
        await _showAccountConflictDialog(conflict, isGoogle: false);
      }
    } on AuthAppleAccountRequiredException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.appleAccountRequired ??
                  e.message,
            ),
            backgroundColor: AppColors.negative,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is AppException
            ? e.message
            : (AppLocalizations.of(context)?.accountLinkErrorGeneric ??
                'Failed to link account. Please try again.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.negative,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLinking = false;
          _activeLinkingProvider = null;
        });
      }
    }
  }

  Future<void> _showAccountConflictDialog(
    AuthConflictException conflict, {
    required bool isGoogle,
  }) async {
    final l10n = AppLocalizations.of(context);

    final switchConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.accountAlreadyInUseTitle ?? 'Account Already Exists',
          style: AppTypography.h3,
        ),
        content: Text(
          l10n?.accountAlreadyInUseBody ??
              'This account is already associated with another Denk profile. Would you like to switch to that account on this device, or keep using your current guest account?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n?.keepCurrentAccountButton ?? 'Keep Guest Account',
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n?.switchAccountButton ?? 'Switch to Existing Account',
            ),
          ),
        ],
      ),
    );

    if (switchConfirmed == true && mounted) {
      setState(() => _isLinking = true);
      try {
        if (conflict.credential != null) {
          await ref
              .read(userProfileControllerProvider.notifier)
              .switchToExistingAccount(conflict.credential!);
        } else {
          await ref
              .read(userProfileControllerProvider.notifier)
              .switchToExistingProvider(
                isGoogle ? GoogleAuthProvider() : AppleAuthProvider(),
              );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.accountSwitchSuccess ??
                    'Switched to existing account.',
              ),
              backgroundColor: AppColors.positive,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.negative,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLinking = false);
        }
      }
    }
  }

  Widget _buildLinkedProviderTile({
    required IconData icon,
    required String title,
    required String? subtitle,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.positive,
            size: 18,
          ),
        ],
      ),
    );
  }

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
                if (mounted) setState(() => _isUpdatingName = true);
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
                } finally {
                  if (mounted) {
                    setState(() => _isUpdatingName = false);
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

  void _showSelectionSheet({
    required String title,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.darkSurface 
                : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkBorder 
                  : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  title,
                  style: AppTypography.h2.copyWith(fontSize: 24),
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 32,
                    left: 24,
                    right: 24,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Material(
                        type: MaterialType.transparency,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: children,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final currentLocale = ref.read(appLocaleProvider);
    final l10n = AppLocalizations.of(context);

    final languages = [
      {'code': null, 'name': l10n?.languageSystem ?? 'System Language'},
      {'code': 'en', 'name': 'English'},
      {'code': 'tr', 'name': 'Türkçe'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'it', 'name': 'Italiano'},
    ];

    _showSelectionSheet(
      title: l10n?.settingsLanguage ?? 'Language',
      children: languages.map((lang) {
        final code = lang['code'];
        final name = lang['name']!;
        final isSelected = currentLocale?.languageCode == code;

        return ListTile(
          title: Text(name, style: AppTypography.bodyMedium),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () {
            ref.read(appLocaleProvider.notifier).setLocale(
              code != null ? Locale(code) : null,
            );
            Navigator.of(context).pop();
          },
        );
      }).toList(),
    );
  }

  void _showThemeDialog() {
    final currentMode = ref.read(appThemeModeProvider);
    final l10n = AppLocalizations.of(context);

    _showSelectionSheet(
      title: l10n?.themeTitle ?? 'Theme',
      children: [
        ListTile(
          title: Text(
            l10n?.themeSystem ?? 'System Default',
            style: AppTypography.bodyMedium,
          ),
          trailing: currentMode == ThemeMode.system
              ? Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () {
            ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.system);
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          title: Text(
            l10n?.themeLight ?? 'Light',
            style: AppTypography.bodyMedium,
          ),
          trailing: currentMode == ThemeMode.light
              ? Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () {
            ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.light);
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          title: Text(
            l10n?.themeDark ?? 'Dark',
            style: AppTypography.bodyMedium,
          ),
          trailing: currentMode == ThemeMode.dark
              ? Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () {
            ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.dark);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _showCurrencyDialog() {
    final profile = ref.read(userProfileControllerProvider).value;
    if (profile == null) return;
    
    final l10n = AppLocalizations.of(context);

    _showSelectionSheet(
      title: (l10n as dynamic).changeCurrency ?? 'Change Currency',
      children: Currency.supportedCurrencies.map((curr) {
        final isSelected = profile.preferredCurrency == curr.code;

        return ListTile(
          title: Text('${curr.code} (${curr.symbol}) — ${curr.name}', style: AppTypography.bodyMedium),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () async {
            try {
              await ref.read(userProfileControllerProvider.notifier).setDisplayName(
                profile.displayName,
                preferredCurrency: curr.code,
                languageCode: profile.languageCode,
              );
              if (mounted) Navigator.of(context).pop();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.negative,
                  ),
                );
              }
            }
          },
        );
      }).toList(),
    );
  }

  Future<void> _launchLegalUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.errorOpeningUrl ??
                    'Could not open link.',
              ),
              backgroundColor: AppColors.negative,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.errorOpeningUrl ??
                  'Could not open link.',
            ),
            backgroundColor: AppColors.negative,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                '• ${l10n?.privacyBullet1 ?? "No email, phone number, or password required."}\n'
                '• ${l10n?.privacyBullet2 ?? "No advertising identifiers or tracker SDKs."}\n'
                '• ${l10n?.privacyBullet3 ?? "No device contact book or GPS location permissions."}\n'
                '• ${l10n?.privacyBullet4 ?? "Authentication uses anonymous Firebase credentials."}\n'
                '• ${l10n?.privacyBullet5 ?? "Only group members you share your invite code with can view your group expenses."}',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _launchLegalUrl(LegalUrls.privacyPolicy);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        l10n?.privacyPolicyTitle ?? 'Privacy Policy',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: AppColors.primary500,
                      ),
                    ],
                  ),
                ),
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

  Future<void> _handleDeleteAccount() async {
    if (_isDeleting) return;
    final l10n = AppLocalizations.of(context);

    // Step 1: Show initial confirmation
    final initialConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.deleteAccountConfirmTitle ?? 'Permanently Delete Account?',
          style: AppTypography.h3,
        ),
        content: Text(
          l10n?.deleteAccountConfirmBody ??
              'This action cannot be undone. Your expense history will be preserved but your name will be anonymized. Groups where you are the sole owner will be deleted.',
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
            child: Text(l10n?.commonConfirm ?? 'Confirm'),
          ),
        ],
      ),
    );

    if (initialConfirm != true || !mounted) return;
    AppHaptics.heavy();

    // Step 2: Check for ownership blocks
    List<OwnedGroupBlock> blocks;
    try {
      blocks = await ref
          .read(userProfileControllerProvider.notifier)
          .analyzeOwnershipBlocks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.negative,
          ),
        );
      }
      return;
    }

    // Step 3: If blocks exist, show ownership transfer dialog
    if (blocks.isNotEmpty && mounted) {
      final transferred = await _showOwnershipTransferRequired(blocks);
      if (!transferred || !mounted) return;
    }

    // Step 4: Execute deletion
    if (!mounted) return;
    setState(() => _isDeleting = true);
    try {
      await ref
          .read(userProfileControllerProvider.notifier)
          .deleteAccountFull();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.deleteAccountSuccess ?? 'Your account has been deleted.',
            ),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } on AuthReauthRequiredException catch (_) {
      if (mounted) {
        setState(() => _isDeleting = false);
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              l10n?.commonError ?? 'Authentication Required',
              style: AppTypography.h3,
            ),
            content: Text(
              l10n?.deleteAccountReauthRequired ??
                  'Please sign in again to confirm account deletion.',
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

  Future<bool> _showOwnershipTransferRequired(
    List<OwnedGroupBlock> blocks,
  ) async {
    final l10n = AppLocalizations.of(context);
    final resolvedGroupIds = <String>{};
    bool? result;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            l10n?.deleteAccountOwnershipRequired ??
                'Ownership Transfer Required',
            style: AppTypography.h3,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.deleteAccountOwnershipRequiredBody ??
                      'You own the following group(s) with other members. Please transfer ownership before deleting your account.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                ...blocks.map((block) {
                  final isResolved = resolvedGroupIds.contains(block.group.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        isResolved
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.positive,
                                size: 20,
                              )
                            : const Icon(Icons.group_rounded, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            block.group.name,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!isResolved)
                          TextButton(
                            onPressed: () async {
                              final transferred =
                                  await _showTransferOwnershipDialog(
                                dialogContext: ctx,
                                block: block,
                              );
                              if (transferred) {
                                setDialogState(
                                  () => resolvedGroupIds.add(block.group.id),
                                );
                              }
                            },
                            child: Text(
                              l10n?.transferOwnershipButton ?? 'Transfer',
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                result = false;
                Navigator.of(ctx).pop();
              },
              child: Text(l10n?.commonCancel ?? 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.negative),
              onPressed: resolvedGroupIds.length == blocks.length
                  ? () {
                      result = true;
                      Navigator.of(ctx).pop();
                    }
                  : null,
              child: Text(l10n?.commonConfirm ?? 'Confirm'),
            ),
          ],
        ),
      ),
    );

    return result == true;
  }

  Future<bool> _showTransferOwnershipDialog({
    required BuildContext dialogContext,
    required OwnedGroupBlock block,
  }) async {
    final l10n = AppLocalizations.of(context);
    GroupMember? selectedMember;

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setInnerState) => AlertDialog(
          title: Text(
            l10n?.transferOwnershipTitle ?? 'Transfer Group Ownership',
            style: AppTypography.h3,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${block.group.name}:',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.transferOwnershipBody ??
                      'Select a member to become the new owner. You will remain a member.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 12),
                ...block.eligibleNewOwners.map((member) {
                  final isSelected = selectedMember?.uid == member.uid;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      member.displayName,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      size: 20,
                    ),
                    onTap: () => setInnerState(() => selectedMember = member),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n?.commonCancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: selectedMember != null
                  ? () => Navigator.of(ctx).pop(true)
                  : null,
              child: Text(
                l10n?.transferOwnershipButton ?? 'Transfer Ownership',
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedMember != null && mounted) {
      try {
        final profile = ref.read(userProfileControllerProvider).value;
        if (profile != null) {
          await ref
              .read(userProfileControllerProvider.notifier)
              .transferGroupOwnership(
                groupId: block.group.id,
                currentOwnerUid: profile.uid,
                newOwnerUid: selectedMember!.uid,
                newOwnerDisplayName: selectedMember!.displayName,
              );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.transferOwnershipSuccess ??
                      'Ownership transferred successfully.',
                ),
                backgroundColor: AppColors.positive,
              ),
            );
          }
          return true;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.negative,
            ),
          );
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileControllerProvider).value;
    final currentLocale = ref.watch(appLocaleProvider);
    final currentThemeMode = ref.watch(appThemeModeProvider);

    final langName = currentLocale == null
        ? (l10n?.languageSystem ?? 'System Language')
        : currentLocale.languageCode == 'tr'
        ? 'Türkçe'
        : currentLocale.languageCode == 'es'
        ? 'Español'
        : currentLocale.languageCode == 'fr'
        ? 'Français'
        : currentLocale.languageCode == 'it'
        ? 'Italiano'
        : 'English';

    final themeName = currentThemeMode == ThemeMode.light
        ? (l10n?.themeLight ?? 'Light')
        : currentThemeMode == ThemeMode.dark
        ? (l10n?.themeDark ?? 'Dark')
        : (l10n?.themeSystem ?? 'System');

    final currencyName = profile?.preferredCurrency ?? 'TRY';

    return Scaffold(
      body: _isDeleting
          ? const Center(child: DenkLoadingView())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: !widget.isTab,
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  floating: true,
                  snap: false,
                  pinned: false,
                  title: Text(
                    l10n?.settingsTitle ?? 'Settings',
                    style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, widget.isTab ? 116 : 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // NEW PROFILE HEADER SECTION
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary.withValues(alpha: 0.2),
                                theme.colorScheme.primary.withValues(alpha: 0.05),
                              ],
                            ),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (profile?.displayName.isNotEmpty ?? false)
                                  ? profile!.displayName[0].toUpperCase()
                                  : '?',
                              style: AppTypography.h1.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              profile?.displayName ?? 'Anonymous User',
                              style: AppTypography.h2,
                            ),
                            const SizedBox(width: 8),
                            _isUpdatingName
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      Icons.edit_rounded, 
                                      size: 18, 
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    onPressed: () {
                                      if (profile != null) {
                                        _showEditNameDialog(profile.displayName);
                                      }
                                    },
                                  ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.anonymousAccount ?? 'Guest Profile',
                          style: AppTypography.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (profile != null) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: profile.uid));
                              setState(() => _isUidCopied = true);
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) {
                                  setState(() => _isUidCopied = false);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isUidCopied
                                    ? AppColors.positive.withValues(alpha: 0.1)
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isUidCopied
                                      ? AppColors.positive.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tag_rounded,
                                    size: 14,
                                    color: _isUidCopied ? AppColors.positive : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.uid.substring(0, profile.uid.length > 8 ? 8 : profile.uid.length),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: _isUidCopied ? AppColors.positive : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontFamily: 'monospace',
                                      fontWeight: _isUidCopied ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    _isUidCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                    size: 14,
                                    color: _isUidCopied ? AppColors.positive : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  // ACCOUNT RECOVERY & SECURITY SECTION
                  Text(
                    l10n?.accountSecurityTitle ?? 'Account Security & Recovery',
                    style: AppTypography.h3,
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final linkedAsync = ref.watch(linkedProvidersProvider);
                      List<String> linkedProviders = linkedAsync.value ?? const [];
                      String? userEmail;
                      try {
                        final repo = ref.read(authRepositoryProvider);
                        if (linkedAsync.value == null) {
                          linkedProviders = repo.linkedProviderIds;
                        }
                        userEmail = repo.currentEmail;
                      } catch (_) {
                        // In widget tests without mocked authRepositoryProvider
                      }
                      final isGoogleLinked =
                          linkedProviders.contains('google.com');
                      final isAppleLinked =
                          linkedProviders.contains('apple.com');
                      final isSecured = isGoogleLinked || isAppleLinked;

                      return DenkCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isSecured
                                      ? Icons.verified_user_rounded
                                      : Icons.shield_outlined,
                                  color: isSecured
                                      ? AppColors.positive
                                      : theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isSecured
                                        ? (l10n?.accountStatusSecured ??
                                            'Secured Account')
                                        : (l10n?.accountStatusAnonymous ??
                                            'Guest Account (Unsecured)'),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSecured
                                          ? AppColors.positive
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isSecured
                                  ? (l10n?.accountSecuredSubtitle ??
                                      'Your groups and balances are backed up and recoverable across devices.')
                                  : (l10n?.accountSecuritySubtitle ??
                                      'Link an account to recover your groups and balances across devices.'),
                              style: AppTypography.bodySmall.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Google
                            if (isGoogleLinked)
                              _buildLinkedProviderTile(
                                icon: Icons.account_circle,
                                title: l10n?.linkedWithGoogle ??
                                    'Linked with Google',
                                subtitle: userEmail,
                                theme: theme,
                              )
                            else
                              DenkButton(
                                label: l10n?.linkWithGoogle ??
                                    'Link with Google',
                                variant: DenkButtonVariant.secondary,
                                customIcon: Image.asset(
                                  'assets/branding/google_logo.png',
                                  width: 18,
                                  height: 18,
                                ),
                                isLoading: _isLinking &&
                                    _activeLinkingProvider == 'google.com',
                                onPressed:
                                    _isLinking ? null : _handleLinkGoogle,
                                height: 44,
                              ),
                            const SizedBox(height: 10),
                            // Apple
                            if (isAppleLinked)
                              _buildLinkedProviderTile(
                                icon: Icons.apple,
                                title: l10n?.linkedWithApple ??
                                    'Linked with Apple',
                                subtitle: null,
                                theme: theme,
                              )
                            else
                              DenkButton(
                                label: l10n?.linkWithApple ??
                                    'Sign in with Apple',
                                variant: DenkButtonVariant.apple,
                                icon: Icons.apple,
                                isLoading: _isLinking &&
                                    _activeLinkingProvider == 'apple.com',
                                onPressed: _isLinking ? null : _handleLinkApple,
                                height: 44,
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // PREFERENCES SECTION
                  Text(
                    l10n?.settingsPreferences ?? 'Preferences',
                    style: AppTypography.h3,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.darkSurfaceSubtle 
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.darkBorder 
                            : AppColors.lightBorder,
                        width: 1,
                      ),
                      boxShadow: Theme.of(context).brightness == Brightness.light ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.language_rounded,
                            title: l10n?.settingsLanguage ?? 'Language',
                            value: langName,
                            onTap: _showLanguageDialog,
                          ),
                          Divider(
                            height: 1, 
                            indent: 56, 
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppColors.darkBorder 
                                : AppColors.lightBorder,
                          ),
                          _SettingsTile(
                            icon: Icons.palette_rounded,
                            title: l10n?.themeTitle ?? 'Theme',
                            value: themeName,
                            onTap: _showThemeDialog,
                          ),
                          Divider(
                            height: 1, 
                            indent: 56, 
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppColors.darkBorder 
                                : AppColors.lightBorder,
                          ),
                          _SettingsTile(
                            icon: Icons.payments_rounded,
                            title: (l10n as dynamic).currency ?? 'Currency',
                            value: currencyName,
                            onTap: _showCurrencyDialog,
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
                    child: Material(
                      color: Colors.transparent,
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
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 4),
                          Material(
                            type: MaterialType.transparency,
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: const Icon(
                                    Icons.description_outlined,
                                    size: 20,
                                    color: AppColors.primary500,
                                  ),
                                  title: Text(
                                    l10n?.privacyPolicyTitle ?? 'Privacy Policy',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 18,
                                    color: AppColors.settled,
                                  ),
                                  onTap: () => _launchLegalUrl(LegalUrls.privacyPolicy),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: const Icon(
                                    Icons.gavel_outlined,
                                    size: 20,
                                    color: AppColors.primary500,
                                  ),
                                  title: Text(
                                    l10n?.termsOfServiceTitle ?? 'Terms of Service',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 18,
                                    color: AppColors.settled,
                                  ),
                                  onTap: () => _launchLegalUrl(LegalUrls.termsOfService),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: const Icon(
                                    Icons.public_outlined,
                                    size: 20,
                                    color: AppColors.primary500,
                                  ),
                                  title: Text(
                                    l10n?.webAccountDeletionTitle ??
                                        'Web Account Deletion',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    l10n?.webAccountDeletionSubtitle ??
                                        'Request account deletion via web if you no longer have access to the app.',
                                    style: AppTypography.caption.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 18,
                                    color: AppColors.settled,
                                  ),
                                  onTap: () =>
                                      _launchLegalUrl(LegalUrls.accountDeletion),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                          l10n?.deleteAccountTitle ?? 'Delete Account',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.negative,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.deleteAccountSubtitle ??
                              'Permanently delete your account. Groups you own with other members require ownership transfer first. This cannot be undone.',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DenkButton(
                          label:
                              l10n?.deleteAccountTitle ?? 'Delete Account',
                          variant: DenkButtonVariant.destructive,
                          height: 42,
                          onPressed: _handleDeleteAccount,
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
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark 
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
