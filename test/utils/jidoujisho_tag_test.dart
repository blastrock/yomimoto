import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/utils.dart';

Future<void> pumpTag(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Material(
        child: Center(
          child: JidoujishoTag(
            text: 'JPDB',
            trailingText: '123, 888ka',
            backgroundColor: Colors.blue,
          ),
        ),
      ),
    ),
  );
}

Color? textColour(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

Color? boxColour(WidgetTester tester, String text) => tester
    .widget<Container>(
      find.ancestor(of: find.text(text), matching: find.byType(Container)).first,
    )
    .color;

void main() {
  testWidgets('e-ink: black chip, inverted nested chip', (tester) async {
    await pumpTag(tester, AppThemes.eink());
    expect(textColour(tester, 'JPDB'), Colors.white);
    expect(boxColour(tester, 'JPDB'), Colors.black);
    expect(textColour(tester, '123, 888ka'), Colors.black);
    expect(boxColour(tester, '123, 888ka'), Colors.white);
  });

  testWidgets('light: keeps the tag colour', (tester) async {
    await pumpTag(tester, AppThemes.light());
    expect(textColour(tester, 'JPDB'), Colors.white);
    expect(boxColour(tester, 'JPDB'), Colors.blue);
    expect(textColour(tester, '123, 888ka'), Colors.white);
    expect(boxColour(tester, '123, 888ka'), const Color(0xFFEF5350));
  });
}
