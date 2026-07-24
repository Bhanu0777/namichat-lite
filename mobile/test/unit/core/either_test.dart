import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';

void main() {
  group('Either', () {
    group('Right', () {
      test('isRight is true', () {
        const e = Right<Failure, int>(42);
        expect(e.isRight, isTrue);
        expect(e.isLeft, isFalse);
      });

      test('right returns the value', () {
        const e = Right<Failure, String>('hello');
        expect(e.right, 'hello');
      });

      test('fold calls onRight', () {
        const e = Right<Failure, int>(10);
        final result = e.fold((_) => -1, (v) => v * 2);
        expect(result, 20);
      });
    });

    group('Left', () {
      test('isLeft is true', () {
        const e = Left<Failure, int>(ServerFailure('oops'));
        expect(e.isLeft, isTrue);
        expect(e.isRight, isFalse);
      });

      test('left returns the failure', () {
        const failure = ServerFailure('something broke', 500);
        const e = Left<Failure, int>(failure);
        expect(e.left, failure);
      });

      test('fold calls onLeft', () {
        const e = Left<Failure, int>(NetworkFailure());
        final result = e.fold((f) => f.message, (_) => 'ok');
        expect(result, 'No internet connection');
      });
    });

    group('Failure hierarchy', () {
      test('ServerFailure carries status code', () {
        const f = ServerFailure('bad gateway', 502);
        expect(f.message, 'bad gateway');
        expect(f.code, 502);
      });

      test('NetworkFailure has default message', () {
        const f = NetworkFailure();
        expect(f.message, 'No internet connection');
      });

      test('ValidationFailure carries message', () {
        const f = ValidationFailure('Name too short');
        expect(f.message, 'Name too short');
      });

      test('AuthFailure carries code', () {
        const f = AuthFailure('Unauthorized', 401);
        expect(f.code, 401);
      });
    });
  });
}
