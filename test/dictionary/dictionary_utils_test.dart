import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

import '../database/test_database.dart';

void main() {
  late Directory directory;
  late String databasePath;
  late Directory resources;
  late ReceivePort progress;
  late ReceivePort alerts;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('yomimoto_import_');
    databasePath = path.join(directory.path, databaseFileName);
    resources = Directory(path.join(directory.path, 'importing'))
      ..createSync();
    progress = ReceivePort();
    alerts = ReceivePort();

    AppDatabase db = AppDatabase.open(databasePath);
    await db.customSelect('SELECT 1').get();
    await db.close();
  });

  tearDown(() {
    progress.close();
    alerts.close();
    directory.deleteSync(recursive: true);
  });

  PrepareDictionaryParams params(String name) => PrepareDictionaryParams(
        dictionaryName: name,
        dictionaryFormat: MigakuFormat.instance,
        resourceDirectory: resources,
        alertSendPort: alerts.sendPort,
        sendPort: progress.sendPort,
        directoryPath: directory.path,
        databasePath: databasePath,
      );

  void writeBank(String contents) {
    File(path.join(resources.path, 'bank.json')).writeAsStringSync(contents);
  }

  int count(String table) {
    Database raw = openRawDatabase(databasePath);
    try {
      return countRows(raw, table);
    } finally {
      raw.close();
    }
  }

  test('deposits a Migaku dictionary and returns its id', () async {
    writeBank('[{"term": "猫", "definition": "cat", "pronunciation": "ねこ"}]');

    int id = await depositDictionaryDataHelper(params('Test'));

    Database raw = openRawDatabase(databasePath);
    addTearDown(raw.close);
    expect(
        raw.select('SELECT id, format_key, "order" FROM dictionary').single,
        {'id': id, 'format_key': 'migaku', 'order': 1});
    expect(raw.select('SELECT term, reading FROM heading').single,
        {'term': '猫', 'reading': 'ねこ'});
    expect(countRows(raw, 'entry'), 1);
  });

  test('a duplicate name fails and leaves the first dictionary alone',
      () async {
    writeBank('[{"term": "猫", "definition": "cat", "pronunciation": "ねこ"}]');
    await depositDictionaryDataHelper(params('Test'));

    await expectLater(
        depositDictionaryDataHelper(params('Test')), throwsA(anything));

    expect(count('dictionary'), 1);
    expect(count('entry'), 1);
  });

  test('a malformed bank rolls the whole import back', () async {
    writeBank('not json');

    await expectLater(
        depositDictionaryDataHelper(params('Broken')), throwsA(anything));

    expect(count('dictionary'), 0);
    expect(count('heading'), 0);
  });

  test('a malformed item after a valid one rolls back what was written',
      () async {
    writeBank('[{"term": "猫", "definition": "cat", "pronunciation": "ねこ"}, '
        '{"definition": "dog"}]');

    await expectLater(
        depositDictionaryDataHelper(params('Partial')), throwsA(anything));

    expect(count('dictionary'), 0);
    expect(count('heading'), 0);
    expect(count('entry'), 0);
  });
}
