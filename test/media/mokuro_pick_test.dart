import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/media.dart';

void main() {
  /// A picked file named [name], copied to `/c/[name]`.
  ({String name, String? path}) f(String name) =>
      (name: name, path: '/c/$name');

  Matcher picks(String archivePath, String? ocrPath) => isA<MokuroPick>()
      .having((pick) => pick.archivePath, 'archivePath', archivePath)
      .having((pick) => pick.ocrPath, 'ocrPath', ocrPath);

  group('mokuroPickOf', () {
    test('an archive alone', () {
      expect(mokuroPickOf([f('v.cbz')]), picks('/c/v.cbz', null));
    });

    test('a zip archive alone', () {
      expect(mokuroPickOf([f('v.zip')]), picks('/c/v.zip', null));
    });

    test('an archive and a .mokuro, either order, any names', () {
      expect(mokuroPickOf([f('a.mokuro'), f('b.zip')]),
          picks('/c/b.zip', '/c/a.mokuro'));
      expect(mokuroPickOf([f('b.cbz'), f('a.mokuro')]),
          picks('/c/b.cbz', '/c/a.mokuro'));
    });

    test('upper-case extensions', () {
      expect(mokuroPickOf([f('V.CBZ'), f('V.Mokuro')]),
          picks('/c/V.CBZ', '/c/V.Mokuro'));
    });

    test('refuses a .mokuro alone', () {
      expect(mokuroPickOf([f('v.mokuro')]), isNull);
    });

    test('refuses two archives', () {
      expect(mokuroPickOf([f('a.cbz'), f('b.zip')]), isNull);
    });

    test('refuses two .mokuro files with an archive', () {
      expect(mokuroPickOf([f('v.cbz'), f('a.mokuro'), f('b.mokuro')]),
          isNull);
    });

    test('refuses another file', () {
      expect(mokuroPickOf([f('v.cbz'), f('notes.txt')]), isNull);
    });

    test('refuses more than two files', () {
      expect(mokuroPickOf([f('v.cbz'), f('v.mokuro'), f('w.cbz')]), isNull);
    });

    test('refuses nothing picked', () {
      expect(mokuroPickOf([]), isNull);
    });

    test('refuses a file without a local path', () {
      expect(mokuroPickOf([(name: 'v.cbz', path: null)]), isNull);
    });
  });
}
