import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/features/auth/data/auth_repository.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart' show AuthProvider, AuthCredential;
import 'package:denk/features/auth/presentation/onboarding_display_name_screen.dart';
import 'package:denk/l10n/l10n.dart';

class FakeAuthRepository implements AuthRepository {
  UserProfile? _profile;
  String? _uid = 'test_uid_123';
  final List<String> _linkedProviders = [];
  final _controller = StreamController<String?>.broadcast();
  final _providersController = StreamController<List<String>>.broadcast();

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  Stream<List<String>> get linkedProvidersChanges =>
      _providersController.stream;

  @override
  String? get currentUid => _uid;

  @override
  bool get isAnonymous => _linkedProviders.isEmpty;

  @override
  List<String> get linkedProviderIds => List.unmodifiable(_linkedProviders);

  @override
  String? get currentEmail => null;

  @override
  Future<String> ensureAnonymousUser() async => _uid ?? 'test_uid_123';

  @override
  Future<UserProfile?> fetchUserProfile() async => _profile;

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _profile = profile;
    _uid = profile.uid;
    _controller.add(_uid);
  }

  @override
  Future<void> updateDisplayName(String newName) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(displayName: newName);
    }
  }

  @override
  Future<void> deleteAccount() async {
    _profile = null;
    _uid = null;
    _controller.add(null);
  }

  @override
  Future<void> linkGoogleAccount({AuthProvider? customProvider}) async {
    _linkedProviders.add('google.com');
    _providersController.add(_linkedProviders);
  }

  @override
  Future<void> linkAppleAccount({AuthProvider? customProvider}) async {
    _linkedProviders.add('apple.com');
    _providersController.add(_linkedProviders);
  }

  @override
  Future<void> linkCredential(AuthCredential credential) async {
    _linkedProviders.add(credential.providerId);
    _providersController.add(_linkedProviders);
  }

  @override
  Future<void> signInWithExistingCredential(AuthCredential credential) async {}

  @override
  Future<void> signInWithProvider(AuthProvider provider) async {}
}

void main() {
  testWidgets('OnboardingDisplayNameScreen validates input and submits', (
    tester,
  ) async {
    final fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingDisplayNameScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Denk'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started without typing anything -> validation error appears
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a name between 2 and 50 characters'),
      findsOneWidget,
    );

    // Enter a valid name
    await tester.enterText(find.byType(TextField), 'Ömer');
    await tester.pumpAndSettle();

    // Tap Get Started again
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify repo received the profile
    final saved = await fakeRepo.fetchUserProfile();
    expect(saved, isNotNull);
    expect(saved!.displayName, 'Ömer');
    expect(saved.uid, 'test_uid_123');
  });
}
