# AnyaLink

Plataforma IoT para cuidado de mascotas. El MVP integra una app Flutter, un broker MQTT local, Node-RED, Supabase y un nodo ESP32 con servo dispensador y sensores ambientales.

## Stack del MVP

- **App**: Flutter 3 + Riverpod + Supabase Realtime.
- **Hardware**: ESP32 (DOIT DevKit v1) con servo, celda de carga HX711, DHT22 y OLED SSD1306.
- **Broker MQTT**: Mosquitto local en Windows (puerto 1883, sin auth en LAN doméstica).
- **Orquestador**: Node-RED local (puerto 1880) que puentea MQTT ↔ Supabase REST.
- **Backend**: Supabase (Postgres + Realtime). Tablas `devices`, `device_metrics`, `device_commands`.

## Componentes del repo

| Path | Descripción |
|---|---|
| [`lib/`](lib/) | App Flutter — `FeederCard`, repositorio Supabase con `sendCommand` y `watchMetrics` por Realtime. |
| [`firmware/anyalink_node/`](firmware/anyalink_node/) | Firmware ESP32 (PlatformIO). Ver su [README](firmware/anyalink_node/README.md). |
| [`infra/`](infra/) | Mosquitto config + Node-RED flows. Ver [README](infra/README.md). |
| [`supabase/migrations/`](supabase/migrations/) | SQL del esquema MVP. |
| [`bridge/`](bridge/) | Bridge Python TP-Link Kasa/Tapo. **Congelado** en el MVP. |
| [`docs/`](docs/) | Documentación funcional, ver [docs/README.md](docs/README.md). |
| [`.claude/`](.claude/) | Skills y MCPs locales para asistir el desarrollo con Claude Code. |

## Quickstart (Windows)

```powershell
flutter pub get
flutter test
flutter run -d windows
```

Para infra local y firmware ver los READMEs correspondientes y `docs/06-desarrollo-y-testing.md`.

## Credenciales

- `lib/core/env.dart` y `firmware/anyalink_node/include/secrets.h` están en `.gitignore`. Copiar de los `*.example` y rellenar.
- El plugin oficial de Supabase para Claude Code (`/plugin install supabase@claude-plugins-official`) habilita ejecución de SQL desde la sesión.
