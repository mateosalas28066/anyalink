# Arquitectura

## Vista general

El flujo esperado es:

```text
Flutter UI -> Riverpod providers -> Supabase devices -> Bridge Python -> Hardware TP-Link
```

La app escribe cambios de estado en Supabase. El bridge local observa Supabase y el hardware, alinea ambos lados y actualiza la base de datos cuando el cambio nace en el dispositivo fisico.

## Capas Flutter

- `core`: configuracion global. Hoy contiene `Env` con URL de Supabase, alias principal, flags de realtime/demo y ruta del asset de camara.
- `presentation`: capa activa de la app. Incluye `HomePage`, `AuthGate`, `LoginPage`, providers Riverpod, widgets de tarjetas y tema por tipo de dispositivo.
- `infrastructure/supabase`: repositorio real usado por la UI para leer y escribir `devices`.
- `domain`: entidad `Device`, contrato `DevicesRepository` y use cases. Esta capa existe pero no es el camino principal usado por `HomePage`.
- `data`: datasource y repository implementation alineados con Clean Architecture. Tambien estan presentes, pero la UI actual usa el repositorio de `infrastructure`.

## Providers principales

- `supabaseClientProvider`: expone `Supabase.instance.client`.
- `deviceRepoProvider`: crea `DeviceRepositorySupabase`.
- `devicesListProvider`: obtiene la lista de dispositivos por Realtime o polling segun `Env.useRealtime`.
- `toggleByIdProvider`: accion por familia para cambiar estado por id, aunque `HomePage` actualmente llama directo al repositorio.
- `optimisticOverridesProvider`: guarda estados temporales por id para que la UI responda antes de que vuelva el dato desde Supabase.
- `authSessionProvider` y `authActionsProvider`: existen para Supabase Auth, pero el gate actual no los usa.

## Flujo de pantalla principal

1. `main.dart` inicializa Supabase.
2. `AnyaLinkApp` monta `AuthGate`.
3. `AuthGate` devuelve `HomePage` directamente.
4. `HomePage` escucha `devicesListProvider`.
5. La lista se separa entre camaras y otros dispositivos.
6. Cada dispositivo no-camara se pinta como `DeviceTile`.
7. Al tocar un tile o switch, se aplica override optimista y se escribe el nuevo estado por id.
8. La lista se invalida para refrescar desde Supabase.

## Realtime vs polling

El repositorio soporta canales Realtime con `onPostgresChanges`, pero el flag actual `Env.useRealtime = false` hace que los providers usen polling:

- `pollStateByAlias`: consulta un dispositivo cada intervalo.
- `pollAll`: consulta la lista completa y emite solo si detecta cambios relevantes.

Esto simplifica estabilidad local cuando Realtime no esta configurado o no es confiable.
