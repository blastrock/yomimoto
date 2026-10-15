import 'package:sqlite3/sqlite3.dart' show Database, PreparedStatement;
import 'package:yuuna/database.dart';

/// Writes one dictionary's tags, entries, pitches and frequencies during an
/// import, through prepared statements on the import isolate's raw
/// connection. It runs inside the import's transaction, which its caller
/// owns, so a failure leaves nothing behind. The only raw writer in the app:
/// a large dictionary is about a million rows, and Drift's per-statement
/// futures would show in the import time.
class DictionaryImportWriter {
  /// Prepare the statements for writing dictionary [dictionaryId] to
  /// [database].
  DictionaryImportWriter({
    required Database database,
    required this.dictionaryId,
  })  : _upsertHeading = database.prepare(
          'INSERT INTO heading (term, reading) VALUES (?, ?) '
          'ON CONFLICT (term, reading) DO UPDATE SET term = excluded.term '
          'RETURNING id',
        ),
        _upsertTag = database.prepare(
          'INSERT INTO tag (dictionary_id, name, category, sorting_order, '
          'notes, popularity) VALUES (?, ?, ?, ?, ?, ?) '
          'ON CONFLICT (dictionary_id, name) DO UPDATE SET '
          'category = excluded.category, '
          'sorting_order = excluded.sorting_order, '
          'notes = excluded.notes, popularity = excluded.popularity '
          'RETURNING id',
        ),
        _insertEntry = database.prepare(
          'INSERT INTO entry (heading_id, dictionary_id, definitions, '
          'popularity) VALUES (?, ?, ?, ?) RETURNING id',
        ),
        _insertEntryTag = database.prepare(
          'INSERT OR IGNORE INTO entry_tag (entry_id, tag_id) VALUES (?, ?)',
        ),
        _insertHeadingTag = database.prepare(
          'INSERT OR IGNORE INTO heading_tag (heading_id, tag_id) '
          'VALUES (?, ?)',
        ),
        _insertPitch = database.prepare(
          'INSERT INTO pitch (heading_id, dictionary_id, downstep) '
          'VALUES (?, ?, ?)',
        ),
        _insertFrequency = database.prepare(
          'INSERT INTO frequency (heading_id, dictionary_id, value, '
          'display_value) VALUES (?, ?, ?, ?)',
        );

  /// The dictionary being written.
  final int dictionaryId;

  final PreparedStatement _upsertHeading;
  final PreparedStatement _upsertTag;
  final PreparedStatement _insertEntry;
  final PreparedStatement _insertEntryTag;
  final PreparedStatement _insertHeadingTag;
  final PreparedStatement _insertPitch;
  final PreparedStatement _insertFrequency;

  final Map<(String, String), int> _headingIds = {};
  final Map<String, int> _tagIds = {};

  static const StringListConverter _definitions = StringListConverter();

  /// The id of the heading ([term], [reading]), creating it if no
  /// dictionary has it yet. Memoised for the import.
  int headingId({required String term, required String reading}) {
    return _headingIds.putIfAbsent(
      (term, reading),
      () => _upsertHeading.select([term, reading]).first['id'] as int,
    );
  }

  /// Define the tag [name]. Defining it again overwrites it.
  void addTag({
    required String name,
    required String category,
    required int sortingOrder,
    required String notes,
    required double popularity,
  }) {
    _tagIds[name] = _upsertTag.select([
      dictionaryId,
      name,
      category,
      sortingOrder,
      notes,
      popularity,
    ]).first['id'] as int;
  }

  /// Add an entry to the heading [headingId], tagged with
  /// [entryTagNames], and tag the heading with [headingTagNames]. Tag names
  /// this dictionary does not define are skipped.
  void addEntry({
    required int headingId,
    required List<String> definitions,
    required double popularity,
    List<String> entryTagNames = const [],
    List<String> headingTagNames = const [],
  }) {
    int entryId = _insertEntry.select([
      headingId,
      dictionaryId,
      _definitions.toSql(definitions),
      popularity,
    ]).first['id'] as int;

    for (String name in entryTagNames) {
      int? tagId = _tagIds[name];
      if (tagId != null) {
        _insertEntryTag.execute([entryId, tagId]);
      }
    }
    for (String name in headingTagNames) {
      int? tagId = _tagIds[name];
      if (tagId != null) {
        _insertHeadingTag.execute([headingId, tagId]);
      }
    }
  }

  /// Add a pitch accent to the heading [headingId].
  void addPitch({required int headingId, required int downstep}) {
    _insertPitch.execute([headingId, dictionaryId, downstep]);
  }

  /// Add a frequency to the heading [headingId].
  void addFrequency({
    required int headingId,
    required double value,
    required String displayValue,
  }) {
    _insertFrequency.execute([headingId, dictionaryId, value, displayValue]);
  }

  /// Release the prepared statements.
  void close() {
    for (PreparedStatement statement in [
      _upsertHeading,
      _upsertTag,
      _insertEntry,
      _insertEntryTag,
      _insertHeadingTag,
      _insertPitch,
      _insertFrequency,
    ]) {
      statement.close();
    }
  }
}
