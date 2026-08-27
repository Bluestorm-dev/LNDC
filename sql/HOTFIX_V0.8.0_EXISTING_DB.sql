-- =============================================================================
-- LE NID DES CHAMPIONS — PATCH V0.8.0
-- Soirées européennes + Hibou solitaire + Centre Ligue des champions
-- =============================================================================

create table if not exists public.ucl_matches (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  external_provider text not null default 'football-data',
  external_match_id bigint not null,
  competition_code text not null default 'CL',
  stage text,
  matchday integer,
  kickoff_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled','live','finished','postponed','cancelled','suspended')),
  home_club_id uuid not null references public.clubs(id),
  away_club_id uuid not null references public.clubs(id),
  home_score integer,
  away_score integer,
  half_time_home integer,
  half_time_away integer,
  winner text,
  venue text,
  last_synced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(external_provider,external_match_id),
  check (home_club_id <> away_club_id)
);
create index if not exists ucl_matches_season_kickoff_idx on public.ucl_matches(season_id,kickoff_at);
create index if not exists ucl_matches_season_stage_idx on public.ucl_matches(season_id,stage);

create table if not exists public.ucl_standings (
  season_id uuid not null references public.seasons(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  position integer not null,
  played_games integer not null default 0,
  won integer not null default 0,
  draw integer not null default 0,
  lost integer not null default 0,
  points integer not null default 0,
  goals_for integer not null default 0,
  goals_against integer not null default 0,
  goal_difference integer not null default 0,
  form text,
  table_type text not null default 'TOTAL',
  updated_at timestamptz not null default now(),
  primary key(season_id,club_id,table_type)
);
create index if not exists ucl_standings_season_position_idx on public.ucl_standings(season_id,table_type,position);

alter table public.ucl_matches enable row level security;
alter table public.ucl_standings enable row level security;
drop policy if exists "ucl_matches_read_authenticated" on public.ucl_matches;
create policy "ucl_matches_read_authenticated" on public.ucl_matches for select to authenticated using (true);
drop policy if exists "ucl_standings_read_authenticated" on public.ucl_standings;
create policy "ucl_standings_read_authenticated" on public.ucl_standings for select to authenticated using (true);
grant select on public.ucl_matches, public.ucl_standings to authenticated;

-- -----------------------------------------------------------------------------
-- Hibou solitaire : calcul parallèle, aucun effet sur les points officiels.
-- -----------------------------------------------------------------------------
create or replace function public.get_hibou_solitaire_events_v080(
  p_season_id uuid,
  p_evening_date date default null
)
returns table(
  user_id uuid,
  username text,
  avatar_key text,
  match_id uuid,
  evening_date date,
  predicted_choice integer,
  actual_choice integer,
  group_count bigint,
  total_predictions bigint,
  group_pct numeric,
  solitary_points integer
)
language sql stable security definer set search_path=public as $$
with base as (
  select p.user_id,p.match_id,
    sign(p.home_score-p.away_score)::integer as predicted_choice,
    sign(m.home_score-m.away_score)::integer as actual_choice,
    (m.kickoff_at at time zone 'Europe/Paris')::date as evening_date
  from public.predictions p
  join public.matches m on m.id=p.match_id
  where p.season_id=p_season_id
    and m.season_id=p_season_id
    and m.status='finished'
    and coalesce(m.is_test,false)=false
    and m.home_score is not null and m.away_score is not null
), counts as (
  select match_id,predicted_choice,count(*)::bigint as group_count
  from base group by match_id,predicted_choice
), totals as (
  select match_id,count(*)::bigint as total_predictions from base group by match_id
), qualified as (
  select b.*,c.group_count,t.total_predictions,
    (c.group_count::numeric/nullif(t.total_predictions,0)::numeric*100)::numeric(8,3) as group_pct,
    case when c.group_count=1 then 10 when c.group_count=2 then 7 when c.group_count::numeric/nullif(t.total_predictions,0)::numeric<=0.05 then 5 else 0 end as solitary_points
  from base b join counts c using(match_id,predicted_choice) join totals t using(match_id)
  where b.predicted_choice=b.actual_choice
)
select q.user_id,pr.username,pr.avatar_key,q.match_id,q.evening_date,q.predicted_choice,q.actual_choice,
  q.group_count,q.total_predictions,q.group_pct,q.solitary_points
from qualified q join public.profiles pr on pr.id=q.user_id
where q.solitary_points>0
  and (p_evening_date is null or q.evening_date=p_evening_date)
order by q.evening_date desc,q.solitary_points desc,pr.username;
$$;
grant execute on function public.get_hibou_solitaire_events_v080(uuid,date) to authenticated;

create or replace function public.get_hibou_solitaire_leaderboard_v080(p_season_id uuid)
returns table(rank bigint,user_id uuid,username text,avatar_key text,solitary_points bigint,successes bigint,unique_successes bigint)
language sql stable security definer set search_path=public as $$
with e as (select * from public.get_hibou_solitaire_events_v080(p_season_id,null)), agg as (
  select e.user_id,max(e.username) username,max(e.avatar_key) avatar_key,sum(e.solitary_points)::bigint solitary_points,count(*)::bigint successes,count(*) filter(where e.group_count=1)::bigint unique_successes
  from e group by e.user_id
)
select row_number() over(order by solitary_points desc,unique_successes desc,successes desc,username)::bigint,
  user_id,username,avatar_key,solitary_points,successes,unique_successes
from agg order by solitary_points desc,unique_successes desc,successes desc,username;
$$;
grant execute on function public.get_hibou_solitaire_leaderboard_v080(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Votes mensuels Casserole / Génie.
-- -----------------------------------------------------------------------------
create table if not exists public.monthly_polls (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  month_key date not null,
  poll_type text not null check(poll_type in ('casserole','genius')),
  title text not null,
  status text not null default 'draft' check(status in ('draft','open','closed')),
  opens_at timestamptz,
  closes_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(season_id,month_key,poll_type)
);
create table if not exists public.monthly_poll_candidates (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.monthly_polls(id) on delete cascade,
  source_event_id uuid references public.gamification_events(id) on delete set null,
  label text not null,
  description text,
  image_url text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.monthly_poll_votes (
  poll_id uuid not null references public.monthly_polls(id) on delete cascade,
  candidate_id uuid not null references public.monthly_poll_candidates(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(poll_id,user_id)
);

alter table public.monthly_polls enable row level security;
alter table public.monthly_poll_candidates enable row level security;
alter table public.monthly_poll_votes enable row level security;
drop policy if exists "monthly_polls_read" on public.monthly_polls;
create policy "monthly_polls_read" on public.monthly_polls for select to authenticated using(status in ('open','closed') or public.is_admin());
drop policy if exists "monthly_candidates_read" on public.monthly_poll_candidates;
create policy "monthly_candidates_read" on public.monthly_poll_candidates for select to authenticated using(exists(select 1 from public.monthly_polls p where p.id=poll_id and (p.status in ('open','closed') or public.is_admin())));
drop policy if exists "monthly_votes_read" on public.monthly_poll_votes;
create policy "monthly_votes_read" on public.monthly_poll_votes for select to authenticated using(exists(select 1 from public.monthly_polls p where p.id=poll_id and (p.status in ('open','closed') or public.is_admin())));
grant select on public.monthly_polls,public.monthly_poll_candidates,public.monthly_poll_votes to authenticated;

create or replace function public.cast_monthly_vote_v080(p_poll_id uuid,p_candidate_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_poll public.monthly_polls%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentification requise.'; end if;
  select * into v_poll from public.monthly_polls where id=p_poll_id;
  if not found or v_poll.status<>'open' then raise exception 'Ce vote n''est pas ouvert.'; end if;
  if v_poll.opens_at is not null and now()<v_poll.opens_at then raise exception 'Le vote n''est pas encore ouvert.'; end if;
  if v_poll.closes_at is not null and now()>v_poll.closes_at then raise exception 'Le vote est terminé.'; end if;
  if not exists(select 1 from public.monthly_poll_candidates c where c.id=p_candidate_id and c.poll_id=p_poll_id) then raise exception 'Candidat invalide.'; end if;
  insert into public.monthly_poll_votes(poll_id,candidate_id,user_id) values(p_poll_id,p_candidate_id,auth.uid())
  on conflict(poll_id,user_id) do update set candidate_id=excluded.candidate_id,created_at=now();
end;
$$;
grant execute on function public.cast_monthly_vote_v080(uuid,uuid) to authenticated;

create or replace function public.admin_create_monthly_poll_v080(
  p_season_id uuid,p_month_key date,p_poll_type text,p_title text,p_candidates jsonb,
  p_opens_at timestamptz default now(),p_closes_at timestamptz default null
)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_poll uuid; item jsonb; idx integer:=0;
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role='super_admin' and status='active') then raise exception 'Réservé au Super Admin.'; end if;
  if p_poll_type not in('casserole','genius') then raise exception 'Type de vote invalide.'; end if;
  insert into public.monthly_polls(season_id,month_key,poll_type,title,status,opens_at,closes_at,created_by)
  values(p_season_id,date_trunc('month',p_month_key)::date,p_poll_type,p_title,'open',p_opens_at,p_closes_at,auth.uid())
  on conflict(season_id,month_key,poll_type) do update set title=excluded.title,status='open',opens_at=excluded.opens_at,closes_at=excluded.closes_at,updated_at=now()
  returning id into v_poll;
  delete from public.monthly_poll_candidates where poll_id=v_poll;
  for item in select value from jsonb_array_elements(coalesce(p_candidates,'[]'::jsonb)) loop
    idx:=idx+1;
    insert into public.monthly_poll_candidates(poll_id,source_event_id,label,description,image_url,sort_order)
    values(v_poll,nullif(item->>'source_event_id','')::uuid,coalesce(nullif(item->>'label',''),'Candidat'),item->>'description',item->>'image_url',idx);
  end loop;
  return v_poll;
end;
$$;
grant execute on function public.admin_create_monthly_poll_v080(uuid,date,text,text,jsonb,timestamptz,timestamptz) to authenticated;

insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
select auth.uid(),'install_v0_8_0','application',null,jsonb_build_object('ucl_center',true,'evenings',true,'hibou_solitaire',true,'monthly_votes',true)
where auth.uid() is not null;

create or replace function public.admin_close_monthly_poll_v080(p_poll_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role='super_admin' and status='active') then raise exception 'Réservé au Super Admin.'; end if;
  update public.monthly_polls set status='closed',closes_at=coalesce(closes_at,now()),updated_at=now() where id=p_poll_id;
end;
$$;
grant execute on function public.admin_close_monthly_poll_v080(uuid) to authenticated;
