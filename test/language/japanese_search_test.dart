import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/language.dart';

import '../database/test_database.dart';

void main() {
  late TestDatabase database;

  setUp(() async {
    database = await openTestDatabase();
    writeTestDictionary(database.raw, 'JMdict', (writer) {
      writer.addTag(
          name: 'P',
          category: 'popular',
          sortingOrder: -1,
          notes: 'popular',
          popularity: 10);
      for ((String, String, double, bool) word in [
        ('食べる', 'たべる', 5, false),
        ('食べ物', 'たべもの', 3, false),
        ('食', 'しょく', 1, false),
        ('テスト', 'てすと', 1, false),
        ('生', '', 0, false),
        ('生', 'なま', 2, false),
        ('上手', 'じょうず', 1, true),
        ('上手', 'うわて', 5, false),
        ('方', 'かた', 1, false),
        ('方', 'ほう', 1, false),
        ('𠮟る', 'しかる', 1, false),
      ]) {
        writer.addEntry(
          headingId: writer.headingId(term: word.$1, reading: word.$2),
          definitions: ['${word.$1} meaning'],
          popularity: word.$3,
          headingTagNames: word.$4 ? ['P'] : [],
        );
      }
    });
    writeTestDictionary(database.raw, 'Freq', (writer) {
      writer
        ..addFrequency(
            headingId: writer.headingId(term: '方', reading: 'かた'),
            value: 50,
            displayValue: '50')
        ..addFrequency(
            headingId: writer.headingId(term: '方', reading: 'ほう'),
            value: 10,
            displayValue: '10');
    });
  });

  tearDown(() => database.db.close());

  Future<DictionarySearchResult?> search(
    String query, {
    bool wildcards = false,
    int maximumTerms = 10,
  }) {
    return searchDictionaryJapanese(
      database: database.db,
      query: query,
      maximumHeadings: 200,
      maximumTerms: maximumTerms,
      searchWithWildcards: wildcards,
    );
  }

  List<String> words(DictionarySearchResult? result) => result!.headings
      .map((heading) => '${heading.term}/${heading.reading}')
      .toList();

  test('finds a word from its inflected form', () async {
    DictionarySearchResult? result = await search('食べた');

    expect(words(result).first, '食べる/たべる');
    expect(result!.bestLength, 3);
  });

  test('finds a katakana word from its hiragana reading', () async {
    expect(words(await search('てすと')).first, 'テスト/てすと');
  });

  test('puts the kanji entry first for a single kanji', () async {
    expect(words(await search('生')), ['生/', '生/なま']);
  });

  test('ranks the reading tagged popular first', () async {
    expect(words(await search('上手')), ['上手/じょうず', '上手/うわて']);
  });

  test('ranks by frequency when the words share a term', () async {
    expect(words(await search('方')), ['方/ほう', '方/かた']);
  });

  test('adds longer words starting with the term, shortest first', () async {
    expect(words(await search('食', wildcards: true)),
        ['食/しょく', '食べる/たべる', '食べ物/たべもの']);
    expect(words(await search('食', wildcards: true, maximumTerms: 2)),
        ['食/しょく', '食べる/たべる']);
  });

  test('wildcards: ？ is one character, ※ any number', () async {
    expect(words(await search('食？？', wildcards: true)).toSet(),
        {'食べる/たべる', '食べ物/たべもの'});
    expect(words(await search('食※', wildcards: true)).toSet(),
        {'食/しょく', '食べる/たべる', '食べ物/たべもの'});
  });

  test('wildcards count characters outside the BMP as one', () async {
    expect(words(await search('𠮟？', wildcards: true)), ['𠮟る/しかる']);
  });

  test('a GLOB metacharacter in the selection does not break the search',
      () async {
    expect(await search('[*', wildcards: true), isNull);
    expect(await search('a[b'), isNull);
  });

  test('returns null when nothing matches', () async {
    expect(await search('ぬぬぬぬ'), isNull);
  });
}
