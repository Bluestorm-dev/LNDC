-- Le Nid des Champions — V0.9.11
-- Betclic expérimental + ouverture progressive des fonctions + nettoyage communication.
-- Ce patch est cumulatif pour une base V0.9.10 et répare aussi les RPC reset/fusion connues.
begin;

-- ---------------------------------------------------------------------------
-- 1. Réparations cumulatives V0.9.10 R5
-- ---------------------------------------------------------------------------
create or replace function public.admin_prelaunch_reset_v0910(p_season_id uuid,p_confirmation text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_first timestamptz; v_season_created timestamptz; v_result jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_confirmation<>'RESET AVANT OUVERTURE' then raise exception 'Confirmation invalide.'; end if;
  select min(m.kickoff_at) into v_first from public.matches m
  where m.season_id=p_season_id and coalesce(m.is_test,false)=false and m.status<>'cancelled';
  select created_at into v_season_created from public.seasons where id=p_season_id;
  if v_first is not null and now()>=v_first then raise exception 'Reset interdit : la compétition a déjà commencé.'; end if;

  v_result:=public.admin_prelaunch_reset_preview_v0910(p_season_id);

  -- Données de jeu / traces de recette. Les comptes, clubs, Teams et calendrier réel sont conservés.
  delete from public.notifications where season_id=p_season_id;
  delete from public.player_reactions where season_id=p_season_id;
  delete from public.rival_duels where season_id=p_season_id;
  delete from public.rival_changes where season_id=p_season_id;
  delete from public.player_rivals where season_id=p_season_id;
  delete from public.ranking_notification_state where season_id=p_season_id;
  delete from public.monthly_poll_votes where poll_id in(select id from public.monthly_polls where season_id=p_season_id);
  delete from public.monthly_poll_candidates where poll_id in(select id from public.monthly_polls where season_id=p_season_id);
  delete from public.monthly_polls where season_id=p_season_id;
  delete from public.poll_votes where poll_id in(select id from public.polls where season_id=p_season_id);
  delete from public.poll_options where poll_id in(select id from public.polls where season_id=p_season_id);
  delete from public.polls where season_id=p_season_id;
  delete from public.season_memory_events where season_id=p_season_id;
  delete from public.player_rank_history where season_id=p_season_id;
  delete from public.season_guestbook_entries_v098 where season_id=p_season_id;
  delete from public.season_final_archives_v098 where season_id=p_season_id;
  -- Les badges de saison, tous les badges TEST et les badges carrière acquis depuis la création
  -- de cette saison sont des traces de recette tant que le premier coup d'envoi n'a pas eu lieu.
  delete from public.player_badges
  where season_id=p_season_id or is_test=true or (season_id is null and earned_at>=coalesce(v_season_created,'epoch'::timestamptz));
  delete from public.gamification_records where season_id=p_season_id;
  delete from public.gamification_events where season_id=p_season_id;
  update public.gamification_settings set test_enabled=false where season_id=p_season_id;
  delete from public.team_events where season_id=p_season_id;
  delete from public.tie_predictions where season_id=p_season_id;
  delete from public.champion_predictions where season_id=p_season_id;
  delete from public.predictions where season_id=p_season_id;
  delete from public.preseason_runs_v099 where season_id=p_season_id;
  delete from public.user_onboarding_v099 where user_id is not null;

  -- Supprime uniquement les objets de calendrier explicitement TEST.
  delete from public.matches where season_id=p_season_id and coalesce(is_test,false);
  delete from public.knockout_ties where season_id=p_season_id and coalesce(is_test,false);
  delete from public.matchdays md where md.season_id=p_season_id and coalesce(md.is_test,false)
    and not exists(select 1 from public.matches m where m.matchday_id=md.id);

  -- Remet les matchs réels avant coup d'envoi dans un état neutre, sans toucher aux dates/équipes.
  update public.matches set status='scheduled',home_score=null,away_score=null,went_to_extra_time=false,
    penalties_home=null,penalties_away=null,winner_club_id=null,updated_at=now()
  where season_id=p_season_id and coalesce(is_test,false)=false;
  update public.knockout_ties set status='scheduled',qualified_club_id=null,updated_at=now()
  where season_id=p_season_id and coalesce(is_test,false)=false;
  update public.seasons set status='preparation',updated_at=now() where id=p_season_id;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'prelaunch_reset_v0910','season',p_season_id::text,v_result||jsonb_build_object('completed_at',now()));
  return v_result||jsonb_build_object('ok',true,'completed_at',now());
end;$$;
grant execute on function public.admin_prelaunch_reset_v0910(uuid,text) to authenticated;

drop function if exists public.admin_merge_clubs_v0910(uuid,uuid);
create or replace function public.admin_merge_clubs_v0910(p_keep_id uuid,p_remove_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  k public.clubs%rowtype;
  r public.clubs%rowtype;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_keep_id is null or p_remove_id is null or p_keep_id=p_remove_id then raise exception 'Deux clubs différents sont requis.'; end if;

  select * into k from public.clubs where id=p_keep_id;
  if not found then raise exception 'Club à conserver introuvable.'; end if;
  select * into r from public.clubs where id=p_remove_id;
  if not found then raise exception 'Doublon à supprimer introuvable.'; end if;

  if exists(select 1 from public.matches where
    (home_club_id=p_keep_id and away_club_id=p_remove_id) or
    (home_club_id=p_remove_id and away_club_id=p_keep_id)) then
    raise exception 'Fusion impossible : un match oppose actuellement ces deux fiches.';
  end if;
  if exists(select 1 from public.ucl_matches where
    (home_club_id=p_keep_id and away_club_id=p_remove_id) or
    (home_club_id=p_remove_id and away_club_id=p_keep_id)) then
    raise exception 'Fusion impossible : une rencontre C1 oppose actuellement ces deux fiches.';
  end if;

  insert into public.club_catalog_memberships(club_id,competition_code,competition_name,country,season_year,updated_at)
  select p_keep_id,competition_code,competition_name,country,season_year,now()
  from public.club_catalog_memberships where club_id=p_remove_id
  on conflict(club_id,competition_code,season_year) do update
  set competition_name=excluded.competition_name,
      country=coalesce(public.club_catalog_memberships.country,excluded.country),
      updated_at=now();
  delete from public.club_catalog_memberships where club_id=p_remove_id;

  insert into public.ucl_standings(season_id,club_id,position,played_games,won,draw,lost,points,goals_for,goals_against,goal_difference,form,table_type,updated_at)
  select season_id,p_keep_id,position,played_games,won,draw,lost,points,goals_for,goals_against,goal_difference,form,table_type,now()
  from public.ucl_standings where club_id=p_remove_id
  on conflict(season_id,club_id,table_type) do nothing;
  delete from public.ucl_standings where club_id=p_remove_id;

  update public.matches set home_club_id=p_keep_id,updated_at=now() where home_club_id=p_remove_id;
  update public.matches set away_club_id=p_keep_id,updated_at=now() where away_club_id=p_remove_id;
  update public.matches set winner_club_id=p_keep_id,updated_at=now() where winner_club_id=p_remove_id;
  update public.ucl_matches set home_club_id=p_keep_id,updated_at=now() where home_club_id=p_remove_id;
  update public.ucl_matches set away_club_id=p_keep_id,updated_at=now() where away_club_id=p_remove_id;
  update public.knockout_ties set team_a_club_id=p_keep_id,updated_at=now() where team_a_club_id=p_remove_id;
  update public.knockout_ties set team_b_club_id=p_keep_id,updated_at=now() where team_b_club_id=p_remove_id;
  update public.knockout_ties set qualified_club_id=p_keep_id,updated_at=now() where qualified_club_id=p_remove_id;
  update public.tie_predictions set qualified_club_id=p_keep_id,updated_at=now() where qualified_club_id=p_remove_id;
  update public.champion_predictions set club_id=p_keep_id,updated_at=now() where club_id=p_remove_id;
  update public.teams set favorite_club_id=p_keep_id,updated_at=now() where favorite_club_id=p_remove_id;

  if k.external_provider is null and r.external_provider is not null then
    update public.clubs set external_provider=null,external_id=null,updated_at=now() where id=p_remove_id;
    update public.clubs
    set external_provider=r.external_provider,
        external_id=r.external_id,
        logo_url=coalesce(public.clubs.logo_url,r.logo_url),
        logo_source_url=coalesce(public.clubs.logo_source_url,r.logo_source_url),
        logo_storage_path=coalesce(public.clubs.logo_storage_path,r.logo_storage_path),
        country=coalesce(public.clubs.country,r.country),
        venue=coalesce(public.clubs.venue,r.venue),
        tla=coalesce(public.clubs.tla,r.tla),
        manual_metadata_lock=true,
        metadata_source=coalesce(public.clubs.metadata_source,'manual'),
        provider_metadata_updated_at=coalesce(r.provider_metadata_updated_at,public.clubs.provider_metadata_updated_at),
        updated_at=now()
    where id=p_keep_id;
  elsif k.external_provider is not null and r.external_provider is not null
    and (k.external_provider<>r.external_provider or k.external_id is distinct from r.external_id) then
    raise exception 'Les deux fiches possèdent des identités fournisseur différentes. Fusion refusée.';
  end if;

  delete from public.clubs where id=p_remove_id;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'merge_clubs_v0910','club',p_keep_id::text,
    jsonb_build_object('kept_name',k.name,'removed_name',r.name,'provider',coalesce(r.external_provider,k.external_provider),'provider_id',coalesce(r.external_id,k.external_id)));

  return jsonb_build_object('ok',true,'kept_id',p_keep_id,'kept_name',k.name,'removed_id',p_remove_id,'removed_name',r.name);
end;$$;
grant execute on function public.admin_merge_clubs_v0910(uuid,uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Feature gates pré-lancement
--    Super Admin garde un bypass côté interface pour continuer les tests.
-- ---------------------------------------------------------------------------
insert into public.app_settings(key,value,updated_at,updated_by) values
  ('feature_knockout','false'::jsonb,now(),auth.uid()),
  ('feature_ucl_center','false'::jsonb,now(),auth.uid()),
  ('feature_evenings','false'::jsonb,now(),auth.uid()),
  ('feature_teams','false'::jsonb,now(),auth.uid()),
  ('feature_gamification','false'::jsonb,now(),auth.uid()),
  ('feature_messages','false'::jsonb,now(),auth.uid()),
  ('feature_rivals','false'::jsonb,now(),auth.uid()),
  ('feature_polls','false'::jsonb,now(),auth.uid()),
  ('feature_solitary_owl','false'::jsonb,now(),auth.uid()),
  ('feature_betclic_odds','true'::jsonb,now(),auth.uid())
on conflict(key) do update
set value=excluded.value,updated_at=now(),updated_by=auth.uid();

create or replace function public.admin_set_app_setting_v095(p_key text,p_value jsonb,p_reason text default null)
returns void language plpgsql security definer set search_path=public as $$
declare oldv jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_key not in (
    'registration_open','maintenance','feature_api','feature_betclic_odds',
    'feature_knockout','feature_ucl_center','feature_evenings',
    'feature_teams','feature_gamification','feature_messages',
    'feature_rivals','feature_polls','feature_solitary_owl'
  ) then
    raise exception 'Réglage non autorisé.';
  end if;
  select value into oldv from public.app_settings where key=p_key;
  insert into public.app_settings(key,value,updated_at,updated_by)
  values(p_key,p_value,now(),auth.uid())
  on conflict(key) do update set value=excluded.value,updated_at=now(),updated_by=auth.uid();
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data,new_data)
  values(auth.uid(),'setting_update','app_setting',p_key,
    jsonb_build_object('value',oldv,'reason',p_reason),
    jsonb_build_object('value',p_value,'reason',p_reason));
end;$$;
grant execute on function public.admin_set_app_setting_v095(text,jsonb,text) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Compteurs et purge des messages de test
-- ---------------------------------------------------------------------------
create or replace function public.admin_message_counts_v0911()
returns jsonb language plpgsql security definer set search_path=public as $$
declare result jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  select jsonb_build_object(
    'owl_messages',(select count(*) from public.owl_messages),
    'notifications',(select count(*) from public.notifications),
    'push_logs',(select count(*) from public.push_delivery_logs),
    'support_tickets',(select count(*) from public.support_tickets),
    'support_messages',(select count(*) from public.support_ticket_messages),
    'support_attachments',(select count(*) from public.support_ticket_attachments),
    'password_help',(select count(*) from public.password_help_requests),
    'guestbook',(select count(*) from public.season_guestbook_entries_v098)
  ) into result;
  return result;
end;$$;
grant execute on function public.admin_message_counts_v0911() to authenticated;

create or replace function public.admin_purge_messages_v0911(p_confirmation text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare before_counts jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if coalesce(p_confirmation,'') <> 'SUPPRIMER TOUS LES MESSAGES' then
    raise exception 'Confirmation invalide.';
  end if;

  before_counts:=public.admin_message_counts_v0911();

  -- pg_safeupdate : chaque DELETE garde volontairement une clause WHERE explicite.
  delete from public.push_delivery_logs where id is not null;
  delete from public.notifications where id is not null;
  delete from public.owl_messages where id is not null;
  delete from public.support_ticket_attachments where id is not null;
  delete from public.support_ticket_messages where id is not null;
  delete from public.support_tickets where id is not null;
  delete from public.password_help_requests where id is not null;
  delete from public.season_guestbook_entries_v098 where id is not null;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'purge_messages_v0911','communication','all',
    before_counts || jsonb_build_object('completed_at',now()));

  return before_counts || jsonb_build_object('ok',true,'completed_at',now());
end;$$;
grant execute on function public.admin_purge_messages_v0911(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Diagnostic release
-- ---------------------------------------------------------------------------
create or replace function public.admin_diagnostics_v0911()
returns table(section text,test text,status text,detail text)
language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé à l’administration.'; end if;
  return query
    select 'Version'::text,'Backend'::text,
      case when exists(select 1 from public.app_settings where key='app_version' and value='"0.9.11"'::jsonb) then 'PASS' else 'FAIL' end,
      'app_version=0.9.11'::text
    union all select 'Feature gates','Phases finales',
      case when exists(select 1 from public.app_settings where key='feature_knockout') then 'PASS' else 'FAIL' end,'feature_knockout'
    union all select 'Feature gates','Messages',
      case when exists(select 1 from public.app_settings where key='feature_messages') then 'PASS' else 'FAIL' end,'feature_messages'
    union all select 'Feature gates','Betclic',
      case when exists(select 1 from public.app_settings where key='feature_betclic_odds') then 'PASS' else 'FAIL' end,'feature_betclic_odds'
    union all select 'Communication','Purge',
      case when to_regprocedure('public.admin_purge_messages_v0911(text)') is not null then 'PASS' else 'FAIL' end,'admin_purge_messages_v0911'
    union all select 'Clubs','Fusion',
      case when to_regprocedure('public.admin_merge_clubs_v0910(uuid,uuid)') is not null then 'PASS' else 'FAIL' end,'admin_merge_clubs_v0910'
    union all select 'Pré-production','Reset',
      case when to_regprocedure('public.admin_prelaunch_reset_v0910(uuid,text)') is not null then 'PASS' else 'FAIL' end,'admin_prelaunch_reset_v0910';
end;$$;
grant execute on function public.admin_diagnostics_v0911() to authenticated;

insert into public.app_settings(key,value,updated_at,updated_by)
values('app_version','"0.9.11"'::jsonb,now(),auth.uid())
on conflict(key) do update set value=excluded.value,updated_at=now(),updated_by=auth.uid();

commit;

select pg_notify('pgrst','reload schema');

-- Contrôles après exécution :
select to_regprocedure('public.admin_merge_clubs_v0910(uuid,uuid)') as merge_rpc;
select to_regprocedure('public.admin_purge_messages_v0911(text)') as purge_rpc;
select key,value from public.app_settings
where key in ('app_version','feature_knockout','feature_ucl_center','feature_evenings','feature_teams','feature_gamification','feature_messages','feature_betclic_odds')
order by key;
