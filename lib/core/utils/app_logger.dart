import 'package:flutter/foundation.dart';

/// Production-safe logger — only outputs in debug builds.
class AppLogger {
  static const String _prefix = '🌿 PlantCare';

  static void info(String message) {
    if (kDebugMode) debugPrint('$_prefix [INFO] $message');
  }

  static void warning(String message) {
    if (kDebugMode) debugPrint('$_prefix [WARN] ⚠️ $message');
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) debugPrint('$_prefix [ERROR] 🔴 $message${error != null ? ": $error" : ""}');
  }

  static void success(String message) {
    if (kDebugMode) debugPrint('$_prefix [OK] ✅ $message');
  }
}
