# Arquitectura

## Vista general

```text
Flutter app  ── REST + Realtime ──►  Supabase  ◄── REST ──  Node-RED  ◄── MQTT ──  Mosquitto  ◄── MQTT ──  ESP32
                                     (Postgres)              (local)                (local)                (servo + HX711 + DHT22 + OLED)
```

Dos lazos lógicos:

- **Comandos** (app → hardware): la app inserta una fila en `device_commands`. Node-RED polea cada 2 s, publica en `anyalink/device/{id}/command` (QoS 1) y marca la fila como `sent`. El ESP32 ejecuta y publica un ACK en `.../state`. Node-RED escucha el ACK y marca `done`.
- **Telemetría** (hardware → app): el ESP32 publica cada 5 s en `anyalink/device/{id}/metrics` (QoS 0). Node-RED hace upsert en `device_metrics`. La app, suscrita a Realtime sobre esa tabla, refresca el `FeederCard` en vivo. Una publicación retained en `.../online` (QoS 1) actualiza `devices.online` y `last_seen`.

## Capas Flutter

- `core`: `Env` con URL y anon key de Supabase, alias del dispensador, flag `useRealtime`.
- `presentation`: `HomePage`, `AuthGate`, `LoginPage`, providers Riverpod, widgets `DeviceCard`, `FeederCard`, `CameraCard`.
- `infrastructure/supabase`: `DeviceRepositorySupabase` con `DeviceEntity`, `DeviceMetrics`, `sendCommand`, `watchMetrics`, polling y Realtime.
- `domain` y `data`: Clean Architecture parcial heredada, no es la ruta activa.

## Providers principales

- `supabaseClientProvider`: expone `Supabase.instance.client`.
- `deviceRepoProvider`: crea `DeviceRepositorySupabase`.
- `devicesListProvider`: stream de la lista de dispositivos (Realtime si `Env.useRealtime`).
- `toggleByIdProvider`: action family para toggles, aunque `HomePage` llama directo al repo.
- `optimisticOverridesProvider`: estados temporales por id para UI responsiva.
- `authSessionProvider` y `authActionsProvider`: existen pero `AuthGate` no los consume aún.

## Flujo de pantalla principal

1. `main.dart` inicializa Supabase.
2. `AnyaLinkApp` monta `AuthGate`.
3. `AuthGate` devuelve `HomePage` directamente.
4. `HomePage` escucha `devicesListProvider`.
5. Cada device se dispatcha por `type`:
   - `type == 'camera'`  → `CameraCard`.
   - `type == 'feeder'`  → `FeederCard` (badge online + métricas en vivo + botón Dispensar).
   - resto → `DeviceCard` (toggle optimista).
6. `FeederCard.Dispensar` → `repo.sendCommand(id, 'dispense', {portion: 1})` → fila pending en `device_commands`.
7. `DeviceCard` toggle → override optimista + `setStateById`.

## Infra local

- **Mosquitto** corre como servicio Windows. Config en `W:\Mosquitto\mosquitto.conf` (copia versionada en `infra/mosquitto/mosquitto.conf`).
- **Node-RED** corre desde npm global (`node-red` en consola, puerto 1880). Flujos vivos en `W:\anyalink\infra\node-red\flows.json` (no en `~/.node-red/`, está pinneado a esa ruta).
- Los 4 flujos son: poll de comandos pending, ACK de state, upsert de métricas, heartbeat online. Detalle en `infra/README.md`.

## Por qué Node-RED y no llamadas directas ESP32 → Supabase

La librería HTTP de Supabase para ESP32 es frágil (Realtime sobre WebSocket no es estable). MQTT es el protocolo natural del edge y Mosquitto + Node-RED ya es el patrón usado en la versión anterior del proyecto. Node-RED encapsula la traducción protocolo/auth y deja al firmware solo hablar MQTT con JSON simple.

## Por qué Realtime activado

Las métricas cambian cada 5 s y la app debe verlas casi al instante. Polling de 800 ms a la tabla `device_metrics` por cada device es ineficiente y aún así introduce latencia. Realtime via `onPostgresChanges` filtrado por `device_id` es la ruta natural. El polling sigue disponible como fallback en el repo.
