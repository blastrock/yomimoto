import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';

import 'test_database.dart';

void main() {
  late TestDatabase database;
  late Database raw;
  late int jmdict;

  setUp(() async {
    database = await openTestDatabase();
    raw = database.raw;
    jmdict = writeTestDictionary(raw, 'JMdict', (writer) {
      writer.addTag(
          name: 'n',
          category: 'partOfSpeech',
          sortingOrder: 0,
          notes: '',
          popularity: 0);
      writer.addEntry(
        headingId: writer.headingId(term: '猫', reading: 'ねこ'),
        definitions: ['cat'],
        popularity: 0,
        entryTagNames: ['n'],
        headingTagNames: ['n'],
      );
      writer.addEntry(
        headingId: writer.headingId(term: '犬', reading: 'いぬ'),
        definitions: ['dog'],
        popularity: 0,
      );
    });
    writeTestDictionary(raw, 'Other', (writer) {
      writer.addEntry(
        headingId: writer.headingId(term: '猫', reading: 'ねこ'),
        definitions: ['neko'],
        popularity: 0,
      );
    });
  });

  tearDown(() => database.db.close());

  test('deleteDictionaryData removes one dictionary and its orphans',
      () async {
    await deleteDictionaryData(database.db, jmdict);

    expect(countRows(raw, 'dictionary'), 1);
    expect(raw.select('SELECT term FROM heading').map((row) => row['term']),
        ['猫']);
    expect(countRows(raw, 'entry'), 1);
    expect(countRows(raw, 'tag'), 0);
    expect(countRows(raw, 'entry_tag'), 0);
    expect(countRows(raw, 'heading_tag'), 0);
  });

  test('deleteAllDictionaryData empties every dictionary table', () async {
    await deleteAllDictionaryData(database.db);

    for (String table in [
      'dictionary',
      'heading',
      'entry',
      'pitch',
      'frequency',
      'tag',
      'entry_tag',
      'heading_tag',
    ]) {
      expect(countRows(raw, table), 0, reason: table);
    }
  });
}
