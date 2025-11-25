import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentEntity {
  final String id;
  final String userId;
  final String userEmail; // Joined from profiles
  final String deviceId;
  final String deviceAlias; // Joined from devices
  final String status;

  const AssignmentEntity({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.deviceId,
    required this.deviceAlias,
    required this.status,
  });

  factory AssignmentEntity.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>? ?? {};
    final device = map['devices'] as Map<String, dynamic>? ?? {};
    
    return AssignmentEntity(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userEmail: profile['email'] as String? ?? 'Unknown',
      deviceId: map['device_id'] as String,
      deviceAlias: device['alias'] as String? ?? 'Unknown',
      status: map['status'] as String,
    );
  }
}

class AdminRepository {
  final SupabaseClient client;

  AdminRepository(this.client);

  // Listar todas las asignaciones (con joins)
  Future<List<AssignmentEntity>> getAllAssignments() async {
    final response = await client
        .from('user_devices')
        .select('*, profiles(email), devices(alias)')
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((e) => AssignmentEntity.fromMap(e))
        .toList();
  }

  // Crear asignación
  Future<void> createAssignment({
    required String userId,
    required String deviceId,
  }) async {
    await client.from('user_devices').insert({
      'user_id': userId,
      'device_id': deviceId,
      'status': 'active',
    });
  }

  // Borrar asignación (Revocar acceso)
  Future<void> deleteAssignment(String id) async {
    await client.from('user_devices').delete().eq('id', id);
  }
  
  // Obtener lista de todos los dispositivos (para el selector)
  Future<List<Map<String, dynamic>>> getAvailableDevices() async {
    final response = await client
        .from('devices')
        .select('id, alias, type')
        .order('alias');
    return List<Map<String, dynamic>>.from(response);
  }
}
