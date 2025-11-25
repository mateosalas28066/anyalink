import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineEntity {
  final String id;
  final String deviceId;
  final String actionType;
  final String actionPayload;
  final int intervalSeconds;
  final bool enabled;
  final DateTime? lastRunAt;
  final DateTime? expiresAt;

  const RoutineEntity({
    required this.id,
    required this.deviceId,
    required this.actionType,
    required this.actionPayload,
    required this.intervalSeconds,
    required this.enabled,
    this.lastRunAt,
    this.expiresAt,
  });

  factory RoutineEntity.fromMap(Map<String, dynamic> map) {
    return RoutineEntity(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      actionType: map['action_type'] as String,
      actionPayload: map['action_payload'] as String,
      intervalSeconds: map['interval_seconds'] as int,
      enabled: map['enabled'] as bool,
      lastRunAt: map['last_run_at'] != null ? DateTime.parse(map['last_run_at']) : null,
      expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
    );
  }
}

class RoutinesRepository {
  final SupabaseClient _client;

  RoutinesRepository(this._client);

  Future<List<RoutineEntity>> getRoutinesForDevice(String deviceId) async {
    final response = await _client
        .from('routines')
        .select()
        .eq('device_id', deviceId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => RoutineEntity.fromMap(e)).toList();
  }

  Future<List<RoutineEntity>> getUserRoutines() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _client
        .from('routines')
        .select('*, devices(alias)') // Join to get device alias if needed
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((e) => RoutineEntity.fromMap(e)).toList();
  }

  Future<void> createRoutine({
    required String deviceId,
    required String actionType,
    required String actionPayload,
    required int intervalSeconds,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('routines').insert({
      'user_id': user.id,
      'device_id': deviceId,
      'action_type': actionType,
      'action_payload': actionPayload,
      'interval_seconds': intervalSeconds,
      'enabled': true,
      // Auto-expire in 1 hour for demo purposes
      'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    });
  }

  Future<void> toggleRoutine(String id, bool enabled) async {
    await _client.from('routines').update({'enabled': enabled}).eq('id', id);
  }

  Future<void> deleteRoutine(String id) async {
    await _client.from('routines').delete().eq('id', id);
  }
}
