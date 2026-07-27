-- Le Nid des Champions — V0.6.7
-- Laboratoire Super Admin : calendrier TEST configurable.

begin;

alter table public.matchdays add column if not exists is_test boolean not null default false;
alter table public.matchdays add column if not exists test_enabled boolean not null default true;

alter table public.matches add column if not exists is_test boolean not null default false;
alter table public.matches add column if not exists test_enabled boolean not null default true;
alter table public.matches add column if not exists venue_country text;

create index if not exists matchdays_test_idx on public.matchdays(season_id,is_test,test_enabled,number);
create index if not exists matches_test_idx on public.matches(season_id,is_test,test_enabled,kickoff_at);

-- Les matchs TEST ne ferment jamais les choix champion et ne font jamais
-- avancer artificiellement la phase de ligue.
create or replace function public.champion_first_close_at_v040(p_season_id uuid)
returns timestamptz language sql stable security definer set search_path=public as $$
  select min(m.kickoff_at)
  from public.matches m
  join public.competition_phases ph on ph.id=m.phase_id
  where m.season_id=p_season_id
    and ph.code='LEAGUE'
    and m.status not in ('cancelled','postponed')
    and coalesce(m.is_test,false)=false;
$$;

create or replace function public.league_phase_finished_v040(p_season_id uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.matches m join public.competition_phases ph on ph.id=m.phase_id
    where m.season_id=p_season_id and ph.code='LEAGUE' and m.status<>'cancelled' and coalesce(m.is_test,false)=false
  ) and not exists(
    select 1 from public.matches m join public.competition_phases ph on ph.id=m.phase_id
    where m.season_id=p_season_id and ph.code='LEAGUE' and m.status not in ('finished','cancelled') and coalesce(m.is_test,false)=false
  );
$$;

-- Les matchs TEST restent pronostiquables mais sont exclus des classements officiels.
create or replace function public.get_leaderboard_v030(
  p_season_id uuid,
  p_scope text default 'general',
  p_matchday_id uuid default null,
  p_evening_date date default null,
  p_include_live boolean default true
)
returns table (
  rank bigint,
  previous_rank bigint,
  variation bigint,
  user_id uuid,
  username text,
  avatar_key text,
  club_heart text,
  points numeric,
  official_points numeric,
  exact_scores bigint,
  good_differences bigint,
  good_results bigint,
  played bigint,
  average numeric,
  precision_pct numeric,
  above_gap numeric,
  below_gap numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with params as (
    select coalesce(
      p_evening_date,
      (
        select max((m.kickoff_at at time zone 'Europe/Paris')::date)
        from public.matches m
        where m.season_id = p_season_id
          and m.status in ('live','finished')
          and coalesce(m.is_test,false)=false
      ),
      (now() at time zone 'Europe/Paris')::date
    ) as reference_date
  ),
  scope_matches as (
    select m.*
    from public.matches m, params pa
    where m.season_id = p_season_id
      and coalesce(m.is_test,false)=false
      and (
        p_scope = 'general'
        or (p_scope = 'matchday' and p_matchday_id is not null and m.matchday_id = p_matchday_id)
        or (p_scope = 'evening' and (m.kickoff_at at time zone 'Europe/Paris')::date = coalesce(p_evening_date, pa.reference_date))
      )
  ),
  stats as (
    select
      pr.id as user_id,
      pr.username::text as username,
      pr.avatar_key,
      pr.club_heart,
      coalesce(sum(
        case
          when m.id is null or p.id is null then 0
          when m.status = 'finished' then p.points
          when p_include_live and m.status = 'live' and m.home_score is not null and m.away_score is not null
            then public.score_prediction_values_v030(p_season_id,p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier)
          else 0
        end
      ),0)::numeric as points,
      coalesce(sum(case when m.status='finished' then p.points else 0 end),0)::numeric as official_points,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
          and p.home_score=m.home_score and p.away_score=m.away_score
      ) as exact_scores,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
          and not (p.home_score=m.home_score and p.away_score=m.away_score)
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
          and (p.home_score-p.away_score)=(m.home_score-m.away_score)
      ) as good_differences,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
      ) as good_results,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
      ) as played
    from public.profiles pr
    left join public.predictions p
      on p.user_id = pr.id and p.season_id = p_season_id
    left join scope_matches m on m.id = p.match_id
    where pr.status = 'active'
    group by pr.id,pr.username,pr.avatar_key,pr.club_heart
  ),
  scored as (
    select
      s.*,
      case when played>0 then points/played else 0 end::numeric as average,
      case when played>0 then round((good_results::numeric*100)/played,1) else 0 end::numeric as precision_pct
    from stats s
  ),
  current_ranked as (
    select
      row_number() over(
        order by points desc, exact_scores desc, average desc, good_differences desc, played desc, username asc
      ) as rank,
      *
    from scored
  ),
  baseline_stats as (
    select
      pr.id as user_id,
      pr.username::text as username,
      coalesce(sum(case when m.status='finished' then p.points else 0 end),0)::numeric as points,
      count(*) filter (
        where m.status='finished' and p.id is not null
          and p.home_score=m.home_score and p.away_score=m.away_score
      ) as exact_scores,
      count(*) filter (
        where m.status='finished' and p.id is not null
          and not (p.home_score=m.home_score and p.away_score=m.away_score)
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
          and (p.home_score-p.away_score)=(m.home_score-m.away_score)
      ) as good_differences,
      count(*) filter (where m.status='finished' and p.id is not null) as played
    from public.profiles pr
    left join public.predictions p
      on p.user_id=pr.id and p.season_id=p_season_id
    left join public.matches m
      on m.id=p.match_id
      and m.season_id=p_season_id
      and coalesce(m.is_test,false)=false
      and (m.kickoff_at at time zone 'Europe/Paris')::date < (select reference_date from params)
    where pr.status='active'
    group by pr.id,pr.username
  ),
  baseline_scored as (
    select *, case when played>0 then points/played else 0 end::numeric as average
    from baseline_stats
  ),
  baseline_ranked as (
    select user_id,
      row_number() over(
        order by points desc, exact_scores desc, average desc, good_differences desc, played desc, username asc
      ) as previous_rank
    from baseline_scored
  ),
  joined as (
    select
      c.*,
      case when p_scope='general' then b.previous_rank else null end as previous_rank
    from current_ranked c
    left join baseline_ranked b on b.user_id=c.user_id
  ),
  neighbors as (
    select
      j.*,
      lag(points) over(order by rank) as above_points,
      lead(points) over(order by rank) as below_points
    from joined j
  )
  select
    rank,
    previous_rank,
    case when previous_rank is null then 0 else previous_rank-rank end as variation,
    user_id,username,avatar_key,club_heart,
    points,official_points,exact_scores,good_differences,good_results,played,
    round(average,2) as average,
    precision_pct,
    case when above_points is null then null else above_points-points end as above_gap,
    case when below_points is null then null else points-below_points end as below_gap
  from neighbors
  order by rank;
$$;

grant execute on function public.get_leaderboard_v030(uuid,text,uuid,date,boolean) to authenticated;

create or replace function public.get_collective_stats_v030(
  p_season_id uuid,
  p_scope text default 'general',
  p_matchday_id uuid default null,
  p_evening_date date default null
)
returns table (
  total_predictions bigint,
  home_picks bigint,
  draw_picks bigint,
  away_picks bigint,
  top_scores jsonb,
  exact_predictions bigint,
  settled_predictions bigint,
  reliability_pct numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with reference as (
    select coalesce(
      p_evening_date,
      (
        select max((m.kickoff_at at time zone 'Europe/Paris')::date)
        from public.matches m
        where m.season_id=p_season_id and m.status in ('live','finished') and coalesce(m.is_test,false)=false
      ),
      (now() at time zone 'Europe/Paris')::date
    ) as evening_date
  ),
  scoped_matches as (
    select m.*
    from public.matches m, reference r
    where m.season_id=p_season_id
      and coalesce(m.is_test,false)=false
      and (
        p_scope='general'
        or (p_scope='matchday' and p_matchday_id is not null and m.matchday_id=p_matchday_id)
        or (p_scope='evening' and (m.kickoff_at at time zone 'Europe/Paris')::date=coalesce(p_evening_date,r.evening_date))
      )
      and (m.status in ('live','finished') or (m.status in ('scheduled','postponed') and m.kickoff_at<=now()))
  ),
  locked_predictions as (
    select p.*,m.status,m.home_score as result_home,m.away_score as result_away
    from public.predictions p
    join scoped_matches m on m.id=p.match_id
    join public.profiles pr on pr.id=p.user_id and pr.status='active'
  ),
  score_counts as (
    select home_score,away_score,count(*)::bigint as n
    from locked_predictions
    group by home_score,away_score
    order by n desc,home_score asc,away_score asc
    limit 5
  ),
  aggregates as (
    select
      count(*)::bigint as total_predictions,
      count(*) filter(where home_score>away_score)::bigint as home_picks,
      count(*) filter(where home_score=away_score)::bigint as draw_picks,
      count(*) filter(where home_score<away_score)::bigint as away_picks,
      count(*) filter(
        where status in ('live','finished') and result_home is not null and result_away is not null
          and home_score=result_home and away_score=result_away
      )::bigint as exact_predictions,
      count(*) filter(
        where status in ('live','finished') and result_home is not null and result_away is not null
      )::bigint as settled_predictions,
      count(*) filter(
        where status in ('live','finished') and result_home is not null and result_away is not null
          and sign(home_score-away_score)=sign(result_home-result_away)
      )::bigint as correct_results
    from locked_predictions
  )
  select
    a.total_predictions,a.home_picks,a.draw_picks,a.away_picks,
    coalesce((select jsonb_agg(jsonb_build_object('score',home_score::text || '–' || away_score::text,'count',n) order by n desc,home_score,away_score) from score_counts),'[]'::jsonb) as top_scores,
    a.exact_predictions,a.settled_predictions,
    case when a.settled_predictions>0 then round((a.correct_results::numeric*100)/a.settled_predictions,1) else 0 end::numeric as reliability_pct
  from aggregates a;
$$;

grant execute on function public.get_collective_stats_v030(uuid,text,uuid,date) to authenticated;

-- Classement Teams : les rencontres TEST ne rapportent jamais de points officiels.
create or replace function public.get_team_leaderboard_v050(p_season_id uuid,p_matchday_id uuid default null)
returns table(
  team_id uuid,team_name text,logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  current_members bigint,contributors bigint,total_points numeric,average_points numeric,top3_points numeric,rank_average bigint,rank_top3 bigint
)
language sql stable security definer set search_path=public as $$
with match_points as (
  select tm.team_id,p.user_id,sum(p.points)::numeric as pts
  from public.predictions p
  join public.matches m on m.id=p.match_id
  left join public.matchdays md on md.id=m.matchday_id
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=p.user_id
    and m.kickoff_at>=tm.joined_at and (tm.left_at is null or m.kickoff_at<tm.left_at)
  where p.season_id=p_season_id and m.status='finished' and coalesce(m.is_test,false)=false
    and (p_matchday_id is null or m.matchday_id=p_matchday_id)
    and (md.number is null or md.number<>0)
  group by tm.team_id,p.user_id
), qualifier_points as (
  select tm.team_id,tp.user_id,sum(case when kt.status='finished' and kt.qualified_club_id=tp.qualified_club_id then case when tp.pick_timing='early' then kt.qualifier_bonus_early else kt.qualifier_bonus_late end else 0 end)::numeric as pts
  from public.tie_predictions tp
  join public.knockout_ties kt on kt.id=tp.tie_id
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=tp.user_id
    and (case when kt.is_single_match then kt.leg1_kickoff_at else kt.leg2_kickoff_at end)>=tm.joined_at
    and (tm.left_at is null or (case when kt.is_single_match then kt.leg1_kickoff_at else kt.leg2_kickoff_at end)<tm.left_at)
  where tp.season_id=p_season_id and p_matchday_id is null
  group by tm.team_id,tp.user_id
), champion_points as (
  select tm.team_id,cp.user_id,sum(cp.points)::numeric as pts
  from public.champion_predictions cp
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=cp.user_id
    and coalesce(cp.locked_at,cp.updated_at)>=tm.joined_at and (tm.left_at is null or coalesce(cp.locked_at,cp.updated_at)<tm.left_at)
  where cp.season_id=p_season_id and p_matchday_id is null and cp.points<>0
  group by tm.team_id,cp.user_id
), user_team_points as (
  select team_id,user_id,sum(pts)::numeric as pts from (
    select * from match_points union all select * from qualifier_points union all select * from champion_points
  ) q group by team_id,user_id
), active_zero as (
  select tm.team_id,tm.user_id,0::numeric pts from public.team_memberships tm join public.teams t on t.id=tm.team_id
  where tm.season_id=p_season_id and tm.left_at is null and t.status='active'
), players as (
  select team_id,user_id,sum(pts)::numeric pts from (
    select * from user_team_points union all select * from active_zero
  ) q group by team_id,user_id
), team_stats as (
  select t.id team_id,t.name team_name,t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    (select count(*) from public.team_memberships x where x.team_id=t.id and x.left_at is null)::bigint current_members,
    count(p.user_id)::bigint contributors,coalesce(sum(p.pts),0)::numeric total_points,coalesce(avg(p.pts),0)::numeric average_points,
    coalesce((select sum(z.pts) from (select p2.pts from players p2 where p2.team_id=t.id order by p2.pts desc limit 3) z),0)::numeric top3_points
  from public.teams t left join players p on p.team_id=t.id
  where t.season_id=p_season_id and t.status='active'
  group by t.id
), ranked as (
  select s.*,
    row_number() over(order by average_points desc,top3_points desc,total_points desc,team_name)::bigint rank_average,
    row_number() over(order by top3_points desc,average_points desc,total_points desc,team_name)::bigint rank_top3
  from team_stats s
)
select * from ranked order by rank_average;
$$;

-- =============================================================================
-- 8. RLS + privilèges
-- =============================================================================
alter table public.teams enable row level security;
alter table public.team_memberships enable row level security;
alter table public.team_join_requests enable row level security;
alter table public.team_invites enable row level security;
alter table public.team_events enable row level security;

drop policy if exists teams_read on public.teams;
create policy teams_read on public.teams for select using(true);

drop policy if exists team_memberships_read on public.team_memberships;
create policy team_memberships_read on public.team_memberships for select using(true);

drop policy if exists team_requests_own_or_captain on public.team_join_requests;
create policy team_requests_own_or_captain on public.team_join_requests for select to authenticated using(
  user_id=auth.uid() or public.is_admin() or public.is_team_captain_v050(team_id)
);

drop policy if exists team_invites_captain_read on public.team_invites;
create policy team_invites_captain_read on public.team_invites for select to authenticated using(public.is_admin() or public.is_team_captain_v050(team_id));

drop policy if exists team_events_read on public.team_events;
create policy team_events_read on public.team_events for select using(true);

revoke all on public.teams,public.team_memberships,public.team_join_requests,public.team_invites,public.team_events from anon,authenticated;
grant select on public.teams,public.team_memberships,public.team_events to anon,authenticated;
grant select on public.team_join_requests,public.team_invites to authenticated;

grant execute on function public.is_team_captain_v050(uuid) to authenticated;
grant execute on function public.current_team_id_v050(uuid,uuid) to authenticated;
grant execute on function public.create_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.update_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.join_public_team_v050(uuid) to authenticated;
grant execute on function public.request_team_join_v050(uuid) to authenticated;
grant execute on function public.process_team_join_request_v050(uuid,boolean) to authenticated;
grant execute on function public.regenerate_team_invite_v050(uuid) to authenticated;
grant execute on function public.join_team_by_code_v050(uuid,text) to authenticated;
grant execute on function public.leave_team_v050(uuid) to authenticated;
grant execute on function public.kick_team_member_v050(uuid,uuid) to authenticated;
grant execute on function public.transfer_team_captain_v050(uuid,uuid) to authenticated;
grant execute on function public.dissolve_team_v050(uuid) to authenticated;
grant execute on function public.get_team_directory_v050(uuid) to anon,authenticated;
grant execute on function public.get_my_team_v050(uuid) to authenticated;
grant execute on function public.get_team_member_directory_v050(uuid) to authenticated;
grant execute on function public.get_team_members_v050(uuid) to authenticated;
grant execute on function public.get_team_history_v050(uuid) to authenticated;
grant execute on function public.get_team_join_requests_v050(uuid) to authenticated;
grant execute on function public.get_team_active_invite_v050(uuid) to authenticated;
grant execute on function public.get_team_leaderboard_v050(uuid,uuid) to anon,authenticated;

create or replace function public.admin_create_test_schedule_v067(p_season_id uuid,p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_phase uuid;
  v_base_number integer;
  v_day jsonb;
  v_match jsonb;
  v_day_id uuid;
  v_day_idx integer:=0;
  v_match_count integer:=0;
  v_first timestamptz;
  v_last timestamptz;
  v_home uuid;
  v_away uuid;
  v_kickoff timestamptz;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_season_id is null then raise exception 'Saison manquante.'; end if;
  if jsonb_typeof(p_payload->'days')<>'array' or jsonb_array_length(p_payload->'days')<>2 then
    raise exception 'Le laboratoire attend exactement 2 journées TEST.';
  end if;

  select id into v_phase from public.competition_phases where season_id=p_season_id and code='LEAGUE' limit 1;

  -- Remplace uniquement l'ancien calendrier TEST V0.6.7.
  delete from public.matches where season_id=p_season_id and is_test=true;
  delete from public.matchdays where season_id=p_season_id and is_test=true;

  select coalesce(max(number),0) into v_base_number from public.matchdays where season_id=p_season_id;

  for v_day in select value from jsonb_array_elements(p_payload->'days') loop
    v_day_idx:=v_day_idx+1;
    if jsonb_typeof(v_day->'matches')<>'array' or jsonb_array_length(v_day->'matches')<1 then
      raise exception 'La journée TEST % doit contenir au moins un match.',v_day_idx;
    end if;

    select min((x->>'kickoff_at')::timestamptz),max((x->>'kickoff_at')::timestamptz)
      into v_first,v_last from jsonb_array_elements(v_day->'matches') x;

    insert into public.matchdays(season_id,phase_id,number,name,starts_at,ends_at,is_test,test_enabled)
    values(p_season_id,v_phase,v_base_number+v_day_idx,coalesce(nullif(v_day->>'name',''),'TEST — Journée '||v_day_idx),v_first,v_last,true,true)
    returning id into v_day_id;

    for v_match in select value from jsonb_array_elements(v_day->'matches') loop
      v_home:=(v_match->>'home_club_id')::uuid;
      v_away:=(v_match->>'away_club_id')::uuid;
      v_kickoff:=(v_match->>'kickoff_at')::timestamptz;
      if v_home=v_away then raise exception 'Une équipe ne peut pas jouer contre elle-même.'; end if;
      if not exists(select 1 from public.clubs where id=v_home and is_active=true) then raise exception 'Club domicile invalide.'; end if;
      if not exists(select 1 from public.clubs where id=v_away and is_active=true) then raise exception 'Club extérieur invalide.'; end if;

      insert into public.matches(season_id,phase_id,matchday_id,home_club_id,away_club_id,kickoff_at,stadium,venue_country,status,data_source,is_test,test_enabled)
      values(p_season_id,v_phase,v_day_id,v_home,v_away,v_kickoff,nullif(v_match->>'stadium',''),nullif(v_match->>'country',''),'scheduled','manual',true,true);
      v_match_count:=v_match_count+1;
    end loop;
  end loop;

  return jsonb_build_object('ok',true,'days_created',2,'matches_created',v_match_count);
end;
$$;

grant execute on function public.admin_create_test_schedule_v067(uuid,jsonb) to authenticated;

create or replace function public.admin_set_test_schedule_enabled_v067(p_season_id uuid,p_enabled boolean)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_count integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  update public.matchdays set test_enabled=p_enabled where season_id=p_season_id and is_test=true;
  if not p_enabled then
    update public.notifications n
       set push_requested=false,deleted_at=coalesce(deleted_at,now())
     where n.season_id=p_season_id
       and n.push_sent_at is null
       and n.deleted_at is null
       and (n.payload->>'matchday_id') in (select id::text from public.matchdays where season_id=p_season_id and is_test=true);
  end if;
  update public.matches
     set test_enabled=p_enabled,
         status=case when p_enabled then 'scheduled' else 'cancelled' end,
         home_score=null,
         away_score=null,
         went_to_extra_time=false,
         penalties_home=null,
         penalties_away=null,
         winner_club_id=null,
         updated_at=now()
   where season_id=p_season_id and is_test=true;
  get diagnostics v_count=row_count;
  return jsonb_build_object('ok',true,'enabled',p_enabled,'matches_updated',v_count);
end;
$$;

grant execute on function public.admin_set_test_schedule_enabled_v067(uuid,boolean) to authenticated;

create or replace function public.admin_delete_test_schedule_v067(p_season_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_matches integer:=0;v_days integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  delete from public.matches where season_id=p_season_id and is_test=true;
  get diagnostics v_matches=row_count;
  delete from public.matchdays where season_id=p_season_id and is_test=true;
  get diagnostics v_days=row_count;
  return jsonb_build_object('ok',true,'matches_deleted',v_matches,'matchdays_deleted',v_days);
end;
$$;

grant execute on function public.admin_delete_test_schedule_v067(uuid) to authenticated;

create or replace function public.admin_delete_all_matches_v067(p_season_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_matches integer:=0;v_days integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  -- Supprime absolument toutes les rencontres de la saison : cela inclut les
  -- anciens matchs de test initiaux même s'ils n'avaient pas encore is_test=true.
  delete from public.matches where season_id=p_season_id;
  get diagnostics v_matches=row_count;
  delete from public.matchdays where season_id=p_season_id;
  get diagnostics v_days=row_count;
  return jsonb_build_object('ok',true,'matches_deleted',v_matches,'matchdays_deleted',v_days);
end;
$$;

grant execute on function public.admin_delete_all_matches_v067(uuid) to authenticated;

insert into public.app_settings(key,value)
values('app_version','"0.6.7"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

commit;

select key,value from public.app_settings where key='app_version';
