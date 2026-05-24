---
name: flutter-supabase-anyalink
description: Use when making changes to lib/ that touch state management, Supabase access, or UI that depends on device data. Covers Riverpod 3 patterns, repository contract, optimistic UI, and Realtime vs polling toggle.
---

# AnyaLink — Flutter + Riverpod 3 + Supabase

## Providers principales (`lib/presentation/providers/`)

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `supabaseClientProvider` | `Provider<SupabaseClient>` | Acceso al cliente Supabase |
| `deviceRepoProvider` | `Provider<DeviceRepository>` | Instancia de `DeviceRepositorySupabase` |
| `devicesListProvider` | `StreamProvider<List<DeviceEntity>>` | Lista de dispositivos (Realtime o polling) |
| `toggleByIdProvider` | `FutureProvider.family<void, String>` | Toggle de estado por id |
| `optimisticOverridesProvider` | `NotifierProvider<..., Map<String,bool>>` | Overrides temporales de estado por id |

## Patrón de toggle optimista (patrón real del repo)

```dart
// En HomePage al tocar un DeviceTile:
void _toggle(WidgetRef ref, DeviceEntity device) {
  final newState = !device.state;
  // 1. Override optimista inmediato (UI responde antes de red)
  ref.read(optimisticOverridesProvider.notifier).set(device.id, newState);
  // 2. Escribir a Supabase
  ref.read(deviceRepoProvider).setStateById(device.id, newState).then((_) {
    // 3. Programar remoción del override tras confirmar
    ref.read(optimisticOverridesProvider.notifier)
        .scheduleRemove(device.id, const Duration(seconds: 2));
    // 4. Invalidar para re-fetch
    ref.invalidate(devicesListProvider);
  });
}
```

## Leer estado efectivo (override + real)

```dart
// En DeviceTile o similar:
final overrides = ref.watch(optimisticOverridesProvider);
final effectiveState = overrides[device.id] ?? device.state;
```

## Realtime vs polling — cómo cambiar

En `lib/core/env.dart`:
```dart
static const bool useRealtime = false; // cambiar a true para Realtime
```

Con `false` → usa `DeviceRepositorySupabase.pollAll()` cada 900 ms.
Con `true` → usa `DeviceRepositorySupabase.watchAll()` con canal Supabase Realtime.

No cambiar a `true` sin verificar que el canal `public:devices-list` esté habilitado en el proyecto Supabase.

## Entidad `DeviceEntity` (en `device_repo.dart`)

```dart
class DeviceEntity {
  final String id;
  final String alias;
  final String? type;   // null → ícono genérico en UI
  final bool state;
}
```

Construida con `DeviceEntity.fromMap(Map<String,dynamic>)`. **No tiene `updated_at`** expuesto en la entidad — solo se usa en los updates.

## Agregar un provider nuevo (patrón del repo)

```dart
// 1. Definir en un archivo de providers
final metricsProvider = StreamProvider.family<List<MetricRow>, String>((ref, deviceId) {
  final client = ref.watch(supabaseClientProvider);
  // implementar stream desde Supabase
});

// 2. Consumir en widget
class MetricsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(metricsProvider(deviceId));
    return async.when(
      data: (rows) => ...,
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

## Convenciones del proyecto

- Usar `ConsumerWidget` / `ConsumerStatefulWidget`, no `HookWidget`.
- `ref.read()` en callbacks, `ref.watch()` en `build()`.
- El `DeviceRepository` abstracto (`lib/domain/repositories/devices_repository.dart`) existe pero la UI actual usa `DeviceRepositorySupabase` directamente vía `deviceRepoProvider`.
- No usar `StateProvider` para listas — ya hay `devicesListProvider` como `StreamProvider`.
- `DeviceTile` y `DeviceCard` son los widgets de presentación de un dispositivo. Ver `lib/presentation/widgets/device_card.dart`.

## Tests existentes

```
test/device_toggle_test.dart    — test de toggle de estado
test/home_presence_test.dart    — test que HomePage renderiza
test/list_presence_test.dart    — test de lista de dispositivos
test/smoke_theme_test.dart      — smoke de tema Material3
test/helpers/test_app.dart      — helper compartido con ProviderScope + Supabase mock
```

Correr con: `flutter test`
