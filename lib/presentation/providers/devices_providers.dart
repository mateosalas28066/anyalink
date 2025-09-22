// lib/presentation/providers/devices_providers.dart
// Comentario (ES): Providers para cliente, repositorio, casos de uso y stream del dispositivo.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../data/repositories/devices_repository_impl.dart';
import '../../domain/entities/device.dart';
import '../../domain/usecases/set_device_state.dart';
import '../../domain/usecases/watch_device_state.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final devicesRepositoryProvider = Provider<DevicesRepositoryImpl>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DevicesRepositoryImpl(client);
});

final watchDeviceStateProvider = Provider<WatchDeviceState>((ref) {
  final repo = ref.watch(devicesRepositoryProvider);
  return WatchDeviceState(repo);
});

final setDeviceStateProvider = Provider<SetDeviceState>((ref) {
  final repo = ref.watch(devicesRepositoryProvider);
  return SetDeviceState(repo);
});

final lightDeviceStreamProvider = StreamProvider<Device?>((ref) {
  final watch = ref.watch(watchDeviceStateProvider);
  return watch(Env.lightAlias); // 'Luz Dormitorio'
});
