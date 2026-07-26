-- À exécuter UNE FOIS dans Supabase > SQL Editor avec le rôle postgres.
-- Ne jamais accorder UPDATE(role,status) au rôle authenticated.

begin;

update public.profiles
set role = 'super_admin',
    status = 'active',
    updated_at = now()
where lower(username::text) = lower('Parkaf');

-- La requête doit modifier exactement le compte Parkaf.
do $$
begin
  if not exists (
    select 1 from public.profiles
    where lower(username::text)=lower('Parkaf')
      and role='super_admin'
      and status='active'
  ) then
    raise exception 'Parkaf n''a pas pu être promu. Vérifie le pseudo et le rôle SQL utilisé.';
  end if;
end;
$$;

commit;

select id, username, role, status, created_at
from public.profiles
where lower(username::text)=lower('Parkaf');
