import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../infrastructure/supabase/activity_logs_repo.dart';

final activityLogsRepoProvider = Provider<ActivityLogsRepository>((ref) {
  return ActivityLogsRepository(Supabase.instance.client);
});

final activityLogsProvider = FutureProvider<List<ActivityLogEntity>>((ref) async {
  final repo = ref.watch(activityLogsRepoProvider);
  return repo.getRecentLogs(limit: 100);
});
