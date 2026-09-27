import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/app.dart';
import 'package:denk/features/auth/data/auth_repository.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<String?>.broadcast();

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  String? get currentUid => 'mock_uid';

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
