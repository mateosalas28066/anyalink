// lib/presentation/providers/device_list_providers.dart
// Comentario (ES): Providers para lista de dispositivos + toggle por id.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anyalink_1/core/env.dart';
import 'package:anyalink_1/infrastructure/supabase/device_repo.dart';
import 'package:anyalink_1/presentation/providers/device_providers.dart'
    show deviceRepoProvider;

// Stream lista de dispositivos
final devicesListProvider = StreamProvider<List<DeviceEntity>>((ref) {
  final repo = ref.watch(deviceRepoProvider);
  if (Env.useRealtime) {
    return repo.watchAll();
  }
  if (repo is DeviceRepositorySupabase) {
    return repo.pollAll();
  }
  return repo.watchAll();
});

// Acción: toggle por id (lee estado actual del snapshot)
final toggleByIdProvider = FutureProvider.family<void, String>((ref, id) async {
  final repo = ref.read(deviceRepoProvider);
  final snapshot = ref.read(devicesListProvider).maybeWhen(
        data: (value) => value,
        orElse: () => const <DeviceEntity>[],
      );
  final device = snapshot.firstWhere(
    (d) => d.id == id,
    orElse: () => throw StateError('Device id $id not found in snapshot'),
  );
  await repo.setStateById(id, !device.state);
});

class OptimisticOverridesNotifier extends Notifier<Map<String, bool>> {
  final _timers = <String, Timer>{};

  @override
  Map<String, bool> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return <String, bool>{};
  }

  void set(String id, bool value) {
    _cancelTimer(id);
    state = {...state, id: value};
  }

  void remove(String id) {
    final next = {...state};
    if (next.remove(id) != null) {
      state = next;
    }
    _cancelTimer(id);
  }

  void scheduleRemove(String id, Duration delay) {
    _cancelTimer(id);
    _timers[id] = Timer(delay, () => remove(id));
  }

  void _cancelTimer(String id) {
    _timers.remove(id)?.cancel();
  }
}

// Comentario (ES): Overrides optimistas por id -> bool (estado temporal de UI).
final optimisticOverridesProvider = NotifierProvider<
    OptimisticOverridesNotifier,
    Map<String, bool>>(OptimisticOverridesNotifier.new);
