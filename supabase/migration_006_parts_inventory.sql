-- Migración 006 — stock de repuestos por taller, con umbral de alerta
-- de stock crítico.

create table if not exists parts_inventory (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references workshops(id) on delete cascade,
  name text not null,
  code text,
  category text,
  unit text not null default 'unidad',
  stock_quantity int not null default 0,
  min_stock_alert int not null default 1,
  created_at timestamptz not null default now()
);

alter table parts_inventory enable row level security;

create policy "parts_inventory_select_staff" on parts_inventory for select
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));

create policy "parts_inventory_insert_staff" on parts_inventory for insert
  with check (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));

create policy "parts_inventory_update_staff" on parts_inventory for update
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));

create policy "parts_inventory_delete_staff" on parts_inventory for delete
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));
