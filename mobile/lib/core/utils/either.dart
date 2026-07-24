/// Generic, immutable [Either] type: a [Left] failure or a [Right] success.
sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  L get left => (this as Left<L, R>).value;
  R get right => (this as Right<L, R>).value;

  T fold<T>(T Function(L l) onLeft, T Function(R r) onRight) {
    if (this is Left<L, R>) return onLeft((this as Left<L, R>).value);
    return onRight((this as Right<L, R>).value);
  }
}

final class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;
}

final class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;
}
