import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denk/features/auth/data/auth_repository.dart';

class MockFirebaseAuth implements FirebaseAuth {
  bool failGetIdToken = false;
  int signInAnonymouslyCallCount = 0;
  int signOutCallCount = 0;
  User? _mockCurrentUser;
  
  @override
  User? get currentUser => _mockCurrentUser;

  @override
  Future<UserCredential> signInAnonymously() async {
    signInAnonymouslyCallCount++;
    await Future.delayed(const Duration(milliseconds: 100));
    _mockCurrentUser = MockUser(shouldThrowOnToken: failGetIdToken);
    return MockUserCredential();
  }
  
  @override
  Future<void> signOut() async {
    signOutCallCount++;
    _mockCurrentUser = null;
    failGetIdToken = false; // Reset for next sign in
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUser implements User {
  final bool shouldThrowOnToken;
  MockUser({this.shouldThrowOnToken = false});
  
  @override
  String get uid => 'mock_uid';

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    if (shouldThrowOnToken) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    return 'mock_token';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements UserCredential {
  @override
  User? get user => MockUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('ensureAnonymousUser uses mutex to prevent duplicate signInAnonymously calls', () async {
    final mockAuth = MockFirebaseAuth();
    final repo = FirebaseAuthRepository(
      firebaseAuth: mockAuth,
      firestore: MockFirestore(),
    );

    // Call it concurrently 5 times
    final futures = List.generate(5, (_) => repo.ensureAnonymousUser());
    await Future.wait(futures);

    // Only 1 account should be created because the mutex blocks the others, 
    // and after the first one, currentUser is not null.
    expect(mockAuth.signInAnonymouslyCallCount, 1);
  });

  test('ensureAnonymousUser signs out and creates new account if token refresh fails (Console deleted user)', () async {
    final mockAuth = MockFirebaseAuth();
    
    // Simulate user having a stale local session
    mockAuth.failGetIdToken = true;
    mockAuth._mockCurrentUser = MockUser(shouldThrowOnToken: true);

    final repo = FirebaseAuthRepository(
      firebaseAuth: mockAuth,
      firestore: MockFirestore(),
    );

    await repo.ensureAnonymousUser();

    expect(mockAuth.signOutCallCount, 1, reason: 'Should sign out the stale user');
    expect(mockAuth.signInAnonymouslyCallCount, 1, reason: 'Should create exactly 1 new user');
  });
}
