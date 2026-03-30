import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_app/firebase_options.dart';

/// Initializes Firebase for the current platform.
///
/// When `firebase_options.dart` still has placeholders, Android/iOS use the
/// native default app from `google-services.json` / `GoogleService-Info.plist`
/// via [Firebase.initializeApp] with no options (avoids passing invalid API keys
/// through the method channel).
Future<void> initializeFirebaseApp() async {
  if (DefaultFirebaseOptions.usesPlaceholderOptions) {
    if (kIsWeb) {
      throw StateError(
        'Firebase is not configured for web. Run:\n'
        '  dart pub global activate flutterfire_cli\n'
        '  flutterfire configure',
      );
    }
    try {
      await Firebase.initializeApp();
    } catch (e, st) {
      debugPrint(
        'Firebase.initializeApp() failed: $e\n'
        'Fix: add real Firebase Android/iOS app files from the console, then run:\n'
        '  flutterfire configure',
      );
      Error.throwWithStackTrace(e, st);
    }
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
