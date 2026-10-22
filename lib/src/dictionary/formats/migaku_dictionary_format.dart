import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' show Database;

import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/i18n/strings.g.dart';

/// A dictionary format for archives following the ABBYY Lingvo or DSL format
/// compatible with GoldenDict.
///
/// Details on the format can be found here:
/// http://lingvo.helpmax.net/en/troubleshooting/dsl-compiler/dsl-dictionary-structure/
class MigakuFormat extends DictionaryFormat {
  /// Define a format with the given metadata that has its behaviour for
  /// import, search and display defined with a set of top-level helper methods.
  MigakuFormat._privateConstructor()
      : super(
          uniqueKey: 'migaku',
          name: 'Migaku Dictionary',
          icon: Icons.auto_stories_rounded,
          allowedExtensions: const ['zip'],
          fileType: FileType.any,
          prepareDirectory: prepareDirectoryMigakuFormat,
          prepareName: prepareNameMigakuFormat,
          importData: importDataMigakuFormat,
        );

  /// Get the singleton instance of this dictionary format.
  static MigakuFormat get instance => _instance;

  static final MigakuFormat _instance = MigakuFormat._privateConstructor();
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
Future<void> prepareDirectoryMigakuFormat(PrepareDirectoryParams params) async {
  await ZipFile.extractToDirectory(
    zipFile: params.file,
    destinationDir: params.resourceDirectory,
  );
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
Future<String> prepareNameMigakuFormat(PrepareDirectoryParams params) async {
  File originalFile = params.file;
  return path.basenameWithoutExtension(originalFile.path);
}

/// Top-level function for use in compute. See [DictionaryFormat] for details.
void importDataMigakuFormat({
  required PrepareDictionaryParams params,
  required Database database,
  required int dictionaryId,
}) {
  DictionaryImportWriter writer = DictionaryImportWriter(
    database: database,
    dictionaryId: dictionaryId,
  );
  try {
    prepareEntriesMigakuFormat(params: params, writer: writer);
  } finally {
    writer.close();
  }
}

/// Writes the entries of the dictionary through [writer].
void prepareEntriesMigakuFormat({
  required PrepareDictionaryParams params,
  required DictionaryImportWriter writer,
}) {
  final List<FileSystemEntity> entities = params.resourceDirectory.listSync();
  final Iterable<File> files = entities.whereType<File>();

  int count = 0;

  for (File file in files) {
    List<dynamic> items = List.from(jsonDecode(file.readAsStringSync()));

    for (dynamic item in items) {
      Map<String, dynamic> map = Map<String, dynamic>.from(item);

      String term = (map['term'] as String).trim();
      String definition = map['definition'] as String;
      String reading = map['pronunciation'] ?? '';

      definition = definition
          .replaceAll('<br>', '\n')
          .replaceAll(RegExp('<[^<]+?>'), '');

      writer.addEntry(
        headingId: writer.headingId(term: term, reading: reading),
        definitions: [definition],
        popularity: 0,
      );

      count++;
      params.send(t.import_found_entry(
        count: count,
      ));
    }
  }

  params.send(t.import_found_entry(count: count));
}
