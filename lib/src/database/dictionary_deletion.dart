import 'package:yuuna/database.dart';

/// Delete the dictionary [dictionaryId] with everything it brought, then the
/// headings nothing refers to any more, then give the freed pages back to
/// the file system.
Future<void> deleteDictionaryData(AppDatabase db, int dictionaryId) async {
  await db.transaction(() async {
    await (db.delete(db.dictionaries)
          ..where((table) => table.id.equals(dictionaryId)))
        .go();
    await db.customStatement(_deleteOrphanHeadings);
  });
  await db.customStatement('PRAGMA incremental_vacuum');
}

/// Delete every dictionary and all their data.
Future<void> deleteAllDictionaryData(AppDatabase db) async {
  await db.transaction(() async {
    await db.delete(db.dictionaries).go();
    await db.customStatement(_deleteOrphanHeadings);
  });
  await db.customStatement('PRAGMA incremental_vacuum');
}

/// Deleting a dictionary cascades to its entries, pitches, frequencies and
/// tags; headings belong to no dictionary and go once nothing points at them.
const String _deleteOrphanHeadings = 'DELETE FROM heading WHERE '
    'NOT EXISTS (SELECT 1 FROM entry WHERE entry.heading_id = heading.id) '
    'AND NOT EXISTS (SELECT 1 FROM pitch WHERE pitch.heading_id = heading.id) '
    'AND NOT EXISTS (SELECT 1 FROM frequency '
    'WHERE frequency.heading_id = heading.id) '
    'AND NOT EXISTS (SELECT 1 FROM heading_tag '
    'WHERE heading_tag.heading_id = heading.id)';
