/// Small persistence abstraction: load and save a whole list of records.
///
/// The UI depends only on [ListRepository]; the app wires in
/// [SharedPreferencesListRepository] and tests use [InMemoryListRepository].
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

typedef FromJson<T> = T Function(Map<String, Object?> json);
typedef ToJson<T> = Map<String, Object?> Function(T value);

abstract interface class ListRepository<T> {
  Future<List<T>> load();
  Future<void> save(List<T> items);
}

/// Stores the list as one JSON array under [storageKey].
///
/// A payload that is not a JSON array throws [FormatException]; individual
/// malformed records are skipped so one bad entry cannot hide the rest.
class SharedPreferencesListRepository<T> implements ListRepository<T> {
  const SharedPreferencesListRepository({
    required this.storageKey,
    required this.fromJson,
    required this.toJson,
  });

  final String storageKey;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;

  @override
  Future<List<T>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(storageKey);
    if (payload == null || payload.isEmpty) return <T>[];
    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      throw const FormatException('Saved data is not a list.');
    }
    final items = <T>[];
    for (final item in decoded.whereType<Map>()) {
      try {
        items.add(fromJson(Map<String, Object?>.from(item)));
      } on TypeError {
        continue;
      } on FormatException {
        continue;
      } on ArgumentError {
        continue;
      }
    }
    return items;
  }

  @override
  Future<void> save(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      storageKey,
      jsonEncode(items.map(toJson).toList()),
    );
    if (!ok) throw StateError('The device did not save the data.');
  }
}

class InMemoryListRepository<T> implements ListRepository<T> {
  InMemoryListRepository([List<T> initial = const []])
      : _items = List.of(initial);

  List<T> _items;

  @override
  Future<List<T>> load() async => List.of(_items);

  @override
  Future<void> save(List<T> items) async {
    _items = List.of(items);
  }
}
