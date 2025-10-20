import 'package:flutter/material.dart';

IconData deviceIcon(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'light':
    case 'lamp':
      return Icons.lightbulb;
    case 'fan':
      return Icons.toys;
    case 'sensor':
      return Icons.sensors;
    case 'dispenser':
      return Icons.pets;
    case 'fountain':
      return Icons.water_drop;
    case 'camera':
      return Icons.videocam;
    default:
      return Icons.device_hub;
  }
}

Color deviceAccent(String? type, {bool isOn = false}) {
  const base = Color(0xFF2EC27E);
  if (!isOn) return const Color(0xFF9AA0A6);
  switch ((type ?? '').toLowerCase()) {
    case 'light':
    case 'lamp':
      return base;
    case 'fan':
      return Colors.teal;
    case 'sensor':
      return Colors.indigo;
    case 'dispenser':
      return Colors.orange;
    case 'fountain':
      return Colors.blueAccent;
    case 'camera':
      return Colors.deepPurple;
    default:
      return base;
  }
}
