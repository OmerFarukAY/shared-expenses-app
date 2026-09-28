import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const ProviderScope(child: DenkApp()));
}
