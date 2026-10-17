import 'package:drift/drift.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/utils.dart';

/// Imported dictionaries.
@UseRowClass(Dictionary)
class Dictionaries extends Table {
  @override
  String get tableName => 'dictionary';

  /// Never reused, so a new dictionary cannot inherit an old one's resource
  /// directory.
  IntColumn get id => integer().autoIncrement()();

  /// Title of the dictionary, read from its archive.
  TextColumn get name => text().unique()();

  /// `uniqueKey` of the dictionary format that imported it.
  TextColumn get formatKey => text()();

  /// Position in the user's dictionary list.
  IntColumn get order => integer().unique()();

  /// Whether its results are hidden.
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();

  /// Whether its entries show folded.
  BoolColumn get isCollapsed => boolean().withDefault(const Constant(false))();
}

/// Words: a term and its reading, shared by every dictionary that has
/// something to say about them.
@DataClassName('HeadingRow')
@TableIndex(name: 'heading_reading', columns: {#reading})
class Headings extends Table {
  @override
  String get tableName => 'heading';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The word as written.
  TextColumn get term => text()();

  /// The word's reading, empty for kanji entries and words given no reading.
  TextColumn get reading => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {term, reading},
      ];
}

/// One dictionary's definitions of a heading.
@DataClassName('EntryRow')
@TableIndex(name: 'entry_heading_id', columns: {#headingId})
@TableIndex(name: 'entry_dictionary_id', columns: {#dictionaryId})
class Entries extends Table {
  @override
  String get tableName => 'entry';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The word defined.
  IntColumn get headingId => integer().references(Headings, #id)();

  /// The dictionary giving the definitions.
  IntColumn get dictionaryId => integer()
      .references(Dictionaries, #id, onDelete: KeyAction.cascade)();

  /// The definitions: plain text, or a structured content JSON document.
  TextColumn get definitions => text().map(const StringListConverter())();

  /// The dictionary's popularity score for this entry; higher is commoner.
  RealColumn get popularity => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Pitch accents of headings.
@DataClassName('PitchRow')
@TableIndex(name: 'pitch_heading_id', columns: {#headingId})
@TableIndex(name: 'pitch_dictionary_id', columns: {#dictionaryId})
class Pitches extends Table {
  @override
  String get tableName => 'pitch';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The word.
  IntColumn get headingId => integer().references(Headings, #id)();

  /// The pitch dictionary it comes from.
  IntColumn get dictionaryId => integer()
      .references(Dictionaries, #id, onDelete: KeyAction.cascade)();

  /// The mora after which the pitch drops; 0 for a flat pattern.
  IntColumn get downstep => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Frequency ranks of headings.
@DataClassName('FrequencyRow')
@TableIndex(name: 'frequency_heading_id', columns: {#headingId})
@TableIndex(name: 'frequency_dictionary_id', columns: {#dictionaryId})
class Frequencies extends Table {
  @override
  String get tableName => 'frequency';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The word.
  IntColumn get headingId => integer().references(Headings, #id)();

  /// The frequency dictionary it comes from.
  IntColumn get dictionaryId => integer()
      .references(Dictionaries, #id, onDelete: KeyAction.cascade)();

  /// The rank, for sorting; lower is more frequent.
  RealColumn get value => real()();

  /// The rank as the dictionary displays it.
  TextColumn get displayValue => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Labels a dictionary defines, attached to its entries and headings.
@DataClassName('TagRow')
class Tags extends Table {
  @override
  String get tableName => 'tag';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The dictionary defining the tag.
  IntColumn get dictionaryId => integer()
      .references(Dictionaries, #id, onDelete: KeyAction.cascade)();

  /// The short label, such as `v1` or `P`.
  TextColumn get name => text()();

  /// The kind of tag; picks its colour.
  TextColumn get category => text()();

  /// Display order among tags.
  IntColumn get sortingOrder => integer()();

  /// What the label means.
  TextColumn get notes => text()();

  /// The dictionary's score for the tag.
  RealColumn get popularity => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {dictionaryId, name},
      ];
}

/// Tags on a heading as a whole.
@DataClassName('HeadingTagRow')
@TableIndex(name: 'heading_tag_tag_id', columns: {#tagId})
class HeadingTags extends Table {
  @override
  String get tableName => 'heading_tag';

  /// The heading tagged.
  IntColumn get headingId =>
      integer().references(Headings, #id, onDelete: KeyAction.cascade)();

  /// The tag.
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {headingId, tagId};
}

/// Tags on one dictionary's entry.
@DataClassName('EntryTagRow')
@TableIndex(name: 'entry_tag_tag_id', columns: {#tagId})
class EntryTags extends Table {
  @override
  String get tableName => 'entry_tag';

  /// The entry tagged.
  IntColumn get entryId =>
      integer().references(Entries, #id, onDelete: KeyAction.cascade)();

  /// The tag.
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {entryId, tagId};
}

/// Books in the Novels library and volumes in the mokuro history.
@UseRowClass(MediaItem)
class MediaItems extends Table {
  @override
  String get tableName => 'media_item';

  /// Kept across saves: the stash refers to it.
  IntColumn get id => integer().autoIncrement()();

  /// The media source owning the item.
  TextColumn get mediaSourceIdentifier => text()();

  /// The item within its source.
  TextColumn get mediaIdentifier => text()();

  /// Display title.
  TextColumn get title => text()();

  /// Cover image.
  TextColumn get imageUrl => text().nullable()();

  /// Source-specific state.
  TextColumn get sourceMetadata => text().nullable()();

  /// Progress, in the source's units.
  IntColumn get position => integer()();

  /// Length, in the source's units.
  IntColumn get duration => integer()();

  /// Whether the user may delete the item.
  BoolColumn get canDelete => boolean()();

  /// Whether the user may override its title and cover.
  BoolColumn get canEdit => boolean()();

  /// When the item was last opened; orders the libraries.
  IntColumn get lastOpenedAt =>
      integer().map(const MicrosecondsConverter())();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {mediaSourceIdentifier, mediaIdentifier},
      ];
}

/// Words saved from books.
@UseRowClass(StashItem)
class StashItems extends Table {
  @override
  String get tableName => 'stash_item';

  /// Assigned on insert.
  IntColumn get id => integer().autoIncrement()();

  /// The book the word was saved from.
  IntColumn get mediaItemId =>
      integer().references(MediaItems, #id, onDelete: KeyAction.cascade)();

  /// The word as written.
  TextColumn get term => text()();

  /// The word's reading.
  TextColumn get reading => text()();

  /// The dictionary of the entry picked when saving, if one was.
  TextColumn get dictionaryName => text().nullable()();

  /// The definitions shown when saving.
  TextColumn get definitions => text().map(const StringListConverter())();

  /// The sentence the word was found in.
  TextColumn get sentence => text()();

  /// Where the word starts in [sentence].
  IntColumn get wordStart => integer()();

  /// How long the word is in [sentence].
  IntColumn get wordLength => integer()();

  /// Where the word is in the book, in ttu bookmark units.
  IntColumn get position => integer()();

  /// When the word was saved.
  DateTimeColumn get dateAdded => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {mediaItemId, term, reading},
      ];
}

/// Card creation profiles.
@UseRowClass(AnkiMapping)
class AnkiMappings extends Table {
  @override
  String get tableName => 'anki_mapping';

  /// Assigned on insert.
  IntColumn get id => integer().autoIncrement()();

  /// The profile name.
  TextColumn get label => text().unique()();

  /// The AnkiDroid note type exported to.
  TextColumn get model => text()();

  /// Position in the profile list.
  IntColumn get order => integer().unique()();

  /// Creator field keys, in note field order; null for an empty note field.
  TextColumn get exportFieldKeys =>
      text().map(const NullableStringListConverter())();

  /// Creator fields shown.
  TextColumn get creatorFieldKeys =>
      text().map(const StringListConverter())();

  /// Creator fields shown folded.
  TextColumn get creatorCollapsedFieldKeys =>
      text().map(const StringListConverter())();

  /// Tags added to every exported card.
  TextColumn get tags => text().map(const StringListConverter())();

  /// Quick actions on dictionary results, slot to action key.
  TextColumn get actions => text().map(const QuickActionsColumnConverter())();

  /// Enhancements per field, slot to enhancement key.
  TextColumn get enhancements =>
      text().map(const EnhancementsColumnConverter())();

  /// Whether exported media get Anki tags rather than bare file names.
  BoolColumn get exportMediaTags => boolean().nullable()();

  /// Whether line breaks are exported as `<br>`.
  BoolColumn get useBrTags => boolean().nullable()();

  /// Whether meanings are prefixed with their dictionary's name.
  BoolColumn get prependDictionaryNames => boolean().nullable()();
}

/// Saved mokuro catalogs.
@UseRowClass(MokuroCatalog)
class MokuroCatalogs extends Table {
  @override
  String get tableName => 'mokuro_catalog';

  /// Assigned on insert.
  IntColumn get id => integer().autoIncrement()();

  /// Display name.
  TextColumn get name => text()();

  /// Where the catalog is.
  TextColumn get url => text().unique()();

  /// Position in the catalog list.
  IntColumn get order => integer().unique()();
}

/// Search terms typed in the dictionary search bar. Ids give recency.
@DataClassName('SearchHistoryRow')
class SearchHistoryItems extends Table {
  @override
  String get tableName => 'search_history_item';

  /// Assigned on insert; never reused, so it orders by recency.
  IntColumn get id => integer().autoIncrement()();

  /// The term searched.
  TextColumn get searchTerm => text().unique()();
}

/// Search terms whose results are shown on the Dictionary tab. Ids give
/// recency.
@DataClassName('DictionaryHistoryRow')
class DictionaryHistoryItems extends Table {
  @override
  String get tableName => 'dictionary_history';

  /// Assigned on insert; never reused, so it orders by recency.
  IntColumn get id => integer().autoIncrement()();

  /// The term searched.
  TextColumn get searchTerm => text().unique()();

  /// Whether the term was searched with wildcards, so that it is searched
  /// again the same way.
  BoolColumn get searchWithWildcards =>
      boolean().withDefault(const Constant(false))();
}

/// Preferences, one row per setting that differs from its default. Read and
/// written only through `PreferenceStore`.
@DataClassName('PreferenceEntry')
class PreferenceEntries extends Table {
  @override
  String get tableName => 'preference';

  /// The setting's name. Per-source settings are prefixed with the source's
  /// `uniqueKey` and a `/`.
  TextColumn get key => text()();

  /// The setting's value, as JSON.
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
