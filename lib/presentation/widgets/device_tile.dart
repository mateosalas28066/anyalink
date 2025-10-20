// lib/presentation/widgets/device_tile.dart
// Comentario (ES): Tile compacto (horizontal) para evitar overflow y reducir altura.

import 'package:flutter/material.dart';

import '../theme/device_theme.dart';

class DeviceTile extends StatelessWidget {
  final String title;
  final String? type;
  final bool isOn;
  final VoidCallback onToggle;

  const DeviceTile({
    super.key,
    required this.title,
    required this.isOn,
    required this.onToggle,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final accent = deviceAccent(type, isOn: isOn);
    final icon = deviceIcon(type);
    final mq = MediaQuery.of(context);
    final double textScale = mq.textScaleFactor.clamp(1.0, 1.2);
    final minH = (68.0 * textScale).clamp(68.0, 90.0);

    return MediaQuery(
      data: mq.copyWith(textScaleFactor: textScale),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggle,
          child: Container(
            constraints: BoxConstraints(minHeight: minH),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x11000000)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _StatusPill(isOn: isOn, color: accent),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Switch.adaptive(
                  value: isOn,
                  onChanged: (_) => onToggle(),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return accent;
                    }
                    return Colors.white;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return accent.withValues(alpha: 0.25);
                    }
                    return const Color(0x14000000);
                  }),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isOn;
  final Color color;
  const _StatusPill({required this.isOn, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOn ? color.withValues(alpha: 0.12) : const Color(0x11000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        // Comentario (ES): El pill nunca hace wrap; si no cabe, elipsis.
        isOn ? 'Encendida' : 'Apagada',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOn ? color : Colors.black54,
        ),
      ),
    );
  }
}
