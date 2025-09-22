// lib/domain/usecases/set_device_state.dart
// Comentario (ES): Cambia On/Off del dispositivo por id.
import '../repositories/devices_repository.dart';

class SetDeviceState {
  final DevicesRepository repo;
  SetDeviceState(this.repo);

  Future<void> call({required String id, required bool state}) {
    return repo.setDeviceState(id: id, state: state);
  }
}
