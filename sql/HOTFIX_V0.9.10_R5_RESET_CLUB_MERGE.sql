-- Le Nid des Champions — V0.9.10 R5
begin;

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

commit;

notify pgrst, 'reload schema';
