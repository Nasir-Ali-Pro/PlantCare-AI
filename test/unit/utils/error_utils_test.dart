import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_app/core/utils/error_utils.dart';

void main() {
  group('AppErrorUtils Exception Translation Tests', () {
    test('Translates SocketException / Failed host lookup to friendly network error', () {
      const error = SocketException("Failed host lookup: 'generativelanguage.googleapis.com' (OS Error: No address associated with hostname, errno = 7)");
      final msg = AppErrorUtils.getUserFriendlyMessage(error);
      expect(msg, contains('📡 Network Unavailable'));
      expect(msg, contains('Please check your internet connection'));
    });

    test('Translates Gemini rate limit / RESOURCE_EXHAUSTED to quota friendly error', () {
      final error = Exception("GoogleGenerativeAIException: RESOURCE_EXHAUSTED - Quota limit reached (429)");
      final msg = AppErrorUtils.getUserFriendlyMessage(error);
      expect(msg, contains('The AI Doctor is currently unavailable'));
    });

    test('Translates TimeoutException to connection timeout error', () {
      final error = TimeoutException("Connection timed out after 10000ms");
      final msg = AppErrorUtils.getUserFriendlyMessage(error);
      expect(msg, contains('⏱️ Connection Timed Out'));
    });

    test('Translates API key / Unauthorized errors cleanly', () {
      final error = Exception("API_KEY_INVALID: Permission denied (401)");
      final msg = AppErrorUtils.getUserFriendlyMessage(error);
      expect(msg, contains('🔑 Authentication Failed'));
    });

    test('Translates 500/503 server errors cleanly', () {
      final error = Exception("503 Service Unavailable");
      final msg = AppErrorUtils.getUserFriendlyMessage(error);
      expect(msg, contains('☁️ Server is temporarily unavailable'));
    });

    test('Sanitizes generic fallback errors cleanly without technical stacktraces', () {
      final error = Exception("ClientException with SocketException: Failed host lookup");
      final msg = AppErrorUtils.getUserFriendlyMessage(error);
      expect(msg, isNot(contains('ClientException')));
      expect(msg, isNot(contains('SocketException')));
    });
  });
}
