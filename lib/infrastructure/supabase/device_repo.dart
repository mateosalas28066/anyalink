// lib/infrastructure/supabase/device_repo.dart
// Comentario (ES): Repositorio para 'devices' en Supabase (por alias o lista completa).

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceEntity {
  final String id;
  final String alias;
  final String? type; // e.g., 'light'
  final bool state;
  final bool online;
  final DateTime? lastSeen;

  const DeviceEntity({
    required this.id,
    required this.alias,
    required this.state,
    this.type,
    this.online = false,
    this.lastSeen,
  });

  factory DeviceEntity.fromMap(Map<String, dynamic> map) {
    return DeviceEntity(
      id: map['id'] as String,
      alias: map['alias'] as String,
      type: map['type'] as String?,
      state: (map['state'] as bool?) ?? false,
      online: (map['online'] as bool?) ?? false,
      lastSeen: map['last_seen'] != null
          ? DateTime.parse(map['last_seen'] as String)
          : null,
    );
  }
}

class DeviceMetrics {
  final double weightG;
  final double temperatureC;
  final double humidityPct;
  final DateTime updatedAt;

  const DeviceMetrics({
    required this.weightG,
    required this.temperatureC,
    required this.humidityPct,
    required this.updatedAt,
  });

  factory DeviceMetrics.fromMap(Map<String, dynamic> map) {
    return DeviceMetrics(
      weightG: (map['weight_g'] as num?)?.toDouble() ?? 0.0,
      temperatureC: (map['temperature_c'] as num?)?.toDouble() ?? 0.0,
      humidityPct: (map['humidity_pct'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}

abstract class DeviceRepository {
  Future<DeviceEntity?> getByAlias(String alias);
  Future<List<DeviceEntity>> getAll();
  Future<void> setStateByAlias(String alias, bool newState);
  Future<void> setStateById(String id, bool newState);
  Stream<bool> watchStateByAlias(String alias);
  Stream<List<DeviceEntity>> watchAll();
  Future<void> sendCommand(String deviceId, String action, Map<String, dynamic> payload);
  Stream<DeviceMetrics?> watchMetrics(String deviceId);
}

class DeviceRepositorySupabase implements DeviceRepository {
  DeviceRepositorySupabase(this.client);

  final SupabaseClient client;

  Map<String, dynamic> _normalizeRow(dynamic row) {
    if (row is Map<String, dynamic>) {
      return Map<String, dynamic>.from(row);
    }
    return Map<String, dynamic>.from(row as Map);
  }

  @override
  Future<DeviceEntity?> getByAlias(String alias) async {
    final rows = await client
        .from('devices')
        .select('id, alias, type, state, online, last_seen')
        .eq('alias', alias)
        .limit(1);
    if (rows.isEmpty) return null;
    return DeviceEntity.fromMap(_normalizeRow(rows.first));
  }

  @override
  Future<List<DeviceEntity>> getAll() async {
    final rows = await client
        .from('devices')
        .select('id, alias, type, state, online, last_seen')
        .order('alias', ascending: true);
    if (rows.isEmpty) return const [];
    return (rows as List)
        .map((row) => DeviceEntity.fromMap(_normalizeRow(row)))
        .toList(growable: false);
  }

  @override
  Future<void> setStateByAlias(String alias, bool newState) async {
    final response = await client
        .from('devices')
        .update({
          'state': newState,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('alias', alias);
    // ignore: avoid_print
    print('[DeviceRepo] update alias=$alias -> $newState resp=$response');
  }

  @override
  Future<void> setStateById(String id, bool newState) async {
    final response = await client
        .from('devices')
        .update({
          'state': newState,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
    // ignore: avoid_print
    print('[DeviceRepo] update id=$id -> $newState resp=$response');
  }

  @override
  Stream<bool> watchStateByAlias(String alias) async* {
    final first = await getByAlias(alias);
    if (first != null) yield first.state;

    final controller = StreamController<bool>();

    final channel = client.channel('public:devices-state-$alias')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'devices',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'alias',
          value: alias,
        ),
        callback: (payload) {
          final newRow = payload.newRecord;
          if (newRow.containsKey('state')) {
            controller.add((newRow['state'] as bool?) ?? false);
          }
        },
      )
      ..subscribe();

    controller.onCancel = () async {
      await client.removeChannel(channel);
    };

    yield* controller.stream;
  }

  @override
  Stream<List<DeviceEntity>> watchAll() {
    final controller = StreamController<List<DeviceEntity>>();

    getAll().then(controller.add).catchError((Object err, StackTrace st) {
      // ignore: avoid_print
      print('[DeviceRepo] initial watchAll error: $err');
    });

    final channel = client.channel('public:devices-list')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'devices',
        callback: (_) async {
          try {
            final items = await getAll();
            controller.add(items);
          } catch (e) {
            // ignore: avoid_print
            print('[DeviceRepo] watchAll refresh error: $e');
          }
        },
      )
      ..subscribe();

    controller.onCancel = () async {
      await client.removeChannel(channel);
    };

    return controller.stream;
  }

  @override
  Future<void> sendCommand(
    String deviceId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    await client.from('device_commands').insert({
      'device_id': deviceId,
      'action': action,
      'payload': payload,
      'status': 'pending',
    });
  }

  @override
  Stream<DeviceMetrics?> watchMetrics(String deviceId) async* {
    final rows = await client
        .from('device_metrics')
        .select()
        .eq('device_id', deviceId)
        .limit(1);
    if (rows.isNotEmpty) {
      yield DeviceMetrics.fromMap(_normalizeRow(rows.first));
    } else {
      yield null;
    }

    final controller = StreamController<DeviceMetrics?>();

    final channel = client.channel('public:device_metrics-$deviceId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'device_metrics',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'device_id',
          value: deviceId,
        ),
        callback: (payload) {
          final newRow = payload.newRecord;
          if (newRow.isNotEmpty) {
            controller.add(DeviceMetrics.fromMap(Map<String, dynamic>.from(newRow)));
          }
        },
      )
      ..subscribe();

    controller.onCancel = () async {
      await client.removeChannel(channel);
    };

    yield* controller.stream;
  }
}

// Comentario (ES): Fallbacks de polling si Realtime no está disponible.
extension DeviceRepoPolling on DeviceRepositorySupabase {
  Stream<bool> pollStateByAlias(
    String alias, {
    Duration interval = const Duration(milliseconds: 800),
  }) async* {
    bool? last;
    while (true) {
      final device = await getByAlias(alias);
      final value = device?.state ?? false;
      if (last == null || value != last) {
        yield value;
        last = value;
      }
      await Future.delayed(interval);
    }
  }

  Stream<List<DeviceEntity>> pollAll({
    Duration interval = const Duration(milliseconds: 900),
  }) async* {
    List<DeviceEntity>? last;
    while (true) {
      final items = await getAll();
      final changed = last == null ||
          items.length != last.length ||
          _listStateChanged(last, items);
      if (changed) {
        yield items;
        last = items;
      }
      await Future.delayed(interval);
    }
  }

  bool _listStateChanged(
    List<DeviceEntity> previous,
    List<DeviceEntity> current,
  ) {
    final len = current.length;
    for (var i = 0; i < len; i++) {
      final curr = current[i];
      final prev = previous.length > i ? previous[i] : null;
      if (prev == null ||
          prev.id != curr.id ||
          prev.state != curr.state ||
          prev.alias != curr.alias) {
        return true;
      }
    }
    return false;
  }
}
