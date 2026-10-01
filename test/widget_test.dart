import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/app.dart';
import 'package:denk/features/auth/data/auth_repository.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';

import 'package:firebase_auth/firebase_auth.dart' show AuthProvider, AuthCredential;

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<String?>.broadcast();

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  Stream<List<String>> get linkedProvidersChanges => Stream.value(const []);

  @override
  String? get currentUid => 'mock_uid';

  @override
  bool get isAnonymous => true;

  @override
  List<String> get linkedProviderIds => const [];

  @override
  String? get currentEmail => null;

  @override
  Future<String> ensureAnonymousUser() async => 'mock_uid';

  @override
  Future<UserProfile?> fetchUserProfile() async => null;

  @override
  Future<void> saveUserProfile(UserProfile profile) async {}

  @override
  Future<void> updateDisplayName(String newName) async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> linkGoogleAccount({AuthProvider? customProvider}) async {}

  @override
  Future<void> linkAppleAccount({AuthProvider? customProvider}) async {}

  @override
  Future<void> linkCredential(AuthCredential credential) async {}

  @override
  Future<void> signInWithExistingCredential(AuthCredential credential) async {}

  @override
  Future<void> signInWithProvider(AuthProvider provider) async {}

  @override
  Future<void> deleteFirebaseAuthAccount() async {}

  @override
  Future<void> deleteUserDocument(String uid) async {}
}

void main() {
  testWidgets('DenkApp renders onboarding display name screen for new users', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: const DenkApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Denk'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
