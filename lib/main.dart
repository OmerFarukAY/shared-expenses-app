import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:denk/app.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  try {
    // iOS reads GoogleService-Info.plist; Android reads google-services.json.
    // Both are gitignored and bundled locally — never committed to source.
    await Firebase.initializeApp();

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
    FlutterNativeSplash.remove();
  }

  runApp(const ProviderScope(child: DenkApp()));
}
