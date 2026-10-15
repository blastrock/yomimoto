import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';

import 'generated/schema.dart';

void main() {
  test('the database the app creates matches the version 1 snapshot',
      () async {
    SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    AppDatabase db = AppDatabase(await verifier.startAt(1));
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });
}
