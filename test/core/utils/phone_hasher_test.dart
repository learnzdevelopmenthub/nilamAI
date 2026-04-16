import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/core/utils/phone_hasher.dart';

void main() {
  group('PhoneHasher', () {
    test('produces deterministic hash for same input', () {
      final hash1 = PhoneHasher.hash('9876543210');
      final hash2 = PhoneHasher.hash('9876543210');
      expect(hash1, equals(hash2));
    });

    test('produces different hashes for different inputs', () {
      final hash1 = PhoneHasher.hash('9876543210');
      final hash2 = PhoneHasher.hash('9876543211');
      expect(hash1, isNot(equals(hash2)));
    });

    test('produces 64-character hex string (SHA-256)', () {
      final hash = PhoneHasher.hash('9876543210');
      expect(hash.length, equals(64));
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('normalizes +91 prefix', () {
      final withPrefix = PhoneHasher.hash('+919876543210');
      final withoutPrefix = PhoneHasher.hash('9876543210');
      expect(withPrefix, equals(withoutPrefix));
    });

    test('normalizes 91 prefix (12 digits)', () {
      final withPrefix = PhoneHasher.hash('919876543210');
      final withoutPrefix = PhoneHasher.hash('9876543210');
      expect(withPrefix, equals(withoutPrefix));
    });

    test('strips whitespace and dashes', () {
      final clean = PhoneHasher.hash('9876543210');
      final withSpaces = PhoneHasher.hash('987 654 3210');
      final withDashes = PhoneHasher.hash('987-654-3210');
      expect(withSpaces, equals(clean));
      expect(withDashes, equals(clean));
    });

    test('throws DatabaseException for too few digits', () {
      expect(
        () => PhoneHasher.hash('12345'),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('throws DatabaseException for too many digits', () {
      expect(
        () => PhoneHasher.hash('12345678901234'),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('throws DatabaseException for non-numeric input', () {
      expect(
        () => PhoneHasher.hash('abcdefghij'),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('throws DatabaseException for empty input', () {
      expect(
        () => PhoneHasher.hash(''),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
