import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

import 'test_database.dart';

void main() {
  late TestDatabase database;
  late int neko;
  late int inu;

  setUp(() async {
    database = await openTestDatabase();
    writeTestDictionary(database.raw, 'JMdict', (writer) {
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
      neko = writer.headingId(term: '猫', reading: 'ねこ');
      inu = writer.headingId(term: '犬', reading: 'いぬ');
      writer
        ..addEntry(
            headingId: neko,
            definitions: ['cat'],
            popularity: 2,
            entryTagNames: ['n'],
            headingTagNames: ['P'])
        ..addEntry(headingId: inu, definitions: ['dog'], popularity: 1)
        ..addPitch(headingId: neko, downstep: 1);
    });
    writeTestDictionary(database.raw, 'Freq', (writer) {
      writer
        ..addFrequency(
            headingId: writer.headingId(term: '猫', reading: 'ねこ'),
            value: 10,
            displayValue: '10')
        ..addFrequency(
            headingId: writer.headingId(term: '猫', reading: ''),
            value: 20,
            displayValue: '20');
    });
  });

  tearDown(() => database.db.close());

  test('loads everything a heading links to, in the requested order',
      () async {
    List<DictionaryHeading> headings =
        await loadHeadings(database.db, [inu, neko, 999]);

    expect(headings.map((heading) => heading.term), ['犬', '猫']);

    DictionaryHeading cat = headings.last;
    DictionaryEntry entry = cat.entries.single;
    expect(entry.definitions, ['cat']);
    expect(entry.dictionary.name, 'JMdict');
    expect(entry.heading, same(cat));
    expect(entry.tags.map((tag) => tag.name), ['n']);
    expect(cat.tags.map((tag) => tag.name), ['P']);
    expect(cat.pitches.single.downstep, 1);
    expect(cat.frequencies.single.displayValue, '10');
    expect(cat.frequencies.single.dictionary.name, 'Freq');
    expect(cat.noReadingFrequencies.single.displayValue, '20');
    expect(cat.popularitySum, 2);
  });

  test('loads nothing for no ids', () async {
    expect(await loadHeadings(database.db, []), isEmpty);
  });
}
