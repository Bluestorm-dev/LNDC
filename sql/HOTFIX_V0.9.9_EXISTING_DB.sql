-- Le Nid des Champions — V0.9.9
-- Pré-saison / répétition générale avant V1.0.0
-- Toutes les données de simulation sont isolées des tables de production.

begin;

create table if not exists public.preseason_runs_v099 (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  label text not null,
  status text not null default 'prepared' check (status in ('prepared','running','completed')),
  config jsonb not null default '{}'::jsonb,
  stats jsonb not null default '{}'::jsonb,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now()
);
create index if not exists preseason_runs_v099_season_idx on public.preseason_runs_v099(season_id,created_at desc);

create table if not exists public.preseason_virtual_players_v099 (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.preseason_runs_v099(id) on delete cascade,
  ordinal integer not null,
  username text not null,
  avatar_key text,
  created_at timestamptz not null default now(),
  unique(run_id,ordinal), unique(run_id,username)
);

create table if not exists public.preseason_virtual_teams_v099 (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.preseason_runs_v099(id) on delete cascade,
  ordinal integer not null,
  name text not null,
  captain_player_id uuid references public.preseason_virtual_players_v099(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(run_id,ordinal), unique(run_id,name)
);

create table if not exists public.preseason_virtual_team_members_v099 (
  run_id uuid not null references public.preseason_runs_v099(id) on delete cascade,
  team_id uuid not null references public.preseason_virtual_teams_v099(id) on delete cascade,
  player_id uuid not null references public.preseason_virtual_players_v099(id) on delete cascade,
  role text not null default 'member' check(role in ('captain','member')),
  primary key(run_id,player_id)
);

create table if not exists public.preseason_virtual_matches_v099 (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.preseason_runs_v099(id) on delete cascade,
  ordinal integer not null,
  phase text not null,
  matchday_number integer,
  home_label text not null,
  away_label text not null,
  kickoff_at timestamptz not null,
  status text not null default 'scheduled' check(status in ('scheduled','live','finished','cancelled')),
  home_score integer,
  away_score integer,
  updated_at timestamptz not null default now(),
  unique(run_id,ordinal)
);
create index if not exists preseason_virtual_matches_v099_run_idx on public.preseason_virtual_matches_v099(run_id,status,ordinal);

create table if not exists public.preseason_virtual_predictions_v099 (
  id bigint generated always as identity primary key,
  run_id uuid not null references public.preseason_runs_v099(id) on delete cascade,
  player_id uuid not null references public.preseason_virtual_players_v099(id) on delete cascade,
  match_id uuid not null references public.preseason_virtual_matches_v099(id) on delete cascade,
  home_score integer not null check(home_score between 0 and 99),
  away_score integer not null check(away_score between 0 and 99),
  points integer not null default 0,
  created_at timestamptz not null default now(),
  unique(run_id,player_id,match_id)
);
create index if not exists preseason_virtual_predictions_v099_run_idx on public.preseason_virtual_predictions_v099(run_id,player_id);

create table if not exists public.preseason_champion_picks_v099 (
  run_id uuid not null references public.preseason_runs_v099(id) on delete cascade,
  player_id uuid not null references public.preseason_virtual_players_v099(id) on delete cascade,
  champion_1 text not null,
  champion_2 text,
  bonus_points integer not null default 0,
  primary key(run_id,player_id)
);

create table if not exists public.preseason_awards_v099 (
  id bigint generated always as identity primary key,
  run_id uuid not null references public.preseason_runs_v099(id) on delete cascade,
  player_id uuid references public.preseason_virtual_players_v099(id) on delete cascade,
  award_type text not null,
  code text not null,
  label text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(run_id,player_id,award_type,code)
);

create table if not exists public.preseason_events_v099 (
  id bigint generated always as identity primary key,
  run_id uuid not null references public.preseason_runs_v099(id) on delete cascade,
  step text not null,
  event_type text not null,
  detail text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists preseason_events_v099_run_idx on public.preseason_events_v099(run_id,created_at);

create table if not exists public.preseason_load_samples_v099 (
  id bigint generated always as identity primary key,
  run_id uuid not null references public.preseason_runs_v099(id) on delete cascade,
  actor_no integer not null,
  event_no integer not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists preseason_load_samples_v099_run_idx on public.preseason_load_samples_v099(run_id);

create table if not exists public.user_onboarding_v099 (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  tutorial_version text not null default '0.9.9',
  current_step integer not null default 0 check(current_step between 0 and 20),
  completed_at timestamptz,
  dismissed_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.preseason_runs_v099 enable row level security;
alter table public.preseason_virtual_players_v099 enable row level security;
alter table public.preseason_virtual_teams_v099 enable row level security;
alter table public.preseason_virtual_team_members_v099 enable row level security;
alter table public.preseason_virtual_matches_v099 enable row level security;
alter table public.preseason_virtual_predictions_v099 enable row level security;
alter table public.preseason_champion_picks_v099 enable row level security;
alter table public.preseason_awards_v099 enable row level security;
alter table public.preseason_events_v099 enable row level security;
alter table public.preseason_load_samples_v099 enable row level security;
alter table public.user_onboarding_v099 enable row level security;

do $$ declare t text; begin
  foreach t in array array[
    'preseason_runs_v099','preseason_virtual_players_v099','preseason_virtual_teams_v099',
    'preseason_virtual_team_members_v099','preseason_virtual_matches_v099','preseason_virtual_predictions_v099',
    'preseason_champion_picks_v099','preseason_awards_v099','preseason_events_v099','preseason_load_samples_v099'
  ] loop
    execute format('drop policy if exists %I on public.%I','preseason_superadmin_v099_'||t,t);
    execute format('create policy %I on public.%I for all to authenticated using (public.is_super_admin()) with check (public.is_super_admin())','preseason_superadmin_v099_'||t,t);
  end loop;
end $$;

drop policy if exists onboarding_v099_read on public.user_onboarding_v099;
create policy onboarding_v099_read on public.user_onboarding_v099 for select to authenticated using(user_id=auth.uid() or public.is_admin());

grant select,insert,update,delete on public.preseason_runs_v099,public.preseason_virtual_players_v099,public.preseason_virtual_teams_v099,public.preseason_virtual_team_members_v099,public.preseason_virtual_matches_v099,public.preseason_virtual_predictions_v099,public.preseason_champion_picks_v099,public.preseason_awards_v099,public.preseason_events_v099,public.preseason_load_samples_v099 to authenticated;
grant select on public.user_onboarding_v099 to authenticated;

create or replace function public.preseason_points_v099(p_ph integer,p_pa integer,p_sh integer,p_sa integer)
returns integer language sql immutable as $$
  select case
    when p_ph is null or p_pa is null or p_sh is null or p_sa is null then 0
    when p_ph=p_sh and p_pa=p_sa then 7
    when sign(p_ph-p_pa)=sign(p_sh-p_sa) and (p_ph-p_pa)=(p_sh-p_sa) then 5
    when sign(p_ph-p_pa)=sign(p_sh-p_sa) then 3
    else 0 end;
$$;

create or replace function public.get_my_onboarding_v099()
returns jsonb language plpgsql security definer set search_path=public as $$
declare r public.user_onboarding_v099%rowtype;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  insert into public.user_onboarding_v099(user_id) values(auth.uid()) on conflict(user_id) do nothing;
  select * into r from public.user_onboarding_v099 where user_id=auth.uid();
  return to_jsonb(r);
end;$$;
grant execute on function public.get_my_onboarding_v099() to authenticated;

create or replace function public.save_my_onboarding_v099(p_step integer default 0,p_completed boolean default false,p_dismissed boolean default false)
returns jsonb language plpgsql security definer set search_path=public as $$
declare r public.user_onboarding_v099%rowtype;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  insert into public.user_onboarding_v099(user_id,current_step,completed_at,dismissed_at,updated_at)
  values(auth.uid(),greatest(0,least(coalesce(p_step,0),20)),case when p_completed then now() end,case when p_dismissed then now() end,now())
  on conflict(user_id) do update set current_step=excluded.current_step,
    completed_at=case when p_completed then now() else public.user_onboarding_v099.completed_at end,
    dismissed_at=case when p_dismissed then now() else case when p_completed then null else public.user_onboarding_v099.dismissed_at end end,
    tutorial_version='0.9.9',updated_at=now()
  returning * into r;
  return to_jsonb(r);
end;$$;
grant execute on function public.save_my_onboarding_v099(integer,boolean,boolean) to authenticated;

create or replace function public.admin_create_preseason_run_v099(
  p_season_id uuid,
  p_label text default null,
  p_players integer default 48,
  p_matches integer default 24,
  p_teams integer default 8
) returns uuid language plpgsql security definer set search_path=public as $$
declare rid uuid; i integer; player_count integer; match_count integer; team_count integer; tid uuid;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if not exists(select 1 from public.seasons where id=p_season_id) then raise exception 'Saison introuvable.'; end if;
  player_count:=greatest(4,least(coalesce(p_players,48),250));
  match_count:=greatest(8,least(coalesce(p_matches,24),80));
  team_count:=greatest(2,least(coalesce(p_teams,8),least(player_count,32)));
  insert into public.preseason_runs_v099(season_id,label,status,config,created_by)
  values(p_season_id,coalesce(nullif(trim(p_label),''),'Répétition générale '||to_char(now(),'DD/MM HH24:MI')),'prepared',jsonb_build_object('players',player_count,'matches',match_count,'teams',team_count,'schema_version','0.9.9'),auth.uid()) returning id into rid;

  insert into public.preseason_virtual_players_v099(run_id,ordinal,username,avatar_key)
  select rid,g,'Hibou TEST '||lpad(g::text,3,'0'),case when g%5=0 then 'avatar-hibou-or' when g%3=0 then 'avatar-hibou-casserole' else 'avatar-hibou-buteur' end
  from generate_series(1,player_count) g;

  for i in 1..team_count loop
    insert into public.preseason_virtual_teams_v099(run_id,ordinal,name) values(rid,i,'Team TEST '||lpad(i::text,2,'0')) returning id into tid;
  end loop;
  insert into public.preseason_virtual_team_members_v099(run_id,team_id,player_id,role)
  select rid,t.id,p.id,case when row_number() over(partition by t.id order by p.ordinal)=1 then 'captain' else 'member' end
  from public.preseason_virtual_players_v099 p
  join public.preseason_virtual_teams_v099 t on t.run_id=rid and t.ordinal=((p.ordinal-1)%team_count)+1
  where p.run_id=rid;
  update public.preseason_virtual_teams_v099 t set captain_player_id=m.player_id
  from public.preseason_virtual_team_members_v099 m where m.team_id=t.id and m.run_id=rid and m.role='captain' and t.run_id=rid;

  insert into public.preseason_virtual_matches_v099(run_id,ordinal,phase,matchday_number,home_label,away_label,kickoff_at)
  select rid,g,
    case when g<=match_count-7 then 'LEAGUE' when g<=match_count-3 then 'QUARTER_FINAL' when g<=match_count-1 then 'SEMI_FINAL' else 'FINAL' end,
    case when g<=match_count-7 then ((g-1)/4)+1 else null end,
    'Club TEST '||lpad((((g-1)*2)%36+1)::text,2,'0'),
    'Club TEST '||lpad(((g*2)%36+1)::text,2,'0'),
    now()+make_interval(hours=>g)
  from generate_series(1,match_count) g;

  insert into public.preseason_virtual_predictions_v099(run_id,player_id,match_id,home_score,away_score)
  select rid,p.id,m.id,(p.ordinal+m.ordinal)%5,(p.ordinal*2+m.ordinal)%4
  from public.preseason_virtual_players_v099 p cross join public.preseason_virtual_matches_v099 m
  where p.run_id=rid and m.run_id=rid;

  insert into public.preseason_champion_picks_v099(run_id,player_id,champion_1,champion_2)
  select rid,p.id,'Club TEST '||lpad(((p.ordinal%8)+1)::text,2,'0'),'Club TEST '||lpad(((p.ordinal%4)+1)::text,2,'0')
  from public.preseason_virtual_players_v099 p where p.run_id=rid;

  insert into public.preseason_events_v099(run_id,step,event_type,detail,payload)
  values(rid,'setup','run_created','Environnement de répétition créé sans toucher aux matchs, pronostics ou utilisateurs réels.',jsonb_build_object('players',player_count,'matches',match_count,'teams',team_count));
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'preseason_create_v099','preseason_run',rid::text,jsonb_build_object('players',player_count,'matches',match_count,'teams',team_count));
  return rid;
end;$$;
grant execute on function public.admin_create_preseason_run_v099(uuid,text,integer,integer,integer) to authenticated;

create or replace function public.get_preseason_dashboard_v099(p_run_id uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare result jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if not exists(select 1 from public.preseason_runs_v099 where id=p_run_id) then raise exception 'Répétition introuvable.'; end if;
  select jsonb_build_object(
    'run',(select to_jsonb(x) from (select id,season_id,label,status,config,stats,created_at,started_at,completed_at,updated_at from public.preseason_runs_v099 where id=p_run_id) x),
    'counts',jsonb_build_object(
      'players',(select count(*) from public.preseason_virtual_players_v099 where run_id=p_run_id),
      'teams',(select count(*) from public.preseason_virtual_teams_v099 where run_id=p_run_id),
      'matches',(select count(*) from public.preseason_virtual_matches_v099 where run_id=p_run_id),
      'scheduled',(select count(*) from public.preseason_virtual_matches_v099 where run_id=p_run_id and status='scheduled'),
      'live',(select count(*) from public.preseason_virtual_matches_v099 where run_id=p_run_id and status='live'),
      'finished',(select count(*) from public.preseason_virtual_matches_v099 where run_id=p_run_id and status='finished'),
      'predictions',(select count(*) from public.preseason_virtual_predictions_v099 where run_id=p_run_id),
      'awards',(select count(*) from public.preseason_awards_v099 where run_id=p_run_id),
      'events',(select count(*) from public.preseason_events_v099 where run_id=p_run_id),
      'load_rows',(select count(*) from public.preseason_load_samples_v099 where run_id=p_run_id)
    ),
    'steps',(select coalesce(jsonb_agg(distinct step),'[]'::jsonb) from public.preseason_events_v099 where run_id=p_run_id),
    'points',jsonb_build_object(
      'zero',(select count(*) from public.preseason_virtual_predictions_v099 where run_id=p_run_id and points=0),
      'three',(select count(*) from public.preseason_virtual_predictions_v099 where run_id=p_run_id and points=3),
      'five',(select count(*) from public.preseason_virtual_predictions_v099 where run_id=p_run_id and points=5),
      'seven',(select count(*) from public.preseason_virtual_predictions_v099 where run_id=p_run_id and points=7)
    ),
    'recent_events',(select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb) from (select id,step,event_type,detail,payload,created_at from public.preseason_events_v099 where run_id=p_run_id order by created_at desc limit 12) x)
  ) into result;
  return result;
end;$$;
grant execute on function public.get_preseason_dashboard_v099(uuid) to authenticated;

create or replace function public.admin_preseason_step_v099(p_run_id uuid,p_step text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare step text:=lower(trim(coalesce(p_step,''))); sid uuid; nid uuid; winner text:='Club TEST 01';
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  select season_id into sid from public.preseason_runs_v099 where id=p_run_id;
  if sid is null then raise exception 'Répétition introuvable.'; end if;
  update public.preseason_runs_v099 set status='running',started_at=coalesce(started_at,now()),updated_at=now() where id=p_run_id;

  if step='live' then
    update public.preseason_virtual_matches_v099 set status='live',home_score=case when ordinal%2=0 then 1 else 0 end,away_score=case when ordinal%3=0 then 1 else 0 end,updated_at=now()
    where run_id=p_run_id and id in (select id from public.preseason_virtual_matches_v099 where run_id=p_run_id and status='scheduled' order by ordinal limit 3);
    insert into public.preseason_events_v099(run_id,step,event_type,detail) values(p_run_id,step,'live_started','Trois rencontres virtuelles sont passées LIVE.');
  elsif step='scores' then
    update public.preseason_virtual_matches_v099 set status='finished',home_score=(ordinal*3)%5,away_score=(ordinal*2)%4,updated_at=now()
    where run_id=p_run_id and phase='LEAGUE';
    update public.preseason_virtual_predictions_v099 p set points=public.preseason_points_v099(p.home_score,p.away_score,m.home_score,m.away_score)
    from public.preseason_virtual_matches_v099 m where p.match_id=m.id and p.run_id=p_run_id and m.run_id=p_run_id and m.status='finished';
    insert into public.preseason_events_v099(run_id,step,event_type,detail) values(p_run_id,step,'league_finished','La phase de ligue virtuelle est terminée et le barème 0/3/5/7 a été recalculé.');
  elsif step='champion' then
    update public.preseason_champion_picks_v099 set bonus_points=case when champion_1=winner then 100 else 0 end where run_id=p_run_id;
    insert into public.preseason_events_v099(run_id,step,event_type,detail,payload) values(p_run_id,step,'champion_resolved','Le vainqueur virtuel a été résolu.',jsonb_build_object('winner',winner));
  elsif step='teams' then
    insert into public.preseason_events_v099(run_id,step,event_type,detail,payload)
    values(p_run_id,step,'teams_checked','Les Teams virtuelles et leurs capitaines sont prêtes pour le contrôle.',jsonb_build_object('teams',(select count(*) from public.preseason_virtual_teams_v099 where run_id=p_run_id)));
  elsif step='badges' then
    insert into public.preseason_awards_v099(run_id,player_id,award_type,code,label)
    select p_run_id,p.id,'badge','badge-premier-exact','Dans le mille' from public.preseason_virtual_players_v099 p where p.run_id=p_run_id and p.ordinal<=8 on conflict do nothing;
    insert into public.preseason_awards_v099(run_id,player_id,award_type,code,label)
    select p_run_id,p.id,'casserole','preseason-casserole','Casserole TEST' from public.preseason_virtual_players_v099 p where p.run_id=p_run_id and p.ordinal in (9,18,27) on conflict do nothing;
    insert into public.preseason_awards_v099(run_id,player_id,award_type,code,label)
    select p_run_id,p.id,'genius','preseason-genius','Coup de Génie TEST' from public.preseason_virtual_players_v099 p where p.run_id=p_run_id and p.ordinal in (5,15,25) on conflict do nothing;
    insert into public.preseason_events_v099(run_id,step,event_type,detail) values(p_run_id,step,'awards_generated','Badges, Casseroles et Coups de Génie virtuels générés.');
  elsif step='notifications' then
    begin
      nid:=public.admin_send_gamification_test_notification_v070(auth.uid(),sid,'Répétition générale V0.9.9','Notification TEST ciblée uniquement vers ton compte Super Admin.',false);
    exception when others then nid:=null; end;
    insert into public.preseason_events_v099(run_id,step,event_type,detail,payload) values(p_run_id,step,'notification_test','Notification interne TEST envoyée uniquement au Super Admin courant.',jsonb_build_object('notification_id',nid));
  elsif step='finale' then
    update public.preseason_virtual_matches_v099 set status='finished',home_score=case when phase='FINAL' then 2 else (ordinal*3)%4 end,away_score=case when phase='FINAL' then 1 else (ordinal*2)%3 end,updated_at=now()
    where run_id=p_run_id and phase<>'LEAGUE';
    update public.preseason_virtual_predictions_v099 p set points=public.preseason_points_v099(p.home_score,p.away_score,m.home_score,m.away_score)
    from public.preseason_virtual_matches_v099 m where p.match_id=m.id and p.run_id=p_run_id and m.run_id=p_run_id and m.status='finished';
    insert into public.preseason_events_v099(run_id,step,event_type,detail) values(p_run_id,step,'final_finished','La finale virtuelle est terminée 2–1.');
  elsif step='pdf' then
    insert into public.preseason_events_v099(run_id,step,event_type,detail) values(p_run_id,step,'pdf_smoke','Étape PDF marquée : prévisualiser Collector, carnet et diplôme depuis V0.9.8.');
  elsif step='complete' then
    update public.preseason_runs_v099 set status='completed',completed_at=now(),updated_at=now() where id=p_run_id;
    insert into public.preseason_events_v099(run_id,step,event_type,detail) values(p_run_id,step,'rehearsal_complete','Répétition générale marquée terminée.');
  else
    raise exception 'Étape inconnue : %',step;
  end if;
  return public.get_preseason_dashboard_v099(p_run_id);
end;$$;
grant execute on function public.admin_preseason_step_v099(uuid,text) to authenticated;

create or replace function public.admin_preseason_load_test_v099(p_run_id uuid,p_rows integer default 20000)
returns jsonb language plpgsql security definer set search_path=public as $$
declare n integer:=greatest(100,least(coalesce(p_rows,20000),100000)); t0 timestamptz:=clock_timestamp(); elapsed numeric;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if not exists(select 1 from public.preseason_runs_v099 where id=p_run_id) then raise exception 'Répétition introuvable.'; end if;
  delete from public.preseason_load_samples_v099 where run_id=p_run_id;
  insert into public.preseason_load_samples_v099(run_id,actor_no,event_no,payload)
  select p_run_id,((g-1)%250)+1,g,jsonb_build_object('score',g%8,'rank',(g%50)+1,'probe',md5(g::text)) from generate_series(1,n) g;
  elapsed:=round((extract(epoch from (clock_timestamp()-t0))*1000)::numeric,2);
  update public.preseason_runs_v099 set stats=coalesce(stats,'{}'::jsonb)||jsonb_build_object('load_test',jsonb_build_object('rows',n,'duration_ms',elapsed,'tested_at',now())),updated_at=now() where id=p_run_id;
  insert into public.preseason_events_v099(run_id,step,event_type,detail,payload) values(p_run_id,'load','load_test','Écriture/lecture de charge dans le bac à sable.',jsonb_build_object('rows',n,'duration_ms',elapsed));
  return jsonb_build_object('ok',true,'rows',n,'duration_ms',elapsed);
end;$$;
grant execute on function public.admin_preseason_load_test_v099(uuid,integer) to authenticated;

create or replace function public.admin_cleanup_preseason_v099(p_run_id uuid,p_confirmation text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare label text;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_confirmation<>'NETTOYER' then raise exception 'Confirmation invalide. Tape NETTOYER.'; end if;
  select r.label into label from public.preseason_runs_v099 r where r.id=p_run_id;
  if label is null then raise exception 'Répétition introuvable.'; end if;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data) values(auth.uid(),'preseason_cleanup_v099','preseason_run',p_run_id::text,jsonb_build_object('label',label));
  delete from public.preseason_runs_v099 where id=p_run_id;
  return jsonb_build_object('ok',true,'deleted_run',p_run_id,'label',label);
end;$$;
grant execute on function public.admin_cleanup_preseason_v099(uuid,text) to authenticated;

create or replace function public.admin_diagnostics_v099()
returns table(section text,test text,status text,detail text)
language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé à l’administration.'; end if;
  return query
  select 'V0.9.9','Bac à sable',case when to_regclass('public.preseason_runs_v099') is not null then 'PASS' else 'FAIL' end,'preseason_runs_v099'
  union all select 'V0.9.9','Joueurs virtuels',case when to_regclass('public.preseason_virtual_players_v099') is not null then 'PASS' else 'FAIL' end,'preseason_virtual_players_v099'
  union all select 'V0.9.9','Matchs virtuels',case when to_regclass('public.preseason_virtual_matches_v099') is not null then 'PASS' else 'FAIL' end,'preseason_virtual_matches_v099'
  union all select 'V0.9.9','Charge',case when to_regprocedure('public.admin_preseason_load_test_v099(uuid,integer)') is not null then 'PASS' else 'FAIL' end,'admin_preseason_load_test_v099'
  union all select 'V0.9.9','Nettoyage',case when to_regprocedure('public.admin_cleanup_preseason_v099(uuid,text)') is not null then 'PASS' else 'FAIL' end,'admin_cleanup_preseason_v099'
  union all select 'V0.9.9','Onboarding',case when to_regclass('public.user_onboarding_v099') is not null and to_regprocedure('public.get_my_onboarding_v099()') is not null then 'PASS' else 'FAIL' end,'user_onboarding_v099'
  union all select 'V0.9.9','Textes Hibou',case when (select count(*) from public.gamification_text_templates where event_key like 'v099_%' and active)>=10 then 'PASS' else 'FAIL' end,'10+ textes V0.9.9'
  union all select 'V0.9.9','Version',case when exists(select 1 from public.app_settings where key='app_version' and value='"0.9.9"'::jsonb) then 'PASS' else 'FAIL' end,'app_settings.app_version';
end;$$;
grant execute on function public.admin_diagnostics_v099() to authenticated;

insert into public.gamification_text_templates(event_key,tone,template,weight,active) values
('v099_onboarding_welcome','sage','Bienvenue dans le Nid. Ici, un pronostic se fait vite, mais une saison peut devenir une légende.',1,true),
('v099_onboarding_welcome','piquant','Bienvenue. Le Hibou a préparé le Nid ; à toi d’éviter de préparer les casseroles.',1,true),
('v099_first_prediction','sage','Premier pronostic enregistré. Une petite ligne de score, neuf mois de conséquences.',1,true),
('v099_first_prediction','sans_pitie','Premier prono. Tu peux encore prétendre que tout était calculé.',1,true),
('v099_live','piquant','Le LIVE est lancé. À partir de maintenant, chaque but peut ruiner une soirée parfaitement tranquille.',1,true),
('v099_exact','sage','Dans le mille. Le score exact est ce bref moment où le Hibou acquiesce sans ironie.',1,true),
('v099_casserole','sans_pitie','La casserole est chaude. Inutile de chercher une excuse, elle est déjà gravée dans le Nid.',1,true),
('v099_genius','piquant','Coup de Génie. Même le Hibou hésite entre applaudir et vérifier les probabilités.',1,true),
('v099_champion_locked','sage','Ton champion est verrouillé. À présent, il ne reste plus qu’à lui expliquer la pression.',1,true),
('v099_team_joined','piquant','Une Team de plus dans le Nid. Statistiquement, cela augmente surtout le nombre de personnes capables de se moquer de toi.',1,true),
('v099_final','sage','La finale est là. Tout ce qui semblait lointain en septembre tient maintenant dans quatre-vingt-dix minutes.',1,true),
('v099_season_end','sage','La saison se referme, mais le Nid garde les traces : classements, records, badges et souvenirs.',1,true),
('v099_tutorial_done','piquant','Tutoriel terminé. Le Hibou retire les petites roues. Bonne chance.',1,true),
('v099_maintenance','sage','Le Nid est momentanément fermé. Le Hibou resserre quelques boulons et revient.',1,true)
on conflict(event_key,tone,template) do update set active=true,weight=excluded.weight;

insert into public.app_settings(key,value)
values('app_version','"0.9.9"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;
