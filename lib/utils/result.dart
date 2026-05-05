sealed class Result<S, F extends Exception> {
  const Result();
}

class Success<S, F extends Exception> extends Result<S, F> {
  const Success(this.value);
  final S value;
}

class Failure<S, F extends Exception> extends Result<S, F> {
  const Failure(this.exception);
  final F exception;
}
