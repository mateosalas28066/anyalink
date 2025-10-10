// lib/presentation/pages/home_page.dart
// Comentario (ES): Muestra "Luz: On/Off" y permite togglear; escucha Realtime.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/devices_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDevice = ref.watch(lightDeviceStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AnyaLink'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Comentario (ES): Cierra sesión y AuthGate enviará a LoginPage.
              await Supabase.instance.client.auth.signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: asyncDevice.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (device) {
            if (device == null) {
              return const Text('Device not found');
            }
            final stateText = device.state ? 'On' : 'Off';
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Luz: $stateText', style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final setDevice = ref.read(setDeviceStateProvider);
                    await setDevice(id: device.id, state: !device.state);
                  },
                  child: const Text('Toggle'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
