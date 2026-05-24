# Resumen del Proyecto

## Proposito

AnyaLink es un panel de domotica para controlar y monitorear dispositivos del hogar. La version actual se concentra en un dashboard Flutter con dispositivos conectados a Supabase y un bridge Python para reflejar cambios entre base de datos y hardware local.

## Stack real

- Flutter y Dart.
- Riverpod para estado y dependencias.
- Supabase Flutter para inicializacion, Auth preparada, consultas, updates y canales Realtime.
- Python con `python-kasa` y `requests` para bridge local.
- Tests de widgets con `flutter_test` y repositorios fake.

## Estructura principal

- `lib/main.dart`: inicializa Supabase y monta `AnyaLinkApp`.
- `lib/core/env.dart`: configuracion fija de entorno y flags de demo.
- `lib/presentation`: paginas, providers, widgets y tema visual.
- `lib/infrastructure/supabase/device_repo.dart`: repositorio usado por la UI actual.
- `lib/domain` y `lib/data`: capa Clean Architecture parcialmente presente, no es la ruta principal de la UI actual.
- `bridge/`: scripts Python para Kasa/Tapo/HS300 y sincronizacion con Supabase.
- `test/`: pruebas de presencia, smoke test y toggle usando fake repo.

## Estado actual

- La app entra directo a `HomePage` porque `AuthGate` devuelve siempre el dashboard.
- La pantalla de login y providers de Auth existen, pero no controlan la navegacion actual.
- La fuente de datos principal es la tabla `devices`.
- `Env.useRealtime` esta en `false`, por lo que el flujo normal usa polling.
- `Env.addDemoTiles` esta en `true`, asi que se agregan tiles demo si no existen en Supabase.
- Hay documentacion historica amplia en `AnyaLink_Documentation.md`, pero no todo lo descrito alli esta implementado.

## Comandos basicos

```powershell
flutter pub get
flutter run
flutter test
```

Para el bridge Python, revisar primero `bridge/config.example.json` y los scripts dentro de `bridge/`. No ejecutar scripts con credenciales reales hasta mover secretos a configuracion local segura.
