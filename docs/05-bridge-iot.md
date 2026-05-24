# Bridge IoT (TP-Link Kasa/Tapo) — CONGELADO en el MVP

> **Estado**: este bridge Python para TP-Link Kasa/Tapo está **congelado** mientras dura el MVP. No se modifica. La integración IoT activa del MVP es el ESP32 vía MQTT (ver `firmware/anyalink_node/README.md` y `infra/README.md`).

## Por qué quedó congelado

El alcance del MVP es el dispensador ESP32 (servo + HX711 + DHT22) y su integración Supabase. Mantener en paralelo el bridge TP-Link multiplica superficie de fallo y trabajo de mantenimiento. El bridge sigue siendo funcional, pero no se actualiza ni se prueba en el MVP.

## Qué hace el bridge cuando se usa

Conecta Supabase con dispositivos TP-Link en la red local:

```text
App Flutter ↔ Supabase devices ↔ Bridge Python ↔ Hardware TP-Link
```

- Si la app cambia `devices.state`, el bridge aplica al hardware.
- Si el hardware cambia manualmente, el bridge actualiza Supabase.

## Bridge unificado

`bridge/anyalink_bridge_unified.py` (basado en `anyalink_bridge_unified.example.py`) cubre:

- Bombillo Kasa con alias DB `Lampara`.
- Regleta Tapo/HS300 con hijos como `Fuente` y `Ventilador`.
- Descubrimiento por MAC/IP.
- Reconexión si falla `update()` del dispositivo.
- Anti-rebote para evitar ecos entre DB y hardware.
- Ventana de comando pendiente después de aplicar un cambio.

Configuración via env vars (ver el ejemplo). El servicio no está integrado en el ciclo de vida de la app Flutter; corre como proceso separado.

## Scripts auxiliares

- `discover_kasa.py`, `test_kasa.py`, `status.py`, `on.py`, `off.py`: utilidades rápidas.
- `hs300_cli.py`: CLI para listar y controlar hijos de regleta HS300/Tapo.
- `config.example.json`: forma esperada de configuración local.

## Cuándo reactivarlo (post-MVP)

Cuando se quiera volver a integrar plugs TP-Link al ecosistema, el plan razonable es:

1. Mover su sincronización a Node-RED via MQTT, eliminando el proceso Python separado.
2. Modelar cada plug como un device más con su propio `type` y semántica de `state`.
3. Mover credenciales fuera del repo.

Mientras tanto, la fuente de verdad para el MVP es el ESP32.
