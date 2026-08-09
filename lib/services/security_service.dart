import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

class SecurityService {
  // ── Hashing ─────────────────────────────────────────────
  // Uses dart team's package:crypto (SHA-256) instead of a custom implementation
  // to guarantee correctness and security.

  static List<int> sha256Bytes(List<int> data) {
    return sha256.convert(data).bytes;
  }

  static String sha256String(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // ── Cryptographic Keystream Symmetric Cipher ────────────

  /// Symmetric Encryption using AES-256 CBC mode with PKCS7 padding.
  /// The key is derived from the secret via SHA-256.
  static String encrypt(String plaintext, String secretKey) {
    if (plaintext.isEmpty) return '';
    try {
      final keyBytes = sha256Bytes(utf8.encode(secretKey));
      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV.fromSecureRandom(16);

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      final combined = BytesBuilder()
        ..add(iv.bytes)
        ..add(encrypted.bytes);

      return base64.encode(combined.toBytes());
    } catch (e) {
      debugPrint('🚨 Encryption error: $e');
      return '';
    }
  }

  /// Symmetric Decryption using AES-256 CBC mode with PKCS7 padding.
  static String decrypt(String ciphertext, String secretKey) {
    if (ciphertext.isEmpty) return '';
    try {
      final decodedBytes = base64.decode(ciphertext);
      if (decodedBytes.length < 16) return '';

      final ivBytes = decodedBytes.sublist(0, 16);
      final encryptedBytes = decodedBytes.sublist(16);

      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypted = enc.Encrypted(Uint8List.fromList(encryptedBytes));

      final keyBytes = sha256Bytes(utf8.encode(secretKey));
      final key = enc.Key(Uint8List.fromList(keyBytes));

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('🚨 Decryption error: $e');
      return '';
    }
  }

  // ── Integrity Protection ────────────────────────────────

  /// Generate a secure integrity signature for local JSON data.
  static String generateSignature(String dataJson, String secretSalt) {
    return sha256String(dataJson + secretSalt);
  }

  /// Verify local JSON integrity against its stored checksum.
  /// Uses a constant-time comparison to prevent timing attacks.
  static bool verifySignature(
      String dataJson, String storedSignature, String secretSalt) {
    final computed = generateSignature(dataJson, secretSalt);
    // Constant-time comparison: compare every byte even if a mismatch is found early
    if (computed.length != storedSignature.length) return false;
    var result = 0;
    for (var i = 0; i < computed.length; i++) {
      result |= computed.codeUnitAt(i) ^ storedSignature.codeUnitAt(i);
    }
    return result == 0;
  }

  // ── Input Sanitization ──────────────────────────────────

  /// Cleanses user input text from HTML/scripts or possible injection payloads.
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
        .replaceAll(r'$', r'\$') // Escape currency signs/formula bindings
        .replaceAll(RegExp(r'[\x00\x1a\xff]'), '') // Strip control chars
        .trim();
  }
}
