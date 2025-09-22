// lib/domain/usecases/watch_device_state.dart
// Comentario (ES): Observa el estado del dispositivo por alias (stream).
import '../entities/device.dart';
import '../repositories/devices_repository.dart';

class WatchDeviceState {
  final DevicesRepository repo;
  WatchDeviceState(this.repo);

  Stream<Device?> call(String alias) => repo.watchDeviceByAlias(alias);
}
