// lib/domain/entities/device.dart
// Comentario (ES): Entidad de dominio para un dispositivo (p.ej., luz).
class Device {
  final String id;
  final String alias;
  final String type; // e.g. 'light'
  final bool state;  // true = On, false = Off

  const Device({
    required this.id,
    required this.alias,
    required this.type,
    required this.state,
  });

  Device copyWith({String? id, String? alias, String? type, bool? state}) {
    return Device(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      type: type ?? this.type,
      state: state ?? this.state,
    );
  }
}
