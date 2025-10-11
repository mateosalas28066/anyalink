// lib/presentation/pages/home_page.dart
// Comentario (ES): HomePage con lista dinámica desde Supabase.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anyalink_1/core/env.dart';
import 'package:anyalink_1/presentation/providers/device_list_providers.dart';
import 'package:anyalink_1/presentation/providers/device_providers.dart';
import 'package:anyalink_1/presentation/widgets/device_card.dart';
import 'package:anyalink_1/presentation/widgets/ui_atoms.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(devicesListProvider);
    final repo = ref.read(deviceRepoProvider);
    final overrides = ref.watch(optimisticOverridesProvider);
    final overridesCtl = ref.read(optimisticOverridesProvider.notifier);

    Future<void> onToggleDevice(String id, bool currentUiValue) async {
      overridesCtl.set(id, !currentUiValue);

      try {
        await repo.setStateById(id, !currentUiValue);
        ref.invalidate(devicesListProvider);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Estado enviado: ${!currentUiValue ? 'Encender' : 'Apagar'}'),
          ),
        );
        overridesCtl.scheduleRemove(id, const Duration(seconds: 1));
      } catch (e) {
        overridesCtl.remove(id);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        return;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AnyaLink'),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.pets, color: Colors.black45),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: asyncList.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Dispositivos'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SectionTitle('Dispositivos'),
                        Text(
                          'No hay dispositivos aún',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Dormitorio'),
                      ...items.map(
                        (device) {
                          final isOnUi = overrides[device.id] ?? device.state;
                          return DeviceCard(
                            title: device.alias,
                            room: 'Dormitorio',
                            isOn: isOnUi,
                            onToggle: () => onToggleDevice(device.id, isOnUi),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: 0.65,
                        child: Text(
                          'Fuente: Supabase ${Env.useRealtime ? 'Realtime' : 'Polling'} (UI optimista)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
