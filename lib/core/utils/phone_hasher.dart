import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../exceptions/app_exception.dart';
import '../logging/logger.dart';

/// Utility for hashing phone numbers using HMAC-SHA256.
///
/// Phone numbers are never stored in plaintext. This class normalizes
/// the input (strips country code, whitespace) and produces a
/// deterministic hex-encoded hash.
class PhoneHasher {
  PhoneHasher._();

  // TODO(phase-2.1): Move salt to --dart-define for production builds.
  static const String _salt = 'NilamAI_2026_agri_phone_salt_v1';

  /// Normalizes and hashes a phone number using HMAC-SHA256.
  ///
  /// Accepts formats: `9876543210`, `+919876543210`, `91 9876543210`.
  /// Returns a 64-character hex string.
  ///
  /// Throws [DatabaseException] if the phone number is invalid.
  static String hash(String phoneNumber) {
    final normalized = _normalize(phoneNumber);
    final hmac = Hmac(sha256, utf8.encode(_salt));
    final digest = hmac.convert(utf8.encode(normalized));
    AppLogger.debug('Phone number hashed successfully', 'PhoneHasher');
    return digest.toString();
  }

  /// Strips whitespace, dashes, and the +91/91 country code prefix.
  /// Validates that the result is exactly 10 digits.
  static String _normalize(String phoneNumber) {
    var cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-()]'), '');

    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }

    if (cleaned.length != 10 || !RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      throw const DatabaseException(
        message: 'Invalid phone number: must be 10 digits',
      );
    }

    return cleaned;
  }
}
