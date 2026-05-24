---
name: anyalink-overview
description: Use at the start of any AnyaLink conversation. Provides the full repo map, MVP scope, what is frozen, and how the layers connect.
---

# AnyaLink — Visión general del repo

## Qué es

AnyaLink es una app IoT doméstica: controla dispositivos (luces, dispensadores) desde una UI Flutter que lee/escribe en Supabase. El MVP actual agrega un ESP32 como nodo de sensores + actuador (servo dispensador de comida, báscula HX711, temperatura DHT22).

## Arquitectura MVP

```
Flutter UI (Windows/Android)
  └── Riverpod providers
        └── DeviceRepositorySupabase
              └── Supabase Postgres (tabla devices + device_metrics + device_commands)
                    ↑↓
              Node-RED (localhost:1880)
                    ↑↓
              Mosquitto MQTT (localhost:1883)
                    ↑↓
              ESP32 firmware (PlatformIO)
                    ├── HX711 (báscula)
                    ├── DHT22 (temperatura/humedad)
                    └── Servo (dispensador)
```

## Carpetas del repo

| Carpeta | Estado | Rol |
|---------|--------|-----|
| `lib/` | Activo | App Flutter (Clean-ish arch + Riverpod) |
| `lib/infrastructure/supabase/` | Activo | Repositorio real contra Supabase |
| `lib/presentation/` | Activo | Pages, providers, widgets |
| `lib/domain/` | Activo (no usado directo por UI) | Entidades y contratos abstractos |
| `lib/data/` | Activo (parallel impl) | Datasource + repository Clean Arch |
| `bridge/` | **CONGELADO** | Bridge Python TP-Link — no tocar |
| `firmware/` | A crear | PlatformIO ESP32 |
| `infra/` | A crear | mosquitto.conf, flows.json Node-RED |
| `docs/` | Referencia | Documentación del proyecto |
| `test/` | Activo | Tests widget y helpers |

## Archivos clave

- `lib/main.dart` — init Supabase + ProviderScope
- `lib/infrastructure/supabase/device_repo.dart` — toda la lógica de DB
- `lib/presentation/providers/device_list_providers.dart` — `devicesListProvider`, `optimisticOverridesProvider`
- `lib/presentation/pages/home_page.dart` — pantalla principal
- `pubspec.yaml` — deps: `flutter_riverpod: ^3.0.0`, `supabase_flutter: ^2.5.0`

## Alcance del MVP (este ciclo)

- [ ] Firmware ESP32: publicar métricas (peso, temp, humedad) vía MQTT, recibir comando de dispense
- [ ] Node-RED: suscribirse a tópicos ESP32, escribir en `device_metrics` y `device_commands` en Supabase
- [ ] Supabase: agregar tablas `device_metrics` y `device_commands`
- [ ] Flutter: mostrar métricas del ESP32 en la UI (opcional)

## Fuera de alcance

- Bridge TP-Link (congelado)
- Auth completo Supabase (AuthGate pasa directo a HomePage)
- TLS/auth en Mosquitto
- Deploy a producción
- App Store / Play Store
