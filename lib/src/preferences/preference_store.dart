import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';
import 'package:yuuna/preferences.dart';

/// The app's settings, stored in the `preference` table. Only the main
/// isolate uses it, and nothing else touches that table.
class PreferenceStore {
  /// Load every stored setting from [raw], the connection [db] runs on.
  PreferenceStore({required this.db, required Database raw}) {
    for (final row in raw.select('SELECT key, value FROM preference')) {
      _cache[row['key'] as String] = row['value'] as String;
    }
  }

  /// The Drift database, for writes.
  final AppDatabase db;

  /// Every stored setting's JSON text, by key. [set] updates it before its
  /// first `await`, so a value reads back the moment it is set. Callers rely
  /// on this, as they did with Hive's `put`: settings switches, the creator's
  /// deck and close-on-export toggles, and the dictionary format and model
  /// dropdowns set a value without awaiting and read it back straight away.
  /// Reading the database instead would return the old value until the write
  /// lands. A failed write leaves this ahead of the database until restart.
  final Map<String, String> _cache = {};

  /// The value of [preference], or its default if unset or if the stored
  /// value cannot be decoded.
  T get<T>(Preference<T> preference) {
    String? text = _cache[preference.key];
    if (text == null) {
      return preference.defaultValue;
    }

    try {
      return preference.fromJson(jsonDecode(text));
    } catch (error) {
      debugPrint('Preference ${preference.key} is unreadable: $error');
      return preference.defaultValue;
    }
  }

  /// Set [preference] to [value]. It reads back at once; the returned future
  /// completes once it is written.
  Future<void> set<T>(Preference<T> preference, T value) async {
    String text = jsonEncode(preference.toJson(value));
    _cache[preference.key] = text;
    await db.into(db.preferenceEntries).insertOnConflictUpdate(
          PreferenceEntriesCompanion.insert(key: preference.key, value: text),
        );
  }

  /// Flip the boolean [preference].
  Future<void> toggle(Preference<bool> preference) =>
      set(preference, !get(preference));
}
