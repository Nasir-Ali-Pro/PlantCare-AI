import 'dart:async';
import 'dart:io';

/// Centralized utility for converting raw exceptions, network errors, and API quota errors
/// into concise, friendly, human-readable messages for UI display.
class AppErrorUtils {
  /// Converts any technical exception or error string into a short, professional,
  /// user-friendly error message suitable for UI display.
  static String getUserFriendlyMessage(dynamic error, {String? defaultPrefix}) {
    if (error == null) {
      return "An unexpected error occurred. Please try again.";
    }

    final String errStr = error.toString().toLowerCase();

    // 1. Internet / Connectivity / Host Lookup Errors
    if (error is SocketException ||
        error is HandshakeException ||
        errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('no address associated with hostname') ||
        errStr.contains('connection refused') ||
        errStr.contains('network_error') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('connection closed') ||
        errStr.contains('errno = 7')) {
      return "📡 Network Unavailable. Please check your internet connection and try again.";
    }

    // 2. Timeout Errors
    if (error is TimeoutException || errStr.contains('timeout') || errStr.contains('timed out')) {
      return "⏱️ Connection Timed Out. Please check your network connection and try again.";
    }

    // 3. Gemini / AI Rate Limit & Free Token Quota Exceeded Errors
    if (errStr.contains('resource_exhausted') ||
        errStr.contains('quota') ||
        errStr.contains('rate_limit') ||
        errStr.contains('429') ||
        errStr.contains('too many requests') ||
        errStr.contains('tokens per minute') ||
        errStr.contains('requests per minute') ||
        errStr.contains('limit reached')) {
      return "🩺 The AI Doctor is currently unavailable. Please try again in a few moments.";
    }

    // 4. API Key / Authentication Errors
    if (errStr.contains('api_key') ||
        errStr.contains('api key') ||
        errStr.contains('unauthorized') ||
        errStr.contains('permission_denied') ||
        errStr.contains('401') ||
        errStr.contains('403') ||
        errStr.contains('invalid credentials')) {
      return "🔑 Authentication Failed. Please check your API key or credentials in settings.";
    }

    // 5. Server / Cloud Unavailable Errors (500, 502, 503, 504)
    if (errStr.contains('500') ||
        errStr.contains('502') ||
        errStr.contains('503') ||
        errStr.contains('504') ||
        errStr.contains('server error') ||
        errStr.contains('bad gateway') ||
        errStr.contains('service unavailable')) {
      return "☁️ Server is temporarily unavailable. Please try again in a few moments.";
    }

    // 6. Camera / Hardware Permission Errors
    if (errStr.contains('camera_access_denied') || errStr.contains('permission denied')) {
      return "📷 Camera permission required. Please grant camera access in settings.";
    }

    // 7. Supabase Database & Auth Errors
    if (errStr.contains('user_not_found') || errStr.contains('invalid login credentials')) {
      return "🔒 Invalid email or password. Please check your credentials and try again.";
    }
    if (errStr.contains('user already registered') || errStr.contains('email_exists')) {
      return "✉️ An account with this email already exists. Please log in instead.";
    }

    // 8. Custom user-facing Exception messages (if already formatted cleanly without technical stacktraces)
    if (error is Exception) {
      final cleanMsg = error.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      if (!cleanMsg.contains('SocketException') &&
          !cleanMsg.contains('ClientException') &&
          !cleanMsg.contains('HttpException') &&
          !cleanMsg.contains('http://') &&
          !cleanMsg.contains('https://') &&
          cleanMsg.length < 120) {
        return cleanMsg;
      }
    }

    // 9. Fallback User-Friendly Message
    final prefix = defaultPrefix != null ? "$defaultPrefix: " : "";
    return "${prefix}Something went wrong while processing your request. Please try again.";
  }
}
