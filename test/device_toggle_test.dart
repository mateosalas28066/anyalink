import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anyalink_1/presentation/widgets/device_tile.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('El toggle cambia el estado (mock)', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Apagada'), findsWidgets);

    final lamparaTile = find.widgetWithText(DeviceTile, 'Lampara');
    final lamparaSwitch = find.descendant(
      of: lamparaTile,
      matching: find.byType(Switch),
    );

    await tester.tap(lamparaSwitch.first);
    await tester.pumpAndSettle();

    expect(find.text('Encendida'), findsWidgets);
  });
}
