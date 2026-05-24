# Supabase y Datos

## Tablas del MVP

### `devices`

Una fila por dispositivo. Columnas usadas por el código:

- `id` (uuid, PK)
- `alias` (text) — nombre visible y key de búsqueda.
- `type` (text) — `feeder`, `camera`, `light`, etc. Determina el widget.
- `state` (bool) — encendido/apagado (para tipos simples).
- `online` (bool, default `false`) — escrito por Node-RED desde el topic `.../online` (retained).
- `last_seen` (timestamptz) — actualizado con cada heartbeat online/offline.
- `updated_at` (timestamptz) — escrito al cambiar `state`.

### `device_metrics`

Último valor por dispositivo (un row por `device_id`):

- `device_id` (uuid, PK, FK → `devices.id` cascade delete)
- `weight_g` (numeric)
- `temperature_c` (numeric)
- `humidity_pct` (numeric)
- `updated_at` (timestamptz)

Patrón de escritura: Node-RED hace `POST /rest/v1/device_metrics` con header `Prefer: resolution=merge-duplicates` (upsert por PK).

### `device_commands`

Cola de comandos pendientes:

- `id` (uuid, PK, default `gen_random_uuid()`)
- `device_id` (uuid, FK → `devices.id` cascade delete)
- `action` (text) — por ahora solo `'dispense'`.
- `payload` (jsonb) — ej. `{"portion": 1}`.
- `status` (text, default `'pending'`) — `pending` → `sent` → `done`.
- `created_at`, `completed_at` (timestamptz)

Índice parcial: `(status) WHERE status = 'pending'` para acelerar el poll de Node-RED.

## Migración

Ver `supabase/migrations/0001_mvp_esp32.sql`. Aplicar desde el SQL Editor del dashboard o vía plugin Supabase de Claude Code. Seed: inserta `('Dispensador', 'feeder', false)`.

## Row Level Security

Para el MVP las tres tablas corren con **RLS desactivada** (LAN doméstica, proyecto académico). Esto significa:

- La anon key puede leer/escribir todo. Es el mismo nivel de exposición que ya tenía `devices` antes del MVP.
- Si en el futuro se activa RLS, Node-RED debe seguir usando service_role (no afectado por RLS) y la app debe agregar `user_id` y policies por usuario.

Comando para activar/desactivar:

```sql
alter table devices         disable row level security;
alter table device_metrics  disable row level security;
alter table device_commands disable row level security;
```

## Lecturas de la app

`DeviceRepositorySupabase.getAll()`:

```text
devices select id, alias, type, state, online, last_seen order by alias
```

`DeviceRepositorySupabase.getByAlias(alias)`: ídem con `eq.alias`, limit 1.

`watchMetrics(deviceId)`: yield inicial vía SELECT + canal Realtime `public:device_metrics-{deviceId}` filtrado por `device_id`.

`watchAll()`: SELECT inicial + canal Realtime `public:devices-list` (cualquier cambio dispara refetch completo).

## Escrituras de la app

- `setStateById(id, newState)` → `update devices set state, updated_at where id = id`.
- `sendCommand(deviceId, action, payload)` → `insert into device_commands (...) values (...)`.

## Credenciales

- **anon key**: en `lib/core/env.dart` (gitignored). Usada por la app Flutter.
- **service_role key**: hardcodeada en `infra/node-red/flows.json` para el MVP. Es la única forma simple de que Node-RED bypassee RLS si en el futuro se activa.
- Las dos viven solo en local — la app es desktop/mobile sin distribución pública aún.
