create extension if not exists pgcrypto;

create or replace function public.hash_usuarios_password_bcrypt()
returns trigger
language plpgsql
as $$
begin
  if new.password_hash is null or btrim(new.password_hash) = '' then
    raise exception 'password_hash is required';
  end if;

  if left(new.password_hash, 2) = '$2' then
    return new;
  end if;

  if lower(new.password_hash) ~ '^[0-9a-f]{64}$' then
    new.password_hash := lower(new.password_hash);
    return new;
  end if;

  new.password_hash := crypt(new.password_hash, gen_salt('bf', 10));
  return new;
end;
$$;

drop trigger if exists trg_usuarios_hash_password on public.usuarios;
create trigger trg_usuarios_hash_password
before insert or update of password_hash on public.usuarios
for each row
execute function public.hash_usuarios_password_bcrypt();
