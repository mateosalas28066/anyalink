// lib/domain/repositories/devices_repository.dart
// Comentario (ES): Contrato del repositorio; abstrae la fuente de datos (Supabase, etc).
import '../entities/device.dart';

abstract class DevicesRepository {
  // Stream del estado de un dispositivo por alias (realtime).
  Stream<Device?> watchDeviceByAlias(String alias);

  // Cambia el estado de un dispositivo (On/Off) por id.
  Future<void> setDeviceState({required String id, required bool state});

  // Obtiene una vez por alias (para bootstrap inicial).
  Future<Device?> getDeviceByAlias(String alias);
}
