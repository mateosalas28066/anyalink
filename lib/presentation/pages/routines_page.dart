import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routines_providers.dart';
import '../../infrastructure/supabase/routines_repo.dart';
import '../widgets/create_routine_dialog.dart';

class RoutinesPage extends ConsumerWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(userRoutinesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Routines')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const CreateRoutineDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: routinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (routines) {
          if (routines.isEmpty) {
            return const Center(
              child: Text(
                'No routines yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Dismissible(
                key: Key(routine.id),
                background: Container(color: Colors.red),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref.read(routinesRepoProvider).deleteRoutine(routine.id);
                  // Optimistic update or invalidate
                  ref.invalidate(userRoutinesProvider);
                },
                child: SwitchListTile(
                  title: Text('${routine.actionType == 'set_state' ? 'Toggle' : 'Message'} every ${routine.intervalSeconds}s'),
                  subtitle: Text('Payload: ${routine.actionPayload}'),
                  value: routine.enabled,
                  onChanged: (val) async {
                    await ref.read(routinesRepoProvider).toggleRoutine(routine.id, val);
                    ref.invalidate(userRoutinesProvider);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
