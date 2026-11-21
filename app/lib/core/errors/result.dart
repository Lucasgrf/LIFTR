import 'package:personal_fitness_os/core/errors/failures.dart';

sealed class Result<S, F extends Failure> {
  const Result();

  T fold<T>(
    T Function(S success) onSuccess,
    T Function(F failure) onFailure,
  ) {
    return switch (this) {
      Success(value: final v) => onSuccess(v),
      Err(failure: final e) => onFailure(e),
    };
  }

  Result<T, F> map<T>(T Function(S success) transform) {
    return switch (this) {
      Success(value: final v) => Success(transform(v)),
      Err(failure: final e) => Err(e),
    };
  }

  Result<S, NewF> mapError<NewF extends Failure>(NewF Function(F failure) transform) {
    return switch (this) {
      Success(value: final v) => Success(v),
      Err(failure: final e) => Err(transform(e)),
    };
  }

  S getOrElse(S Function(F failure) orElse) {
    return switch (this) {
      Success(value: final v) => v,
      Err(failure: final e) => orElse(e),
    };
  }

  bool get isSuccess => this is Success<S, F>;
  bool get isError => this is Err<S, F>;
}

class Success<S, F extends Failure> extends Result<S, F> {
  const Success(this.value);
  final S value;
}

class Err<S, F extends Failure> extends Result<S, F> {
  const Err(this.failure);
  final F failure;
}
