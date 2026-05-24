// lib/presentation/widgets/feeder_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anyalink_1/infrastructure/supabase/device_repo.dart';
import 'package:anyalink_1/presentation/providers/device_providers.dart';

// Provider local para las métricas del feeder
final _feederMetricsProvider =
    StreamProvider.autoDispose.family<DeviceMetrics?, String>((ref, deviceId) {
  final repo = ref.watch(deviceRepoProvider);
  return repo.watchMetrics(deviceId);
});

class FeederCard extends ConsumerWidget {
  final DeviceEntity device;

  const FeederCard({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(_feederMetricsProvider(device.id));
    final repo = ref.read(deviceRepoProvider);

    Future<void> onDispense() async {
      try {
        await repo.sendCommand(device.id, 'dispense', {'portion': 1});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comando enviado')),
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

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6))
        ],
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: device.online ? const Color(0xFFECFDF5) : const Color(0xFFF2F3F5),
                ),
                child: Icon(
                  Icons.pets,
                  color: device.online ? const Color(0xFF2EC27E) : Colors.black45,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.alias,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 4),
                    _OnlineBadge(online: device.online),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onDispense,
                icon: const Icon(Icons.restaurant, size: 16),
                label: const Text('Dispensar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2EC27E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          metricsAsync.when(
            data: (metrics) => _MetricsRow(metrics: metrics),
            loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, _) => const _MetricsRow(metrics: null),
          ),
        ],
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  final bool online;
  const _OnlineBadge({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF2EC27E) : Colors.black45;
    final bg = online ? const Color(0x332EC27E) : const Color(0x11000000);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 5),
        Text(
          online ? 'En línea' : 'Sin conexión',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ]),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final DeviceMetrics? metrics;
  const _MetricsRow({this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricTile(
          icon: Icons.scale,
          label: 'Peso',
          value: metrics != null ? '${metrics!.weightG.toStringAsFixed(0)}g' : '--',
        ),
        const SizedBox(width: 8),
        _MetricTile(
          icon: Icons.thermostat,
          label: 'Temp',
          value: metrics != null ? '${metrics!.temperatureC.toStringAsFixed(1)}°C' : '--',
        ),
        const SizedBox(width: 8),
        _MetricTile(
          icon: Icons.water_drop,
          label: 'Humedad',
          value: metrics != null ? '${metrics!.humidityPct.toStringAsFixed(0)}%' : '--',
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2EC27E)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
