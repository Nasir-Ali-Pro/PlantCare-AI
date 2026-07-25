import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

class SecurityService {
  /// Pure-Dart SHA-256 standard hash implementation (Zero external dependencies).
  static List<int> sha256Bytes(List<int> data) {
    // SHA-256 Constants
    final List<int> k = const [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ];

    // Initial state values
    int h0 = 0x6a09e667;
    int h1 = 0xbb67ae85;
    int h2 = 0x3c6ef372;
    int h3 = 0xa54ff53a;
    int h4 = 0x510e527f;
    int h5 = 0x9b05688c;
    int h6 = 0x1f83d9ab;
    int h7 = 0x5be0cd19;

    // Pre-processing (Padding)
    final int l = data.length * 8; // length in bits
    final List<int> padded = List<int>.from(data)..add(0x80);
    while ((padded.length * 8 + 64) % 512 != 0) {
      padded.add(0);
    }
    
    // Append length in bits as a 64-bit big-endian integer
    final high = (l ~/ 4294967296) & 0xFFFFFFFF;
    final low = l & 0xFFFFFFFF;
    final bd = ByteData(8)
      ..setUint32(0, high, Endian.big)
      ..setUint32(4, low, Endian.big);
    padded.addAll(bd.buffer.asUint8List());

    // Process in 512-bit (64-byte) blocks
    for (int i = 0; i < padded.length; i += 64) {
      final w = List<int>.filled(64, 0);
      for (int t = 0; t < 16; t++) {
        w[t] = (padded[i + t * 4] << 24) |
               (padded[i + t * 4 + 1] << 16) |
               (padded[i + t * 4 + 2] << 8) |
               padded[i + t * 4 + 3];
      }

      for (int t = 16; t < 64; t++) {
        final s0 = _rotr(w[t - 15], 7) ^ _rotr(w[t - 15], 18) ^ (w[t - 15] >> 3);
        final s1 = _rotr(w[t - 2], 17) ^ _rotr(w[t - 2], 19) ^ (w[t - 2] >> 10);
        w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & 0xFFFFFFFF;
      }

      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;
      int f = h5;
      int g = h6;
      int h = h7;

      for (int t = 0; t < 64; t++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ (~e & g);
        final temp1 = (h + s1 + ch + k[t] + w[t]) & 0xFFFFFFFF;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xFFFFFFFF;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xFFFFFFFF;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
      h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF;
      h7 = (h7 + h) & 0xFFFFFFFF;
    }

    final out = ByteData(32);
    out.setUint32(0, h0, Endian.big);
    out.setUint32(4, h1, Endian.big);
    out.setUint32(8, h2, Endian.big);
    out.setUint32(12, h3, Endian.big);
    out.setUint32(16, h4, Endian.big);
    out.setUint32(20, h5, Endian.big);
    out.setUint32(24, h6, Endian.big);
    out.setUint32(28, h7, Endian.big);
    return out.buffer.asUint8List();
  }

  static String sha256String(String input) {
    final bytes = utf8.encode(input);
    final hashed = sha256Bytes(bytes);
    return hashed.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static int _rotr(int val, int count) =>
      ((val >> count) | (val << (32 - count))) & 0xFFFFFFFF;

  // ── Cryptographic Keystream Symmetric Cipher ────────────

  /// Symmetric Encryption using AES-256 block feedback (CBC mode, PKCS7 padding)
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
      debugPrint("🚨 Encryption error: $e");
      return '';
    }
  }

  /// Symmetric Decryption using AES-256 block feedback (CBC mode, PKCS7 padding)
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
      debugPrint("🚨 Decryption error: $e");
      return '';
    }
  }

  // ── Integrity Protection ────────────────────────────────

  /// Generate a secure integrity signature/checksum for local JSON data
  static String generateSignature(String dataJson, String secretSalt) {
    return sha256String(dataJson + secretSalt);
  }

  /// Verify local JSON integrity against its stored checksum
  static bool verifySignature(String dataJson, String storedSignature, String secretSalt) {
    final computed = generateSignature(dataJson, secretSalt);
    return computed == storedSignature;
  }

  // ── Input Sanitization ──────────────────────────────────

  /// Cleanses user input text from HTML/scripts or possible injection payloads
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
        .replaceAll(r'$', r'\$') // Escape currency signs/formula bindings
        .replaceAll(RegExp(r'[\x00\x1a\xff]'), '') // Strip control chars
        .trim();
  }
}
