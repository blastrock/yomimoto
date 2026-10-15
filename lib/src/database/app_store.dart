import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';
import 'package:yuuna/media.dart';

/// The app's own data over one connection: the libraries and their stashes,
/// and in later additions the profiles, catalogs, histories and dictionary
/// list. Reads are synchronous, through [raw], so widgets can call them while
/// building; writes go through [db], which runs on that same connection.
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
  /// marking it opened now. Sets the item's `id` and `lastOpenedAt`.
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
}
