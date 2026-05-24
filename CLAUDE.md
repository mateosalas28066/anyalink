# AnyaLink — Contexto para Claude

## Stack

- **Flutter 3 + Riverpod 3** — app móvil/desktop en `lib/`
- **Supabase** — auth, base de datos Postgres, Realtime (polling activo ahora)
- **ESP32** — firmware a crear en `firmware/` (PlatformIO)
- **MQTT** — Mosquitto local en Windows, broker en puerto 1883
- **Node-RED** — orquesta MQTT ↔ Supabase, flows en `infra/nodered/`
- **Bridge Python (TP-Link)** — CONGELADO. No modificar `bridge/`

## Paths críticos

| Path | Rol |
|------|-----|
| `lib/infrastructure/supabase/device_repo.dart` | Repositorio real, queries a `devices` |
| `lib/presentation/providers/device_list_providers.dart` | Providers Riverpod + optimistic UI |
| `lib/presentation/pages/home_page.dart` | Pantalla principal, lista dispositivos |
| `lib/main.dart` | Init Supabase + ProviderScope |
| `firmware/` | A crear — PlatformIO ESP32 |
| `infra/` | A crear — mosquitto.conf, flows.json Node-RED |
| `bridge/` | CONGELADO — no tocar |
| `docs/` | Documentación del proyecto |

## Comandos clave

```bash
flutter run -d windows          # correr en desktop Windows
flutter test                    # tests unitarios/widget
flutter analyze                 # linter
pio run -t upload               # flash firmware ESP32
pio device monitor              # serial monitor ESP32
node-red                        # arrancar Node-RED (puerto 1880)
mosquitto_sub -h localhost -t 'anyalink/#' -v   # debug MQTT
mosquitto_pub -h localhost -t 'anyalink/test' -m 'hola'
net start mosquitto             # arrancar broker
net stop mosquitto              # detener broker
```

## NO tocar

- `bridge/` — código TP-Link congelado permanentemente para este MVP
- Credenciales reales en `lib/core/env.dart` — nunca commitear valores reales
- Schema `devices` sin crear migración SQL explícita

## Estado actual del MVP

- **App Flutter**: lista `devices`, toggle optimista, polling a Supabase activo (`Env.useRealtime = false`)
- **Firmware ESP32**: a implementar (servo dispensador + HX711 + DHT22)
- **MQTT + Node-RED**: a implementar en `infra/`
- **Supabase**: tabla `devices` existe; hay que agregar `device_metrics` y `device_commands`

## Skills locales disponibles

Invocar con `/anyalink-overview`, `/anyalink-supabase-schema`, `/esp32-mqtt-node`, `/nodered-mosquitto-local`, `/flutter-supabase-anyalink`.

| Skill | Cuándo usarla |
|-------|--------------|
| `anyalink-overview` | Cualquier conversación sobre AnyaLink |
| `anyalink-supabase-schema` | Tarea que toque Supabase, SQL, migraciones |
| `esp32-mqtt-node` | Firmware ESP32, PlatformIO, MQTT topics |
| `nodered-mosquitto-local` | Infra MQTT, flows Node-RED, broker |
| `flutter-supabase-anyalink` | Cambios en `lib/` que toquen estado o Supabase |
