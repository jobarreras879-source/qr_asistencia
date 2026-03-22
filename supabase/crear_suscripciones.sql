-- Tabla de Configuración de Suscripción
create table if not exists public.config_suscripcion (
  id integer primary key default 1,
  plan varchar(50) not null,
  limite_usuarios integer not null,
  activa boolean default true,
  fecha_expiracion timestamp with time zone
);

-- Insertar el plan de prueba por defecto (5 usuarios)
insert into public.config_suscripcion (id, plan, limite_usuarios)
values (1, 'Básico (Prueba)', 5)
on conflict (id) do update set 
  plan = excluded.plan,
  limite_usuarios = excluded.limite_usuarios;

-- Desactivar RLS para que la app pueda leerla sin problemas
alter table public.config_suscripcion disable row level security;
