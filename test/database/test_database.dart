import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;
import 'package:yuuna/database.dart';

/// An opened in-memory database, configured like the app's, with the raw
/// connection Drift runs on.
typedef TestDatabase = ({AppDatabase db, Database raw});

/// Open a fresh [TestDatabase] with its schema created.
Future<TestDatabase> openTestDatabase() async {
  Database raw = sqlite3.openInMemory();
  configureConnection(raw);
  AppDatabase db = AppDatabase.fromRaw(raw);
  await db.customSelect('SELECT 1').get();
  return (db: db, raw: raw);
}

/// The number of rows in [table].
int countRows(Database raw, String table) {
  return raw.select('SELECT COUNT(*) AS count FROM $table').first['count']
      as int;
}

/// Insert a dictionary row named [name], last in order, and return its id.
int insertTestDictionary(Database raw, String name) {
  raw.execute(
    'INSERT INTO dictionary (name, format_key, "order") VALUES '
    '(?, ?, (SELECT COALESCE(MAX("order"), 0) + 1 FROM dictionary))',
    [name, 'yomichan'],
  );
  return raw.lastInsertRowId;
}

/// Insert a dictionary named [name] and let [write] fill it through a
/// [DictionaryImportWriter], as an import would. Returns its id.
int writeTestDictionary(
  Database raw,
  String name,
  void Function(DictionaryImportWriter writer) write,
) {
  int dictionaryId = insertTestDictionary(raw, name);
  DictionaryImportWriter writer =
      DictionaryImportWriter(database: raw, dictionaryId: dictionaryId);
  try {
    write(writer);
  } finally {
    writer.close();
  }
  return dictionaryId;
}
