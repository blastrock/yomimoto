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
      ..importMeta(
          accepted.where((bank) => bank.name.startsWith('term_meta_bank')));
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
      ..execute('DELETE FROM stage')
      ..execute(_createMetaStage)
      ..execute('DELETE FROM meta_stage')
      ..execute(_createPitchStage)
      ..execute('DELETE FROM pitch_stage');
    _stageTags = database.prepare(_stageTagsSql);
    _insertTags = database.prepare(_insertTagsSql);
    _stageTerms = database.prepare(_stageTermsSql);
    _stageKanji = database.prepare(_stageKanjiSql);
    _insertHeadings = database.prepare(_insertHeadingsSql);
    _resolveHeadings = database.prepare(_resolveHeadingsSql);
    _insertEntries = database.prepare(_insertEntriesSql);
    _insertEntryTags = database.prepare(_insertEntryTagsSql);
    _insertHeadingTags = database.prepare(_insertHeadingTagsSql);
    _stageMeta = database.prepare(_stageMetaSql);
    _insertMetaHeadings = database.prepare(_insertMetaHeadingsSql);
    _resolveMetaHeadings = database.prepare(_resolveMetaHeadingsSql);
    _insertFrequencies = database.prepare(_insertFrequenciesSql);
    _stagePitches = database.prepare(_stagePitchesSql);
    _insertPitches = database.prepare(_insertPitchesSql);
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
  late final PreparedStatement _stageKanji;
  late final PreparedStatement _insertHeadings;
  late final PreparedStatement _resolveHeadings;
  late final PreparedStatement _insertEntries;
  late final PreparedStatement _insertEntryTags;
  late final PreparedStatement _insertHeadingTags;
  late final PreparedStatement _stageMeta;
  late final PreparedStatement _insertMetaHeadings;
  late final PreparedStatement _resolveMetaHeadings;
  late final PreparedStatement _insertFrequencies;
  late final PreparedStatement _stagePitches;
  late final PreparedStatement _insertPitches;

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
      _importTermBank(bank);
      _finish(bank);
    }
  }

  /// Import the frequencies and pitches of the term meta [banks].
  void importMeta(Iterable<YomichanBank> banks) {
    for (YomichanBank bank in banks) {
      database.execute('DELETE FROM meta_stage');
      _stageMeta.execute([bank.read()]);
      int rows = _scalar('SELECT COALESCE(MAX(n), 0) FROM meta_stage');
      for (int first = 1; first <= rows; first += _chunkSize) {
        int last = min(first + _chunkSize - 1, rows);
        _insertMetaHeadings.execute([first, last]);
        _resolveMetaHeadings.execute([first, last]);
        _insertFrequencies.execute([first, last, dictionaryId]);
        database.execute('DELETE FROM pitch_stage');
        _stagePitches.execute([first, last]);
        _insertPitches.execute([dictionaryId]);
        onProgress((_done + bank.size * last / rows) / total);
      }
      _finish(bank);
    }
  }

  /// Import a term bank or a kanji bank: both are staged, and the same
  /// statements insert them.
  void _importTermBank(YomichanBank bank) {
    database.execute('DELETE FROM stage');
    (bank.name.startsWith('kanji_bank') ? _stageKanji : _stageTerms)
        .execute([bank.read()]);
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
      _stageKanji,
      _insertHeadings,
      _resolveHeadings,
      _insertEntries,
      _insertEntryTags,
      _insertHeadingTags,
      _stageMeta,
      _insertMetaHeadings,
      _resolveMetaHeadings,
      _insertFrequencies,
      _stagePitches,
      _insertPitches,
    ]) {
      statement.close();
    }
    database
      ..execute('DROP TABLE IF EXISTS tag_stage')
      ..execute('DROP TABLE IF EXISTS stage')
      ..execute('DROP TABLE IF EXISTS meta_stage')
      ..execute('DROP TABLE IF EXISTS pitch_stage');
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

/// SQL giving [value], the element [index] of the JSON array [row], when that
/// element is a string or a number, which SQLite converts to text or real
/// without loss, and NULL otherwise: a missing element, `null`, a boolean, an
/// object or an array. The staging columns reject NULL.
String _scalar(String row, int index, String value) =>
    "CASE WHEN json_type($row, '\$[$index]') IN ('text', 'integer', 'real') "
    'THEN $value END';

/// Stage a term bank (`?1`: its bytes). The term, the reading, the popularity
/// and the term tags must be strings or numbers, and the definition tags a
/// string, a number or `null`; a row with anything else, or with a missing
/// element, fails the import (the definitions column is made NULL for a bad
/// definition tags, which the column rejects). Definitions are converted as
/// `YomichanFormat.processDefinition` does: a string as is, a text element's
/// text, the content of structured content and images as JSON, anything else
/// dropped. The outer row is aliased `r` because inside the subquery a bare
/// `value` is the inner `json_each`'s. A text element whose text is not a
/// string, or definitions that are not a list, make the value NULL, which the
/// column rejects. `|| ''` strips the JSON subtype, so the content is added to
/// the array as a string.
final String _stageTermsSql = '''
INSERT INTO stage (term, reading, def_tags, popularity, definitions, term_tags)
SELECT ${_scalar('r.value', 0, 'r.value->>0')},
  ${_scalar('r.value', 1, 'r.value->>1')}, r.value->>2,
  ${_scalar('r.value', 4, 'r.value->>4')},
  CASE WHEN json_type(r.value->5) = 'array'
      AND json_type(r.value, '\$[2]') IN ('null', 'text', 'integer', 'real')
    THEN (
    SELECT CASE WHEN max(bad) THEN NULL
      ELSE json_group_array(d) FILTER (WHERE d IS NOT NULL) END
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
        THEN COALESCE(
          json_type(e.value, '\$.text') NOT IN ('text', 'null'), 0)
        ELSE 0 END AS bad
      FROM json_each(r.value->5) e
      ORDER BY e.id
    )) END,
  ${_scalar('r.value', 7, 'r.value->>7')}
FROM json_each(CAST(?1 AS TEXT)) r''';

/// The characters trimmed from kanji definitions: the whitespace Dart's `trim`
/// removes from them, ASCII and U+3000.
const String _kanjiTrimmed = "' \t\n\r　'";

/// SQL building the section [title] of a kanji definition when the condition
/// [include] holds: the title, then a bullet for each string of the JSON array
/// [items].
String _kanjiSection(String title, String items, String include) => '''
CASE WHEN $include THEN '$title' || char(10) || (
    SELECT group_concat('  • ' || value || char(10), '' ORDER BY key)
    FROM json_each($items)) || char(10)
  ELSE '' END''';

/// SQL turning the space separated [text] into a JSON array of strings, empty
/// pieces included as `split(' ')` keeps them.
String _kanjiPieces(String text) => '''
'["' || replace(replace(replace($text,
    '\\', '\\\\'), '"', '\\"'), ' ', '","') || '"]\'''';

/// SQL telling whether the readings [text] have something to show: they do
/// unless they are blank once their spaces are gone.
String _kanjiHasReading(String text) =>
    "trim(replace($text, ' ', ''), $_kanjiTrimmed) <> ''";

/// Stage a kanji bank (`?1`: its bytes) like a term bank, with an empty
/// reading, no definition tags and no popularity. The definition is built as
/// `prepareEntriesYomichanFormat` builds it: a section for the on'yomi (音読み)
/// and one for the kun'yomi (訓読み) unless blank, one for the meanings (意味)
/// unless there are none, and the whole trimmed. A kanji whose definition is
/// empty is left out. The term, the readings and the tags must be strings or
/// numbers and the meanings a list of them; a kanji with anything else, or
/// with a missing element, fails the import (its definition is NULL, which the
/// column rejects).
final String _stageKanjiSql = '''
INSERT INTO stage (term, reading, def_tags, popularity, definitions, term_tags)
SELECT term, '', NULL, 0, CASE WHEN definition IS NOT NULL
  THEN json_array(definition) END, term_tags FROM (
  SELECT term, term_tags, CASE
    WHEN term IS NULL OR term_tags IS NULL OR onyomi IS NULL
        OR kunyomi IS NULL OR json_type(meanings) IS NOT 'array'
        OR EXISTS (SELECT 1 FROM json_each(meanings)
          WHERE type NOT IN ('text', 'integer', 'real'))
      THEN NULL
    ELSE trim(
      ${_kanjiSection('音読み', _kanjiPieces('onyomi'), _kanjiHasReading('onyomi'))} ||
      ${_kanjiSection('訓読み', _kanjiPieces('kunyomi'), _kanjiHasReading('kunyomi'))} ||
      ${_kanjiSection('意味', 'meanings', 'json_array_length(meanings) > 0')},
      $_kanjiTrimmed) END AS definition
  FROM (
    SELECT ${_scalar('r.value', 0, 'r.value->>0')} AS term,
      ${_scalar('r.value', 1, 'r.value->>1')} AS onyomi,
      ${_scalar('r.value', 2, 'r.value->>2')} AS kunyomi,
      ${_scalar('r.value', 3, 'r.value->>3')} AS term_tags,
      r.value->4 AS meanings
    FROM json_each(CAST(?1 AS TEXT)) r))
WHERE definition IS NULL OR definition <> ''
''';

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

const String _createMetaStage = '''
CREATE TEMP TABLE IF NOT EXISTS meta_stage (
  n INTEGER PRIMARY KEY,
  term TEXT NOT NULL,
  type TEXT NOT NULL,
  reading TEXT,
  value REAL,
  display_value TEXT,
  data ANY,
  heading_id INTEGER,
  CHECK (type <> 'pitch' OR data IS NOT NULL),
  CHECK (type <> 'freq' OR reading IS NULL OR value IS NOT NULL)
) STRICT''';

const String _createPitchStage = '''
CREATE TEMP TABLE IF NOT EXISTS pitch_stage (
  heading_id INTEGER NOT NULL,
  downstep INTEGER NOT NULL
) STRICT''';

/// SQL giving the number at the JSON [path] of the JSONB `d`, or 0 when it is
/// absent or `null` (as `?? 0` does), and NULL when it is anything else than a
/// number: the stage rejects that, as Dart's cast does.
String _metaNumber(String path) => '''
CASE WHEN COALESCE(json_type(d, '$path'), 'null')
    IN ('null', 'integer', 'real')
  THEN COALESCE(d->>'$path', 0) END''';

/// Stage a term meta bank (`?1`: its bytes), keeping its frequency and pitch
/// rows. For a frequency the heading reading, the value and the display value
/// are computed as `prepareFrequenciesYomichanFormat` does, its cases in its
/// order; a row for which no case sets the reading has a NULL reading and is
/// left out of the import. A pitch takes its `reading` (empty by default) and
/// keeps its `pitches` in `data`, which the table rejects unless it is an
/// array. The term must be a string or a number and the type a string; rows of
/// other types are dropped. The shape is read from a JSONB copy `d` of the
/// third element, in a `MATERIALIZED` subquery so it is parsed once.
final String _stageMetaSql = '''
INSERT INTO meta_stage (term, type, reading, value, display_value, data)
SELECT CASE WHEN t IS NULL AND type IN ('freq', 'pitch') THEN NULL
    ELSE term END, type,
  CASE
    WHEN type <> 'freq' THEN COALESCE(d->>'reading', '')
    WHEN t <> 'object' THEN ''
    WHEN d->>'reading' IS NOT NULL AND json_type(d, '\$.frequency') = 'object'
      THEN d->>'reading'
    WHEN d->>'displayValue' IS NOT NULL OR d->>'value' IS NOT NULL
        OR json_type(d, '\$.frequency') IN ('integer', 'real')
      THEN COALESCE(d->>'reading', '')
  END,
  CASE
    WHEN type <> 'freq' THEN NULL
    WHEN t IN ('integer', 'real') THEN d->>'\$'
    WHEN t <> 'object' THEN 0
    WHEN d->>'reading' IS NOT NULL AND json_type(d, '\$.frequency') = 'object'
      THEN ${_metaNumber('\$.frequency.value')}
    WHEN d->>'displayValue' IS NOT NULL OR d->>'value' IS NOT NULL
      THEN ${_metaNumber('\$.value')}
    ELSE d->>'frequency'
  END,
  CASE
    WHEN type <> 'freq' THEN NULL
    WHEN t = 'integer' THEN d->>'\$'
    WHEN t = 'real' THEN iif(d->>'\$' = floor(d->>'\$'),
      CAST(CAST(d->>'\$' AS INTEGER) AS TEXT), d->>'\$')
    WHEN t IN ('true', 'false', 'null') THEN t
    WHEN t <> 'object' THEN d->>'\$'
    WHEN d->>'reading' IS NOT NULL AND json_type(d, '\$.frequency') = 'object'
      THEN COALESCE(d->'frequency'->>'displayValue', '')
    WHEN d->>'displayValue' IS NOT NULL THEN d->>'displayValue'
    WHEN d->>'value' IS NOT NULL THEN CAST(CAST(d->>'value' AS INTEGER) AS TEXT)
    WHEN json_type(d, '\$.frequency') = 'integer' THEN d->>'frequency'
    ELSE iif(d->>'frequency' = floor(d->>'frequency'),
      CAST(CAST(d->>'frequency' AS INTEGER) AS TEXT), d->>'frequency')
  END,
  CASE WHEN type = 'pitch' AND json_type(d, '\$.pitches') = 'array'
    THEN d->'pitches' END
FROM (
  WITH x AS MATERIALIZED (
    SELECT ${_scalar('value', 0, 'value->>0')} AS term,
      CASE WHEN json_type(value, '\$[1]') = 'text' THEN value->>1 END AS type,
      jsonb(value->2) AS d, json_type(value, '\$[2]') AS t
    FROM json_each(CAST(?1 AS TEXT))
  ) SELECT * FROM x
)
WHERE type IS NULL OR term IS NULL OR type IN ('freq', 'pitch')''';

/// Insert the headings of the chunk `?1` to `?2` of the meta stage.
const String _insertMetaHeadingsSql = '''
INSERT INTO heading (term, reading)
SELECT term, reading FROM meta_stage
WHERE n BETWEEN ?1 AND ?2 AND reading IS NOT NULL
ON CONFLICT DO NOTHING''';

/// Find the heading of each staged meta row of the chunk `?1` to `?2`.
const String _resolveMetaHeadingsSql = '''
UPDATE meta_stage SET heading_id = (
  SELECT h.id FROM heading h
  WHERE h.term = meta_stage.term AND h.reading = meta_stage.reading)
WHERE n BETWEEN ?1 AND ?2 AND reading IS NOT NULL''';

/// Insert the frequencies of the chunk `?1` to `?2`; `?3`: the dictionary id.
const String _insertFrequenciesSql = '''
INSERT INTO frequency (heading_id, dictionary_id, value, display_value)
SELECT heading_id, ?3, value, COALESCE(display_value, '')
FROM meta_stage
WHERE n BETWEEN ?1 AND ?2 AND type = 'freq' AND reading IS NOT NULL
ORDER BY n''';

/// Stage the pitch positions of the chunk `?1` to `?2` in the STRICT pitch
/// stage, which rejects a position that is not an integer.
const String _stagePitchesSql = '''
INSERT INTO pitch_stage (heading_id, downstep)
SELECT m.heading_id, p.value->>'position'
FROM meta_stage m CROSS JOIN json_each(m.data) p
WHERE m.n BETWEEN ?1 AND ?2 AND m.type = 'pitch'
ORDER BY m.n, p.id''';

/// Insert the staged pitches; `?1`: the dictionary id.
const String _insertPitchesSql = '''
INSERT INTO pitch (heading_id, dictionary_id, downstep)
SELECT heading_id, ?1, downstep FROM pitch_stage ORDER BY rowid''';
