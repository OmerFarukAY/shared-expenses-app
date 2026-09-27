import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/auth/presentation/onboarding_display_name_screen.dart';
import 'package:denk/l10n/l10n.dart';

/// Root application widget for Denk.
class DenkApp extends ConsumerWidget {
  final Locale? forcedLocale;

  const DenkApp({super.key, this.forcedLocale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Denk',
      debugShowCheckedModeBanner: false,
      locale: forcedLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const DenkAuthGate(),
    );
  }
}

/// Authentication and onboarding gate.
///
/// Seamlessly directs the user to [OnboardingDisplayNameScreen] if no display name
/// has been chosen yet, or to the authenticated home experience.
class DenkAuthGate extends ConsumerWidget {
  const DenkAuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileControllerProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null || profile.displayName.trim().isEmpty) {
          return const OnboardingDisplayNameScreen();
        }
        return DenkHomeShell(profileName: profile.displayName);
      },
      loading: () => const Scaffold(
        body: Center(child: DenkLoadingView(message: 'Initializing...')),
      ),
      error: (err, _) => const OnboardingDisplayNameScreen(),
    );
  }
}

/// Home shell placeholder displaying current user display name
class DenkHomeShell extends StatelessWidget {
  final String profileName;

  const DenkHomeShell({super.key, required this.profileName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const DenkLogo(size: 28, showBackground: false),
            const SizedBox(width: 8),
            Text(l10n?.appName ?? 'Denk'),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hello, $profileName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.noGroupsSubtitle ??
                    'Create a group or enter an invite code to start sharing expenses.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
