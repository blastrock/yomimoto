import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' show Database, SqliteException, sqlite3;
import 'package:yuuna/database.dart';

import 'test_database.dart';

void main() {
  group('openRawDatabase', () {
    test('persists WAL and incremental vacuum, and turns on foreign keys',
        () async {
      Directory directory =
          Directory.systemTemp.createTempSync('yomimoto_database_');
      addTearDown(() => directory.deleteSync(recursive: true));
      String file = path.join(directory.path, databaseFileName);

      AppDatabase db = AppDatabase.open(file);
      await db.customSelect('SELECT 1').get();
      await db.close();

      Database plain = sqlite3.open(file);
      addTearDown(plain.close);
      expect(plain.select('PRAGMA journal_mode').first.columnAt(0), 'wal');
      expect(plain.select('PRAGMA auto_vacuum').first.columnAt(0), 2);

      Database configured = openRawDatabase(file);
      addTearDown(configured.close);
      expect(configured.select('PRAGMA foreign_keys').first.columnAt(0), 1);
    });
  });

  group('schema', () {
    late TestDatabase database;

    setUp(() async {
      database = await openTestDatabase();
    });

    tearDown(() => database.db.close());

    test('assigns heading ids on insert', () {
      database.raw.execute(
          "INSERT INTO heading (term, reading) VALUES ('猫', 'ねこ')");
      expect(database.raw.lastInsertRowId, 1);
    });

    test('rejects an entry for a missing heading', () {
      database.raw.execute('INSERT INTO dictionary (name, format_key, "order") '
          "VALUES ('JMdict', 'yomichan', 1)");
      expect(
        () => database.raw.execute(
            'INSERT INTO entry (heading_id, dictionary_id, definitions, '
            "popularity) VALUES (42, 1, '[]', 0)"),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting a dictionary deletes what it brought', () {
      Database raw = database.raw;
      raw.execute('INSERT INTO dictionary (name, format_key, "order") '
          "VALUES ('JMdict', 'yomichan', 1)");
      raw.execute("INSERT INTO heading (term, reading) VALUES ('猫', 'ねこ')");
      raw.execute('INSERT INTO entry (heading_id, dictionary_id, definitions, '
          "popularity) VALUES (1, 1, '[\"cat\"]', 0)");
      raw.execute('INSERT INTO pitch (heading_id, dictionary_id, downstep) '
          'VALUES (1, 1, 1)');
      raw.execute('INSERT INTO frequency (heading_id, dictionary_id, value, '
          "display_value) VALUES (1, 1, 10, '10')");
      raw.execute('INSERT INTO tag (dictionary_id, name, category, '
          "sorting_order, notes, popularity) VALUES (1, 'n', 'noun', 0, '', 0)");
      raw.execute('INSERT INTO entry_tag (entry_id, tag_id) VALUES (1, 1)');
      raw.execute('INSERT INTO heading_tag (heading_id, tag_id) VALUES (1, 1)');

      raw.execute('DELETE FROM dictionary');

      for (String table in [
        'entry',
        'pitch',
        'frequency',
        'tag',
        'entry_tag',
        'heading_tag',
      ]) {
        expect(countRows(raw, table), 0, reason: table);
      }
      expect(countRows(raw, 'heading'), 1);
    });
  });

  group('converters', () {
    test('round-trip their values', () {
      const StringListConverter strings = StringListConverter();
      expect(strings.fromSql(strings.toSql(['読む', 'よむ'])), ['読む', 'よむ']);

      const NullableStringListConverter nullable =
          NullableStringListConverter();
      expect(nullable.fromSql(nullable.toSql(['term', null])), ['term', null]);

      const QuickActionsColumnConverter actions = QuickActionsColumnConverter();
      expect(actions.fromSql(actions.toSql({0: 'card_creator'})),
          {0: 'card_creator'});

      const EnhancementsColumnConverter enhancements =
          EnhancementsColumnConverter();
      expect(
        enhancements.fromSql(enhancements.toSql({
          'term': {-1: 'auto', 0: 'manual'},
        })),
        {
          'term': {-1: 'auto', 0: 'manual'},
        },
      );

      const MicrosecondsConverter instants = MicrosecondsConverter();
      DateTime moment = DateTime.fromMicrosecondsSinceEpoch(1760000000123456);
      expect(instants.fromSql(instants.toSql(moment)), moment);
    });
  });
}
