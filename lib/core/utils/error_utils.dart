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
        errStr.contains('403')) {
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
    if (errStr.contains('user_not_found') ||
        errStr.contains('invalid login credentials') ||
        errStr.contains('invalid_credentials')) {
      return "🔒 Invalid email or password. Please double-check your credentials and try again.";
    }
    if (errStr.contains('user already registered') ||
        errStr.contains('email_exists') ||
        errStr.contains('already in use')) {
      return "✉️ An account with this email address already exists. Please sign in instead.";
    }
    if (errStr.contains('row-level security') || errStr.contains('42501')) {
      return "🔒 Session expired or restricted. Please sign out and sign back in.";
    }
    if (errStr.contains('foreign key') || errStr.contains('23503')) {
      return "⚠️ The requested post or comment was not found on the server.";
    }
    if (errStr.contains('not-null constraint') || errStr.contains('23502')) {
      return "⚠️ Missing required information. Please complete all required fields.";
    }

    // 8. Extract clean message from custom Exception or object
    final String fullMsg = error.toString();
    final String cleanMsg = fullMsg.replaceAll(RegExp(r'^(Exception|PostgrestException|AuthException):\s*'), '').trim();
    if (!cleanMsg.contains('SocketException') &&
        !cleanMsg.contains('ClientException') &&
        !cleanMsg.contains('HttpException') &&
        !cleanMsg.contains('http://') &&
        !cleanMsg.contains('https://') &&
        cleanMsg.length > 5 &&
        cleanMsg.length < 100) {
      return cleanMsg;
    }

    // 9. Fallback User-Friendly Message
    final prefix = defaultPrefix != null ? "$defaultPrefix: " : "";
    return "${prefix}Something went wrong while processing your request. Please try again.";
  }

  /// Specialized method for formatting User Login, Sign Up, and Password Reset exceptions
  static String getAuthErrorMessage(dynamic error, {bool isSignUp = false}) {
    if (error == null) {
      return isSignUp
          ? "Account registration failed. Please try again."
          : "Sign in failed. Please check your credentials and try again.";
    }

    final String errStr = error.toString().toLowerCase();

    // 1. Internet / Connectivity
    if (error is SocketException ||
        error is HandshakeException ||
        errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('no address associated with hostname') ||
        errStr.contains('connection refused') ||
        errStr.contains('network_error') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('errno = 7')) {
      return "📡 Network Unavailable. Please check your internet connection and try again.";
    }

    // 2. Already Registered / Email Exists (Sign Up)
    if (errStr.contains('user already registered') ||
        errStr.contains('email_exists') ||
        errStr.contains('already in use') ||
        errStr.contains('already registered') ||
        errStr.contains('user_already_exists')) {
      return "✉️ An account with this email address already exists. Please sign in instead.";
    }

    // 3. Invalid Login Credentials / Wrong Password (Sign In)
    if (errStr.contains('invalid login credentials') ||
        errStr.contains('invalid_credentials') ||
        errStr.contains('wrong password') ||
        errStr.contains('invalid email or password') ||
        errStr.contains('invalid grant')) {
      return "🔒 Invalid email or password. Please double-check your credentials and try again.";
    }

    // 4. User Not Found
    if (errStr.contains('user_not_found') || errStr.contains('user not found')) {
      return "👤 No account found with this email address. Please check your email or sign up.";
    }

    // 5. Unconfirmed Email / Verification Required
    if (errStr.contains('email_not_confirmed') ||
        errStr.contains('email not confirmed') ||
        errStr.contains('confirm your email') ||
        errStr.contains('verification required')) {
      return "✉️ Email not verified. Please check your inbox and verify your address before logging in.";
    }

    // 6. Rate Limit / Too Many Attempts
    if (errStr.contains('over_email_send_rate_limit') ||
        errStr.contains('rate_limit') ||
        errStr.contains('too many requests') ||
        errStr.contains('too_many_requests') ||
        errStr.contains('429')) {
      return "⏳ Too many attempts. Please wait a minute before trying again.";
    }

    // 7. Weak Password
    if (errStr.contains('weak_password') ||
        errStr.contains('password should be at least') ||
        errStr.contains('password is too short')) {
      return "🔐 Password is too weak. Please use at least 6 characters with letters and numbers.";
    }

    // 8. Invalid Email Format
    if (errStr.contains('invalid_email') || errStr.contains('unable to validate email')) {
      return "📧 Please enter a valid email address.";
    }

    // 9. Supabase Unconfigured / Offline Mode
    if (errStr.contains('supabase is not configured') || errStr.contains('not configured')) {
      return "🌐 Cloud service is currently offline. You can continue as a Guest gardener!";
    }

    // 10. General Clean Error Fallback
    if (error is Exception) {
      final cleanMsg = error.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      if (!cleanMsg.contains('AuthException') &&
          !cleanMsg.contains('SocketException') &&
          !cleanMsg.contains('ClientException') &&
          !cleanMsg.contains('http') &&
          cleanMsg.length < 120) {
        return cleanMsg;
      }
    }

    return isSignUp
        ? "Unable to complete registration. Please check your details and try again."
        : "Unable to sign in. Please verify your credentials and try again.";
  }
}
