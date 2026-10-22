import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database, Row, SqliteException;
import 'package:yuuna/database.dart';

import 'test_database.dart';

YomichanBank bank(String name, String json) {
  Uint8List bytes = Uint8List.fromList(utf8.encode(json));
  return (name: name, size: bytes.length, read: () => bytes);
}

int importBanks(
  Database raw,
  String name,
  List<YomichanBank> banks, {
  List<double>? progress,
}) {
  raw.execute('BEGIN');
  try {
    int dictionaryId = insertTestDictionary(raw, name);
    importYomichanBanks(
      database: raw,
      dictionaryId: dictionaryId,
      banks: banks,
      onProgress: (fraction) => progress?.add(fraction),
    );
    raw.execute('COMMIT');
    return dictionaryId;
  } catch (_) {
    raw.execute('ROLLBACK');
    rethrow;
  }
}

void main() {
  late TestDatabase database;
  late Database raw;

  setUp(() async {
    database = await openTestDatabase();
    raw = database.raw;
  });

  tearDown(() => database.db.close());

  test('recognises the bank files at the root of the archive', () {
    expect(isYomichanBank('tag_bank_1.json'), isTrue);
    expect(isYomichanBank('term_bank_12.json'), isTrue);
    expect(isYomichanBank('kanji_bank_1.json'), isTrue);
    expect(isYomichanBank('term_meta_bank_1.json'), isTrue);
    expect(isYomichanBank('index.json'), isFalse);
    expect(isYomichanBank('sub/term_bank_1.json'), isFalse);
  });

  test('imports tags, terms, definitions and their tags', () {
    importBanks(raw, 'D', [
      bank(
          'tag_bank_1.json',
          '[["n","partOfSpeech",-1,"noun",0],'
              '["P","popular",-10,"common",10],'
              '["n","partOfSpeech",-2,"noun again",1]]'),
      bank(
          'term_bank_1.json',
          '[["猫","ねこ","n","",5,['
              '"cat",{"type":"text","text":"feline"},{"type":"text"},'
              '{"type":"structured-content","content":{"tag":"span","content":"neko"}},'
              '{"type":"image","path":"img/neko.png"},7,{"type":"unknown"}],1,"P"]]'),
    ]);
    expect(
        raw.select('SELECT name, sorting_order, notes FROM tag ORDER BY name'),
        [
          {'name': 'P', 'sorting_order': -10, 'notes': 'common'},
          {'name': 'n', 'sorting_order': -2, 'notes': 'noun again'},
        ]);
    Row entry = raw.select('SELECT * FROM entry').single;
    expect(jsonDecode(entry['definitions'] as String),
        ['cat', 'feline', '{"tag":"span","content":"neko"}', 'null']);
    expect(entry['popularity'], 5.0);
    expect(
        raw
            .select('SELECT t.name FROM entry_tag JOIN tag t ON t.id = tag_id')
            .map((r) => r['name']),
        ['n']);
    expect(
        raw
            .select(
                'SELECT t.name FROM heading_tag JOIN tag t ON t.id = tag_id')
            .map((r) => r['name']),
        ['P']);
  });

  test('shares headings across dictionaries and continues entry ids', () {
    int a = importBanks(raw, 'A', [
      bank('term_bank_1.json', '[["猫","ねこ",null,"",1,["cat"],1,""]]'),
    ]);
    int b = importBanks(raw, 'B', [
      bank('term_bank_1.json', '[["猫","ねこ",null,"",1,["kitty"],1,""]]'),
    ]);
    expect(countRows(raw, 'heading'), 1);
    Iterable<Row> entries =
        raw.select('SELECT id, dictionary_id FROM entry ORDER BY id');
    expect(entries.map((r) => r['id']), [1, 2]);
    expect(entries.map((r) => r['dictionary_id']), [a, b]);
  });

  test('splits tag names containing quotes and backslashes', () {
    importBanks(raw, 'D', [
      bank(
          'tag_bank_1.json',
          r'[["a\"b","c",0,"",0],["c\\d","c",0,"",0]]'),
      bank('term_bank_1.json', r'[["猫","ねこ","a\"b c\\d","",1,["cat"],1,""]]'),
    ]);
    expect(countRows(raw, 'entry_tag'), 2);
  });

  test('a null or empty definition-tag string adds no entry tags', () {
    importBanks(raw, 'D', [
      bank('tag_bank_1.json', '[["n","c",0,"",0]]'),
      bank(
          'term_bank_1.json',
          '[["猫","ねこ",null,"",1,["cat"],1,""],'
              '["犬","いぬ","","",1,["dog"],1,""]]'),
    ]);
    expect(countRows(raw, 'entry'), 2);
    expect(countRows(raw, 'entry_tag'), 0);
    expect(countRows(raw, 'heading_tag'), 0);
  });

  test('reports progress by bank size, rising to 1', () {
    String rows = List.filled(1500, '["猫","ねこ","","",1,["cat"],1,""]')
        .join(',');
    List<double> progress = [];
    importBanks(
        raw,
        'D',
        [
          bank('term_bank_1.json', '[$rows]'),
          bank('term_bank_2.json', '[["犬","いぬ","","",1,["dog"],1,""]]'),
        ],
        progress: progress);
    expect(progress.length, greaterThanOrEqualTo(3));
    expect(progress.first, lessThan(1.0));
    expect(progress.last, 1.0);
    for (int i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
    }
    expect(countRows(raw, 'entry'), 1501);
  });

  test('an archive without banks imports nothing and reports nothing', () {
    List<double> progress = [];
    importBanks(raw, 'D', [], progress: progress);
    expect(progress, isEmpty);
    expect(countRows(raw, 'entry'), 0);
  });

  test('popularity given as a numeric string is accepted', () {
    importBanks(raw, 'D', [
      bank('term_bank_1.json', '[["猫","ねこ","","","5",["cat"],1,""]]'),
    ]);
    expect(raw.select('SELECT popularity FROM entry').single['popularity'], 5.0);
  });

  for (var (label, json) in [
    (
      'a popularity that is not a number',
      '[["猫","ねこ","","","abc",["cat"],1,""]]'
    ),
    ('definitions that are not a list', '[["猫","ねこ","","",1,"cat",1,""]]'),
    (
      'a text definition whose text is a number',
      '[["猫","ねこ","","",1,[{"type":"text","text":5}],1,""]]'
    ),
    ('a row without term tags', '[["猫","ねこ","","",1,["cat"],1]]'),
    ('broken JSON', '[["猫"'),
  ]) {
    test('fails on $label and writes nothing', () {
      expect(
        () => importBanks(raw, 'D', [bank('term_bank_1.json', json)]),
        throwsA(isA<SqliteException>()),
      );
      expect(countRows(raw, 'dictionary'), 0);
      expect(countRows(raw, 'heading'), 0);
      expect(countRows(raw, 'entry'), 0);
    });
  }

  for (var (label, definitions, stored) in [
    ('an empty list', '[]', '[]'),
    ('a text element without text', '[{"type":"text"}]', '[]'),
    ('a text element with null text', '[{"type":"text","text":null}]', '[]'),
    (
      'structured content that is a string',
      '[{"type":"structured-content","content":"plain"}]',
      '["\\"plain\\""]'
    ),
  ]) {
    test('stores definitions of $label', () {
      importBanks(raw, 'D', [
        bank('term_bank_1.json',
            '[["猫","ねこ","","",1,$definitions,1,""]]'),
      ]);
      expect(raw.select('SELECT definitions FROM entry').single['definitions'],
          stored);
    });
  }

  test('a tag sorting order that is not an integer fails the import', () {
    expect(
      () => importBanks(raw, 'D', [
        bank('tag_bank_1.json', '[["n","c","abc","",0]]'),
      ]),
      throwsA(isA<SqliteException>()),
    );
    expect(countRows(raw, 'tag'), 0);
  });

  test('an import after a failed one on the same connection works', () {
    expect(
      () => importBanks(raw, 'D', [bank('term_bank_1.json', '[["猫"')]),
      throwsA(isA<SqliteException>()),
    );
    importBanks(raw, 'E', [
      bank('term_bank_1.json', '[["猫","ねこ","","",1,["cat"],1,""]]'),
    ]);
    expect(countRows(raw, 'entry'), 1);
  });
}
