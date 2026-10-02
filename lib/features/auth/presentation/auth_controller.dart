import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' show AuthProvider, AuthCredential, FirebaseAuth;
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/auth/data/auth_repository.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/domain/account_deletion_service.dart';
import 'package:denk/features/groups/data/group_repository.dart';

/// Provider for the singleton [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Stream of authenticated anonymous user ID changes.
final authStateProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Stream of linked provider IDs for the current session (e.g. ['google.com', 'apple.com']).
final linkedProvidersProvider = StreamProvider<List<String>>((ref) {
  try {
    final repo = ref.watch(authRepositoryProvider);
    return repo.linkedProvidersChanges;
  } catch (_) {
    return Stream.value(const []);
  }
});

/// Async state controller for the user's minimal profile.
class UserProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final uid = ref.watch(authStateProvider).value;
    final repo = ref.watch(authRepositoryProvider);

    if (uid != null) {
      final docStream = FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
      final sub = docStream.listen((snapshot) {
        if (!snapshot.exists && state.value != null) {
          // Instantly kick the user out if their Firestore document is deleted.
          // This usually happens when deleted from Firebase Auth via extensions.
          FirebaseAuth.instance.signOut();
          ref.invalidateSelf();
        }
      });
      ref.onDispose(() => sub.cancel());
    }

    try {
      return await repo.fetchUserProfile();
    } catch (e) {
      debugPrint('UserProfileController build warning: $e');
      return await repo.fetchUserProfile();
    }
  }

  /// Sets the initial display name and optional preferences for the user.
  Future<void> setDisplayName(
    String name, {
    String? preferredCurrency,
    String? languageCode,
  }) async {
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 50) {
      throw const AppException(
        message: 'Name must be between 2 and 50 characters.',
        code: 'invalid-name',
      );
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      final uid = await repo.ensureAnonymousUser();

      final now = DateTime.now();
      final newProfile = UserProfile(
        uid: uid,
        displayName: trimmed,
        preferredCurrency: preferredCurrency ?? 'USD',
        languageCode: languageCode ?? 'en',
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveUserProfile(newProfile);
      state = AsyncValue.data(newProfile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates an existing user's display name.
  Future<void> updateDisplayName(String newName) async {
    final current = state.value;
    if (current == null) return;

    final trimmed = newName.trim();
    if (trimmed.length < 2 || trimmed.length > 50) {
      throw const AppException(
        message: 'Name must be between 2 and 50 characters.',
        code: 'invalid-name',
      );
    }

    // Removed global loading state to prevent auth gate from unmounting the app
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateDisplayName(trimmed);
      final updated = current.copyWith(
        displayName: trimmed,
        updatedAt: DateTime.now(),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deletes the local account and resets state.
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Links current user with Google, preserving current UID.
  Future<void> linkGoogle({AuthProvider? customProvider}) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.linkGoogleAccount(customProvider: customProvider);
    final updated = await repo.fetchUserProfile();
    state = AsyncValue.data(updated);
  }

  /// Links current user with Apple, preserving current UID.
  Future<void> linkApple({AuthProvider? customProvider}) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.linkAppleAccount(customProvider: customProvider);
    final updated = await repo.fetchUserProfile();
    state = AsyncValue.data(updated);
  }

  /// Switches to an existing account using an existing [AuthCredential].
  Future<void> switchToExistingAccount(AuthCredential credential) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithExistingCredential(credential);
      final profile = await repo.fetchUserProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Switches to an existing account using an [AuthProvider].
  Future<void> switchToExistingProvider(AuthProvider provider) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithProvider(provider);
      final profile = await repo.fetchUserProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Analyzes which groups need ownership transfer before account deletion.
  Future<List<OwnedGroupBlock>> analyzeOwnershipBlocks() async {
    final repo = ref.read(authRepositoryProvider);
    final groupRepo = FirestoreGroupRepository();
    final uid = repo.currentUid;
    if (uid == null) return const [];
    final service = AccountDeletionService(authRepo: repo, groupRepo: groupRepo);
    return service.analyzeOwnershipBlocks(uid);
  }

  /// Transfers group ownership to a new owner.
  Future<void> transferGroupOwnership({
    required String groupId,
    required String currentOwnerUid,
    required String newOwnerUid,
    required String newOwnerDisplayName,
  }) async {
    final groupRepo = FirestoreGroupRepository();
    await groupRepo.transferOwnership(
      groupId: groupId,
      currentOwnerUid: currentOwnerUid,
      newOwnerUid: newOwnerUid,
      newOwnerDisplayName: newOwnerDisplayName,
    );
  }

  /// Full account deletion with Firestore cleanup.
  /// Throws [AuthReauthRequiredException] if re-authentication is needed.
  Future<void> deleteAccountFull() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final groupRepo = FirestoreGroupRepository();
      final uid = repo.currentUid;
      if (uid == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final service = AccountDeletionService(authRepo: repo, groupRepo: groupRepo);
      await service.executeFullDeletion(uid);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final userProfileControllerProvider =
    AsyncNotifierProvider<UserProfileController, UserProfile?>(() {
      return UserProfileController();
    });
