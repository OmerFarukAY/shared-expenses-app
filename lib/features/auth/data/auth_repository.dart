import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/auth/domain/user_profile.dart';

/// Contract for authentication and minimal user profile operations.
abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  String? get currentUid;
  Future<String> ensureAnonymousUser();
  Future<UserProfile?> fetchUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> updateDisplayName(String newName);
  Future<void> deleteAccount();
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
  String? get currentUid => _firebaseAuth.currentUser?.uid;

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
        try {
          await _firestore.collection('users').doc(uid).delete();
        } catch (e) {
          debugPrint('Firestore user doc deletion warning: $e');
        }
      }

      await _clearCachedProfile();

      if (_firebaseAuth.currentUser != null) {
        try {
          await _firebaseAuth.currentUser!.delete();
        } catch (_) {
          await _firebaseAuth.signOut();
        }
      }
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      throw AppException.fromFirebase(e);
    }
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
