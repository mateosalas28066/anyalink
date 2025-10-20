// lib/presentation/pages/home_page.dart
// Comentario (ES): Home con cámara grande + tiles pequeños de demo (no persistentes).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../infrastructure/supabase/device_repo.dart';
import '../providers/device_list_providers.dart';
import '../providers/device_providers.dart';
import '../widgets/camera_card.dart';
import '../widgets/device_tile.dart';
import '../widgets/skeletons.dart';
import '../widgets/ui_atoms.dart';

bool _isDemoId(String id) => id.startsWith('demo-');

List<DeviceEntity> _demoDevices() => const [
  DeviceEntity(id: 'demo-fan', alias: 'Ventilador', state: true, type: 'fan'),
  DeviceEntity(id: 'demo-feeder', alias: 'Comedero', state: false, type: 'dispenser'),
  DeviceEntity(id: 'demo-fountain', alias: 'Fuente', state: false, type: 'fountain'),
  DeviceEntity(id: 'demo-camera', alias: 'Camara', state: true, type: 'camera'),
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(devicesListProvider);
    final repo = ref.read(deviceRepoProvider);
    final overrides = ref.watch(optimisticOverridesProvider);
    final overridesCtl = ref.read(optimisticOverridesProvider.notifier);

    Future<void> onToggleDevice(DeviceEntity d, bool currentUiValue) async {
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
          SnackBar(content: Text('Estado enviado: ${!currentUiValue ? 'Encender' : 'Apagar'}')),
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
                      slivers: const [
                        SliverToBoxAdapter(child: SectionTitle('Dispositivos')),
                        SliverToBoxAdapter(child: SizedBox(height: 8)),
                        SliverToBoxAdapter(
                          child: Text(
                            'No hay dispositivos aún',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: SectionTitle('Dispositivos')),
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
                            'Fuente: ${Env.useRealtime ? 'Realtime' : 'Polling'} · demo=${Env.addDemoTiles}',
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
          SectionTitle('Dispositivos'),
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
          const SectionTitle('Dispositivos'),
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
