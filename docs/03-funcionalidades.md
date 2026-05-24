# Funcionalidades

## Dashboard de dispositivos

La pantalla principal es `HomePage`. Muestra el titulo `AnyaLink`, una seccion `Dispositivos`, tiles compactos para dispositivos comunes y una tarjeta de camara cuando existe algun dispositivo con tipo `camera`.

La UI usa Material 3, fondo gris claro, tarjetas blancas y acentos por tipo de dispositivo.

## Lista desde Supabase

`devicesListProvider` obtiene dispositivos desde `DeviceRepositorySupabase.getAll()`. La consulta selecciona:

- `id`
- `alias`
- `type`
- `state`

La lista se ordena por `alias`. Si no hay dispositivos, la pantalla muestra un estado vacio.

## Toggle con estado optimista

Al cambiar un dispositivo:

1. `HomePage` calcula el valor actual visible.
2. `optimisticOverridesProvider` guarda el valor opuesto para ese id.
3. Si es dispositivo demo, solo agenda limpiar el override.
4. Si es dispositivo real, llama `setStateById`.
5. Si el update funciona, invalida `devicesListProvider` y muestra un SnackBar.
6. Si falla, remueve el override y muestra el error.

Esto hace que el switch responda rapido aunque Supabase o el bridge tarden en confirmar.

## Camara y tiles demo

`Env.addDemoTiles = true` agrega dispositivos demo cuando no aparecen por alias en Supabase:

- Ventilador
- Comedero
- Fuente
- Camara

Los ids demo empiezan por `demo-`. No se escriben en Supabase. La camara usa `CameraCard` y carga `Env.cameraAsset`.

## Auth preparada, no activa

Existen:

- `LoginPage` con email y credenciales de acceso.
- `authSessionProvider` para escuchar la sesion de Supabase.
- `authActionsProvider` con sign in, sign up y sign out.

Pero `AuthGate` actualmente devuelve siempre `HomePage`. Por eso la app no exige login aunque exista la pantalla.

## Realtime o polling

`Env.useRealtime` decide el modo:

- `true`: usa canales Realtime de Supabase.
- `false`: usa polling desde `DeviceRepositorySupabase`.

El valor actual es `false`, asi que el comportamiento esperado en desarrollo es polling.
