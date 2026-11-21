sealed class Failure {
  const Failure(this.message, [this.stackTrace]);
  final String message;
  final StackTrace? stackTrace;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.stackTrace]);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.stackTrace]);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.stackTrace]);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.stackTrace]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.stackTrace]);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, [super.stackTrace]);
}
