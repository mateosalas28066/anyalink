import 'package:supabase_flutter/supabase_flutter.dart';

class RequestEntity {
  final String id;
  final String userId;
  final String? userEmail; // New field
  final String? desiredType;
  final String? comment;
  final String? targetDeviceId;
  final String status;
  final DateTime createdAt;

  const RequestEntity({
    required this.id,
    required this.userId,
    this.userEmail,
    this.desiredType,
    this.comment,
    this.targetDeviceId,
    required this.status,
    required this.createdAt,
  });

  factory RequestEntity.fromMap(Map<String, dynamic> map) {
    // Extract email from joined profiles table if available
    String? email;
    if (map['profiles'] != null && map['profiles'] is Map) {
      email = map['profiles']['email'] as String?;
    }

    return RequestEntity(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userEmail: email,
      desiredType: map['desired_type'] as String?,
      comment: map['comment'] as String?,
      targetDeviceId: map['target_device_id'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}

class RequestRepository {
  final SupabaseClient client;

  RequestRepository(this.client);

  // Crear una solicitud
  Future<void> createRequest({
    required String userId,
    String? desiredType,
    String? comment,
    String? targetDeviceId,
  }) async {
    await client.from('device_requests').insert({
      'user_id': userId,
      'desired_type': desiredType,
      'comment': comment,
      'target_device_id': targetDeviceId,
      'status': 'pending',
    });
  }

  // Obtener opciones de dispositivos (RPC seguro)
  Future<List<Map<String, dynamic>>> getDeviceOptions() async {
    final response = await client.rpc('get_device_options');
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Listar solicitudes (para Admin)
  Future<List<RequestEntity>> getAllRequests() async {
    final response = await client
        .from('device_requests')
        .select('*, profiles(email)') // Join with profiles to get email
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((e) => RequestEntity.fromMap(e))
        .toList();
  }

  // Actualizar estado (Aceptar/Rechazar)
  Future<void> updateStatus(String id, String newStatus) async {
    await client.from('device_requests').update({
      'status': newStatus,
    }).eq('id', id);
  }
}
