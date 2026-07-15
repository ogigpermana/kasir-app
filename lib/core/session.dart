import 'package:hive_flutter/hive_flutter.dart';

class Session {
  static const _boxName = 'session';
  static const _keyUserId = 'userId';

  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static int? get userId => _box.get(_keyUserId) as int?;

  static Future<void> saveUserId(int userId) => _box.put(_keyUserId, userId);

  static Future<void> clear() => _box.delete(_keyUserId);
}
