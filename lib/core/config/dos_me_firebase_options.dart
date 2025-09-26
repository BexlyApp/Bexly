import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DOSMeFirebaseOptions {
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
        throw UnsupportedError(
          'DOS-Me Firebase options have not been configured for macOS',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DOS-Me Firebase options have not been configured for windows',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DOS-Me Firebase options have not been configured for linux',
        );
      default:
        throw UnsupportedError(
          'DOS-Me Firebase options are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBwUcP2tCRIQiDMZduOod7lPQJy9jDcJLM',
    appId: '1:368090586626:android:5702bedad5db10a077511b',
    messagingSenderId: '368090586626',
    projectId: 'dos-me',
    storageBucket: 'dos-me.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBwUcP2tCRIQiDMZduOod7lPQJy9jDcJLM',  // Same API key for iOS
    appId: '1:368090586626:ios:612a3e89230058e977511b',
    messagingSenderId: '368090586626',
    projectId: 'dos-me',
    storageBucket: 'dos-me.firebasestorage.app',
    iosBundleId: 'com.joy.bexly',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwUcP2tCRIQiDMZduOod7lPQJy9jDcJLM',
    appId: '1:368090586626:web:c6258a12974dc08b77511b',
    messagingSenderId: '368090586626',
    projectId: 'dos-me',
    authDomain: 'dos-me.firebaseapp.com',
    storageBucket: 'dos-me.firebasestorage.app',
  );
}