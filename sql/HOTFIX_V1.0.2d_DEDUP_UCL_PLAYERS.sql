-- ============================================================
-- Le Nid des Champions V1.0.2d
-- Dédoublonnage définitif des classements C1 existants
-- ============================================================

begin;

create or replace function public.lndc_player_key_v102d(p_name text)
returns text
language sql
immutable
as $$
  select lower(
    regexp_replace(
      regexp_replace(trim(coalesce(p_name,'')), '[’''`´_-]+', ' ', 'g'),
      '\s+', ' ', 'g'
    )
  );
$$;

-- Buteurs : on fusionne par saison + nom, même si un ancien patch a associé
-- deux club_id différents. L'identifiant provider positif est prioritaire.
do $$
declare
  r record;
  v_keep bigint;
begin
  for r in
    select season_id, public.lndc_player_key_v102d(player_name) as player_key
    from public.ucl_player_stats
    group by season_id, public.lndc_player_key_v102d(player_name)
    having count(*) > 1
  loop
    select s.player_external_id
    into v_keep
    from public.ucl_player_stats s
    where s.season_id=r.season_id
      and public.lndc_player_key_v102d(s.player_name)=r.player_key
    order by (s.player_external_id > 0) desc,
             (s.club_id is not null) desc,
             s.updated_at desc nulls last
    limit 1;

    update public.ucl_player_stats k
    set
      player_name = coalesce((
        select nullif(trim(s.player_name),'')
        from public.ucl_player_stats s
        where s.season_id=r.season_id
          and public.lndc_player_key_v102d(s.player_name)=r.player_key
        order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
        limit 1
      ), k.player_name),
      club_id = coalesce((
        select s.club_id
        from public.ucl_player_stats s
        where s.season_id=r.season_id
          and public.lndc_player_key_v102d(s.player_name)=r.player_key
          and s.club_id is not null
        order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
        limit 1
      ), k.club_id),
      position = coalesce((
        select nullif(trim(s.position),'')
        from public.ucl_player_stats s
        where s.season_id=r.season_id
          and public.lndc_player_key_v102d(s.player_name)=r.player_key
          and nullif(trim(s.position),'') is not null
        order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
        limit 1
      ), k.position),
      nationality = coalesce((
        select nullif(trim(s.nationality),'')
        from public.ucl_player_stats s
        where s.season_id=r.season_id
          and public.lndc_player_key_v102d(s.player_name)=r.player_key
          and nullif(trim(s.nationality),'') is not null
        order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
        limit 1
      ), k.nationality),
      played_matches = (select max(coalesce(s.played_matches,0)) from public.ucl_player_stats s where s.season_id=r.season_id and public.lndc_player_key_v102d(s.player_name)=r.player_key),
      goals = (select max(coalesce(s.goals,0)) from public.ucl_player_stats s where s.season_id=r.season_id and public.lndc_player_key_v102d(s.player_name)=r.player_key),
      assists = (select max(coalesce(s.assists,0)) from public.ucl_player_stats s where s.season_id=r.season_id and public.lndc_player_key_v102d(s.player_name)=r.player_key),
      penalties = (select max(coalesce(s.penalties,0)) from public.ucl_player_stats s where s.season_id=r.season_id and public.lndc_player_key_v102d(s.player_name)=r.player_key),
      updated_at = now()
    where k.season_id=r.season_id and k.player_external_id=v_keep;

    delete from public.ucl_player_stats s
    where s.season_id=r.season_id
      and public.lndc_player_key_v102d(s.player_name)=r.player_key
      and s.player_external_id<>v_keep;
  end loop;
end $$;

-- Cartons : même principe, sans additionner les doublons.
do $$
declare
  r record;
  v_keep bigint;
begin
  for r in
    select season_id, public.lndc_player_key_v102d(player_name) as player_key
    from public.ucl_discipline_stats
    group by season_id, public.lndc_player_key_v102d(player_name)
    having count(*) > 1
  loop
    select s.player_external_id
    into v_keep
    from public.ucl_discipline_stats s
    where s.season_id=r.season_id
      and public.lndc_player_key_v102d(s.player_name)=r.player_key
    order by (s.player_external_id > 0) desc,
             (s.club_id is not null) desc,
             s.updated_at desc nulls last
    limit 1;

    update public.ucl_discipline_stats k
    set
      player_name = coalesce((
        select nullif(trim(s.player_name),'')
        from public.ucl_discipline_stats s
        where s.season_id=r.season_id
          and public.lndc_player_key_v102d(s.player_name)=r.player_key
        order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
        limit 1
      ), k.player_name),
      club_id = coalesce((
        select s.club_id
        from public.ucl_discipline_stats s
        where s.season_id=r.season_id
          and public.lndc_player_key_v102d(s.player_name)=r.player_key
          and s.club_id is not null
        order by (s.player_external_id > 0) desc, s.updated_at desc nulls last
        limit 1
      ), k.club_id),
      yellow_cards = (select max(coalesce(s.yellow_cards,0)) from public.ucl_discipline_stats s where s.season_id=r.season_id and public.lndc_player_key_v102d(s.player_name)=r.player_key),
      yellow_red_cards = (select max(coalesce(s.yellow_red_cards,0)) from public.ucl_discipline_stats s where s.season_id=r.season_id and public.lndc_player_key_v102d(s.player_name)=r.player_key),
      red_cards = (select max(coalesce(s.red_cards,0)) from public.ucl_discipline_stats s where s.season_id=r.season_id and public.lndc_player_key_v102d(s.player_name)=r.player_key),
      updated_at = now()
    where k.season_id=r.season_id and k.player_external_id=v_keep;

    delete from public.ucl_discipline_stats s
    where s.season_id=r.season_id
      and public.lndc_player_key_v102d(s.player_name)=r.player_key
      and s.player_external_id<>v_keep;
  end loop;
end $$;

-- Rattachement croisé du club si une des deux tables le connaît.
with club_map as (
  select season_id, public.lndc_player_key_v102d(player_name) player_key,
         (array_agg(club_id order by (player_external_id > 0) desc, updated_at desc nulls last) filter (where club_id is not null))[1] club_id
  from public.ucl_discipline_stats
  group by season_id, public.lndc_player_key_v102d(player_name)
)
update public.ucl_player_stats s
set club_id=m.club_id, updated_at=now()
from club_map m
where s.club_id is null and m.club_id is not null
  and s.season_id=m.season_id
  and public.lndc_player_key_v102d(s.player_name)=m.player_key;

with club_map as (
  select season_id, public.lndc_player_key_v102d(player_name) player_key,
         (array_agg(club_id order by (player_external_id > 0) desc, updated_at desc nulls last) filter (where club_id is not null))[1] club_id
  from public.ucl_player_stats
  group by season_id, public.lndc_player_key_v102d(player_name)
)
update public.ucl_discipline_stats s
set club_id=m.club_id, updated_at=now()
from club_map m
where s.club_id is null and m.club_id is not null
  and s.season_id=m.season_id
  and public.lndc_player_key_v102d(s.player_name)=m.player_key;

insert into public.app_settings(key,value,updated_at)
values('app_version','"1.0.2d"'::jsonb,now())
on conflict(key) do update set value=excluded.value,updated_at=now();

commit;

-- Ces deux contrôles doivent retourner 0 ligne.
select public.lndc_player_key_v102d(player_name) joueur, count(*) doublons
from public.ucl_player_stats
group by season_id, public.lndc_player_key_v102d(player_name)
having count(*)>1;

select public.lndc_player_key_v102d(player_name) joueur, count(*) doublons
from public.ucl_discipline_stats
group by season_id, public.lndc_player_key_v102d(player_name)
having count(*)>1;
