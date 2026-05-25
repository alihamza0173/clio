sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class ProcessFailure extends Failure {
  const ProcessFailure(super.message);
}

class PtyFailure extends Failure {
  const PtyFailure(super.message);
}
