import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase is only configured for Android and Web.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAQ1mxQUzWn9SBflEv3HCOs1r2hrS-12vE',
    appId: '1:1085357682452:web:2992822c25bb989f7b9c01',
    messagingSenderId: '1085357682452',
    projectId: 'wifivoucherapp-9be19',
    authDomain: 'wifivoucherapp-9be19.firebaseapp.com',
    storageBucket: 'wifivoucherapp-9be19.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQ1mxQUzWn9SBflEv3HCOs1r2hrS-12vE',
    appId: '1:1085357682452:android:59a5972f37bbaea37b9c01',
    messagingSenderId: '1085357682452',
    projectId: 'wifivoucherapp-9be19',
    storageBucket: 'wifivoucherapp-9be19.firebasestorage.app',
  );
}
