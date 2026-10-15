import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

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
      // The import is one transaction, so the WAL file has grown to the
      // dictionary's size; truncate it, or it keeps that size for as long
      // as the main connection stays open.
      database.select('PRAGMA wal_checkpoint(TRUNCATE)');
      return dictionaryId;
    } catch (_) {
      if (!database.autocommit) {
        database.execute('ROLLBACK');
      }
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
