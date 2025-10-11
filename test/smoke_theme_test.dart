// test/smoke_theme_test.dart
// Comentario (ES): Verifica que AnyaLinkApp monta y no crashea.

import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('AnyaLinkApp smoke test', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    // Si llegó aquí sin excepciones, OK.
  });
}
