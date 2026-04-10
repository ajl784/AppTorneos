import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000/api/v1';
    }
    // Android emulador usa 10.0.2.2, otros usan localhost
    return _isAndroid() ? 'http://10.0.2.2:3000/api/v1' : 'http://127.0.0.1:3000/api/v1';
  }

  static bool _isAndroid() {
    try {
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (_) {
      return false;
    }
  }
}
