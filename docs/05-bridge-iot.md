# Bridge IoT

## Rol del bridge

El bridge Python conecta Supabase con dispositivos TP-Link en la red local. Su objetivo es mantener sincronizados tres estados:

```text
App Flutter <-> Supabase devices <-> Bridge Python <-> Hardware TP-Link
```

Si la app cambia `devices.state`, el bridge aplica ese cambio al hardware. Si el hardware cambia manualmente, el bridge actualiza Supabase.

## Bridge unificado

`bridge/anyalink_bridge_unified.py` cubre:

- Bombillo Kasa con alias de base de datos `Lampara`.
- Regleta Tapo/HS300 con hijos como `Fuente` y `Ventilador`.
- Descubrimiento por MAC/IP.
- Reconexion si falla el update del dispositivo.
- Anti-rebote para evitar ecos entre DB y hardware.
- Ventana de comando pendiente despues de aplicar un cambio.

Este script contiene configuracion sensible hardcodeada y debe migrarse antes de usarse como base estable.

## Scripts auxiliares

- `discover_kasa.py`: descubre dispositivos Kasa en la LAN.
- `test_kasa.py`, `status.py`, `on.py`, `off.py`: pruebas rapidas contra bombillo por IP.
- `kasa_bridge_alias.py`: bridge anterior por alias.
- `kasa_bridge_mac.py`: bridge anterior por MAC.
- `hs300_cli.py`: CLI para listar y controlar hijos de una regleta HS300/Tapo usando credenciales desde variables de entorno.
- `config.example.json`: ejemplo de configuracion local esperada.

## Sincronizacion bidireccional

El bridge compara el estado anterior de Supabase y hardware:

- Si cambia Supabase, aplica DB -> hardware.
- Si cambia hardware y no hay comando pendiente, aplica hardware -> DB.
- Si hay desalineacion sin cambio claro, prefiere alinear hardware con DB.

El cooldown evita escribir varias veces por el mismo cambio.

## Riesgos operativos

- Requiere que el equipo que corre el bridge este en la misma red que los dispositivos.
- IPs pueden cambiar; por eso existen hints y redescubrimiento por MAC.
- Las credenciales actuales no deben permanecer en codigo.
- El bridge no esta integrado al ciclo de vida de la app Flutter; se ejecuta como proceso separado.
- Si Supabase, red local o discovery fallan, la UI puede mostrar estados atrasados hasta el siguiente polling.
