import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

Future<void> pumpBorder(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Material(
        child: QuickActionBorder(child: SizedBox.square(dimension: 40)),
      ),
    ),
  );
}

BoxBorder? drawnBorder(WidgetTester tester) {
  DecoratedBox box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(QuickActionBorder),
      matching: find.byType(DecoratedBox),
    ),
  );

  return (box.decoration as BoxDecoration).border;
}

void main() {
  testWidgets('a quick action has the e-ink border', (tester) async {
    await pumpBorder(tester, AppThemes.eink());
    expect(drawnBorder(tester), Border.fromBorderSide(AppStyle.eink.border));
  });

  testWidgets('a quick action has no border in light and dark',
      (tester) async {
    for (ThemeData theme in [AppThemes.light(), AppThemes.dark()]) {
      await pumpBorder(tester, theme);
      expect(drawnBorder(tester), const Border.fromBorderSide(BorderSide.none));
    }
  });
}
