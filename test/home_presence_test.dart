import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('Home muestra AnyaLink y Lampara', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('AnyaLink'), findsOneWidget);
    expect(find.text('Lampara'), findsOneWidget);
  });
}
