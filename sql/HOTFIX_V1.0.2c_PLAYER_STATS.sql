-- ============================================================
-- Le Nid des Champions V1.0.2c
-- Nettoyage des doublons joueurs C1 + version applicative
-- ============================================================

begin;

-- Clé de comparaison volontairement simple : casse + espaces.
-- On ne fusionne que lorsque les lignes n'ont pas plusieurs clubs connus.
create or replace function public.lndc_player_key_v102c(p_name text)
returns text
language sql
immutable
as $$
  select lower(regexp_replace(trim(coalesce(p_name,'')), '\s+', ' ', 'g'));
$$;

-- ---------------------------------------------------------------------------
-- 1. Buteurs : fusionne les doublons d'un même joueur.
--    Les totaux sont pris au MAX, jamais additionnés, pour ne pas doubler
--    les statistiques API + saisie manuelle.
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
  v_keep bigint;
begin
  for r in
    select season_id, public.lndc_player_key_v102c(player_name) as player_key
    from public.ucl_player_stats
    group by season_id, public.lndc_player_key_v102c(player_name)
    having count(*) > 1 and count(distinct club_id) <= 1
  loop
    select s.player_external_id
      into v_keep
    from public.ucl_player_stats s
    where s.season_id=r.season_id
      and public.lndc_player_key_v102c(s.player_name)=r.player_key
    order by (s.club_id is not null) desc,
             (s.player_external_id > 0) desc,
             s.updated_at desc nulls last
    limit 1;

    update public.ucl_player_stats k
    set club_id = coalesce((
          select s.club_id from public.ucl_player_stats s
          where s.season_id=r.season_id
            and public.lndc_player_key_v102c(s.player_name)=r.player_key
            and s.club_id is not null
          order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
          limit 1
        ),k.club_id),
        position = coalesce((
          select nullif(trim(s.position),'') from public.ucl_player_stats s
          where s.season_id=r.season_id
            and public.lndc_player_key_v102c(s.player_name)=r.player_key
            and nullif(trim(s.position),'') is not null
          order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
          limit 1
        ),k.position),
        nationality = coalesce((
          select nullif(trim(s.nationality),'') from public.ucl_player_stats s
          where s.season_id=r.season_id
            and public.lndc_player_key_v102c(s.player_name)=r.player_key
            and nullif(trim(s.nationality),'') is not null
          order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
          limit 1
        ),k.nationality),
        played_matches = (select max(s.played_matches) from public.ucl_player_stats s where s.season_id=r.season_id and public.lndc_player_key_v102c(s.player_name)=r.player_key),
        goals = (select max(s.goals) from public.ucl_player_stats s where s.season_id=r.season_id and public.lndc_player_key_v102c(s.player_name)=r.player_key),
        assists = (select max(s.assists) from public.ucl_player_stats s where s.season_id=r.season_id and public.lndc_player_key_v102c(s.player_name)=r.player_key),
        penalties = (select max(s.penalties) from public.ucl_player_stats s where s.season_id=r.season_id and public.lndc_player_key_v102c(s.player_name)=r.player_key),
        updated_at = now()
    where k.season_id=r.season_id and k.player_external_id=v_keep;

    delete from public.ucl_player_stats s
    where s.season_id=r.season_id
      and public.lndc_player_key_v102c(s.player_name)=r.player_key
      and s.player_external_id<>v_keep;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 2. Discipline : même nettoyage pour les cartons.
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
  v_keep bigint;
begin
  for r in
    select season_id, public.lndc_player_key_v102c(player_name) as player_key
    from public.ucl_discipline_stats
    group by season_id, public.lndc_player_key_v102c(player_name)
    having count(*) > 1 and count(distinct club_id) <= 1
  loop
    select s.player_external_id
      into v_keep
    from public.ucl_discipline_stats s
    where s.season_id=r.season_id
      and public.lndc_player_key_v102c(s.player_name)=r.player_key
    order by (s.club_id is not null) desc,
             (s.player_external_id > 0) desc,
             s.updated_at desc nulls last
    limit 1;

    update public.ucl_discipline_stats k
    set club_id = coalesce((
          select s.club_id from public.ucl_discipline_stats s
          where s.season_id=r.season_id
            and public.lndc_player_key_v102c(s.player_name)=r.player_key
            and s.club_id is not null
          order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
          limit 1
        ),k.club_id),
        yellow_cards = (select max(s.yellow_cards) from public.ucl_discipline_stats s where s.season_id=r.season_id and public.lndc_player_key_v102c(s.player_name)=r.player_key),
        yellow_red_cards = (select max(s.yellow_red_cards) from public.ucl_discipline_stats s where s.season_id=r.season_id and public.lndc_player_key_v102c(s.player_name)=r.player_key),
        red_cards = (select max(s.red_cards) from public.ucl_discipline_stats s where s.season_id=r.season_id and public.lndc_player_key_v102c(s.player_name)=r.player_key),
        updated_at = now()
    where k.season_id=r.season_id and k.player_external_id=v_keep;

    delete from public.ucl_discipline_stats s
    where s.season_id=r.season_id
      and public.lndc_player_key_v102c(s.player_name)=r.player_key
      and s.player_external_id<>v_keep;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3. Récupère le club connu depuis l'autre table lorsque c'est sans ambiguïté.
-- ---------------------------------------------------------------------------
with club_map as (
  select season_id, public.lndc_player_key_v102c(player_name) player_key, min(club_id::text)::uuid club_id
  from public.ucl_discipline_stats
  where club_id is not null
  group by season_id, public.lndc_player_key_v102c(player_name)
  having count(distinct club_id)=1
)
update public.ucl_player_stats s
set club_id=m.club_id, updated_at=now()
from club_map m
where s.club_id is null
  and s.season_id=m.season_id
  and public.lndc_player_key_v102c(s.player_name)=m.player_key;

with club_map as (
  select season_id, public.lndc_player_key_v102c(player_name) player_key, min(club_id::text)::uuid club_id
  from public.ucl_player_stats
  where club_id is not null
  group by season_id, public.lndc_player_key_v102c(player_name)
  having count(distinct club_id)=1
)
update public.ucl_discipline_stats s
set club_id=m.club_id, updated_at=now()
from club_map m
where s.club_id is null
  and s.season_id=m.season_id
  and public.lndc_player_key_v102c(s.player_name)=m.player_key;

insert into public.app_settings(key,value,updated_at)
values('app_version','"1.0.2c"'::jsonb,now())
on conflict(key) do update set value=excluded.value,updated_at=now();

commit;

-- Contrôles : ces deux listes doivent idéalement être vides.
select min(player_name) as joueur, count(*) as doublons
from public.ucl_player_stats
group by season_id, public.lndc_player_key_v102c(player_name)
having count(*)>1
order by count(*) desc, min(player_name);

select min(player_name) as joueur, count(*) as doublons
from public.ucl_discipline_stats
group by season_id, public.lndc_player_key_v102c(player_name)
having count(*)>1
order by count(*) desc, min(player_name);
