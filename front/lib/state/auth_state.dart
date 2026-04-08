import 'package:flutter/foundation.dart';

class AuthState {
  AuthState._();

  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
}
