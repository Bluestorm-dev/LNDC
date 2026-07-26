-- Le Nid des Champions — V0.1.1
-- Inscriptions : Supabase crée le compte, le Super Admin autorise l'accès au Nid.
-- À exécuter dans Supabase > SQL Editor avec le rôle POSTGRES / rôle par défaut.

begin;

-- -----------------------------------------------------------------------------
-- 1. Statuts de compte
-- -----------------------------------------------------------------------------
alter table public.profiles drop constraint if exists profiles_status_check;
alter table public.profiles
  add constraint profiles_status_check
  check (status in ('pending','active','rejected','suspended','deleted'));

alter table public.profiles alter column status set default 'pending';

-- Les futurs comptes arrivent toujours en attente.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_first_name text;
begin
  v_username := nullif(trim(new.raw_user_meta_data ->> 'username'), '');
  v_first_name := nullif(trim(new.raw_user_meta_data ->> 'first_name'), '');

  if v_username is null then
    raise exception 'Le pseudo est obligatoire.';
  end if;

  insert into public.profiles (id, username, status)
  values (new.id, v_username, 'pending');

  insert into public.profile_private (user_id, first_name)
  values (new.id, v_first_name);

  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. Garde d'accès active
-- -----------------------------------------------------------------------------
create or replace function public.is_active_member()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid() and status = 'active'
  );
$$;

-- Les demandes pending/rejected ne sont pas exposées publiquement.
drop policy if exists profiles_public_read on public.profiles;
create policy profiles_public_read on public.profiles
for select
using (
  status = 'active'
  or id = auth.uid()
  or public.is_admin()
);

-- Un compte non validé ne peut pas modifier son profil ni envoyer de pronostic.
drop policy if exists profiles_own_update on public.profiles;
create policy profiles_own_update on public.profiles
for update to authenticated
using (id = auth.uid() and public.is_active_member())
with check (id = auth.uid() and public.is_active_member());

drop policy if exists predictions_insert_own on public.predictions;
create policy predictions_insert_own on public.predictions
for insert to authenticated
with check (user_id = auth.uid() and public.is_active_member());

drop policy if exists predictions_update_own on public.predictions;
create policy predictions_update_own on public.predictions
for update to authenticated
using (user_id = auth.uid() and public.is_active_member())
with check (user_id = auth.uid() and public.is_active_member());

-- -----------------------------------------------------------------------------
-- 3. File des demandes — SUPER ADMIN uniquement
-- -----------------------------------------------------------------------------
create or replace function public.admin_list_registration_requests()
returns table (
  user_id uuid,
  username text,
  first_name text,
  email text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au Super Admin.';
  end if;

  return query
  select
    p.id,
    p.username::text,
    pp.first_name,
    u.email::text,
    p.status,
    p.created_at
  from public.profiles p
  left join public.profile_private pp on pp.user_id = p.id
  left join auth.users u on u.id = p.id
  where p.status in ('pending','rejected')
  order by
    case when p.status = 'pending' then 0 else 1 end,
    p.created_at asc;
end;
$$;

create or replace function public.admin_review_registration(
  p_user_id uuid,
  p_decision text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old public.profiles%rowtype;
  v_new_status text;
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au Super Admin.';
  end if;

  v_new_status := case lower(trim(p_decision))
    when 'approve' then 'active'
    when 'active' then 'active'
    when 'reject' then 'rejected'
    when 'rejected' then 'rejected'
    else null
  end;

  if v_new_status is null then
    raise exception 'Décision invalide.';
  end if;

  select * into v_old from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'Compte introuvable.';
  end if;

  if v_old.role = 'super_admin' and v_new_status <> 'active' then
    raise exception 'Impossible de refuser le Super Admin principal.';
  end if;

  update public.profiles
  set status = v_new_status,
      updated_at = now()
  where id = p_user_id;

  insert into public.audit_logs(actor_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(),
    case when v_new_status = 'active' then 'registration_approved' else 'registration_rejected' end,
    'profile',
    p_user_id::text,
    jsonb_build_object('status', v_old.status, 'username', v_old.username::text),
    jsonb_build_object('status', v_new_status, 'username', v_old.username::text)
  );

  return v_new_status;
end;
$$;

revoke all on function public.admin_list_registration_requests() from public, anon;
revoke all on function public.admin_review_registration(uuid,text) from public, anon;
grant execute on function public.admin_list_registration_requests() to authenticated;
grant execute on function public.admin_review_registration(uuid,text) to authenticated;
grant execute on function public.is_active_member() to authenticated;

-- Version applicative
insert into public.app_settings(key,value)
values ('app_version','"0.1.1"'::jsonb)
on conflict (key) do update set value=excluded.value, updated_at=now();

commit;
