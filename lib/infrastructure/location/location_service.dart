// lib/infrastructure/location/location_service.dart
// Comentario (ES): Servicio simple para obtener la ubicacion una vez con permisos.

import 'package:geolocator/geolocator.dart';

class LocationPoint {
  final double lat;
  final double lon;
  const LocationPoint(this.lat, this.lon);
}

class LocationService {
  Future<bool> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      return false;
    }
    return true;
  }

  Future<LocationPoint?> getOnce() async {
    if (!await _ensurePermission()) return null;
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low, // Comentario (ES): Precision baja es suficiente para clima.
    );
    return LocationPoint(pos.latitude, pos.longitude);
  }
}
