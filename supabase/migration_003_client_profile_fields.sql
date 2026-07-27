-- Migración 003 — campos adicionales de perfil para gestión de clientes
-- (teléfono para WhatsApp, fecha de nacimiento para saludos de cumpleaños)
-- y permiso para que el staff del taller pueda editarlos.

alter table profiles add column if not exists phone text;
alter table profiles add column if not exists birthday date;

-- El staff de taller ya puede LEER los perfiles de sus clientes
-- (migración 002). Esto agrega el permiso para poder ACTUALIZARLOS
-- (nombre, teléfono, cumpleaños) desde la pantalla de edición.
create policy "profiles_update_workshop_clients" on profiles for update
  using (id in (select workshop_client_ids()));
