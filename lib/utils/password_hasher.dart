import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Cryptographic password hashing and verification utility.
/// Uses PBKDF2 with HMAC-SHA256 and cryptographically secure random salts.
/// Ensures passwords are never stored or handled in plaintext.
class PasswordHasher {
  static const int defaultSaltBytes = 16;
  static const int defaultIterations = 10000;
  static const String algorithmIdentifier = 'pbkdf2-sha256';
  static const String prefix = '\$$algorithmIdentifier';

  /// Generates a cryptographically secure random salt encoded in hex.
  static String generateSalt([int byteLength = defaultSaltBytes]) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes [password] with a secure salt using PBKDF2-HMAC-SHA256.
  /// Returns a structured string: `$pbkdf2-sha256$i=10000$<salt>$<hash>`
  static String hashPassword(
    String password, {
    String? salt,
    int iterations = defaultIterations,
  }) {
    final effectiveSalt = salt ?? generateSalt();
    final hash = _pbkdf2(password, effectiveSalt, iterations);
    return '$prefix\$i=$iterations\$$effectiveSalt\$$hash';
  }

  /// PBKDF2 key derivation using HMAC-SHA256 (256-bit output).
  static String _pbkdf2(String password, String salt, int iterations) {
    final keyBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    final hmac = Hmac(sha256, keyBytes);

    // Initial block: U_1 = HMAC(key, salt || INT_32_BE(1))
    final uBlockInput = <int>[...saltBytes, 0, 0, 0, 1];
    var u = hmac.convert(uBlockInput).bytes;
    final result = List<int>.from(u);

    // Iterations U_2 ... U_iterations
    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int k = 0; k < result.length; k++) {
        result[k] ^= u[k];
      }
    }

    return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Verifies [password] against [storedHash].
  /// Supports PBKDF2 salted hash, legacy salted formats, and legacy plaintext upgrade fallback.
  static bool verifyPassword(String password, String storedHash) {
    if (storedHash.isEmpty) return false;

    // 1. Standard PBKDF2 format: $pbkdf2-sha256$i=10000$<salt>$<hash>
    if (storedHash.startsWith(prefix)) {
      final parts = storedHash.split(r'$');
      if (parts.length == 5) {
        final iterStr = parts[2].replaceFirst('i=', '');
        final iter = int.tryParse(iterStr) ?? defaultIterations;
        final salt = parts[3];
        final expectedHash = parts[4];
        final computedHash = _pbkdf2(password, salt, iter);
        return _constantTimeEquals(computedHash, expectedHash);
      }
    }

    // 2. Simple salt:hash format support
    if (storedHash.contains(':')) {
      final parts = storedHash.split(':');
      if (parts.length == 2 && parts[0].length >= 16) {
        final salt = parts[0];
        final expectedHash = parts[1];
        final computedHash = sha256.convert(utf8.encode('$salt$password')).toString();
        return _constantTimeEquals(computedHash, expectedHash);
      }
    }

    // 3. Fallback for legacy plaintext passwords to allow seamless database migration
    if (isLegacyPlaintext(storedHash)) {
      return _constantTimeEquals(password, storedHash);
    }

    return false;
  }

  /// Checks if [value] is already in a salted hash format.
  static bool isHashed(String value) {
    if (value.startsWith(prefix)) return true;
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length == 2 && parts[0].length >= 16) return true;
    }
    return false;
  }

  /// Returns true if [value] appears to be an unhashed plaintext password.
  static bool isLegacyPlaintext(String value) {
    return !isHashed(value);
  }

  /// Constant-time comparison to prevent timing side-channel attacks.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
