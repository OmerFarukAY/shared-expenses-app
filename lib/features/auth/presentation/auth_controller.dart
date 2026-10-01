import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/auth/data/auth_repository.dart';
import 'package:denk/features/auth/domain/user_profile.dart';

/// Provider for the singleton [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Stream of authenticated anonymous user ID changes.
final authStateProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Async state controller for the user's minimal profile.
class UserProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    try {
      await repo.ensureAnonymousUser();
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

    state = const AsyncValue.loading();
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

    state = const AsyncValue.loading();
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
}

final userProfileControllerProvider =
    AsyncNotifierProvider<UserProfileController, UserProfile?>(() {
      return UserProfileController();
    });
