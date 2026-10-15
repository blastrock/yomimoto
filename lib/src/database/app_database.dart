import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;
import 'package:yuuna/creator.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/utils.dart';

part 'app_database.g.dart';

/// Name of the database file, in the app support directory.
const String databaseFileName = 'yomimoto.sqlite';

/// The app's SQLite database: dictionaries, libraries, stashes, profiles,
/// catalogs and histories. Schema version 1 is the 1.0 baseline; every later
/// version comes with a migration and a schema snapshot.
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
    MokuroCatalogs,
    SearchHistoryItems,
    DictionaryHistoryItems,
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
  int get schemaVersion => 1;
}

/// Apply the settings every connection needs: foreign keys, WAL, a busy
/// timeout, and incremental vacuum. `auto_vacuum` only takes effect while the
/// database has no tables, so it sticks from the first open.
void configureConnection(Database database) {
  database
    ..execute('PRAGMA auto_vacuum = INCREMENTAL')
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA foreign_keys = ON')
    ..execute('PRAGMA busy_timeout = 10000');
}

/// Open the database file at [path] on a new raw connection, prepared by
/// [configureConnection].
Database openRawDatabase(String path) {
  Database database = sqlite3.open(path);
  configureConnection(database);
  return database;
}
