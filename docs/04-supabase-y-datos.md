# Supabase y Datos

## Tabla usada por la app

La app actual usa la tabla `devices`. Los campos requeridos por el codigo son:

- `id`: identificador del dispositivo. Se usa para updates y como clave de lista.
- `alias`: nombre visible y busqueda por alias.
- `type`: tipo para icono, color y separacion de camaras.
- `state`: booleano de encendido/apagado.
- `updated_at`: se actualiza al escribir estado.

## Lecturas

`DeviceRepositorySupabase.getAll()` consulta:

```text
devices select id, alias, type, state order by alias
```

`getByAlias(alias)` consulta un dispositivo por `alias` con limite 1.

## Escrituras

La UI principal escribe con `setStateById(id, newState)`:

```text
update devices
set state = newState, updated_at = now
where id = id
```

Tambien existe `setStateByAlias(alias, newState)`, usado por providers antiguos o flujos de dispositivo unico.

## Streams y polling

Realtime:

- `watchStateByAlias(alias)` escucha updates filtrados por alias.
- `watchAll()` escucha cualquier cambio en `devices` y vuelve a consultar la lista completa.

Polling:

- `pollStateByAlias()` consulta el estado por alias periodicamente.
- `pollAll()` consulta la lista completa periodicamente y emite si cambia longitud, id, alias o state.

El flag activo es `Env.useRealtime`. En el codigo actual esta apagado.

## Requisitos esperados de datos

Para que un dispositivo real aparezca y pueda cambiarse desde la app:

- Debe existir una fila en `devices`.
- `id` debe ser estable.
- `alias` debe coincidir con el alias esperado por la app o por el bridge.
- `state` debe ser booleano.
- `type` debe existir o aceptar valor nulo; si es nulo, la UI usa icono generico.

## Seguridad de configuracion

El codigo actual contiene credenciales y configuracion sensible hardcodeadas en Dart y Python. La documentacion nueva no reproduce esos valores. Antes de produccion, moverlos a variables de entorno, archivos locales ignorados por Git o configuracion segura de build.
