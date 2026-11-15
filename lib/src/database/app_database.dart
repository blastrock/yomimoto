import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;
import 'package:yuuna/creator.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/media.dart';

part 'app_database.g.dart';

/// Name of the database file, in the app support directory.
const String databaseFileName = 'yomimoto.sqlite';

/// The app's SQLite database: dictionaries, libraries, stashes, profiles and
/// histories. Every version comes with a migration and a schema snapshot.
/// Version 2 dropped the mokuro catalogs and the volumes of the legacy mokuro
/// reader; version 3 dropped the text segmentation enhancement.
@DriftDatabase(
  tables: [
    Dictionaries,
    Headings,
    Entries,
    Pitches,
    Frequencies,
    Tags,
    HeadingTags,
    EntryTags,
    MediaItems,
    StashItems,
    AnkiMappings,
    SearchHistoryItems,
    DictionaryHistoryItems,
    PreferenceEntries,
  ],
  include: {'search.drift'},
)
class AppDatabase extends _$AppDatabase {
  /// Open the database over [executor]. Tests pass in-memory executors.
  AppDatabase(super.executor);

  /// Open the database over [raw], a connection prepared by
  /// [configureConnection]. Drift runs on that very connection, so [raw] can
  /// also serve synchronous reads. Closing the database closes [raw].
  AppDatabase.fromRaw(Database raw) : super(NativeDatabase.opened(raw));

  /// Open the database file at [path] on a connection of its own, as the
  /// isolates do.
  factory AppDatabase.open(String path) =>
      AppDatabase.fromRaw(openRawDatabase(path));

  @override
  int get schemaVersion => 3;

  /// Creates the schema, then the standard profile with id
  /// [AnkiMapping.standardProfileId]. That profile cannot be deleted, so the
  /// id is never handed out again.
  ///
  /// Version 2 removes what the legacy mokuro reader left: its catalogs,
  /// its volumes (legacy HTML URLs the new reader cannot open) with their
  /// stashes, and two dropped settings.
  ///
  /// Version 3 takes the removed text segmentation enhancement out of every
  /// profile's slots. The creator expects every assigned enhancement to be
  /// registered, so a profile still naming it would break the creator.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(ankiMappings).insert(ankiMappingCompanion(
              AnkiMapping.defaultMapping(order: 0)
                ..id = AnkiMapping.standardProfileId));
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement('DROP TABLE IF EXISTS mokuro_catalog');
            // Not left to the cascade: foreign keys may be off while a
            // migration runs.
            await customStatement('DELETE FROM stash_item '
                'WHERE media_item_id IN (SELECT id FROM media_item '
                "WHERE media_source_identifier = 'reader_mokuro')");
            await customStatement('DELETE FROM media_item '
                "WHERE media_source_identifier = 'reader_mokuro'");
            await customStatement('DELETE FROM preference WHERE key IN '
                "('reader_mokuro/use_dark_theme', "
                "'reader_mokuro/extend_page_beyond_navbar')");
          }
          if (from < 3) {
            // Rebuilds each profile's field-to-slot map without the
            // enhancement; the other slots keep their numbers.
            await customStatement('''
              UPDATE anki_mapping SET enhancements = (
                SELECT json_group_object(field.key, json((
                  SELECT json_group_object(slot.key, slot.value)
                  FROM json_each(field.value) AS slot
                  WHERE slot.value != 'text_segmentation')))
                FROM json_each(anki_mapping.enhancements) AS field)
            ''');
          }
        },
      );
}

/// Apply the settings every connection needs: a busy timeout, incremental
/// vacuum, WAL and foreign keys. The busy timeout comes first so the others
/// wait for a writer instead of failing. Setting `auto_vacuum` opens a write
/// transaction, so it is only set when not already incremental; it only takes
/// effect while the database has no tables, so in practice it is set once,
/// on the first open of a fresh file.
void configureConnection(Database database) {
  database.execute('PRAGMA busy_timeout = 10000');
  if (database.select('PRAGMA auto_vacuum').first.columnAt(0) != 2) {
    database.execute('PRAGMA auto_vacuum = INCREMENTAL');
  }
  database
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA foreign_keys = ON');
}

/// Open the database file at [path] on a new raw connection, prepared by
/// [configureConnection]. The connection is closed if preparing it fails.
Database openRawDatabase(String path) {
  Database database = sqlite3.open(path);
  try {
    configureConnection(database);
  } catch (_) {
    database.close();
    rethrow;
  }
  return database;
}
