// lib/presentation/widgets/device_card.dart
// Comentario (ES): Tarjeta tipo mockup para un dispositivo de luz.

import 'package:flutter/material.dart';

import 'ui_atoms.dart';

class DeviceCard extends StatelessWidget {
  final String title;
  final String room;
  final bool isOn;
  final VoidCallback onToggle;

  const DeviceCard({
    super.key,
    required this.title,
    required this.room,
    required this.isOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
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
        child: Row(
          children: [
            IconCircle(icon: isOn ? Icons.lightbulb : Icons.lightbulb_outline, highlight: isOn),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(room, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            Row(
              children: [
                StatusChip(isOn: isOn),
                const SizedBox(width: 10),
                Switch.adaptive(
                  value: isOn,
                  onChanged: (_) => onToggle(),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF2EC27E);
                    }
                    return Colors.white;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0x332EC27E);
                    }
                    return const Color(0x14000000);
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
