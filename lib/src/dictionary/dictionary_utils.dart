import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/models.dart';

/// FNV-1a 64bit hash algorithm optimized for Dart Strings.
/// This is used to generate integer IDs that can be hard assigned to entities
/// with string IDs with microscopically low collision. This allows for example,
/// a [DictionaryHeading]'s ID to always be determinable by its composite
/// parameters.
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}

/// Import the dictionary described by [params] in one transaction, and
/// return its new id. On failure nothing is written. Top-level for
/// `compute`.
Future<int> depositDictionaryDataHelper(PrepareDictionaryParams params) async {
  Database database = openRawDatabase(params.databasePath);
  try {
    database.execute('BEGIN IMMEDIATE');
    try {
      database.execute(
        'INSERT INTO dictionary (name, format_key, "order") VALUES '
        '(?, ?, (SELECT COALESCE(MAX("order"), 0) + 1 FROM dictionary))',
        [params.dictionaryName, params.dictionaryFormat.uniqueKey],
      );
      int dictionaryId = database.lastInsertRowId;

      DictionaryImportWriter writer = DictionaryImportWriter(
        database: database,
        dictionaryId: dictionaryId,
      );
      try {
        params.dictionaryFormat.prepareTags(params: params, writer: writer);
        params.dictionaryFormat.prepareEntries(params: params, writer: writer);
        params.dictionaryFormat.preparePitches(params: params, writer: writer);
        params.dictionaryFormat
            .prepareFrequencies(params: params, writer: writer);
      } finally {
        writer.close();
      }

      database.execute('COMMIT');
      return dictionaryId;
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  } catch (e, stack) {
    debugPrint('$e');
    debugPrint('$stack');

    params.send('$stack');

    rethrow;
  } finally {
    database.close();
  }
}

/// Preloads the entities linked to a search result.
void preloadResultSync(int id) {
  /// Create a new instance of Isar as this is a different isolate.
  final Isar database = Isar.getInstance()!;
  DictionarySearchResult result = database.dictionarySearchResults.getSync(id)!;

  result.headings.loadSync();

  for (DictionaryHeading heading in result.headings) {
    heading.entries.loadSync();
    for (DictionaryEntry entry in heading.entries) {
      entry.dictionary.loadSync();
      entry.tags.loadSync();
    }
    heading.pitches.loadSync();
    heading.frequencies.loadSync();
    for (DictionaryFrequency frequency in heading.frequencies) {
      frequency.dictionary.loadSync();
    }
    heading.tags.loadSync();
  }
}

/// Add a [DictionarySearchResult] to the dictionary history. If the maximum value
/// is exceed, the dictionary history is cut down to the newest values.
Future<void> updateDictionaryHistoryHelper(
  UpdateDictionaryHistoryParams params,
) async {
  final Isar database = await Isar.open(
    globalSchemas,
    directory: params.directoryPath,
    maxSizeMiB: 8192,
  );

  DictionarySearchResult result =
      database.dictionarySearchResults.getSync(params.resultId)!;

  database.writeTxnSync(() {
    result.scrollPosition = params.newPosition;
    database.dictionarySearchResults.putSync(result);
  });
}

/// Clears all data from the dictionary database.
Future<void> deleteDictionariesHelper(DeleteDictionaryParams params) async {
  AppDatabase database = AppDatabase.open(params.databasePath);
  try {
    await deleteAllDictionaryData(database);
  } finally {
    await database.close();
  }
}

/// Clears single dictionary data from the dictionary database.
Future<void> deleteDictionaryHelper(DeleteDictionaryParams params) async {
  AppDatabase database = AppDatabase.open(params.databasePath);
  try {
    await deleteDictionaryData(database, params.dictionaryId!);
  } finally {
    await database.close();
  }
}
