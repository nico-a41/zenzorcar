-- Migración 007 — catálogo de servicios pre-programados con precio fijo,
-- por taller (para presupuestar y gestionar órdenes rápido).

create table if not exists service_catalog (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references workshops(id) on delete cascade,
  name text not null,
  description text,
  price numeric not null default 0,
  estimated_minutes int,
  created_at timestamptz not null default now()
);

alter table service_catalog enable row level security;

create policy "service_catalog_select_staff" on service_catalog for select
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));

create policy "service_catalog_insert_staff" on service_catalog for insert
  with check (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));

create policy "service_catalog_update_staff" on service_catalog for update
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));

create policy "service_catalog_delete_staff" on service_catalog for delete
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));
