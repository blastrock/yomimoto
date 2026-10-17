import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/preferences.dart';

import '../database/test_database.dart';

const _flag = Preference<bool>('flag', defaultValue: true);
const _count = Preference<int>('count', defaultValue: 10);
const _size = Preference<double>('size', defaultValue: 16);
const _name = Preference<String>('name', defaultValue: '');
const _path = Preference<String?>('path', defaultValue: null);
const _models = StringListPreference('models', defaultValue: ['Yomimoto']);
const _theme = EnumPreference<ThemeMode>('theme', ThemeMode.values,
    defaultValue: ThemeMode.system);

void main() {
  late TestDatabase database;
  late PreferenceStore store;

  setUp(() async {
    database = await openTestDatabase();
    store = PreferenceStore(db: database.db, raw: database.raw);
  });

  tearDown(() => database.db.close());

  /// A store opened after [value] was written raw under [key].
  PreferenceStore storeWithRow(String key, String value) {
    database.raw.execute('INSERT INTO preference VALUES (?, ?)', [key, value]);
    return PreferenceStore(db: database.db, raw: database.raw);
  }

  test('an unset key returns the default', () {
    expect(store.get(_flag), isTrue);
    expect(store.get(_count), 10);
    expect(store.get(_size), 16);
    expect(store.get(_name), '');
    expect(store.get(_path), isNull);
    expect(store.get(_models), ['Yomimoto']);
    expect(store.get(_theme), ThemeMode.system);
  });

  test('set values round-trip', () async {
    await store.set(_flag, false);
    await store.set(_count, 3);
    await store.set(_size, 18.5);
    await store.set(_name, 'x');
    await store.set(_path, '/sdcard');
    await store.set(_models, ['A', 'B']);
    await store.set(_theme, ThemeMode.dark);

    PreferenceStore reopened =
        PreferenceStore(db: database.db, raw: database.raw);
    for (PreferenceStore s in [store, reopened]) {
      expect(s.get(_flag), isFalse);
      expect(s.get(_count), 3);
      expect(s.get(_size), 18.5);
      expect(s.get(_name), 'x');
      expect(s.get(_path), '/sdcard');
      expect(s.get(_models), ['A', 'B']);
      expect(s.get(_theme), ThemeMode.dark);
    }
  });

  test('a nullable value can be set back to null', () async {
    await store.set(_path, '/sdcard');
    await store.set(_path, null);

    expect(store.get(_path), isNull);
    expect(PreferenceStore(db: database.db, raw: database.raw).get(_path),
        isNull);
  });

  test('set overwrites', () async {
    await store.set(_count, 3);
    await store.set(_count, 4);

    expect(store.get(_count), 4);
    expect(countRows(database.raw, 'preference'), 1);
  });

  test('get sees a set before it is awaited', () async {
    Future<void> write = store.set(_count, 5);
    expect(store.get(_count), 5);
    await write;
  });

  test('toggle flips a bool, and two quick toggles cancel out', () async {
    await store.toggle(_flag);
    expect(store.get(_flag), isFalse);

    Future<void> first = store.toggle(_flag);
    Future<void> second = store.toggle(_flag);
    await first;
    await second;
    expect(store.get(_flag), isFalse);
    expect(PreferenceStore(db: database.db, raw: database.raw).get(_flag),
        isFalse);
  });

  test('a new store reads what an earlier one wrote', () async {
    await store.set(_count, 7);

    expect(PreferenceStore(db: database.db, raw: database.raw).get(_count), 7);
  });

  test('invalid JSON returns the default', () {
    expect(storeWithRow('count', 'not json').get(_count), 10);
  });

  test('a value of the wrong type returns the default', () {
    expect(storeWithRow('count', '"three"').get(_count), 10);
  });

  test('an unknown enum name returns the default', () {
    expect(storeWithRow('theme', '"sepia"').get(_theme), ThemeMode.system);
  });
}
