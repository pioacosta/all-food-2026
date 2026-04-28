import 'package:flutter/services.dart';

class ErrorFeedback {
  static void vibrate() {
    HapticFeedback.mediumImpact();
  }
}
