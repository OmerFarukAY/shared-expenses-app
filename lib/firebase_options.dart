// Firebase options for the Denk app (project: denk-262c0).
//
// iOS and Android platforms do NOT use this class at runtime.
// FirebaseCore reads credentials directly from the native config files:
//   iOS:     GoogleService-Info.plist  (bundled in Runner.app, gitignored)
//   Android: google-services.json      (processed by Gradle plugin, gitignored)
//
// This file only provides configuration for the Web platform.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  // Web config — see main.dart for how this is used.
  // Firebase client API keys are intentionally public identifiers.
  // Access control is enforced via Firebase Security Rules, not the key.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAx8_hVWRrEumSJfe4XJyWxPXIpWPAOVmA',
    appId: '1:173401764703:web:placeholder',
    messagingSenderId: '173401764703',
    projectId: 'denk-262c0',
    authDomain: 'denk-262c0.firebaseapp.com',
    storageBucket: 'denk-262c0.firebasestorage.app',
  );
}
