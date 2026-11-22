import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/media.dart';

void main() {
  group('MokuroReadyEvent', () {
    test('is compatible with the same protocol version only', () {
      expect(MokuroBridge.protocolVersion, 3);
      expect(MokuroReadyEvent.fromJson({'protocolVersion': 3}).isCompatible,
          isTrue);
      expect(MokuroReadyEvent.fromJson({'protocolVersion': 2}).isCompatible,
          isFalse);
    });
  });

  group('MokuroTapEvent', () {
    test('reads a tap on a character', () {
      MokuroTapEvent event = MokuroTapEvent.fromJson({
        'type': 'tap',
        'text': 'あい',
        'offset': 1,
        'page': 3,
        'x': 10.6,
        'y': 20.2,
      });

      expect(event.text, 'あい');
      expect(event.offset, 1);
      expect(event.page, 3);
      expect(event.x, 11);
      expect(event.y, 20);
      expect(event.isDismiss, isFalse);
    });

    test('reads a dismiss', () {
      MokuroTapEvent event = MokuroTapEvent.fromJson({
        'type': 'tap',
        'text': '',
        'offset': -1,
        'page': -1,
        'x': 5,
        'y': 6,
      });

      expect(event.isDismiss, isTrue);
    });
  });

  group('MokuroPageEvent', () {
    test('reads the pages shown', () {
      MokuroPageEvent event =
          MokuroPageEvent.fromJson({'pages': [5, 6], 'count': 200});

      expect(event.pages, [5, 6]);
      expect(event.count, 200);
      expect(event.first, 5);
      expect(event.last, 6);
    });
  });
}
