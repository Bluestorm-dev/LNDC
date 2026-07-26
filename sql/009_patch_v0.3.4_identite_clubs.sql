-- Le Nid des Champions — HOTFIX V0.3.4
-- La correction principale est dans l'Edge Function sync-football-data.
-- Après redéploiement, relancer « Bibliothèque Top 5 + logos ».

begin;
insert into public.app_settings(key,value)
values ('app_version','"0.3.4"'::jsonb)
on conflict (key) do update
set value=excluded.value, updated_at=now();
commit;

-- Diagnostic des appartenances Top 5 actuellement stockées.
select competition_code, competition_name, count(*) as clubs
from public.club_catalog_memberships
where competition_code in ('FL1','PL','PD','SA','BL1')
group by competition_code,competition_name
order by competition_code;

-- Détecte les mêmes lignes club utilisées dans plusieurs championnats nationaux.
-- Après la resynchronisation V0.3.4, cette requête doit normalement retourner 0 ligne.
select c.id,c.name,c.tla,c.external_provider,c.external_id,
       array_agg(m.competition_code order by m.competition_code) as competitions
from public.clubs c
join public.club_catalog_memberships m on m.club_id=c.id
where m.competition_code in ('FL1','PL','PD','SA','BL1')
group by c.id,c.name,c.tla,c.external_provider,c.external_id
having count(distinct m.competition_code) > 1
order by c.name;
