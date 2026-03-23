// Remplace ce fichier par la sortie de : dart run flutterfire_cli:flutterfire configure
// (les clés ci-dessous sont des placeholders — elles doivent correspondre à la console Firebase.)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyReplaceMeFromFirebaseConsole',
    appId: '1:123456789012:android:abcdef0123456789abcdef',
    messagingSenderId: '123456789012',
    projectId: 'oklifor-dev-setup',
    storageBucket: 'oklifor-dev-setup.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyReplaceMeFromFirebaseConsole',
    appId: '1:123456789012:ios:abcdef0123456789abcdef',
    messagingSenderId: '123456789012',
    projectId: 'oklifor-dev-setup',
    storageBucket: 'oklifor-dev-setup.appspot.com',
    iosBundleId: 'com.example.okliforDatingApp',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummyReplaceMeFromFirebaseConsole',
    appId: '1:123456789012:web:abcdef0123456789abcdef',
    messagingSenderId: '123456789012',
    projectId: 'oklifor-dev-setup',
    storageBucket: 'oklifor-dev-setup.appspot.com',
  );
}
