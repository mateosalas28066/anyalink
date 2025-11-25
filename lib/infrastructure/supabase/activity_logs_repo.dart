import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityLogEntity {
  final String id;
  final String? userId;
  final String deviceId;
  final String actionType;
  final String actionValue;
  final String source;
  final DateTime createdAt;
  final String? userEmail;
  final String? deviceAlias;

  const ActivityLogEntity({
    required this.id,
    this.userId,
    required this.deviceId,
    required this.actionType,
    required this.actionValue,
    required this.source,
    required this.createdAt,
    this.userEmail,
    this.deviceAlias,
  });

  factory ActivityLogEntity.fromMap(Map<String, dynamic> map) {
    return ActivityLogEntity(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      deviceId: map['device_id'] as String,
      actionType: map['action_type'] as String,
      actionValue: map['action_value'] as String,
      source: map['source'] as String,
      createdAt: DateTime.parse(map['created_at']),
      userEmail: map['profiles']?['email'] as String?,
      deviceAlias: map['devices']?['alias'] as String?,
    );
  }
}

class ActivityLogsRepository {
  final SupabaseClient _client;

  ActivityLogsRepository(this._client);

  Future<List<ActivityLogEntity>> getRecentLogs({int limit = 50}) async {
    final response = await _client
        .from('activity_logs')
        .select('*, profiles(email), devices(alias)')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => ActivityLogEntity.fromMap(e))
        .toList();
  }
}
