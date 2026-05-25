import 'package:uuid/uuid.dart';

class UuidService {
  const UuidService();

  String v4() => const Uuid().v4();
}
