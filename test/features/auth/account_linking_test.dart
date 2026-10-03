import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show AuthProvider, AuthCredential, GoogleAuthProvider;
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/features/auth/data/auth_repository.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/settings/presentation/settings_screen.dart';
import 'package:denk/l10n/l10n.dart';

class MockLinkingAuthRepository implements AuthRepository {
  String? _uid = 'anonymous_uid_123';
  final List<String> _linkedProviders = [];
  String? _email;
  UserProfile? _profile;

  final _authController = StreamController<String?>.broadcast();
  final _providersController = StreamController<List<String>>.broadcast();

  bool shouldThrowConflictOnGoogle = false;
  bool shouldThrowCancelledOnApple = false;
  bool shouldThrowAppleAccountRequired = false;
  bool shouldThrowGenericError = false;

  MockLinkingAuthRepository({UserProfile? initialProfile}) {
    _profile = initialProfile ??
        UserProfile(
          uid: 'anonymous_uid_123',
          displayName: 'Test User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  @override
  Stream<String?> get authStateChanges => _authController.stream;

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
  String? get currentEmail => _email;

  @override
  Future<String> ensureAnonymousUser() async => _uid!;

  @override
  Future<UserProfile?> fetchUserProfile() async => _profile;

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _profile = profile;
    _uid = profile.uid;
    _authController.add(_uid);
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
    _linkedProviders.clear();
    _authController.add(null);
    _providersController.add(const []);
  }

  @override
  Future<void> deleteFirebaseAuthAccount() async {
    _profile = null;
    _uid = null;
    _authController.add(null);
  }

  @override
  Future<void> deleteUserDocument(String uid) async {
    _profile = null;
  }

  @override
  Future<void> linkGoogleAccount({AuthProvider? customProvider}) async {
    if (shouldThrowConflictOnGoogle) {
      throw const AuthConflictException(
        message: 'Account already in use',
        code: 'credential-already-in-use',
        conflictingEmail: 'existing@example.com',
      );
    }
    if (shouldThrowGenericError) {
      throw const AppException(
        message: 'Network failed',
        code: 'network-unavailable',
      );
    }
    _linkedProviders.add('google.com');
    _email = 'user@gmail.com';
    _providersController.add(List.unmodifiable(_linkedProviders));
  }

  @override
  Future<void> linkAppleAccount({AuthProvider? customProvider}) async {
    if (shouldThrowCancelledOnApple) {
      throw const AuthCancelledException();
    }
    if (shouldThrowAppleAccountRequired) {
      throw const AuthAppleAccountRequiredException();
    }
    _linkedProviders.add('apple.com');
    _providersController.add(List.unmodifiable(_linkedProviders));
  }

  @override
  Future<void> linkCredential(AuthCredential credential) async {
    _linkedProviders.add(credential.providerId);
    _providersController.add(List.unmodifiable(_linkedProviders));
  }

  @override
  Future<void> signInWithExistingCredential(AuthCredential credential) async {
    _uid = 'existing_uid_456';
    _linkedProviders.clear();
    _linkedProviders.add(credential.providerId);
    _profile = UserProfile(
      uid: _uid!,
      displayName: 'Existing User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _authController.add(_uid);
    _providersController.add(List.unmodifiable(_linkedProviders));
  }

  @override
  Future<void> signInWithProvider(AuthProvider provider) async {
    _uid = 'existing_uid_456';
    _linkedProviders.clear();
    _linkedProviders.add(provider.providerId);
    _profile = UserProfile(
      uid: _uid!,
      displayName: 'Existing User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _authController.add(_uid);
    _providersController.add(List.unmodifiable(_linkedProviders));
  }
}

void main() {
  group('Phase 16 — Account Recovery & Account Linking Tests', () {
    test('Linking Google preserves existing anonymous UID', () async {
      final repo = MockLinkingAuthRepository();
      expect(repo.isAnonymous, isTrue);
      expect(repo.currentUid, 'anonymous_uid_123');

      await repo.linkGoogleAccount();

      // UID MUST be preserved exactly
      expect(repo.currentUid, 'anonymous_uid_123');
      expect(repo.isAnonymous, isFalse);
      expect(repo.linkedProviderIds, contains('google.com'));
      expect(repo.currentEmail, 'user@gmail.com');
    });

    test('Linking Apple updates linked providers and preserves UID', () async {
      final repo = MockLinkingAuthRepository();
      expect(repo.isAnonymous, isTrue);
      expect(repo.currentUid, 'anonymous_uid_123');

      await repo.linkAppleAccount();

      expect(repo.currentUid, 'anonymous_uid_123');
      expect(repo.isAnonymous, isFalse);
      expect(repo.linkedProviderIds, contains('apple.com'));
    });

    test('Conflict throws AuthConflictException with credential details', () async {
      final repo = MockLinkingAuthRepository();
      repo.shouldThrowConflictOnGoogle = true;

      expect(
        () => repo.linkGoogleAccount(),
        throwsA(isA<AuthConflictException>().having(
          (e) => e.code,
          'code',
          'credential-already-in-use',
        )),
      );
    });

    test('Cancellation throws AuthCancelledException cleanly', () async {
      final repo = MockLinkingAuthRepository();
      repo.shouldThrowCancelledOnApple = true;

      expect(
        () => repo.linkAppleAccount(),
        throwsA(isA<AuthCancelledException>()),
      );
    });

    test('Switching to existing account switches UID to existing profile', () async {
      final repo = MockLinkingAuthRepository();
      expect(repo.currentUid, 'anonymous_uid_123');

      // User chooses to switch to the existing account
      await repo.signInWithProvider(GoogleAuthProvider());

      expect(repo.currentUid, 'existing_uid_456');
      expect(repo.linkedProviderIds, contains('google.com'));
      final profile = await repo.fetchUserProfile();
      expect(profile?.displayName, 'Existing User');
    });

    testWidgets('SettingsScreen displays Guest Account (Unsecured) when anonymous', (
      tester,
    ) async {
      final repo = MockLinkingAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Security & Recovery'), findsOneWidget);
      expect(find.text('Guest Account (Unsecured)'), findsOneWidget);
      expect(find.text('Link with Google'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsOneWidget);
    });

    testWidgets('SettingsScreen on Android does not display Sign in with Apple button', (
      tester,
    ) async {
      final repo = MockLinkingAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const SettingsScreen(isApplePlatformOverride: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Link with Google'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsNothing);
    });

    testWidgets('Tapping Link with Google successfully secures account', (
      tester,
    ) async {
      final repo = MockLinkingAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Link with Google
      await tester.tap(find.text('Link with Google'));
      await tester.pumpAndSettle();

      // Verify success snackbar and updated UI state
      expect(find.text('Account linked successfully!'), findsOneWidget);
      expect(find.text('Secured Account'), findsOneWidget);
      expect(find.text('Linked with Google'), findsOneWidget);
    });

    testWidgets('Account conflict displays non-destructive resolution dialog', (
      tester,
    ) async {
      final repo = MockLinkingAuthRepository();
      repo.shouldThrowConflictOnGoogle = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Link with Google triggering conflict
      await tester.tap(find.text('Link with Google'));
      await tester.pumpAndSettle();

      // Verify conflict dialog
      expect(find.text('Account Already Exists'), findsOneWidget);
      expect(find.text('Keep Guest Account'), findsOneWidget);
      expect(find.text('Switch to Existing Account'), findsOneWidget);

      // Tap Keep Guest Account -> Cancel without changing session
      await tester.tap(find.text('Keep Guest Account'));
      await tester.pumpAndSettle();

      expect(find.text('Account Already Exists'), findsNothing);
      expect(repo.currentUid, 'anonymous_uid_123');
      expect(find.text('Guest Account (Unsecured)'), findsOneWidget);
    });

    testWidgets('Confirming account switch changes active session to existing profile', (
      tester,
    ) async {
      final repo = MockLinkingAuthRepository();
      repo.shouldThrowConflictOnGoogle = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Link with Google triggering conflict
      await tester.tap(find.text('Link with Google'));
      await tester.pumpAndSettle();

      // Confirm switch to existing account
      await tester.tap(find.text('Switch to Existing Account'));
      await tester.pumpAndSettle();

      expect(find.text('Switched to existing account.'), findsOneWidget);
      expect(repo.currentUid, 'existing_uid_456');
    });

    testWidgets('Tapping Sign in with Apple and cancelling does not show error banner', (
      tester,
    ) async {
      final repo = MockLinkingAuthRepository();
      repo.shouldThrowCancelledOnApple = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Tapping Sign in with Apple without Apple Account on device shows informative message', (
      tester,
    ) async {
      final repo = MockLinkingAuthRepository();
      repo.shouldThrowAppleAccountRequired = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Please sign in with an Apple Account in your device settings to continue with Apple.',
        ),
        findsOneWidget,
      );
    });

    test('AppException.fromFirebase correctly maps Apple ASAuthorization errors', () {
      final error1001 = AppException.fromFirebase(
        'PlatformException(1001, The operation couldn’t be completed. (com.apple.AuthenticationServices.AuthorizationError error 1001.), null, null)',
      );
      expect(error1001, isA<AuthCancelledException>());

      final error1000 = AppException.fromFirebase(
        'PlatformException(error, The operation couldn’t be completed. (com.apple.AuthenticationServices.AuthorizationError error 1000.), null, null)',
      );
      expect(error1000, isA<AuthAppleAccountRequiredException>());
    });
  });
}
