// Firebase: mytowncabs-3eadc · Android app (com.mytowncabs.app), iOS app (com.mytown.cabs).
// Web values are still placeholders until `flutterfire configure`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// `true` until [flutterfire configure](https://firebase.flutter.dev/docs/cli/) replaces API keys.
  static bool get usesPlaceholderOptions {
    if (kIsWeb) {
      return web.apiKey == 'REPLACE_ME' || web.apiKey.isEmpty;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android.apiKey == 'REPLACE_ME' || android.apiKey.isEmpty;
      case TargetPlatform.iOS:
        return ios.apiKey == 'REPLACE_ME' || ios.apiKey.isEmpty;
      default:
        return true;
    }
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS is not configured');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:606763588417:web:CONFIGURE_IN_FIREBASE_CONSOLE',
    messagingSenderId: '606763588417',
    projectId: 'mytowncabs-3eadc',
    authDomain: 'mytowncabs-3eadc.firebaseapp.com',
    storageBucket: 'mytowncabs-3eadc.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAW0HVBpHg-vijWzzujjqsb4o6Ql5Bfuvo',
    appId: '1:606763588417:android:89b293e3671474c4d61fc0',
    messagingSenderId: '606763588417',
    projectId: 'mytowncabs-3eadc',
    storageBucket: 'mytowncabs-3eadc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD0p2kmB62eSu5O9NQ5bDVvWy8v38qYiBU',
    appId: '1:606763588417:ios:4161efad2288b5ecd61fc0',
    messagingSenderId: '606763588417',
    projectId: 'mytowncabs-3eadc',
    storageBucket: 'mytowncabs-3eadc.firebasestorage.app',
    iosBundleId: 'com.mytown.cabs',
  );
}
