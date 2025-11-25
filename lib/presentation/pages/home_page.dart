// lib/presentation/pages/home_page.dart
// Comentario (ES): Home con tarjeta de camara grande + tiles compactos de demo (no persistentes).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../infrastructure/supabase/device_repo.dart';
import '../providers/device_list_providers.dart';
import '../providers/device_providers.dart';
import '../providers/auth_providers.dart'; // userRoleProvider
import '../widgets/camera_card.dart';
import '../widgets/device_tile.dart';
import '../widgets/device_request_dialog.dart'; // DeviceRequestDialog
import '../widgets/screen_message_dialog.dart'; // ScreenMessageDialog
import 'admin_dashboard_page.dart'; // AdminDashboardPage
import '../widgets/skeletons.dart';
import '../widgets/ui_atoms.dart';
import '../widgets/weather_header.dart';

bool _isDemoId(String id) => id.startsWith('demo-');

List<DeviceEntity> _demoDevices() => const [
  DeviceEntity(id: 'demo-fan', alias: 'Ventilador', state: true, type: 'fan'),
  DeviceEntity(id: 'demo-feeder', alias: 'Comedero', state: false, type: 'dispenser'),
  DeviceEntity(id: 'demo-led', alias: 'LED', state: true, type: 'led'),
  DeviceEntity(id: 'demo-fountain', alias: 'Fuente', state: false, type: 'fountain'),
  DeviceEntity(id: 'demo-camera', alias: 'Camara', state: true, type: 'camera')
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(devicesListProvider);
    final repo = ref.read(deviceRepoProvider);
    final overrides = ref.watch(optimisticOverridesProvider);
    final overridesCtl = ref.read(optimisticOverridesProvider.notifier);

    final userRole = ref.watch(userRoleProvider).asData?.value;

    Future<void> onToggleDevice(DeviceEntity d, bool currentUiValue) async {
      // Handle screen devices with message dialog
      if (d.type?.toLowerCase() == 'screen') {
        final newMessage = await showDialog<String>(
          context: context,
          builder: (_) => ScreenMessageDialog(currentMessage: d.message ?? ''),
        );
        
        if (newMessage == null) return; // User cancelled
        
        try {
          await repo.setMessageById(d.id, newMessage);
          ref.invalidate(devicesListProvider);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message sent')),
          );
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
        return;
      }
      
      // Original toggle logic for non-screen devices
      overridesCtl.set(d.id, !currentUiValue);

      if (_isDemoId(d.id)) {
        overridesCtl.scheduleRemove(d.id, const Duration(milliseconds: 900));
        return;
      }

      try {
        await repo.setStateById(d.id, !currentUiValue);
        ref.invalidate(devicesListProvider);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Command sent: ${!currentUiValue ? 'Turn On' : 'Turn Off'}')),
        );
      } catch (e) {
        overridesCtl.remove(d.id);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    return Scaffold(
      floatingActionButton: userRole == 'guest'
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const DeviceRequestDialog(),
                );
              },
              icon: const Icon(Icons.add_link),
              label: const Text('Request Device'),
            )
          : null,
      appBar: AppBar(
        title: const Text('AnyaLink'),
        centerTitle: false,
        actions: [
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Dashboard',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
                );
              },
            ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.pets, color: Colors.black45),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: asyncList.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorState(message: '$e'),
                data: (items0) {
                  var items = <DeviceEntity>[...items0];
                  if (Env.addDemoTiles) {
                    for (final d in _demoDevices()) {
                      final exists = items.any(
                        (x) => x.alias.toLowerCase() == d.alias.toLowerCase(),
                      );
                      if (!exists) items.add(d);
                    }
                  }

                  final cams = items
                      .where((d) => (d.type ?? '').toLowerCase() == 'camera')
                      .toList();
                  final others = items
                      .where((d) => (d.type ?? '').toLowerCase() != 'camera')
                      .toList();

                  if (items.isEmpty) {
                    return CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: SectionTitle('Your Devices')),
                        const SliverToBoxAdapter(child: SizedBox(height: 8)),
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No devices assigned yet.',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white70 
                                    : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const DeviceRequestDialog(),
                                  );
                                },
                                icon: const Icon(Icons.add_link),
                                label: const Text('Request Device Access'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: WeatherHeader(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SectionTitle('Your Devices')),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),

                      SliverPadding(
                        padding: EdgeInsets.zero,
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount =
                                constraints.crossAxisExtent < 340 ? 1 : 2;
                            return SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 104,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final d = others[i];
                                  final isOnUi = overrides[d.id] ?? d.state;
                                  return DeviceTile(
                                    title: d.alias,
                                    type: d.type,
                                    isOn: isOnUi,
                                    onToggle: () => onToggleDevice(d, isOnUi),
                                  );
                                },
                                childCount: others.length,
                              ),
                            );
                          },
                        ),
                      ),

                      if (cams.isNotEmpty) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        SliverToBoxAdapter(
                          child: CameraCard(
                            title: cams.first.alias,
                            room: 'Bedroom',
                            onTap: () {},
                          ),
                        ),
                      ],

                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverToBoxAdapter(
                        child: Opacity(
                          opacity: 0.65,
                          child: Text(
                            'Source: ${Env.useRealtime ? 'Realtime' : 'Polling'} | demo=${Env.addDemoTiles}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionTitle('Your Devices'),
          SizedBox(height: 8),
          GridSkeleton(count: 4),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Your Devices'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: $message',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}






