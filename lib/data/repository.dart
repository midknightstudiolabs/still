import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

abstract interface class VisionRepository {
  Future<AppData> load();
  Future<void> save(AppData data);
}

/// A versioned snapshot keeps linked records together. A cloud implementation
/// can replace this boundary without changing screens or domain behavior.
class LocalVisionRepository implements VisionRepository {
  LocalVisionRepository(this.storage);
  final SharedPreferences storage;
  static const key = 'still.snapshot.v1';
  @override
  Future<AppData> load() async {
    final raw = storage.getString(key);
    if (raw == null) return AppData();
    // Never silently replace a damaged or newer snapshot with an empty one.
    return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AppData data) async {
    final saved = await storage.setString(key, jsonEncode(data.toJson()));
    if (!saved) {
      throw StateError('Your change could not be saved. Please try again.');
    }
  }
}
