import 'dart:typed_data';

import 'package:flutter_pty/flutter_pty.dart';

abstract interface class PtyHandle {
  Stream<Uint8List> get output;
  Future<int> get exitCode;
  void write(Uint8List data);
  void resize(int rows, int columns);
  void kill();
}

abstract interface class PtyService {
  PtyHandle start({
    required String executable,
    List<String> arguments,
    required String workingDirectory,
    Map<String, String>? environment,
    int rows,
    int columns,
  });
}

class FlutterPtyService implements PtyService {
  const FlutterPtyService();

  @override
  PtyHandle start({
    required String executable,
    List<String> arguments = const [],
    required String workingDirectory,
    Map<String, String>? environment,
    int rows = 25,
    int columns = 80,
  }) {
    final pty = Pty.start(
      executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      rows: rows,
      columns: columns,
    );
    return _FlutterPtyHandle(pty);
  }
}

class _FlutterPtyHandle implements PtyHandle {
  _FlutterPtyHandle(this._pty);

  final Pty _pty;

  @override
  Stream<Uint8List> get output => _pty.output;

  @override
  Future<int> get exitCode => _pty.exitCode;

  @override
  void write(Uint8List data) => _pty.write(data);

  @override
  void resize(int rows, int columns) => _pty.resize(rows, columns);

  @override
  void kill() => _pty.kill();
}
