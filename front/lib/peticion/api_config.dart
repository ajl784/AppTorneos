import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      final host = Uri.base.host;
      final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
      if (host.isEmpty) {
        return 'http://127.0.0.1:3000/api/v1';
      }
      return '$scheme://$host:3000/api/v1';
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
