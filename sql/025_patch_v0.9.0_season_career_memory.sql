-- =============================================================================
-- LE NID DES CHAMPIONS â€” PATCH V0.9.0
-- Saison, carriÃ¨re & mÃ©moire
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. Historique de rang : une photographie du classement Ã  chaque moment clÃ©.
-- -----------------------------------------------------------------------------
create table if not exists public.player_rank_history (
  id bigint generated always as identity primary key,
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  snapshot_key text not null,
  source text not null default 'manual',
  rank integer not null,
  points numeric not null default 0,
  exact_scores integer not null default 0,
  average numeric not null default 0,
  precision_pct numeric not null default 0,
  captured_at timestamptz not null default now(),
  unique(season_id,user_id,snapshot_key)
);
create index if not exists player_rank_history_user_idx on public.player_rank_history(user_id,season_id,captured_at);
create index if not exists player_rank_history_leader_idx on public.player_rank_history(season_id,rank,captured_at);

alter table public.player_rank_history enable row level security;
drop policy if exists player_rank_history_read on public.player_rank_history;
create policy player_rank_history_read on public.player_rank_history for select to authenticated using(true);
grant select on public.player_rank_history to authenticated;

create or replace function public.capture_season_snapshot_v090(
  p_season_id uuid,
  p_snapshot_key text default null,
  p_source text default 'manual'
)
returns integer
language plpgsql
security definer
set search_path=public
as $$
declare
  v_key text;
  v_count integer:=0;
begin
  if auth.uid() is not null and not exists(
    select 1 from public.profiles where id=auth.uid() and status='active'
  ) then
    raise exception 'Compte inactif.';
  end if;
  if not exists(select 1 from public.seasons where id=p_season_id) then
    raise exception 'Saison introuvable.';
  end if;

  v_key:=coalesce(nullif(trim(p_snapshot_key),''),'daily:'||to_char((now() at time zone 'Europe/Paris')::date,'YYYY-MM-DD'));

  insert into public.player_rank_history(
    season_id,user_id,snapshot_key,source,rank,points,exact_scores,average,precision_pct,captured_at
  )
  select p_season_id,l.user_id,v_key,coalesce(nullif(trim(p_source),''),'manual'),l.rank::integer,
    coalesce(l.points,0),coalesce(l.exact_scores,0)::integer,coalesce(l.average,0),coalesce(l.precision_pct,0),now()
  from public.get_leaderboard_v040(p_season_id,'general',null,null,false) l
  on conflict(season_id,user_id,snapshot_key) do update set
    source=excluded.source,rank=excluded.rank,points=excluded.points,exact_scores=excluded.exact_scores,
    average=excluded.average,precision_pct=excluded.precision_pct,captured_at=excluded.captured_at;

  get diagnostics v_count=row_count;
  return v_count;
end;
$$;
grant execute on function public.capture_season_snapshot_v090(uuid,text,text) to authenticated;

create or replace function public.capture_finished_match_snapshot_v090()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  if new.is_test is not true and new.status='finished' and old.status is distinct from 'finished' then
    perform public.capture_season_snapshot_v090(new.season_id,'match:'||new.id::text,'match_finished');
  end if;
  return new;
end;
$$;

drop trigger if exists matches_capture_rank_v090 on public.matches;
create trigger matches_capture_rank_v090
after update of status on public.matches
for each row execute function public.capture_finished_match_snapshot_v090();

-- Capture initiale de l'Ã©tat courant des saisons dÃ©jÃ  prÃ©sentes.
do $$
declare s record;
begin
  for s in select id from public.seasons loop
    perform public.capture_season_snapshot_v090(s.id,'migration:0.9.0','migration');
  end loop;
end $$;

-- -----------------------------------------------------------------------------
-- 2. Distinctions persistantes entre saisons.
-- -----------------------------------------------------------------------------
create table if not exists public.player_distinctions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  code text not null,
  label text not null,
  description text,
  icon text not null default 'ðŸ†',
  source_season_id uuid references public.seasons(id) on delete set null,
  awarded_at timestamptz not null default now(),
  active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  unique(user_id,code)
);
create index if not exists player_distinctions_user_idx on public.player_distinctions(user_id,active,awarded_at desc);
alter table public.player_distinctions enable row level security;
drop policy if exists player_distinctions_read on public.player_distinctions;
create policy player_distinctions_read on public.player_distinctions for select to authenticated using(active=true or public.is_admin());
grant select on public.player_distinctions to authenticated;

create or replace function public.admin_set_distinction_v090(
  p_user_id uuid,p_code text,p_label text,p_description text default null,p_icon text default 'ðŸ†',
  p_source_season_id uuid default null,p_active boolean default true,p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_id uuid;
begin
  if not public.is_super_admin() then raise exception 'RÃ©servÃ© au Super Admin.'; end if;
  if not exists(select 1 from public.profiles where id=p_user_id) then raise exception 'Joueur introuvable.'; end if;
  if nullif(trim(p_code),'') is null or nullif(trim(p_label),'') is null then raise exception 'Code et libellÃ© obligatoires.'; end if;
  insert into public.player_distinctions(user_id,code,label,description,icon,source_season_id,active,created_by,metadata)
  values(p_user_id,lower(trim(p_code)),trim(p_label),nullif(trim(p_description),''),coalesce(nullif(trim(p_icon),''),'ðŸ†'),p_source_season_id,p_active,auth.uid(),coalesce(p_metadata,'{}'::jsonb))
  on conflict(user_id,code) do update set label=excluded.label,description=excluded.description,icon=excluded.icon,
    source_season_id=excluded.source_season_id,active=excluded.active,metadata=excluded.metadata,created_by=auth.uid(),awarded_at=now()
  returning id into v_id;
  return v_id;
end;
$$;
grant execute on function public.admin_set_distinction_v090(uuid,text,text,text,text,uuid,boolean,jsonb) to authenticated;


-- Distinction historique dÃ©diÃ©e : vainqueur du Nid des Pronos â€” Coupe du monde 2026.
-- Un seul joueur peut porter ce titre actif Ã  la fois. p_user_id = null retire le titre.
create unique index if not exists player_distinctions_single_world_cup_winner_idx
  on public.player_distinctions(code)
  where active and code='nid-pronos-world-cup-2026';

create or replace function public.admin_set_world_cup_winner_v090(p_user_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_code constant text := 'nid-pronos-world-cup-2026';
  v_id uuid;
begin
  if not public.is_super_admin() then raise exception 'RÃ©servÃ© au Super Admin.'; end if;

  -- DÃ©sactive l'ancien dÃ©tenteur avant toute nouvelle attribution.
  update public.player_distinctions
     set active=false, created_by=auth.uid(), awarded_at=now()
   where code=v_code and active;

  if p_user_id is null then
    return null;
  end if;

  if not exists(select 1 from public.profiles where id=p_user_id) then
    raise exception 'Joueur introuvable.';
  end if;

  insert into public.player_distinctions(
    user_id,code,label,description,icon,source_season_id,active,created_by,metadata
  ) values (
    p_user_id,
    v_code,
    'Vainqueur du Nid des Pronos â€” Coupe du monde 2026',
    'A remportÃ© le Nid des Pronos lors de la Coupe du monde 2026.',
    'ðŸ†',
    null,
    true,
    auth.uid(),
    jsonb_build_object(
      'competition','Coupe du monde',
      'edition','2026',
      'legacy_app','Le Nid des Pronos',
      'official',true
    )
  )
  on conflict(user_id,code) do update set
    label=excluded.label,
    description=excluded.description,
    icon=excluded.icon,
    source_season_id=null,
    active=true,
    metadata=excluded.metadata,
    created_by=auth.uid(),
    awarded_at=now()
  returning id into v_id;

  return v_id;
end;
$$;
grant execute on function public.admin_set_world_cup_winner_v090(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Sondages gÃ©nÃ©raux (les votes mensuels V0.8 restent inchangÃ©s).
-- -----------------------------------------------------------------------------
create table if not exists public.polls (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete cascade,
  title text not null,
  question text not null,
  status text not null default 'draft' check(status in ('draft','open','closed','archived')),
  opens_at timestamptz,
  closes_at timestamptz,
  allow_change boolean not null default true,
  show_results_before_close boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.poll_options (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.polls(id) on delete cascade,
  label text not null,
  description text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.poll_votes (
  poll_id uuid not null references public.polls(id) on delete cascade,
  option_id uuid not null references public.poll_options(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key(poll_id,user_id)
);
create index if not exists polls_season_status_idx on public.polls(season_id,status,opens_at desc);
create index if not exists poll_options_poll_idx on public.poll_options(poll_id,sort_order);

alter table public.polls enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes enable row level security;
drop policy if exists polls_read on public.polls;
create policy polls_read on public.polls for select to authenticated using(status in ('open','closed','archived') or public.is_admin());
drop policy if exists poll_options_read on public.poll_options;
create policy poll_options_read on public.poll_options for select to authenticated using(exists(select 1 from public.polls p where p.id=poll_id and (p.status in ('open','closed','archived') or public.is_admin())));
drop policy if exists poll_votes_read on public.poll_votes;
create policy poll_votes_read on public.poll_votes for select to authenticated using(
  user_id=auth.uid() or public.is_admin() or exists(select 1 from public.polls p where p.id=poll_id and (p.status in ('closed','archived') or p.show_results_before_close))
);
grant select on public.polls,public.poll_options,public.poll_votes to authenticated;

create or replace function public.cast_poll_vote_v090(p_poll_id uuid,p_option_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare v_poll public.polls%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentification requise.'; end if;
  select * into v_poll from public.polls where id=p_poll_id;
  if not found then raise exception 'Sondage introuvable.'; end if;
  if v_poll.status<>'open' then raise exception 'Ce sondage n''est pas ouvert.'; end if;
  if v_poll.opens_at is not null and now()<v_poll.opens_at then raise exception 'Ce sondage n''est pas encore ouvert.'; end if;
  if v_poll.closes_at is not null and now()>v_poll.closes_at then raise exception 'Ce sondage est terminÃ©.'; end if;
  if not exists(select 1 from public.poll_options where id=p_option_id and poll_id=p_poll_id) then raise exception 'Choix invalide.'; end if;
  if not v_poll.allow_change and exists(select 1 from public.poll_votes where poll_id=p_poll_id and user_id=auth.uid()) then
    raise exception 'Ton vote est dÃ©finitif pour ce sondage.';
  end if;
  insert into public.poll_votes(poll_id,option_id,user_id)
  values(p_poll_id,p_option_id,auth.uid())
  on conflict(poll_id,user_id) do update set option_id=excluded.option_id,updated_at=now();
end;
$$;
grant execute on function public.cast_poll_vote_v090(uuid,uuid) to authenticated;

create or replace function public.admin_create_poll_v090(
  p_season_id uuid,p_title text,p_question text,p_options jsonb,
  p_opens_at timestamptz default now(),p_closes_at timestamptz default null,
  p_allow_change boolean default true,p_show_results_before_close boolean default true
)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_poll uuid; item jsonb; idx integer:=0;
begin
  if not public.is_super_admin() then raise exception 'RÃ©servÃ© au Super Admin.'; end if;
  if nullif(trim(p_title),'') is null or nullif(trim(p_question),'') is null then raise exception 'Titre et question obligatoires.'; end if;
  if jsonb_array_length(coalesce(p_options,'[]'::jsonb))<2 then raise exception 'Il faut au moins 2 rÃ©ponses.'; end if;
  insert into public.polls(season_id,title,question,status,opens_at,closes_at,allow_change,show_results_before_close,created_by)
  values(p_season_id,trim(p_title),trim(p_question),'open',p_opens_at,p_closes_at,p_allow_change,p_show_results_before_close,auth.uid())
  returning id into v_poll;
  for item in select value from jsonb_array_elements(p_options) loop
    idx:=idx+1;
    insert into public.poll_options(poll_id,label,description,sort_order)
    values(v_poll,coalesce(nullif(trim(item->>'label'),''),'Choix '||idx),nullif(trim(item->>'description'),''),idx);
  end loop;
  return v_poll;
end;
$$;
grant execute on function public.admin_create_poll_v090(uuid,text,text,jsonb,timestamptz,timestamptz,boolean,boolean) to authenticated;

create or replace function public.admin_close_poll_v090(p_poll_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.is_super_admin() then raise exception 'RÃ©servÃ© au Super Admin.'; end if;
  update public.polls set status='closed',closes_at=coalesce(closes_at,now()),updated_at=now() where id=p_poll_id;
end;
$$;
grant execute on function public.admin_close_poll_v090(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. Ã‰vÃ©nements de mÃ©moire Ã©ditoriaux facultatifs pour le replay.
-- -----------------------------------------------------------------------------
create table if not exists public.season_memory_events (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  event_at timestamptz not null default now(),
  event_type text not null default 'memory',
  title text not null,
  subtitle text,
  user_id uuid references public.profiles(id) on delete set null,
  icon text,
  is_public boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists season_memory_events_idx on public.season_memory_events(season_id,event_at desc);
alter table public.season_memory_events enable row level security;
drop policy if exists season_memory_events_read on public.season_memory_events;
create policy season_memory_events_read on public.season_memory_events for select to authenticated using(is_public or public.is_admin());
grant select on public.season_memory_events to authenticated;

create or replace function public.admin_add_season_memory_event_v090(
  p_season_id uuid,p_event_at timestamptz,p_event_type text,p_title text,p_subtitle text default null,
  p_user_id uuid default null,p_icon text default null,p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_id uuid;
begin
  if not public.is_admin() then raise exception 'RÃ©servÃ© aux administrateurs.'; end if;
  insert into public.season_memory_events(season_id,event_at,event_type,title,subtitle,user_id,icon,created_by,metadata)
  values(p_season_id,coalesce(p_event_at,now()),coalesce(nullif(trim(p_event_type),''),'memory'),trim(p_title),nullif(trim(p_subtitle),''),p_user_id,p_icon,auth.uid(),coalesce(p_metadata,'{}'::jsonb))
  returning id into v_id;
  return v_id;
end;
$$;
grant execute on function public.admin_add_season_memory_event_v090(uuid,timestamptz,text,text,text,uuid,text,jsonb) to authenticated;

-- -----------------------------------------------------------------------------
-- 5. Profil saison complet.
-- -----------------------------------------------------------------------------
create or replace function public.get_player_season_profile_v090(p_season_id uuid,p_user_id uuid default null)
returns table(
  user_id uuid,username text,avatar_key text,club_heart text,rank bigint,points numeric,exact_scores bigint,
  good_differences bigint,good_results bigint,played bigint,average numeric,precision_pct numeric,
  qualifier_successes bigint,forgotten bigint,casseroles bigint,casserole_points bigint,genius bigint,genius_points bigint,
  solitary_successes bigint,solitary_points bigint,records bigint,badges bigint,best_rank integer,worst_rank integer,
  biggest_climb integer,biggest_drop integer,days_in_lead numeric,form jsonb,rank_history jsonb,distinctions jsonb
)
language sql
stable
security definer
set search_path=public
as $$
with target as (
  select coalesce(p_user_id,auth.uid()) uid
), season_end as (
  select case
    when s.status in ('finished','archived') then coalesce(
      (select max(m.kickoff_at) from public.matches m where m.season_id=s.id and m.status='finished' and coalesce(m.is_test,false)=false),
      s.updated_at,
      now()
    )
    else now()
  end as end_at
  from public.seasons s where s.id=p_season_id
), lb as (
  select l.* from public.get_leaderboard_v040(p_season_id,'general',null,null,false) l,target t where l.user_id=t.uid
), hist0 as (
  select h.*,lag(h.rank) over(order by h.captured_at,h.id) prev_rank,
    lead(h.captured_at,1,(select end_at from season_end)) over(order by h.captured_at,h.id) next_at
  from public.player_rank_history h,target t where h.season_id=p_season_id and h.user_id=t.uid
), hist as (
  select coalesce(min(rank),null)::integer best_rank,coalesce(max(rank),null)::integer worst_rank,
    coalesce(max(greatest(coalesce(prev_rank,rank)-rank,0)),0)::integer biggest_climb,
    coalesce(max(greatest(rank-coalesce(prev_rank,rank),0)),0)::integer biggest_drop,
    coalesce(sum(case when rank=1 then greatest(extract(epoch from (next_at-captured_at))/86400.0,0) else 0 end),0)::numeric(10,2) days_in_lead,
    coalesce(jsonb_agg(jsonb_build_object('at',captured_at,'rank',rank,'points',points,'source',source) order by captured_at),'[]'::jsonb) rank_history
  from hist0
), form_src as (
  select p.match_id,p.points,m.kickoff_at,
    case when p.points>=7 then 'exact' when p.points>=5 then 'difference' when p.points>=3 then 'result' else 'miss' end form_result
  from public.predictions p join public.matches m on m.id=p.match_id,target t
  where p.season_id=p_season_id and p.user_id=t.uid and m.status='finished' and coalesce(m.is_test,false)=false
  order by m.kickoff_at desc limit 5
), form as (
  select coalesce(jsonb_agg(jsonb_build_object('match_id',match_id,'points',points,'result',form_result,'at',kickoff_at) order by kickoff_at desc),'[]'::jsonb) data from form_src
), extras as (
  select
    (select count(*) from public.tie_predictions tp join public.knockout_ties kt on kt.id=tp.tie_id,target t where tp.season_id=p_season_id and tp.user_id=t.uid and kt.status='finished' and kt.qualified_club_id=tp.qualified_club_id)::bigint qualifier_successes,
    (select count(*) from public.matches m,target t where m.season_id=p_season_id and m.status='finished' and coalesce(m.is_test,false)=false and not exists(select 1 from public.predictions p where p.match_id=m.id and p.user_id=t.uid))::bigint forgotten,
    (select count(*) from public.gamification_events e,target t where e.season_id=p_season_id and e.user_id=t.uid and e.event_type='casserole' and not e.is_test)::bigint casseroles,
    (select coalesce(sum(e.points),0) from public.gamification_events e,target t where e.season_id=p_season_id and e.user_id=t.uid and e.event_type='casserole' and not e.is_test)::bigint casserole_points,
    (select count(*) from public.gamification_events e,target t where e.season_id=p_season_id and e.user_id=t.uid and e.event_type='genius' and not e.is_test)::bigint genius,
    (select coalesce(sum(e.points),0) from public.gamification_events e,target t where e.season_id=p_season_id and e.user_id=t.uid and e.event_type='genius' and not e.is_test)::bigint genius_points,
    (select count(*) from public.get_hibou_solitaire_events_v080(p_season_id,null) e,target t where e.user_id=t.uid)::bigint solitary_successes,
    (select coalesce(sum(e.solitary_points),0) from public.get_hibou_solitaire_events_v080(p_season_id,null) e,target t where e.user_id=t.uid)::bigint solitary_points,
    (select count(*) from public.gamification_records r,target t where r.season_id=p_season_id and r.user_id=t.uid and r.active and not r.is_test)::bigint records,
    (select count(*) from public.player_badges b,target t where b.user_id=t.uid and (b.season_id=p_season_id or b.season_id is null) and b.revoked_at is null and not b.is_test)::bigint badges,
    (select coalesce(jsonb_agg(jsonb_build_object('code',d.code,'label',d.label,'description',d.description,'icon',d.icon,'awarded_at',d.awarded_at) order by d.awarded_at desc),'[]'::jsonb) from public.player_distinctions d,target t where d.user_id=t.uid and d.active) distinctions
)
select lb.user_id,lb.username,lb.avatar_key,lb.club_heart,lb.rank,lb.points,lb.exact_scores,lb.good_differences,lb.good_results,lb.played,lb.average,lb.precision_pct,
  e.qualifier_successes,e.forgotten,e.casseroles,e.casserole_points,e.genius,e.genius_points,e.solitary_successes,e.solitary_points,e.records,e.badges,
  h.best_rank,h.worst_rank,h.biggest_climb,h.biggest_drop,h.days_in_lead,f.data,h.rank_history,e.distinctions
from lb cross join hist h cross join form f cross join extras e;
$$;
grant execute on function public.get_player_season_profile_v090(uuid,uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 6. CarriÃ¨re multi-saisons.
-- -----------------------------------------------------------------------------
create or replace function public.get_career_leaderboard_v090()
returns table(
  rank bigint,user_id uuid,username text,avatar_key text,club_heart text,seasons_played bigint,total_points numeric,
  total_played bigint,career_average numeric,exact_scores bigint,podiums bigint,titles bigint,badges bigint,records bigint
)
language sql
stable
security definer
set search_path=public
as $$
with season_rows as (
  select s.id season_id,s.status,l.*
  from public.seasons s
  cross join lateral public.get_leaderboard_v040(s.id,'general',null,null,false) l
  where l.played>0 or l.points<>0
), agg as (
  select sr.user_id,max(sr.username) username,max(sr.avatar_key) avatar_key,max(sr.club_heart) club_heart,
    count(distinct sr.season_id)::bigint seasons_played,sum(sr.points)::numeric total_points,sum(sr.played)::bigint total_played,
    case when sum(sr.played)>0 then (sum(sr.points)/sum(sr.played))::numeric else 0::numeric end career_average,
    sum(sr.exact_scores)::bigint exact_scores,
    count(*) filter(where sr.status in('finished','archived') and sr.rank<=3)::bigint podiums,
    count(*) filter(where sr.status in('finished','archived') and sr.rank=1)::bigint titles
  from season_rows sr group by sr.user_id
), enriched as (
  select a.*,
    (select count(*) from public.player_badges pb where pb.user_id=a.user_id and pb.revoked_at is null and not pb.is_test)::bigint badges,
    (select count(*) from public.gamification_records gr where gr.user_id=a.user_id and gr.active and not gr.is_test)::bigint records
  from agg a
), ranked as (
  select row_number() over(order by total_points desc,exact_scores desc,career_average desc,seasons_played desc,username)::bigint rank,e.* from enriched e
)
select rank,user_id,username,avatar_key,club_heart,seasons_played,total_points,total_played,career_average,exact_scores,podiums,titles,badges,records
from ranked order by rank;
$$;
grant execute on function public.get_career_leaderboard_v090() to authenticated;

create or replace function public.get_player_career_v090(p_user_id uuid default null)
returns jsonb
language sql
stable
security definer
set search_path=public
as $$
with target as (select coalesce(p_user_id,auth.uid()) uid),
career as (
  select c.* from public.get_career_leaderboard_v090() c,target t where c.user_id=t.uid
), seasons_json as (
  select coalesce(jsonb_agg(jsonb_build_object(
    'season_id',s.id,'season',s.name,'slug',s.slug,'status',s.status,'rank',l.rank,'points',l.points,
    'played',l.played,'average',l.average,'exacts',l.exact_scores,'precision',l.precision_pct
  ) order by s.created_at desc),'[]'::jsonb) data
  from public.seasons s cross join lateral public.get_leaderboard_v040(s.id,'general',null,null,false) l,target t
  where l.user_id=t.uid and (l.played>0 or l.points<>0)
), d as (
  select coalesce(jsonb_agg(jsonb_build_object('code',pd.code,'label',pd.label,'description',pd.description,'icon',pd.icon,'awarded_at',pd.awarded_at,'source_season_id',pd.source_season_id) order by pd.awarded_at desc),'[]'::jsonb) data
  from public.player_distinctions pd,target t where pd.user_id=t.uid and pd.active
), historical_records as (
  select coalesce(jsonb_agg(jsonb_build_object('key',x.record_key,'name',x.record_name,'value',x.value,'achieved_at',x.achieved_at,'season_id',x.season_id) order by x.achieved_at desc),'[]'::jsonb) data
  from (
    select distinct on (gr.record_key) gr.record_key,gr.record_name,gr.value,gr.achieved_at,gr.season_id
    from public.gamification_records gr,target t where gr.user_id=t.uid and gr.active and not gr.is_test
    order by gr.record_key,gr.value desc,gr.achieved_at desc
  ) x
)
select jsonb_build_object(
  'summary',coalesce((select to_jsonb(c) from career c),'{}'::jsonb),
  'seasons',(select data from seasons_json),
  'distinctions',(select data from d),
  'historical_records',(select data from historical_records)
);
$$;
grant execute on function public.get_player_career_v090(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 7. Champion en titre et Hall of Fame.
-- -----------------------------------------------------------------------------
create or replace function public.get_title_holder_v090(p_season_id uuid)
returns table(user_id uuid,username text,avatar_key text,source_season_id uuid,source_season_name text)
language sql
stable
security definer
set search_path=public
as $$
with current_s as (select * from public.seasons where id=p_season_id), previous_s as (
  select s.* from public.seasons s,current_s c
  where s.id<>c.id and s.status in('finished','archived') and s.created_at<c.created_at
  order by s.created_at desc limit 1
), winner as (
  select l.user_id,l.username,l.avatar_key,p.id source_season_id,p.name source_season_name
  from previous_s p cross join lateral public.get_leaderboard_v040(p.id,'general',null,null,false) l
  where l.rank=1 limit 1
)
select * from winner;
$$;
grant execute on function public.get_title_holder_v090(uuid) to authenticated;

create or replace function public.get_hall_of_fame_v090(p_season_id uuid default null)
returns table(
  season_id uuid,season_name text,category text,"position" integer,user_id uuid,username text,value numeric,label text,metadata jsonb
)
language sql
stable
security definer
set search_path=public
as $$
with seasons_scope as (
  select s.* from public.seasons s where p_season_id is null or s.id=p_season_id
), lb as (
  select s.id season_id,s.name season_name,l.* from seasons_scope s cross join lateral public.get_leaderboard_v040(s.id,'general',null,null,false) l
), podium as (
  select season_id,season_name,'podium'::text category,rank::integer position,user_id,username,points value,
    case rank when 1 then 'Champion' when 2 then 'Vice-champion' else 'TroisiÃ¨me' end label,'{}'::jsonb metadata
  from lb where rank<=3
), best_score as (
  select season_id,season_name,'best_score'::text category,1 position,user_id,username,points::numeric value,'Meilleur scoreur'::text label,
    jsonb_build_object('played',played,'average',average) metadata
  from (select l.*,row_number() over(partition by season_id order by points desc,exact_scores desc,username) rn from lb l) x where rn=1
), exacts as (
  select season_id,season_name,'best_exact'::text category,1 position,user_id,username,exact_scores::numeric value,'MaÃ®tre des scores exacts'::text label,'{}'::jsonb metadata
  from (select l.*,row_number() over(partition by season_id order by exact_scores desc,points desc,username) rn from lb l) x where rn=1
), casseroles as (
  select s.id season_id,s.name season_name,'poele_or'::text category,1 position,e.user_id,p.username,sum(e.points)::numeric value,'PoÃªle d''Or'::text label,jsonb_build_object('events',count(*)) metadata
  from seasons_scope s join public.gamification_events e on e.season_id=s.id and e.event_type='casserole' and not e.is_test join public.profiles p on p.id=e.user_id
  group by s.id,s.name,e.user_id,p.username
  having sum(e.points)=(select max(z.total) from (select sum(e2.points) total from public.gamification_events e2 where e2.season_id=s.id and e2.event_type='casserole' and not e2.is_test group by e2.user_id) z)
), geniuses as (
  select s.id season_id,s.name season_name,'genius'::text category,1 position,e.user_id,p.username,sum(e.points)::numeric value,'GÃ©nie de la saison'::text label,jsonb_build_object('events',count(*)) metadata
  from seasons_scope s join public.gamification_events e on e.season_id=s.id and e.event_type='genius' and not e.is_test join public.profiles p on p.id=e.user_id
  group by s.id,s.name,e.user_id,p.username
  having sum(e.points)=(select max(z.total) from (select sum(e2.points) total from public.gamification_events e2 where e2.season_id=s.id and e2.event_type='genius' and not e2.is_test group by e2.user_id) z)
), solitary as (
  select s.id season_id,s.name season_name,'solitary'::text category,1 position,h.user_id,h.username,h.solitary_points::numeric value,'Hibou solitaire'::text label,jsonb_build_object('successes',h.successes,'unique_successes',h.unique_successes) metadata
  from seasons_scope s cross join lateral public.get_hibou_solitaire_leaderboard_v080(s.id) h where h.rank=1
), teams as (
  select s.id season_id,s.name season_name,'team'::text category,1 position,null::uuid user_id,t.team_name username,t.average_points::numeric value,'Meilleure Team'::text label,jsonb_build_object('team_id',t.team_id,'top3_points',t.top3_points) metadata
  from seasons_scope s cross join lateral public.get_team_leaderboard_v050(s.id,null) t where t.rank_average=1
), records_ranked as (
  select s.id season_id,s.name season_name,'record'::text category,
    row_number() over(partition by s.id order by r.achieved_at desc,r.record_key)::integer position,
    r.user_id,p.username,r.value::numeric value,coalesce(r.record_name,r.record_key)::text label,
    jsonb_build_object('record_key',r.record_key,'previous_value',r.previous_value,'achieved_at',r.achieved_at) metadata
  from seasons_scope s
  join public.gamification_records r on r.season_id=s.id and r.active and not r.is_test and r.scope='nid'
  join public.profiles p on p.id=r.user_id
), records as (
  select * from records_ranked where position<=6
)
select * from podium
union all select * from best_score
union all select * from exacts
union all select * from casseroles
union all select * from geniuses
union all select * from solitary
union all select * from teams
union all select * from records
order by season_name,category,position;
$$;
grant execute on function public.get_hall_of_fame_v090(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 8. Replay automatique de saison.
-- -----------------------------------------------------------------------------
create or replace function public.get_season_replay_v090(p_season_id uuid)
returns table(event_at timestamptz,event_type text,title text,subtitle text,user_id uuid,username text,icon text,metadata jsonb)
language sql
stable
security definer
set search_path=public
as $$
with leader_rows as (
  select h.captured_at event_at,'leader'::text event_type,'Nouveau leader du Nid'::text title,
    p.username||' prend la tÃªte avec '||round(h.points)::text||' pts' subtitle,h.user_id,p.username,'ðŸ‘‘'::text icon,
    jsonb_build_object('rank',h.rank,'points',h.points,'source',h.source) metadata,
    lag(h.user_id) over(order by h.captured_at,h.id) previous_leader
  from public.player_rank_history h join public.profiles p on p.id=h.user_id
  where h.season_id=p_season_id and h.rank=1
), leaders as (
  select event_at,event_type,title,subtitle,user_id,username,icon,metadata from leader_rows where previous_leader is distinct from user_id
), records as (
  select r.achieved_at,'record',coalesce(r.record_name,'Nouveau record'),p.username||' Â· '||r.value::text,r.user_id,p.username,'ðŸ“ˆ',jsonb_build_object('record_key',r.record_key,'value',r.value,'previous',r.previous_value)
  from public.gamification_records r join public.profiles p on p.id=r.user_id where r.season_id=p_season_id and r.active and not r.is_test and r.scope='nid'
), gamification as (
  select e.created_at,e.event_type,coalesce(e.title,case when e.event_type='casserole' then 'Casserole' else 'Coup de gÃ©nie' end),coalesce(e.message,p.username),e.user_id,p.username,
    case when e.event_type='casserole' then 'ðŸ³' else 'âœ¨' end,jsonb_build_object('points',e.points,'severity',e.severity,'subtype',e.subtype)
  from public.gamification_events e join public.profiles p on p.id=e.user_id where e.season_id=p_season_id and e.event_type in('casserole','genius') and e.is_public and not e.is_test
), legendary_badges as (
  select pb.earned_at,'legendary_badge',gb.name,p.username||' dÃ©bloque un badge lÃ©gendaire',pb.user_id,p.username,'ðŸ…',jsonb_build_object('badge',gb.code,'description',gb.description)
  from public.player_badges pb join public.gamification_badges gb on gb.id=pb.badge_id join public.profiles p on p.id=pb.user_id
  where pb.season_id=p_season_id and pb.revoked_at is null and not pb.is_test and gb.rarity='legendary'
), champion_eliminations as (
  select cp.eliminated_at,'champion_eliminated','Un champion tombe',p.username||' perd son choix '||cp.pick_number::text,cp.user_id,p.username,'ðŸ’”',jsonb_build_object('pick_number',cp.pick_number,'club_id',cp.club_id)
  from public.champion_predictions cp join public.profiles p on p.id=cp.user_id where cp.season_id=p_season_id and cp.eliminated_at is not null
), final_event as (
  select coalesce(t.updated_at,t.leg1_kickoff_at),'final','La finale est scellÃ©e',coalesce(c.name,'Le champion europÃ©en est connu'),null::uuid,null::text,'ðŸ†',jsonb_build_object('qualified_club_id',t.qualified_club_id)
  from public.knockout_ties t left join public.clubs c on c.id=t.qualified_club_id join public.competition_phases ph on ph.id=t.phase_id
  where t.season_id=p_season_id and ph.code='FINAL' and t.status='finished'
), manual_events as (
  select e.event_at,e.event_type,e.title,e.subtitle,e.user_id,p.username,coalesce(e.icon,'ðŸ¦‰'),e.metadata
  from public.season_memory_events e left join public.profiles p on p.id=e.user_id where e.season_id=p_season_id and e.is_public
)
select * from leaders
union all select * from records
union all select * from gamification
union all select * from legendary_badges
union all select * from champion_eliminations
union all select * from final_event
union all select * from manual_events
order by event_at desc;
$$;
grant execute on function public.get_season_replay_v090(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 9. Administration des saisons : crÃ©ation, activation et archivage.
-- -----------------------------------------------------------------------------
create or replace function public.admin_create_season_v090(
  p_name text,p_slug text,p_copy_from_season_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_id uuid; src public.seasons%rowtype;
begin
  if not public.is_super_admin() then raise exception 'RÃ©servÃ© au Super Admin.'; end if;
  if nullif(trim(p_name),'') is null or nullif(trim(p_slug),'') is null then raise exception 'Nom et slug obligatoires.'; end if;
  if exists(select 1 from public.seasons where slug=lower(trim(p_slug))) then raise exception 'Ce slug de saison existe dÃ©jÃ .'; end if;
  if p_copy_from_season_id is not null then select * into src from public.seasons where id=p_copy_from_season_id; end if;
  insert into public.seasons(name,slug,status,is_active,timezone,points_wrong,points_result,points_difference,points_exact,champion_1_bonus,champion_2_bonus)
  values(trim(p_name),lower(trim(p_slug)),'preparation',false,coalesce(src.timezone,'Europe/Paris'),coalesce(src.points_wrong,0),coalesce(src.points_result,3),coalesce(src.points_difference,5),coalesce(src.points_exact,7),coalesce(src.champion_1_bonus,100),coalesce(src.champion_2_bonus,50))
  returning id into v_id;
  if p_copy_from_season_id is not null then
    insert into public.competition_phases(season_id,code,name,sort_order,default_multiplier)
    select v_id,code,name,sort_order,default_multiplier from public.competition_phases where season_id=p_copy_from_season_id order by sort_order;
  else
    insert into public.competition_phases(season_id,code,name,sort_order,default_multiplier) values
      (v_id,'LEAGUE','Phase de ligue',10,1),(v_id,'KNOCKOUT_PLAYOFF','Barrages',20,1),(v_id,'ROUND_OF_16','HuitiÃ¨mes de finale',30,1),
      (v_id,'QUARTER_FINAL','Quarts de finale',40,1),(v_id,'SEMI_FINAL','Demi-finales',50,1),(v_id,'FINAL','Finale',60,1);
  end if;
  insert into public.gamification_settings(season_id) values(v_id) on conflict(season_id) do nothing;
  return v_id;
end;
$$;
grant execute on function public.admin_create_season_v090(text,text,uuid) to authenticated;

create or replace function public.admin_set_active_season_v090(p_season_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.is_super_admin() then raise exception 'RÃ©servÃ© au Super Admin.'; end if;
  if not exists(select 1 from public.seasons where id=p_season_id) then raise exception 'Saison introuvable.'; end if;
  update public.seasons set is_active=false,updated_at=now() where is_active=true and id<>p_season_id;
  update public.seasons set is_active=true,status='active',updated_at=now() where id=p_season_id;
end;
$$;
grant execute on function public.admin_set_active_season_v090(uuid) to authenticated;

create or replace function public.admin_set_season_status_v090(p_season_id uuid,p_status text)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.is_super_admin() then raise exception 'RÃ©servÃ© au Super Admin.'; end if;
  if p_status not in('preparation','active','finished','archived') then raise exception 'Statut invalide.'; end if;
  update public.seasons set status=p_status,is_active=case when p_status='active' then true when p_status in('finished','archived') then false else is_active end,updated_at=now() where id=p_season_id;
  if p_status='active' then update public.seasons set is_active=false,updated_at=now() where id<>p_season_id and is_active=true; end if;
end;
$$;
grant execute on function public.admin_set_season_status_v090(uuid,text) to authenticated;

-- -----------------------------------------------------------------------------
-- 10. Archives en lecture seule : les anciennes saisons ne doivent plus muter.
-- -----------------------------------------------------------------------------
create or replace function public.season_is_writable_v090(p_season_id uuid)
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select coalesce((select status not in ('finished','archived') from public.seasons where id=p_season_id),false);
$$;
grant execute on function public.season_is_writable_v090(uuid) to authenticated;

-- Le recalcul serveur des points reste autorisÃ© sur une saison terminÃ©e,
-- mais un joueur ne peut plus crÃ©er/modifier son pronostic.
create or replace function public.guard_prediction_write()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  v_match public.matches%rowtype;
begin
  select * into v_match from public.matches where id=new.match_id;
  if not found then raise exception 'Match introuvable.'; end if;

  if tg_op='UPDATE'
     and new.user_id=old.user_id
     and new.match_id=old.match_id
     and new.home_score=old.home_score
     and new.away_score=old.away_score then
    new.season_id:=v_match.season_id;
    new.updated_at:=now();
    return new;
  end if;

  if not public.season_is_writable_v090(v_match.season_id) then
    raise exception 'Cette saison est terminÃ©e et consultable en lecture seule.';
  end if;
  if v_match.status not in ('scheduled','postponed') or v_match.kickoff_at<=now() then
    raise exception 'Pronostic verrouillÃ©.';
  end if;

  new.season_id:=v_match.season_id;
  new.points:=0;
  new.updated_at:=now();
  return new;
end;
$$;

create or replace function public.guard_tie_prediction_v040()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  t public.knockout_ties%rowtype;
  v_first timestamptz;
  v_last timestamptz;
begin
  select * into t from public.knockout_ties where id=new.tie_id;
  if not found then raise exception 'Confrontation introuvable.'; end if;
  if not public.season_is_writable_v090(t.season_id) then raise exception 'Cette saison est terminÃ©e et consultable en lecture seule.'; end if;
  if t.status in ('finished','cancelled') then raise exception 'Pronostic qualifiÃ© verrouillÃ©.'; end if;
  if t.team_a_club_id is null or t.team_b_club_id is null then raise exception 'Les deux clubs ne sont pas encore connus.'; end if;
  if new.qualified_club_id not in (t.team_a_club_id,t.team_b_club_id) then raise exception 'Le qualifiÃ© doit Ãªtre lâ€™un des deux clubs.'; end if;

  v_first:=t.leg1_kickoff_at;
  v_last:=case when t.is_single_match then t.leg1_kickoff_at else t.leg2_kickoff_at end;
  if now()>=v_last then raise exception 'Pronostic qualifiÃ© verrouillÃ©.'; end if;

  new.season_id:=t.season_id;
  new.pick_timing:=case
    when tg_op='UPDATE' and new.qualified_club_id=old.qualified_club_id then old.pick_timing
    when now()<v_first then 'early' else 'late' end;
  new.points:=0;
  new.updated_at:=now();
  return new;
end;
$$;

create or replace function public.save_champion_pick_v040(p_pick_number integer,p_club_id uuid,p_season_id uuid default null)
returns void
language plpgsql security definer set search_path=public as $$
declare v_season uuid;
begin
  if auth.uid() is null then raise exception 'Utilisateur non connectÃ©.'; end if;
  v_season:=p_season_id;
  if v_season is null then select id into v_season from public.seasons where is_active=true order by created_at desc limit 1; end if;
  if v_season is null then raise exception 'Saison active introuvable.'; end if;
  if not public.season_is_writable_v090(v_season) then raise exception 'Cette saison est terminÃ©e et consultable en lecture seule.'; end if;
  if p_pick_number not in (1,2) then raise exception 'Choix champion invalide.'; end if;
  if not public.is_champion_pick_open_v040(v_season,p_pick_number) then raise exception 'Ce choix champion est verrouillÃ©.'; end if;
  if not public.is_champion_candidate_v040(v_season,p_pick_number,p_club_id) then raise exception 'Ce club nâ€™est pas disponible pour ce choix champion.'; end if;

  insert into public.champion_predictions(user_id,season_id,pick_number,club_id,assigned_default,locked_at)
  values(auth.uid(),v_season,p_pick_number,p_club_id,false,null)
  on conflict(user_id,season_id,pick_number) do update
    set club_id=excluded.club_id,assigned_default=false,eliminated_at=null,points=0,updated_at=now();
end;
$$;
grant execute on function public.save_champion_pick_v040(integer,uuid,uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 10b. Les archives figent aussi les Teams.
-- Le Super Admin garde la possibilitÃ© d'une correction exceptionnelle.
-- -----------------------------------------------------------------------------
create or replace function public.guard_archived_team_mutation_v090()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  v_season uuid;
begin
  if tg_table_name = 'team_invites' then
    select season_id into v_season
    from public.teams
    where id = case when tg_op='DELETE' then old.team_id else new.team_id end;
  else
    v_season := case when tg_op='DELETE' then old.season_id else new.season_id end;
  end if;

  if v_season is not null
     and not public.season_is_writable_v090(v_season)
     and not public.is_super_admin() then
    raise exception 'Cette saison est terminÃ©e et les Teams sont consultables en lecture seule.';
  end if;

  if tg_op='DELETE' then return old; end if;
  return new;
end;
$$;

drop trigger if exists teams_archive_guard_v090 on public.teams;
create trigger teams_archive_guard_v090
before insert or update or delete on public.teams
for each row execute function public.guard_archived_team_mutation_v090();

drop trigger if exists team_memberships_archive_guard_v090 on public.team_memberships;
create trigger team_memberships_archive_guard_v090
before insert or update or delete on public.team_memberships
for each row execute function public.guard_archived_team_mutation_v090();

drop trigger if exists team_join_requests_archive_guard_v090 on public.team_join_requests;
create trigger team_join_requests_archive_guard_v090
before insert or update or delete on public.team_join_requests
for each row execute function public.guard_archived_team_mutation_v090();

drop trigger if exists team_invites_archive_guard_v090 on public.team_invites;
create trigger team_invites_archive_guard_v090
before insert or update or delete on public.team_invites
for each row execute function public.guard_archived_team_mutation_v090();

grant execute on function public.guard_archived_team_mutation_v090() to authenticated;

-- -----------------------------------------------------------------------------
-- 11. Diagnostic V0.9.0.
-- -----------------------------------------------------------------------------
create or replace function public.admin_run_diagnostics_v090()
returns jsonb
language plpgsql
security definer
set search_path=public,pg_catalog
as $$
declare
  v_base jsonb;
  v_checks_v090 jsonb;
  v_checks jsonb;
  v_total integer:=0;
  v_passed integer:=0;
  v_warnings integer:=0;
  v_failed integer:=0;
begin
  if not public.is_super_admin() then raise exception 'RÃ©servÃ© au Super Admin.'; end if;
  select public.admin_run_diagnostics_v081() into v_base;

  select jsonb_agg(jsonb_build_object('id',id,'version','0.9','category',category,'status',status,'message',message) order by id)
  into v_checks_v090
  from (
    values
      ('table.player_rank_history','MÃ©moire',case when to_regclass('public.player_rank_history') is not null then 'PASS' else 'FAIL' end,'Historique de rang'),
      ('table.player_distinctions','CarriÃ¨re',case when to_regclass('public.player_distinctions') is not null then 'PASS' else 'FAIL' end,'Distinctions persistantes'),
      ('rpc.admin_set_world_cup_winner_v090','MÃ©moire',case when to_regprocedure('public.admin_set_world_cup_winner_v090(uuid)') is not null then 'PASS' else 'FAIL' end,'Vainqueur manuel du Nid des Pronos â€” Coupe du monde 2026'),
      ('table.polls','Sondages',case when to_regclass('public.polls') is not null then 'PASS' else 'FAIL' end,'Sondages gÃ©nÃ©raux'),
      ('table.poll_options','Sondages',case when to_regclass('public.poll_options') is not null then 'PASS' else 'FAIL' end,'Choix de sondages'),
      ('table.poll_votes','Sondages',case when to_regclass('public.poll_votes') is not null then 'PASS' else 'FAIL' end,'Votes de sondages'),
      ('table.season_memory_events','Replay',case when to_regclass('public.season_memory_events') is not null then 'PASS' else 'FAIL' end,'Ã‰vÃ©nements de replay'),
      ('rpc.get_player_season_profile_v090','Profil',case when to_regprocedure('public.get_player_season_profile_v090(uuid,uuid)') is not null then 'PASS' else 'FAIL' end,'Profil saison complet'),
      ('rpc.get_career_leaderboard_v090','CarriÃ¨re',case when to_regprocedure('public.get_career_leaderboard_v090()') is not null then 'PASS' else 'FAIL' end,'Classement carriÃ¨re'),
      ('rpc.get_player_career_v090','CarriÃ¨re',case when to_regprocedure('public.get_player_career_v090(uuid)') is not null then 'PASS' else 'FAIL' end,'Fiche carriÃ¨re'),
      ('rpc.get_title_holder_v090','MÃ©moire',case when to_regprocedure('public.get_title_holder_v090(uuid)') is not null then 'PASS' else 'FAIL' end,'Champion en titre'),
      ('rpc.get_hall_of_fame_v090','Hall of Fame',case when to_regprocedure('public.get_hall_of_fame_v090(uuid)') is not null then 'PASS' else 'FAIL' end,'Hall of Fame'),
      ('rpc.get_season_replay_v090','Replay',case when to_regprocedure('public.get_season_replay_v090(uuid)') is not null then 'PASS' else 'FAIL' end,'Replay de saison'),
      ('rpc.cast_poll_vote_v090','Sondages',case when to_regprocedure('public.cast_poll_vote_v090(uuid,uuid)') is not null then 'PASS' else 'FAIL' end,'Vote gÃ©nÃ©ral'),
      ('rpc.admin_create_season_v090','Multi-saison',case when to_regprocedure('public.admin_create_season_v090(text,text,uuid)') is not null then 'PASS' else 'FAIL' end,'CrÃ©ation de saison'),
      ('rpc.admin_set_active_season_v090','Multi-saison',case when to_regprocedure('public.admin_set_active_season_v090(uuid)') is not null then 'PASS' else 'FAIL' end,'Activation de saison'),
      ('rpc.admin_set_season_status_v090','Multi-saison',case when to_regprocedure('public.admin_set_season_status_v090(uuid,text)') is not null then 'PASS' else 'FAIL' end,'Statut de saison'),
      ('rpc.season_is_writable_v090','Archives',case when to_regprocedure('public.season_is_writable_v090(uuid)') is not null then 'PASS' else 'FAIL' end,'Archives en lecture seule'),
      ('rpc.guard_archived_team_mutation_v090','Archives',case when to_regprocedure('public.guard_archived_team_mutation_v090()') is not null then 'PASS' else 'FAIL' end,'Teams figÃ©es dans les archives'),
      ('rls.player_rank_history','SÃ©curitÃ©',case when exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='player_rank_history' and c.relrowsecurity) then 'PASS' else 'FAIL' end,'RLS historique de rang'),
      ('rls.poll_votes','SÃ©curitÃ©',case when exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='poll_votes' and c.relrowsecurity) then 'PASS' else 'FAIL' end,'RLS votes gÃ©nÃ©raux')
  ) c(id,category,status,message);

  v_checks:=coalesce(v_base->'checks','[]'::jsonb)||coalesce(v_checks_v090,'[]'::jsonb);

  select count(*)::integer,
         count(*) filter(where x->>'status'='PASS')::integer,
         count(*) filter(where x->>'status'='WARN')::integer,
         count(*) filter(where x->>'status'='FAIL')::integer
  into v_total,v_passed,v_warnings,v_failed
  from jsonb_array_elements(v_checks) x;

  return jsonb_build_object(
    'ok',v_failed=0,
    'version','0.9.0',
    'generated_at',now(),
    'summary',jsonb_build_object('total',v_total,'passed',v_passed,'warnings',v_warnings,'failed',v_failed),
    'checks',v_checks,
    'base_v081',v_base,
    'checks_v090',coalesce(v_checks_v090,'[]'::jsonb)
  );
end;
$$;
grant execute on function public.admin_run_diagnostics_v090() to authenticated;

insert into public.app_settings(key,value)
values('app_version','"0.9.0"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

commit;

select key,value,updated_at from public.app_settings where key='app_version';

