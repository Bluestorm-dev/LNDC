-- Le Nid des Champions V1.0.1
-- LIVE C1, statistiques joueurs, fiches clubs, mouvement du Nid et rivalités.
begin;

-- =============================================================================
-- 1. Métadonnées enrichies des clubs (Football-Data)
-- =============================================================================
alter table public.clubs add column if not exists address text;
alter table public.clubs add column if not exists website text;
alter table public.clubs add column if not exists founded integer;
alter table public.clubs add column if not exists club_colors text;
alter table public.clubs add column if not exists coach_name text;
alter table public.clubs add column if not exists coach_nationality text;
alter table public.clubs add column if not exists squad jsonb not null default '[]'::jsonb;
alter table public.clubs add column if not exists provider_details_updated_at timestamptz;

-- =============================================================================
-- 2. Buteurs et discipline Ligue des champions
-- =============================================================================
create table if not exists public.ucl_player_stats (
  season_id uuid not null references public.seasons(id) on delete cascade,
  player_external_id bigint not null,
  player_name text not null,
  club_id uuid references public.clubs(id) on delete set null,
  position text,
  nationality text,
  played_matches integer not null default 0,
  goals integer not null default 0,
  assists integer not null default 0,
  penalties integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key(season_id,player_external_id)
);
create index if not exists ucl_player_stats_goals_idx on public.ucl_player_stats(season_id,goals desc,assists desc,played_matches);

create table if not exists public.ucl_discipline_stats (
  season_id uuid not null references public.seasons(id) on delete cascade,
  player_external_id bigint not null,
  player_name text not null,
  club_id uuid references public.clubs(id) on delete set null,
  yellow_cards integer not null default 0,
  red_cards integer not null default 0,
  yellow_red_cards integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key(season_id,player_external_id)
);
create index if not exists ucl_discipline_stats_cards_idx on public.ucl_discipline_stats(season_id,red_cards desc,yellow_red_cards desc,yellow_cards desc);

alter table public.ucl_player_stats enable row level security;
alter table public.ucl_discipline_stats enable row level security;
drop policy if exists ucl_player_stats_read on public.ucl_player_stats;
create policy ucl_player_stats_read on public.ucl_player_stats for select to authenticated using(true);
drop policy if exists ucl_discipline_stats_read on public.ucl_discipline_stats;
create policy ucl_discipline_stats_read on public.ucl_discipline_stats for select to authenticated using(true);
grant select on public.ucl_player_stats,public.ucl_discipline_stats to authenticated;

-- =============================================================================
-- 3. Mouvement du Nid : séries à zéro + détail casseroles/génie par joueur
-- =============================================================================
create or replace function public.get_nid_movement_v101(p_season_id uuid)
returns table(
  user_id uuid,
  zero_streak bigint,
  casserole_events bigint,
  casserole_points bigint,
  genius_events bigint,
  genius_points bigint
)
language sql
stable
security definer
set search_path=public
as $$
  with active_players as (
    select id as user_id from public.profiles where status='active'
  ), scored as (
    select p.user_id,coalesce(p.points,0)::numeric as points,m.kickoff_at,
      sum(case when coalesce(p.points,0)<>0 then 1 else 0 end)
        over(partition by p.user_id order by m.kickoff_at desc,m.id desc rows between unbounded preceding and current row) as nonzero_seen
    from public.predictions p
    join public.matches m on m.id=p.match_id
    where p.season_id=p_season_id
      and m.status='finished'
      and coalesce(m.is_test,false)=false
  ), zeros as (
    select user_id,count(*)::bigint as zero_streak
    from scored
    where nonzero_seen=0 and points=0
    group by user_id
  ), events as (
    select e.user_id,
      count(*) filter(where e.event_type='casserole')::bigint as casserole_events,
      coalesce(sum(e.points) filter(where e.event_type='casserole'),0)::bigint as casserole_points,
      count(*) filter(where e.event_type='genius')::bigint as genius_events,
      coalesce(sum(e.points) filter(where e.event_type='genius'),0)::bigint as genius_points
    from public.gamification_events e
    where e.season_id=p_season_id and e.is_test=false and e.event_type in('casserole','genius')
    group by e.user_id
  )
  select a.user_id,coalesce(z.zero_streak,0),coalesce(e.casserole_events,0),coalesce(e.casserole_points,0),coalesce(e.genius_events,0),coalesce(e.genius_points,0)
  from active_players a
  left join zeros z on z.user_id=a.user_id
  left join events e on e.user_id=a.user_id;
$$;
grant execute on function public.get_nid_movement_v101(uuid) to authenticated;

-- =============================================================================
-- 4. Rivalités : figer/finaliser automatiquement dès que les matchs évoluent
-- =============================================================================
create or replace function public.refresh_rivals_after_match_v101()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  if new.matchday_id is not null
     and coalesce(new.is_test,false)=false
     and (tg_op='INSERT'
          or new.status is distinct from old.status
          or new.home_score is distinct from old.home_score
          or new.away_score is distinct from old.away_score) then
    perform public.refresh_rival_duels_v060(new.matchday_id);
  end if;
  return new;
end;
$$;

drop trigger if exists matches_refresh_rivals_v101 on public.matches;
create trigger matches_refresh_rivals_v101
after insert or update of status,home_score,away_score on public.matches
for each row execute function public.refresh_rivals_after_match_v101();

-- Rattrapage immédiat des journées déjà terminées avant l'installation du correctif.
do $$
declare r record;
begin
  for r in
    select md.id
    from public.matchdays md
    where exists(select 1 from public.matches m where m.matchday_id=md.id and coalesce(m.is_test,false)=false)
      and not exists(select 1 from public.matches m where m.matchday_id=md.id and coalesce(m.is_test,false)=false and m.status not in('finished','cancelled'))
  loop
    perform public.refresh_rival_duels_v060(r.id);
  end loop;
end $$;

-- =============================================================================
-- 5. Version
-- =============================================================================
insert into public.app_settings(key,value)
values ('app_version','"1.0.1"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
