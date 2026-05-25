import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/process_service.dart';
import '../services/pty_service.dart';
import '../services/shell_env_service.dart';
import '../services/storage_service.dart';
import '../services/uuid_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  ),
);

final storageServiceProvider = Provider<KeyValueStore>(
  (ref) => SharedPreferencesStore(ref.watch(sharedPreferencesProvider)),
);

final uuidServiceProvider = Provider<UuidService>((ref) => const UuidService());

final processServiceProvider = Provider<ProcessService>(
  (ref) => const ProcessService(),
);

final shellEnvServiceProvider = Provider<ShellEnvService>(
  (ref) => ShellEnvService(),
);

final ptyServiceProvider = Provider<PtyService>(
  (ref) => const FlutterPtyService(),
);
