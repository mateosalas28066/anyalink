// lib/data/repositories/devices_repository_impl.dart
// Comentario (ES): Implementa el repositorio usando el Data Source de Supabase.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/device.dart';
import '../../domain/repositories/devices_repository.dart';
import '../datasources/supabase_remote_data_source.dart';

class DevicesRepositoryImpl implements DevicesRepository {
  final SupabaseRemoteDataSource remote;

  DevicesRepositoryImpl(SupabaseClient client)
      : remote = SupabaseRemoteDataSource(client);

  @override
  Future<Device?> getDeviceByAlias(String alias) async {
    final row = await remote.getDeviceByAlias(alias);
    if (row == null) return null;
    return _map(row);
  }

  @override
  Future<void> setDeviceState({required String id, required bool state}) {
    return remote.updateDeviceState(id: id, state: state);
  }

  @override
  Stream<Device?> watchDeviceByAlias(String alias) async* {
    // Comentario (ES): 1) Trae una vez por alias para obtener 'id'
    final first = await remote.getDeviceByAlias(alias);
    if (first == null) {
      yield null;
      return;
    }
    yield _map(first);

    // Comentario (ES): 2) Abre stream por 'id' (realtime)
    final id = first['id'] as String;
    yield* remote.streamDeviceById(id).map((rows) {
      if (rows.isEmpty) return null;
      return _map(rows.first);
    });
  }

  Device _map(Map<String, dynamic> row) {
    return Device(
      id: row['id'] as String,
      alias: row['alias'] as String,
      type: row['type'] as String,
      state: row['state'] as bool,
    );
  }
}
