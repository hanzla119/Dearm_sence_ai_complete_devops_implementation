// File configured with real credentials from google-services.json.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCv6ipB95Zk35kMBsnxOJHGFsUa5ObhG2w',
    appId: '1:372117631486:web:a454dbe5061bdf1f2410af',
    messagingSenderId: '372117631486',
    projectId: 'dermasenseai-2c6f2',
    authDomain: 'dermasenseai-2c6f2.firebaseapp.com',
    storageBucket: 'dermasenseai-2c6f2.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCv6ipB95Zk35kMBsnxOJHGFsUa5ObhG2w',
    appId: '1:372117631486:android:a454dbe5061bdf1f2410af',
    messagingSenderId: '372117631486',
    projectId: 'dermasenseai-2c6f2',
    storageBucket: 'dermasenseai-2c6f2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCv6ipB95Zk35kMBsnxOJHGFsUa5ObhG2w',
    appId: '1:372117631486:ios:a454dbe5061bdf1f2410af',
    messagingSenderId: '372117631486',
    projectId: 'dermasenseai-2c6f2',
    storageBucket: 'dermasenseai-2c6f2.firebasestorage.app',
    iosBundleId: 'com.example.frontend',
  );
}
