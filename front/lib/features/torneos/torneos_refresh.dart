import 'package:flutter/foundation.dart';

class TorneosRefresh {
  TorneosRefresh._();

  static final TorneosRefresh instance = TorneosRefresh._();

  /// Incrementa el valor para notificar a listeners.
  final ValueNotifier<int> tick = ValueNotifier<int>(0);

  void notify() {
    tick.value = tick.value + 1;
  }
}
