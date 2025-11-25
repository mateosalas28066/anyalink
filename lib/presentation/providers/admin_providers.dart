import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../infrastructure/supabase/admin_repo.dart';
import '../../infrastructure/supabase/request_repo.dart';

// Repositories
final adminRepoProvider = Provider((ref) {
  return AdminRepository(Supabase.instance.client);
});

final requestRepoProvider = Provider((ref) {
  return RequestRepository(Supabase.instance.client);
});

// Providers de datos (AutoDispose para refrescar al salir)
final adminRequestsProvider = FutureProvider.autoDispose<List<RequestEntity>>((ref) async {
  final repo = ref.watch(requestRepoProvider);
  return repo.getAllRequests();
});

final adminAssignmentsProvider = FutureProvider.autoDispose<List<AssignmentEntity>>((ref) async {
  final repo = ref.watch(adminRepoProvider);
  return repo.getAllAssignments();
});

final adminAvailableDevicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepoProvider);
  return repo.getAvailableDevices();
});
