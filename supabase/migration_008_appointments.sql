-- Migración 008 — agenda de turnos: el cliente puede pedir un turno
-- desde su app, y el staff del taller gestiona/confirma la agenda.

create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references workshops(id) on delete cascade,
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  requested_by uuid references profiles(id),
  scheduled_at timestamptz not null,
  service_description text,
  status text not null default 'pending' check (status in ('pending','confirmed','completed','cancelled')),
  notes text,
  created_at timestamptz not null default now()
);

alter table appointments enable row level security;

-- El cliente ve y crea turnos para su propio vehículo
create policy "appointments_select_owner" on appointments for select
  using (vehicle_id in (select id from vehicles where owner_id = auth.uid()));

create policy "appointments_insert_owner" on appointments for insert
  with check (vehicle_id in (select id from vehicles where owner_id = auth.uid()));

-- El staff del taller ve/gestiona los turnos de su propio taller
create policy "appointments_select_staff" on appointments for select
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));

create policy "appointments_insert_staff" on appointments for insert
  with check (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));

create policy "appointments_update_staff" on appointments for update
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));
