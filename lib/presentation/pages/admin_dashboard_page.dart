import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/supabase/admin_repo.dart';
import '../../infrastructure/supabase/request_repo.dart';
import '../providers/admin_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Assignments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestsTab(),
            _AssignmentsTab(),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  Future<void> _approve(BuildContext context, WidgetRef ref, RequestEntity req) async {
    String? deviceId;

    // 1. If user requested a specific device, use it directly (or confirm)
    if (req.targetDeviceId != null) {
      // Optional: You could still show a dialog to confirm, but for speed let's auto-select
      // or show a dialog pre-filled. Let's show dialog pre-filled/highlighted or just use it.
      // For this flow, let's assume we trust the request target if valid.
      deviceId = req.targetDeviceId;
    } else {
      // 2. Show dialog to select device manually
      deviceId = await showDialog<String>(
        context: context,
        builder: (ctx) => _AssignDeviceDialog(userId: req.userId),
      );
    }

    if (deviceId != null) {
      try {
        final adminRepo = ref.read(adminRepoProvider);
        final reqRepo = ref.read(requestRepoProvider);

        // 2. Create assignment
        await adminRepo.createAssignment(userId: req.userId, deviceId: deviceId);
        
        // 3. Update request status
        await reqRepo.updateStatus(req.id, 'accepted');

        // 4. Refresh lists
        ref.invalidate(adminRequestsProvider);
        ref.invalidate(adminAssignmentsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request approved & device assigned')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String reqId) async {
    try {
      await ref.read(requestRepoProvider).updateStatus(reqId, 'rejected');
      ref.invalidate(adminRequestsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(adminRequestsProvider);

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(req.desiredType ?? 'General Access'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User: ${req.userEmail ?? req.userId}'),
                    if (req.comment != null) Text('Note: ${req.comment}'),
                    Text(
                      'Status: ${req.status}',
                      style: TextStyle(
                        color: req.status == 'pending' ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: req.status == 'pending'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approve(context, ref, req),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _reject(context, ref, req.id),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _AssignmentsTab extends ConsumerWidget {
  const _AssignmentsTab();

  Future<void> _revoke(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(adminRepoProvider).deleteAssignment(id);
      ref.invalidate(adminAssignmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access revoked')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(adminAssignmentsProvider);

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No active assignments'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text('${item.deviceAlias} (${item.deviceId.substring(0,4)}...)'),
              subtitle: Text('Assigned to: ${item.userEmail}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _revoke(context, ref, item.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _AssignDeviceDialog extends ConsumerWidget {
  final String userId;
  const _AssignDeviceDialog({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(adminAvailableDevicesProvider);

    return AlertDialog(
      title: const Text('Select Device to Assign'),
      content: devicesAsync.when(
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Error: $e'),
        data: (devices) {
          if (devices.isEmpty) return const Text('No devices available');
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];
                return ListTile(
                  title: Text(d['alias'] ?? 'Unknown'),
                  subtitle: Text(d['type'] ?? ''),
                  onTap: () {
                    Navigator.of(context).pop(d['id']);
                  },
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
