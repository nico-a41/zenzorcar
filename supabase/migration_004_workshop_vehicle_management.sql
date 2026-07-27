-- Migración 004 — permite que el staff del taller edite los datos de un
-- vehículo (marca/modelo/año/patente/km) y agregue vehículos nuevos a un
-- cliente existente, siempre y cuando el vehículo quede asignado a su
-- propio taller.

create policy "vehicles_update_by_workshop_staff" on vehicles for update
  using (
    workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller')
  );

create policy "vehicles_insert_by_workshop_staff" on vehicles for insert
  with check (
    workshop_id in (select workshop_id from profiles where id = auth.uid() and role = 'taller')
  );
