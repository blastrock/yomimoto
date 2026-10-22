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
  test('isYomichanBank accepts root bank files only', () {
    expect(isYomichanBank('term_bank_1.json'), isTrue);
    expect(isYomichanBank('term_meta_bank_3.json'), isTrue);
    expect(isYomichanBank('sub/term_bank_1.json'), isFalse);
    expect(isYomichanBank('index.json'), isFalse);
    expect(isYomichanBank('img/a.png'), isFalse);
  });

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
    for (String row in [
      '["犬","a","",""]',
      '["犬","a","","",["x",null],{}]',
      '["犬","a","","",[{"a":1}],{}]',
      '["犬","a","","",[true],{}]',
      '["犬",{},"","",[],{}]',
      '["犬","",[],"",[],{}]',
      '["犬","","",{},[],{}]',
      '[{},"","",""]',
    ]) {
      expect(
          () => importBanks(
              raw, 'K', [bank('kanji_bank_1.json', '[$row]')]),
          throwsA(isA<SqliteException>()),
          reason: row);
    }
  });

  test('fails the import on wrongly typed term fields', () {
    for (String row in [
      '[{},"ね","","",0,[],1,""]',
      '["猫",[],"","",0,[],1,""]',
      '["猫","ね","","",true,[],1,""]',
      '["猫","ね","","",0,[],1,{}]',
      '["猫","ね",{},"",0,[],1,""]',
    ]) {
      expect(
          () => importBanks(
              raw, 'T', [bank('term_bank_1.json', '[$row]')]),
          throwsA(isA<SqliteException>()),
          reason: row);
    }
    expect(countRows(raw, 'entry'), 0);
  });

  test('null definition tags still import', () {
    importBanks(raw, 'T', [
      bank('term_bank_1.json', '[["猫","ね",null,"",0,[],1,""]]'),
    ]);
    expect(countRows(raw, 'entry'), 1);
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

  test('imports a kanji with its readings and meanings', () {
    importBanks(raw, 'K', [
      bank('tag_bank_1.json', '[["jouyou","misc",0,"常用",0]]'),
      bank('kanji_bank_1.json',
          '[["猫","ビョウ ミョウ","ねこ","jouyou",["cat","feline"],{}]]'),
    ]);
    expect(raw.select('SELECT term, reading FROM heading').single,
        {'term': '猫', 'reading': ''});
    expect(
        jsonDecode(raw.select('SELECT definitions FROM entry').single[
            'definitions'] as String),
        ['音読み\n  • ビョウ\n  • ミョウ\n\n訓読み\n  • ねこ\n\n意味\n  • cat\n  • feline']);
    expect(countRows(raw, 'heading_tag'), 1);
  });

  test('skips empty kanji sections', () {
    importBanks(raw, 'K', [
      bank('kanji_bank_1.json', '[["犬","","いぬ","",[],{}]]'),
    ]);
    expect(
        jsonDecode(raw.select('SELECT definitions FROM entry').single[
            'definitions'] as String),
        ['訓読み\n  • いぬ']);
  });

  test('keeps empty kanji reading pieces as bullets', () {
    importBanks(raw, 'K', [
      bank('kanji_bank_1.json', r'[["犬","a  b","","",["\"q\""],{}]]'),
    ]);
    expect(
        jsonDecode(raw.select('SELECT definitions FROM entry').single[
            'definitions'] as String),
        ['音読み\n  • a\n  • \n  • b\n\n意味\n  • "q"']);
  });

  test('skips a kanji with nothing to say', () {
    importBanks(raw, 'K', [
      bank('kanji_bank_1.json', '[["丶","","","",[],{}]]'),
    ]);
    expect(countRows(raw, 'heading'), 0);
    expect(countRows(raw, 'entry'), 0);
  });

  test('fails the import on a kanji with wrongly typed fields', () {
    expect(
        () => importBanks(raw, 'K', [
              bank('kanji_bank_1.json', '[["犬",null,"いぬ","",[],{}]]'),
            ]),
        throwsA(isA<SqliteException>()));
    expect(
        () => importBanks(raw, 'K', [
              bank('kanji_bank_1.json', '[["犬","","","","cat",{}]]'),
            ]),
        throwsA(isA<SqliteException>()));
    expect(countRows(raw, 'entry'), 0);
  });

  test('imports every frequency shape as today', () {
    importBanks(raw, 'F', [
      bank('term_meta_bank_1.json', '['
          '["a","freq",5],["b","freq",2.5],["c","freq",3.0],'
          '["d","freq",{"reading":"でぃ","frequency":{"value":7,"displayValue":"7★"}}],'
          '["e","freq",{"value":8,"displayValue":"8㋕"}],'
          '["f","freq",{"reading":"えふ","value":9.7}],'
          '["g","freq",{"frequency":4}],["h","freq",{"frequency":4.5}],'
          '["i","freq",{"reading":"あい"}],["j","freq","rare"],'
          '["l","ipa",{}]]'),
    ]);
    expect(
        raw.select('SELECT h.term, h.reading, f.value, f.display_value '
            'FROM frequency f JOIN heading h ON h.id = f.heading_id '
            'ORDER BY f.id'),
        [
          {'term': 'a', 'reading': '', 'value': 5.0, 'display_value': '5'},
          {'term': 'b', 'reading': '', 'value': 2.5, 'display_value': '2.5'},
          {'term': 'c', 'reading': '', 'value': 3.0, 'display_value': '3'},
          {'term': 'd', 'reading': 'でぃ', 'value': 7.0, 'display_value': '7★'},
          {'term': 'e', 'reading': '', 'value': 8.0, 'display_value': '8㋕'},
          {'term': 'f', 'reading': 'えふ', 'value': 9.7, 'display_value': '9'},
          {'term': 'g', 'reading': '', 'value': 4.0, 'display_value': '4'},
          {'term': 'h', 'reading': '', 'value': 4.5, 'display_value': '4.5'},
          {'term': 'j', 'reading': '', 'value': 0.0, 'display_value': 'rare'},
        ]);
    expect(countRows(raw, 'heading'), 9); // 'i' and 'l' create none
  });

  test('imports pitches with their reading', () {
    importBanks(raw, 'P', [
      bank('term_meta_bank_1.json', '['
          '["け","pitch",{"reading":"け","pitches":[{"position":0},{"position":2}]}],'
          '["く","pitch",{"pitches":[{"position":1}]}]]'),
    ]);
    expect(
        raw.select('SELECT h.term, h.reading, p.downstep '
            'FROM pitch p JOIN heading h ON h.id = p.heading_id '
            'ORDER BY p.id'),
        [
          {'term': 'け', 'reading': 'け', 'downstep': 0},
          {'term': 'け', 'reading': 'け', 'downstep': 2},
          {'term': 'く', 'reading': '', 'downstep': 1},
        ]);
    expect(countRows(raw, 'heading'), 2);
  });

  test('processes term banks before meta banks whatever their order', () {
    importBanks(raw, 'D', [
      bank('term_meta_bank_1.json', '[["犬","freq",3]]'),
      bank('term_bank_1.json', '[["猫","ねこ","","",1,["cat"],1,""]]'),
    ]);
    expect(raw.select('SELECT id, term FROM heading ORDER BY id'), [
      {'id': 1, 'term': '猫'},
      {'id': 2, 'term': '犬'},
    ]);
  });

  test('a pitch row without a pitch list fails the import', () {
    for (String data in ['{"reading":"け"}', '{"pitches":null}', 'null']) {
      expect(
          () => importBanks(raw, 'P', [
                bank('term_meta_bank_1.json', '[["け","pitch",$data]]'),
              ]),
          throwsA(isA<SqliteException>()),
          reason: data);
    }
    expect(countRows(raw, 'pitch'), 0);
    expect(countRows(raw, 'heading'), 0);
  });

  test('a pitch position that is not an integer fails the import', () {
    for (String position in ['1.5', '"x"', 'null']) {
      expect(
          () => importBanks(raw, 'P', [
                bank('term_meta_bank_1.json',
                    '[["け","pitch",{"pitches":[{"position":$position}]}]]'),
              ]),
          throwsA(isA<SqliteException>()),
          reason: position);
    }
    expect(countRows(raw, 'pitch'), 0);
  });

  test('fails the import on wrongly typed meta rows', () {
    for (String row in [
      '[null,"freq",1]',
      '["a",1,1]',
      '["a","freq",{"value":"x","displayValue":"y"}]',
      '["a","freq",{"reading":"r","frequency":{"value":"x"}}]',
      '["a","freq",{"frequency":4,"value":true}]',
      '["a","freq",{"reading":{"x":1},"value":3}]',
      '["a","freq",{"reading":true,"value":3}]',
      '["a","pitch",{"reading":[1],"pitches":[]}]',
      '["a","freq",{"value":3,"displayValue":{"x":1}}]',
      '["a","freq",{"value":3,"displayValue":false}]',
      '["a","freq",{"reading":"r","frequency":{"value":3,"displayValue":[1]}}]',
      '["a","pitch",{"pitches":[{"position":true}]}]',
    ]) {
      expect(
          () => importBanks(raw, 'F', [
                bank('term_meta_bank_1.json', '[$row]'),
              ]),
          throwsA(isA<SqliteException>()),
          reason: row);
    }
    expect(countRows(raw, 'frequency'), 0);
  });

  test('skips frequency shapes that no case handles', () {
    importBanks(raw, 'F', [
      bank('term_meta_bank_1.json', '['
          '["a","freq",{"reading":"r","frequency":"rare"}],'
          '["b","freq",{"frequency":{"value":7}}],'
          '["c","freq",{"reading":true}],'
          '["d","freq",2]]'),
    ]);
    expect(raw.select('SELECT h.term FROM frequency f '
        'JOIN heading h ON h.id = f.heading_id'), [
      {'term': 'd'},
    ]);
    expect(countRows(raw, 'heading'), 1);
  });

  test('accepts numeric readings and display values', () {
    importBanks(raw, 'F', [
      bank('term_meta_bank_1.json', '['
          '["a","freq",{"reading":12,"value":3,"displayValue":4}],'
          '["b","freq",{"value":3,"displayValue":"x"}]]'),
    ]);
    expect(
        raw.select('SELECT h.term, h.reading, f.display_value FROM frequency f '
            'JOIN heading h ON h.id = f.heading_id ORDER BY f.id'),
        [
          {'term': 'a', 'reading': '12', 'display_value': '4'},
          {'term': 'b', 'reading': '', 'display_value': 'x'},
        ]);
  });
}
