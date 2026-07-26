-- Migración 002 — permite que el staff de un taller vea el nombre de los
-- clientes cuyos vehículos están asignados a ese taller (para la pantalla
-- "Clientes" del panel de Héctor). Correr una sola vez en el SQL Editor,
-- después de haber corrido supabase/schema.sql.

create or replace function public.current_workshop_id()
returns uuid
language sql
security definer
stable
as $$
  select workshop_id from public.profiles where id = auth.uid() and role = 'taller';
$$;

create policy "profiles_select_workshop_clients" on profiles for select
  using (
    id in (select owner_id from vehicles where workshop_id = public.current_workshop_id())
  );
