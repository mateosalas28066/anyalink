# AnyaLink

Panel de domotica minimalista para controlar y monitorear dispositivos del hogar.

La documentacion funcional para retomar el proyecto esta en:

- [docs/README.md](docs/README.md)

Resumen rapido:

- Flutter + Dart con Riverpod.
- Supabase para Auth preparada, tabla `devices` y cambios de estado.
- Bridge local Python para sincronizar Supabase con dispositivos TP-Link Kasa/Tapo.
- La app actual entra directo al dashboard; el login existe pero no esta conectado al gate.
