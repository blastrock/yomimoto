import 'dart:math';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart' show Database, PreparedStatement;

/// A bank file of a Yomichan archive: its name, its uncompressed size and
/// a way to read its bytes when its turn comes.
typedef YomichanBank = ({String name, int size, Uint8List Function() read});

/// How many staged rows are inserted by one round of statements.
const int _chunkSize = 1000;

/// Whether [name], an archive entry name, is a bank file this import reads:
/// at the archive's root and starting with `tag_bank`, `term_bank`,
/// `kanji_bank` or `term_meta_bank`.
bool isYomichanBank(String name) {
  if (name.contains('/')) {
    return false;
  }
  return name.startsWith('tag_bank') ||
      name.startsWith('term_bank') ||
      name.startsWith('kanji_bank') ||
      name.startsWith('term_meta_bank');
}

/// Import [banks] as dictionary [dictionaryId] into [database], inside the
/// caller's transaction. [onProgress] gets the fraction of the banks'
/// total size done, after every chunk and at each bank's end.
///
/// SQLite parses the banks itself and inserts set-based: each bank's bytes are
/// bound to one statement that stages its rows in a STRICT temporary table,
/// which type-checks them, and chunks of the stage are then inserted.
void importYomichanBanks({
  required Database database,
  required int dictionaryId,
  required List<YomichanBank> banks,
  required void Function(double fraction) onProgress,
}) {
  List<YomichanBank> accepted =
      banks.where((bank) => isYomichanBank(bank.name)).toList();
  int total = accepted.fold(0, (sum, bank) => sum + bank.size);
  if (total == 0) {
    return;
  }

  _YomichanImport import = _YomichanImport(
    database: database,
    dictionaryId: dictionaryId,
    total: total,
    onProgress: onProgress,
  );
  try {
    import
      ..importTags(
          accepted.where((bank) => bank.name.startsWith('tag_bank')))
      ..importTerms(accepted.where((bank) =>
          bank.name.startsWith('term_bank') ||
          bank.name.startsWith('kanji_bank')))
      ..skip(accepted.where((bank) => bank.name.startsWith('term_meta_bank')));
  } finally {
    import.close();
  }
}

/// The state and statements of one [importYomichanBanks] run.
class _YomichanImport {
  _YomichanImport({
    required this.database,
    required this.dictionaryId,
    required this.total,
    required this.onProgress,
  }) {
    // Temp tables may survive an earlier failed import on this connection.
    database
      ..execute(_createTagStage)
      ..execute('DELETE FROM tag_stage')
      ..execute(_createStage)
      ..execute('DELETE FROM stage');
    _stageTags = database.prepare(_stageTagsSql);
    _insertTags = database.prepare(_insertTagsSql);
    _stageTerms = database.prepare(_stageTermsSql);
    _insertHeadings = database.prepare(_insertHeadingsSql);
    _resolveHeadings = database.prepare(_resolveHeadingsSql);
    _insertEntries = database.prepare(_insertEntriesSql);
    _insertEntryTags = database.prepare(_insertEntryTagsSql);
    _insertHeadingTags = database.prepare(_insertHeadingTagsSql);
  }

  final Database database;
  final int dictionaryId;
  final int total;
  final void Function(double fraction) onProgress;

  /// The bytes of the banks finished so far.
  int _done = 0;

  late final PreparedStatement _stageTags;
  late final PreparedStatement _insertTags;
  late final PreparedStatement _stageTerms;
  late final PreparedStatement _insertHeadings;
  late final PreparedStatement _resolveHeadings;
  late final PreparedStatement _insertEntries;
  late final PreparedStatement _insertEntryTags;
  late final PreparedStatement _insertHeadingTags;

  void importTags(Iterable<YomichanBank> banks) {
    for (YomichanBank bank in banks) {
      database.execute('DELETE FROM tag_stage');
      _stageTags.execute([bank.read()]);
      _insertTags.execute([dictionaryId]);
      _finish(bank);
    }
  }

  void importTerms(Iterable<YomichanBank> banks) {
    for (YomichanBank bank in banks) {
      // Kanji banks come with a later change.
      if (bank.name.startsWith('term_bank')) {
        _importTermBank(bank);
      }
      _finish(bank);
    }
  }

  /// Count [banks] as done without reading them.
  void skip(Iterable<YomichanBank> banks) {
    banks.forEach(_finish);
  }

  void _importTermBank(YomichanBank bank) {
    database.execute('DELETE FROM stage');
    _stageTerms.execute([bank.read()]);
    int rows = _scalar('SELECT COALESCE(MAX(n), 0) FROM stage');
    int offset = _scalar('SELECT COALESCE(MAX(id), 0) FROM entry');
    for (int first = 1; first <= rows; first += _chunkSize) {
      int last = min(first + _chunkSize - 1, rows);
      _insertHeadings.execute([first, last]);
      _resolveHeadings.execute([first, last]);
      _insertEntries.execute([first, last, offset, dictionaryId]);
      _insertEntryTags.execute([first, last, offset, dictionaryId]);
      _insertHeadingTags.execute([first, last, offset, dictionaryId]);
      onProgress((_done + bank.size * last / rows) / total);
    }
  }

  int _scalar(String sql) => database.select(sql).first.values.first as int;

  void _finish(YomichanBank bank) {
    _done += bank.size;
    onProgress(_done / total);
  }

  void close() {
    for (PreparedStatement statement in [
      _stageTags,
      _insertTags,
      _stageTerms,
      _insertHeadings,
      _resolveHeadings,
      _insertEntries,
      _insertEntryTags,
      _insertHeadingTags,
    ]) {
      statement.close();
    }
    database
      ..execute('DROP TABLE IF EXISTS tag_stage')
      ..execute('DROP TABLE IF EXISTS stage');
  }
}

const String _createTagStage = '''
CREATE TEMP TABLE IF NOT EXISTS tag_stage (
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  sorting_order INTEGER NOT NULL,
  notes TEXT NOT NULL,
  popularity REAL NOT NULL
) STRICT''';

const String _createStage = '''
CREATE TEMP TABLE IF NOT EXISTS stage (
  n INTEGER PRIMARY KEY,
  term TEXT NOT NULL,
  reading TEXT NOT NULL,
  def_tags TEXT,
  popularity REAL NOT NULL,
  definitions TEXT NOT NULL,
  term_tags TEXT NOT NULL,
  heading_id INTEGER
) STRICT''';

/// Stage a tag bank (`?1`: its bytes).
const String _stageTagsSql = '''
INSERT INTO tag_stage (name, category, sorting_order, notes, popularity)
SELECT value->>0, value->>1, value->>2, value->>3, value->>4
FROM json_each(CAST(?1 AS TEXT))''';

/// Insert the staged tags of dictionary `?1`; defining a name again
/// overwrites it.
const String _insertTagsSql = '''
INSERT INTO tag (dictionary_id, name, category, sorting_order, notes,
  popularity)
SELECT ?1, name, category, sorting_order, notes, popularity
FROM tag_stage WHERE true
ON CONFLICT (dictionary_id, name) DO UPDATE SET
  category = excluded.category, sorting_order = excluded.sorting_order,
  notes = excluded.notes, popularity = excluded.popularity''';

/// Stage a term bank (`?1`: its bytes). Definitions are converted as
/// `YomichanFormat.processDefinition` does: a string as is, a text element's
/// text, the content of structured content and images as JSON, anything else
/// dropped. The outer row is aliased `r` because inside the subquery a bare
/// `value` is the inner `json_each`'s. A text element whose text is not a
/// string, or definitions that are not a list, make the value NULL, which the
/// column rejects. `|| ''` strips the JSON subtype, so the content is added to
/// the array as a string.
const String _stageTermsSql = '''
INSERT INTO stage (term, reading, def_tags, popularity, definitions, term_tags)
SELECT r.value->>0, r.value->>1, r.value->>2, r.value->>4,
  CASE WHEN json_type(r.value->5) = 'array' THEN (
    SELECT CASE WHEN min(bad) = 0 THEN json_group_array(d) FILTER (
        WHERE d IS NOT NULL) END
    FROM (
      SELECT CASE
        WHEN e.type = 'text' THEN e.atom
        WHEN e.type = 'object' AND e.value->>'type' = 'text'
          THEN e.value->>'text'
        WHEN e.type = 'object'
            AND e.value->>'type' IN ('structured-content', 'image')
          THEN COALESCE(json(e.value->'content'), 'null') || ''
      END AS d,
      CASE WHEN e.type = 'object' AND e.value->>'type' = 'text'
        THEN json_type(e.value, '\$.text') NOT IN ('text', 'null')
        ELSE 0 END AS bad
      FROM json_each(r.value->5) e
      ORDER BY e.id
    )) END,
  r.value->>7
FROM json_each(CAST(?1 AS TEXT)) r''';

/// Insert the headings of the chunk `?1` to `?2` of the stage.
const String _insertHeadingsSql = '''
INSERT INTO heading (term, reading)
SELECT term, reading FROM stage WHERE n BETWEEN ?1 AND ?2
ON CONFLICT DO NOTHING''';

/// Find the heading of each staged row of the chunk `?1` to `?2`.
const String _resolveHeadingsSql = '''
UPDATE stage SET heading_id = (
  SELECT h.id FROM heading h
  WHERE h.term = stage.term AND h.reading = stage.reading)
WHERE n BETWEEN ?1 AND ?2''';

/// Insert the entries of the chunk `?1` to `?2`; `?3`: the entry id offset,
/// `?4`: the dictionary id.
const String _insertEntriesSql = '''
INSERT INTO entry (id, heading_id, dictionary_id, definitions, popularity)
SELECT n + ?3, heading_id, ?4, definitions, popularity
FROM stage WHERE n BETWEEN ?1 AND ?2''';

/// Insert the entry tags of the chunk, with the parameters of
/// [_insertEntriesSql]. `stage` stays the outer loop (`CROSS JOIN`), or the
/// planner re-splits every row once per tag.
const String _insertEntryTagsSql = r'''
INSERT OR IGNORE INTO entry_tag (entry_id, tag_id)
SELECT s.n + ?3, t.id
FROM stage s
CROSS JOIN json_each('["' || replace(replace(replace(s.def_tags,
    '\', '\\'), '"', '\"'), ' ', '","') || '"]') j
CROSS JOIN tag t ON t.dictionary_id = ?4 AND t.name = j.value
WHERE s.n BETWEEN ?1 AND ?2 AND s.def_tags IS NOT NULL AND s.def_tags <> ''
''';

/// Insert the heading tags of the chunk, with the parameters of
/// [_insertEntriesSql].
const String _insertHeadingTagsSql = r'''
INSERT OR IGNORE INTO heading_tag (heading_id, tag_id)
SELECT s.heading_id, t.id
FROM stage s
CROSS JOIN json_each('["' || replace(replace(replace(s.term_tags,
    '\', '\\'), '"', '\"'), ' ', '","') || '"]') j
CROSS JOIN tag t ON t.dictionary_id = ?4 AND t.name = j.value
WHERE s.n BETWEEN ?1 AND ?2 AND s.term_tags <> ''
''';
