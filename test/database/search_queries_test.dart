import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

import 'test_database.dart';

void main() {
  late TestDatabase database;
  late AppDatabase db;

  setUp(() async {
    database = await openTestDatabase();
    db = database.db;
    writeTestDictionary(database.raw, 'JMdict', (writer) {
      writer.addTag(
          name: 'n',
          category: 'partOfSpeech',
          sortingOrder: 0,
          notes: 'noun',
          popularity: 0);
      writer.addTag(
          name: 'P',
          category: 'popular',
          sortingOrder: -1,
          notes: 'popular',
          popularity: 10);
      for ((String, String, double) word in [
        ('食', 'しょく', 1),
        ('食べる', 'たべる', 5),
        ('食べ物', 'たべもの', 3),
        ('生', 'なま', 1),
        ('生', 'せい', 4),
        ('𠮟る', 'しかる', 1),
      ]) {
        writer.addEntry(
          headingId: writer.headingId(term: word.$1, reading: word.$2),
          definitions: ['${word.$1} meaning'],
          popularity: word.$3,
          entryTagNames: ['n'],
          headingTagNames: word.$1 == '食べる' ? ['P'] : [],
        );
      }
      writer.addPitch(
          headingId: writer.headingId(term: '食べる', reading: 'たべる'),
          downstep: 2);
      writer.addPitch(
          headingId: writer.headingId(term: '無', reading: 'む'), downstep: 0);
    });
    writeTestDictionary(database.raw, 'Freq', (writer) {
      writer.addFrequency(
          headingId: writer.headingId(term: '生', reading: ''),
          value: 300,
          displayValue: '300');
    });
  });

  tearDown(() => db.close());

  List<String> terms(List<HeadingRow> rows) =>
      rows.map((row) => '${row.term}/${row.reading}').toList();

  test('headingsByTerms finds headings with entries only', () async {
    expect(terms(await db.headingsByTerms(terms: ['食べる', '無']).get()),
        ['食べる/たべる']);
    expect(await db.headingCountByTerm(term: '無').getSingle(), 1);
  });

  test('headingsByTermsByPopularity puts the most popular first', () async {
    expect(terms(await db.headingsByTermsByPopularity(terms: ['生']).get()),
        ['生/せい', '生/なま']);
  });

  test('headingsByReadings honours its limit', () async {
    expect(
        await db.headingsByReadings(readings: ['なま', 'せい'], limit: 1).get(),
        hasLength(1));
  });

  test('headingsByTermPrefix is shortest first and limited', () async {
    expect(
      terms(await db
          .headingsByTermPrefix(prefix: '食', prefixEnd: '食\u{10FFFF}', limit: 10)
          .get()),
      ['食/しょく', '食べる/たべる', '食べ物/たべもの'],
    );
    expect(
      await db
          .headingsByTermPrefix(prefix: '食', prefixEnd: '食\u{10FFFF}', limit: 2)
          .get(),
      hasLength(2),
    );
  });

  test('headingsByTermGlob filters on character length', () async {
    expect(
      terms(await db
          .headingsByTermGlob(
              pattern: '食??', minimumLength: 3, maximumLength: 3, limit: 10)
          .get()),
      ['食べる/たべる', '食べ物/たべもの'],
    );
    expect(
      terms(await db
          .headingsByTermGlob(
              pattern: '𠮟?', minimumLength: 2, maximumLength: 2, limit: 10)
          .get()),
      ['𠮟る/しかる'],
    );
  });

  test('headingsByReadingGlob matches either pattern', () async {
    expect(
      terms(await db
          .headingsByReadingGlob(
              pattern: 'な?', alternativePattern: 'せ?', limit: 10)
          .get()),
      ['生/なま', '生/せい'],
    );
  });

  test('heading lookups by term and reading', () async {
    expect(await db.headingWithEntries(term: '無', reading: 'む').get(),
        isEmpty);
    expect(await db.headingByTermAndReading(term: '無', reading: 'む').get(),
        hasLength(1));
  });

  test('the loader queries return what the heading links to', () async {
    HeadingRow taberu =
        (await db.headingsByTerms(terms: ['食べる']).get()).single;
    List<int> ids = [taberu.id];

    List<EntryRow> entries = await db.entriesByHeadings(ids: ids).get();
    expect(entries.single.definitions, ['食べる meaning']);
    expect((await db.pitchesByHeadings(ids: ids).get()).single.downstep, 2);
    expect(
        (await db.headingTagsByHeadings(ids: ids).get())
            .map((row) => (row.ownerId, row.tag.name)),
        [(taberu.id, 'P')]);
    expect(
        (await db.entryTagsByEntries(ids: [entries.single.id]).get())
            .map((row) => row.tag.name),
        ['n']);
    expect(
        (await db.noReadingFrequencies(terms: ['生']).get())
            .map((row) => (row.term, row.frequency.displayValue)),
        [('生', '300')]);
    expect((await db.headingsByIds(ids: ids).get()).single.term, '食べる');
  });

  test('allDictionaries is in the user order', () async {
    List<Dictionary> dictionaries = await db.allDictionaries().get();
    expect(dictionaries.map((dictionary) => dictionary.name),
        ['JMdict', 'Freq']);
  });
}
