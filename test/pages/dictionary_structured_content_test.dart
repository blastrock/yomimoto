import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/pages.dart';

Future<void> pumpDefinition(WidgetTester tester, String html) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: Html(
          data: html,
          shrinkWrap: true,
          style: dictionaryHtmlStyle(
            textColor: Colors.green,
            linkColor: Colors.black,
            fontSize: FontSize(16),
            tableStyle: Style(),
          ),
        ),
      ),
    ),
  );
}

Iterable<TextSpan> textSpans(InlineSpan span) sync* {
  if (span is TextSpan) {
    yield span;
    for (InlineSpan child in span.children ?? const <InlineSpan>[]) {
      yield* textSpans(child);
    }
  }
}

TextStyle renderedStyle(WidgetTester tester, String text) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .expand((richText) => textSpans(richText.text))
      .firstWhere((span) => span.text == text)
      .style!;
}

void main() {
  for (String html in [
    '<a href="?query=語">語</a>',
    '<a href="?query=語"><span>語</span></a>',
    '<span><a href="?query=語"><span lang="ja"><span>語</span></span></a></span>',
    '<a>語</a>',
  ]) {
    testWidgets('a link is black and underlined: $html', (tester) async {
      await pumpDefinition(tester, html);
      expect(renderedStyle(tester, '語').decoration, TextDecoration.underline);
      expect(renderedStyle(tester, '語').color, Colors.black);
    });
  }

  testWidgets('other text is not underlined', (tester) async {
    await pumpDefinition(tester, '<span>語</span>');
    expect(
      renderedStyle(tester, '語').decoration,
      isNot(TextDecoration.underline),
    );
    expect(renderedStyle(tester, '語').color, Colors.green);
  });
}
