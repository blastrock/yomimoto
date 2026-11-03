import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/media.dart';

void main() {
  group('TtuReadyEvent', () {
    test('is compatible with the same protocol version', () {
      TtuReadyEvent event = TtuReadyEvent.fromJson({
        'protocolVersion': TtuBridge.protocolVersion,
        'route': '/b.html',
      });

      expect(TtuBridge.protocolVersion, 5);
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

  group('TtuBridge.parseContext', () {
    test('parses a context result', () {
      expect(TtuBridge.parseContext(['a', 'b']), ['a', 'b']);
      expect(TtuBridge.parseContext(null), isEmpty);
      expect(TtuBridge.parseContext(['a', 1]), ['a']);
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
