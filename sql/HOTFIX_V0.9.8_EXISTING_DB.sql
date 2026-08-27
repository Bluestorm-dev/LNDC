-- =============================================================================
-- LE NID DES CHAMPIONS — V0.9.8
-- PDF A4, collector de saison, diplôme, Livre d'or, export final et archivage.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. Livre d'or : une contribution par joueur et par saison.
-- -----------------------------------------------------------------------------
create table if not exists public.season_guestbook_entries_v098 (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check (char_length(trim(message)) between 2 and 500),
  status text not null default 'published' check (status in ('published','hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  moderated_at timestamptz,
  moderated_by uuid references public.profiles(id) on delete set null,
  unique(season_id,user_id)
);
create index if not exists season_guestbook_v098_season_idx on public.season_guestbook_entries_v098(season_id,status,created_at);
drop trigger if exists season_guestbook_entries_v098_updated_at on public.season_guestbook_entries_v098;
create trigger season_guestbook_entries_v098_updated_at before update on public.season_guestbook_entries_v098
for each row execute function public.set_updated_at();

alter table public.season_guestbook_entries_v098 enable row level security;
drop policy if exists season_guestbook_v098_read on public.season_guestbook_entries_v098;
create policy season_guestbook_v098_read on public.season_guestbook_entries_v098 for select to authenticated using(
  status='published' or user_id=auth.uid() or public.is_admin()
);
grant select on public.season_guestbook_entries_v098 to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Archive finale : photographie publique et figée de la fin de saison.
--    Le payload ne contient aucune adresse e-mail ni donnée privée.
-- -----------------------------------------------------------------------------
create table if not exists public.season_final_archives_v098 (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null unique references public.seasons(id) on delete cascade,
  schema_version text not null default '0.9.8',
  snapshot jsonb not null default '{}'::jsonb,
  snapshot_hash text not null,
  stats jsonb not null default '{}'::jsonb,
  is_final boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  finalized_at timestamptz
);
drop trigger if exists season_final_archives_v098_updated_at on public.season_final_archives_v098;
create trigger season_final_archives_v098_updated_at before update on public.season_final_archives_v098
for each row execute function public.set_updated_at();

alter table public.season_final_archives_v098 enable row level security;
drop policy if exists season_final_archives_v098_read on public.season_final_archives_v098;
create policy season_final_archives_v098_read on public.season_final_archives_v098 for select to authenticated using(true);
grant select on public.season_final_archives_v098 to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Livre d'or : lecture, écriture personnelle et modération.
-- -----------------------------------------------------------------------------
create or replace function public.get_guestbook_v098(p_season_id uuid)
returns table(
  id uuid,user_id uuid,username text,avatar_key text,message text,status text,created_at timestamptz,updated_at timestamptz,is_mine boolean
)
language sql stable security definer set search_path=public as $$
  select g.id,g.user_id,p.username,p.avatar_key,g.message,g.status,g.created_at,g.updated_at,(g.user_id=auth.uid())
  from public.season_guestbook_entries_v098 g
  join public.profiles p on p.id=g.user_id
  where g.season_id=p_season_id
    and (g.status='published' or g.user_id=auth.uid() or public.is_admin())
  order by g.created_at asc,p.username asc;
$$;
grant execute on function public.get_guestbook_v098(uuid) to authenticated;

create or replace function public.save_guestbook_entry_v098(p_season_id uuid,p_message text)
returns uuid
language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_status text; v_msg text:=trim(coalesce(p_message,''));
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if char_length(v_msg) not between 2 and 500 then raise exception 'Le message doit contenir entre 2 et 500 caractères.'; end if;
  select status into v_status from public.seasons where id=p_season_id;
  if not found then raise exception 'Saison introuvable.'; end if;
  if v_status not in ('finished','archived') and not public.is_admin() then
    raise exception 'Le Livre d''or ouvre lorsque la saison est terminée.';
  end if;
  if v_status='archived' and not public.is_admin() then
    raise exception 'Le Livre d''or est figé avec les archives de la saison.';
  end if;
  insert into public.season_guestbook_entries_v098(season_id,user_id,message,status)
  values(p_season_id,auth.uid(),v_msg,'published')
  on conflict(season_id,user_id) do update set message=excluded.message,status='published',updated_at=now(),moderated_at=null,moderated_by=null
  returning id into v_id;
  return v_id;
end;$$;
grant execute on function public.save_guestbook_entry_v098(uuid,text) to authenticated;

create or replace function public.admin_set_guestbook_status_v098(p_entry_id uuid,p_status text)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé à l’administration.'; end if;
  if p_status not in ('published','hidden') then raise exception 'Statut invalide.'; end if;
  update public.season_guestbook_entries_v098
  set status=p_status,moderated_at=now(),moderated_by=auth.uid()
  where id=p_entry_id;
  if not found then raise exception 'Message introuvable.'; end if;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'guestbook_'||p_status,'guestbook',p_entry_id::text,jsonb_build_object('status',p_status));
end;$$;
grant execute on function public.admin_set_guestbook_status_v098(uuid,text) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. État de préparation à la clôture.
-- -----------------------------------------------------------------------------
create or replace function public.get_season_closeout_readiness_v098(p_season_id uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare s public.seasons%rowtype; unfinished bigint; live_count bigint; total_matches bigint; finished_matches bigint;
  players bigint; guestbook_count bigint; archive_ready boolean;
begin
  select * into s from public.seasons where id=p_season_id;
  if not found then raise exception 'Saison introuvable.'; end if;
  select count(*),count(*) filter(where status='finished'),count(*) filter(where status='live'),count(*) filter(where status not in ('finished','cancelled'))
  into total_matches,finished_matches,live_count,unfinished
  from public.matches where season_id=p_season_id and coalesce(is_test,false)=false;
  select count(*) into players from public.get_leaderboard_v040(p_season_id,'general',null,null,false);
  select count(*) into guestbook_count from public.season_guestbook_entries_v098 where season_id=p_season_id and status='published';
  archive_ready := total_matches>0 and unfinished=0 and live_count=0;
  return jsonb_build_object(
    'season_id',s.id,'season_name',s.name,'season_slug',s.slug,'status',s.status,'is_active',s.is_active,
    'total_matches',total_matches,'finished_matches',finished_matches,'unfinished_matches',unfinished,'live_matches',live_count,
    'players',players,'guestbook_entries',guestbook_count,'ready',archive_ready,
    'reason',case when total_matches=0 then 'Aucun match officiel dans la saison.' when live_count>0 then 'Des matchs sont encore LIVE.' when unfinished>0 then 'Des matchs officiels ne sont pas terminés.' else 'La saison est prête pour son archive finale.' end
  );
end;$$;
grant execute on function public.get_season_closeout_readiness_v098(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 5. Rapport final de saison : source unique des pages collector et de l'export.
-- -----------------------------------------------------------------------------
create or replace function public.get_final_season_report_v098(p_season_id uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare result jsonb;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.seasons where id=p_season_id) then raise exception 'Saison introuvable.'; end if;
  if exists(select 1 from public.seasons where id=p_season_id and status='archived') then
    select a.snapshot into result from public.season_final_archives_v098 a where a.season_id=p_season_id and a.is_final limit 1;
    if result is not null then return result; end if;
  end if;
  select jsonb_build_object(
    'schema_version','0.9.8',
    'generated_at',now(),
    'season',(select to_jsonb(x) from (select id,name,slug,status,timezone,is_active,points_wrong,points_result,points_difference,points_exact,champion_1_bonus,champion_2_bonus,created_at,updated_at from public.seasons where id=p_season_id) x),
    'readiness',public.get_season_closeout_readiness_v098(p_season_id),
    'leaderboard',(select coalesce(jsonb_agg(to_jsonb(x) order by x.rank),'[]'::jsonb) from public.get_leaderboard_v040(p_season_id,'general',null,null,false) x),
    'teams',(select coalesce(jsonb_agg(to_jsonb(x) order by x.rank_average),'[]'::jsonb) from public.get_team_leaderboard_v050(p_season_id,null) x),
    'hall_of_fame',(select coalesce(jsonb_agg(to_jsonb(x) order by x.category,x."position"),'[]'::jsonb) from public.get_hall_of_fame_v090(p_season_id) x),
    'replay',(select coalesce(jsonb_agg(to_jsonb(x) order by x.event_at,x.event_type),'[]'::jsonb) from public.get_season_replay_v090(p_season_id) x),
    'guestbook',(select coalesce(jsonb_agg(jsonb_build_object('user_id',g.user_id,'username',p.username,'avatar_key',p.avatar_key,'message',g.message,'created_at',g.created_at) order by g.created_at),'[]'::jsonb) from public.season_guestbook_entries_v098 g join public.profiles p on p.id=g.user_id where g.season_id=p_season_id and g.status='published'),
    'badges',(select coalesce(jsonb_agg(jsonb_build_object('user_id',pb.user_id,'username',p.username,'code',b.code,'name',b.name,'rarity',b.rarity,'earned_at',pb.earned_at,'image_url',coalesce(b.image_url,b.default_asset_path),'context',pb.context) order by pb.earned_at),'[]'::jsonb) from public.player_badges pb join public.gamification_badges b on b.id=pb.badge_id join public.profiles p on p.id=pb.user_id where pb.season_id=p_season_id and pb.revoked_at is null and not pb.is_test),
    'records',(select coalesce(jsonb_agg(jsonb_build_object('user_id',r.user_id,'username',p.username,'record_key',r.record_key,'record_name',r.record_name,'category',r.category,'value',r.value,'achieved_at',r.achieved_at,'metadata',r.metadata) order by r.achieved_at),'[]'::jsonb) from public.gamification_records r join public.profiles p on p.id=r.user_id where r.season_id=p_season_id and r.active and not r.is_test),
    'statistics',jsonb_build_object(
      'matches',(select count(*) from public.matches where season_id=p_season_id and coalesce(is_test,false)=false),
      'finished_matches',(select count(*) from public.matches where season_id=p_season_id and coalesce(is_test,false)=false and status='finished'),
      'predictions',(select count(*) from public.predictions where season_id=p_season_id),
      'players',(select count(*) from public.get_leaderboard_v040(p_season_id,'general',null,null,false)),
      'points',(select coalesce(sum(points),0) from public.get_leaderboard_v040(p_season_id,'general',null,null,false)),
      'exact_scores',(select coalesce(sum(exact_scores),0) from public.get_leaderboard_v040(p_season_id,'general',null,null,false)),
      'badges',(select count(*) from public.player_badges where season_id=p_season_id and revoked_at is null and not is_test),
      'records',(select count(*) from public.gamification_records where season_id=p_season_id and active and not is_test),
      'casseroles',(select count(*) from public.gamification_events where season_id=p_season_id and event_type='casserole' and is_public and not is_test),
      'genius',(select count(*) from public.gamification_events where season_id=p_season_id and event_type='genius' and is_public and not is_test),
      'teams',(select count(*) from public.teams where season_id=p_season_id),
      'guestbook',(select count(*) from public.season_guestbook_entries_v098 where season_id=p_season_id and status='published')
    )
  ) into result;
  return result;
end;$$;
grant execute on function public.get_final_season_report_v098(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Rapport personnel : carnet A4 et diplôme.
-- -----------------------------------------------------------------------------
create or replace function public.get_final_player_report_v098(p_season_id uuid,p_user_id uuid default null)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare uid uuid:=coalesce(p_user_id,auth.uid()); result jsonb;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if uid<>auth.uid() and not public.is_admin() then raise exception 'Tu ne peux ouvrir que ton propre carnet.'; end if;
  if not exists(select 1 from public.seasons where id=p_season_id) then raise exception 'Saison introuvable.'; end if;
  select jsonb_build_object(
    'schema_version','0.9.8','generated_at',now(),
    'season',(select to_jsonb(x) from (select id,name,slug,status,timezone from public.seasons where id=p_season_id) x),
    'player',(select to_jsonb(x) from (select id,username,avatar_key,avatar_source,avatar_storage_path,club_heart,role,status from public.profiles where id=uid) x),
    'season_stats',(select to_jsonb(x) from public.get_player_season_profile_v090(p_season_id,uid) x limit 1),
    'career',public.get_player_career_v090(uid),
    'team',(select to_jsonb(x) from (select t.id,t.name,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,(t.captain_user_id=uid) is_captain from public.team_memberships tm join public.teams t on t.id=tm.team_id where tm.user_id=uid and tm.season_id=p_season_id and tm.left_at is null order by tm.joined_at desc limit 1) x),
    'badges',(select coalesce(jsonb_agg(jsonb_build_object('code',b.code,'name',b.name,'description',b.description,'rarity',b.rarity,'earned_at',pb.earned_at,'image_url',coalesce(b.image_url,b.default_asset_path),'context',pb.context) order by pb.earned_at),'[]'::jsonb) from public.player_badges pb join public.gamification_badges b on b.id=pb.badge_id where pb.season_id=p_season_id and pb.user_id=uid and pb.revoked_at is null and not pb.is_test),
    'records',(select coalesce(jsonb_agg(jsonb_build_object('record_key',r.record_key,'record_name',r.record_name,'category',r.category,'value',r.value,'achieved_at',r.achieved_at,'metadata',r.metadata) order by r.achieved_at),'[]'::jsonb) from public.gamification_records r where r.season_id=p_season_id and r.user_id=uid and r.active and not r.is_test),
    'distinctions',(select coalesce(jsonb_agg(jsonb_build_object('code',d.code,'label',d.label,'description',d.description,'icon',d.icon,'awarded_at',d.awarded_at,'metadata',d.metadata) order by d.awarded_at),'[]'::jsonb) from public.player_distinctions d where d.user_id=uid and d.active),
    'hall_awards',(select coalesce(jsonb_agg(to_jsonb(x) order by x.category,x."position"),'[]'::jsonb) from public.get_hall_of_fame_v090(p_season_id) x where x.user_id=uid),
    'rank_history',(select coalesce(jsonb_agg(jsonb_build_object('snapshot_key',h.snapshot_key,'rank',h.rank,'points',h.points,'exact_scores',h.exact_scores,'average',h.average,'precision_pct',h.precision_pct,'captured_at',h.captured_at) order by h.captured_at),'[]'::jsonb) from public.player_rank_history h where h.season_id=p_season_id and h.user_id=uid),
    'guestbook',(select to_jsonb(x) from (select id,message,status,created_at,updated_at from public.season_guestbook_entries_v098 where season_id=p_season_id and user_id=uid) x)
  ) into result;
  return result;
end;$$;
grant execute on function public.get_final_player_report_v098(uuid,uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 7. Snapshot final et archivage sécurisé.
-- -----------------------------------------------------------------------------
create or replace function public.admin_create_final_archive_v098(p_season_id uuid,p_force boolean default false)
returns uuid language plpgsql security definer set search_path=public as $$
declare readiness jsonb; payload jsonb; aid uuid; h text; final_flag boolean;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  readiness:=public.get_season_closeout_readiness_v098(p_season_id);
  if coalesce((readiness->>'ready')::boolean,false)=false and not p_force then
    raise exception 'Saison non prête : %',coalesce(readiness->>'reason','contrôle incomplet');
  end if;
  perform public.capture_season_snapshot_v090(p_season_id,'final-v098','finale_v098');
  payload:=public.get_final_season_report_v098(p_season_id);
  h:=md5(payload::text);
  final_flag:=exists(select 1 from public.seasons where id=p_season_id and status in ('finished','archived'));
  insert into public.season_final_archives_v098(season_id,schema_version,snapshot,snapshot_hash,stats,is_final,created_by,finalized_at)
  values(p_season_id,'0.9.8',payload,h,coalesce(payload->'statistics','{}'::jsonb),final_flag,auth.uid(),case when final_flag then now() else null end)
  on conflict(season_id) do update set schema_version='0.9.8',snapshot=excluded.snapshot,snapshot_hash=excluded.snapshot_hash,stats=excluded.stats,is_final=excluded.is_final,created_by=auth.uid(),finalized_at=excluded.finalized_at,updated_at=now()
  returning id into aid;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'season_final_archive','season',p_season_id::text,jsonb_build_object('archive_id',aid,'hash',h,'forced',p_force,'readiness',readiness));
  return aid;
end;$$;
grant execute on function public.admin_create_final_archive_v098(uuid,boolean) to authenticated;

create or replace function public.admin_archive_season_v098(p_season_id uuid,p_confirmation text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare readiness jsonb; aid uuid;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_confirmation<>'ARCHIVER' then raise exception 'Confirmation invalide. Tape ARCHIVER.'; end if;
  readiness:=public.get_season_closeout_readiness_v098(p_season_id);
  if coalesce((readiness->>'ready')::boolean,false)=false then raise exception 'Saison non prête : %',coalesce(readiness->>'reason','contrôle incomplet'); end if;
  update public.seasons set status='finished',is_active=false,updated_at=now() where id=p_season_id;
  aid:=public.admin_create_final_archive_v098(p_season_id,false);
  update public.seasons set status='archived',is_active=false,updated_at=now() where id=p_season_id;
  update public.season_final_archives_v098 set is_final=true,finalized_at=now(),updated_at=now() where id=aid;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'season_archive_final','season',p_season_id::text,jsonb_build_object('archive_id',aid,'readiness',readiness));
  return jsonb_build_object('ok',true,'season_id',p_season_id,'archive_id',aid,'status','archived');
end;$$;
grant execute on function public.admin_archive_season_v098(uuid,text) to authenticated;

create or replace function public.get_final_archive_meta_v098(p_season_id uuid)
returns table(id uuid,schema_version text,snapshot_hash text,stats jsonb,is_final boolean,created_at timestamptz,updated_at timestamptz,finalized_at timestamptz)
language sql stable security definer set search_path=public as $$
  select a.id,a.schema_version,a.snapshot_hash,a.stats,a.is_final,a.created_at,a.updated_at,a.finalized_at
  from public.season_final_archives_v098 a where a.season_id=p_season_id;
$$;
grant execute on function public.get_final_archive_meta_v098(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 8. Diagnostic V0.9.8.
-- -----------------------------------------------------------------------------
create or replace function public.admin_diagnostics_v098()
returns table(section text,test text,status text,detail text)
language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé à l’administration.'; end if;
  return query
  select 'V0.9.8','Livre d''or',case when to_regclass('public.season_guestbook_entries_v098') is not null then 'PASS' else 'FAIL' end,'season_guestbook_entries_v098'
  union all select 'V0.9.8','Archive finale',case when to_regclass('public.season_final_archives_v098') is not null then 'PASS' else 'FAIL' end,'season_final_archives_v098'
  union all select 'V0.9.8','Rapport saison',case when to_regprocedure('public.get_final_season_report_v098(uuid)') is not null then 'PASS' else 'FAIL' end,'get_final_season_report_v098'
  union all select 'V0.9.8','Rapport joueur',case when to_regprocedure('public.get_final_player_report_v098(uuid,uuid)') is not null then 'PASS' else 'FAIL' end,'get_final_player_report_v098'
  union all select 'V0.9.8','Clôture',case when to_regprocedure('public.admin_archive_season_v098(uuid,text)') is not null then 'PASS' else 'FAIL' end,'admin_archive_season_v098'
  union all select 'V0.9.8','Version',case when exists(select 1 from public.app_settings where key='app_version' and value='"0.9.8"'::jsonb) then 'PASS' else 'FAIL' end,'app_settings.app_version';
end;$$;
grant execute on function public.admin_diagnostics_v098() to authenticated;

insert into public.app_settings(key,value)
values('app_version','"0.9.8"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;
