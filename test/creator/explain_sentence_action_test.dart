import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/utils.dart';

void main() {
  test('can explain only a reader sentence', () {
    expect(
      ExplainSentenceAction.canExplain(kind: null, sentence: 'x'),
      isFalse,
    );
    expect(
      ExplainSentenceAction.canExplain(
          kind: ExplanationKind.novel, sentence: ' \n'),
      isFalse,
    );
    expect(
      ExplainSentenceAction.canExplain(
          kind: ExplanationKind.manga, sentence: '南雲桜子。'),
      isTrue,
    );
  });
}
