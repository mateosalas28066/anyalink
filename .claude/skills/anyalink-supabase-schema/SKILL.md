---
name: anyalink-supabase-schema
description: Use when modifying Supabase tables, writing SQL migrations, or any DB access from the AnyaLink app or Node-RED. Defines canonical schema for devices, device_metrics, device_commands.
---

# AnyaLink — Schema canónico de Supabase

## Tabla `devices` (existente)

```sql
-- Ya existe en Supabase. No recrear.
create table devices (
  id          uuid primary key default gen_random_uuid(),
  alias       text not null unique,
  type        text,           -- 'light' | 'camera' | null → ícono genérico
  state       boolean not null default false,
  updated_at  timestamptz not null default now()
);
```

**Rows que deben existir para el MVP:**
- `alias = 'ESP32-Dispensador'`, `type = 'dispenser'`, `state = false`

## Tabla `device_metrics` (a crear en MVP)

```sql
create table device_metrics (
  id          bigserial primary key,
  device_id   uuid references devices(id) on delete cascade,
  metric_name text not null,   -- 'weight_g' | 'temp_c' | 'humidity_pct'
  value       numeric not null,
  recorded_at timestamptz not null default now()
);

create index on device_metrics (device_id, recorded_at desc);
```

## Tabla `device_commands` (a crear en MVP)

```sql
create table device_commands (
  id          bigserial primary key,
  device_id   uuid references devices(id) on delete cascade,
  command     text not null,       -- 'dispense' | 'set_state'
  payload     jsonb,               -- e.g. {"grams": 50}
  status      text not null default 'pending', -- 'pending' | 'ack' | 'error'
  created_at  timestamptz not null default now(),
  ack_at      timestamptz
);

create index on device_commands (device_id, status, created_at desc);
```

## Patrones de query en Dart (DeviceRepositorySupabase)

```dart
// Leer todos los dispositivos
final rows = await client
    .from('devices')
    .select('id, alias, type, state')
    .order('alias', ascending: true);

// Toggle por id (patrón real del repo)
await client
    .from('devices')
    .update({'state': newState, 'updated_at': DateTime.now().toUtc().toIso8601String()})
    .eq('id', id);

// Insertar métrica desde Node-RED (JS)
await supabase.from('device_metrics').insert({
  device_id: deviceId,
  metric_name: 'weight_g',
  value: 123.4
});
```

## Flags de comportamiento

- `Env.useRealtime` (en `lib/core/env.dart`) → `false` actualmente. Con `false`, la app usa `pollAll()` cada 900 ms.
- Para activar Realtime: cambiar a `true` y asegurarse de que el canal `public:devices-list` esté habilitado en Supabase.

## Reglas para migraciones

1. Siempre crear la migración como SQL explícito antes de aplicar.
2. Nunca modificar `devices` sin migración. Si hay datos de prueba, incluir INSERT en la migración.
3. Los `id` de `devices` son UUIDs estables — no regenerar si ya hay rows referenciadas en métricas.
4. RLS: por ahora disabled (MVP local). Antes de producción, habilitar con políticas por `auth.uid()`.
