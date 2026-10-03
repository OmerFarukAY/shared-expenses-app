import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/core/errors/error_localizer.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/l10n/l10n.dart';

class OnboardingDisplayNameScreen extends ConsumerStatefulWidget {
  const OnboardingDisplayNameScreen({super.key});

  @override
  ConsumerState<OnboardingDisplayNameScreen> createState() =>
      _OnboardingDisplayNameScreenState();
}

class _OnboardingDisplayNameScreenState
    extends ConsumerState<OnboardingDisplayNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    final name = _nameController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (name.length < 2 || name.length > 50) {
      setState(() {
        _errorText =
            l10n?.displayNameValidation ??
            'Please enter a name between 2 and 50 characters';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      final locale = Localizations.localeOf(context);
      final currentLocale = locale.languageCode;
      final defaultCurrency = Currency.getDefaultCurrencyForLocale(
        locale.languageCode,
        locale.countryCode,
      );
      
      await ref
          .read(userProfileControllerProvider.notifier)
          .setDisplayName(
            name,
            preferredCurrency: defaultCurrency.code,
            languageCode: currentLocale,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.localizedErrorMessage(e)),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.darkBg,
                      AppColors.darkSurfaceSubtle.withValues(alpha: 0.5),
                      AppColors.darkBg,
                    ]
                  : [
                      AppColors.lightBg,
                      const Color(0xFFF1F5F9),
                      AppColors.lightBg,
                    ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      const Center(child: DenkLogo(size: 46)),
                      const SizedBox(height: 10),
                      Text(
                        l10n?.welcomeTitle ?? 'Welcome to Denk',
                        textAlign: TextAlign.center,
                        style: AppTypography.h2,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n?.welcomeSubtitle ??
                            'Keep track of shared expenses with friends, roommates, and family without passwords or personal data.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3 Micro Value Props Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceSubtle
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: 1,
                          ),
                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              icon: Icons.bolt_rounded,
                              iconColor: AppColors.primary500,
                              title: l10n?.welcomeFeature1Title ??
                                  'No Account or Password',
                              subtitle: l10n?.welcomeFeature1Subtitle ??
                                  'No email or phone required, start instantly.',
                              isDark: isDark,
                            ),
                            Divider(
                              height: 14,
                              thickness: 1,
                              color: isDark
                                  ? AppColors.darkBorder.withValues(alpha: 0.5)
                                  : AppColors.lightBorder.withValues(alpha: 0.7),
                            ),
                            _buildFeatureRow(
                              icon: Icons.balance_rounded,
                              iconColor: AppColors.categoryHome,
                              title: l10n?.welcomeFeature2Title ??
                                  'Exact & Fair Splitting',
                              subtitle: l10n?.welcomeFeature2Subtitle ??
                                  'Split expenses fairly and transparently.',
                              isDark: isDark,
                            ),
                            Divider(
                              height: 14,
                              thickness: 1,
                              color: isDark
                                  ? AppColors.darkBorder.withValues(alpha: 0.5)
                                  : AppColors.lightBorder.withValues(alpha: 0.7),
                            ),
                            _buildFeatureRow(
                              icon: Icons.group_add_rounded,
                              iconColor: AppColors.positive,
                              title: l10n?.welcomeFeature3Title ??
                                  'Instant Joining',
                              subtitle: l10n?.welcomeFeature3Subtitle ??
                                  'Join groups in seconds with an invite code.',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CTA & Name Input Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceSubtle
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: 1,
                          ),
                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n?.chooseDisplayName ??
                                  'Your display name in groups',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DenkTextField(
                              controller: _nameController,
                              focusNode: _focusNode,
                              hintText: l10n?.displayNameHint ??
                                  'e.g. Alex, Sam, Ömer',
                              errorText: _errorText,
                              autofocus: false,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _validateAndSubmit(),
                              onChanged: (_) {
                                if (_errorText != null) {
                                  setState(() {
                                    _errorText = null;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            DenkButton(
                              label: l10n?.getStarted ?? 'Get Started',
                              isLoading: _isSubmitting,
                              onPressed: _validateAndSubmit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Footer Trust Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.positive.withValues(alpha: 0.1)
                              : AppColors.positive.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.positive.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shield_rounded,
                              size: 16,
                              color: AppColors.positive,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l10n?.privacyFirstInfo ??
                                    'Privacy-First • No Email Required',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.16 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
