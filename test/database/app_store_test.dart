import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/media.dart';

import 'test_database.dart';

MediaItem _book(
  String identifier, {
  String title = 'Book',
  String source = 'reader_ttu',
}) {
  return MediaItem(
    mediaIdentifier: identifier,
    title: title,
    mediaSourceIdentifier: source,
    position: 0,
    duration: 1,
    canDelete: false,
    canEdit: true,
  );
}

StashItem _stash(int mediaItemId, {String term = '漢字', int position = 10}) {
  return StashItem(
    mediaItemId: mediaItemId,
    term: term,
    reading: 'かんじ',
    dictionaryName: 'JMdict',
    definitions: ['kanji'],
    sentence: '漢字を書く。',
    wordStart: 0,
    wordLength: 2,
    position: position,
    dateAdded: DateTime(2026, 10, 14),
  );
}

void main() {
  late TestDatabase database;
  late AppStore store;

  setUp(() async {
    database = await openTestDatabase();
    store = AppStore(db: database.db, raw: database.raw);
  });

  tearDown(() => database.db.close());

  group('media items', () {
    test('putMediaItem inserts the item and sets its id', () async {
      MediaItem book = _book('b.html?id=1');
      await store.putMediaItem(book);

      expect(book.id, isNotNull);
      expect(book.lastOpenedAt, isNotNull);
      expect(store.mediaItems('reader_ttu').single.mediaIdentifier,
          'b.html?id=1');
    });

    test('putMediaItem on a known item keeps its id and makes it the newest',
        () async {
      MediaItem first = _book('b.html?id=1');
      await store.putMediaItem(first);
      await store.putMediaItem(_book('b.html?id=2', title: 'Other'));

      MediaItem again = _book('b.html?id=1', title: 'Renamed');
      await store.putMediaItem(again);

      expect(again.id, first.id);
      expect(store.mediaItems('reader_ttu').map((item) => item.title),
          ['Other', 'Renamed']);
    });

    test('concurrent puts of the same item leave one row', () async {
      await Future.wait([
        store.putMediaItem(_book('b.html?id=1')),
        store.putMediaItem(_book('b.html?id=1')),
      ]);

      expect(store.mediaItems('reader_ttu'), hasLength(1));
    });

    test('addMediaItem keeps the most recent items of its source only',
        () async {
      await store.putMediaItem(_book('other', source: 'reader_mokuro'));
      for (int i = 0; i < 5; i++) {
        await store.addMediaItem(_book('m$i'), maximum: 3);
      }

      expect(store.mediaItems('reader_ttu').map((item) => item.mediaIdentifier),
          ['m2', 'm3', 'm4']);
      expect(store.mediaItems('reader_mokuro'), hasLength(1));
    });

    test('updateMediaItem saves the position without reordering', () async {
      MediaItem first = _book('a');
      await store.putMediaItem(first);
      await store.putMediaItem(_book('b'));

      first.position = 42;
      await store.updateMediaItem(first);

      List<MediaItem> items = store.mediaItems('reader_ttu');
      expect(items.map((item) => item.mediaIdentifier), ['a', 'b']);
      expect(items.first.position, 42);
    });

    test('deleting a media item deletes its stash', () async {
      MediaItem book = _book('b.html?id=1');
      await store.putMediaItem(book);
      await store.putStashItem(_stash(book.id!));

      await store.deleteMediaItem(book);

      expect(store.mediaItems('reader_ttu'), isEmpty);
      expect(countRows(database.raw, 'stash_item'), 0);
    });
  });

  group('stash', () {
    late MediaItem book;

    setUp(() async {
      book = _book('b.html?id=1');
      await store.putMediaItem(book);
    });

    test('putStashItem refuses a word the book already has', () async {
      expect(await store.putStashItem(_stash(book.id!)), isTrue);
      expect(await store.putStashItem(_stash(book.id!, position: 99)), isFalse);
      expect(store.stashItems(book.id!), hasLength(1));
    });

    test('stashItems come in reading order', () async {
      await store.putStashItem(_stash(book.id!, term: '後', position: 20));
      await store.putStashItem(_stash(book.id!, term: '前', position: 5));

      expect(store.stashItems(book.id!).map((item) => item.term), ['前', '後']);
    });

    test('deleteStashItems deletes those items', () async {
      StashItem kept = _stash(book.id!, term: '残');
      StashItem gone = _stash(book.id!, term: '消');
      await store.putStashItem(kept);
      await store.putStashItem(gone);

      await store.deleteStashItems([gone.id!]);

      expect(store.stashItems(book.id!).map((item) => item.term), ['残']);
    });
  });
}
