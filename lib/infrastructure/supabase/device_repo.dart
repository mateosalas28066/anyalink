// lib/infrastructure/supabase/device_repo.dart
// Comentario (ES): Repositorio para 'devices' en Supabase (por alias o lista completa).

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceEntity {
  final String id;
  final String alias;
  final String? type; // e.g., 'light'
  final bool state;

  const DeviceEntity({
    required this.id,
    required this.alias,
    required this.state,
    this.type,
  });

  factory DeviceEntity.fromMap(Map<String, dynamic> map) {
    return DeviceEntity(
      id: map['id'] as String,
      alias: map['alias'] as String,
      type: map['type'] as String?,
      state: (map['state'] as bool?) ?? false,
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
        .select('id, alias, type, state')
        .eq('alias', alias)
        .limit(1);
    if (rows.isEmpty) return null;
    return DeviceEntity.fromMap(_normalizeRow(rows.first));
  }

  @override
  Future<List<DeviceEntity>> getAll() async {
    final rows = await client
        .from('devices')
        .select('id, alias, type, state')
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
