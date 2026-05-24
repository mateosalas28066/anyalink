import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('Tap en Dispensar llama sendCommand con action dispense',
      (tester) async {
    final (:app, :repo) = buildFeederTestApp(online: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Dispensar'), findsOneWidget);
    await tester.tap(find.text('Dispensar'));
    await tester.pumpAndSettle();

    expect(repo.sentCommands.length, 1);
    expect(repo.sentCommands.first['action'], 'dispense');
    expect(repo.sentCommands.first['deviceId'], '1');
    expect(find.text('Comando enviado'), findsOneWidget);
  });
}
