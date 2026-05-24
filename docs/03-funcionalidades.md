# Funcionalidades

## Dashboard de dispositivos

`HomePage` muestra el título `AnyaLink`, sección `Dispositivos` con tarjetas y, si existe algún device tipo `camera`, su tarjeta. Material 3, fondo gris claro, acentos por tipo.

## Lista desde Supabase

`devicesListProvider` lee de `DeviceRepositorySupabase.getAll()`. Columnas: `id, alias, type, state, online, last_seen`, ordenado por `alias`.

## `FeederCard` (tipo `feeder`)

Para el dispensador (alias `Dispensador`, type `feeder`):

- **Badge online**: verde si `devices.online == true`, gris si offline. Se actualiza cuando el ESP32 publica retained en `anyalink/device/{id}/online`.
- **Métricas en vivo**: tres tiles con peso (g), temperatura (°C), humedad (%). Vienen de `device_metrics` via Realtime (`watchMetrics(deviceId)`).
- **Botón Dispensar**: inserta una fila en `device_commands` con `action='dispense', payload={portion:1}, status='pending'`. Node-RED la recoge en ≤2 s y la publica al ESP32. Snackbar de confirmación local.

## `DeviceCard` (otros tipos)

Toggle con estado optimista:

1. `HomePage` calcula valor actual visible.
2. `optimisticOverridesProvider` guarda el opuesto para ese id.
3. Si es device demo, solo limpia el override.
4. Si es real, llama `setStateById`.
5. Si éxito, invalida `devicesListProvider` y muestra snackbar.
6. Si error, remueve override y muestra el error.

## `CameraCard` (tipo `camera`)

Render del asset `Env.cameraAsset` (`assets/sample/camera.jpg`). Visualización estática por ahora.

## Tiles demo

`Env.addDemoTiles = true` agrega tiles falsos cuando no existen por alias en Supabase: Ventilador, Comedero, Fuente, Camara. Ids prefijo `demo-`, no se escriben en Supabase.

## Auth preparada, no activa

Existen `LoginPage`, `authSessionProvider`, `authActionsProvider`. `AuthGate` devuelve siempre `HomePage`. Para activar login hay que cablear el gate a la sesión.

## Realtime o polling

`Env.useRealtime` controla:

- `true` (actual): canales Realtime para devices y métricas.
- `false`: fallback a polling (`pollAll`, `pollStateByAlias`) en el repo.
