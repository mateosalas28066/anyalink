// lib/presentation/providers/mock_providers.dart
// Comentario (ES): Estado mock para la UI local de Home (sin Supabase).

import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceUiModel {
  final String id;
  final String title;
  final String room;
  final bool isOn;

  const DeviceUiModel({
    required this.id,
    required this.title,
    required this.room,
    required this.isOn,
  });

  DeviceUiModel copyWith({bool? isOn}) {
    return DeviceUiModel(
      id: id,
      title: title,
      room: room,
      isOn: isOn ?? this.isOn,
    );
  }
}

class DevicesNotifier extends Notifier<List<DeviceUiModel>> {
  @override
  List<DeviceUiModel> build() {
    return const [
      DeviceUiModel(
        id: 'lampara',
        title: 'Lampara',
        room: 'Dormitorio',
        isOn: false,
      ),
    ];
  }

  void toggle(String id) {
    state = [
      for (final device in state)
        if (device.id == id)
          device.copyWith(isOn: !device.isOn)
        else
          device,
    ];
  }
}

final devicesProvider =
    NotifierProvider<DevicesNotifier, List<DeviceUiModel>>(DevicesNotifier.new);
