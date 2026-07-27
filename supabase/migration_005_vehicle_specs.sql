-- Migración 005 — ficha técnica de referencia (capacidades de aceite y
-- códigos de filtro por marca/modelo). Es una base de datos técnica
-- compartida, no específica de un cliente: cualquier cuenta con rol
-- "taller" puede consultarla y mantenerla actualizada.

create table if not exists vehicle_specs (
  id uuid primary key default gen_random_uuid(),
  brand text not null,
  model text not null,
  year_from int,
  year_to int,
  oil_capacity_liters numeric,
  oil_viscosity text,
  oil_filter_code text,
  air_filter_code text,
  cabin_filter_code text,
  notes text,
  created_at timestamptz not null default now()
);

alter table vehicle_specs enable row level security;

create policy "vehicle_specs_select_taller" on vehicle_specs for select
  using (exists (select 1 from profiles where id = auth.uid() and role = 'taller'));

create policy "vehicle_specs_insert_taller" on vehicle_specs for insert
  with check (exists (select 1 from profiles where id = auth.uid() and role = 'taller'));

create policy "vehicle_specs_update_taller" on vehicle_specs for update
  using (exists (select 1 from profiles where id = auth.uid() and role = 'taller'));
