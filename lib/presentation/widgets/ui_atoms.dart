// lib/presentation/widgets/ui_atoms.dart
// Comentario (ES): Átomos reutilizables para AnyaLink.

import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final bool isOn;
  final String labelOn;
  final String labelOff;
  const StatusChip({
    super.key,
    required this.isOn,
    this.labelOn = 'Encendida',
    this.labelOff = 'Apagada',
  });

  @override
  Widget build(BuildContext context) {
    final bg = isOn ? const Color(0x332EC27E) : const Color(0x11000000);
    final fg = isOn ? const Color(0xFF2EC27E) : Colors.black54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isOn ? Icons.flash_on : Icons.power_settings_new, size: 14, color: fg),
        const SizedBox(width: 6),
        Text(isOn ? labelOn : labelOff, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

class IconCircle extends StatelessWidget {
  final IconData icon;
  final bool highlight;
  const IconCircle({super.key, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlight ? const Color(0xFFECFDF5) : const Color(0xFFF2F3F5),
      ),
      child: Icon(icon, color: highlight ? const Color(0xFF2EC27E) : Colors.black45, size: 26),
    );
  }
}
