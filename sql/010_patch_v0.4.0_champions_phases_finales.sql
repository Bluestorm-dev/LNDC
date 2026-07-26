-- =============================================================================
-- LE NID DES CHAMPIONS — V0.4.0
-- Champions + phases finales complètes
-- =============================================================================
-- Couvre : champion +100, OM par défaut, 2e champion +50, choix cachés,
-- éliminations, aller-retour, cumul, score à 120 minutes, tirs au but,
-- qualifié, bonus qualifié et multiplicateurs x1/x2/x3/x4.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. Phases UEFA 2026/27
-- -----------------------------------------------------------------------------
insert into public.competition_phases(season_id,code,name,sort_order,default_multiplier)
select s.id, v.code, v.name, v.sort_order, v.multiplier
from public.seasons s
cross join (values
  ('LEAGUE','Phase de ligue',10,1::numeric),
  ('KNOCKOUT_PLAYOFF','Barrages',20,1::numeric),
  ('ROUND_OF_16','Huitièmes de finale',30,1::numeric),
  ('QUARTER_FINAL','Quarts de finale',40,1::numeric),
  ('SEMI_FINAL','Demi-finales',50,1::numeric),
  ('FINAL','Finale',60,1::numeric)
) as v(code,name,sort_order,multiplier)
on conflict (season_id,code) do update
set name=excluded.name,sort_order=excluded.sort_order;

-- -----------------------------------------------------------------------------
-- 2. Confrontations à élimination directe
-- -----------------------------------------------------------------------------
create table if not exists public.knockout_ties (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  phase_id uuid not null references public.competition_phases(id) on delete cascade,
  code text not null,
  label text not null,
  sort_order integer not null default 0,
  team_a_club_id uuid references public.clubs(id) on delete set null,
  team_b_club_id uuid references public.clubs(id) on delete set null,
  qualified_club_id uuid references public.clubs(id) on delete set null,
  status text not null default 'scheduled' check (status in ('scheduled','live','finished','cancelled')),
  is_single_match boolean not null default false,
  is_test boolean not null default false,
  leg1_kickoff_at timestamptz not null,
  leg2_kickoff_at timestamptz,
  qualifier_bonus_early numeric(6,2) not null default 3,
  qualifier_bonus_late numeric(6,2) not null default 1,
  next_tie_id uuid references public.knockout_ties(id) on delete set null deferrable initially deferred,
  next_slot text check (next_slot in ('A','B')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(season_id,code),
  check (team_a_club_id is null or team_b_club_id is null or team_a_club_id<>team_b_club_id),
  check ((is_single_match and leg2_kickoff_at is null) or (not is_single_match and leg2_kickoff_at is not null))
);

create index if not exists knockout_ties_season_phase_idx on public.knockout_ties(season_id,phase_id,sort_order);
create index if not exists knockout_ties_next_idx on public.knockout_ties(next_tie_id);

drop trigger if exists knockout_ties_updated_at on public.knockout_ties;
create trigger knockout_ties_updated_at before update on public.knockout_ties
for each row execute function public.set_updated_at();

alter table public.matches add column if not exists tie_id uuid references public.knockout_ties(id) on delete set null;
alter table public.matches add column if not exists leg_number smallint check (leg_number in (1,2));
alter table public.matches add column if not exists went_to_extra_time boolean not null default false;
alter table public.matches add column if not exists penalties_home integer check (penalties_home is null or penalties_home>=0);
alter table public.matches add column if not exists penalties_away integer check (penalties_away is null or penalties_away>=0);
alter table public.matches add column if not exists winner_club_id uuid references public.clubs(id) on delete set null;
create index if not exists matches_tie_idx on public.matches(tie_id,leg_number);

-- -----------------------------------------------------------------------------
-- 3. Pronostic du qualifié d'une confrontation
-- -----------------------------------------------------------------------------
create table if not exists public.tie_predictions (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  tie_id uuid not null references public.knockout_ties(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  qualified_club_id uuid not null references public.clubs(id) on delete restrict,
  pick_timing text not null default 'early' check (pick_timing in ('early','late')),
  points numeric(8,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id,tie_id)
);
create index if not exists tie_predictions_user_idx on public.tie_predictions(season_id,user_id);

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
  if t.status in ('finished','cancelled') then raise exception 'Pronostic qualifié verrouillé.'; end if;
  if t.team_a_club_id is null or t.team_b_club_id is null then raise exception 'Les deux clubs ne sont pas encore connus.'; end if;
  if new.qualified_club_id not in (t.team_a_club_id,t.team_b_club_id) then raise exception 'Le qualifié doit être l’un des deux clubs.'; end if;

  v_first:=t.leg1_kickoff_at;
  v_last:=case when t.is_single_match then t.leg1_kickoff_at else t.leg2_kickoff_at end;
  if now()>=v_last then raise exception 'Pronostic qualifié verrouillé.'; end if;

  new.season_id:=t.season_id;
  new.pick_timing:=case
    when tg_op='UPDATE' and new.qualified_club_id=old.qualified_club_id then old.pick_timing
    when now()<v_first then 'early' else 'late' end;
  new.points:=0;
  new.updated_at:=now();
  return new;
end;
$$;

drop trigger if exists tie_predictions_guard on public.tie_predictions;
create trigger tie_predictions_guard before insert or update on public.tie_predictions
for each row execute function public.guard_tie_prediction_v040();

-- -----------------------------------------------------------------------------
-- 4. Champions de la saison
-- -----------------------------------------------------------------------------
create table if not exists public.champion_predictions (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  pick_number smallint not null check (pick_number in (1,2)),
  club_id uuid not null references public.clubs(id) on delete restrict,
  assigned_default boolean not null default false,
  locked_at timestamptz,
  eliminated_at timestamptz,
  points integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id,season_id,pick_number)
);
create index if not exists champion_predictions_season_user_idx on public.champion_predictions(season_id,user_id);
create index if not exists champion_predictions_club_idx on public.champion_predictions(season_id,club_id);

create or replace function public.champion_first_close_at_v040(p_season_id uuid)
returns timestamptz language sql stable security definer set search_path=public as $$
  select min(m.kickoff_at)
  from public.matches m
  join public.competition_phases ph on ph.id=m.phase_id
  where m.season_id=p_season_id and ph.code='LEAGUE' and m.status not in ('cancelled','postponed');
$$;

create or replace function public.champion_second_close_at_v040(p_season_id uuid)
returns timestamptz language sql stable security definer set search_path=public as $$
  select min(t.leg1_kickoff_at)
  from public.knockout_ties t
  join public.competition_phases ph on ph.id=t.phase_id
  where t.season_id=p_season_id and ph.code in ('KNOCKOUT_PLAYOFF','ROUND_OF_16') and t.status<>'cancelled';
$$;

create or replace function public.league_phase_finished_v040(p_season_id uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.matches m join public.competition_phases ph on ph.id=m.phase_id
    where m.season_id=p_season_id and ph.code='LEAGUE' and m.status<>'cancelled'
  ) and not exists(
    select 1 from public.matches m join public.competition_phases ph on ph.id=m.phase_id
    where m.season_id=p_season_id and ph.code='LEAGUE' and m.status not in ('finished','cancelled')
  );
$$;

create or replace function public.is_champion_pick_open_v040(p_season_id uuid,p_pick_number integer)
returns boolean language plpgsql stable security definer set search_path=public as $$
declare v_close timestamptz;
begin
  if p_pick_number=1 then
    v_close:=public.champion_first_close_at_v040(p_season_id);
    return v_close is null or now()<v_close;
  elsif p_pick_number=2 then
    if not public.league_phase_finished_v040(p_season_id) then return false; end if;
    v_close:=public.champion_second_close_at_v040(p_season_id);
    return v_close is null or now()<v_close;
  end if;
  return false;
end;
$$;

create or replace function public.is_champion_candidate_v040(p_season_id uuid,p_pick_number integer,p_club_id uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select case
    when p_pick_number=1 then exists(
      select 1 from public.matches m join public.competition_phases ph on ph.id=m.phase_id
      where m.season_id=p_season_id and ph.code='LEAGUE' and (m.home_club_id=p_club_id or m.away_club_id=p_club_id)
    )
    when p_pick_number=2 then exists(
      select 1 from public.knockout_ties t
      where t.season_id=p_season_id and t.status<>'cancelled'
        and (t.team_a_club_id=p_club_id or t.team_b_club_id=p_club_id or t.qualified_club_id=p_club_id)
    )
    else false end;
$$;

create or replace function public.save_champion_pick_v040(p_pick_number integer,p_club_id uuid,p_season_id uuid default null)
returns void
language plpgsql security definer set search_path=public as $$
declare v_season uuid;
begin
  if auth.uid() is null then raise exception 'Utilisateur non connecté.'; end if;
  v_season:=p_season_id;
  if v_season is null then select id into v_season from public.seasons where is_active=true order by created_at desc limit 1; end if;
  if v_season is null then raise exception 'Saison active introuvable.'; end if;
  if p_pick_number not in (1,2) then raise exception 'Choix champion invalide.'; end if;
  if not public.is_champion_pick_open_v040(v_season,p_pick_number) then raise exception 'Ce choix champion est verrouillé.'; end if;
  if not public.is_champion_candidate_v040(v_season,p_pick_number,p_club_id) then raise exception 'Ce club n’est pas disponible pour ce choix champion.'; end if;

  insert into public.champion_predictions(user_id,season_id,pick_number,club_id,assigned_default,locked_at)
  values(auth.uid(),v_season,p_pick_number,p_club_id,false,null)
  on conflict(user_id,season_id,pick_number) do update
    set club_id=excluded.club_id,assigned_default=false,eliminated_at=null,points=0,updated_at=now();
end;
$$;

grant execute on function public.save_champion_pick_v040(integer,uuid,uuid) to authenticated;

-- OM est attribué à tous les joueurs actifs qui ont oublié le premier champion.
create or replace function public.assign_default_champion_1_v040(p_season_id uuid)
returns integer
language plpgsql security definer set search_path=public as $$
declare v_om uuid; v_count integer:=0; v_close timestamptz;
begin
  v_close:=public.champion_first_close_at_v040(p_season_id);
  if v_close is null or now()<v_close then return 0; end if;
  select c.id into v_om from public.clubs c
  where lower(c.name) like '%marseille%' or lower(c.short_name) like '%marseille%' or upper(coalesce(c.tla,''))='OM'
  order by (c.external_provider='football-data') desc nulls last,c.name limit 1;
  if v_om is null then raise exception 'Olympique de Marseille introuvable. Synchronise la bibliothèque Top 5.'; end if;

  insert into public.champion_predictions(user_id,season_id,pick_number,club_id,assigned_default,locked_at)
  select p.id,p_season_id,1,v_om,true,v_close
  from public.profiles p
  where p.status='active'
    and not exists(select 1 from public.champion_predictions cp where cp.user_id=p.id and cp.season_id=p_season_id and cp.pick_number=1)
  on conflict do nothing;
  get diagnostics v_count=row_count;
  update public.champion_predictions set locked_at=coalesce(locked_at,v_close),updated_at=now()
  where season_id=p_season_id and pick_number=1;
  return v_count;
end;
$$;
revoke all on function public.assign_default_champion_1_v040(uuid) from public,anon,authenticated;

create or replace function public.admin_assign_default_champion_v040(p_season_id uuid)
returns integer language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  return public.assign_default_champion_1_v040(p_season_id);
end;
$$;
grant execute on function public.admin_assign_default_champion_v040(uuid) to authenticated;

create or replace function public.auto_default_champion_on_first_live_v040()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status in ('live','finished') and old.status is distinct from new.status then
    if now()>=coalesce(public.champion_first_close_at_v040(new.season_id),'infinity'::timestamptz) then
      perform public.assign_default_champion_1_v040(new.season_id);
    end if;
  end if;
  return new;
exception when others then
  -- Un logo/catalogue manquant ne doit jamais empêcher la saisie d'un score.
  return new;
end;
$$;
drop trigger if exists auto_default_champion_first_live on public.matches;
create trigger auto_default_champion_first_live after update of status on public.matches
for each row execute function public.auto_default_champion_on_first_live_v040();

-- -----------------------------------------------------------------------------
-- 5. RLS : les choix restent secrets jusqu'au verrouillage
-- -----------------------------------------------------------------------------
alter table public.knockout_ties enable row level security;
alter table public.tie_predictions enable row level security;
alter table public.champion_predictions enable row level security;

drop policy if exists knockout_ties_read on public.knockout_ties;
create policy knockout_ties_read on public.knockout_ties for select to authenticated using (true);
drop policy if exists knockout_ties_admin_all on public.knockout_ties;
create policy knockout_ties_admin_all on public.knockout_ties for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists tie_predictions_own_or_admin on public.tie_predictions;
create policy tie_predictions_own_or_admin on public.tie_predictions for select to authenticated using(user_id=auth.uid() or public.is_admin());
drop policy if exists tie_predictions_insert on public.tie_predictions;
create policy tie_predictions_insert on public.tie_predictions for insert to authenticated with check(user_id=auth.uid());
drop policy if exists tie_predictions_update on public.tie_predictions;
create policy tie_predictions_update on public.tie_predictions for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

drop policy if exists champion_predictions_own_or_admin on public.champion_predictions;
create policy champion_predictions_own_or_admin on public.champion_predictions for select to authenticated using(user_id=auth.uid() or public.is_admin());
drop policy if exists champion_predictions_admin_write on public.champion_predictions;
create policy champion_predictions_admin_write on public.champion_predictions for all to authenticated using(public.is_admin()) with check(public.is_admin());

grant select on public.knockout_ties to authenticated;
grant select,insert,update on public.tie_predictions to authenticated;
grant select on public.champion_predictions to authenticated;
grant insert,update,delete on public.knockout_ties to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Cumul, qualifié et création automatique des matchs
-- -----------------------------------------------------------------------------
create or replace function public.ensure_knockout_matches_v040(p_tie_id uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare t public.knockout_ties%rowtype; ph public.competition_phases%rowtype; v_count integer:=0;
begin
  select * into t from public.knockout_ties where id=p_tie_id;
  if not found or t.team_a_club_id is null or t.team_b_club_id is null then return 0; end if;
  select * into ph from public.competition_phases where id=t.phase_id;

  if not exists(select 1 from public.matches where tie_id=t.id and leg_number=1) then
    insert into public.matches(season_id,phase_id,matchday_id,home_club_id,away_club_id,kickoff_at,status,data_source,points_multiplier,tie_id,leg_number)
    values(t.season_id,t.phase_id,null,t.team_a_club_id,t.team_b_club_id,t.leg1_kickoff_at,'scheduled','manual',ph.default_multiplier,t.id,1);
    v_count:=v_count+1;
  end if;
  if not t.is_single_match and not exists(select 1 from public.matches where tie_id=t.id and leg_number=2) then
    insert into public.matches(season_id,phase_id,matchday_id,home_club_id,away_club_id,kickoff_at,status,data_source,points_multiplier,tie_id,leg_number)
    values(t.season_id,t.phase_id,null,t.team_b_club_id,t.team_a_club_id,t.leg2_kickoff_at,'scheduled','manual',ph.default_multiplier,t.id,2);
    v_count:=v_count+1;
  end if;
  return v_count;
end;
$$;
revoke all on function public.ensure_knockout_matches_v040(uuid) from public,anon,authenticated;

create or replace function public.tie_aggregate_v040(p_tie_id uuid)
returns table(team_a_goals integer,team_b_goals integer)
language sql stable security definer set search_path=public as $$
  select
    coalesce(sum(case when m.home_club_id=t.team_a_club_id then m.home_score when m.away_club_id=t.team_a_club_id then m.away_score else 0 end) filter(where m.status in ('live','finished')),0)::integer,
    coalesce(sum(case when m.home_club_id=t.team_b_club_id then m.home_score when m.away_club_id=t.team_b_club_id then m.away_score else 0 end) filter(where m.status in ('live','finished')),0)::integer
  from public.knockout_ties t left join public.matches m on m.tie_id=t.id
  where t.id=p_tie_id group by t.id;
$$;
grant execute on function public.tie_aggregate_v040(uuid) to authenticated;

create or replace function public.recalculate_tie_prediction_points_v040(p_tie_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  -- Les points qualifié sont calculés dynamiquement par get_leaderboard_v040.
  -- On évite ainsi qu'un client puisse modifier une colonne de points persistée.
  return;
end;
$$;

create or replace function public.recalculate_champion_points_v040(p_season_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_winner uuid; s public.seasons%rowtype;
begin
  select * into s from public.seasons where id=p_season_id;
  select t.qualified_club_id into v_winner
  from public.knockout_ties t join public.competition_phases ph on ph.id=t.phase_id
  where t.season_id=p_season_id and ph.code='FINAL' and t.status='finished'
  order by t.sort_order limit 1;
  if v_winner is null then return; end if;
  update public.champion_predictions cp
  set points=case when cp.club_id=v_winner then case when cp.pick_number=1 then s.champion_1_bonus else s.champion_2_bonus end else 0 end,
      eliminated_at=case when cp.club_id<>v_winner then coalesce(cp.eliminated_at,now()) else null end,
      updated_at=now()
  where cp.season_id=p_season_id;
end;
$$;

create or replace function public.recalculate_champion_eliminations_v040(p_season_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  -- Après la ligue : tout premier champion absent des 24 clubs du tableau est éliminé.
  if public.league_phase_finished_v040(p_season_id) and (
    select count(distinct club_id) from (
      select team_a_club_id as club_id from public.knockout_ties where season_id=p_season_id and team_a_club_id is not null
      union all
      select team_b_club_id from public.knockout_ties where season_id=p_season_id and team_b_club_id is not null
    ) seeded
  ) >= 24 then
    update public.champion_predictions cp
    set eliminated_at=coalesce(cp.eliminated_at,now()),updated_at=now()
    where cp.season_id=p_season_id and cp.eliminated_at is null
      and not exists(
        select 1 from public.knockout_ties t where t.season_id=p_season_id
          and (t.team_a_club_id=cp.club_id or t.team_b_club_id=cp.club_id or t.qualified_club_id=cp.club_id)
      );
  end if;
end;
$$;

create or replace function public.maybe_finalize_tie_v040(p_tie_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare
  t public.knockout_ties%rowtype; m1 public.matches%rowtype; m2 public.matches%rowtype;
  a integer; b integer; v_qualified uuid; v_loser uuid;
begin
  select * into t from public.knockout_ties where id=p_tie_id for update;
  if not found or t.status='finished' then return coalesce(t.status='finished',false); end if;
  select * into m1 from public.matches where tie_id=t.id and leg_number=1;
  if not found or m1.status<>'finished' then return false; end if;

  if t.is_single_match then
    if m1.home_score>m1.away_score then v_qualified:=m1.home_club_id;
    elsif m1.away_score>m1.home_score then v_qualified:=m1.away_club_id;
    else
      if not m1.went_to_extra_time then raise exception 'Finale à égalité : indique la prolongation (score à 120 minutes).'; end if;
      if m1.penalties_home is null or m1.penalties_away is null or m1.penalties_home=m1.penalties_away then
        raise exception 'Finale à égalité après 120 minutes : renseigne les tirs au but.';
      end if;
      v_qualified:=case when m1.penalties_home>m1.penalties_away then m1.home_club_id else m1.away_club_id end;
    end if;
  else
    select * into m2 from public.matches where tie_id=t.id and leg_number=2;
    if not found or m2.status<>'finished' then return false; end if;
    select team_a_goals,team_b_goals into a,b from public.tie_aggregate_v040(t.id);
    if a>b then v_qualified:=t.team_a_club_id;
    elsif b>a then v_qualified:=t.team_b_club_id;
    else
      if not m2.went_to_extra_time then raise exception 'Cumul à égalité : indique la prolongation du match retour (score à 120 minutes).'; end if;
      if m2.penalties_home is null or m2.penalties_away is null or m2.penalties_home=m2.penalties_away then
        raise exception 'Cumul à égalité après 120 minutes : renseigne les tirs au but du match retour.';
      end if;
      v_qualified:=case when m2.penalties_home>m2.penalties_away then m2.home_club_id else m2.away_club_id end;
    end if;
  end if;

  v_loser:=case when v_qualified=t.team_a_club_id then t.team_b_club_id else t.team_a_club_id end;
  update public.knockout_ties set qualified_club_id=v_qualified,status='finished',updated_at=now() where id=t.id;
  update public.champion_predictions set eliminated_at=coalesce(eliminated_at,now()),updated_at=now()
    where season_id=t.season_id and club_id=v_loser and eliminated_at is null;
  perform public.recalculate_tie_prediction_points_v040(t.id);

  if t.next_tie_id is not null and t.next_slot is not null then
    if t.next_slot='A' then update public.knockout_ties set team_a_club_id=v_qualified where id=t.next_tie_id;
    else update public.knockout_ties set team_b_club_id=v_qualified where id=t.next_tie_id; end if;
    perform public.ensure_knockout_matches_v040(t.next_tie_id);
  else
    perform public.recalculate_champion_points_v040(t.season_id);
  end if;
  return true;
end;
$$;

-- -----------------------------------------------------------------------------
-- 7. Saisie Admin : score à 120 min + tirs au but + qualification
-- -----------------------------------------------------------------------------
create or replace function public.admin_set_knockout_match_state_v040(
  p_match_id uuid,
  p_status text,
  p_home_score integer default null,
  p_away_score integer default null,
  p_went_to_extra_time boolean default false,
  p_penalties_home integer default null,
  p_penalties_away integer default null,
  p_kickoff_at timestamptz default null
)
returns void language plpgsql security definer set search_path=public as $$
declare m public.matches%rowtype;
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  select * into m from public.matches where id=p_match_id;
  if not found or m.tie_id is null then raise exception 'Match de phase finale introuvable.'; end if;
  if p_status not in ('scheduled','live','finished','postponed','cancelled') then raise exception 'Statut invalide.'; end if;
  if p_status in ('live','finished') and (p_home_score is null or p_away_score is null) then raise exception 'Le score doit contenir les deux valeurs.'; end if;
  if coalesce(p_home_score,0)<0 or coalesce(p_away_score,0)<0 or coalesce(p_penalties_home,0)<0 or coalesce(p_penalties_away,0)<0 then raise exception 'Une valeur ne peut pas être négative.'; end if;

  update public.matches
  set status=p_status,
      home_score=case when p_status in ('live','finished') then p_home_score when p_status='scheduled' then null else home_score end,
      away_score=case when p_status in ('live','finished') then p_away_score when p_status='scheduled' then null else away_score end,
      went_to_extra_time=case when p_status in ('live','finished') then coalesce(p_went_to_extra_time,false) else went_to_extra_time end,
      penalties_home=case when p_status in ('live','finished') then p_penalties_home when p_status='scheduled' then null else penalties_home end,
      penalties_away=case when p_status in ('live','finished') then p_penalties_away when p_status='scheduled' then null else penalties_away end,
      winner_club_id=case
        when p_status='finished' and p_home_score>p_away_score then home_club_id
        when p_status='finished' and p_away_score>p_home_score then away_club_id
        when p_status='finished' and p_penalties_home is not null and p_penalties_away is not null and p_penalties_home<>p_penalties_away
          then case when p_penalties_home>p_penalties_away then home_club_id else away_club_id end
        when p_status='scheduled' then null else winner_club_id end,
      kickoff_at=coalesce(p_kickoff_at,kickoff_at),data_source='manual',updated_at=now()
  where id=p_match_id;

  update public.knockout_ties set status=case when p_status='live' then 'live' else status end where id=m.tie_id and status<>'finished';
  if p_status='finished' then perform public.maybe_finalize_tie_v040(m.tie_id); end if;
end;
$$;
grant execute on function public.admin_set_knockout_match_state_v040(uuid,text,integer,integer,boolean,integer,integer,timestamptz) to authenticated;

-- -----------------------------------------------------------------------------
-- 8. Multiplicateurs configurables
-- -----------------------------------------------------------------------------
create or replace function public.admin_set_phase_multiplier_v040(p_phase_id uuid,p_multiplier numeric,p_apply_to_upcoming boolean default true)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  if p_multiplier not in (1,2,3,4) then raise exception 'Multiplicateur autorisé : x1, x2, x3 ou x4.'; end if;
  update public.competition_phases set default_multiplier=p_multiplier where id=p_phase_id;
  if p_apply_to_upcoming then
    update public.matches set points_multiplier=p_multiplier where phase_id=p_phase_id and status in ('scheduled','postponed');
  end if;
end;
$$;
create or replace function public.admin_set_match_multiplier_v040(p_match_id uuid,p_multiplier numeric)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  if p_multiplier not in (1,2,3,4) then raise exception 'Multiplicateur autorisé : x1, x2, x3 ou x4.'; end if;
  update public.matches set points_multiplier=p_multiplier where id=p_match_id;
end;
$$;
grant execute on function public.admin_set_phase_multiplier_v040(uuid,numeric,boolean) to authenticated;
grant execute on function public.admin_set_match_multiplier_v040(uuid,numeric) to authenticated;

-- -----------------------------------------------------------------------------
-- 9. Centre Champions : candidat, statut et révélation après verrouillage
-- -----------------------------------------------------------------------------
create or replace function public.get_champion_candidates_v040(p_season_id uuid,p_pick_number integer)
returns table(club_id uuid,name text,short_name text,tla text,logo_url text,logo_source_url text)
language sql stable security definer set search_path=public as $$
  select distinct c.id,c.name,c.short_name,c.tla,c.logo_url,c.logo_source_url
  from public.clubs c
  where c.is_active=true and public.is_champion_candidate_v040(p_season_id,p_pick_number,c.id)
  order by c.name;
$$;
grant execute on function public.get_champion_candidates_v040(uuid,integer) to authenticated;

create or replace function public.get_champion_board_v040(p_season_id uuid,p_pick_number integer)
returns table(user_id uuid,username text,club_id uuid,club_name text,assigned_default boolean,eliminated_at timestamptz,points integer)
language sql stable security definer set search_path=public as $$
  select cp.user_id,p.username::text,cp.club_id,c.name,cp.assigned_default,cp.eliminated_at,cp.points
  from public.champion_predictions cp
  join public.profiles p on p.id=cp.user_id
  join public.clubs c on c.id=cp.club_id
  where cp.season_id=p_season_id and cp.pick_number=p_pick_number and p.status='active'
    and (cp.user_id=auth.uid() or public.is_admin() or not public.is_champion_pick_open_v040(p_season_id,p_pick_number))
  order by p.username;
$$;
grant execute on function public.get_champion_board_v040(uuid,integer) to authenticated;

create or replace function public.get_champion_status_v040(p_season_id uuid)
returns table(
  first_open boolean,first_close_at timestamptz,second_open boolean,second_close_at timestamptz,
  first_club_id uuid,first_club_name text,first_default boolean,first_eliminated_at timestamptz,first_points integer,
  second_club_id uuid,second_club_name text,second_eliminated_at timestamptz,second_points integer
)
language sql stable security definer set search_path=public as $$
  select
    public.is_champion_pick_open_v040(p_season_id,1),public.champion_first_close_at_v040(p_season_id),
    public.is_champion_pick_open_v040(p_season_id,2),public.champion_second_close_at_v040(p_season_id),
    c1.id,c1.name,coalesce(cp1.assigned_default,false),cp1.eliminated_at,coalesce(cp1.points,0),
    c2.id,c2.name,cp2.eliminated_at,coalesce(cp2.points,0)
  from (select 1) x
  left join public.champion_predictions cp1 on cp1.user_id=auth.uid() and cp1.season_id=p_season_id and cp1.pick_number=1
  left join public.clubs c1 on c1.id=cp1.club_id
  left join public.champion_predictions cp2 on cp2.user_id=auth.uid() and cp2.season_id=p_season_id and cp2.pick_number=2
  left join public.clubs c2 on c2.id=cp2.club_id;
$$;
grant execute on function public.get_champion_status_v040(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 10. Classement V0.4 : points matchs + bonus qualifiés + champions
-- -----------------------------------------------------------------------------
create or replace function public.get_leaderboard_v040(
  p_season_id uuid,
  p_scope text default 'general',
  p_matchday_id uuid default null,
  p_evening_date date default null,
  p_include_live boolean default true
)
returns table(
  rank bigint,previous_rank bigint,variation bigint,user_id uuid,username text,avatar_key text,club_heart text,
  points numeric,official_points numeric,exact_scores bigint,good_differences bigint,good_results bigint,played bigint,
  average numeric,precision_pct numeric,above_gap numeric,below_gap numeric
)
language sql stable security definer set search_path=public as $$
with base as (
  select * from public.get_leaderboard_v030(p_season_id,p_scope,p_matchday_id,p_evening_date,p_include_live)
),
qualifier_extra as (
  select tp.user_id,coalesce(sum(case when t.status='finished' and t.qualified_club_id=tp.qualified_club_id then case when tp.pick_timing='early' then t.qualifier_bonus_early else t.qualifier_bonus_late end else 0 end),0)::numeric as pts
  from public.tie_predictions tp
  join public.knockout_ties t on t.id=tp.tie_id
  left join public.matches dm on dm.tie_id=t.id and dm.leg_number=case when t.is_single_match then 1 else 2 end
  where tp.season_id=p_season_id
    and (p_scope='general'
      or (p_scope='matchday' and p_matchday_id is not null and dm.matchday_id=p_matchday_id)
      or (p_scope='evening' and (dm.kickoff_at at time zone 'Europe/Paris')::date=p_evening_date))
  group by tp.user_id
),
champion_extra as (
  select cp.user_id,coalesce(sum(cp.points),0)::numeric as pts
  from public.champion_predictions cp where cp.season_id=p_season_id and p_scope='general' group by cp.user_id
),
adjusted as (
  select b.*,
    (b.points+coalesce(q.pts,0)+coalesce(c.pts,0))::numeric as total_points,
    (b.official_points+coalesce(q.pts,0)+coalesce(c.pts,0))::numeric as total_official
  from base b left join qualifier_extra q on q.user_id=b.user_id left join champion_extra c on c.user_id=b.user_id
),
ranked as (
  select row_number() over(order by total_points desc,exact_scores desc,average desc,good_differences desc,played desc,username asc)::bigint as new_rank,a.*
  from adjusted a
),
gapped as (
  select r.*,
    (lag(total_points) over(order by new_rank)-total_points)::numeric as new_above,
    (total_points-lead(total_points) over(order by new_rank))::numeric as new_below
  from ranked r
)
select new_rank,previous_rank,(coalesce(previous_rank,new_rank)-new_rank)::bigint,user_id,username,avatar_key,club_heart,
  total_points,total_official,exact_scores,good_differences,good_results,played,average,precision_pct,new_above,new_below
from gapped order by new_rank;
$$;
grant execute on function public.get_leaderboard_v040(uuid,text,uuid,date,boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- 11. Générateur TEST complet : barrages -> finale (24 clubs)
-- -----------------------------------------------------------------------------
create or replace function public.admin_seed_knockout_test_v040(p_season_id uuid,p_start_at timestamptz default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  clubs uuid[]; start_at timestamptz:=coalesce(p_start_at,now()+interval '2 days');
  i integer; po_id uuid; r16_id uuid; qf_id uuid; sf_id uuid; f_id uuid;
  ph_po uuid; ph_r16 uuid; ph_qf uuid; ph_sf uuid; ph_f uuid;
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  select array_agg(id order by name) into clubs from (
    select distinct c.id,c.name from public.clubs c
    join public.club_catalog_memberships cm on cm.club_id=c.id and cm.competition_code='CL'
    where c.is_active=true limit 24
  ) z;
  if coalesce(array_length(clubs,1),0)<24 then
    select array_agg(id order by name) into clubs from (select id,name from public.clubs where is_active=true order by name limit 24) z;
  end if;
  if coalesce(array_length(clubs,1),0)<24 then raise exception 'Il faut au moins 24 clubs actifs pour générer le tableau test.'; end if;

  select id into ph_po from public.competition_phases where season_id=p_season_id and code='KNOCKOUT_PLAYOFF';
  select id into ph_r16 from public.competition_phases where season_id=p_season_id and code='ROUND_OF_16';
  select id into ph_qf from public.competition_phases where season_id=p_season_id and code='QUARTER_FINAL';
  select id into ph_sf from public.competition_phases where season_id=p_season_id and code='SEMI_FINAL';
  select id into ph_f from public.competition_phases where season_id=p_season_id and code='FINAL';

  delete from public.knockout_ties where season_id=p_season_id and is_test=true;

  -- Finale, demies, quarts, huitièmes : créés d'abord pour pouvoir chaîner les gagnants.
  insert into public.knockout_ties(season_id,phase_id,code,label,sort_order,is_single_match,is_test,leg1_kickoff_at)
  values(p_season_id,ph_f,'F1','Finale',1,true,true,start_at+interval '84 days') returning id into f_id;

  for i in 1..2 loop
    insert into public.knockout_ties(season_id,phase_id,code,label,sort_order,is_test,leg1_kickoff_at,leg2_kickoff_at,next_tie_id,next_slot)
    values(p_season_id,ph_sf,'SF'||i,'Demi-finale '||i,i,true,start_at+interval '63 days',start_at+interval '70 days',f_id,case when i=1 then 'A' else 'B' end) returning id into sf_id;
  end loop;

  for i in 1..4 loop
    select id into sf_id from public.knockout_ties where season_id=p_season_id and code='SF'||ceil(i/2.0)::int;
    insert into public.knockout_ties(season_id,phase_id,code,label,sort_order,is_test,leg1_kickoff_at,leg2_kickoff_at,next_tie_id,next_slot)
    values(p_season_id,ph_qf,'QF'||i,'Quart de finale '||i,i,true,start_at+interval '42 days',start_at+interval '49 days',sf_id,case when mod(i,2)=1 then 'A' else 'B' end);
  end loop;

  for i in 1..8 loop
    select id into qf_id from public.knockout_ties where season_id=p_season_id and code='QF'||ceil(i/2.0)::int;
    insert into public.knockout_ties(season_id,phase_id,code,label,sort_order,team_a_club_id,is_test,leg1_kickoff_at,leg2_kickoff_at,next_tie_id,next_slot)
    values(p_season_id,ph_r16,'R16-'||i,'Huitième '||i,i,clubs[i],true,start_at+interval '21 days',start_at+interval '28 days',qf_id,case when mod(i,2)=1 then 'A' else 'B' end)
    returning id into r16_id;

    insert into public.knockout_ties(season_id,phase_id,code,label,sort_order,team_a_club_id,team_b_club_id,is_test,leg1_kickoff_at,leg2_kickoff_at,next_tie_id,next_slot)
    values(p_season_id,ph_po,'PO'||i,'Barrage '||i,i,clubs[8+i],clubs[16+i],true,start_at+(i-1)*interval '15 minutes',start_at+interval '7 days'+(i-1)*interval '15 minutes',r16_id,'B')
    returning id into po_id;
    perform public.ensure_knockout_matches_v040(po_id);
  end loop;

  perform public.recalculate_champion_eliminations_v040(p_season_id);
  return jsonb_build_object('ok',true,'ties',23,'initial_matches',16,'start_at',start_at);
end;
$$;
grant execute on function public.admin_seed_knockout_test_v040(uuid,timestamptz) to authenticated;

-- Admin : créer / mettre à jour une confrontation réelle (draw manuel/API futur).
create or replace function public.admin_upsert_knockout_tie_v040(
  p_season_id uuid,p_phase_code text,p_code text,p_label text,p_team_a uuid,p_team_b uuid,
  p_leg1_kickoff_at timestamptz,p_leg2_kickoff_at timestamptz default null,p_is_single_match boolean default false
)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_phase uuid; v_id uuid; v_sort integer;
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  if p_team_a is null or p_team_b is null or p_team_a=p_team_b then raise exception 'Deux clubs différents sont obligatoires.'; end if;
  if p_leg1_kickoff_at is null then raise exception 'La date du premier match est obligatoire.'; end if;
  if p_phase_code='FINAL' and not p_is_single_match then raise exception 'La finale est un match unique.'; end if;
  if p_phase_code<>'FINAL' and p_is_single_match then raise exception 'Seule la finale est un match unique.'; end if;
  if not p_is_single_match and (p_leg2_kickoff_at is null or p_leg2_kickoff_at<=p_leg1_kickoff_at) then raise exception 'Le retour doit être programmé après l’aller.'; end if;

  select id into v_phase from public.competition_phases where season_id=p_season_id and code=p_phase_code;
  if v_phase is null then raise exception 'Phase introuvable.'; end if;
  select coalesce(max(sort_order),0)+1 into v_sort from public.knockout_ties where season_id=p_season_id and phase_id=v_phase;

  insert into public.knockout_ties(season_id,phase_id,code,label,sort_order,team_a_club_id,team_b_club_id,is_single_match,leg1_kickoff_at,leg2_kickoff_at,is_test)
  values(p_season_id,v_phase,p_code,p_label,v_sort,p_team_a,p_team_b,p_is_single_match,p_leg1_kickoff_at,case when p_is_single_match then null else p_leg2_kickoff_at end,false)
  on conflict(season_id,code) do update set phase_id=excluded.phase_id,label=excluded.label,team_a_club_id=excluded.team_a_club_id,team_b_club_id=excluded.team_b_club_id,is_single_match=excluded.is_single_match,leg1_kickoff_at=excluded.leg1_kickoff_at,leg2_kickoff_at=excluded.leg2_kickoff_at,updated_at=now()
  returning id into v_id;

  -- Si l'Admin corrige un tirage encore à venir, les matchs déjà créés suivent la confrontation.
  update public.matches m
  set home_club_id=p_team_a,away_club_id=p_team_b,kickoff_at=p_leg1_kickoff_at,phase_id=v_phase,updated_at=now()
  where m.tie_id=v_id and m.leg_number=1 and m.status in ('scheduled','postponed');
  if p_is_single_match then
    delete from public.matches m where m.tie_id=v_id and m.leg_number=2 and m.status in ('scheduled','postponed');
  else
    update public.matches m
    set home_club_id=p_team_b,away_club_id=p_team_a,kickoff_at=p_leg2_kickoff_at,phase_id=v_phase,updated_at=now()
    where m.tie_id=v_id and m.leg_number=2 and m.status in ('scheduled','postponed');
  end if;

  perform public.ensure_knockout_matches_v040(v_id);
  perform public.recalculate_champion_eliminations_v040(p_season_id);
  return v_id;
end;
$$;
grant execute on function public.admin_upsert_knockout_tie_v040(uuid,text,text,text,uuid,uuid,timestamptz,timestamptz,boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- 12. Realtime + version
-- -----------------------------------------------------------------------------
do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='knockout_ties') then execute 'alter publication supabase_realtime add table public.knockout_ties'; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='tie_predictions') then execute 'alter publication supabase_realtime add table public.tie_predictions'; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='champion_predictions') then execute 'alter publication supabase_realtime add table public.champion_predictions'; end if;
  end if;
end $$;

insert into public.app_settings(key,value) values('app_version','"0.4.0"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

-- Vérifications
select key,value from public.app_settings where key='app_version';
select code,name,default_multiplier from public.competition_phases order by sort_order;
select proname from pg_proc where proname in (
  'save_champion_pick_v040','get_champion_status_v040','get_champion_board_v040',
  'admin_set_knockout_match_state_v040','get_leaderboard_v040','admin_seed_knockout_test_v040'
) order by proname;
