import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/creator.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/utils.dart';

/// The app's own data over one connection: the libraries and their stashes,
/// the Anki mappings, the mokuro catalogs, the search and dictionary
/// histories, and the dictionary list. Reads are synchronous, through [raw],
/// so widgets can call them while building; writes go through [db], which
/// runs on that same connection.
class AppStore {
  /// Wrap [db] and [raw], the connection it runs on.
  AppStore({required this.db, required this.raw});

  /// The Drift database, for writes.
  final AppDatabase db;

  /// The connection [db] runs on, for synchronous reads only.
  final Database raw;

  /// Run [sql] on [raw] and map each row with a Drift table's `map`, which
  /// decodes columns and applies type converters.
  List<T> _select<T>(
    T Function(Map<String, dynamic> row) map,
    String sql, [
    List<Object?> parameters = const [],
  ]) {
    return raw.select(sql, parameters).map(map).toList();
  }

  /// The items of the media source [mediaSourceIdentifier], least recently
  /// opened first.
  List<MediaItem> mediaItems(String mediaSourceIdentifier) {
    return _select(
      db.mediaItems.map,
      'SELECT * FROM media_item WHERE media_source_identifier = ? '
      'ORDER BY last_opened_at, id',
      [mediaSourceIdentifier],
    );
  }

  /// Insert [item], or update the item with the same source and identifier,
  /// marking it opened now. Sets the item's `id` and `lastOpenedAt`, and
  /// loads its override title, which saving leaves alone.
  Future<void> putMediaItem(MediaItem item) async {
    DateTime now = DateTime.now();
    item.lastOpenedAt = now;
    MediaItemsCompanion companion = MediaItemsCompanion.insert(
      mediaSourceIdentifier: item.mediaSourceIdentifier,
      mediaIdentifier: item.mediaIdentifier,
      title: item.title,
      imageUrl: Value(item.imageUrl),
      sourceMetadata: Value(item.sourceMetadata),
      position: item.position,
      duration: item.duration,
      canDelete: item.canDelete,
      canEdit: item.canEdit,
      lastOpenedAt: now,
    );

    MediaItem row = await db.into(db.mediaItems).insertReturning(
          companion,
          onConflict: DoUpdate(
            (_) => companion,
            target: [
              db.mediaItems.mediaSourceIdentifier,
              db.mediaItems.mediaIdentifier,
            ],
          ),
        );
    item.id = row.id;
    item.overrideTitle = row.overrideTitle;
  }

  /// [putMediaItem], then forget the least recently opened items of the
  /// same source beyond [maximum].
  Future<void> addMediaItem(MediaItem item, {required int maximum}) async {
    await db.transaction(() async {
      await putMediaItem(item);
      await db.customUpdate(
        'DELETE FROM media_item WHERE media_source_identifier = ?1 '
        'AND id NOT IN (SELECT id FROM media_item '
        'WHERE media_source_identifier = ?1 '
        'ORDER BY last_opened_at DESC, id DESC LIMIT ?2)',
        variables: [
          Variable.withString(item.mediaSourceIdentifier),
          Variable.withInt(maximum),
        ],
        updates: {db.mediaItems},
        updateKind: UpdateKind.delete,
      );
    });
  }

  /// Save [item]'s title, cover, metadata and progress, leaving its recency
  /// alone. Does nothing for an item that was never saved.
  Future<void> updateMediaItem(MediaItem item) async {
    int? id = item.id;
    if (id == null) {
      return;
    }

    await (db.update(db.mediaItems)..where((table) => table.id.equals(id)))
        .write(
      MediaItemsCompanion(
        title: Value(item.title),
        imageUrl: Value(item.imageUrl),
        sourceMetadata: Value(item.sourceMetadata),
        position: Value(item.position),
        duration: Value(item.duration),
      ),
    );
  }

  /// Set the title the user gave the media item [id], or clear it with null.
  Future<void> setMediaItemOverrideTitle(int id, String? title) async {
    await (db.update(db.mediaItems)..where((table) => table.id.equals(id)))
        .write(MediaItemsCompanion(overrideTitle: Value(title)));
  }

  /// Delete [item], and with it its stash.
  Future<void> deleteMediaItem(MediaItem item) async {
    await (db.delete(db.mediaItems)..where((table) => table.id.equals(item.id!)))
        .go();
  }

  /// The stash of the media item [mediaItemId], in reading order.
  List<StashItem> stashItems(int mediaItemId) {
    return _select(
      db.stashItems.map,
      'SELECT * FROM stash_item WHERE media_item_id = ? ORDER BY position, id',
      [mediaItemId],
    );
  }

  /// Save [item] and set its `id`. Returns false, saving nothing, when its
  /// book already has this word.
  Future<bool> putStashItem(StashItem item) async {
    StashItem? row = await db.into(db.stashItems).insertReturningOrNull(
          StashItemsCompanion.insert(
            mediaItemId: item.mediaItemId,
            term: item.term,
            reading: item.reading,
            dictionaryName: Value(item.dictionaryName),
            definitions: item.definitions,
            sentence: item.sentence,
            wordStart: item.wordStart,
            wordLength: item.wordLength,
            position: item.position,
            dateAdded: item.dateAdded,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    if (row == null) {
      return false;
    }

    item.id = row.id;
    return true;
  }

  /// Delete the stash items with these [ids].
  Future<void> deleteStashItems(List<int> ids) async {
    await (db.delete(db.stashItems)..where((table) => table.id.isIn(ids)))
        .go();
  }

  /// The card creation profiles, in the user's order.
  List<AnkiMapping> mappings() {
    return _select(
        db.ankiMappings.map, 'SELECT * FROM anki_mapping ORDER BY "order"');
  }

  /// The profile named [label], if any.
  AnkiMapping? mappingByLabel(String label) {
    return _select(db.ankiMappings.map,
        'SELECT * FROM anki_mapping WHERE label = ?', [label]).firstOrNull;
  }

  /// The profile [id], if any.
  AnkiMapping? mappingById(int id) {
    return _select(db.ankiMappings.map,
        'SELECT * FROM anki_mapping WHERE id = ?', [id]).firstOrNull;
  }

  /// Whether another profile, at another position, is named like [mapping].
  bool mappingLabelTaken(AnkiMapping mapping) {
    return raw.select(
      'SELECT 1 FROM anki_mapping WHERE label = ? AND "order" != ? LIMIT 1',
      [mapping.label, mapping.order],
    ).isNotEmpty;
  }

  /// The position after the last profile.
  int nextMappingOrder() {
    return raw
        .select('SELECT COALESCE(MAX("order") + 1, 0) AS next '
            'FROM anki_mapping')
        .first['next'] as int;
  }

  /// Save [mapping], replacing the profile with its id, label or position,
  /// and set its id.
  Future<void> putMapping(AnkiMapping mapping) async {
    AnkiMapping row = await db.into(db.ankiMappings).insertReturning(
          ankiMappingCompanion(mapping),
          mode: InsertMode.insertOrReplace,
        );
    mapping.id = row.id;
  }

  /// Replace every profile with [mappings], keeping their ids. Used to save
  /// a new order: positions are unique, so they cannot be updated one by one.
  Future<void> replaceMappings(List<AnkiMapping> mappings) async {
    await db.transaction(() async {
      await db.delete(db.ankiMappings).go();
      for (AnkiMapping mapping in mappings) {
        await db.into(db.ankiMappings).insert(ankiMappingCompanion(mapping));
      }
    });
  }

  /// Delete the profile [id].
  Future<void> deleteMapping(int id) async {
    await (db.delete(db.ankiMappings)..where((table) => table.id.equals(id)))
        .go();
  }

  /// The mokuro catalogs, in the user's order.
  List<MokuroCatalog> catalogs() {
    return _select(db.mokuroCatalogs.map,
        'SELECT * FROM mokuro_catalog ORDER BY "order"');
  }

  /// Whether another catalog, at another position, has [catalog]'s URL.
  bool catalogUrlTaken(MokuroCatalog catalog) {
    return raw.select(
      'SELECT 1 FROM mokuro_catalog WHERE url = ? AND "order" != ? LIMIT 1',
      [catalog.url, catalog.order],
    ).isNotEmpty;
  }

  /// The position after the last catalog.
  int nextCatalogOrder() {
    return raw
        .select('SELECT COALESCE(MAX("order") + 1, 0) AS next '
            'FROM mokuro_catalog')
        .first['next'] as int;
  }

  /// Save [catalog], replacing the catalog with its id, URL or position, and
  /// set its id.
  Future<void> putCatalog(MokuroCatalog catalog) async {
    MokuroCatalog row = await db.into(db.mokuroCatalogs).insertReturning(
          _catalogCompanion(catalog),
          mode: InsertMode.insertOrReplace,
        );
    catalog.id = row.id;
  }

  /// Replace every catalog with [catalogs], keeping their ids. Used to save a
  /// new order.
  Future<void> replaceCatalogs(List<MokuroCatalog> catalogs) async {
    await db.transaction(() async {
      await db.delete(db.mokuroCatalogs).go();
      for (MokuroCatalog catalog in catalogs) {
        await db.into(db.mokuroCatalogs).insert(_catalogCompanion(catalog));
      }
    });
  }

  /// Delete the catalog [id].
  Future<void> deleteCatalog(int id) async {
    await (db.delete(db.mokuroCatalogs)..where((table) => table.id.equals(id)))
        .go();
  }

  MokuroCatalogsCompanion _catalogCompanion(MokuroCatalog catalog) {
    return MokuroCatalogsCompanion.insert(
      id: Value.absentIfNull(catalog.id),
      name: catalog.name,
      url: catalog.url,
      order: catalog.order,
    );
  }

  /// The search bar's history, oldest first.
  List<String> searchHistory() {
    return raw
        .select('SELECT search_term FROM search_history_item ORDER BY id')
        .map((row) => row['search_term'] as String)
        .toList();
  }

  /// Make [searchTerm] the newest search, keeping the [maximum] newest.
  Future<void> addToSearchHistory(String searchTerm, {required int maximum}) =>
      _addRecentTerm(db.searchHistoryItems, searchTerm, maximum);

  /// Forget the search [searchTerm].
  Future<void> removeFromSearchHistory(String searchTerm) async {
    await (db.delete(db.searchHistoryItems)
          ..where((table) => table.searchTerm.equals(searchTerm)))
        .go();
  }

  /// Forget every search.
  Future<void> clearSearchHistory() async {
    await db.delete(db.searchHistoryItems).go();
  }

  /// Delete [searchTerm] from [table], a table of unique `search_term`s whose
  /// ids give recency, insert it again as the newest, and keep only the
  /// [maximum] newest. [extraColumns] are more column values for the new row.
  Future<void> _addRecentTerm(
    TableInfo<Table, dynamic> table,
    String searchTerm,
    int maximum, {
    Map<String, Variable> extraColumns = const {},
  }) async {
    String name = table.actualTableName;
    String columns = ['search_term', ...extraColumns.keys].join(', ');
    String placeholders = List.filled(extraColumns.length + 1, '?').join(', ');
    await db.transaction(() async {
      await db.customUpdate(
        'DELETE FROM $name WHERE search_term = ?',
        variables: [Variable.withString(searchTerm)],
        updates: {table},
        updateKind: UpdateKind.delete,
      );
      await db.customInsert(
        'INSERT INTO $name ($columns) VALUES ($placeholders)',
        variables: [Variable.withString(searchTerm), ...extraColumns.values],
        updates: {table},
      );
      await db.customUpdate(
        'DELETE FROM $name WHERE id NOT IN '
        '(SELECT id FROM $name ORDER BY id DESC LIMIT ?)',
        variables: [Variable.withInt(maximum)],
        updates: {table},
        updateKind: UpdateKind.delete,
      );
    });
  }

  /// The imported dictionaries, in the user's order.
  List<Dictionary> dictionaries() {
    return _select(
        db.dictionaries.map, 'SELECT * FROM dictionary ORDER BY "order"');
  }

  /// Save [dictionary]'s hidden and collapsed flags.
  Future<void> updateDictionaryFlags(Dictionary dictionary) async {
    await (db.update(db.dictionaries)
          ..where((table) => table.id.equals(dictionary.id)))
        .write(
      DictionariesCompanion(
        isHidden: Value(dictionary.isHidden),
        isCollapsed: Value(dictionary.isCollapsed),
      ),
    );
  }

  /// Save the order of [dictionaries], whose `order` fields hold their new
  /// positions. Positions are unique, so they pass through negative values
  /// first.
  Future<void> reorderDictionaries(List<Dictionary> dictionaries) async {
    await db.transaction(() async {
      for (Dictionary dictionary in dictionaries) {
        await _setDictionaryOrder(dictionary.id, -1 - dictionary.order);
      }
      for (Dictionary dictionary in dictionaries) {
        await _setDictionaryOrder(dictionary.id, dictionary.order);
      }
    });
  }

  Future<void> _setDictionaryOrder(int id, int order) async {
    await (db.update(db.dictionaries)..where((table) => table.id.equals(id)))
        .write(DictionariesCompanion(order: Value(order)));
  }

  /// The searches whose results the Dictionary tab shows, oldest first.
  List<DictionaryHistoryItem> dictionaryHistory() {
    return raw
        .select('SELECT search_term, search_with_wildcards '
            'FROM dictionary_history ORDER BY id')
        .map((row) => (
              searchTerm: row['search_term'] as String,
              searchWithWildcards: row['search_with_wildcards'] == 1,
            ))
        .toList();
  }

  /// Make [searchTerm], searched with or without wildcards, the newest
  /// dictionary history item, keeping the [maximum] newest. Re-adding a term
  /// replaces its flag.
  Future<void> addToDictionaryHistory(
    String searchTerm, {
    required bool searchWithWildcards,
    required int maximum,
  }) =>
      _addRecentTerm(
        db.dictionaryHistoryItems,
        searchTerm,
        maximum,
        extraColumns: {
          'search_with_wildcards': Variable.withBool(searchWithWildcards),
        },
      );

  /// Forget the dictionary history.
  Future<void> clearDictionaryHistory() async {
    await db.delete(db.dictionaryHistoryItems).go();
  }
}

/// A Dictionary tab history item: the term searched, and whether it was
/// searched with wildcards.
typedef DictionaryHistoryItem = ({String searchTerm, bool searchWithWildcards});

/// The row for [mapping]; its id is left to the database when unset.
AnkiMappingsCompanion ankiMappingCompanion(AnkiMapping mapping) {
  return AnkiMappingsCompanion.insert(
    id: Value.absentIfNull(mapping.id),
    label: mapping.label,
    model: mapping.model,
    order: mapping.order,
    exportFieldKeys: mapping.exportFieldKeys,
    creatorFieldKeys: mapping.creatorFieldKeys,
    creatorCollapsedFieldKeys: mapping.creatorCollapsedFieldKeys,
    tags: mapping.tags,
    actions: mapping.actions!,
    enhancements: mapping.enhancements!,
    exportMediaTags: Value(mapping.exportMediaTags),
    useBrTags: Value(mapping.useBrTags),
    prependDictionaryNames: Value(mapping.prependDictionaryNames),
  );
}
