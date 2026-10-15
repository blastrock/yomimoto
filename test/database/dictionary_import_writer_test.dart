import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';

import 'test_database.dart';

void main() {
  late TestDatabase database;
  late Database raw;

  setUp(() async {
    database = await openTestDatabase();
    raw = database.raw;
  });

  tearDown(() => database.db.close());

  test('headingId reuses a heading created by another dictionary', () {
    late int first;
    late int second;
    writeTestDictionary(raw, 'A', (writer) {
      first = writer.headingId(term: '猫', reading: 'ねこ');
      writer.addEntry(headingId: first, definitions: ['cat'], popularity: 0);
    });
    writeTestDictionary(raw, 'B', (writer) {
      second = writer.headingId(term: '猫', reading: 'ねこ');
      writer.addEntry(headingId: second, definitions: ['neko'], popularity: 0);
    });

    expect(second, first);
    expect(countRows(raw, 'heading'), 1);
    expect(countRows(raw, 'entry'), 2);
  });

  test('headingId returns the same id for the same word', () {
    writeTestDictionary(raw, 'A', (writer) {
      expect(writer.headingId(term: '犬', reading: 'いぬ'),
          writer.headingId(term: '犬', reading: 'いぬ'));
    });
    expect(countRows(raw, 'heading'), 1);
  });

  test('links known tags and skips unknown ones', () {
    writeTestDictionary(raw, 'A', (writer) {
      writer
        ..addTag(
            name: 'n',
            category: 'partOfSpeech',
            sortingOrder: 0,
            notes: 'noun',
            popularity: 0)
        ..addTag(
            name: 'P',
            category: 'popular',
            sortingOrder: -1,
            notes: 'popular',
            popularity: 10);
      writer.addEntry(
        headingId: writer.headingId(term: '猫', reading: 'ねこ'),
        definitions: ['cat'],
        popularity: 1,
        entryTagNames: ['n', 'unknown', ''],
        headingTagNames: ['P'],
      );
    });

    expect(countRows(raw, 'tag'), 2);
    expect(countRows(raw, 'entry_tag'), 1);
    expect(countRows(raw, 'heading_tag'), 1);
  });

  test('a tag defined twice is one tag', () {
    writeTestDictionary(raw, 'A', (writer) {
      writer
        ..addTag(
            name: 'n',
            category: 'a',
            sortingOrder: 0,
            notes: '',
            popularity: 0)
        ..addTag(
            name: 'n',
            category: 'b',
            sortingOrder: 0,
            notes: '',
            popularity: 0);
    });

    expect(raw.select('SELECT category FROM tag').single['category'], 'b');
  });

  test('a pitch or frequency for an unknown word keeps its reading', () {
    writeTestDictionary(raw, 'Pitch', (writer) {
      writer.addPitch(
          headingId: writer.headingId(term: '行く', reading: 'いく'),
          downstep: 0);
      writer.addFrequency(
          headingId: writer.headingId(term: '行く', reading: 'ゆく'),
          value: 100,
          displayValue: '100');
    });

    expect(
      raw
          .select('SELECT reading FROM heading ORDER BY id')
          .map((row) => row['reading']),
      ['いく', 'ゆく'],
    );
  });

  test('stores definitions as the converter reads them', () async {
    writeTestDictionary(raw, 'A', (writer) {
      writer.addEntry(
        headingId: writer.headingId(term: '猫', reading: 'ねこ'),
        definitions: ['cat', '{"tag":"span"}'],
        popularity: 2.5,
      );
    });

    EntryRow entry = await database.db.select(database.db.entries).getSingle();
    expect(entry.definitions, ['cat', '{"tag":"span"}']);
    expect(entry.popularity, 2.5);
  });
}
