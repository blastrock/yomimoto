import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/media.dart';

void main() {
  group('TtuReadyEvent', () {
    test('is compatible with the same protocol version', () {
      TtuReadyEvent event = TtuReadyEvent.fromJson({
        'protocolVersion': TtuBridge.protocolVersion,
        'route': '/b.html',
      });

      expect(TtuBridge.protocolVersion, 3);
      expect(event.isCompatible, isTrue);
      expect(event.route, '/b.html');
    });

    test('is incompatible with any other protocol version', () {
      for (int version in [
        TtuBridge.protocolVersion - 1,
        TtuBridge.protocolVersion + 1,
      ]) {
        TtuReadyEvent event = TtuReadyEvent.fromJson({
          'protocolVersion': version,
          'route': '/b.html',
        });

        expect(event.isCompatible, isFalse, reason: 'version $version');
      }
    });

    test('defaults a missing route to empty', () {
      TtuReadyEvent event = TtuReadyEvent.fromJson({'protocolVersion': 3});

      expect(event.route, '');
    });
  });

  group('TtuTapEvent', () {
    test('reads a full payload', () {
      TtuTapEvent event = TtuTapEvent.fromJson({
        'type': 'tap',
        'text': '彼は漢字を書いた。',
        'offset': 2,
        'x': 120,
        'y': 340,
        'position': 425,
      });

      expect(event.text, '彼は漢字を書いた。');
      expect(event.offset, 2);
      expect(event.x, 120);
      expect(event.y, 340);
      expect(event.position, 425);
      expect(event.isDismiss, isFalse);
    });

    test('defaults missing text, offset and position', () {
      TtuTapEvent event = TtuTapEvent.fromJson({'x': 1, 'y': 2});

      expect(event.text, '');
      expect(event.offset, -1);
      expect(event.position, -1);
    });

    test('rounds fractional coordinates', () {
      TtuTapEvent event = TtuTapEvent.fromJson({
        'text': 'あ',
        'offset': 0,
        'x': 10.4,
        'y': 20.5,
      });

      expect(event.x, 10);
      expect(event.y, 21);
    });

    test('is a dismissal without an offset or without text', () {
      TtuTapEvent noOffset = TtuTapEvent.fromJson({
        'text': 'あ',
        'offset': -1,
        'x': 0,
        'y': 0,
      });
      TtuTapEvent noText = TtuTapEvent.fromJson({
        'text': '',
        'offset': 0,
        'x': 0,
        'y': 0,
      });

      expect(noOffset.isDismiss, isTrue);
      expect(noText.isDismiss, isTrue);
    });
  });

  group('TtuThemeEvent', () {
    test('reads colours', () {
      TtuThemeEvent event = TtuThemeEvent.fromJson({
        'backgroundColor': {'r': 255, 'g': 250, 'b': 240, 'a': 1},
        'fontColor': {'r': 0, 'g': 0, 'b': 0, 'a': 0.5},
      });

      expect(event.backgroundColor.toARGB32(), 0xFFFFFAF0);
      expect(event.fontColor.toARGB32(), 0x80000000);
    });

    test('defaults a missing alpha to opaque', () {
      TtuThemeEvent event = TtuThemeEvent.fromJson({
        'backgroundColor': {'r': 1, 'g': 2, 'b': 3},
        'fontColor': {'r': 4, 'g': 5, 'b': 6},
      });

      expect(event.backgroundColor.toARGB32(), 0xFF010203);
      expect(event.fontColor.toARGB32(), 0xFF040506);
    });

    test('rounds fractional components', () {
      TtuThemeEvent event = TtuThemeEvent.fromJson({
        'backgroundColor': {'r': 254.6, 'g': 0.4, 'b': 127.5},
        'fontColor': {'r': 0, 'g': 0, 'b': 0},
      });

      expect(event.backgroundColor.toARGB32(), 0xFFFF0080);
    });
  });

  group('TtuBook', () {
    test('reads id and title', () {
      TtuBook book = TtuBook.fromJson({'id': 7, 'title': '試験の本'});

      expect(book.id, 7);
      expect(book.title, '試験の本');
    });

    test('defaults a missing title to empty', () {
      expect(TtuBook.fromJson({'id': 7}).title, '');
    });
  });
}
