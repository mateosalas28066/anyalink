alter table devices add column if not exists online boolean default false;
alter table devices add column if not exists last_seen timestamptz;

create table if not exists device_metrics (
  device_id uuid primary key references devices(id) on delete cascade,
  weight_g numeric,
  temperature_c numeric,
  humidity_pct numeric,
  updated_at timestamptz default now()
);

create table if not exists device_commands (
  id uuid primary key default gen_random_uuid(),
  device_id uuid references devices(id) on delete cascade,
  action text not null,
  payload jsonb,
  status text default 'pending',
  created_at timestamptz default now(),
  completed_at timestamptz
);

create index if not exists idx_device_commands_pending
  on device_commands (status) where status = 'pending';

insert into devices (alias, type, state)
values ('Dispensador', 'feeder', false)
on conflict do nothing;
