import 'package:flutter_test/flutter_test.dart';

import 'package:anyalink_1/infrastructure/supabase/device_repo.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('Cuando llega un valor por el stream de metrics, se renderiza',
      (tester) async {
    final (:app, :repo) = buildFeederTestApp(online: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Emitir métricas desde el fake
    repo.emitMetrics(DeviceMetrics(
      weightG: 300.0,
      temperatureC: 22.5,
      humidityPct: 60.0,
      updatedAt: DateTime.now(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('300g'), findsOneWidget);
    expect(find.text('22.5°C'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
  });
}
