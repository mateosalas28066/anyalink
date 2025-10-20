// lib/presentation/providers/location_providers.dart
// Comentario (ES): Provider para obtener la ubicacion una vez y exponerla.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/location/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Comentario (ES): FutureProvider que intenta ubicacion una vez (puede regresar null sin permisos).
final deviceLocationOnceProvider =
    FutureProvider.autoDispose<LocationPoint?>((ref) async {
  final svc = ref.read(locationServiceProvider);
  return svc.getOnce();
});
