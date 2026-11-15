import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';

import 'generated/schema.dart';

void main() {
  test('the database the app creates matches the version 3 snapshot',
      () async {
    SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    AppDatabase db = AppDatabase(await verifier.startAt(3));
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 3);
  });

  test('upgrading from version 1 drops mokuro catalogs and old volumes',
      () async {
    SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    InitializedSchema schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute('''
      INSERT INTO media_item (id, media_source_identifier, media_identifier,
        title, position, duration, can_delete, can_edit, last_opened_at)
      VALUES (1, 'reader_mokuro', 'file:///a.html', 'old', 0, 1, 1, 1, 0),
             (2, 'reader_ttu', 'b.html?id=1', 'book', 0, 1, 0, 1, 0);
      INSERT INTO stash_item (media_item_id, term, reading, definitions,
        sentence, word_start, word_length, position, date_added)
      VALUES (1, '猫', 'ねこ', '[]', '猫', 0, 1, 0, 0),
             (2, '犬', 'いぬ', '[]', '犬', 0, 1, 0, 0);
      INSERT INTO mokuro_catalog (name, url, "order") VALUES ('c', 'u', 0);
      INSERT INTO preference (key, value) VALUES
        ('reader_mokuro/use_dark_theme', 'true'),
        ('reader_mokuro/extend_page_beyond_navbar', 'true'),
        ('reader_mokuro/highlight_on_tap', 'false');
    ''');
    AppDatabase db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 3);

    expect(await db.select(db.mediaItems).map((r) => r.id).get(), [2]);
    expect(await db.select(db.stashItems).map((r) => r.term).get(), ['犬']);
    expect(await db.select(db.preferenceEntries).map((r) => r.key).get(),
        ['reader_mokuro/highlight_on_tap']);
  });

  test('upgrading from version 2 removes the text segmentation enhancement',
      () async {
    SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    InitializedSchema schema = await verifier.schemaAt(2);
    schema.rawDatabase.execute('''
      INSERT INTO anki_mapping (id, label, model, "order", export_field_keys,
        creator_field_keys, creator_collapsed_field_keys, tags, enhancements)
      VALUES (1, 'a', 'm', 0, '[]', '[]', '[]', '[]',
        '{"sentence":{"0":"clear_field","1":"text_segmentation",' ||
        '"2":"sentence_picker"},"notes":{"-1":"text_segmentation"},' ||
        '"image":{"-1":"bing_images"}}'),
        (2, 'b', 'm', 1, '[]', '[]', '[]', '[]', '{}');
    ''');
    AppDatabase db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 3);

    expect(await db.select(db.ankiMappings).map((r) => r.enhancements).get(), [
      {
        'sentence': {0: 'clear_field', 2: 'sentence_picker'},
        'notes': <int, String>{},
        'image': {-1: 'bing_images'},
      },
      <String, Map<int, String>>{},
    ]);
  });
}
