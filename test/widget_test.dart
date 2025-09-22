// test/widget_test.dart
// Comentario (ES): Test neutro que no depende de Supabase ni de tu árbol real.
// Solo verifica que podemos renderizar un widget básico.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnyaLink placeholder smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Text('AnyaLink')),
    ));

    // Comentario (ES): Debe renderizar el texto 'AnyaLink'.
    expect(find.text('AnyaLink'), findsOneWidget);
  });
}
