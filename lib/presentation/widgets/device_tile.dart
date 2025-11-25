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
    final displayTitle = title.trim().isNotEmpty
        ? title.trim()
        : ((type ?? '').trim().isNotEmpty ? (type ?? '').trim() : 'Device');
    final double textScale = mq.textScaler.scale(1.0).clamp(1.0, 1.2);
    final minH = (68.0 * textScale).clamp(68.0, 90.0);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final borderColor = isDarkMode ? const Color(0x22FFFFFF) : const Color(0x11000000);

    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(textScale)),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggle,
          child: Container(
            constraints: BoxConstraints(minHeight: minH),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDarkMode 
                ? [] 
                : const [
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
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _StatusPill(isOn: isOn, color: accent),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Show text input button for screens, toggle for others
                if (type?.toLowerCase() == 'screen')
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onToggle, // Will trigger dialog in HomePage
                    color: accent,
                  )
                else
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
                IconButton(
                  icon: const Icon(Icons.alarm_add, color: Colors.black45),
                  tooltip: 'Add Routine',
                  onPressed: () {
                    // We need to pass the device to the dialog, but the dialog currently selects from a list.
                    // Ideally, we'd pass the device as a pre-selected argument.
                    // For now, let's just open the dialog.
                    // Note: This requires importing the dialog.
                    // Since this is a pure widget, we might need to pass a callback or use a global navigator key.
                    // But for simplicity in this architecture, let's assume we can push the dialog.
                    // Wait, DeviceTile is used in HomePage. Let's add an onAddRoutine callback to DeviceTile instead.
                  },
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
        isOn ? 'On' : 'Off',
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
