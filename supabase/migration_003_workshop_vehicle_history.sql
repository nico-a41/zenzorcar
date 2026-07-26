-- Migración 003 — permite que el staff de un taller vea el historial de
-- service y los diagnósticos de los vehículos asignados a su taller
-- (para el detalle de historial por vehículo en la pestaña "Clientes").
--
-- Mismo patrón que migration_002: una función plpgsql + security definer
-- que hace todo el trabajo adentro (chequeo de rol/taller + qué vehículos
-- son de ese taller), para no formar un ciclo de recursión entre tablas.

create or replace function public.workshop_vehicle_ids()
returns setof uuid
language plpgsql
security definer
stable
as $$
begin
  return query
    select v.id
    from public.vehicles v
    where v.workshop_id = (
      select p.workshop_id from public.profiles p where p.id = auth.uid() and p.role = 'taller'
    );
end;
$$;

create policy "service_history_select_workshop" on service_history for select
  using (vehicle_id in (select workshop_vehicle_ids()));

create policy "diagnostics_select_workshop" on diagnostics for select
  using (vehicle_id in (select workshop_vehicle_ids()));
