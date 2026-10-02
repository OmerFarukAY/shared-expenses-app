import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/auth/presentation/onboarding_display_name_screen.dart';
import 'package:denk/core/widgets/main_navigation_screen.dart';
import 'package:denk/features/groups/presentation/groups_list_screen.dart';
import 'package:denk/features/settings/presentation/settings_controller.dart';
import 'package:denk/l10n/l10n.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Root application widget for Denk.
class DenkApp extends ConsumerWidget {
  final Locale? forcedLocale;

  const DenkApp({super.key, this.forcedLocale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocale = ref.watch(appLocaleProvider);
    final appThemeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: 'Denk',
      debugShowCheckedModeBanner: false,
      locale: forcedLocale ?? appLocale,
      navigatorObservers: [
        if (NativeLiquidGlassUtils.supportsLiquidGlass)
          LiquidGlassNavigatorObserver(),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appThemeMode,
      builder: (context, child) {
        return child!;
      },
      onGenerateRoute: (settings) {
        if (settings.name != null &&
            (settings.name!.startsWith('/link') ||
             settings.name!.contains('deep_link_id') ||
             settings.name!.contains('firebaseError'))) {
          return PageRouteBuilder<void>(
            settings: settings,
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SizedBox.shrink(),
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return PageRouteBuilder<void>(
          settings: settings,
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SizedBox.shrink(),
        );
      },
      home: const DenkAuthGate(),
    );
  }
}

/// Authentication and onboarding gate.
///
/// Seamlessly directs the user to [OnboardingDisplayNameScreen] if no display name
/// has been chosen yet, or to the authenticated [GroupsListScreen].
class DenkAuthGate extends ConsumerWidget {
  const DenkAuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileControllerProvider);

    return profileAsync.when(
      data: (profile) {
        FlutterNativeSplash.remove();
        if (profile == null || profile.displayName.trim().isEmpty) {
          return const OnboardingDisplayNameScreen();
        }
        return const MainNavigationScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: DenkLoadingView()),
      ),
      error: (err, _) {
        FlutterNativeSplash.remove();
        return const OnboardingDisplayNameScreen();
      },
    );
  }
}
