# Resumen del Proyecto

## Propósito

AnyaLink es una plataforma IoT para cuidado de mascotas. El MVP combina un dashboard Flutter con un nodo ESP32 que dispensa comida (servo), mide peso (HX711) y monitorea temperatura/humedad (DHT22), todo conectado vía MQTT local y persistido en Supabase.

## Stack del MVP

- **Frontend**: Flutter 3 + Riverpod 3, Material 3, Supabase Realtime para métricas en vivo.
- **Backend**: Supabase (Postgres + Realtime), tablas `devices`, `device_metrics`, `device_commands`.
- **Edge**: ESP32 DOIT DevKit v1 con PlatformIO, Arduino framework. Servo en GPIO13, HX711 DT=16 SCK=17, DHT22 GPIO4, OLED I2C 0x3C.
- **Broker**: Mosquitto v2 nativo en Windows como servicio, escuchando 0.0.0.0:1883.
- **Orquestación**: Node-RED v4 (npm global) con 4 flujos que puentean MQTT con Supabase REST.

## Estructura principal

- `lib/main.dart`: inicializa Supabase y monta `AnyaLinkApp`.
- `lib/core/env.dart` (no commiteado): URL y anon key de Supabase, alias y flags. Plantilla en `.example`.
- `lib/presentation/`: páginas, providers, widgets (`DeviceCard`, `FeederCard`, `CameraCard`).
- `lib/infrastructure/supabase/device_repo.dart`: repositorio activo (`DeviceEntity`, `DeviceMetrics`, `sendCommand`, `watchMetrics`).
- `lib/domain/` y `lib/data/`: Clean Architecture parcial, no es la ruta principal.
- `firmware/anyalink_node/`: firmware ESP32 con su propio README. `secrets.h` no commiteado.
- `infra/`: configs de Mosquitto y flows.json de Node-RED, con README propio.
- `supabase/migrations/`: SQL del esquema MVP.
- `bridge/`: scripts Python TP-Link Kasa/Tapo. **Congelado** en el MVP (ver `05-bridge-iot.md`).
- `test/`: tests de presencia, smoke, toggle y los nuevos `feeder_dispense_test` y `feeder_metrics_test`.

## Estado actual

- `AuthGate` devuelve directo a `HomePage`. La pantalla de login existe pero no controla la navegación.
- `Env.useRealtime = true` — la app usa canales Realtime para métricas y lista de dispositivos.
- El tile `Dispensador` se renderiza como `FeederCard` (badge online, métricas peso/temp/humedad, botón Dispensar).
- Otros tipos usan `DeviceCard` (toggle con UI optimista).
- RLS desactivada en las tres tablas (LAN doméstica, MVP académico).

## Comandos básicos

```powershell
flutter pub get
flutter run -d windows
flutter test
flutter analyze
```

Para firmware, broker e infra ver `06-desarrollo-y-testing.md` y los READMEs en `firmware/` e `infra/`.
