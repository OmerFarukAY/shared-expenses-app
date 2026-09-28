import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:denk/firebase_options.dart';
import 'package:denk/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      // Web requires explicit options — native platforms read from bundled
      // config files (GoogleService-Info.plist / google-services.json).
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      // iOS reads GoogleService-Info.plist; Android reads google-services.json.
      // Both are gitignored and bundled locally — never committed to source.
      await Firebase.initializeApp();
    }

    // Initialize Firebase App Check.
    // In debug mode, uses DebugProvider so developers and iOS Simulators / Android emulators
    // are not blocked.
    // In production release mode, uses AppleAppAttestWithDeviceCheckFallbackProvider for iOS
    // and AndroidPlayIntegrityProvider for Android.
    await FirebaseAppCheck.instance.activate(
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const ProviderScope(child: DenkApp()));
}
