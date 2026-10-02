import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/auth/domain/user_profile.dart';

/// Contract for authentication and minimal user profile operations.
abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  Stream<List<String>> get linkedProvidersChanges;
  String? get currentUid;
  bool get isAnonymous;
  List<String> get linkedProviderIds;
  String? get currentEmail;

  Future<String> ensureAnonymousUser();
  Future<UserProfile?> fetchUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> updateDisplayName(String newName);
  Future<void> deleteAccount();

  /// Deletes the Firebase Auth account. Should be called AFTER all Firestore cleanup.
  /// Throws [AuthReauthRequiredException] if the session is too old.
  Future<void> deleteFirebaseAuthAccount();

  /// Deletes the users/{uid} Firestore document and all known subcollections.
  Future<void> deleteUserDocument(String uid);

  /// Links the current anonymous user with Google, preserving [currentUid].
  Future<void> linkGoogleAccount({AuthProvider? customProvider});

  /// Links the current anonymous user with Apple, preserving [currentUid].
  Future<void> linkAppleAccount({AuthProvider? customProvider});

  /// Links the current user with an explicit [AuthCredential], preserving [currentUid].
  Future<void> linkCredential(AuthCredential credential);

  /// Switches to an existing account if a conflict occurs during linking.
  Future<void> signInWithExistingCredential(AuthCredential credential);

  /// Signs in with a provider if credentials are not directly available.
  Future<void> signInWithProvider(AuthProvider provider);
}

/// Production implementation of [AuthRepository] using Firebase Auth & Cloud Firestore
/// with local SharedPreferences cache for instant offline startup.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final SharedPreferences? prefs;

  static const String _prefProfileKey = 'denk_local_user_profile';

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    this.prefs,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<String?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid);

  @override
  Stream<List<String>> get linkedProvidersChanges =>
      _firebaseAuth.userChanges().map((user) {
        if (user == null) return const [];
        return user.providerData.map((p) => p.providerId).toList();
      });

  @override
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  @override
  bool get isAnonymous => _firebaseAuth.currentUser?.isAnonymous ?? true;

  @override
  List<String> get linkedProviderIds {
    final user = _firebaseAuth.currentUser;
    if (user == null) return const [];
    return user.providerData.map((p) => p.providerId).toList();
  }

  @override
  String? get currentEmail => _firebaseAuth.currentUser?.email;

  @override
  Future<String> ensureAnonymousUser() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        return currentUser.uid;
      }
      final userCredential = await _firebaseAuth.signInAnonymously();
      final user = userCredential.user;
      if (user == null) {
        throw const AppException(
          message: 'Unable to initialize anonymous session.',
          code: 'auth-failed',
        );
      }
      return user.uid;
    } catch (e) {
      if (e is AppException) rethrow;
      debugPrint('ensureAnonymousUser error: $e');
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<UserProfile?> fetchUserProfile() async {
    final uid = currentUid;
    if (uid == null) {
      return _readCachedProfile();
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!, doc.id);
        await _cacheProfile(profile);
        return profile;
      } else {
        // If doc does not exist remotely yet, check local cache and sync to Firestore
        final cached = await _readCachedProfile();
        if (cached != null && cached.uid == uid) {
          await saveUserProfile(cached);
          return cached;
        }
      }
    } catch (e) {
      debugPrint(
        'fetchUserProfile remote failed, falling back to local cache: $e',
      );
    }

    // Fallback to local cache if network is unavailable or document is pending
    return _readCachedProfile();
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _cacheProfile(profile);

      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveUserProfile remote sync notice: $e');
      // Even if remote write is queued offline, local cache is saved
    }
  }

  @override
  Future<void> updateDisplayName(String newName) async {
    final uid = currentUid;
    if (uid == null) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed.length > 50) {
      throw const AppException(
        message: 'Display name must be between 1 and 50 characters.',
        code: 'invalid-name',
      );
    }

    final existing = await fetchUserProfile();
    final updated =
        (existing ??
                UserProfile(
                  uid: uid,
                  displayName: trimmed,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ))
            .copyWith(displayName: trimmed, updatedAt: DateTime.now());

    await saveUserProfile(updated);
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final uid = currentUid;
      if (uid != null) {
        await deleteUserDocument(uid);
      } else {
        await _clearCachedProfile();
      }
      await deleteFirebaseAuthAccount();
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> deleteFirebaseAuthAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return; // Already deleted or signed out
    try {
      await user.delete();
      await _clearCachedProfile();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthReauthRequiredException(originalError: e);
      }
      throw AppException.fromFirebase(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> deleteUserDocument(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      // Delete subcollections first (Firestore does not cascade delete subcollections)
      final userGroupsSnap = await userRef.collection('user_groups').get();
      final joinReqsSnap = await userRef.collection('join_requests').get();
      final allRefs = <DocumentReference>[
        ...userGroupsSnap.docs.map((d) => d.reference),
        ...joinReqsSnap.docs.map((d) => d.reference),
      ];
      for (var i = 0; i < allRefs.length; i += 450) {
        final batch = _firestore.batch();
        for (final ref in allRefs.skip(i).take(450)) {
          batch.delete(ref);
        }
        await batch.commit();
      }
      // Delete the user document itself
      await userRef.delete();
    } catch (e) {
      debugPrint('deleteUserDocument error: $e');
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> linkGoogleAccount({AuthProvider? customProvider}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        message: 'No active session to link.',
        code: 'no-current-user',
      );
    }

    try {
      final provider = customProvider ?? GoogleAuthProvider();
      await user.linkWithProvider(provider);
      await _syncLinkedProfileName();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> linkAppleAccount({AuthProvider? customProvider}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        message: 'No active session to link.',
        code: 'no-current-user',
      );
    }

    try {
      final provider = customProvider ?? AppleAuthProvider();
      await user.linkWithProvider(provider);
      await _syncLinkedProfileName();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> linkCredential(AuthCredential credential) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        message: 'No active session to link.',
        code: 'no-current-user',
      );
    }

    try {
      await user.linkWithCredential(credential);
      await _syncLinkedProfileName();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> signInWithExistingCredential(AuthCredential credential) async {
    try {
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AppException(
          message: 'Unable to switch account.',
          code: 'sign-in-failed',
        );
      }
      await fetchUserProfile();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  @override
  Future<void> signInWithProvider(AuthProvider provider) async {
    try {
      final userCredential = await _firebaseAuth.signInWithProvider(provider);
      final user = userCredential.user;
      if (user == null) {
        throw const AppException(
          message: 'Unable to sign in.',
          code: 'sign-in-failed',
        );
      }
      await fetchUserProfile();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  Future<void> _syncLinkedProfileName() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    try {
      final profile = await fetchUserProfile();
      if (profile != null &&
          profile.displayName.trim().isEmpty &&
          user.displayName != null &&
          user.displayName!.trim().isNotEmpty) {
        await updateDisplayName(user.displayName!.trim());
      }
    } catch (e) {
      debugPrint('Optional profile name sync notice: $e');
    }
  }

  AppException _mapFirebaseAuthException(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    final combined = '$code $message';

    // Cancellation cases
    if (code == 'canceled' ||
        code == 'sign_in_canceled' ||
        code == 'web-context-cancelled' ||
        code == 'user-cancelled' ||
        code == '1001' ||
        combined.contains('1001') ||
        combined.contains('canceled') ||
        combined.contains('cancelled') ||
        combined.contains('authorizationerror error 1001')) {
      return AuthCancelledException(originalError: e);
    }

    // Missing Apple Account on device or simulator
    if (combined.contains('authorizationerror error 1000') ||
        combined.contains('authorizationerror') ||
        combined.contains('apple-account-required')) {
      return AuthAppleAccountRequiredException(originalError: e);
    }

    // Account conflict cases
    if (code == 'credential-already-in-use' ||
        code == 'email-already-in-use' ||
        code == 'account-exists-with-different-credential') {
      return AuthConflictException(
        message:
            'This account is already associated with another Denk profile.',
        code: e.code,
        credential: e.credential,
        conflictingEmail: e.email,
        originalError: e,
      );
    }

    // Provider already linked
    if (code == 'provider-already-linked') {
      return const AppException(
        message: 'This provider is already linked to your account.',
        code: 'provider-already-linked',
      );
    }

    return AppException.fromFirebase(e);
  }

  AppException _mapPlatformException(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    final combined = '$code $message';

    if (code == '1001' ||
        combined.contains('1001') ||
        combined.contains('canceled') ||
        combined.contains('cancelled') ||
        combined.contains('authorizationerror error 1001')) {
      return AuthCancelledException(originalError: e);
    }

    if (code == '1000' ||
        combined.contains('authorizationerror error 1000') ||
        combined.contains('authorizationerror') ||
        combined.contains('apple-account-required')) {
      return AuthAppleAccountRequiredException(originalError: e);
    }

    return AppException.fromFirebase(e);
  }

  Future<void> _cacheProfile(UserProfile profile) async {
    try {
      final localPrefs = prefs ?? await SharedPreferences.getInstance();
      final jsonStr = jsonEncode({
        'uid': profile.uid,
        'displayName': profile.displayName,
        'preferredCurrency': profile.preferredCurrency,
        'languageCode': profile.languageCode,
        'createdAt': profile.createdAt.toIso8601String(),
        'updatedAt': profile.updatedAt.toIso8601String(),
      });
      await localPrefs.setString(_prefProfileKey, jsonStr);
    } catch (e) {
      debugPrint('Cache profile failed: $e');
    }
  }

  Future<UserProfile?> _readCachedProfile() async {
    try {
      final localPrefs = prefs ?? await SharedPreferences.getInstance();
      final jsonStr = localPrefs.getString(_prefProfileKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return UserProfile.fromMap(map, map['uid'] as String? ?? '');
    } catch (e) {
      debugPrint('Read cached profile failed: $e');
      return null;
    }
  }

  Future<void> _clearCachedProfile() async {
    try {
      final localPrefs = prefs ?? await SharedPreferences.getInstance();
      await localPrefs.remove(_prefProfileKey);
    } catch (e) {
      debugPrint('Clear cached profile failed: $e');
    }
  }
}
