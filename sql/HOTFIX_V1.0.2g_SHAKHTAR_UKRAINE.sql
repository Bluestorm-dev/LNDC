-- Le Nid des Champions V1.0.2g
-- Shakhtar Donetsk : pays Ukraine pour le drapeau et les fiches club.

begin;

update public.clubs
set country = 'Ukraine',
    updated_at = now()
where lower(coalesce(name,'')) like '%shakhtar%'
   or lower(coalesce(short_name,'')) like '%shakhtar%'
   or lower(coalesce(name,'')) like '%chakhtar%'
   or lower(coalesce(short_name,'')) like '%chakhtar%';

insert into public.app_settings(key,value,updated_at)
values('app_version','"1.0.2g"'::jsonb,now())
on conflict(key) do update
set value=excluded.value,
    updated_at=now();

commit;
