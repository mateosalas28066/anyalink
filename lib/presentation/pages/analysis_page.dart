import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/activity_logs_providers.dart';

class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activityLogsProvider),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No activity yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final dateFormat = DateFormat('MMM d, h:mm a');
              
              IconData icon;
              Color color;
              String actionText;

              if (log.actionType == 'state_change') {
                icon = log.actionValue == 'true' ? Icons.toggle_on : Icons.toggle_off;
                color = log.actionValue == 'true' ? Colors.green : Colors.grey;
                actionText = log.actionValue == 'true' ? 'Turned ON' : 'Turned OFF';
              } else {
                icon = Icons.message;
                color = Colors.blue;
                actionText = 'Message: "${log.actionValue}"';
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(
                    '${log.deviceAlias ?? log.deviceId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(actionText),
                      const SizedBox(height: 4),
                      Text(
                        'User: ${log.userEmail ?? "System"} • ${dateFormat.format(log.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
