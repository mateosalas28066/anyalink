import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../infrastructure/supabase/routines_repo.dart';

final routinesRepoProvider = Provider<RoutinesRepository>((ref) {
  return RoutinesRepository(Supabase.instance.client);
});

// Fetch routines for a specific device
final deviceRoutinesProvider = FutureProvider.family<List<RoutineEntity>, String>((ref, deviceId) async {
  final repo = ref.watch(routinesRepoProvider);
  return repo.getRoutinesForDevice(deviceId);
});

// Fetch all routines for the current user
final userRoutinesProvider = FutureProvider<List<RoutineEntity>>((ref) async {
  final repo = ref.watch(routinesRepoProvider);
  return repo.getUserRoutines();
});
