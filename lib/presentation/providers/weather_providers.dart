// lib/presentation/providers/weather_providers.dart
// Comentario (ES): Clima que se vuelve a construir cuando cambian coordenadas o se refresca.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../infrastructure/weather/weather_service.dart';
import 'location_providers.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

class _WeatherRefreshTrigger extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

// Disparador manual (boton de refresco)
final weatherRefreshTriggerProvider =
    NotifierProvider<_WeatherRefreshTrigger, int>(_WeatherRefreshTrigger.new);

final weatherNowStreamProvider =
    StreamProvider.autoDispose<WeatherNow>((ref) async* {
  final service = ref.watch(weatherServiceProvider);

  // ⬇️ Al "watch" de la ubicación, este provider se vuelve a crear cuando haya permisos/datos.
  final locAsync = ref.watch(deviceLocationOnceProvider);
  final coords = locAsync.asData?.value;

  // ⬇️ Si tocan el botón de refresh, forzamos reconstrucción también.
  ref.watch(weatherRefreshTriggerProvider);

  final double lat = coords?.lat ?? Env.weatherLatitude;
  final double lon = coords?.lon ?? Env.weatherLongitude;

  WeatherNow? lastOk;
  final controller = StreamController<WeatherNow>();

  Future<void> tick() async {
    try {
      final now = await service.fetchNow(lat: lat, lon: lon);
      lastOk = now;
      if (!controller.isClosed) controller.add(now);
    } catch (error, stackTrace) {
      // En error, emitimos el último valor válido; si no hay, mandamos error para que la UI lo muestre.
      if (lastOk != null && !controller.isClosed) {
        controller.add(lastOk!);
      } else if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }
  }

  // Primer fetch inmediato
  await tick();

  // Polling periódico
  final timer = Timer.periodic(
    Duration(seconds: Env.weatherPollSeconds),
    (_) => tick(),
  );

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  yield* controller.stream;
});
