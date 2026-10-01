import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';
import 'package:denk/core/widgets/widgets.dart';
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
  Currency? _selectedCurrency;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCurrency == null) {
      final locale = Localizations.localeOf(context);
      _selectedCurrency = Currency.getDefaultCurrencyForLocale(
        locale.languageCode,
        locale.countryCode,
      );
    }
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
      final currentLocale = Localizations.localeOf(context).languageCode;
      await ref
          .read(userProfileControllerProvider.notifier)
          .setDisplayName(
            name,
            preferredCurrency: _selectedCurrency!.code,
            languageCode: currentLocale,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: DenkLogo(size: 60)),
                  const SizedBox(height: 24),
                  Text(
                    l10n?.welcomeTitle ?? 'Welcome to Denk',
                    textAlign: TextAlign.center,
                    style: AppTypography.h1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.welcomeSubtitle ??
                        'Keep track of shared expenses with friends, roommates, and family without passwords or personal data.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  DenkCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DenkTextField(
                          controller: _nameController,
                          focusNode: _focusNode,
                          label: l10n?.chooseDisplayName ?? 'Your Display Name',
                          hintText:
                              l10n?.displayNameHint ?? 'e.g. Alex, Sam, Ömer',
                          errorText: _errorText,
                          autofocus: true,
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
                        const SizedBox(height: 20),
                        Text(
                          l10n?.groupCurrencyLabel ?? 'Default Currency',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Currency>(
                              value: _selectedCurrency,
                              isExpanded: true,
                              items: Currency.supportedCurrencies
                                  .map(
                                    (curr) => DropdownMenuItem(
                                      value: curr,
                                      child: Text(
                                        '${curr.code} (${curr.symbol}) — ${curr.name}',
                                        style: AppTypography.bodyMedium,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (newCurr) {
                                if (newCurr != null) {
                                  setState(() {
                                    _selectedCurrency = newCurr;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        DenkButton(
                          label: l10n?.getStarted ?? 'Get Started',
                          isLoading: _isSubmitting,
                          onPressed: _validateAndSubmit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 15,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                      Text(
                        'Privacy-First • No Email or Phone Required',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
