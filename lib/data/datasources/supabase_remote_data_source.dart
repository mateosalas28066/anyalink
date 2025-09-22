// lib/data/datasources/supabase_remote_data_source.dart
// Comentario (ES): Acceso crudo a Supabase (select/stream/update) para la tabla 'devices'.

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRemoteDataSource {
  final SupabaseClient client;

  // Comentario (ES): Nombre de la tabla (ya confirmaste que es 'devices').
  static const String tableDevices = 'devices';

  SupabaseRemoteDataSource(this.client);

  // Comentario (ES): Obtiene una fila por alias (útil para bootstrap).
  Future<Map<String, dynamic>?> getDeviceByAlias(String alias) async {
    final row = await client
        .from(tableDevices)
        .select()
        .eq('alias', alias)
        .limit(1)
        .maybeSingle();
    return row;
  }

  // Comentario (ES): Stream Realtime por PK 'id' (más fiable que por alias).
  Stream<List<Map<String, dynamic>>> streamDeviceById(String id) {
    return client
        .from(tableDevices)
        .stream(primaryKey: ['id'])
        .eq('id', id);
  }

  // Comentario (ES): Update del estado On/Off por id.
  Future<void> updateDeviceState({
    required String id,
    required bool state,
  }) async {
    await client
        .from(tableDevices)
        .update({
          'state': state,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
