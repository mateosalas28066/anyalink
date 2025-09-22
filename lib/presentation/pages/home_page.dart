// lib/presentation/pages/home_page.dart
// Comentario (ES): HomePage estilo "AnyaLink" claro: tarjetas blancas, sombra suave y switch verde.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          child: asyncDevice.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
            data: (device) {
              if (device == null) {
                return const Center(child: Text('Device not found'));
              }
              final isOn = device.state;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comentario (ES): Cabecera tipo sección ("Your Devices" -> "Dormitorio").
                  Text(
                    'Dormitorio',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  // Comentario (ES): Tarjeta blanca del dispositivo (como el mockup).
                  _DeviceCard(
                    isOn: isOn,
                    title: 'Luz Dormitorio',
                    room: 'Bedroom',
                    icon: Icons.lightbulb_outline,
                    onToggle: () async {
                      final setDevice = ref.read(setDeviceStateProvider);
                      await setDevice(id: device.id, state: !isOn);
                    },
                  ),

                  // Comentario (ES): Espacio para futuras tarjetas (ventilador, comedero, cámara, etc).
                  const Spacer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  // Comentario (ES): Tarjeta blanca con icono redondo, títulos y switch verde.
  final bool isOn;
  final String title;
  final String room;
  final IconData icon;
  final VoidCallback onToggle;

  const _DeviceCard({
    required this.isOn,
    required this.title,
    required this.room,
    required this.icon,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle, // Comentario (ES): Tocar la tarjeta también alterna.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // sombra muy sutil
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0x11000000)),
        ),
        child: Row(
          children: [
            // Comentario (ES): Avatar del icono (círculo gris claro).
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF2F3F5),
              ),
              child: Icon(
                isOn ? Icons.lightbulb : icon,
                color: isOn ? const Color(0xFF2EC27E) : Colors.black45,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Comentario (ES): Títulos (nombre del device + habitación).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    room,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Comentario (ES): Estado y switch verde.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOn ? const Color(0x332EC27E) : const Color(0x11000000),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOn ? Icons.flash_on : Icons.power_settings_new,
                        size: 14,
                        color: isOn ? const Color(0xFF2EC27E) : Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOn ? 'Encendida' : 'Apagada',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOn ? const Color(0xFF2EC27E) : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Switch.adaptive(
                  value: isOn,
                  onChanged: (_) => onToggle(),
                  activeColor: const Color(0xFF2EC27E),          // verde acento
                  activeTrackColor: const Color(0x332EC27E),     // track suave
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
