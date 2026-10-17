import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/utils.dart';

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
  group('profiles', () {
    AnkiMapping profile(String label, int order) =>
        AnkiMapping.defaultMapping(order: order).copyWith(label: label);

    test('a fresh database holds the Standard profile at id 1', () {
      AnkiMapping standard = store.mappings().single;
      AnkiMapping expected = AnkiMapping.defaultMapping(order: 0);

      expect(standard.id, 1);
      expect(standard.label, AnkiMapping.standardProfileName);
      expect(standard.model, AnkiMapping.standardModelName);
      expect(standard.order, 0);
      expect(standard.exportFieldKeys, expected.exportFieldKeys);
      expect(standard.creatorFieldKeys, expected.creatorFieldKeys);
      expect(standard.tags, expected.tags);
      expect(standard.actions, expected.actions);
      expect(standard.enhancements, expected.enhancements);
      expect(standard.useBrTags, isTrue);
    });

    test('the next profile added gets id 2', () async {
      AnkiMapping mapping = profile('Mine', 1);
      await store.putMapping(mapping);

      expect(mapping.id, 2);
    });

    test('mappingById finds a profile, or nothing', () {
      expect(store.mappingById(1)!.label, AnkiMapping.standardProfileName);
      expect(store.mappingById(99), isNull);
    });

    test('putMapping on a saved profile replaces it', () async {
      AnkiMapping mapping = profile('Mine', 1);
      await store.putMapping(mapping);
      mapping.creatorFieldKeys = ['term'];
      await store.putMapping(mapping);

      expect(store.mappings().length, 2);
      expect(store.mappingById(mapping.id!)!.creatorFieldKeys, ['term']);
    });

    test('replaceMappings swaps orders and keeps ids', () async {
      AnkiMapping standard = store.mappingById(1)!;
      AnkiMapping a = profile('A', 1);
      AnkiMapping b = profile('B', 2);
      await store.putMapping(a);
      await store.putMapping(b);
      int aId = a.id!;
      int bId = b.id!;

      a.order = 2;
      b.order = 1;
      await store.replaceMappings([standard, b, a]);

      List<AnkiMapping> mappings = store.mappings();
      expect(mappings.map((mapping) => mapping.label),
          [AnkiMapping.standardProfileName, 'B', 'A']);
      expect(mappings.map((mapping) => mapping.id), [1, bId, aId]);
    });

    test('nextMappingOrder and mappingLabelTaken', () async {
      expect(store.nextMappingOrder(), 1);
      await store.putMapping(profile('A', 1));
      expect(store.nextMappingOrder(), 2);
      expect(store.mappingLabelTaken(profile('A', 5)), isTrue);
      expect(store.mappingLabelTaken(profile('A', 1)), isFalse);
    });
  });

  group('catalogs', () {
    test('put, reorder and delete', () async {
      MokuroCatalog a = MokuroCatalog(name: 'A', url: 'https://a', order: 0);
      MokuroCatalog b = MokuroCatalog(name: 'B', url: 'https://b', order: 1);
      await store.putCatalog(a);
      await store.putCatalog(b);
      expect(store.catalogUrlTaken(
          MokuroCatalog(name: 'C', url: 'https://a', order: 7)), isTrue);
      expect(store.nextCatalogOrder(), 2);

      a.order = 1;
      b.order = 0;
      await store.replaceCatalogs([b, a]);
      expect(store.catalogs().map((catalog) => catalog.name), ['B', 'A']);

      await store.deleteCatalog(b.id!);
      expect(store.catalogs().map((catalog) => catalog.name), ['A']);
    });
  });

  group('search history', () {
    test('re-adding a term makes it the newest, and the oldest go', () async {
      await store.addToSearchHistory('一', maximum: 3);
      await store.addToSearchHistory('二', maximum: 3);
      await store.addToSearchHistory('三', maximum: 3);
      await store.addToSearchHistory('一', maximum: 3);
      await store.addToSearchHistory('四', maximum: 3);

      expect(store.searchHistory(), ['三', '一', '四']);
    });

    test('remove and clear', () async {
      await store.addToSearchHistory('一', maximum: 3);
      await store.addToSearchHistory('二', maximum: 3);
      await store.removeFromSearchHistory('一');
      expect(store.searchHistory(), ['二']);

      await store.clearSearchHistory();
      expect(store.searchHistory(), isEmpty);
    });
  });

  group('dictionaries', () {
    test('listed in order; flags saved; reordered without constraint errors',
        () async {
      insertTestDictionary(database.raw, 'A');
      insertTestDictionary(database.raw, 'B');

      List<Dictionary> dictionaries = store.dictionaries();
      expect(dictionaries.map((dictionary) => dictionary.name), ['A', 'B']);

      Dictionary a = dictionaries.first..isHidden = true;
      await store.updateDictionaryFlags(a);
      expect(store.dictionaries().first.isHidden, isTrue);

      Dictionary b = dictionaries.last;
      a.order = 2;
      b.order = 1;
      await store.reorderDictionaries([b, a]);
      expect(store.dictionaries().map((dictionary) => dictionary.name),
          ['B', 'A']);
    });
  });

  group('dictionary history', () {
    List<(String, bool)> history() => store
        .dictionaryHistory()
        .map((item) => (item.searchTerm, item.searchWithWildcards))
        .toList();

    test('keeps the newest terms, re-added terms last', () async {
      await store.addToDictionaryHistory('一',
          searchWithWildcards: false, maximum: 2);
      await store.addToDictionaryHistory('二',
          searchWithWildcards: false, maximum: 2);
      await store.addToDictionaryHistory('一',
          searchWithWildcards: false, maximum: 2);
      await store.addToDictionaryHistory('三',
          searchWithWildcards: false, maximum: 2);

      expect(history(), [('一', false), ('三', false)]);

      await store.clearDictionaryHistory();
      expect(store.dictionaryHistory(), isEmpty);
    });

    test('keeps the wildcard flag; re-adding a term replaces it', () async {
      await store.addToDictionaryHistory('食？？',
          searchWithWildcards: true, maximum: 10);
      await store.addToDictionaryHistory('猫',
          searchWithWildcards: false, maximum: 10);
      expect(history(), [('食？？', true), ('猫', false)]);

      await store.addToDictionaryHistory('食？？',
          searchWithWildcards: false, maximum: 10);
      expect(history(), [('猫', false), ('食？？', false)]);
    });
  });
}
