-- =============================================================================
-- LE NID DES CHAMPIONS — V0.9.10
-- Sécurisation pré-production : calendrier hybride, édition manuelle, favoris,
-- reset avant ouverture et diagnostic de cohérence.
-- Base attendue : V0.9.9 (édition 100 succès intégrés).
-- =============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1. Traçabilité calendrier / protection des corrections manuelles
-- ----------------------------------------------------------------------------
alter table public.matches add column if not exists schedule_source text not null default 'legacy';
alter table public.matches add column if not exists manual_schedule_lock boolean not null default false;
alter table public.matches add column if not exists manual_schedule_updated_at timestamptz;
alter table public.matches add column if not exists provider_schedule_updated_at timestamptz;

update public.matches
set schedule_source = case
  when data_source='manual' then 'manual'
  when external_provider='football-data' then 'football-data'
  else 'legacy'
end
where schedule_source='legacy';

alter table public.clubs add column if not exists metadata_source text not null default 'legacy';
alter table public.clubs add column if not exists manual_metadata_lock boolean not null default false;
alter table public.clubs add column if not exists manual_metadata_updated_at timestamptz;
alter table public.clubs add column if not exists provider_metadata_updated_at timestamptz;

update public.clubs
set metadata_source = case
  when external_provider='football-data' then 'football-data'
  else 'legacy'
end
where metadata_source='legacy';

-- Fenêtres officielles connues, même avant que le fournisseur ne publie les matchs.
create table if not exists public.competition_schedule_windows_v0910 (
  id bigint generated always as identity primary key,
  season_id uuid not null references public.seasons(id) on delete cascade,
  phase_code text not null,
  matchday_number integer not null default 0,
  leg_number integer not null default 0,
  label text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  source text not null default 'UEFA',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(season_id,phase_code,matchday_number,leg_number)
);

alter table public.competition_schedule_windows_v0910 enable row level security;
drop policy if exists competition_schedule_windows_v0910_read on public.competition_schedule_windows_v0910;
create policy competition_schedule_windows_v0910_read on public.competition_schedule_windows_v0910
for select to authenticated using(true);
grant select on public.competition_schedule_windows_v0910 to authenticated;

-- Calendrier UEFA 2026/27 : fenêtres des 8 journées et tours KO connus.
with s as (
  select id from public.seasons where slug='ucl-2026-27' limit 1
), x(phase_code,matchday_number,leg_number,label,starts_at,ends_at) as (
  values
  ('LEAGUE',1,0,'Journée 1','2026-09-08 18:45:00+02'::timestamptz,'2026-09-10 23:30:00+02'::timestamptz),
  ('LEAGUE',2,0,'Journée 2','2026-10-13 18:45:00+02'::timestamptz,'2026-10-14 23:30:00+02'::timestamptz),
  ('LEAGUE',3,0,'Journée 3','2026-10-20 18:45:00+02'::timestamptz,'2026-10-21 23:30:00+02'::timestamptz),
  ('LEAGUE',4,0,'Journée 4','2026-11-03 18:45:00+01'::timestamptz,'2026-11-04 23:30:00+01'::timestamptz),
  ('LEAGUE',5,0,'Journée 5','2026-11-24 18:45:00+01'::timestamptz,'2026-11-25 23:30:00+01'::timestamptz),
  ('LEAGUE',6,0,'Journée 6','2026-12-08 18:45:00+01'::timestamptz,'2026-12-09 23:30:00+01'::timestamptz),
  ('LEAGUE',7,0,'Journée 7','2027-01-19 18:45:00+01'::timestamptz,'2027-01-20 23:30:00+01'::timestamptz),
  ('LEAGUE',8,0,'Journée 8','2027-01-27 21:00:00+01'::timestamptz,'2027-01-27 23:59:00+01'::timestamptz),
  ('KNOCKOUT_PLAYOFF',0,1,'Barrages — aller','2027-02-16 18:00:00+01'::timestamptz,'2027-02-17 23:59:00+01'::timestamptz),
  ('KNOCKOUT_PLAYOFF',0,2,'Barrages — retour','2027-02-23 18:00:00+01'::timestamptz,'2027-02-24 23:59:00+01'::timestamptz),
  ('ROUND_OF_16',0,1,'Huitièmes — aller','2027-03-09 18:00:00+01'::timestamptz,'2027-03-10 23:59:00+01'::timestamptz),
  ('ROUND_OF_16',0,2,'Huitièmes — retour','2027-03-16 18:00:00+01'::timestamptz,'2027-03-17 23:59:00+01'::timestamptz),
  ('QUARTER_FINAL',0,1,'Quarts — aller','2027-04-06 18:00:00+02'::timestamptz,'2027-04-07 23:59:00+02'::timestamptz),
  ('QUARTER_FINAL',0,2,'Quarts — retour','2027-04-13 18:00:00+02'::timestamptz,'2027-04-14 23:59:00+02'::timestamptz),
  ('SEMI_FINAL',0,1,'Demi-finales — aller','2027-04-27 18:00:00+02'::timestamptz,'2027-04-28 23:59:00+02'::timestamptz),
  ('SEMI_FINAL',0,2,'Demi-finales — retour','2027-05-04 18:00:00+02'::timestamptz,'2027-05-05 23:59:00+02'::timestamptz),
  ('FINAL',0,1,'Finale — Madrid','2027-06-05 18:00:00+02'::timestamptz,'2027-06-05 23:59:00+02'::timestamptz)
)
insert into public.competition_schedule_windows_v0910(season_id,phase_code,matchday_number,leg_number,label,starts_at,ends_at)
select s.id,x.phase_code,x.matchday_number,x.leg_number,x.label,x.starts_at,x.ends_at from s cross join x
on conflict (season_id,phase_code,matchday_number,leg_number) do update
set label=excluded.label,starts_at=excluded.starts_at,ends_at=excluded.ends_at,source='UEFA',updated_at=now();

create or replace function public.season_start_year_v0910(p_season_id uuid)
returns integer language sql stable security definer set search_path=public as $$
  select coalesce((substring(coalesce(s.slug,s.name) from '(20[0-9]{2})'))::integer,extract(year from s.created_at)::integer)
  from public.seasons s where s.id=p_season_id;
$$;
grant execute on function public.season_start_year_v0910(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- 2. Champion n°1 disponible dès que les 36 clubs C1 sont connus
-- ----------------------------------------------------------------------------
create or replace function public.champion_first_close_at_v040(p_season_id uuid)
returns timestamptz language sql stable security definer set search_path=public as $$
  select coalesce(
    (
      select min(m.kickoff_at)
      from public.matches m
      join public.competition_phases ph on ph.id=m.phase_id
      where m.season_id=p_season_id and ph.code='LEAGUE'
        and coalesce(m.is_test,false)=false
        and m.status not in ('cancelled','postponed')
    ),
    (
      select min(w.starts_at)
      from public.competition_schedule_windows_v0910 w
      where w.season_id=p_season_id and w.phase_code='LEAGUE' and w.matchday_number=1
    )
  );
$$;

create or replace function public.is_champion_candidate_v040(p_season_id uuid,p_pick_number integer,p_club_id uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select case
    when p_pick_number=1 then (
      exists(
        select 1 from public.matches m join public.competition_phases ph on ph.id=m.phase_id
        where m.season_id=p_season_id and ph.code='LEAGUE' and coalesce(m.is_test,false)=false
          and (m.home_club_id=p_club_id or m.away_club_id=p_club_id)
      )
      or exists(
        select 1 from public.club_catalog_memberships cm
        where cm.club_id=p_club_id and cm.competition_code='CL'
          and cm.season_year=public.season_start_year_v0910(p_season_id)
      )
    )
    when p_pick_number=2 then exists(
      select 1 from public.knockout_ties t
      where t.season_id=p_season_id and t.status<>'cancelled' and coalesce(t.is_test,false)=false
        and (t.team_a_club_id=p_club_id or t.team_b_club_id=p_club_id or t.qualified_club_id=p_club_id)
    )
    else false end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Édition manuelle des clubs
-- ----------------------------------------------------------------------------
create or replace function public.admin_create_club_v0910(
  p_name text,p_short_name text,p_tla text default null,p_country text default null,p_venue text default null,
  p_logo_url text default null,p_competition_code text default 'CL',p_season_year integer default null
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_year integer;
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  if nullif(trim(p_name),'') is null or nullif(trim(p_short_name),'') is null then raise exception 'Nom et nom court requis.'; end if;
  v_year:=coalesce(p_season_year,extract(year from now())::integer);
  insert into public.clubs(name,short_name,tla,country,venue,logo_url,is_active,metadata_source,manual_metadata_lock,manual_metadata_updated_at,updated_at)
  values(trim(p_name),trim(p_short_name),nullif(upper(trim(p_tla)),''),nullif(trim(p_country),''),nullif(trim(p_venue),''),nullif(trim(p_logo_url),''),true,'manual',true,now(),now())
  returning id into v_id;
  if nullif(trim(p_competition_code),'') is not null then
    insert into public.club_catalog_memberships(club_id,competition_code,competition_name,country,season_year,updated_at)
    values(v_id,upper(trim(p_competition_code)),case when upper(trim(p_competition_code))='CL' then 'UEFA Champions League' else upper(trim(p_competition_code)) end,nullif(trim(p_country),''),v_year,now())
    on conflict(club_id,competition_code,season_year) do update set country=excluded.country,updated_at=now();
  end if;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'club_create_v0910','club',v_id::text,jsonb_build_object('name',trim(p_name),'competition',p_competition_code,'manual_lock',true));
  return v_id;
end;$$;

grant execute on function public.admin_create_club_v0910(text,text,text,text,text,text,text,integer) to authenticated;

create or replace function public.admin_update_club_metadata_v0910(
  p_club_id uuid,p_name text,p_short_name text,p_tla text default null,p_country text default null,
  p_venue text default null,p_logo_url text default null,p_lock_manual boolean default true
) returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  if not exists(select 1 from public.clubs where id=p_club_id) then raise exception 'Club introuvable.'; end if;
  update public.clubs set
    name=coalesce(nullif(trim(p_name),''),name),short_name=coalesce(nullif(trim(p_short_name),''),short_name),
    tla=nullif(upper(trim(p_tla)),''),country=nullif(trim(p_country),''),venue=nullif(trim(p_venue),''),
    logo_url=coalesce(nullif(trim(p_logo_url),''),logo_url),metadata_source=case when p_lock_manual then 'manual' else metadata_source end,
    manual_metadata_lock=p_lock_manual,manual_metadata_updated_at=case when p_lock_manual then now() else manual_metadata_updated_at end,updated_at=now()
  where id=p_club_id;
  update public.club_catalog_memberships set country=(select country from public.clubs where id=p_club_id),updated_at=now() where club_id=p_club_id;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'club_update_v0910','club',p_club_id::text,jsonb_build_object('manual_lock',p_lock_manual));
end;$$;
grant execute on function public.admin_update_club_metadata_v0910(uuid,text,text,text,text,text,text,boolean) to authenticated;

-- ----------------------------------------------------------------------------
-- 4. Édition manuelle du calendrier / verrouillage local
-- ----------------------------------------------------------------------------
create or replace function public.admin_update_match_schedule_v0910(
  p_match_id uuid,p_home_club_id uuid,p_away_club_id uuid,p_kickoff_at timestamptz,
  p_matchday_id uuid default null,p_stadium text default null,p_venue_country text default null,p_lock_manual boolean default true
) returns void language plpgsql security definer set search_path=public as $$
declare v_status text;
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  select status into v_status from public.matches where id=p_match_id;
  if v_status is null then raise exception 'Match introuvable.'; end if;
  if v_status in ('live','finished') then raise exception 'Un match LIVE ou terminé ne peut pas être déplacé ici.'; end if;
  if p_home_club_id=p_away_club_id then raise exception 'Les deux clubs doivent être différents.'; end if;
  update public.matches set home_club_id=p_home_club_id,away_club_id=p_away_club_id,kickoff_at=p_kickoff_at,
    matchday_id=p_matchday_id,stadium=nullif(trim(p_stadium),''),venue_country=nullif(trim(p_venue_country),''),
    data_source='manual',schedule_source=case when p_lock_manual then 'manual' else schedule_source end,
    manual_schedule_lock=p_lock_manual,manual_schedule_updated_at=case when p_lock_manual then now() else manual_schedule_updated_at end,updated_at=now()
  where id=p_match_id;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'match_schedule_update_v0910','match',p_match_id::text,jsonb_build_object('kickoff_at',p_kickoff_at,'manual_lock',p_lock_manual));
end;$$;
grant execute on function public.admin_update_match_schedule_v0910(uuid,uuid,uuid,timestamptz,uuid,text,text,boolean) to authenticated;

create or replace function public.admin_unlock_match_schedule_v0910(p_match_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  update public.matches set manual_schedule_lock=false,schedule_source=case when external_provider='football-data' then 'football-data' else schedule_source end,updated_at=now() where id=p_match_id;
  if not found then raise exception 'Match introuvable.'; end if;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'match_schedule_unlock_v0910','match',p_match_id::text,jsonb_build_object('manual_lock',false));
end;$$;
grant execute on function public.admin_unlock_match_schedule_v0910(uuid) to authenticated;

-- Import du calendrier officiel embarqué. Les IDs de clubs sont résolus par le front
-- à partir des 36 clubs du catalogue. Aucune suppression n'est effectuée.
create or replace function public.admin_seed_official_calendar_v0910(p_season_id uuid,p_fixtures jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  v_phase_id uuid; v_md_id uuid; v_match_id uuid; v_row jsonb; v_count integer; v_bad integer;
  v_inserted integer:=0; v_updated integer:=0; v_skipped integer:=0; v_md integer;
  v_home uuid; v_away uuid; v_kickoff timestamptz;
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  if p_fixtures is null or jsonb_typeof(p_fixtures)<>'array' then raise exception 'Calendrier invalide.'; end if;
  select jsonb_array_length(p_fixtures) into v_count;
  if v_count<>144 then raise exception 'Le calendrier officiel doit contenir exactement 144 matchs (reçu: %).',v_count; end if;

  select count(*) into v_bad from (
    select (x->>'matchday')::integer md,count(*) n from jsonb_array_elements(p_fixtures) x group by 1
  ) q where q.md not between 1 and 8 or q.n<>18;
  if v_bad<>0 or (select count(distinct (x->>'matchday')::integer) from jsonb_array_elements(p_fixtures) x)<>8 then
    raise exception 'Le calendrier doit contenir 8 journées de 18 matchs.';
  end if;

  select id into v_phase_id from public.competition_phases where season_id=p_season_id and code='LEAGUE';
  if v_phase_id is null then
    insert into public.competition_phases(season_id,code,name,sort_order,default_multiplier)
    values(p_season_id,'LEAGUE','Phase de ligue',10,1) returning id into v_phase_id;
  end if;

  for v_md in 1..8 loop
    select id into v_md_id from public.matchdays where season_id=p_season_id and number=v_md;
    if v_md_id is null then
      insert into public.matchdays(season_id,phase_id,number,name,starts_at,ends_at,is_test,test_enabled)
      select p_season_id,v_phase_id,v_md,'Journée '||v_md,min((x->>'kickoff_at')::timestamptz),max((x->>'kickoff_at')::timestamptz)+interval '3 hours',false,true
      from jsonb_array_elements(p_fixtures) x where (x->>'matchday')::integer=v_md
      returning id into v_md_id;
    else
      update public.matchdays set phase_id=v_phase_id,name='Journée '||v_md,
        starts_at=(select min((x->>'kickoff_at')::timestamptz) from jsonb_array_elements(p_fixtures) x where (x->>'matchday')::integer=v_md),
        ends_at=(select max((x->>'kickoff_at')::timestamptz)+interval '3 hours' from jsonb_array_elements(p_fixtures) x where (x->>'matchday')::integer=v_md)
      where id=v_md_id;
    end if;
  end loop;

  for v_row in select value from jsonb_array_elements(p_fixtures) loop
    v_md:=(v_row->>'matchday')::integer; v_home:=(v_row->>'home_club_id')::uuid; v_away:=(v_row->>'away_club_id')::uuid; v_kickoff:=(v_row->>'kickoff_at')::timestamptz;
    if v_home is null or v_away is null or v_home=v_away then raise exception 'Clubs invalides dans le calendrier officiel.'; end if;
    if not exists(select 1 from public.clubs where id=v_home) or not exists(select 1 from public.clubs where id=v_away) then raise exception 'Un club du calendrier officiel est introuvable.'; end if;
    select id into v_md_id from public.matchdays where season_id=p_season_id and number=v_md;

    select id into v_match_id from public.matches
    where season_id=p_season_id and home_club_id=v_home and away_club_id=v_away and coalesce(is_test,false)=false
    order by created_at limit 1;

    if v_match_id is null then
      insert into public.matches(season_id,phase_id,matchday_id,home_club_id,away_club_id,kickoff_at,stadium,status,data_source,is_test,test_enabled,schedule_source,manual_schedule_lock)
      values(p_season_id,v_phase_id,v_md_id,v_home,v_away,v_kickoff,nullif(v_row->>'stadium',''),'scheduled','api',false,true,'uefa_seed',false);
      v_inserted:=v_inserted+1;
    elsif exists(select 1 from public.matches where id=v_match_id and (manual_schedule_lock or status in ('live','finished'))) then
      v_skipped:=v_skipped+1;
    else
      update public.matches set phase_id=v_phase_id,matchday_id=v_md_id,kickoff_at=v_kickoff,
        stadium=coalesce(nullif(v_row->>'stadium',''),stadium),schedule_source='uefa_seed',data_source='api',updated_at=now()
      where id=v_match_id;
      v_updated:=v_updated+1;
    end if;
  end loop;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'calendar_seed_uefa_v0910','season',p_season_id::text,jsonb_build_object('inserted',v_inserted,'updated',v_updated,'skipped',v_skipped,'total',v_count));
  return jsonb_build_object('inserted',v_inserted,'updated',v_updated,'skipped',v_skipped,'total',v_count);
end;$$;
grant execute on function public.admin_seed_official_calendar_v0910(uuid,jsonb) to authenticated;

-- ----------------------------------------------------------------------------
-- 5. État du calendrier
-- ----------------------------------------------------------------------------
create or replace function public.get_calendar_health_v0910(p_season_id uuid)
returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object(
    'official_matches',count(*) filter(where coalesce(m.is_test,false)=false and ph.code='LEAGUE'),
    'manual_locked',count(*) filter(where coalesce(m.is_test,false)=false and ph.code='LEAGUE' and m.manual_schedule_lock),
    'with_external_id',count(*) filter(where coalesce(m.is_test,false)=false and ph.code='LEAGUE' and m.external_match_id is not null),
    'with_odds',count(*) filter(where coalesce(m.is_test,false)=false and ph.code='LEAGUE' and m.odds_home is not null and m.odds_draw is not null and m.odds_away is not null),
    'expected_matches',144,
    'matchdays',count(distinct m.matchday_id) filter(where coalesce(m.is_test,false)=false and ph.code='LEAGUE'),
    'complete',count(*) filter(where coalesce(m.is_test,false)=false and ph.code='LEAGUE')=144
  )
  from public.matches m left join public.competition_phases ph on ph.id=m.phase_id
  where m.season_id=p_season_id;
$$;
grant execute on function public.get_calendar_health_v0910(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- 6. Reset propre avant ouverture officielle
-- ----------------------------------------------------------------------------
create or replace function public.admin_prelaunch_reset_preview_v0910(p_season_id uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare v_first timestamptz; v_season_created timestamptz;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  select min(m.kickoff_at) into v_first from public.matches m
  where m.season_id=p_season_id and coalesce(m.is_test,false)=false and m.status<>'cancelled';
  select created_at into v_season_created from public.seasons where id=p_season_id;
  return jsonb_build_object(
    'allowed',v_first is null or now()<v_first,'first_kickoff_at',v_first,
    'predictions',(select count(*) from public.predictions where season_id=p_season_id),
    'champion_picks',(select count(*) from public.champion_predictions where season_id=p_season_id),
    'tie_picks',(select count(*) from public.tie_predictions where season_id=p_season_id),
    'badges',(select count(*) from public.player_badges where season_id=p_season_id or is_test=true or (season_id is null and earned_at>=coalesce(v_season_created,'epoch'::timestamptz))),
    'guestbook',(select count(*) from public.season_guestbook_entries_v098 where season_id=p_season_id),
    'final_archives',(select count(*) from public.season_final_archives_v098 where season_id=p_season_id),
    'gamification_events',(select count(*) from public.gamification_events where season_id=p_season_id),
    'gamification_records',(select count(*) from public.gamification_records where season_id=p_season_id),
    'test_matches',(select count(*) from public.matches where season_id=p_season_id and coalesce(is_test,false)),
    'preseason_runs',(select count(*) from public.preseason_runs_v099 where season_id=p_season_id)
  );
end;$$;
grant execute on function public.admin_prelaunch_reset_preview_v0910(uuid) to authenticated;

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
  delete from public.user_onboarding_v099;

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

-- ----------------------------------------------------------------------------
-- 7. Diagnostic V0.9.10
-- ----------------------------------------------------------------------------
create or replace function public.admin_diagnostics_v0910()
returns table(section text,test text,status text,detail text) language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé à l’administration.'; end if;
  return query
    select 'Version'::text,'Backend'::text,case when exists(select 1 from public.app_settings where key='app_version' and value='"0.9.10"'::jsonb) then 'PASS' else 'FAIL' end,'app_version=0.9.10'::text
    union all select 'Calendrier','Protection manuelle',case when exists(select 1 from information_schema.columns where table_schema='public' and table_name='matches' and column_name='manual_schedule_lock') then 'PASS' else 'FAIL' end,'matches.manual_schedule_lock'
    union all select 'Clubs','Protection métadonnées',case when exists(select 1 from information_schema.columns where table_schema='public' and table_name='clubs' and column_name='manual_metadata_lock') then 'PASS' else 'FAIL' end,'clubs.manual_metadata_lock'
    union all select 'Calendrier','Fenêtres UEFA',case when to_regclass('public.competition_schedule_windows_v0910') is not null then 'PASS' else 'FAIL' end,'competition_schedule_windows_v0910'
    union all select 'Champion','Candidats avant calendrier',case when to_regprocedure('public.season_start_year_v0910(uuid)') is not null then 'PASS' else 'FAIL' end,'fallback club_catalog_memberships CL'
    union all select 'Pré-production','Reset propre',case when to_regprocedure('public.admin_prelaunch_reset_v0910(uuid,text)') is not null then 'PASS' else 'FAIL' end,'RESET AVANT OUVERTURE'
    union all select 'Administration','Édition manuelle',case when to_regprocedure('public.admin_update_match_schedule_v0910(uuid,uuid,uuid,timestamp with time zone,uuid,text,text,boolean)') is not null and to_regprocedure('public.admin_update_club_metadata_v0910(uuid,text,text,text,text,text,text,boolean)') is not null then 'PASS' else 'FAIL' end,'matchs + clubs';
end;$$;
grant execute on function public.admin_diagnostics_v0910() to authenticated;

insert into public.app_settings(key,value)
values('app_version','"0.9.10"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

commit;
