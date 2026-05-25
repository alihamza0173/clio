class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => 'StorageException: $message';
}

class PtyException implements Exception {
  const PtyException(this.message);

  final String message;

  @override
  String toString() => 'PtyException: $message';
}
