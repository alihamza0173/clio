import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clio/core/services/process_service.dart';
import 'package:clio/core/services/url_launcher_service.dart';

class _RecordingProcessService extends ProcessService {
  _RecordingProcessService();

  final calls = <List<String>>[];

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    calls.add([executable, ...arguments]);
    return ProcessResult(0, 0, '', '');
  }
}

void main() {
  late _RecordingProcessService process;
  late UrlLauncherService launcher;

  setUp(() {
    process = _RecordingProcessService();
    launcher = UrlLauncherService(process);
  });

  test('opens an https url with the platform opener', () async {
    await launcher.open('https://github.com/acme/clio/pull/12');

    expect(process.calls, hasLength(1));
    expect(process.calls.single.last, 'https://github.com/acme/clio/pull/12');
  });

  test('ignores non-web schemes and bare text', () async {
    await launcher.open('file:///etc/passwd');
    await launcher.open('javascript:alert(1)');
    await launcher.open('not a url');
    await launcher.open('');

    expect(process.calls, isEmpty);
  });
}
