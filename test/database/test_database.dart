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
