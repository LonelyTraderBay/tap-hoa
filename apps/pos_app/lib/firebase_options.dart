/// Placeholder Firebase options. Replace with `flutterfire configure` output.
/// Without real options, [PushService] skips FCM and the app still runs.
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web options not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        // Dummy project values — real apps must replace via FlutterFire.
        // initializeApp will fail if this project does not exist; PushService
        // catches that and continues without push.
        return const FirebaseOptions(
          apiKey: 'REPLACE_ME',
          appId: '1:000000000000:web:0000000000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'tap-hoa-unconfigured',
          storageBucket: 'tap-hoa-unconfigured.appspot.com',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
