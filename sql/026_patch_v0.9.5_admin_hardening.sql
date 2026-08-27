-- Le Nid des Champions V0.9.5 — Administration & durcissement
-- Idempotent. À exécuter sur une V0.9.0 déjà migrée.
begin;

create table if not exists public.admin_backups_v095 (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  season_id uuid references public.seasons(id) on delete set null,
  scope text not null default 'season' check (scope in ('season','configuration')),
  payload jsonb not null default '{}'::jsonb,
  stats jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.account_deletion_requests_v095 (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  status text not null default 'requested' check(status in ('requested','reviewing','cancelled','processed','rejected')),
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete set null,
  admin_note text
);

alter table public.account_deletion_requests_v095 drop constraint if exists account_deletion_requests_v095_user_id_status_key;
drop index if exists account_deletion_requests_v095_open_uidx;
create unique index account_deletion_requests_v095_open_uidx on public.account_deletion_requests_v095(user_id) where status in ('requested','reviewing');

alter table public.admin_backups_v095 enable row level security;
alter table public.account_deletion_requests_v095 enable row level security;

drop policy if exists admin_backups_v095_super on public.admin_backups_v095;
create policy admin_backups_v095_super on public.admin_backups_v095 for all to authenticated
using(public.is_super_admin()) with check(public.is_super_admin());

drop policy if exists deletion_requests_v095_own_read on public.account_deletion_requests_v095;
create policy deletion_requests_v095_own_read on public.account_deletion_requests_v095 for select to authenticated
using(user_id=auth.uid() or public.is_admin());
drop policy if exists deletion_requests_v095_admin_all on public.account_deletion_requests_v095;
create policy deletion_requests_v095_admin_all on public.account_deletion_requests_v095 for all to authenticated
using(public.is_admin()) with check(public.is_admin());

grant select,insert,update,delete on public.admin_backups_v095 to authenticated;
grant select,insert,update,delete on public.account_deletion_requests_v095 to authenticated;

insert into public.app_settings(key,value) values
 ('registration_open','true'::jsonb),
 ('maintenance','false'::jsonb),
 ('feature_rivals','true'::jsonb),
 ('feature_polls','true'::jsonb),
 ('feature_api','true'::jsonb),
 ('feature_solitary_owl','true'::jsonb),
 ('feature_gamification','true'::jsonb),
 ('feature_teams','true'::jsonb),
 ('app_version','"0.9.5"'::jsonb)
on conflict(key) do nothing;
update public.app_settings set value='"0.9.5"'::jsonb,updated_at=now(),updated_by=auth.uid() where key='app_version';

create or replace function public.admin_set_app_setting_v095(p_key text,p_value jsonb,p_reason text default null)
returns void language plpgsql security definer set search_path=public as $$
declare oldv jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_key not in ('registration_open','maintenance','feature_rivals','feature_polls','feature_api','feature_solitary_owl','feature_gamification','feature_teams') then
    raise exception 'Réglage non autorisé.';
  end if;
  select value into oldv from public.app_settings where key=p_key;
  insert into public.app_settings(key,value,updated_at,updated_by) values(p_key,p_value,now(),auth.uid())
  on conflict(key) do update set value=excluded.value,updated_at=now(),updated_by=auth.uid();
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data,new_data)
  values(auth.uid(),'setting_update','app_setting',p_key,jsonb_build_object('value',oldv,'reason',p_reason),jsonb_build_object('value',p_value,'reason',p_reason));
end;$$;

create or replace function public.admin_dashboard_v095(p_season_id uuid default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare sid uuid; result jsonb;
begin
  if not public.is_admin() then raise exception 'Réservé à l’administration.'; end if;
  sid:=coalesce(p_season_id,(select id from public.seasons where is_active order by updated_at desc limit 1));
  select jsonb_build_object(
    'players_active',(select count(*) from public.profiles where status='active'),
    'players_pending',(select count(*) from public.profiles where status='pending'),
    'matches',(select count(*) from public.matches where season_id=sid),
    'matches_live',(select count(*) from public.matches where season_id=sid and status='live'),
    'matches_unfinished',(select count(*) from public.matches where season_id=sid and status not in ('finished','cancelled')),
    'teams',(select count(*) from public.teams where season_id=sid and status='active'),
    'tickets_open',(select count(*) from public.support_tickets where status not in ('fixed','resolved','closed','rejected')),
    'avatars_pending',(select count(*) from public.profiles where avatar_source='upload' and avatar_moderation_status='pending'),
    'push_failed_24h',(select count(*) from public.push_delivery_logs where status='failed' and created_at>now()-interval '24 hours'),
    'deletion_requests',(select count(*) from public.account_deletion_requests_v095 where status in ('requested','reviewing')),
    'audit_24h',(select count(*) from public.audit_logs where created_at>now()-interval '24 hours'),
    'last_match_update',(select max(updated_at) from public.matches where season_id=sid),
    'season_id',sid,
    'server_time',now()
  ) into result;
  return result;
end;$$;

create or replace function public.admin_audit_v095(
  p_limit integer default 25,p_offset integer default 0,p_action text default null,p_entity_type text default null,p_search text default null
) returns table(
  id bigint,actor_id uuid,actor_username text,action text,entity_type text,entity_id text,old_data jsonb,new_data jsonb,created_at timestamptz,total_count bigint
) language sql security definer set search_path=public as $$
  select a.id,a.actor_id,p.username::text,a.action,a.entity_type,a.entity_id,a.old_data,a.new_data,a.created_at,count(*) over()
  from public.audit_logs a left join public.profiles p on p.id=a.actor_id
  where public.is_admin()
    and (p_action is null or a.action=p_action)
    and (p_entity_type is null or a.entity_type=p_entity_type)
    and (p_search is null or p_search='' or coalesce(p.username::text,'') ilike '%'||p_search||'%' or a.action ilike '%'||p_search||'%' or a.entity_type ilike '%'||p_search||'%' or coalesce(a.entity_id,'') ilike '%'||p_search||'%')
  order by a.created_at desc
  limit greatest(1,least(coalesce(p_limit,25),100)) offset greatest(coalesce(p_offset,0),0)
$$;

create or replace function public.admin_log_impersonation_v095(p_target_user_id uuid,p_event text default 'start')
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé à l’administration.'; end if;
  if p_event not in ('start','stop') then raise exception 'Événement invalide.'; end if;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'impersonation_'||p_event,'profile',p_target_user_id::text,jsonb_build_object('target_user_id',p_target_user_id,'read_only',true));
end;$$;

create or replace function public.admin_player_preview_v095(p_user_id uuid,p_season_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare result jsonb;
begin
  if not public.is_admin() then raise exception 'Réservé à l’administration.'; end if;
  select jsonb_build_object(
    'profile',(select to_jsonb(p) from (select id,username,avatar_key,avatar_source,avatar_storage_path,avatar_moderation_status,club_heart,role,status,created_at from public.profiles where id=p_user_id) p),
    'predictions',(select coalesce(jsonb_agg(to_jsonb(x) order by x.updated_at desc),'[]'::jsonb) from (select id,match_id,home_score,away_score,points,updated_at from public.predictions where user_id=p_user_id and season_id=p_season_id) x),
    'champions',(select coalesce(jsonb_agg(to_jsonb(x) order by x.pick_number),'[]'::jsonb) from (select pick_number,club_id,assigned_default,locked_at,eliminated_at,points from public.champion_predictions where user_id=p_user_id and season_id=p_season_id) x),
    'team',(select to_jsonb(x) from (select t.id,t.name,t.visibility,t.status,(t.captain_user_id=p_user_id) as is_captain from public.team_memberships tm join public.teams t on t.id=tm.team_id where tm.user_id=p_user_id and tm.season_id=p_season_id and tm.left_at is null limit 1) x),
    'notifications_unread',(select count(*) from public.notifications where user_id=p_user_id and deleted_at is null and read_at is null),
    'season_id',p_season_id
  ) into result;
  return result;
end;$$;

create or replace function public.admin_create_backup_v095(p_label text,p_season_id uuid default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare sid uuid; bid uuid; payload jsonb; stats jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  sid:=coalesce(p_season_id,(select id from public.seasons where is_active order by updated_at desc limit 1));
  if sid is null then raise exception 'Aucune saison à sauvegarder.'; end if;
  payload:=jsonb_build_object(
    'schema_version','0.9.5','created_at',now(),
    'season',(select to_jsonb(s) from public.seasons s where s.id=sid),
    'competition_phases',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.competition_phases x where x.season_id=sid),
    'matchdays',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.matchdays x where x.season_id=sid),
    'knockout_ties',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.knockout_ties x where x.season_id=sid),
    'matches',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.matches x where x.season_id=sid),
    'predictions',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.predictions x where x.season_id=sid),
    'champion_predictions',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.champion_predictions x where x.season_id=sid),
    'tie_predictions',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.tie_predictions x where x.season_id=sid),
    'teams',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.teams x where x.season_id=sid),
    'team_memberships',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.team_memberships x where x.season_id=sid),
    'team_join_requests',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.team_join_requests x where x.season_id=sid),
    'team_invites',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.team_invites x where x.team_id in(select id from public.teams where season_id=sid)),
    'gamification_settings',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.gamification_settings x where x.season_id=sid),
    'gamification_events',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.gamification_events x where x.season_id=sid),
    'gamification_records',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.gamification_records x where x.season_id=sid),
    'player_badges',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.player_badges x where x.season_id=sid),
    'player_rank_history',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.player_rank_history x where x.season_id=sid),
    'season_memory_events',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.season_memory_events x where x.season_id=sid),
    'monthly_polls',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.monthly_polls x where x.season_id=sid),
    'monthly_poll_candidates',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.monthly_poll_candidates x where x.poll_id in(select id from public.monthly_polls where season_id=sid)),
    'monthly_poll_votes',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.monthly_poll_votes x where x.poll_id in(select id from public.monthly_polls where season_id=sid)),
    'polls',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.polls x where x.season_id=sid),
    'poll_options',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.poll_options x where x.poll_id in(select id from public.polls where season_id=sid)),
    'poll_votes',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.poll_votes x where x.poll_id in(select id from public.polls where season_id=sid)),
    'ucl_matches',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.ucl_matches x where x.season_id=sid),
    'ucl_standings',(select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) from public.ucl_standings x where x.season_id=sid)
  );
  stats:=jsonb_build_object(
    'matches',(select count(*) from public.matches where season_id=sid),
    'predictions',(select count(*) from public.predictions where season_id=sid),
    'players',(select count(distinct user_id) from public.predictions where season_id=sid),
    'teams',(select count(*) from public.teams where season_id=sid),
    'memory_events',(select count(*) from public.season_memory_events where season_id=sid)
  );
  insert into public.admin_backups_v095(label,season_id,payload,stats,created_by) values(coalesce(nullif(trim(p_label),''),'Sauvegarde '||to_char(now(),'YYYY-MM-DD HH24:MI')),sid,payload,stats,auth.uid()) returning id into bid;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data) values(auth.uid(),'backup_create','admin_backup',bid::text,stats);
  return bid;
end;$$;

create or replace function public.admin_delete_backup_v095(p_backup_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  delete from public.admin_backups_v095 where id=p_backup_id;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id) values(auth.uid(),'backup_delete','admin_backup',p_backup_id::text);
end;$$;

create or replace function public.request_account_deletion_v095(p_reason text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare rid uuid;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if exists(select 1 from public.account_deletion_requests_v095 where user_id=auth.uid() and status in ('requested','reviewing')) then
    select id into rid from public.account_deletion_requests_v095 where user_id=auth.uid() and status in ('requested','reviewing') order by requested_at desc limit 1;
    return rid;
  end if;
  insert into public.account_deletion_requests_v095(user_id,reason) values(auth.uid(),nullif(trim(p_reason),'')) returning id into rid;
  return rid;
end;$$;

create or replace function public.admin_process_account_deletion_v095(p_request_id uuid,p_decision text,p_note text default null)
returns void language plpgsql security definer set search_path=public as $$
declare r public.account_deletion_requests_v095%rowtype;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  select * into r from public.account_deletion_requests_v095 where id=p_request_id for update;
  if not found then raise exception 'Demande introuvable.'; end if;
  if p_decision not in ('reviewing','rejected','processed') then raise exception 'Décision invalide.'; end if;
  if p_decision='processed' then
    update public.profiles set username='Joueur supprimé '||left(r.user_id::text,8),club_heart=null,status='deleted',updated_at=now() where id=r.user_id;
    update public.profile_private set first_name=null where user_id=r.user_id;
    update public.push_subscriptions set active=false,disabled_at=now() where user_id=r.user_id;
  end if;
  update public.account_deletion_requests_v095 set status=p_decision,reviewed_at=now(),reviewed_by=auth.uid(),admin_note=p_note where id=p_request_id;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data) values(auth.uid(),'account_deletion_'||p_decision,'profile',r.user_id::text,jsonb_build_object('request_id',p_request_id,'note',p_note));
end;$$;

create or replace function public.admin_diagnostics_v095()
returns table(section text,test text,status text,detail text) language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé à l’administration.'; end if;
  return query
  select 'Version','Backend',case when exists(select 1 from public.app_settings where key='app_version' and value='"0.9.5"'::jsonb) then 'PASS' else 'FAIL' end,'app_version=0.9.5'
  union all select 'Sécurité','RLS backups',case when (select relrowsecurity from pg_class where oid='public.admin_backups_v095'::regclass) then 'PASS' else 'FAIL' end,'admin_backups_v095'
  union all select 'Sécurité','RLS suppressions',case when (select relrowsecurity from pg_class where oid='public.account_deletion_requests_v095'::regclass) then 'PASS' else 'FAIL' end,'account_deletion_requests_v095'
  union all select 'Administration','Réglages',case when (select count(*) from public.app_settings where key in ('maintenance','registration_open','feature_rivals','feature_polls','feature_api','feature_solitary_owl','feature_gamification','feature_teams'))=8 then 'PASS' else 'FAIL' end,'8 réglages attendus'
  union all select 'Administration','Audit',case when to_regclass('public.audit_logs') is not null then 'PASS' else 'FAIL' end,'audit_logs'
  union all select 'Administration','Sauvegardes',case when to_regclass('public.admin_backups_v095') is not null then 'PASS' else 'FAIL' end,'Snapshots serveur';
end;$$;

grant execute on function public.admin_set_app_setting_v095(text,jsonb,text) to authenticated;
grant execute on function public.admin_dashboard_v095(uuid) to authenticated;
grant execute on function public.admin_audit_v095(integer,integer,text,text,text) to authenticated;
grant execute on function public.admin_log_impersonation_v095(uuid,text) to authenticated;
grant execute on function public.admin_player_preview_v095(uuid,uuid) to authenticated;
grant execute on function public.admin_create_backup_v095(text,uuid) to authenticated;
grant execute on function public.admin_delete_backup_v095(uuid) to authenticated;
grant execute on function public.request_account_deletion_v095(text) to authenticated;
grant execute on function public.admin_process_account_deletion_v095(uuid,text,text) to authenticated;
grant execute on function public.admin_diagnostics_v095() to authenticated;

commit;

begin;
create or replace function public.admin_restore_backup_v095(p_backup_id uuid,p_confirmation text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare b public.admin_backups_v095%rowtype; sid uuid; srow public.seasons%rowtype;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_confirmation <> 'RESTAURER' then raise exception 'Confirmation invalide.'; end if;
  select * into b from public.admin_backups_v095 where id=p_backup_id;
  if not found then raise exception 'Sauvegarde introuvable.'; end if;
  sid:=b.season_id;
  if sid is null then raise exception 'Cette sauvegarde ne contient pas de saison.'; end if;
  select * into srow from jsonb_populate_record(null::public.seasons,b.payload->'season');
  set constraints all deferred;

  delete from public.monthly_poll_votes where poll_id in(select id from public.monthly_polls where season_id=sid);
  delete from public.monthly_poll_candidates where poll_id in(select id from public.monthly_polls where season_id=sid);
  delete from public.monthly_polls where season_id=sid;
  delete from public.poll_votes where poll_id in(select id from public.polls where season_id=sid);
  delete from public.poll_options where poll_id in(select id from public.polls where season_id=sid);
  delete from public.polls where season_id=sid;
  delete from public.player_rank_history where season_id=sid;
  delete from public.player_badges where season_id=sid;
  delete from public.gamification_records where season_id=sid;
  delete from public.gamification_events where season_id=sid;
  delete from public.gamification_settings where season_id=sid;
  delete from public.team_invites where team_id in(select id from public.teams where season_id=sid);
  delete from public.team_join_requests where season_id=sid;
  delete from public.team_memberships where season_id=sid;
  delete from public.teams where season_id=sid;
  delete from public.tie_predictions where season_id=sid;
  delete from public.champion_predictions where season_id=sid;
  delete from public.predictions where season_id=sid;
  delete from public.matches where season_id=sid;
  delete from public.knockout_ties where season_id=sid;
  delete from public.matchdays where season_id=sid;
  delete from public.competition_phases where season_id=sid;
  delete from public.season_memory_events where season_id=sid;
  delete from public.ucl_standings where season_id=sid;
  delete from public.ucl_matches where season_id=sid;

  if srow.is_active then update public.seasons set is_active=false where id<>sid; end if;
  update public.seasons set name=srow.name,slug=srow.slug,status=srow.status,timezone=srow.timezone,is_active=srow.is_active,
    points_wrong=srow.points_wrong,points_result=srow.points_result,points_difference=srow.points_difference,points_exact=srow.points_exact,
    champion_1_bonus=srow.champion_1_bonus,champion_2_bonus=srow.champion_2_bonus,updated_at=now() where id=sid;

  insert into public.competition_phases select * from jsonb_populate_recordset(null::public.competition_phases,b.payload->'competition_phases');
  insert into public.matchdays select * from jsonb_populate_recordset(null::public.matchdays,b.payload->'matchdays');
  insert into public.knockout_ties select * from jsonb_populate_recordset(null::public.knockout_ties,b.payload->'knockout_ties');
  insert into public.matches select * from jsonb_populate_recordset(null::public.matches,b.payload->'matches');
  insert into public.predictions select * from jsonb_populate_recordset(null::public.predictions,b.payload->'predictions');
  insert into public.champion_predictions select * from jsonb_populate_recordset(null::public.champion_predictions,b.payload->'champion_predictions');
  insert into public.tie_predictions select * from jsonb_populate_recordset(null::public.tie_predictions,b.payload->'tie_predictions');
  insert into public.teams select * from jsonb_populate_recordset(null::public.teams,b.payload->'teams');
  insert into public.team_memberships select * from jsonb_populate_recordset(null::public.team_memberships,b.payload->'team_memberships');
  insert into public.team_join_requests select * from jsonb_populate_recordset(null::public.team_join_requests,b.payload->'team_join_requests');
  insert into public.team_invites select * from jsonb_populate_recordset(null::public.team_invites,b.payload->'team_invites');
  insert into public.gamification_settings select * from jsonb_populate_recordset(null::public.gamification_settings,b.payload->'gamification_settings');
  insert into public.gamification_events select * from jsonb_populate_recordset(null::public.gamification_events,b.payload->'gamification_events');
  insert into public.gamification_records select * from jsonb_populate_recordset(null::public.gamification_records,b.payload->'gamification_records');
  insert into public.player_badges select * from jsonb_populate_recordset(null::public.player_badges,b.payload->'player_badges');
  insert into public.player_rank_history(season_id,user_id,snapshot_key,source,rank,points,exact_scores,average,precision_pct,captured_at)
    select season_id,user_id,snapshot_key,source,rank,points,exact_scores,average,precision_pct,captured_at
    from jsonb_populate_recordset(null::public.player_rank_history,b.payload->'player_rank_history');
  insert into public.season_memory_events select * from jsonb_populate_recordset(null::public.season_memory_events,b.payload->'season_memory_events');
  insert into public.monthly_polls select * from jsonb_populate_recordset(null::public.monthly_polls,b.payload->'monthly_polls');
  insert into public.monthly_poll_candidates select * from jsonb_populate_recordset(null::public.monthly_poll_candidates,b.payload->'monthly_poll_candidates');
  insert into public.monthly_poll_votes select * from jsonb_populate_recordset(null::public.monthly_poll_votes,b.payload->'monthly_poll_votes');
  insert into public.polls select * from jsonb_populate_recordset(null::public.polls,b.payload->'polls');
  insert into public.poll_options select * from jsonb_populate_recordset(null::public.poll_options,b.payload->'poll_options');
  insert into public.poll_votes select * from jsonb_populate_recordset(null::public.poll_votes,b.payload->'poll_votes');
  insert into public.ucl_matches select * from jsonb_populate_recordset(null::public.ucl_matches,b.payload->'ucl_matches');
  insert into public.ucl_standings select * from jsonb_populate_recordset(null::public.ucl_standings,b.payload->'ucl_standings');

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'backup_restore','admin_backup',p_backup_id::text,b.stats);
  return jsonb_build_object('ok',true,'season_id',sid,'stats',b.stats);
end;$$;
grant execute on function public.admin_restore_backup_v095(uuid,text) to authenticated;
commit;
