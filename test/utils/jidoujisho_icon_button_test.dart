import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/utils.dart';

void main() {
  testWidgets('an icon button draws no border, even in e-ink', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.eink(),
        home: const Material(
          child: JidoujishoIconButton(icon: Icons.copy, tooltip: 'Copy'),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(JidoujishoIconButton),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });
}
