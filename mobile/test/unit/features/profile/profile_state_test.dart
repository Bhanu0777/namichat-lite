import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/features/profile/presentation/providers/profile_state.dart';

void main() {
  group('ProfileState', () {
    test('default state is initial with no user', () {
      const state = ProfileState();
      expect(state.status, ProfileStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const original = ProfileState(
        status: ProfileStatus.loaded,
        errorMessage: null,
      );
      final copy = original.copyWith(status: ProfileStatus.error);
      expect(copy.status, ProfileStatus.error);
    });

    test('copyWith clearError nullifies errorMessage', () {
      const original = ProfileState(
        status: ProfileStatus.error,
        errorMessage: 'something broke',
      );
      final copy = original.copyWith(clearError: true);
      expect(copy.errorMessage, isNull);
    });

    test('copyWith does not clear error without flag', () {
      const original = ProfileState(
        status: ProfileStatus.error,
        errorMessage: 'bad',
      );
      final copy = original.copyWith(status: ProfileStatus.loading);
      expect(copy.errorMessage, 'bad');
    });

    test('equality holds for identical states', () {
      const a = ProfileState(status: ProfileStatus.initial);
      const b = ProfileState(status: ProfileStatus.initial);
      expect(a, equals(b));
    });

    test('equality fails when status differs', () {
      const a = ProfileState(status: ProfileStatus.initial);
      const b = ProfileState(status: ProfileStatus.loading);
      expect(a, isNot(equals(b)));
    });
  });
}
