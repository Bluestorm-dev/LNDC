-- Le Nid des Champions — V0.3.1
-- Correctifs : rattachement des clubs TEST aux clubs Football-Data + version.
-- La navigation automatique A -> B -> match suivant est côté client (assets/js/app.js).

begin;

-- Les 8 clubs de la Journée TEST existaient avant l'import Football-Data.
-- Quand le club canonique importé existe, on rattache tous les matchs à ce club
-- puis on masque l'ancien doublon. Les pronostics ne sont pas touchés : ils sont
-- liés aux matchs, pas aux clubs.
do $$
declare
  r record;
  v_legacy uuid;
  v_canonical uuid;
begin
  for r in
    select *
    from (values
      ('Paris SG'::text,       524::bigint),
      ('Bayern Munich'::text,    5::bigint),
      ('Real Madrid'::text,      86::bigint),
      ('Arsenal'::text,          57::bigint),
      ('Inter Milan'::text,     108::bigint),
      ('FC Barcelone'::text,     81::bigint),
      ('Liverpool'::text,        64::bigint),
      ('Dortmund'::text,          4::bigint)
    ) as legacy(legacy_name, external_id)
  loop
    v_legacy := null;
    v_canonical := null;

    select c.id
      into v_canonical
    from public.clubs c
    where c.external_provider = 'football-data'
      and c.external_id = r.external_id
    limit 1;

    if v_canonical is null then
      continue;
    end if;

    select c.id
      into v_legacy
    from public.clubs c
    where c.name = r.legacy_name
      and c.id <> v_canonical
    limit 1;

    if v_legacy is null then
      continue;
    end if;

    update public.matches
       set home_club_id = v_canonical,
           updated_at = now()
     where home_club_id = v_legacy;

    update public.matches
       set away_club_id = v_canonical,
           updated_at = now()
     where away_club_id = v_legacy;

    update public.clubs
       set is_active = false,
           updated_at = now()
     where id = v_legacy;
  end loop;
end $$;

insert into public.app_settings(key,value)
values ('app_version','"0.3.1"'::jsonb)
on conflict (key) do update
set value=excluded.value, updated_at=now();

commit;

-- Contrôle lisible dans le SQL Editor : après synchronisation Football-Data,
-- les 8 lignes suivantes doivent pointer vers external_provider='football-data'.
select
  c.name,
  c.short_name,
  c.external_provider,
  c.external_id,
  coalesce(c.logo_storage_path, c.logo_source_url, c.logo_url) as logo
from public.clubs c
where c.external_provider='football-data'
  and c.external_id in (524,5,86,57,108,81,64,4)
order by c.name;
