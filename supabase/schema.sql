-- Lubri-admin — esquema inicial + Row Level Security
-- Pegar y correr esto completo en Supabase → SQL Editor (proyecto nuevo, una sola vez).

-- ============================================================
-- TABLAS
-- ============================================================

create table if not exists workshops (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'cliente' check (role in ('cliente','taller')),
  full_name text,
  workshop_id uuid references workshops(id),
  created_at timestamptz not null default now()
);

create table if not exists vehicles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  workshop_id uuid references workshops(id),
  plate text not null,
  brand text,
  model text,
  year int,
  km int default 0,
  created_at timestamptz not null default now()
);

create table if not exists diagnostics (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  dtc_code text not null,
  severity text not null check (severity in ('optimo','atencion','urgente')),
  label text not null,
  human_explanation text,
  source text not null default 'live' check (source in ('live','manual')),
  created_at timestamptz not null default now()
);

create table if not exists service_history (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  description text not null,
  on_time boolean not null default true,
  performed_at timestamptz not null default now()
);

create table if not exists badges (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  badge_key text not null,
  earned_at timestamptz not null default now(),
  unique (profile_id, badge_key)
);

create table if not exists workshop_faults (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references workshops(id) on delete cascade,
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  dtc_code text not null,
  label text not null,
  human_explanation text,
  severity text not null check (severity in ('atencion','urgente')),
  part_needed text,
  status text not null default 'pending' check (status in ('pending','prepared')),
  created_at timestamptz not null default now()
);

-- ============================================================
-- Perfil automático al registrarse (rol por defecto: 'cliente')
-- ============================================================

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, role, full_name)
  values (new.id, 'cliente', new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Nota: para convertir una cuenta en "taller", hacerlo manualmente y a mano
-- desde el SQL Editor (nunca dejar que el usuario se auto-asigne el rol):
--   update profiles set role = 'taller', workshop_id = '<uuid-del-taller>'
--   where id = '<uuid-del-usuario>';

-- ============================================================
-- ROW LEVEL SECURITY — activado en todas las tablas
-- ============================================================

alter table workshops enable row level security;
alter table profiles enable row level security;
alter table vehicles enable row level security;
alter table diagnostics enable row level security;
alter table service_history enable row level security;
alter table badges enable row level security;
alter table workshop_faults enable row level security;

-- profiles: cada usuario ve y edita solo su propia fila
create policy "profiles_select_own" on profiles for select
  using (id = auth.uid());
create policy "profiles_update_own" on profiles for update
  using (id = auth.uid());

-- workshops: el staff del taller puede ver su propio taller
create policy "workshops_select_staff" on workshops for select
  using (id in (select workshop_id from profiles where id = auth.uid()));

-- vehicles: el dueño ve el suyo; el staff del taller ve los vehículos asignados a su taller
create policy "vehicles_select" on vehicles for select
  using (
    owner_id = auth.uid()
    or workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller')
  );
create policy "vehicles_insert_own" on vehicles for insert
  with check (owner_id = auth.uid());
create policy "vehicles_update_own" on vehicles for update
  using (owner_id = auth.uid());

-- diagnostics: visibles/insertables solo para el dueño del vehículo
create policy "diagnostics_select_owner" on diagnostics for select
  using (vehicle_id in (select id from vehicles where owner_id = auth.uid()));
create policy "diagnostics_insert_owner" on diagnostics for insert
  with check (vehicle_id in (select id from vehicles where owner_id = auth.uid()));

-- service_history: idem
create policy "service_history_select_owner" on service_history for select
  using (vehicle_id in (select id from vehicles where owner_id = auth.uid()));
create policy "service_history_insert_owner" on service_history for insert
  with check (vehicle_id in (select id from vehicles where owner_id = auth.uid()));

-- badges: cada usuario ve/gana solo las suyas
create policy "badges_select_own" on badges for select
  using (profile_id = auth.uid());
create policy "badges_insert_own" on badges for insert
  with check (profile_id = auth.uid());

-- workshop_faults: el dueño del vehículo puede reportar una falla a su taller;
-- el staff del taller ve y actualiza (ej. "Preparar repuestos") solo las de su taller
create policy "workshop_faults_select_staff" on workshop_faults for select
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));
create policy "workshop_faults_update_staff" on workshop_faults for update
  using (workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller'));
create policy "workshop_faults_insert_owner" on workshop_faults for insert
  with check (vehicle_id in (select id from vehicles where owner_id = auth.uid()));
