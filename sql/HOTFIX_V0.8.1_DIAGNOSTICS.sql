-- =============================================================================
-- LE NID DES CHAMPIONS — V0.8.1
-- Diagnostic structurel en lecture seule pour le Centre de tests.
-- Ne modifie aucune donnée métier.
-- =============================================================================

begin;

create or replace function public.admin_run_diagnostics_v081()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentification requise.';
  end if;
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'super_admin' and status = 'active'
  ) then
    raise exception 'Réservé au Super Admin.';
  end if;

  with expected_tables(version, feature, name, critical) as (
    values
      ('0.1','Socle','seasons',true),('0.1','Socle','profiles',true),('0.1','Socle','app_settings',true),('0.1','Audit','audit_logs',true),
      ('0.2','Pronostics','competition_phases',true),('0.2','Pronostics','clubs',true),('0.2','Pronostics','matchdays',true),('0.2','Pronostics','matches',true),('0.2','Pronostics','predictions',true),('0.2','Historique','prediction_history',true),
      ('0.4','Phases finales','knockout_ties',true),('0.4','Phases finales','tie_predictions',true),('0.4','Champions','champion_predictions',true),
      ('0.5','Teams','teams',true),('0.5','Teams','team_memberships',true),('0.5','Teams','team_join_requests',true),('0.5','Teams','team_invites',true),('0.5','Teams','team_events',true),('0.5','Avatars','player_avatar_catalog',true),
      ('0.6','Notifications','notifications',true),('0.6','Notifications','notification_preferences',true),('0.6','Push','push_subscriptions',true),('0.6','Push','push_delivery_logs',true),
      ('0.6','Rivalités','player_rivals',true),('0.6','Rivalités','rival_duels',true),('0.6','Rivalités','rival_changes',true),('0.6','Hibou','owl_messages',true),
      ('0.6','Support','support_tickets',true),('0.6','Support','support_ticket_messages',true),('0.6','Support','support_ticket_attachments',true),('0.6','Réactions','player_reactions',true),
      ('0.7','Gamification','gamification_badges',true),('0.7','Gamification','player_badges',true),('0.7','Gamification','gamification_events',true),('0.7','Records','gamification_records',true),('0.7','Gamification','gamification_settings',true),('0.7','Narration','gamification_text_templates',true),('0.7','Audit gamification','gamification_audit',true),
      ('0.8','Centre C1','ucl_matches',true),('0.8','Centre C1','ucl_standings',true),('0.8','Votes','monthly_polls',true),('0.8','Votes','monthly_poll_candidates',true),('0.8','Votes','monthly_poll_votes',true)
  ),
  table_checks as (
    select
      'table.'||e.name as id,
      e.version,
      e.feature as category,
      case when to_regclass('public.'||e.name) is not null then 'PASS' else case when e.critical then 'FAIL' else 'WARN' end end as status,
      case when to_regclass('public.'||e.name) is not null then 'Table public.'||e.name||' présente.' else 'Table public.'||e.name||' absente.' end as message
    from expected_tables e
  ),
  expected_functions(version, feature, name) as (
    values
      ('0.1','Droits','is_admin'),('0.1','Droits','is_super_admin'),('0.1','Authentification','is_username_available'),
      ('0.2','Pronostics','calculate_prediction_points'),('0.2','Admin matchs','admin_set_match_state'),('0.2','Historique','get_my_prediction_history'),
      ('0.3','Classements','get_leaderboard_v030'),('0.3','Statistiques','get_collective_stats_v030'),('0.3','Pronostics des autres','get_match_predictions_v030'),
      ('0.4','Classements','get_leaderboard_v040'),('0.4','Champions','get_champion_status_v040'),('0.4','Champions','save_champion_pick_v040'),('0.4','Phases finales','admin_upsert_knockout_tie_v040'),
      ('0.5','Teams','create_team_v050'),('0.5','Teams','get_my_team_v050'),('0.5','Teams','get_team_leaderboard_v050'),('0.5','Teams','join_public_team_v050'),('0.5','Teams','transfer_team_captain_v050'),
      ('0.6','Rivalités','set_my_rival_v060'),('0.6','Support','create_support_ticket_v060'),('0.6','Hibou','admin_send_owl_message_v060'),('0.6','Push','register_my_push_subscription_v064'),('0.6','Réactions','send_player_reaction_v062'),
      ('0.7','Musée','get_museum_summary_v070'),('0.7','Badges','evaluate_badges_v070'),('0.7','Gamification','process_match_gamification_v070'),('0.7','LIVE TEST','get_test_leaderboard_v071'),('0.7','Rôles Team','get_my_roles_v073'),
      ('0.8','Hibou solitaire','get_hibou_solitaire_events_v080'),('0.8','Hibou solitaire','get_hibou_solitaire_leaderboard_v080'),('0.8','Votes','cast_monthly_vote_v080'),('0.8','Votes','admin_create_monthly_poll_v080'),('0.8','Votes','admin_close_monthly_poll_v080'),
      ('0.8.1','Diagnostic','admin_run_diagnostics_v081')
  ),
  function_checks as (
    select
      'function.'||e.name as id,
      e.version,
      e.feature as category,
      case when exists (
        select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname=e.name
      ) then 'PASS' else 'FAIL' end as status,
      case when exists (
        select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname=e.name
      ) then 'Fonction '||e.name||' présente.' else 'Fonction '||e.name||' absente.' end as message
    from expected_functions e
  ),
  expected_columns(version, feature, table_name, column_name) as (
    values
      ('0.2','Matchs','matches','kickoff_at'),('0.2','Matchs','matches','status'),('0.2','Matchs','matches','home_score'),('0.2','Matchs','matches','away_score'),
      ('0.3','Cotes','matches','odds_home'),('0.3','Cotes','matches','odds_draw'),('0.3','Cotes','matches','odds_away'),
      ('0.4','Multiplicateurs','matches','points_multiplier'),('0.4','Phases finales','matches','tie_id'),('0.4','Phases finales','matches','leg_number'),('0.4','Phases finales','matches','penalties_home'),('0.4','Phases finales','matches','penalties_away'),
      ('0.6','Tests','matches','is_test'),('0.6','Tests','matches','test_enabled'),
      ('0.8','Centre C1','ucl_matches','external_match_id'),('0.8','Centre C1','ucl_matches','stage'),('0.8','Centre C1','ucl_standings','position')
  ),
  column_checks as (
    select
      'column.'||e.table_name||'.'||e.column_name as id,
      e.version,
      e.feature as category,
      case when exists (
        select 1 from information_schema.columns c
        where c.table_schema='public' and c.table_name=e.table_name and c.column_name=e.column_name
      ) then 'PASS' else 'FAIL' end as status,
      case when exists (
        select 1 from information_schema.columns c
        where c.table_schema='public' and c.table_name=e.table_name and c.column_name=e.column_name
      ) then e.table_name||'.'||e.column_name||' présent.' else e.table_name||'.'||e.column_name||' absent.' end as message
    from expected_columns e
  ),
  expected_rls(version, feature, name) as (
    values
      ('0.1','Profils','profiles'),('0.2','Pronostics','predictions'),('0.4','Champions','champion_predictions'),('0.4','Phases finales','tie_predictions'),
      ('0.5','Teams','team_memberships'),('0.6','Notifications','notifications'),('0.6','Push','push_subscriptions'),('0.6','Support','support_tickets'),
      ('0.7','Badges','player_badges'),('0.8','Centre C1','ucl_matches'),('0.8','Centre C1','ucl_standings'),('0.8','Votes','monthly_poll_votes')
  ),
  rls_checks as (
    select
      'rls.'||e.name as id,
      e.version,
      e.feature as category,
      case when coalesce(c.relrowsecurity,false) then 'PASS' else 'FAIL' end as status,
      case when coalesce(c.relrowsecurity,false) then 'RLS active sur '||e.name||'.' else 'RLS inactive ou table absente sur '||e.name||'.' end as message
    from expected_rls e
    left join pg_class c on c.relname=e.name and c.relnamespace=(select oid from pg_namespace where nspname='public')
  ),
  all_checks as (
    select * from table_checks
    union all select * from function_checks
    union all select * from column_checks
    union all select * from rls_checks
  ),
  summary as (
    select
      count(*)::int as total,
      count(*) filter(where status='PASS')::int as passed,
      count(*) filter(where status='WARN')::int as warnings,
      count(*) filter(where status='FAIL')::int as failed
    from all_checks
  )
  select jsonb_build_object(
    'ok', s.failed=0,
    'version', '0.8.1',
    'generated_at', now(),
    'summary', jsonb_build_object('total',s.total,'passed',s.passed,'warnings',s.warnings,'failed',s.failed),
    'checks', coalesce((select jsonb_agg(jsonb_build_object('id',id,'version',version,'category',category,'status',status,'message',message) order by version,category,id) from all_checks),'[]'::jsonb)
  ) into v_result
  from summary s;

  return v_result;
end;
$$;

grant execute on function public.admin_run_diagnostics_v081() to authenticated;

insert into public.app_settings(key,value)
values ('app_version','"0.8.1"'::jsonb)
on conflict (key) do update set value=excluded.value, updated_at=now();

commit;

select key,value,updated_at from public.app_settings where key='app_version';
