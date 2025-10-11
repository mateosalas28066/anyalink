// lib/presentation/providers/device_providers.dart
// Comentario (ES): Providers reales (Supabase) para Lampara.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../infrastructure/supabase/device_repo.dart';

// Cliente Supabase seguro (lazy)
final supabaseClientProvider =
    Provider<SupabaseClient>((_) => Supabase.instance.client);

// Repo
final deviceRepoProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepositorySupabase(ref.watch(supabaseClientProvider)),
);

// Estado actual único (fetch)
final deviceOnceProvider = FutureProvider<DeviceEntity?>((ref) async {
  final repo = ref.watch(deviceRepoProvider);
  return repo.getByAlias(Env.lightAlias);
});

// Stream de estado ON/OFF (Realtime puro)
final deviceStateStreamProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(deviceRepoProvider);
  return repo.watchStateByAlias(Env.lightAlias);
});

// Acción: toggle (lee el último valor conocido y escribe lo opuesto)
final toggleDeviceProvider = FutureProvider.autoDispose<void>((ref) async {
  final repo = ref.read(deviceRepoProvider);
  final asyncState = ref.read(deviceStateProvider);
  final current = asyncState.maybeWhen(
    data: (v) => v,
    orElse: () => null,
  );
  final value =
      current ?? (await repo.getByAlias(Env.lightAlias))?.state ?? false;
  await repo.setStateByAlias(Env.lightAlias, !value);
});

// Comentario (ES): Provider unificado con fallback a polling.
final deviceStateProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(deviceRepoProvider);
  if (Env.useRealtime) {

    return repo.watchStateByAlias(Env.lightAlias);

  }

  if (repo is DeviceRepositorySupabase) {

    return repo.pollStateByAlias(Env.lightAlias);

  }

  return repo.watchStateByAlias(Env.lightAlias);

});
