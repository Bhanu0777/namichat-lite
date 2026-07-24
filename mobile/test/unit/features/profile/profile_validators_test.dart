import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/features/profile/presentation/validators/profile_validators.dart';

void main() {
  group('ProfileValidators', () {
    group('required', () {
      test('null returns error', () {
        expect(ProfileValidators.required(null), isNotNull);
      });

      test('empty string returns error', () {
        expect(ProfileValidators.required(''), isNotNull);
      });

      test('whitespace-only returns error', () {
        expect(ProfileValidators.required('   '), isNotNull);
      });

      test('non-empty string returns null', () {
        expect(ProfileValidators.required('Alice'), isNull);
      });

      test('custom label is used', () {
        expect(ProfileValidators.required('', label: 'Name'), 'Name is required');
      });
    });

    group('email', () {
      test('null returns error', () {
        expect(ProfileValidators.email(null), isNotNull);
      });

      test('string without @ returns error', () {
        expect(ProfileValidators.email('aliceexample.com'), isNotNull);
      });

      test('string with @ returns null', () {
        expect(ProfileValidators.email('alice@example.com'), isNull);
      });
    });

    group('username', () {
      test('null returns error', () {
        expect(ProfileValidators.username(null), isNotNull);
      });

      test('2 chars returns error', () {
        expect(ProfileValidators.username('ab'), isNotNull);
      });

      test('3 chars returns null', () {
        expect(ProfileValidators.username('abc'), isNull);
      });

      test('whitespace-padded 3 chars returns null', () {
        expect(ProfileValidators.username('  abc  '), isNull);
      });
    });

    group('namiId', () {
      test('null returns null (optional)', () {
        expect(ProfileValidators.namiId(null), isNull);
      });

      test('empty string returns null (optional)', () {
        expect(ProfileValidators.namiId(''), isNull);
      });

      test('2 chars returns error', () {
        expect(ProfileValidators.namiId('ab'), 'Nami ID must be at least 3 characters');
      });

      test('uppercase letters return error', () {
        expect(ProfileValidators.namiId('ABC'), 'Use lowercase letters, numbers, or dashes');
      });

      test('valid lowercase returns null', () {
        expect(ProfileValidators.namiId('wave-42'), isNull);
      });
    });

    group('bio', () {
      test('null returns null (optional)', () {
        expect(ProfileValidators.bio(null), isNull);
      });

      test('empty string returns null (optional)', () {
        expect(ProfileValidators.bio(''), isNull);
      });

      test('160 chars returns null', () {
        expect(ProfileValidators.bio('a' * 160), isNull);
      });

      test('161 chars returns error', () {
        expect(ProfileValidators.bio('a' * 161), 'Bio can be at most 160 characters');
      });
    });
  });
}
