-- Le Nid des Champions V1.0.2b
-- Détails publics Casseroles / Génie pour l'accueil, le Musée et les fiches joueur.

begin;

create or replace function public.get_gamification_event_details_v102a(p_season_id uuid)
returns table(
  event_id uuid,
  user_id uuid,
  event_type text,
  subtype text,
  severity text,
  points integer,
  match_id uuid,
  matchday_id uuid,
  matchday_name text,
  kickoff_at timestamptz,
  home_club_id uuid,
  home_name text,
  away_club_id uuid,
  away_name text,
  result_home integer,
  result_away integer,
  prediction_home integer,
  prediction_away integer,
  prediction_points numeric,
  labels jsonb,
  metadata jsonb,
  created_at timestamptz
)
language sql
stable
security definer
set search_path=public
as $$
  select
    e.id as event_id,
    e.user_id,
    e.event_type,
    e.subtype,
    e.severity,
    e.points,
    e.match_id,
    e.matchday_id,
    md.name as matchday_name,
    m.kickoff_at,
    m.home_club_id,
    coalesce(hc.short_name,hc.name,'Domicile') as home_name,
    m.away_club_id,
    coalesce(ac.short_name,ac.name,'Extérieur') as away_name,
    m.home_score::integer as result_home,
    m.away_score::integer as result_away,
    p.home_score::integer as prediction_home,
    p.away_score::integer as prediction_away,
    p.points::numeric as prediction_points,
    e.labels,
    e.metadata,
    e.created_at
  from public.gamification_events e
  left join public.matches m on m.id=e.match_id
  left join public.matchdays md on md.id=e.matchday_id
  left join public.clubs hc on hc.id=m.home_club_id
  left join public.clubs ac on ac.id=m.away_club_id
  left join public.predictions p on p.match_id=e.match_id and p.user_id=e.user_id
  where e.season_id=p_season_id
    and e.is_test=false
    and e.is_public=true
    and e.event_type in ('casserole','genius')
  order by e.created_at desc
  limit 300;
$$;

grant execute on function public.get_gamification_event_details_v102a(uuid) to authenticated;

insert into public.app_settings(key,value,updated_at)
values('app_version','"1.0.2b"'::jsonb,now())
on conflict(key) do update
set value=excluded.value,updated_at=now();

commit;
