// lib/presentation/widgets/weather_header.dart
// Comentario (ES): Header estilo "Sunny, 24\u00B0C" + subtitulo con ubicacion.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../providers/location_providers.dart';
import '../providers/weather_providers.dart';

class WeatherHeader extends ConsumerWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNow = ref.watch(weatherNowStreamProvider);
    final locState = ref.watch(deviceLocationOnceProvider);

    final content = asyncNow.when(
      loading: _skeleton,
      error: (error, stackTrace) => Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Weather unavailable: $error',
              style: const TextStyle(fontSize: 14, color: Colors.redAccent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Retry weather',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(deviceLocationOnceProvider);
              ref.read(weatherRefreshTriggerProvider.notifier).bump();
            },
          ),
        ],
      ),
      data: (w) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _iconFor(w.conditionCode, isDay: w.isDay),
            color: Colors.amber.shade600,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${w.label}, ${w.displayTemperatureC.toStringAsFixed(0)}\u00B0C',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Refresh weather',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(deviceLocationOnceProvider);
              ref.read(weatherRefreshTriggerProvider.notifier).bump();
            },
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        content,
        const SizedBox(height: 4),
        locState.when(
          loading: () => Text(
            Env.weatherPlaceLabel,
            style: const TextStyle(color: Colors.black54),
          ),
          error: (err, stack) => Text(
            '${Env.weatherPlaceLabel} (default)',
            style: const TextStyle(color: Colors.black54),
          ),
          data: (loc) {
            final subtitle = loc != null
                ? 'Current location (${loc.lat.toStringAsFixed(2)}, ${loc.lon.toStringAsFixed(2)})'
                : '${Env.weatherPlaceLabel} (default)';
            return Text(
              subtitle,
              style: const TextStyle(color: Colors.black54),
            );
          },
        ),
      ],
    );
  }

  // Comentario (ES): Mapeo aproximado de iconos para codigos OpenWeather.
  IconData _iconFor(int code, {required bool isDay}) {
    if (code >= 200 && code < 300) return Icons.flash_on;
    if (code >= 300 && code < 400) return Icons.grain;
    if (code >= 500 && code < 600) return Icons.umbrella;
    if (code >= 600 && code < 700) return Icons.ac_unit;
    if (code >= 700 && code < 800) return Icons.blur_on;
    if (code == 800) return isDay ? Icons.wb_sunny : Icons.nights_stay;
    if (code >= 801 && code <= 804) return Icons.cloud;
    return Icons.wb_sunny_outlined;
  }

  Widget _skeleton() {
    const baseColor = Color(0xFFEAECEF);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 160,
          height: 20,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
