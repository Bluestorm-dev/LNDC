-- Le Nid des Champions — installation fraîche V0.7.0
-- Socle V0.6.7 + moteur V0.7.0 + banque narrative.

-- Le Nid des Champions — INSTALLATION FRAÎCHE V0.5.5a
-- Socle V0.5.3 + migration V0.5.5 Team polish.

-- Le Nid des Champions V0.5.0 — installation fraîche
-- Base V0.4.2 complète + migration Teams V0.5.0.
-- À exécuter sur un projet Supabase vierge avec le rôle postgres.

-- Le Nid des Champions V0.4.2 — installation fraîche
-- Schéma identique à V0.4.0 : V0.4.2 conserve le même schéma : évolution front-only.

-- Le Nid des Champions — INSTALLATION FRAÎCHE V0.3.3
-- Socle V0.3.2 + migration V0.3.3 navigation A/B et bibliothèque clubs.

-- Le Nid des Champions — INSTALLATION FRAÎCHE V0.3.1
-- Généré à partir du socle V0.2.0 + migrations V0.3.0 et V0.3.1.
-- Les correctifs V0.2.2 côté Football-Data / interface sont dans les fichiers applicatifs.

-- Le Nid des Champions — INSTALLATION FRAÎCHE V0.2.0
-- Projet Supabase neuf uniquement. Exécuter tout ce fichier avec le rôle postgres.

-- Le Nid des Champions — V0.1.0
-- Nouvelle base Supabase. À exécuter dans le SQL Editor d'un projet SUPABASE NEUF.

begin;

create extension if not exists citext;
create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- Utilitaires
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Profils
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username citext not null unique,
  avatar_key text not null default 'owl-gold',
  club_heart text,
  role text not null default 'player' check (role in ('player','admin','super_admin')),
  status text not null default 'active' check (status in ('active','suspended','deleted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_private (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  first_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger profile_private_updated_at before update on public.profile_private
for each row execute function public.set_updated_at();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin','super_admin') and status = 'active'
  );
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'super_admin' and status = 'active'
  );
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_first_name text;
begin
  v_username := nullif(trim(new.raw_user_meta_data ->> 'username'), '');
  v_first_name := nullif(trim(new.raw_user_meta_data ->> 'first_name'), '');

  if v_username is null then
    raise exception 'Le pseudo est obligatoire.';
  end if;

  insert into public.profiles (id, username)
  values (new.id, v_username);

  insert into public.profile_private (user_id, first_name)
  values (new.id, v_first_name);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

create or replace function public.is_username_available(p_username text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1 from public.profiles where lower(username::text) = lower(trim(p_username))
  );
$$;

-- -----------------------------------------------------------------------------
-- Saison / compétition
-- -----------------------------------------------------------------------------
create table if not exists public.seasons (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  status text not null default 'preparation' check (status in ('preparation','active','finished','archived')),
  timezone text not null default 'Europe/Paris',
  is_active boolean not null default false,
  points_wrong integer not null default 0,
  points_result integer not null default 3,
  points_difference integer not null default 5,
  points_exact integer not null default 7,
  champion_1_bonus integer not null default 100,
  champion_2_bonus integer not null default 50,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.competition_phases (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  code text not null,
  name text not null,
  sort_order integer not null default 0,
  default_multiplier numeric(5,2) not null default 1,
  created_at timestamptz not null default now(),
  unique(season_id, code)
);

create table if not exists public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  short_name text not null,
  country text,
  logo_url text,
  primary_color text,
  secondary_color text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(name)
);

create table if not exists public.matchdays (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  phase_id uuid references public.competition_phases(id) on delete set null,
  number integer not null,
  name text not null,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  unique(season_id, number)
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  phase_id uuid references public.competition_phases(id) on delete set null,
  matchday_id uuid references public.matchdays(id) on delete set null,
  home_club_id uuid not null references public.clubs(id),
  away_club_id uuid not null references public.clubs(id),
  kickoff_at timestamptz not null,
  stadium text,
  status text not null default 'scheduled' check (status in ('scheduled','live','finished','postponed','cancelled')),
  data_source text not null default 'manual' check (data_source in ('manual','api')),
  home_score integer check (home_score is null or home_score >= 0),
  away_score integer check (away_score is null or away_score >= 0),
  points_multiplier numeric(5,2) not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (home_club_id <> away_club_id)
);

create trigger seasons_updated_at before update on public.seasons
for each row execute function public.set_updated_at();
create trigger matches_updated_at before update on public.matches
for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Pronostics et calcul serveur
-- -----------------------------------------------------------------------------
create table if not exists public.predictions (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  match_id uuid not null references public.matches(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  home_score integer not null check (home_score between 0 and 99),
  away_score integer not null check (away_score between 0 and 99),
  points numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, match_id)
);

create index if not exists predictions_season_user_idx on public.predictions(season_id,user_id);
create index if not exists predictions_match_idx on public.predictions(match_id);
create index if not exists matches_matchday_idx on public.matches(matchday_id,kickoff_at);

create or replace function public.guard_prediction_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches%rowtype;
begin
  select * into v_match from public.matches where id = new.match_id;
  if not found then raise exception 'Match introuvable.'; end if;

  -- Une mise à jour interne qui ne change que les points reste autorisée après verrouillage.
  if tg_op = 'UPDATE'
     and new.user_id = old.user_id
     and new.match_id = old.match_id
     and new.home_score = old.home_score
     and new.away_score = old.away_score then
    new.season_id := v_match.season_id;
    new.updated_at := now();
    return new;
  end if;

  if v_match.status <> 'scheduled' or v_match.kickoff_at <= now() then
    raise exception 'Pronostic verrouillé.';
  end if;

  new.season_id := v_match.season_id;
  new.points := 0;
  new.updated_at := now();
  return new;
end;
$$;

create trigger predictions_guard before insert or update on public.predictions
for each row execute function public.guard_prediction_write();

create or replace function public.calculate_prediction_points(p_prediction_id uuid)
returns numeric
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  p public.predictions%rowtype;
  m public.matches%rowtype;
  s public.seasons%rowtype;
  v_base numeric := 0;
  v_pred_diff integer;
  v_real_diff integer;
begin
  select * into p from public.predictions where id = p_prediction_id;
  if not found then return 0; end if;
  select * into m from public.matches where id = p.match_id;
  select * into s from public.seasons where id = p.season_id;

  if m.status <> 'finished' or m.home_score is null or m.away_score is null then return 0; end if;

  if p.home_score = m.home_score and p.away_score = m.away_score then
    v_base := s.points_exact;
  else
    v_pred_diff := p.home_score - p.away_score;
    v_real_diff := m.home_score - m.away_score;
    if sign(v_pred_diff) = sign(v_real_diff) and v_pred_diff = v_real_diff then
      v_base := s.points_difference;
    elsif sign(v_pred_diff) = sign(v_real_diff) then
      v_base := s.points_result;
    else
      v_base := s.points_wrong;
    end if;
  end if;

  return v_base * m.points_multiplier;
end;
$$;

create or replace function public.recalculate_match_points(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.predictions p
  set points = public.calculate_prediction_points(p.id), updated_at = now()
  where p.match_id = p_match_id;
end;
$$;

create or replace function public.recalculate_after_match_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is distinct from new.status
     or old.home_score is distinct from new.home_score
     or old.away_score is distinct from new.away_score
     or old.points_multiplier is distinct from new.points_multiplier then
    perform public.recalculate_match_points(new.id);
  end if;
  return new;
end;
$$;

create trigger match_recalculate_points
after update on public.matches
for each row execute function public.recalculate_after_match_change();

-- -----------------------------------------------------------------------------
-- Classement public via RPC : aucun e-mail ni donnée privée n'est exposé.
-- -----------------------------------------------------------------------------
create or replace function public.get_standings(p_season_id uuid)
returns table (
  rank bigint,
  user_id uuid,
  username text,
  avatar_key text,
  club_heart text,
  points numeric,
  exact_scores bigint,
  good_differences bigint,
  played bigint,
  average numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with stats as (
    select
      pr.id as user_id,
      pr.username::text as username,
      pr.avatar_key,
      pr.club_heart,
      coalesce(sum(p.points),0)::numeric as points,
      count(*) filter (
        where m.status='finished' and p.home_score=m.home_score and p.away_score=m.away_score
      ) as exact_scores,
      count(*) filter (
        where m.status='finished'
          and not (p.home_score=m.home_score and p.away_score=m.away_score)
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
          and (p.home_score-p.away_score)=(m.home_score-m.away_score)
      ) as good_differences,
      count(*) filter (where m.status='finished') as played
    from public.profiles pr
    left join public.predictions p on p.user_id=pr.id and p.season_id=p_season_id
    left join public.matches m on m.id=p.match_id
    where pr.status='active'
    group by pr.id,pr.username,pr.avatar_key,pr.club_heart
  ), scored as (
    select *, case when played>0 then points/played else 0 end::numeric as average
    from stats
  )
  select
    row_number() over(order by points desc, exact_scores desc, average desc, good_differences desc, played desc, username asc) as rank,
    user_id,username,avatar_key,club_heart,points,exact_scores,good_differences,played,average
  from scored
  order by rank;
$$;

-- -----------------------------------------------------------------------------
-- Configuration, demandes au Hibou, journal
-- -----------------------------------------------------------------------------
create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table if not exists public.password_help_requests (
  id uuid primary key default gen_random_uuid(),
  username text not null,
  contact_email text not null,
  message text,
  status text not null default 'received' check (status in ('received','read','in_progress','resolved','closed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id)
);

create table if not exists public.audit_logs (
  id bigserial primary key,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  old_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.request_password_help(p_username text,p_contact_email text,p_message text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid;
begin
  if length(trim(p_username)) < 2 or position('@' in p_contact_email) < 2 then
    raise exception 'Informations invalides.';
  end if;
  insert into public.password_help_requests(username,contact_email,message)
  values(trim(p_username),lower(trim(p_contact_email)),nullif(trim(p_message),'')) returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.audit_match_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old is distinct from new then
    insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data,new_data)
    values(auth.uid(),'match_update','match',new.id::text,to_jsonb(old),to_jsonb(new));
  end if;
  return new;
end;
$$;
create trigger audit_matches after update on public.matches
for each row execute function public.audit_match_change();

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.profile_private enable row level security;
alter table public.seasons enable row level security;
alter table public.competition_phases enable row level security;
alter table public.clubs enable row level security;
alter table public.matchdays enable row level security;
alter table public.matches enable row level security;
alter table public.predictions enable row level security;
alter table public.app_settings enable row level security;
alter table public.password_help_requests enable row level security;
alter table public.audit_logs enable row level security;

-- Profils : seulement des données publiques dans profiles.
create policy profiles_public_read on public.profiles for select using (true);
create policy profiles_own_update on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
create policy profiles_admin_update on public.profiles for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy private_own_read on public.profile_private for select to authenticated using (user_id=auth.uid() or public.is_admin());
create policy private_own_update on public.profile_private for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy private_admin_update on public.profile_private for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Référentiel lisible publiquement.
create policy seasons_read on public.seasons for select using (true);
create policy phases_read on public.competition_phases for select using (true);
create policy clubs_read on public.clubs for select using (true);
create policy matchdays_read on public.matchdays for select using (true);
create policy matches_read on public.matches for select using (true);

create policy seasons_admin_all on public.seasons for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy phases_admin_all on public.competition_phases for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy clubs_admin_all on public.clubs for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy matchdays_admin_all on public.matchdays for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy matches_admin_update on public.matches for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Pronos visibles par leur auteur, les admins, puis par tous après le verrouillage du match.
create policy predictions_read on public.predictions for select to authenticated using (
  user_id=auth.uid() or public.is_admin() or exists(
    select 1 from public.matches m where m.id=match_id and (m.kickoff_at<=now() or m.status in ('live','finished'))
  )
);
create policy predictions_insert_own on public.predictions for insert to authenticated with check (user_id=auth.uid());
create policy predictions_update_own on public.predictions for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());

create policy app_settings_public_read on public.app_settings for select using (true);
create policy app_settings_admin_all on public.app_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy password_help_admin_read on public.password_help_requests for select to authenticated using (public.is_admin());
create policy password_help_admin_update on public.password_help_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy audit_admin_read on public.audit_logs for select to authenticated using (public.is_admin());

-- -----------------------------------------------------------------------------
-- Privilèges : un joueur ne peut pas s'auto-promouvoir en modifiant role/status.
-- -----------------------------------------------------------------------------
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to anon, authenticated;
grant update(username,avatar_key,club_heart) on public.profiles to authenticated;

grant select on public.profile_private to authenticated;
grant update(first_name) on public.profile_private to authenticated;

grant select on public.seasons,public.competition_phases,public.clubs,public.matchdays,public.matches to anon, authenticated;
grant insert,update,delete on public.seasons,public.competition_phases,public.clubs,public.matchdays to authenticated;
grant update on public.matches to authenticated;

grant select,insert,update on public.predictions to authenticated;
grant select on public.app_settings to anon,authenticated;
grant insert,update,delete on public.app_settings to authenticated;
grant select,update on public.password_help_requests to authenticated;
grant select on public.audit_logs to authenticated;

grant execute on function public.is_username_available(text) to anon,authenticated;
grant execute on function public.request_password_help(text,text,text) to anon,authenticated;
grant execute on function public.get_standings(uuid) to anon,authenticated;

-- -----------------------------------------------------------------------------
-- Données de test V0.1.0
-- -----------------------------------------------------------------------------
insert into public.app_settings(key,value)
values
  ('registration_open','true'::jsonb),
  ('app_version','"0.1.0"'::jsonb),
  ('maintenance','false'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

insert into public.seasons(name,slug,status,timezone,is_active,points_wrong,points_result,points_difference,points_exact,champion_1_bonus,champion_2_bonus)
values('Champions League 2026–27','ucl-2026-27','preparation','Europe/Paris',true,0,3,5,7,100,50)
on conflict(slug) do update set is_active=true;

insert into public.clubs(name,short_name,country,primary_color,secondary_color) values
('Paris SG','PSG','France','#0b1f5e','#df1f2d'),
('Bayern Munich','BAY','Allemagne','#dc052d','#0066b2'),
('Real Madrid','RMA','Espagne','#ffffff','#1f4da8'),
('Arsenal','ARS','Angleterre','#ef0107','#ffffff'),
('Inter Milan','INT','Italie','#00529f','#000000'),
('FC Barcelone','BAR','Espagne','#004d98','#a50044'),
('Liverpool','LIV','Angleterre','#c8102e','#00b2a9'),
('Dortmund','BVB','Allemagne','#fde100','#000000')
on conflict(name) do nothing;

-- V0.6.7 : plus aucun match fictif n’est injecté lors d’une installation neuve.
-- On crée uniquement la phase de ligue ; Admin > Test fabrique les journées temporaires.
do $$
declare v_season uuid;
begin
  select id into v_season from public.seasons where slug='ucl-2026-27';
  insert into public.competition_phases(season_id,code,name,sort_order,default_multiplier)
  values(v_season,'LEAGUE','Phase de ligue',10,1)
  on conflict(season_id,code) do update set name=excluded.name;
end $$;

-- Activer le Realtime sur matches si nécessaire.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='matches'
  ) then
    alter publication supabase_realtime add table public.matches;
  end if;
end $$;

commit;

-- -----------------------------------------------------------------------------
-- IMPORTANT APRÈS CRÉATION DU PREMIER COMPTE :
-- Remplace Parkaf si nécessaire puis exécute UNE FOIS :
--
-- update public.profiles set role='super_admin' where lower(username::text)=lower('Parkaf');
--
-- L'adresse e-mail réelle reste dans auth.users et n'est jamais exposée via profiles.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- V0.1.1 — Appliquer immédiatement le flux pending / Super Admin
-- Le bloc est volontairement dupliqué par inclusion conceptuelle :
-- pour un projet neuf, exécuter ensuite 002_patch_v0.1.1_inscriptions_super_admin.sql.
-- -----------------------------------------------------------------------------

-- ===== MIGRATION V0.1.1 =====
-- Le Nid des Champions — V0.1.1
-- Inscriptions : Supabase crée le compte, le Super Admin autorise l'accès au Nid.
-- À exécuter dans Supabase > SQL Editor avec le rôle POSTGRES / rôle par défaut.

begin;

-- -----------------------------------------------------------------------------
-- 1. Statuts de compte
-- -----------------------------------------------------------------------------
alter table public.profiles drop constraint if exists profiles_status_check;
alter table public.profiles
  add constraint profiles_status_check
  check (status in ('pending','active','rejected','suspended','deleted'));

alter table public.profiles alter column status set default 'pending';

-- Les futurs comptes arrivent toujours en attente.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_first_name text;
begin
  v_username := nullif(trim(new.raw_user_meta_data ->> 'username'), '');
  v_first_name := nullif(trim(new.raw_user_meta_data ->> 'first_name'), '');

  if v_username is null then
    raise exception 'Le pseudo est obligatoire.';
  end if;

  insert into public.profiles (id, username, status)
  values (new.id, v_username, 'pending');

  insert into public.profile_private (user_id, first_name)
  values (new.id, v_first_name);

  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. Garde d'accès active
-- -----------------------------------------------------------------------------
create or replace function public.is_active_member()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid() and status = 'active'
  );
$$;

-- Les demandes pending/rejected ne sont pas exposées publiquement.
drop policy if exists profiles_public_read on public.profiles;
create policy profiles_public_read on public.profiles
for select
using (
  status = 'active'
  or id = auth.uid()
  or public.is_admin()
);

-- Un compte non validé ne peut pas modifier son profil ni envoyer de pronostic.
drop policy if exists profiles_own_update on public.profiles;
create policy profiles_own_update on public.profiles
for update to authenticated
using (id = auth.uid() and public.is_active_member())
with check (id = auth.uid() and public.is_active_member());

drop policy if exists predictions_insert_own on public.predictions;
create policy predictions_insert_own on public.predictions
for insert to authenticated
with check (user_id = auth.uid() and public.is_active_member());

drop policy if exists predictions_update_own on public.predictions;
create policy predictions_update_own on public.predictions
for update to authenticated
using (user_id = auth.uid() and public.is_active_member())
with check (user_id = auth.uid() and public.is_active_member());

-- -----------------------------------------------------------------------------
-- 3. File des demandes — SUPER ADMIN uniquement
-- -----------------------------------------------------------------------------
create or replace function public.admin_list_registration_requests()
returns table (
  user_id uuid,
  username text,
  first_name text,
  email text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au Super Admin.';
  end if;

  return query
  select
    p.id,
    p.username::text,
    pp.first_name,
    u.email::text,
    p.status,
    p.created_at
  from public.profiles p
  left join public.profile_private pp on pp.user_id = p.id
  left join auth.users u on u.id = p.id
  where p.status in ('pending','rejected')
  order by
    case when p.status = 'pending' then 0 else 1 end,
    p.created_at asc;
end;
$$;

create or replace function public.admin_review_registration(
  p_user_id uuid,
  p_decision text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old public.profiles%rowtype;
  v_new_status text;
begin
  if not public.is_super_admin() then
    raise exception 'Réservé au Super Admin.';
  end if;

  v_new_status := case lower(trim(p_decision))
    when 'approve' then 'active'
    when 'active' then 'active'
    when 'reject' then 'rejected'
    when 'rejected' then 'rejected'
    else null
  end;

  if v_new_status is null then
    raise exception 'Décision invalide.';
  end if;

  select * into v_old from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'Compte introuvable.';
  end if;

  if v_old.role = 'super_admin' and v_new_status <> 'active' then
    raise exception 'Impossible de refuser le Super Admin principal.';
  end if;

  update public.profiles
  set status = v_new_status,
      updated_at = now()
  where id = p_user_id;

  insert into public.audit_logs(actor_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(),
    case when v_new_status = 'active' then 'registration_approved' else 'registration_rejected' end,
    'profile',
    p_user_id::text,
    jsonb_build_object('status', v_old.status, 'username', v_old.username::text),
    jsonb_build_object('status', v_new_status, 'username', v_old.username::text)
  );

  return v_new_status;
end;
$$;

revoke all on function public.admin_list_registration_requests() from public, anon;
revoke all on function public.admin_review_registration(uuid,text) from public, anon;
grant execute on function public.admin_list_registration_requests() to authenticated;
grant execute on function public.admin_review_registration(uuid,text) to authenticated;
grant execute on function public.is_active_member() to authenticated;

-- Version applicative
insert into public.app_settings(key,value)
values ('app_version','"0.1.1"'::jsonb)
on conflict (key) do update set value=excluded.value, updated_at=now();

commit;

-- ===== MIGRATION V0.1.2 =====
-- Le Nid des Champions — V0.1.2
-- Tous les comptes ACTIFS peuvent pronostiquer, quel que soit leur rôle.
-- Player / Admin / Super Admin jouent avec leur propre compte.
-- À exécuter dans Supabase > SQL Editor avec le rôle postgres / par défaut.

begin;

-- Les privilèges de table sont nécessaires, puis la RLS limite chaque utilisateur
-- à ses propres pronostics. Ceci ne donne AUCUN droit sur les profils/rôles.
grant select, insert, update on public.predictions to authenticated;

-- Réaffirme explicitement que le droit de jouer dépend du statut ACTIVE,
-- et non du rôle player/admin/super_admin.
drop policy if exists predictions_insert_own on public.predictions;
create policy predictions_insert_own on public.predictions
for insert to authenticated
with check (
  user_id = auth.uid()
  and public.is_active_member()
);

drop policy if exists predictions_update_own on public.predictions;
create policy predictions_update_own on public.predictions
for update to authenticated
using (
  user_id = auth.uid()
  and public.is_active_member()
)
with check (
  user_id = auth.uid()
  and public.is_active_member()
);

insert into public.app_settings(key, value)
values ('app_version', '"0.1.2"'::jsonb)
on conflict (key) do update set value = excluded.value, updated_at = now();

commit;

-- Vérification utile : ton compte doit apparaître ACTIVE, mais son rôle peut être
-- player, admin ou super_admin.
select id, username, role, status
from public.profiles
where id = auth.uid()
   or lower(username::text) = lower('Parkaf');

-- ===== MIGRATION V0.2.0 =====
-- Le Nid des Champions — V0.2.0
-- Phase de ligue & pronostics + synchronisation clubs/logos/calendrier.
-- À exécuter dans Supabase > SQL Editor avec le rôle postgres / par défaut.

begin;

-- -----------------------------------------------------------------------------
-- 1. Clubs enrichis pour les imports externes et les logos synchronisés
-- -----------------------------------------------------------------------------
alter table public.clubs add column if not exists tla text;
alter table public.clubs add column if not exists venue text;
alter table public.clubs add column if not exists external_provider text;
alter table public.clubs add column if not exists external_id bigint;
alter table public.clubs add column if not exists logo_source_url text;
alter table public.clubs add column if not exists logo_storage_path text;
alter table public.clubs add column if not exists logo_updated_at timestamptz;
alter table public.clubs add column if not exists updated_at timestamptz not null default now();

create unique index if not exists clubs_external_provider_id_uidx
  on public.clubs(external_provider, external_id);
create index if not exists clubs_tla_idx on public.clubs(tla);

drop trigger if exists clubs_updated_at on public.clubs;
create trigger clubs_updated_at before update on public.clubs
for each row execute function public.set_updated_at();

-- Le bucket est public en lecture. Les écritures sont effectuées par l'Edge Function
-- avec la service role, jamais par le navigateur.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('club-logos', 'club-logos', true, 2097152, array['image/png','image/webp','image/jpeg','image/svg+xml'])
on conflict (id) do update
set public = true,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- -----------------------------------------------------------------------------
-- 2. Matchs importables depuis une source externe
-- -----------------------------------------------------------------------------
alter table public.matches add column if not exists external_provider text;
alter table public.matches add column if not exists external_match_id bigint;
alter table public.matches add column if not exists external_stage text;

create unique index if not exists matches_external_provider_id_uidx
  on public.matches(external_provider, external_match_id);
create index if not exists matches_season_kickoff_idx on public.matches(season_id, kickoff_at);

-- Les admins peuvent désormais aussi créer/supprimer les matchs du calendrier.
drop policy if exists matches_admin_update on public.matches;
drop policy if exists matches_admin_all on public.matches;
create policy matches_admin_all on public.matches
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

grant select, insert, update, delete on public.matches to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Un match reporté reste pronostiquable si sa nouvelle date est dans le futur.
-- -----------------------------------------------------------------------------
create or replace function public.guard_prediction_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches%rowtype;
begin
  select * into v_match from public.matches where id = new.match_id;
  if not found then raise exception 'Match introuvable.'; end if;

  -- Le recalcul serveur des points reste autorisé après verrouillage s'il ne change
  -- ni l'auteur, ni le match, ni le score pronostiqué.
  if tg_op = 'UPDATE'
     and new.user_id = old.user_id
     and new.match_id = old.match_id
     and new.home_score = old.home_score
     and new.away_score = old.away_score then
    new.season_id := v_match.season_id;
    new.updated_at := now();
    return new;
  end if;

  if v_match.status not in ('scheduled','postponed') or v_match.kickoff_at <= now() then
    raise exception 'Pronostic verrouillé.';
  end if;

  new.season_id := v_match.season_id;
  new.points := 0;
  new.updated_at := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 4. Historique technique des modifications de pronostics
-- -----------------------------------------------------------------------------
create table if not exists public.prediction_history (
  id bigserial primary key,
  prediction_id uuid not null references public.predictions(id) on delete cascade,
  season_id uuid not null references public.seasons(id) on delete cascade,
  match_id uuid not null references public.matches(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  old_home_score integer,
  old_away_score integer,
  new_home_score integer not null,
  new_away_score integer not null,
  changed_at timestamptz not null default now()
);

create index if not exists prediction_history_user_idx
  on public.prediction_history(user_id, changed_at desc);
create index if not exists prediction_history_match_idx
  on public.prediction_history(match_id, changed_at desc);

create or replace function public.log_prediction_history()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.prediction_history(
      prediction_id, season_id, match_id, user_id,
      old_home_score, old_away_score, new_home_score, new_away_score
    ) values (
      new.id, new.season_id, new.match_id, new.user_id,
      null, null, new.home_score, new.away_score
    );
  elsif old.home_score is distinct from new.home_score
     or old.away_score is distinct from new.away_score then
    insert into public.prediction_history(
      prediction_id, season_id, match_id, user_id,
      old_home_score, old_away_score, new_home_score, new_away_score
    ) values (
      new.id, new.season_id, new.match_id, new.user_id,
      old.home_score, old.away_score, new.home_score, new.away_score
    );
  end if;
  return new;
end;
$$;

drop trigger if exists predictions_history_log on public.predictions;
create trigger predictions_history_log
after insert or update on public.predictions
for each row execute function public.log_prediction_history();

alter table public.prediction_history enable row level security;
drop policy if exists prediction_history_read on public.prediction_history;
create policy prediction_history_read on public.prediction_history
for select to authenticated
using (user_id = auth.uid() or public.is_admin());

grant select on public.prediction_history to authenticated;

-- -----------------------------------------------------------------------------
-- 5. Historique joueur prêt pour l'interface
-- -----------------------------------------------------------------------------
create or replace function public.get_my_prediction_history(p_season_id uuid)
returns table (
  match_id uuid,
  matchday_id uuid,
  matchday_number integer,
  matchday_name text,
  kickoff_at timestamptz,
  match_status text,
  home_name text,
  home_short text,
  home_logo_url text,
  away_name text,
  away_short text,
  away_logo_url text,
  prediction_home integer,
  prediction_away integer,
  result_home integer,
  result_away integer,
  points numeric,
  prediction_updated_at timestamptz,
  modification_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    m.id,
    md.id,
    md.number,
    md.name,
    m.kickoff_at,
    m.status,
    hc.name,
    hc.short_name,
    coalesce(
      case when hc.logo_storage_path is not null then
        (select value #>> '{}' from public.app_settings where key='club_logo_public_base') || '/' || hc.logo_storage_path
      end,
      hc.logo_url,
      hc.logo_source_url
    ) as home_logo_url,
    ac.name,
    ac.short_name,
    coalesce(
      case when ac.logo_storage_path is not null then
        (select value #>> '{}' from public.app_settings where key='club_logo_public_base') || '/' || ac.logo_storage_path
      end,
      ac.logo_url,
      ac.logo_source_url
    ) as away_logo_url,
    p.home_score,
    p.away_score,
    m.home_score,
    m.away_score,
    p.points,
    p.updated_at,
    coalesce((
      select count(*) from public.prediction_history ph
      where ph.prediction_id = p.id
    ),0) as modification_count
  from public.predictions p
  join public.matches m on m.id = p.match_id
  left join public.matchdays md on md.id = m.matchday_id
  join public.clubs hc on hc.id = m.home_club_id
  join public.clubs ac on ac.id = m.away_club_id
  where p.user_id = auth.uid()
    and p.season_id = p_season_id
  order by m.kickoff_at desc;
$$;

grant execute on function public.get_my_prediction_history(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Aides d'administration du calendrier
-- -----------------------------------------------------------------------------
create or replace function public.admin_set_match_state(
  p_match_id uuid,
  p_status text,
  p_home_score integer default null,
  p_away_score integer default null,
  p_kickoff_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Réservé aux administrateurs.';
  end if;

  if p_status not in ('scheduled','live','finished','postponed','cancelled') then
    raise exception 'Statut de match invalide.';
  end if;

  if p_status = 'finished' and (p_home_score is null or p_away_score is null) then
    raise exception 'Un résultat final doit contenir les deux scores.';
  end if;

  update public.matches
  set status = p_status,
      home_score = case when p_status='finished' then p_home_score else home_score end,
      away_score = case when p_status='finished' then p_away_score else away_score end,
      kickoff_at = coalesce(p_kickoff_at, kickoff_at),
      data_source = 'manual',
      updated_at = now()
  where id = p_match_id;
end;
$$;

grant execute on function public.admin_set_match_state(uuid,text,integer,integer,timestamptz) to authenticated;

-- -----------------------------------------------------------------------------
-- 7. Version et base publique des logos Storage
-- -----------------------------------------------------------------------------
insert into public.app_settings(key,value)
values
  ('app_version','"0.2.0"'::jsonb),
  ('club_logo_public_base','null'::jsonb)
on conflict (key) do update set value=excluded.value, updated_at=now();

-- L'interface construit l'URL publique Storage avec SUPABASE_URL. La clé reste
-- réservée à une éventuelle URL CDN personnalisée dans une future version.

commit;

-- Vérifications rapides
select key, value from public.app_settings where key in ('app_version','club_logo_public_base');
select column_name from information_schema.columns where table_schema='public' and table_name='clubs' order by ordinal_position;

-- ============================================================================
-- MIGRATION V0.3.0 — CLASSEMENTS & LIVE
-- ============================================================================

-- Le Nid des Champions — V0.3.0
-- Classements & Live : classements multi-portées, départages, variations,
-- scores Admin LIVE, statistiques collectives et Realtime.

begin;

create index if not exists matches_season_status_kickoff_idx
  on public.matches(season_id, status, kickoff_at);
create index if not exists predictions_season_match_idx
  on public.predictions(season_id, match_id, user_id);

-- -----------------------------------------------------------------------------
-- 1. Calcul de points provisoires sur un score courant (LIVE ou final)
-- -----------------------------------------------------------------------------
create or replace function public.score_prediction_values_v030(
  p_season_id uuid,
  p_prediction_home integer,
  p_prediction_away integer,
  p_result_home integer,
  p_result_away integer,
  p_multiplier numeric default 1
)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select case
    when p_result_home is null or p_result_away is null then 0::numeric
    when p_prediction_home = p_result_home and p_prediction_away = p_result_away
      then s.points_exact * coalesce(p_multiplier,1)
    when sign(p_prediction_home - p_prediction_away) = sign(p_result_home - p_result_away)
         and (p_prediction_home - p_prediction_away) = (p_result_home - p_result_away)
      then s.points_difference * coalesce(p_multiplier,1)
    when sign(p_prediction_home - p_prediction_away) = sign(p_result_home - p_result_away)
      then s.points_result * coalesce(p_multiplier,1)
    else s.points_wrong * coalesce(p_multiplier,1)
  end::numeric
  from public.seasons s
  where s.id = p_season_id;
$$;

grant execute on function public.score_prediction_values_v030(uuid,integer,integer,integer,integer,numeric) to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Classement V0.3.0
--    Départage : points > exacts > moyenne > bons écarts > pronostics joués.
--    Le rang est toujours unique (row_number).
--    En général, la variation compare au classement avant la soirée de référence.
-- -----------------------------------------------------------------------------
create or replace function public.get_leaderboard_v030(
  p_season_id uuid,
  p_scope text default 'general',
  p_matchday_id uuid default null,
  p_evening_date date default null,
  p_include_live boolean default true
)
returns table (
  rank bigint,
  previous_rank bigint,
  variation bigint,
  user_id uuid,
  username text,
  avatar_key text,
  club_heart text,
  points numeric,
  official_points numeric,
  exact_scores bigint,
  good_differences bigint,
  good_results bigint,
  played bigint,
  average numeric,
  precision_pct numeric,
  above_gap numeric,
  below_gap numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with params as (
    select coalesce(
      p_evening_date,
      (
        select max((m.kickoff_at at time zone 'Europe/Paris')::date)
        from public.matches m
        where m.season_id = p_season_id
          and m.status in ('live','finished')
      ),
      (now() at time zone 'Europe/Paris')::date
    ) as reference_date
  ),
  scope_matches as (
    select m.*
    from public.matches m, params pa
    where m.season_id = p_season_id
      and (
        p_scope = 'general'
        or (p_scope = 'matchday' and p_matchday_id is not null and m.matchday_id = p_matchday_id)
        or (p_scope = 'evening' and (m.kickoff_at at time zone 'Europe/Paris')::date = coalesce(p_evening_date, pa.reference_date))
      )
  ),
  stats as (
    select
      pr.id as user_id,
      pr.username::text as username,
      pr.avatar_key,
      pr.club_heart,
      coalesce(sum(
        case
          when m.id is null or p.id is null then 0
          when m.status = 'finished' then p.points
          when p_include_live and m.status = 'live' and m.home_score is not null and m.away_score is not null
            then public.score_prediction_values_v030(p_season_id,p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier)
          else 0
        end
      ),0)::numeric as points,
      coalesce(sum(case when m.status='finished' then p.points else 0 end),0)::numeric as official_points,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
          and p.home_score=m.home_score and p.away_score=m.away_score
      ) as exact_scores,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
          and not (p.home_score=m.home_score and p.away_score=m.away_score)
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
          and (p.home_score-p.away_score)=(m.home_score-m.away_score)
      ) as good_differences,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
      ) as good_results,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
      ) as played
    from public.profiles pr
    left join public.predictions p
      on p.user_id = pr.id and p.season_id = p_season_id
    left join scope_matches m on m.id = p.match_id
    where pr.status = 'active'
    group by pr.id,pr.username,pr.avatar_key,pr.club_heart
  ),
  scored as (
    select
      s.*,
      case when played>0 then points/played else 0 end::numeric as average,
      case when played>0 then round((good_results::numeric*100)/played,1) else 0 end::numeric as precision_pct
    from stats s
  ),
  current_ranked as (
    select
      row_number() over(
        order by points desc, exact_scores desc, average desc, good_differences desc, played desc, username asc
      ) as rank,
      *
    from scored
  ),
  baseline_stats as (
    select
      pr.id as user_id,
      pr.username::text as username,
      coalesce(sum(case when m.status='finished' then p.points else 0 end),0)::numeric as points,
      count(*) filter (
        where m.status='finished' and p.id is not null
          and p.home_score=m.home_score and p.away_score=m.away_score
      ) as exact_scores,
      count(*) filter (
        where m.status='finished' and p.id is not null
          and not (p.home_score=m.home_score and p.away_score=m.away_score)
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
          and (p.home_score-p.away_score)=(m.home_score-m.away_score)
      ) as good_differences,
      count(*) filter (where m.status='finished' and p.id is not null) as played
    from public.profiles pr
    left join public.predictions p
      on p.user_id=pr.id and p.season_id=p_season_id
    left join public.matches m
      on m.id=p.match_id
      and m.season_id=p_season_id
      and (m.kickoff_at at time zone 'Europe/Paris')::date < (select reference_date from params)
    where pr.status='active'
    group by pr.id,pr.username
  ),
  baseline_scored as (
    select *, case when played>0 then points/played else 0 end::numeric as average
    from baseline_stats
  ),
  baseline_ranked as (
    select user_id,
      row_number() over(
        order by points desc, exact_scores desc, average desc, good_differences desc, played desc, username asc
      ) as previous_rank
    from baseline_scored
  ),
  joined as (
    select
      c.*,
      case when p_scope='general' then b.previous_rank else null end as previous_rank
    from current_ranked c
    left join baseline_ranked b on b.user_id=c.user_id
  ),
  neighbors as (
    select
      j.*,
      lag(points) over(order by rank) as above_points,
      lead(points) over(order by rank) as below_points
    from joined j
  )
  select
    rank,
    previous_rank,
    case when previous_rank is null then 0 else previous_rank-rank end as variation,
    user_id,username,avatar_key,club_heart,
    points,official_points,exact_scores,good_differences,good_results,played,
    round(average,2) as average,
    precision_pct,
    case when above_points is null then null else above_points-points end as above_gap,
    case when below_points is null then null else points-below_points end as below_gap
  from neighbors
  order by rank;
$$;

grant execute on function public.get_leaderboard_v030(uuid,text,uuid,date,boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Statistiques collectives agrégées : aucune donnée privée n'est exposée.
-- -----------------------------------------------------------------------------
create or replace function public.get_collective_stats_v030(
  p_season_id uuid,
  p_scope text default 'general',
  p_matchday_id uuid default null,
  p_evening_date date default null
)
returns table (
  total_predictions bigint,
  home_picks bigint,
  draw_picks bigint,
  away_picks bigint,
  top_scores jsonb,
  exact_predictions bigint,
  settled_predictions bigint,
  reliability_pct numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with reference as (
    select coalesce(
      p_evening_date,
      (
        select max((m.kickoff_at at time zone 'Europe/Paris')::date)
        from public.matches m
        where m.season_id=p_season_id and m.status in ('live','finished')
      ),
      (now() at time zone 'Europe/Paris')::date
    ) as evening_date
  ),
  scoped_matches as (
    select m.*
    from public.matches m, reference r
    where m.season_id=p_season_id
      and (
        p_scope='general'
        or (p_scope='matchday' and p_matchday_id is not null and m.matchday_id=p_matchday_id)
        or (p_scope='evening' and (m.kickoff_at at time zone 'Europe/Paris')::date=coalesce(p_evening_date,r.evening_date))
      )
      and (m.status in ('live','finished') or (m.status in ('scheduled','postponed') and m.kickoff_at<=now()))
  ),
  locked_predictions as (
    select p.*,m.status,m.home_score as result_home,m.away_score as result_away
    from public.predictions p
    join scoped_matches m on m.id=p.match_id
    join public.profiles pr on pr.id=p.user_id and pr.status='active'
  ),
  score_counts as (
    select home_score,away_score,count(*)::bigint as n
    from locked_predictions
    group by home_score,away_score
    order by n desc,home_score asc,away_score asc
    limit 5
  ),
  aggregates as (
    select
      count(*)::bigint as total_predictions,
      count(*) filter(where home_score>away_score)::bigint as home_picks,
      count(*) filter(where home_score=away_score)::bigint as draw_picks,
      count(*) filter(where home_score<away_score)::bigint as away_picks,
      count(*) filter(
        where status in ('live','finished') and result_home is not null and result_away is not null
          and home_score=result_home and away_score=result_away
      )::bigint as exact_predictions,
      count(*) filter(
        where status in ('live','finished') and result_home is not null and result_away is not null
      )::bigint as settled_predictions,
      count(*) filter(
        where status in ('live','finished') and result_home is not null and result_away is not null
          and sign(home_score-away_score)=sign(result_home-result_away)
      )::bigint as correct_results
    from locked_predictions
  )
  select
    a.total_predictions,a.home_picks,a.draw_picks,a.away_picks,
    coalesce((select jsonb_agg(jsonb_build_object('score',home_score::text || '–' || away_score::text,'count',n) order by n desc,home_score,away_score) from score_counts),'[]'::jsonb) as top_scores,
    a.exact_predictions,a.settled_predictions,
    case when a.settled_predictions>0 then round((a.correct_results::numeric*100)/a.settled_predictions,1) else 0 end::numeric as reliability_pct
  from aggregates a;
$$;

grant execute on function public.get_collective_stats_v030(uuid,text,uuid,date) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. Révélation des pronostics adverses seulement après verrouillage.
-- -----------------------------------------------------------------------------
create or replace function public.get_match_predictions_v030(p_match_id uuid)
returns table (
  user_id uuid,
  username text,
  avatar_key text,
  prediction_home integer,
  prediction_away integer,
  current_points numeric,
  is_me boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_match public.matches%rowtype;
begin
  select * into v_match from public.matches where id=p_match_id;
  if not found then raise exception 'Match introuvable.'; end if;

  if v_match.status in ('scheduled','postponed') and v_match.kickoff_at>now() then
    raise exception 'Les pronostics du Nid restent cachés avant le verrouillage.';
  end if;

  return query
  select
    pr.id,
    pr.username::text,
    pr.avatar_key,
    p.home_score,
    p.away_score,
    case
      when v_match.status='finished' then p.points
      when v_match.status='live' and v_match.home_score is not null and v_match.away_score is not null
        then public.score_prediction_values_v030(v_match.season_id,p.home_score,p.away_score,v_match.home_score,v_match.away_score,v_match.points_multiplier)
      else 0::numeric
    end,
    pr.id=auth.uid()
  from public.predictions p
  join public.profiles pr on pr.id=p.user_id and pr.status='active'
  where p.match_id=p_match_id
  order by p.home_score,p.away_score,pr.username;
end;
$$;

grant execute on function public.get_match_predictions_v030(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 5. Saisie Admin LIVE : le score courant est conservé pendant le match.
-- -----------------------------------------------------------------------------
create or replace function public.admin_set_match_state(
  p_match_id uuid,
  p_status text,
  p_home_score integer default null,
  p_away_score integer default null,
  p_kickoff_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Réservé aux administrateurs.';
  end if;

  if p_status not in ('scheduled','live','finished','postponed','cancelled') then
    raise exception 'Statut de match invalide.';
  end if;

  if p_status in ('live','finished') and (p_home_score is null or p_away_score is null) then
    raise exception 'Le score LIVE/final doit contenir les deux valeurs.';
  end if;

  if coalesce(p_home_score,0)<0 or coalesce(p_away_score,0)<0 then
    raise exception 'Un score ne peut pas être négatif.';
  end if;

  update public.matches
  set status=p_status,
      home_score=case
        when p_status in ('live','finished') then p_home_score
        when p_status='scheduled' then null
        else home_score
      end,
      away_score=case
        when p_status in ('live','finished') then p_away_score
        when p_status='scheduled' then null
        else away_score
      end,
      kickoff_at=coalesce(p_kickoff_at,kickoff_at),
      data_source='manual',
      updated_at=now()
  where id=p_match_id;
end;
$$;

grant execute on function public.admin_set_match_state(uuid,text,integer,integer,timestamptz) to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Realtime : matches + predictions doivent appartenir à la publication.
-- -----------------------------------------------------------------------------
do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='matches') then
      execute 'alter publication supabase_realtime add table public.matches';
    end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='predictions') then
      execute 'alter publication supabase_realtime add table public.predictions';
    end if;
  end if;
end $$;

insert into public.app_settings(key,value)
values ('app_version','"0.3.0"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

commit;

-- Vérifications rapides
select key,value from public.app_settings where key='app_version';
select proname from pg_proc where proname in ('get_leaderboard_v030','get_collective_stats_v030','get_match_predictions_v030','score_prediction_values_v030');


-- =============================================================================
-- MIGRATION V0.3.1 — LOGOS TEST & NAVIGATION
-- =============================================================================

-- Le Nid des Champions — V0.3.1
-- Correctifs : rattachement des clubs TEST aux clubs Football-Data + version.
-- La navigation automatique A -> B -> match suivant est côté client (assets/js/app.js).

begin;

-- Les 8 clubs de la Journée TEST existaient avant l'import Football-Data.
-- Quand le club canonique importé existe, on rattache tous les matchs à ce club
-- puis on masque l'ancien doublon. Les pronostics ne sont pas touchés : ils sont
-- liés aux matchs, pas aux clubs.
do $$
declare
  r record;
  v_legacy uuid;
  v_canonical uuid;
begin
  for r in
    select *
    from (values
      ('Paris SG'::text,       524::bigint),
      ('Bayern Munich'::text,    5::bigint),
      ('Real Madrid'::text,      86::bigint),
      ('Arsenal'::text,          57::bigint),
      ('Inter Milan'::text,     108::bigint),
      ('FC Barcelone'::text,     81::bigint),
      ('Liverpool'::text,        64::bigint),
      ('Dortmund'::text,          4::bigint)
    ) as legacy(legacy_name, external_id)
  loop
    v_legacy := null;
    v_canonical := null;

    select c.id
      into v_canonical
    from public.clubs c
    where c.external_provider = 'football-data'
      and c.external_id = r.external_id
    limit 1;

    if v_canonical is null then
      continue;
    end if;

    select c.id
      into v_legacy
    from public.clubs c
    where c.name = r.legacy_name
      and c.id <> v_canonical
    limit 1;

    if v_legacy is null then
      continue;
    end if;

    update public.matches
       set home_club_id = v_canonical,
           updated_at = now()
     where home_club_id = v_legacy;

    update public.matches
       set away_club_id = v_canonical,
           updated_at = now()
     where away_club_id = v_legacy;

    update public.clubs
       set is_active = false,
           updated_at = now()
     where id = v_legacy;
  end loop;
end $$;

insert into public.app_settings(key,value)
values ('app_version','"0.3.1"'::jsonb)
on conflict (key) do update
set value=excluded.value, updated_at=now();

commit;

-- Contrôle lisible dans le SQL Editor : après synchronisation Football-Data,
-- les 8 lignes suivantes doivent pointer vers external_provider='football-data'.
select
  c.name,
  c.short_name,
  c.external_provider,
  c.external_id,
  coalesce(c.logo_storage_path, c.logo_source_url, c.logo_url) as logo
from public.clubs c
where c.external_provider='football-data'
  and c.external_id in (524,5,86,57,108,81,64,4)
order by c.name;


-- MIGRATION V0.3.2 — COTES 1N2
-- Le Nid des Champions — V0.3.2
-- Cotes 1N2 : stockage des cotes pré-match et de leur provenance.

begin;

alter table public.matches add column if not exists odds_home numeric(10,3);
alter table public.matches add column if not exists odds_draw numeric(10,3);
alter table public.matches add column if not exists odds_away numeric(10,3);
alter table public.matches add column if not exists odds_provider text;
alter table public.matches add column if not exists odds_bookmaker text;
alter table public.matches add column if not exists odds_source_season text;
alter table public.matches add column if not exists odds_is_test_shifted boolean not null default false;
alter table public.matches add column if not exists odds_updated_at timestamptz;

comment on column public.matches.odds_home is 'Cote décimale pré-match pour la victoire domicile (1).';
comment on column public.matches.odds_draw is 'Cote décimale pré-match pour le match nul (N).';
comment on column public.matches.odds_away is 'Cote décimale pré-match pour la victoire extérieure (2).';
comment on column public.matches.odds_provider is 'Fournisseur technique de la cote (Football-Data ou source externe configurée).';
comment on column public.matches.odds_bookmaker is 'Bookmaker ou libellé de source utilisé pour le triplet 1N2.';
comment on column public.matches.odds_source_season is 'Saison réelle de provenance quand la saison de test est transposée.';
comment on column public.matches.odds_is_test_shifted is 'Vrai si les cotes proviennent d une saison source transposée dans le calendrier de test.';
comment on column public.matches.odds_updated_at is 'Dernière actualisation de la cote affichée.';

insert into public.app_settings(key,value)
values ('app_version','"0.3.2"'::jsonb)
on conflict (key) do update
set value=excluded.value, updated_at=now();

commit;

select
  count(*) filter (where odds_home is not null and odds_draw is not null and odds_away is not null) as matches_with_odds,
  count(*) as total_matches
from public.matches;

-- Le Nid des Champions — V0.3.3
-- Navigation A/B bidirectionnelle (front) + bibliothèque indépendante de clubs/logos.

begin;

create table if not exists public.club_catalog_memberships (
  club_id uuid not null references public.clubs(id) on delete cascade,
  competition_code text not null,
  competition_name text not null,
  country text,
  season_year integer not null,
  updated_at timestamptz not null default now(),
  primary key (club_id, competition_code, season_year)
);

create index if not exists club_catalog_memberships_competition_idx
  on public.club_catalog_memberships(competition_code, season_year);

alter table public.club_catalog_memberships enable row level security;

drop policy if exists club_catalog_memberships_read on public.club_catalog_memberships;
create policy club_catalog_memberships_read
on public.club_catalog_memberships
for select
to authenticated
using (true);

grant select on public.club_catalog_memberships to authenticated;

-- Rattrapage : les clubs déjà utilisés par les matchs Football-Data C1 de la base
-- deviennent immédiatement visibles dans le filtre Champions League, sans attendre
-- une nouvelle synchronisation.
with cl_ids as (
  select m.home_club_id as club_id
  from public.matches m
  where m.external_provider = 'football-data'
  union
  select m.away_club_id as club_id
  from public.matches m
  where m.external_provider = 'football-data'
)
insert into public.club_catalog_memberships(club_id,competition_code,competition_name,country,season_year,updated_at)
select c.id,'CL','UEFA Champions League',c.country,2025,now()
from cl_ids x
join public.clubs c on c.id=x.club_id
on conflict (club_id,competition_code,season_year) do update
set competition_name=excluded.competition_name,
    country=excluded.country,
    updated_at=now();

insert into public.app_settings(key,value)
values ('app_version','"0.3.3"'::jsonb)
on conflict (key) do update
set value=excluded.value, updated_at=now();

commit;

select
  competition_code,
  competition_name,
  season_year,
  count(*) as clubs
from public.club_catalog_memberships
group by competition_code,competition_name,season_year
order by competition_code,season_year desc;
-- Le Nid des Champions — HOTFIX V0.3.4
-- La correction principale est dans l'Edge Function sync-football-data.
-- Après redéploiement, relancer « Bibliothèque Top 5 + logos ».

begin;
insert into public.app_settings(key,value)
values ('app_version','"0.3.4"'::jsonb)
on conflict (key) do update
set value=excluded.value, updated_at=now();
commit;

-- Diagnostic des appartenances Top 5 actuellement stockées.
select competition_code, competition_name, count(*) as clubs
from public.club_catalog_memberships
where competition_code in ('FL1','PL','PD','SA','BL1')
group by competition_code,competition_name
order by competition_code;

-- Détecte les mêmes lignes club utilisées dans plusieurs championnats nationaux.
-- Après la resynchronisation V0.3.4, cette requête doit normalement retourner 0 ligne.
select c.id,c.name,c.tla,c.external_provider,c.external_id,
       array_agg(m.competition_code order by m.competition_code) as competitions
from public.clubs c
join public.club_catalog_memberships m on m.club_id=c.id
where m.competition_code in ('FL1','PL','PD','SA','BL1')
group by c.id,c.name,c.tla,c.external_provider,c.external_id
having count(distinct m.competition_code) > 1
order by c.name;
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

-- ============================================================================
-- V0.5.0 — Teams
-- ============================================================================
-- Le Nid des Champions — V0.5.0 Teams
-- À exécuter après V0.4.2 avec le rôle postgres dans Supabase SQL Editor.
-- Teams publiques/privées, capitaine unique, identité visuelle, historique, classements et Realtime.

begin;

-- =============================================================================
-- 1. Tables Teams
-- =============================================================================
create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  name text not null,
  slug text not null,
  slogan text,
  description text,
  favorite_club_id uuid references public.clubs(id) on delete set null,
  visibility text not null default 'public' check (visibility in ('public','private')),
  status text not null default 'active' check (status in ('active','dissolved')),
  captain_user_id uuid not null references public.profiles(id) on delete restrict,
  logo_type text not null default 'library' check (logo_type in ('library','upload')),
  logo_asset_key text,
  logo_url text,
  shape text not null default 'shield-classic',
  frame_style text not null default 'champions',
  primary_color text not null default '#315cff',
  secondary_color text not null default '#7454ff',
  background_style text not null default 'diagonal' check (background_style in ('solid','vertical','horizontal','diagonal','radial','halo')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  dissolved_at timestamptz,
  check (char_length(trim(name)) between 3 and 30),
  check (slogan is null or char_length(slogan) <= 80),
  check (description is null or char_length(description) <= 160)
);

create unique index if not exists teams_active_name_unique_idx on public.teams(season_id,lower(name)) where status='active';
create index if not exists teams_season_status_idx on public.teams(season_id,status,name);
create index if not exists teams_captain_idx on public.teams(captain_user_id,status);

drop trigger if exists teams_updated_at on public.teams;
create trigger teams_updated_at before update on public.teams
for each row execute function public.set_updated_at();

create table if not exists public.team_memberships (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  join_type text not null default 'public' check (join_type in ('creator','public','request','code','admin')),
  leave_type text check (leave_type in ('left','kicked','dissolved','admin')),
  created_at timestamptz not null default now(),
  check (left_at is null or left_at >= joined_at)
);
create unique index if not exists team_memberships_one_active_team_idx on public.team_memberships(season_id,user_id) where left_at is null;
create index if not exists team_memberships_team_active_idx on public.team_memberships(team_id,left_at,user_id);
create index if not exists team_memberships_history_idx on public.team_memberships(season_id,user_id,joined_at,left_at);

create table if not exists public.team_join_requests (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','rejected','cancelled')),
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  processed_by uuid references public.profiles(id) on delete set null
);
create unique index if not exists team_join_requests_one_pending_idx on public.team_join_requests(team_id,user_id) where status='pending';
create index if not exists team_join_requests_team_idx on public.team_join_requests(team_id,status,requested_at desc);

create table if not exists public.team_invites (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  code text not null unique,
  active boolean not null default true,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz
);
create index if not exists team_invites_active_idx on public.team_invites(team_id,active,created_at desc);

create table if not exists public.team_events (
  id bigint generated always as identity primary key,
  season_id uuid not null references public.seasons(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  target_user_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists team_events_team_idx on public.team_events(team_id,created_at desc);

-- =============================================================================
-- 2. Stockage des logos uploadés
-- =============================================================================
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('team-logos','team-logos',true,3145728,array['image/png','image/jpeg','image/webp','image/svg+xml'])
on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists team_logos_public_read on storage.objects;
create policy team_logos_public_read on storage.objects for select using (bucket_id='team-logos');

drop policy if exists team_logos_own_insert on storage.objects;
create policy team_logos_own_insert on storage.objects for insert to authenticated
with check (bucket_id='team-logos' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists team_logos_own_update on storage.objects;
create policy team_logos_own_update on storage.objects for update to authenticated
using (bucket_id='team-logos' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()))
with check (bucket_id='team-logos' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));

drop policy if exists team_logos_own_delete on storage.objects;
create policy team_logos_own_delete on storage.objects for delete to authenticated
using (bucket_id='team-logos' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));

-- =============================================================================
-- 3. Helpers
-- =============================================================================
create or replace function public.slugify_team_v050(p_value text)
returns text language sql immutable as $$
  select trim(both '-' from regexp_replace(lower(coalesce(p_value,'')),'[^a-z0-9]+','-','g'));
$$;

create or replace function public.is_team_captain_v050(p_team_id uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.teams t
    where t.id=p_team_id and t.status='active' and t.captain_user_id=auth.uid()
  );
$$;

create or replace function public.current_team_id_v050(p_season_id uuid,p_user_id uuid default null)
returns uuid language sql stable security definer set search_path=public as $$
  select tm.team_id
  from public.team_memberships tm
  join public.teams t on t.id=tm.team_id and t.status='active'
  where tm.season_id=p_season_id and tm.user_id=coalesce(p_user_id,auth.uid()) and tm.left_at is null
  order by tm.joined_at desc limit 1;
$$;

create or replace function public.log_team_event_v050(
  p_team_id uuid,p_event_type text,p_target_user_id uuid default null,p_payload jsonb default '{}'::jsonb,p_actor_id uuid default null
)
returns void language plpgsql security definer set search_path=public as $$
declare v_season uuid;
begin
  select season_id into v_season from public.teams where id=p_team_id;
  if v_season is null then return; end if;
  insert into public.team_events(season_id,team_id,actor_id,target_user_id,event_type,payload)
  values(v_season,p_team_id,coalesce(p_actor_id,auth.uid()),p_target_user_id,p_event_type,coalesce(p_payload,'{}'::jsonb));
end;
$$;

-- =============================================================================
-- 4. Création / modification
-- =============================================================================
create or replace function public.create_team_v050(
  p_season_id uuid,
  p_name text,
  p_slogan text,
  p_description text,
  p_favorite_club_id uuid,
  p_visibility text,
  p_logo_type text,
  p_logo_asset_key text,
  p_logo_url text,
  p_shape text,
  p_frame_style text,
  p_primary_color text,
  p_secondary_color text,
  p_background_style text
)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;v_name text:=trim(p_name);v_slug text;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=auth.uid() and status='active') then raise exception 'Compte inactif.'; end if;
  if exists(select 1 from public.team_memberships where season_id=p_season_id and user_id=auth.uid() and left_at is null) then raise exception 'Tu appartiens déjà à une Team.'; end if;
  if char_length(v_name) not between 3 and 30 then raise exception 'Le nom doit contenir entre 3 et 30 caractères.'; end if;
  if coalesce(char_length(p_slogan),0)>80 then raise exception 'Slogan trop long.'; end if;
  if coalesce(char_length(p_description),0)>160 then raise exception 'Description trop longue.'; end if;
  if p_visibility not in ('public','private') then raise exception 'Visibilité invalide.'; end if;
  if p_background_style not in ('solid','vertical','horizontal','diagonal','radial','halo') then raise exception 'Fond invalide.'; end if;
  if p_logo_type not in ('library','upload') then raise exception 'Type de logo invalide.'; end if;
  v_slug:=public.slugify_team_v050(v_name)||'-'||substr(replace(gen_random_uuid()::text,'-',''),1,6);

  insert into public.teams(season_id,name,slug,slogan,description,favorite_club_id,visibility,captain_user_id,logo_type,logo_asset_key,logo_url,shape,frame_style,primary_color,secondary_color,background_style)
  values(p_season_id,v_name,v_slug,nullif(trim(p_slogan),''),nullif(trim(p_description),''),p_favorite_club_id,p_visibility,auth.uid(),p_logo_type,nullif(p_logo_asset_key,''),nullif(p_logo_url,''),coalesce(nullif(p_shape,''),'shield-classic'),coalesce(nullif(p_frame_style,''),'champions'),coalesce(nullif(p_primary_color,''),'#315cff'),coalesce(nullif(p_secondary_color,''),'#7454ff'),p_background_style)
  returning id into v_id;

  insert into public.team_memberships(season_id,team_id,user_id,join_type) values(p_season_id,v_id,auth.uid(),'creator');
  perform public.log_team_event_v050(v_id,'team_created',auth.uid(),jsonb_build_object('name',v_name),auth.uid());
  return v_id;
exception when unique_violation then
  raise exception 'Ce nom de Team est déjà utilisé pour cette saison.';
end;
$$;

create or replace function public.update_team_v050(
  p_team_id uuid,
  p_name text,
  p_slogan text,
  p_description text,
  p_favorite_club_id uuid,
  p_visibility text,
  p_logo_type text,
  p_logo_asset_key text,
  p_logo_url text,
  p_shape text,
  p_frame_style text,
  p_primary_color text,
  p_secondary_color text,
  p_background_style text
)
returns void language plpgsql security definer set search_path=public as $$
declare old_row public.teams%rowtype;v_name text:=trim(p_name);
begin
  select * into old_row from public.teams where id=p_team_id for update;
  if not found then raise exception 'Team introuvable.'; end if;
  if old_row.status<>'active' then raise exception 'Cette Team est dissoute.'; end if;
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if char_length(v_name) not between 3 and 30 then raise exception 'Le nom doit contenir entre 3 et 30 caractères.'; end if;
  if coalesce(char_length(p_slogan),0)>80 then raise exception 'Slogan trop long.'; end if;
  if coalesce(char_length(p_description),0)>160 then raise exception 'Description trop longue.'; end if;
  if p_visibility not in ('public','private') then raise exception 'Visibilité invalide.'; end if;
  if p_logo_type not in ('library','upload') then raise exception 'Type de logo invalide.'; end if;

  update public.teams set
    name=v_name,
    slogan=nullif(trim(p_slogan),''),
    description=nullif(trim(p_description),''),
    favorite_club_id=p_favorite_club_id,
    visibility=p_visibility,
    logo_type=p_logo_type,
    logo_asset_key=nullif(p_logo_asset_key,''),
    logo_url=nullif(p_logo_url,''),
    shape=coalesce(nullif(p_shape,''),shape),
    frame_style=coalesce(nullif(p_frame_style,''),frame_style),
    primary_color=coalesce(nullif(p_primary_color,''),primary_color),
    secondary_color=coalesce(nullif(p_secondary_color,''),secondary_color),
    background_style=coalesce(nullif(p_background_style,''),background_style)
  where id=p_team_id;

  perform public.log_team_event_v050(p_team_id,'identity_changed',null,jsonb_build_object(
    'old_name',old_row.name,'new_name',v_name,'visibility',p_visibility,'favorite_club_id',p_favorite_club_id,
    'shape',p_shape,'frame_style',p_frame_style,'primary_color',p_primary_color,'secondary_color',p_secondary_color,'background_style',p_background_style
  ));
exception when unique_violation then
  raise exception 'Ce nom de Team est déjà utilisé pour cette saison.';
end;
$$;

-- =============================================================================
-- 5. Adhésions
-- =============================================================================
create or replace function public.join_public_team_v050(p_team_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;
begin
  select * into t from public.teams where id=p_team_id for update;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;
  if t.visibility<>'public' then raise exception 'Cette Team est privée.'; end if;
  if exists(select 1 from public.team_memberships where season_id=t.season_id and user_id=auth.uid() and left_at is null) then raise exception 'Tu appartiens déjà à une Team.'; end if;
  insert into public.team_memberships(season_id,team_id,user_id,join_type) values(t.season_id,t.id,auth.uid(),'public');
  update public.team_join_requests set status='cancelled',processed_at=now(),processed_by=auth.uid() where season_id=t.season_id and user_id=auth.uid() and status='pending';
  perform public.log_team_event_v050(t.id,'member_joined',auth.uid(),jsonb_build_object('join_type','public'));
end;
$$;

create or replace function public.request_team_join_v050(p_team_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;v_id uuid;
begin
  select * into t from public.teams where id=p_team_id;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;
  if t.visibility<>'private' then raise exception 'Cette Team est publique : rejoins-la directement.'; end if;
  if exists(select 1 from public.team_memberships where season_id=t.season_id and user_id=auth.uid() and left_at is null) then raise exception 'Tu appartiens déjà à une Team.'; end if;
  select id into v_id from public.team_join_requests where team_id=t.id and user_id=auth.uid() and status='pending' limit 1;
  if v_id is not null then return v_id; end if;
  insert into public.team_join_requests(season_id,team_id,user_id,status) values(t.season_id,t.id,auth.uid(),'pending') returning id into v_id;
  perform public.log_team_event_v050(t.id,'join_requested',auth.uid(),jsonb_build_object('request_id',v_id));
  return v_id;
end;
$$;

create or replace function public.process_team_join_request_v050(p_request_id uuid,p_accept boolean)
returns void language plpgsql security definer set search_path=public as $$
declare r public.team_join_requests%rowtype;t public.teams%rowtype;
begin
  select * into r from public.team_join_requests where id=p_request_id for update;
  if not found or r.status<>'pending' then raise exception 'Demande introuvable ou déjà traitée.'; end if;
  select * into t from public.teams where id=r.team_id;
  if not (public.is_team_captain_v050(t.id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if p_accept then
    if exists(select 1 from public.team_memberships where season_id=t.season_id and user_id=r.user_id and left_at is null) then raise exception 'Ce joueur appartient déjà à une Team.'; end if;
    insert into public.team_memberships(season_id,team_id,user_id,join_type) values(t.season_id,t.id,r.user_id,'request');
    update public.team_join_requests set status='accepted',processed_at=now(),processed_by=auth.uid() where id=r.id;
    perform public.log_team_event_v050(t.id,'member_joined',r.user_id,jsonb_build_object('join_type','request'));
  else
    update public.team_join_requests set status='rejected',processed_at=now(),processed_by=auth.uid() where id=r.id;
    perform public.log_team_event_v050(t.id,'join_rejected',r.user_id,jsonb_build_object('request_id',r.id));
  end if;
end;
$$;

create or replace function public.regenerate_team_invite_v050(p_team_id uuid)
returns text language plpgsql security definer set search_path=public as $$
declare v_code text;
begin
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if not exists(select 1 from public.teams where id=p_team_id and status='active') then raise exception 'Team introuvable.'; end if;
  update public.team_invites set active=false where team_id=p_team_id and active=true;
  v_code:='NID-'||upper(substr(encode(gen_random_bytes(6),'hex'),1,8));
  insert into public.team_invites(team_id,code,created_by) values(p_team_id,v_code,auth.uid());
  perform public.log_team_event_v050(p_team_id,'invite_regenerated',null,'{}'::jsonb);
  return v_code;
end;
$$;

create or replace function public.join_team_by_code_v050(p_season_id uuid,p_code text)
returns uuid language plpgsql security definer set search_path=public as $$
declare i public.team_invites%rowtype;t public.teams%rowtype;
begin
  select * into i from public.team_invites where upper(code)=upper(trim(p_code)) and active=true and (expires_at is null or expires_at>now()) order by created_at desc limit 1;
  if not found then raise exception 'Code d’invitation invalide ou expiré.'; end if;
  select * into t from public.teams where id=i.team_id and season_id=p_season_id and status='active';
  if not found then raise exception 'Team indisponible.'; end if;
  if exists(select 1 from public.team_memberships where season_id=p_season_id and user_id=auth.uid() and left_at is null) then raise exception 'Tu appartiens déjà à une Team.'; end if;
  insert into public.team_memberships(season_id,team_id,user_id,join_type) values(p_season_id,t.id,auth.uid(),'code');
  update public.team_join_requests set status='cancelled',processed_at=now(),processed_by=auth.uid() where season_id=p_season_id and user_id=auth.uid() and status='pending';
  perform public.log_team_event_v050(t.id,'member_joined',auth.uid(),jsonb_build_object('join_type','code'));
  return t.id;
end;
$$;

create or replace function public.leave_team_v050(p_season_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare tm public.team_memberships%rowtype;t public.teams%rowtype;
begin
  select * into tm from public.team_memberships where season_id=p_season_id and user_id=auth.uid() and left_at is null for update;
  if not found then raise exception 'Tu n’appartiens à aucune Team.'; end if;
  select * into t from public.teams where id=tm.team_id;
  if t.captain_user_id=auth.uid() then raise exception 'Transfère d’abord le capitanat avant de quitter la Team.'; end if;
  update public.team_memberships set left_at=now(),leave_type='left' where id=tm.id;
  perform public.log_team_event_v050(t.id,'member_left',auth.uid(),'{}'::jsonb);
end;
$$;

create or replace function public.kick_team_member_v050(p_team_id uuid,p_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;tm_id uuid;
begin
  select * into t from public.teams where id=p_team_id;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if t.captain_user_id=p_user_id then raise exception 'Le capitaine ne peut pas être exclu.'; end if;
  select id into tm_id from public.team_memberships where team_id=p_team_id and user_id=p_user_id and left_at is null for update;
  if tm_id is null then raise exception 'Ce joueur n’est pas membre de la Team.'; end if;
  update public.team_memberships set left_at=now(),leave_type='kicked' where id=tm_id;
  perform public.log_team_event_v050(p_team_id,'member_kicked',p_user_id,'{}'::jsonb);
end;
$$;

create or replace function public.transfer_team_captain_v050(p_team_id uuid,p_new_captain_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;v_old uuid;
begin
  select * into t from public.teams where id=p_team_id for update;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;
  if not (t.captain_user_id=auth.uid() or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if not exists(select 1 from public.team_memberships where team_id=p_team_id and user_id=p_new_captain_user_id and left_at is null) then raise exception 'Le nouveau capitaine doit être membre actif.'; end if;
  v_old:=t.captain_user_id;
  if v_old=p_new_captain_user_id then return; end if;
  update public.teams set captain_user_id=p_new_captain_user_id where id=p_team_id;
  perform public.log_team_event_v050(p_team_id,'captain_transferred',p_new_captain_user_id,jsonb_build_object('old_captain_user_id',v_old,'new_captain_user_id',p_new_captain_user_id));
end;
$$;

create or replace function public.dissolve_team_v050(p_team_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;
begin
  select * into t from public.teams where id=p_team_id for update;
  if not found then raise exception 'Team introuvable.'; end if;
  if not (t.captain_user_id=auth.uid() or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if t.status='dissolved' then return; end if;
  perform public.log_team_event_v050(p_team_id,'team_dissolved',null,jsonb_build_object('name',t.name));
  update public.teams set status='dissolved',dissolved_at=now() where id=p_team_id;
  update public.team_memberships set left_at=now(),leave_type='dissolved' where team_id=p_team_id and left_at is null;
  update public.team_invites set active=false where team_id=p_team_id and active=true;
  update public.team_join_requests set status='cancelled',processed_at=now(),processed_by=auth.uid() where team_id=p_team_id and status='pending';
end;
$$;

-- =============================================================================
-- 6. Lecture / annuaire / membres / historique
-- =============================================================================
create or replace function public.get_team_directory_v050(p_season_id uuid)
returns table(
  team_id uuid,name text,slug text,slogan text,description text,visibility text,status text,captain_user_id uuid,captain_username text,
  favorite_club_id uuid,favorite_club_name text,favorite_club_short text,favorite_club_logo_url text,favorite_club_logo_storage_path text,
  logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  member_count bigint,created_at timestamptz
)
language sql stable security definer set search_path=public as $$
  select t.id,t.name,t.slug,t.slogan,t.description,t.visibility,t.status,t.captain_user_id,p.username::text,
    c.id,c.name,c.short_name,coalesce(c.logo_source_url,c.logo_url),c.logo_storage_path,
    t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    count(tm.id) filter(where tm.left_at is null)::bigint,t.created_at
  from public.teams t
  join public.profiles p on p.id=t.captain_user_id
  left join public.clubs c on c.id=t.favorite_club_id
  left join public.team_memberships tm on tm.team_id=t.id
  where t.season_id=p_season_id
  group by t.id,p.username,c.id,c.name,c.short_name,c.logo_source_url,c.logo_url,c.logo_storage_path
  order by (t.status='active') desc,t.name;
$$;

create or replace function public.get_my_team_v050(p_season_id uuid)
returns table(
  team_id uuid,name text,slug text,slogan text,description text,visibility text,status text,captain_user_id uuid,captain_username text,is_captain boolean,
  favorite_club_id uuid,favorite_club_name text,favorite_club_short text,favorite_club_logo_url text,favorite_club_logo_storage_path text,
  logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  joined_at timestamptz,member_count bigint
)
language sql stable security definer set search_path=public as $$
  select t.id,t.name,t.slug,t.slogan,t.description,t.visibility,t.status,t.captain_user_id,cap.username::text,(t.captain_user_id=auth.uid()),
    c.id,c.name,c.short_name,coalesce(c.logo_source_url,c.logo_url),c.logo_storage_path,
    t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    mine.joined_at,(select count(*) from public.team_memberships x where x.team_id=t.id and x.left_at is null)::bigint
  from public.team_memberships mine
  join public.teams t on t.id=mine.team_id
  join public.profiles cap on cap.id=t.captain_user_id
  left join public.clubs c on c.id=t.favorite_club_id
  where mine.season_id=p_season_id and mine.user_id=auth.uid() and mine.left_at is null and t.status='active'
  order by mine.joined_at desc limit 1;
$$;

create or replace function public.get_team_member_directory_v050(p_season_id uuid)
returns table(
  user_id uuid,username text,avatar_key text,club_heart text,team_id uuid,team_name text,is_captain boolean,
  logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text
)
language sql stable security definer set search_path=public as $$
  select p.id,p.username::text,p.avatar_key,p.club_heart,t.id,t.name,(t.captain_user_id=p.id),
    t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style
  from public.team_memberships tm
  join public.teams t on t.id=tm.team_id and t.status='active'
  join public.profiles p on p.id=tm.user_id
  where tm.season_id=p_season_id and tm.left_at is null
  order by t.name,p.username;
$$;

create or replace function public.get_team_members_v050(p_team_id uuid)
returns table(user_id uuid,username text,avatar_key text,club_heart text,is_captain boolean,joined_at timestamptz,points numeric,exact_scores bigint,average numeric,rank bigint)
language sql stable security definer set search_path=public as $$
  with t as (select season_id,captain_user_id from public.teams where id=p_team_id),
  lb as (select * from public.get_leaderboard_v040((select season_id from t),'general',null,null,true))
  select p.id,p.username::text,p.avatar_key,p.club_heart,(p.id=(select captain_user_id from t)),tm.joined_at,
    coalesce(lb.points,0),coalesce(lb.exact_scores,0),coalesce(lb.average,0),lb.rank
  from public.team_memberships tm
  join public.profiles p on p.id=tm.user_id
  left join lb on lb.user_id=p.id
  where tm.team_id=p_team_id and tm.left_at is null
  order by (p.id=(select captain_user_id from t)) desc,coalesce(lb.points,0) desc,p.username;
$$;

create or replace function public.get_team_history_v050(p_team_id uuid)
returns table(event_id bigint,event_type text,actor_id uuid,actor_username text,target_user_id uuid,target_username text,payload jsonb,created_at timestamptz)
language sql stable security definer set search_path=public as $$
  select e.id,e.event_type,e.actor_id,a.username::text,e.target_user_id,t.username::text,e.payload,e.created_at
  from public.team_events e
  left join public.profiles a on a.id=e.actor_id
  left join public.profiles t on t.id=e.target_user_id
  where e.team_id=p_team_id
  order by e.created_at desc,e.id desc limit 300;
$$;

create or replace function public.get_team_join_requests_v050(p_team_id uuid)
returns table(request_id uuid,user_id uuid,username text,avatar_key text,club_heart text,requested_at timestamptz)
language plpgsql stable security definer set search_path=public as $$
begin
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  return query
    select r.id,p.id,p.username::text,p.avatar_key,p.club_heart,r.requested_at
    from public.team_join_requests r join public.profiles p on p.id=r.user_id
    where r.team_id=p_team_id and r.status='pending'
    order by r.requested_at;
end;
$$;

create or replace function public.get_team_active_invite_v050(p_team_id uuid)
returns text language plpgsql stable security definer set search_path=public as $$
declare v text;
begin
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then return null; end if;
  select code into v from public.team_invites where team_id=p_team_id and active=true and (expires_at is null or expires_at>now()) order by created_at desc limit 1;
  return v;
end;
$$;

-- =============================================================================
-- 7. Classements Teams : points attribués à la Team au moment du verrouillage.
-- =============================================================================
create or replace function public.get_team_leaderboard_v050(p_season_id uuid,p_matchday_id uuid default null)
returns table(
  team_id uuid,team_name text,logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  current_members bigint,contributors bigint,total_points numeric,average_points numeric,top3_points numeric,rank_average bigint,rank_top3 bigint
)
language sql stable security definer set search_path=public as $$
with match_points as (
  select tm.team_id,p.user_id,sum(p.points)::numeric as pts
  from public.predictions p
  join public.matches m on m.id=p.match_id
  left join public.matchdays md on md.id=m.matchday_id
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=p.user_id
    and m.kickoff_at>=tm.joined_at and (tm.left_at is null or m.kickoff_at<tm.left_at)
  where p.season_id=p_season_id and m.status='finished'
    and (p_matchday_id is null or m.matchday_id=p_matchday_id)
    and (md.number is null or md.number<>0)
  group by tm.team_id,p.user_id
), qualifier_points as (
  select tm.team_id,tp.user_id,sum(case when kt.status='finished' and kt.qualified_club_id=tp.qualified_club_id then case when tp.pick_timing='early' then kt.qualifier_bonus_early else kt.qualifier_bonus_late end else 0 end)::numeric as pts
  from public.tie_predictions tp
  join public.knockout_ties kt on kt.id=tp.tie_id
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=tp.user_id
    and (case when kt.is_single_match then kt.leg1_kickoff_at else kt.leg2_kickoff_at end)>=tm.joined_at
    and (tm.left_at is null or (case when kt.is_single_match then kt.leg1_kickoff_at else kt.leg2_kickoff_at end)<tm.left_at)
  where tp.season_id=p_season_id and p_matchday_id is null
  group by tm.team_id,tp.user_id
), champion_points as (
  select tm.team_id,cp.user_id,sum(cp.points)::numeric as pts
  from public.champion_predictions cp
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=cp.user_id
    and coalesce(cp.locked_at,cp.updated_at)>=tm.joined_at and (tm.left_at is null or coalesce(cp.locked_at,cp.updated_at)<tm.left_at)
  where cp.season_id=p_season_id and p_matchday_id is null and cp.points<>0
  group by tm.team_id,cp.user_id
), user_team_points as (
  select team_id,user_id,sum(pts)::numeric as pts from (
    select * from match_points union all select * from qualifier_points union all select * from champion_points
  ) q group by team_id,user_id
), active_zero as (
  select tm.team_id,tm.user_id,0::numeric pts from public.team_memberships tm join public.teams t on t.id=tm.team_id
  where tm.season_id=p_season_id and tm.left_at is null and t.status='active'
), players as (
  select team_id,user_id,sum(pts)::numeric pts from (
    select * from user_team_points union all select * from active_zero
  ) q group by team_id,user_id
), team_stats as (
  select t.id team_id,t.name team_name,t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    (select count(*) from public.team_memberships x where x.team_id=t.id and x.left_at is null)::bigint current_members,
    count(p.user_id)::bigint contributors,coalesce(sum(p.pts),0)::numeric total_points,coalesce(avg(p.pts),0)::numeric average_points,
    coalesce((select sum(z.pts) from (select p2.pts from players p2 where p2.team_id=t.id order by p2.pts desc limit 3) z),0)::numeric top3_points
  from public.teams t left join players p on p.team_id=t.id
  where t.season_id=p_season_id and t.status='active'
  group by t.id
), ranked as (
  select s.*,
    row_number() over(order by average_points desc,top3_points desc,total_points desc,team_name)::bigint rank_average,
    row_number() over(order by top3_points desc,average_points desc,total_points desc,team_name)::bigint rank_top3
  from team_stats s
)
select * from ranked order by rank_average;
$$;

-- =============================================================================
-- 8. RLS + privilèges
-- =============================================================================
alter table public.teams enable row level security;
alter table public.team_memberships enable row level security;
alter table public.team_join_requests enable row level security;
alter table public.team_invites enable row level security;
alter table public.team_events enable row level security;

drop policy if exists teams_read on public.teams;
create policy teams_read on public.teams for select using(true);

drop policy if exists team_memberships_read on public.team_memberships;
create policy team_memberships_read on public.team_memberships for select using(true);

drop policy if exists team_requests_own_or_captain on public.team_join_requests;
create policy team_requests_own_or_captain on public.team_join_requests for select to authenticated using(
  user_id=auth.uid() or public.is_admin() or public.is_team_captain_v050(team_id)
);

drop policy if exists team_invites_captain_read on public.team_invites;
create policy team_invites_captain_read on public.team_invites for select to authenticated using(public.is_admin() or public.is_team_captain_v050(team_id));

drop policy if exists team_events_read on public.team_events;
create policy team_events_read on public.team_events for select using(true);

revoke all on public.teams,public.team_memberships,public.team_join_requests,public.team_invites,public.team_events from anon,authenticated;
grant select on public.teams,public.team_memberships,public.team_events to anon,authenticated;
grant select on public.team_join_requests,public.team_invites to authenticated;

grant execute on function public.is_team_captain_v050(uuid) to authenticated;
grant execute on function public.current_team_id_v050(uuid,uuid) to authenticated;
grant execute on function public.create_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.update_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.join_public_team_v050(uuid) to authenticated;
grant execute on function public.request_team_join_v050(uuid) to authenticated;
grant execute on function public.process_team_join_request_v050(uuid,boolean) to authenticated;
grant execute on function public.regenerate_team_invite_v050(uuid) to authenticated;
grant execute on function public.join_team_by_code_v050(uuid,text) to authenticated;
grant execute on function public.leave_team_v050(uuid) to authenticated;
grant execute on function public.kick_team_member_v050(uuid,uuid) to authenticated;
grant execute on function public.transfer_team_captain_v050(uuid,uuid) to authenticated;
grant execute on function public.dissolve_team_v050(uuid) to authenticated;
grant execute on function public.get_team_directory_v050(uuid) to anon,authenticated;
grant execute on function public.get_my_team_v050(uuid) to authenticated;
grant execute on function public.get_team_member_directory_v050(uuid) to authenticated;
grant execute on function public.get_team_members_v050(uuid) to authenticated;
grant execute on function public.get_team_history_v050(uuid) to authenticated;
grant execute on function public.get_team_join_requests_v050(uuid) to authenticated;
grant execute on function public.get_team_active_invite_v050(uuid) to authenticated;
grant execute on function public.get_team_leaderboard_v050(uuid,uuid) to anon,authenticated;

-- =============================================================================
-- 9. Audit léger sur les modifications de Team
-- =============================================================================
create or replace function public.audit_team_change_v050()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if old is distinct from new then
    insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data,new_data)
    values(auth.uid(),'team_update','team',new.id::text,to_jsonb(old),to_jsonb(new));
  end if;
  return new;
end;
$$;
drop trigger if exists audit_teams_v050 on public.teams;
create trigger audit_teams_v050 after update on public.teams for each row execute function public.audit_team_change_v050();

-- =============================================================================
-- 10. Realtime + version
-- =============================================================================
do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='teams') then execute 'alter publication supabase_realtime add table public.teams'; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='team_memberships') then execute 'alter publication supabase_realtime add table public.team_memberships'; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='team_join_requests') then execute 'alter publication supabase_realtime add table public.team_join_requests'; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='team_events') then execute 'alter publication supabase_realtime add table public.team_events'; end if;
  end if;
end $$;

insert into public.app_settings(key,value) values('app_version','"0.5.0"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

-- Vérifications utiles
select key,value from public.app_settings where key='app_version';
select proname from pg_proc where proname like '%team%v050' order by proname;
select id,name,public from storage.buckets where id='team-logos';


-- ============================================================================
-- V0.5.3 AVATARS
-- ============================================================================

-- Le Nid des Champions — V0.5.3
-- Avatars joueurs : bibliothèque officielle, upload, Storage, RLS et modération Admin.

begin;

alter table public.profiles add column if not exists avatar_source text not null default 'library';
alter table public.profiles add column if not exists avatar_storage_path text;
alter table public.profiles add column if not exists avatar_moderation_status text not null default 'approved';
alter table public.profiles add column if not exists avatar_rejection_reason text;
alter table public.profiles add column if not exists avatar_updated_at timestamptz not null default now();
alter table public.profiles alter column avatar_key set default 'avatar-hibou-or';

alter table public.profiles drop constraint if exists profiles_avatar_source_check;
alter table public.profiles add constraint profiles_avatar_source_check check (avatar_source in ('library','upload'));
alter table public.profiles drop constraint if exists profiles_avatar_moderation_status_check;
alter table public.profiles add constraint profiles_avatar_moderation_status_check check (avatar_moderation_status in ('approved','pending','rejected'));

-- Compatibilité avec les trois clés historiques du mode démo / premières versions.
update public.profiles set avatar_key='avatar-hibou-or' where avatar_key='owl-gold';
update public.profiles set avatar_key='avatar-hibou-saphir' where avatar_key='owl-blue';
update public.profiles set avatar_key='avatar-hibou-amethyste' where avatar_key='owl-violet';
update public.profiles set avatar_key='avatar-hibou-or' where avatar_key is null or btrim(avatar_key)='';

-- Les colonnes de modération ne sont volontairement PAS accordées en UPDATE direct.
-- Le joueur passe par les RPC ci-dessous ; l'Admin passe par la RPC de modération.
grant select on public.profiles to authenticated;
revoke update(avatar_key) on public.profiles from authenticated;

-- -----------------------------------------------------------------------------
-- Catalogue officiel V0.5.3 : 90 assets livrés avec le front.
-- -----------------------------------------------------------------------------
create table if not exists public.player_avatar_catalog (
  avatar_key text primary key,
  label text not null,
  category text not null,
  sort_order integer not null,
  asset_path text not null,
  active boolean not null default true
);

alter table public.player_avatar_catalog enable row level security;
drop policy if exists player_avatar_catalog_read on public.player_avatar_catalog;
create policy player_avatar_catalog_read on public.player_avatar_catalog
for select using (true);
grant select on public.player_avatar_catalog to anon,authenticated;

insert into public.player_avatar_catalog(avatar_key,label,category,sort_order,asset_path,active)
values
  ('avatar-hibou-royal','Royal','Nobles',1,'assets/avatars/nid/avatar-hibou-royal.png',true),
  ('avatar-hibou-argent','Argent','Nobles',2,'assets/avatars/nid/avatar-hibou-argent.png',true),
  ('avatar-hibou-or','Or','Nobles',3,'assets/avatars/nid/avatar-hibou-or.png',true),
  ('avatar-hibou-saphir','Saphir','Nobles',4,'assets/avatars/nid/avatar-hibou-saphir.png',true),
  ('avatar-hibou-amethyste','Amethyste','Nobles',5,'assets/avatars/nid/avatar-hibou-amethyste.png',true),
  ('avatar-hibou-velours','Velours','Nobles',6,'assets/avatars/nid/avatar-hibou-velours.png',true),
  ('avatar-hibou-couronne','Couronne','Nobles',7,'assets/avatars/nid/avatar-hibou-couronne.png',true),
  ('avatar-hibou-imperial','Imperial','Nobles',8,'assets/avatars/nid/avatar-hibou-imperial.png',true),
  ('avatar-hibou-europe','Europe','Nobles',9,'assets/avatars/nid/avatar-hibou-europe.png',true),
  ('avatar-hibou-prestige','Prestige','Nobles',10,'assets/avatars/nid/avatar-hibou-prestige.png',true),
  ('avatar-hibou-minuit','Minuit','Nocturnes',11,'assets/avatars/nid/avatar-hibou-minuit.png',true),
  ('avatar-hibou-eclipse','Eclipse','Nocturnes',12,'assets/avatars/nid/avatar-hibou-eclipse.png',true),
  ('avatar-hibou-lunaire','Lunaire','Nocturnes',13,'assets/avatars/nid/avatar-hibou-lunaire.png',true),
  ('avatar-hibou-nebuleuse','Nebuleuse','Nocturnes',14,'assets/avatars/nid/avatar-hibou-nebuleuse.png',true),
  ('avatar-hibou-astral','Astral','Nocturnes',15,'assets/avatars/nid/avatar-hibou-astral.png',true),
  ('avatar-hibou-constellation','Constellation','Nocturnes',16,'assets/avatars/nid/avatar-hibou-constellation.png',true),
  ('avatar-hibou-etoile','Etoile','Nocturnes',17,'assets/avatars/nid/avatar-hibou-etoile.png',true),
  ('avatar-hibou-comete','Comete','Nocturnes',18,'assets/avatars/nid/avatar-hibou-comete.png',true),
  ('avatar-hibou-orbite','Orbite','Nocturnes',19,'assets/avatars/nid/avatar-hibou-orbite.png',true),
  ('avatar-hibou-galaxie','Galaxie','Nocturnes',20,'assets/avatars/nid/avatar-hibou-galaxie.png',true),
  ('avatar-hibou-echarpe','Echarpe','Supporters',21,'assets/avatars/nid/avatar-hibou-echarpe.png',true),
  ('avatar-hibou-tambour','Tambour','Supporters',22,'assets/avatars/nid/avatar-hibou-tambour.png',true),
  ('avatar-hibou-tribune','Tribune','Supporters',23,'assets/avatars/nid/avatar-hibou-tribune.png',true),
  ('avatar-hibou-ultra','Ultra','Supporters',24,'assets/avatars/nid/avatar-hibou-ultra.png',true),
  ('avatar-hibou-drapeau','Drapeau','Supporters',25,'assets/avatars/nid/avatar-hibou-drapeau.png',true),
  ('avatar-hibou-chant','Chant','Supporters',26,'assets/avatars/nid/avatar-hibou-chant.png',true),
  ('avatar-hibou-stade','Stade','Supporters',27,'assets/avatars/nid/avatar-hibou-stade.png',true),
  ('avatar-hibou-kop','Kop','Supporters',28,'assets/avatars/nid/avatar-hibou-kop.png',true),
  ('avatar-hibou-tifo','Tifo','Supporters',29,'assets/avatars/nid/avatar-hibou-tifo.png',true),
  ('avatar-hibou-fumigene','Fumigene','Supporters',30,'assets/avatars/nid/avatar-hibou-fumigene.png',true),
  ('avatar-hibou-buteur','Buteur','Football',31,'assets/avatars/nid/avatar-hibou-buteur.png',true),
  ('avatar-hibou-gardien','Gardien','Football',32,'assets/avatars/nid/avatar-hibou-gardien.png',true),
  ('avatar-hibou-coach','Coach','Football',33,'assets/avatars/nid/avatar-hibou-coach.png',true),
  ('avatar-hibou-arbitre','Arbitre','Football',34,'assets/avatars/nid/avatar-hibou-arbitre.png',true),
  ('avatar-hibou-capitaine','Capitaine','Football',35,'assets/avatars/nid/avatar-hibou-capitaine.png',true),
  ('avatar-hibou-meneur','Meneur','Football',36,'assets/avatars/nid/avatar-hibou-meneur.png',true),
  ('avatar-hibou-defenseur','Defenseur','Football',37,'assets/avatars/nid/avatar-hibou-defenseur.png',true),
  ('avatar-hibou-ailier','Ailier','Football',38,'assets/avatars/nid/avatar-hibou-ailier.png',true),
  ('avatar-hibou-numero10','Numero10','Football',39,'assets/avatars/nid/avatar-hibou-numero10.png',true),
  ('avatar-hibou-remplacant','Remplacant','Football',40,'assets/avatars/nid/avatar-hibou-remplacant.png',true),
  ('avatar-hibou-coupe','Coupe','Champions',41,'assets/avatars/nid/avatar-hibou-coupe.png',true),
  ('avatar-hibou-medaille','Medaille','Champions',42,'assets/avatars/nid/avatar-hibou-medaille.png',true),
  ('avatar-hibou-champion','Champion','Champions',43,'assets/avatars/nid/avatar-hibou-champion.png',true),
  ('avatar-hibou-finale','Finale','Champions',44,'assets/avatars/nid/avatar-hibou-finale.png',true),
  ('avatar-hibou-podium','Podium','Champions',45,'assets/avatars/nid/avatar-hibou-podium.png',true),
  ('avatar-hibou-victoire','Victoire','Champions',46,'assets/avatars/nid/avatar-hibou-victoire.png',true),
  ('avatar-hibou-etoile-or','Etoile Or','Champions',47,'assets/avatars/nid/avatar-hibou-etoile-or.png',true),
  ('avatar-hibou-trophee','Trophee','Champions',48,'assets/avatars/nid/avatar-hibou-trophee.png',true),
  ('avatar-hibou-legende','Legende','Champions',49,'assets/avatars/nid/avatar-hibou-legende.png',true),
  ('avatar-hibou-dynastie','Dynastie','Champions',50,'assets/avatars/nid/avatar-hibou-dynastie.png',true),
  ('avatar-hibou-casserole','Casserole','Humour',51,'assets/avatars/nid/avatar-hibou-casserole.png',true),
  ('avatar-hibou-poele','Poele','Humour',52,'assets/avatars/nid/avatar-hibou-poele.png',true),
  ('avatar-hibou-boulet','Boulet','Humour',53,'assets/avatars/nid/avatar-hibou-boulet.png',true),
  ('avatar-hibou-perdu','Perdu','Humour',54,'assets/avatars/nid/avatar-hibou-perdu.png',true),
  ('avatar-hibou-endormi','Endormi','Humour',55,'assets/avatars/nid/avatar-hibou-endormi.png',true),
  ('avatar-hibou-retard','Retard','Humour',56,'assets/avatars/nid/avatar-hibou-retard.png',true),
  ('avatar-hibou-var','Var','Humour',57,'assets/avatars/nid/avatar-hibou-var.png',true),
  ('avatar-hibou-carton','Carton','Humour',58,'assets/avatars/nid/avatar-hibou-carton.png',true),
  ('avatar-hibou-zero','Zero','Humour',59,'assets/avatars/nid/avatar-hibou-zero.png',true),
  ('avatar-hibou-mauvaise-foi','Mauvaise Foi','Humour',60,'assets/avatars/nid/avatar-hibou-mauvaise-foi.png',true),
  ('avatar-hibou-masque','Masque','Mystérieux',61,'assets/avatars/nid/avatar-hibou-masque.png',true),
  ('avatar-hibou-ombre','Ombre','Mystérieux',62,'assets/avatars/nid/avatar-hibou-ombre.png',true),
  ('avatar-hibou-fantome','Fantome','Mystérieux',63,'assets/avatars/nid/avatar-hibou-fantome.png',true),
  ('avatar-hibou-secret','Secret','Mystérieux',64,'assets/avatars/nid/avatar-hibou-secret.png',true),
  ('avatar-hibou-oracle','Oracle','Mystérieux',65,'assets/avatars/nid/avatar-hibou-oracle.png',true),
  ('avatar-hibou-prophete','Prophete','Mystérieux',66,'assets/avatars/nid/avatar-hibou-prophete.png',true),
  ('avatar-hibou-mage','Mage','Mystérieux',67,'assets/avatars/nid/avatar-hibou-mage.png',true),
  ('avatar-hibou-alchimiste','Alchimiste','Mystérieux',68,'assets/avatars/nid/avatar-hibou-alchimiste.png',true),
  ('avatar-hibou-sorcier','Sorcier','Mystérieux',69,'assets/avatars/nid/avatar-hibou-sorcier.png',true),
  ('avatar-hibou-enigme','Enigme','Mystérieux',70,'assets/avatars/nid/avatar-hibou-enigme.png',true),
  ('avatar-hibou-neon','Neon','Futuristes',71,'assets/avatars/nid/avatar-hibou-neon.png',true),
  ('avatar-hibou-cyber','Cyber','Futuristes',72,'assets/avatars/nid/avatar-hibou-cyber.png',true),
  ('avatar-hibou-hologramme','Hologramme','Futuristes',73,'assets/avatars/nid/avatar-hibou-hologramme.png',true),
  ('avatar-hibou-quantique','Quantique','Futuristes',74,'assets/avatars/nid/avatar-hibou-quantique.png',true),
  ('avatar-hibou-electrique','Electrique','Futuristes',75,'assets/avatars/nid/avatar-hibou-electrique.png',true),
  ('avatar-hibou-plasma','Plasma','Futuristes',76,'assets/avatars/nid/avatar-hibou-plasma.png',true),
  ('avatar-hibou-vector','Vector','Futuristes',77,'assets/avatars/nid/avatar-hibou-vector.png',true),
  ('avatar-hibou-digital','Digital','Futuristes',78,'assets/avatars/nid/avatar-hibou-digital.png',true),
  ('avatar-hibou-android','Android','Futuristes',79,'assets/avatars/nid/avatar-hibou-android.png',true),
  ('avatar-hibou-cosmos','Cosmos','Futuristes',80,'assets/avatars/nid/avatar-hibou-cosmos.png',true),
  ('avatar-hibou-cristal','Cristal','Rares',81,'assets/avatars/nid/avatar-hibou-cristal.png',true),
  ('avatar-hibou-diamant','Diamant','Rares',82,'assets/avatars/nid/avatar-hibou-diamant.png',true),
  ('avatar-hibou-obsidienne','Obsidienne','Rares',83,'assets/avatars/nid/avatar-hibou-obsidienne.png',true),
  ('avatar-hibou-rubis','Rubis','Rares',84,'assets/avatars/nid/avatar-hibou-rubis.png',true),
  ('avatar-hibou-emeraude','Emeraude','Rares',85,'assets/avatars/nid/avatar-hibou-emeraude.png',true),
  ('avatar-hibou-opale','Opale','Rares',86,'assets/avatars/nid/avatar-hibou-opale.png',true),
  ('avatar-hibou-titane','Titane','Rares',87,'assets/avatars/nid/avatar-hibou-titane.png',true),
  ('avatar-hibou-platine','Platine','Rares',88,'assets/avatars/nid/avatar-hibou-platine.png',true),
  ('avatar-hibou-arcane','Arcane','Rares',89,'assets/avatars/nid/avatar-hibou-arcane.png',true),
  ('avatar-hibou-aurora','Aurora','Rares',90,'assets/avatars/nid/avatar-hibou-aurora.png',true)
on conflict(avatar_key) do update
set label=excluded.label,category=excluded.category,sort_order=excluded.sort_order,asset_path=excluded.asset_path,active=excluded.active;

-- -----------------------------------------------------------------------------
-- Storage player-avatars : privé ; lecture RLS propriétaire/Admin/approuvé, écriture limitée au dossier du joueur.
-- La publication dans l'UI reste conditionnée par avatar_moderation_status='approved'.
-- -----------------------------------------------------------------------------
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('player-avatars','player-avatars',false,3145728,array['image/png','image/jpeg','image/webp'])
on conflict(id) do update
set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists player_avatars_public_read on storage.objects;
drop policy if exists player_avatars_authorized_read on storage.objects;
create policy player_avatars_authorized_read on storage.objects
for select to authenticated
using (
  bucket_id='player-avatars'
  and (
    (storage.foldername(name))[1]=auth.uid()::text
    or public.is_admin()
    or exists(
      select 1 from public.profiles p
      where p.avatar_source='upload'
        and p.avatar_storage_path=name
        and p.avatar_moderation_status='approved'
        and p.status='active'
    )
  )
);

drop policy if exists player_avatars_own_insert on storage.objects;
create policy player_avatars_own_insert on storage.objects
for insert to authenticated
with check (
  bucket_id='player-avatars'
  and (storage.foldername(name))[1]=auth.uid()::text
  and lower(storage.extension(name)) in ('png','jpg','jpeg','webp')
);

drop policy if exists player_avatars_own_update on storage.objects;
create policy player_avatars_own_update on storage.objects
for update to authenticated
using (
  bucket_id='player-avatars'
  and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin())
)
with check (
  bucket_id='player-avatars'
  and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin())
  and lower(storage.extension(name)) in ('png','jpg','jpeg','webp')
);

drop policy if exists player_avatars_own_delete on storage.objects;
create policy player_avatars_own_delete on storage.objects
for delete to authenticated
using (
  bucket_id='player-avatars'
  and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin())
);

-- -----------------------------------------------------------------------------
-- Choix d'un avatar officiel : immédiatement approuvé.
-- -----------------------------------------------------------------------------
create or replace function public.select_player_avatar_v053(p_avatar_key text)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare v_key text:=btrim(coalesce(p_avatar_key,''));
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=auth.uid() and status='active') then raise exception 'Compte inactif.'; end if;
  if not exists(select 1 from public.player_avatar_catalog where avatar_key=v_key and active) then raise exception 'Avatar officiel invalide.'; end if;

  update public.profiles
  set avatar_source='library',
      avatar_key=v_key,
      avatar_storage_path=null,
      avatar_moderation_status='approved',
      avatar_rejection_reason=null,
      avatar_updated_at=now()
  where id=auth.uid();
end;
$$;
grant execute on function public.select_player_avatar_v053(text) to authenticated;

-- -----------------------------------------------------------------------------
-- Dépôt d'un upload : reste masqué publiquement jusqu'à validation Admin.
-- -----------------------------------------------------------------------------
create or replace function public.submit_player_avatar_v053(p_storage_path text)
returns void
language plpgsql
security definer
set search_path=public,storage
as $$
declare
  v_path text:=btrim(coalesce(p_storage_path,''));
  v_expected_prefix text:=auth.uid()::text || '/';
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=auth.uid() and status='active') then raise exception 'Compte inactif.'; end if;
  if v_path not like v_expected_prefix || '%' then raise exception 'Chemin avatar interdit.'; end if;
  if lower(storage.extension(v_path)) not in ('png','jpg','jpeg','webp') then raise exception 'Format avatar interdit.'; end if;
  if not exists(select 1 from storage.objects where bucket_id='player-avatars' and name=v_path) then raise exception 'Fichier avatar introuvable.'; end if;

  update public.profiles
  set avatar_source='upload',
      avatar_storage_path=v_path,
      avatar_moderation_status='pending',
      avatar_rejection_reason=null,
      avatar_updated_at=now()
  where id=auth.uid();
end;
$$;
grant execute on function public.submit_player_avatar_v053(text) to authenticated;

-- -----------------------------------------------------------------------------
-- File de modération Admin.
-- -----------------------------------------------------------------------------
create or replace function public.admin_list_avatar_moderation_v053()
returns table(
  user_id uuid,
  username text,
  avatar_key text,
  avatar_storage_path text,
  avatar_moderation_status text,
  avatar_rejection_reason text,
  avatar_updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path=public
as $$
begin
  if not public.is_admin() then raise exception 'Accès Admin requis.'; end if;
  return query
  select p.id,p.username::text,p.avatar_key,p.avatar_storage_path,p.avatar_moderation_status,p.avatar_rejection_reason,p.avatar_updated_at
  from public.profiles p
  where p.avatar_source='upload'
    and p.avatar_storage_path is not null
    and p.avatar_moderation_status in ('pending','rejected')
  order by case when p.avatar_moderation_status='pending' then 0 else 1 end,p.avatar_updated_at desc;
end;
$$;
grant execute on function public.admin_list_avatar_moderation_v053() to authenticated;

create or replace function public.admin_moderate_avatar_v053(
  p_user_id uuid,
  p_decision text,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  v_before jsonb;
  v_after jsonb;
  v_decision text:=lower(btrim(coalesce(p_decision,'')));
begin
  if not public.is_admin() then raise exception 'Accès Admin requis.'; end if;
  if v_decision not in ('approve','reject') then raise exception 'Décision invalide.'; end if;

  select to_jsonb(p) into v_before from public.profiles p where p.id=p_user_id;
  if v_before is null then raise exception 'Joueur introuvable.'; end if;
  if not exists(select 1 from public.profiles where id=p_user_id and avatar_source='upload' and avatar_storage_path is not null) then
    raise exception 'Aucun avatar uploadé à modérer.';
  end if;

  update public.profiles
  set avatar_moderation_status=case when v_decision='approve' then 'approved' else 'rejected' end,
      avatar_rejection_reason=case when v_decision='reject' then nullif(btrim(coalesce(p_reason,'')),'') else null end,
      avatar_updated_at=now()
  where id=p_user_id;

  select to_jsonb(p) into v_after from public.profiles p where p.id=p_user_id;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data,new_data)
  values(auth.uid(),'avatar_'||v_decision,'profile',p_user_id,v_before,v_after);
end;
$$;
grant execute on function public.admin_moderate_avatar_v053(uuid,text,text) to authenticated;

insert into public.app_settings(key,value)
values('app_version','"0.5.3"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
select id,name,public,file_size_limit,allowed_mime_types from storage.buckets where id='player-avatars';
select proname from pg_proc where proname like '%avatar%v053' order by proname;
-- Le Nid des Champions — V0.5.5
-- Finitions Teams : nouveaux motifs deux couleurs type blason.
-- À exécuter après V0.5.3/V0.5.4 avec le rôle postgres dans Supabase SQL Editor.

begin;

alter table public.teams
  drop constraint if exists teams_background_style_check;

alter table public.teams
  add constraint teams_background_style_check
  check (background_style in (
    'solid','vertical','horizontal','diagonal','radial','halo',
    'split-vertical','split-horizontal','split-diagonal',
    'stripes-vertical','stripes-horizontal','stripes-diagonal','quarters'
  ));

create or replace function public.create_team_v050(
  p_season_id uuid,
  p_name text,
  p_slogan text,
  p_description text,
  p_favorite_club_id uuid,
  p_visibility text,
  p_logo_type text,
  p_logo_asset_key text,
  p_logo_url text,
  p_shape text,
  p_frame_style text,
  p_primary_color text,
  p_secondary_color text,
  p_background_style text
)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;v_name text:=trim(p_name);v_slug text;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=auth.uid() and status='active') then raise exception 'Compte inactif.'; end if;
  if exists(select 1 from public.team_memberships where season_id=p_season_id and user_id=auth.uid() and left_at is null) then raise exception 'Tu appartiens déjà à une Team.'; end if;
  if char_length(v_name) not between 3 and 30 then raise exception 'Le nom doit contenir entre 3 et 30 caractères.'; end if;
  if coalesce(char_length(p_slogan),0)>80 then raise exception 'Slogan trop long.'; end if;
  if coalesce(char_length(p_description),0)>160 then raise exception 'Description trop longue.'; end if;
  if p_visibility not in ('public','private') then raise exception 'Visibilité invalide.'; end if;
  if p_background_style not in (
    'solid','vertical','horizontal','diagonal','radial','halo',
    'split-vertical','split-horizontal','split-diagonal',
    'stripes-vertical','stripes-horizontal','stripes-diagonal','quarters'
  ) then raise exception 'Fond invalide.'; end if;
  if p_logo_type not in ('library','upload') then raise exception 'Type de logo invalide.'; end if;
  v_slug:=public.slugify_team_v050(v_name)||'-'||substr(replace(gen_random_uuid()::text,'-',''),1,6);

  insert into public.teams(season_id,name,slug,slogan,description,favorite_club_id,visibility,captain_user_id,logo_type,logo_asset_key,logo_url,shape,frame_style,primary_color,secondary_color,background_style)
  values(p_season_id,v_name,v_slug,nullif(trim(p_slogan),''),nullif(trim(p_description),''),p_favorite_club_id,p_visibility,auth.uid(),p_logo_type,nullif(p_logo_asset_key,''),nullif(p_logo_url,''),coalesce(nullif(p_shape,''),'shield-classic'),coalesce(nullif(p_frame_style,''),'champions'),coalesce(nullif(p_primary_color,''),'#315cff'),coalesce(nullif(p_secondary_color,''),'#7454ff'),p_background_style)
  returning id into v_id;

  insert into public.team_memberships(season_id,team_id,user_id,join_type) values(p_season_id,v_id,auth.uid(),'creator');
  perform public.log_team_event_v050(v_id,'team_created',auth.uid(),jsonb_build_object('name',v_name),auth.uid());
  return v_id;
exception when unique_violation then
  raise exception 'Ce nom de Team est déjà utilisé pour cette saison.';
end;
$$;

grant execute on function public.create_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;

insert into public.app_settings(key,value)
values ('app_version','"0.5.5"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
select conname,pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid='public.teams'::regclass and conname='teams_background_style_check';


-- ============================================================================
-- PATCH V0.5.5a
-- ============================================================================
-- Le Nid des Champions — V0.5.5a
-- Correctif Teams : fonds de prévisualisation lisibles côté front,
-- Teams vacantes/réactivables et suppression définitive Super Admin.
-- À exécuter après V0.5.5 avec le rôle postgres dans Supabase SQL Editor.

begin;

-- Un capitaine peut quitter une Team dont il est le dernier membre.
-- La Team reste alors active mais vacante, donc captain_user_id doit accepter NULL.
alter table public.teams
  alter column captain_user_id drop not null;

-- Annuaire : conserver les Teams vacantes (capitaine NULL) et les archives.
create or replace function public.get_team_directory_v050(p_season_id uuid)
returns table(
  team_id uuid,name text,slug text,slogan text,description text,visibility text,status text,captain_user_id uuid,captain_username text,
  favorite_club_id uuid,favorite_club_name text,favorite_club_short text,favorite_club_logo_url text,favorite_club_logo_storage_path text,
  logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  member_count bigint,created_at timestamptz
)
language sql stable security definer set search_path=public as $$
  select t.id,t.name,t.slug,t.slogan,t.description,t.visibility,t.status,t.captain_user_id,cap.username::text,
    c.id,c.name,c.short_name,coalesce(c.logo_source_url,c.logo_url),c.logo_storage_path,
    t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    count(tm.id) filter(where tm.left_at is null)::bigint,t.created_at
  from public.teams t
  left join public.profiles cap on cap.id=t.captain_user_id
  left join public.clubs c on c.id=t.favorite_club_id
  left join public.team_memberships tm on tm.team_id=t.id
  where t.season_id=p_season_id
  group by t.id,cap.username,c.id,c.name,c.short_name,c.logo_source_url,c.logo_url,c.logo_storage_path
  order by (t.status='active') desc,(t.captain_user_id is null) desc,t.name;
$$;

-- Lecture de la Team courante : LEFT JOIN sur le capitaine pour tolérer les
-- états transitoires/vacants sans casser la RPC.
create or replace function public.get_my_team_v050(p_season_id uuid)
returns table(
  team_id uuid,name text,slug text,slogan text,description text,visibility text,status text,captain_user_id uuid,captain_username text,is_captain boolean,
  favorite_club_id uuid,favorite_club_name text,favorite_club_short text,favorite_club_logo_url text,favorite_club_logo_storage_path text,
  logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  joined_at timestamptz,member_count bigint
)
language sql stable security definer set search_path=public as $$
  select t.id,t.name,t.slug,t.slogan,t.description,t.visibility,t.status,t.captain_user_id,cap.username::text,(t.captain_user_id=auth.uid()),
    c.id,c.name,c.short_name,coalesce(c.logo_source_url,c.logo_url),c.logo_storage_path,
    t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    mine.joined_at,(select count(*) from public.team_memberships x where x.team_id=t.id and x.left_at is null)::bigint
  from public.team_memberships mine
  join public.teams t on t.id=mine.team_id
  left join public.profiles cap on cap.id=t.captain_user_id
  left join public.clubs c on c.id=t.favorite_club_id
  where mine.season_id=p_season_id and mine.user_id=auth.uid() and mine.left_at is null and t.status='active'
  order by mine.joined_at desc limit 1;
$$;

-- Quitter :
-- - membre normal => départ classique ;
-- - capitaine avec d'autres membres => transfert obligatoire ;
-- - capitaine seul => départ autorisé, Team conservée active et vacante.
create or replace function public.leave_team_v050(p_season_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  tm public.team_memberships%rowtype;
  t public.teams%rowtype;
  v_other_members integer;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;

  select * into tm
  from public.team_memberships
  where season_id=p_season_id and user_id=auth.uid() and left_at is null
  for update;
  if not found then raise exception 'Tu n’appartiens à aucune Team.'; end if;

  select * into t from public.teams where id=tm.team_id for update;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;

  if t.captain_user_id=auth.uid() then
    select count(*)::integer into v_other_members
    from public.team_memberships
    where team_id=t.id and left_at is null and user_id<>auth.uid();

    if v_other_members>0 then
      raise exception 'Transfère d’abord le capitanat avant de quitter la Team.';
    end if;

    update public.team_memberships set left_at=now(),leave_type='left' where id=tm.id;
    update public.teams set captain_user_id=null where id=t.id;
    update public.team_invites set active=false where team_id=t.id and active=true;
    update public.team_join_requests
      set status='cancelled',processed_at=now(),processed_by=auth.uid()
      where team_id=t.id and status='pending';
    perform public.log_team_event_v050(t.id,'member_left',auth.uid(),'{}'::jsonb);
    perform public.log_team_event_v050(t.id,'team_vacated',null,jsonb_build_object('former_captain_user_id',auth.uid()));
    return;
  end if;

  update public.team_memberships set left_at=now(),leave_type='left' where id=tm.id;
  perform public.log_team_event_v050(t.id,'member_left',auth.uid(),'{}'::jsonb);
end;
$$;

-- Reprendre une Team vacante ou réactiver sa propre Team dissoute.
create or replace function public.reclaim_team_v055a(p_team_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  t public.teams%rowtype;
  v_active_members integer;
  v_was_dissolved boolean;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=auth.uid() and status='active') then raise exception 'Compte inactif.'; end if;

  select * into t from public.teams where id=p_team_id for update;
  if not found then raise exception 'Team introuvable.'; end if;

  if exists(
    select 1 from public.team_memberships
    where season_id=t.season_id and user_id=auth.uid() and left_at is null
  ) then raise exception 'Tu appartiens déjà à une Team.'; end if;

  select count(*)::integer into v_active_members
  from public.team_memberships where team_id=t.id and left_at is null;

  v_was_dissolved := t.status='dissolved';

  if t.status='active' then
    if t.captain_user_id is not null or v_active_members>0 then
      raise exception 'Cette Team n’est plus vacante.';
    end if;
  elsif t.status='dissolved' then
    if t.captain_user_id is distinct from auth.uid() then
      raise exception 'Seul le dernier capitaine peut réactiver cette Team.';
    end if;
    if v_active_members>0 then raise exception 'Cette Team possède encore des membres actifs.'; end if;
  else
    raise exception 'État de Team non pris en charge.';
  end if;

  update public.teams
  set status='active',dissolved_at=null,captain_user_id=auth.uid()
  where id=t.id;

  insert into public.team_memberships(season_id,team_id,user_id,join_type)
  values(t.season_id,t.id,auth.uid(),'public');

  perform public.log_team_event_v050(
    t.id,
    case when v_was_dissolved then 'team_reactivated' else 'team_reclaimed' end,
    auth.uid(),
    jsonb_build_object('was_dissolved',v_was_dissolved)
  );
exception
  when unique_violation then
    raise exception 'Impossible de réactiver cette Team : son nom est désormais utilisé par une autre Team active.';
end;
$$;

-- Suppression physique réservée EXCLUSIVEMENT au Super Admin.
-- Les tables enfants sont en ON DELETE CASCADE ; un audit est conservé avant
-- suppression afin de garder la trace de l'acte de modération.
create or replace function public.super_admin_delete_team_v055a(p_team_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  t public.teams%rowtype;
begin
  if auth.uid() is null or not public.is_super_admin() then
    raise exception 'Suppression définitive réservée au Super Admin.';
  end if;

  select * into t from public.teams where id=p_team_id for update;
  if not found then raise exception 'Team introuvable.'; end if;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data,new_data)
  values(auth.uid(),'team_hard_delete','team',t.id::text,to_jsonb(t),jsonb_build_object('deleted_permanently',true));

  delete from public.teams where id=t.id;
end;
$$;

grant execute on function public.get_team_directory_v050(uuid) to anon,authenticated;
grant execute on function public.get_my_team_v050(uuid) to authenticated;
grant execute on function public.leave_team_v050(uuid) to authenticated;
grant execute on function public.reclaim_team_v055a(uuid) to authenticated;
grant execute on function public.super_admin_delete_team_v055a(uuid) to authenticated;

insert into public.app_settings(key,value)
values ('app_version','"0.5.5a"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
select id,name,status,captain_user_id,dissolved_at from public.teams order by created_at desc limit 20;

-- Le Nid des Champions — V0.6.0
-- Hibou masqué, rivalités, tickets, notifications internes + Web Push.
-- À exécuter après V0.5.5a avec le rôle postgres dans Supabase SQL Editor.

begin;

-- =============================================================================
-- 1. Préférences de notifications / caractère du Hibou
-- =============================================================================
create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  notifications_enabled boolean not null default true,
  push_enabled boolean not null default true,
  category_matches boolean not null default true,
  category_champion boolean not null default true,
  category_results boolean not null default true,
  category_rival boolean not null default true,
  category_team boolean not null default true,
  category_owl boolean not null default true,
  category_support boolean not null default true,
  category_system boolean not null default true,
  category_ranking boolean not null default true,
  reminder_24h boolean not null default false,
  reminder_3h boolean not null default true,
  reminder_1h boolean not null default false,
  reminder_30m boolean not null default true,
  quiet_hours_enabled boolean not null default true,
  quiet_start time not null default '23:00',
  quiet_end time not null default '08:00',
  urgent_bypass_quiet boolean not null default true,
  owl_tone text not null default 'automatic' check (owl_tone in ('sage','piquant','sans_pitie','automatic')),
  timezone text not null default 'Europe/Paris',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists notification_preferences_updated_at on public.notification_preferences;
create trigger notification_preferences_updated_at before update on public.notification_preferences
for each row execute function public.set_updated_at();

insert into public.notification_preferences(user_id)
select id from public.profiles
on conflict(user_id) do nothing;

create or replace function public.seed_notification_preferences_v060()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.notification_preferences(user_id) values(new.id) on conflict(user_id) do nothing;
  return new;
end;
$$;
drop trigger if exists seed_notification_preferences_v060 on public.profiles;
create trigger seed_notification_preferences_v060 after insert on public.profiles
for each row execute function public.seed_notification_preferences_v060();

-- =============================================================================
-- 2. Centre de notifications
-- =============================================================================
alter table public.notification_preferences add column if not exists category_support boolean not null default true;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  season_id uuid references public.seasons(id) on delete cascade,
  category text not null check (category in ('matches','champion','results','rival','team','owl','system','ranking','support')),
  title text not null,
  body text not null,
  importance text not null default 'normal' check (importance in ('normal','info','important','urgent')),
  deep_link text,
  payload jsonb not null default '{}'::jsonb,
  source_key text,
  push_requested boolean not null default false,
  push_not_before timestamptz,
  push_sent_at timestamptz,
  read_at timestamptz,
  deleted_at timestamptz,
  expires_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create unique index if not exists notifications_user_source_unique_idx
  on public.notifications(user_id,source_key) where source_key is not null;
create index if not exists notifications_user_created_idx on public.notifications(user_id,created_at desc);
create index if not exists notifications_pending_push_idx on public.notifications(push_requested,push_sent_at,created_at)
  where push_requested=true and push_sent_at is null;

-- =============================================================================
-- 3. Abonnements Web Push + journal de livraison
-- =============================================================================
create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth_key text not null,
  device_name text,
  user_agent text,
  platform text,
  active boolean not null default true,
  last_success_at timestamptz,
  last_failure_at timestamptz,
  failure_count integer not null default 0,
  disabled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists push_subscriptions_user_active_idx on public.push_subscriptions(user_id,active,created_at desc);
drop trigger if exists push_subscriptions_updated_at on public.push_subscriptions;
create trigger push_subscriptions_updated_at before update on public.push_subscriptions
for each row execute function public.set_updated_at();

create table if not exists public.push_delivery_logs (
  id bigint generated always as identity primary key,
  notification_id uuid references public.notifications(id) on delete set null,
  user_id uuid references public.profiles(id) on delete set null,
  subscription_id uuid references public.push_subscriptions(id) on delete set null,
  delivery_kind text not null default 'notification',
  status text not null check (status in ('sent','failed','expired','skipped')),
  response_code integer,
  error_message text,
  created_at timestamptz not null default now()
);
create index if not exists push_delivery_logs_created_idx on public.push_delivery_logs(created_at desc);
create index if not exists push_delivery_logs_user_idx on public.push_delivery_logs(user_id,created_at desc);

-- =============================================================================
-- 4. Rivalités
-- =============================================================================
create table if not exists public.player_rivals (
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rival_user_id uuid not null references public.profiles(id) on delete cascade,
  changed_matchday_id uuid references public.matchdays(id) on delete set null,
  changed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key(season_id,user_id),
  check (user_id <> rival_user_id)
);
create index if not exists player_rivals_rival_idx on public.player_rivals(season_id,rival_user_id);

create table if not exists public.rival_changes (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  matchday_id uuid not null references public.matchdays(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  old_rival_user_id uuid references public.profiles(id) on delete set null,
  rival_user_id uuid not null references public.profiles(id) on delete cascade,
  changed_at timestamptz not null default now(),
  unique(season_id,user_id,matchday_id),
  check (user_id <> rival_user_id)
);
create index if not exists rival_changes_user_idx on public.rival_changes(season_id,user_id,changed_at desc);

create table if not exists public.rival_duels (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  matchday_id uuid not null references public.matchdays(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rival_user_id uuid not null references public.profiles(id) on delete cascade,
  user_points integer not null default 0,
  rival_points integer not null default 0,
  result text check (result in ('win','draw','loss')),
  is_mutual boolean not null default false,
  locked_at timestamptz not null default now(),
  finalized_at timestamptz,
  created_at timestamptz not null default now(),
  unique(season_id,matchday_id,user_id),
  check (user_id <> rival_user_id)
);
create index if not exists rival_duels_user_idx on public.rival_duels(season_id,user_id,matchday_id);
create index if not exists rival_duels_pair_idx on public.rival_duels(season_id,user_id,rival_user_id);

create table if not exists public.ranking_notification_state (
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rank integer,
  points integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key(season_id,user_id)
);

-- =============================================================================
-- 5. Messages du Hibou
-- =============================================================================
create table if not exists public.owl_messages (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete cascade,
  title text not null default 'Message du Hibou masqué',
  body text not null,
  importance text not null default 'info' check (importance in ('normal','info','important','urgent')),
  target_scope text not null default 'all' check (target_scope in ('all','team','player')),
  target_id uuid,
  push_enabled boolean not null default false,
  automated boolean not null default false,
  show_in_history boolean not null default true,
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(title) between 1 and 120),
  check (char_length(body) between 1 and 4000)
);
create index if not exists owl_messages_active_idx on public.owl_messages(starts_at desc,expires_at);
drop trigger if exists owl_messages_updated_at on public.owl_messages;
create trigger owl_messages_updated_at before update on public.owl_messages
for each row execute function public.set_updated_at();

-- =============================================================================
-- 6. Tickets au Hibou + conversations + captures
-- =============================================================================
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  season_id uuid references public.seasons(id) on delete set null,
  ticket_type text not null check (ticket_type in ('bug','suggestion','question','modification','other')),
  subject text not null,
  status text not null default 'received' check (status in ('received','read','in_progress','fixed','resolved','closed','rejected')),
  priority text not null default 'normal' check (priority in ('normal','important','urgent')),
  technical_context jsonb not null default '{}'::jsonb,
  resolved_by_user_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(subject) between 3 and 160)
);
create index if not exists support_tickets_user_idx on public.support_tickets(user_id,created_at desc);
create index if not exists support_tickets_status_idx on public.support_tickets(status,priority,created_at desc);
drop trigger if exists support_tickets_updated_at on public.support_tickets;
create trigger support_tickets_updated_at before update on public.support_tickets
for each row execute function public.set_updated_at();

create table if not exists public.support_ticket_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  author_id uuid references public.profiles(id) on delete set null,
  author_kind text not null check (author_kind in ('player','owl')),
  body text not null,
  created_at timestamptz not null default now(),
  check (char_length(body) between 1 and 6000)
);
create index if not exists support_ticket_messages_ticket_idx on public.support_ticket_messages(ticket_id,created_at);

create table if not exists public.support_ticket_attachments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  message_id uuid references public.support_ticket_messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null,
  size_bytes integer not null check (size_bytes > 0 and size_bytes <= 5242880),
  created_at timestamptz not null default now()
);
create index if not exists support_ticket_attachments_ticket_idx on public.support_ticket_attachments(ticket_id,created_at);

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('support-captures','support-captures',false,5242880,array['image/png','image/jpeg','image/webp'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

-- =============================================================================
-- 7. Helpers notifications
-- =============================================================================
create or replace function public.create_notification_v060(
  p_user_id uuid,
  p_season_id uuid,
  p_category text,
  p_title text,
  p_body text,
  p_importance text default 'normal',
  p_deep_link text default null,
  p_payload jsonb default '{}'::jsonb,
  p_push_requested boolean default false,
  p_source_key text default null
) returns uuid
language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
  if not exists(select 1 from public.profiles where id=p_user_id and status='active') then return null; end if;
  insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,push_requested,source_key,expires_at)
  values(p_user_id,p_season_id,p_category,left(p_title,160),left(p_body,2000),p_importance,p_deep_link,coalesce(p_payload,'{}'::jsonb),p_push_requested,p_source_key,
    case when p_importance in ('important','urgent') then null else now()+interval '90 days' end)
  on conflict(user_id,source_key) where source_key is not null do nothing
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.mark_all_notifications_read_v060()
returns void language sql security definer set search_path=public as $$
  update public.notifications set read_at=coalesce(read_at,now())
  where user_id=auth.uid() and deleted_at is null and read_at is null;
$$;

-- =============================================================================
-- 8. Rival : choix, verrouillage et duels
-- =============================================================================
create or replace function public.set_my_rival_v060(p_season_id uuid,p_matchday_id uuid,p_rival_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  v_first_kickoff timestamptz;
  v_old uuid;
  v_me text;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if p_rival_user_id=auth.uid() then raise exception 'Tu ne peux pas être ton propre rival.'; end if;
  if not exists(select 1 from public.profiles where id=p_rival_user_id and status='active') then raise exception 'Ce joueur n’est pas disponible.'; end if;
  if not exists(select 1 from public.matchdays where id=p_matchday_id and season_id=p_season_id) then raise exception 'Journée UEFA invalide.'; end if;
  select min(kickoff_at) into v_first_kickoff from public.matches where matchday_id=p_matchday_id and status<>'cancelled';
  if v_first_kickoff is not null and v_first_kickoff<=now() then raise exception 'Rival verrouillé : la journée UEFA a commencé.'; end if;
  if exists(select 1 from public.rival_changes where season_id=p_season_id and user_id=auth.uid() and matchday_id=p_matchday_id) then
    raise exception 'Tu as déjà changé de rival pour cette journée UEFA.';
  end if;
  select rival_user_id into v_old from public.player_rivals where season_id=p_season_id and user_id=auth.uid();
  insert into public.player_rivals(season_id,user_id,rival_user_id,changed_matchday_id,changed_at)
  values(p_season_id,auth.uid(),p_rival_user_id,p_matchday_id,now())
  on conflict(season_id,user_id) do update set rival_user_id=excluded.rival_user_id,changed_matchday_id=excluded.changed_matchday_id,changed_at=now();
  insert into public.rival_changes(season_id,matchday_id,user_id,old_rival_user_id,rival_user_id)
  values(p_season_id,p_matchday_id,auth.uid(),v_old,p_rival_user_id);
  select username::text into v_me from public.profiles where id=auth.uid();
  perform public.create_notification_v060(p_rival_user_id,p_season_id,'rival','⚔️ Tu as été choisi comme rival',
    coalesce(v_me,'Un joueur')||' t’a dans le viseur pour le Nid.','info','rival',jsonb_build_object('rival_user_id',auth.uid()),true,
    'rival-chosen:'||p_season_id::text||':'||p_matchday_id::text||':'||auth.uid()::text);
end;
$$;

create or replace function public.refresh_rival_duels_v060(p_matchday_id uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare
  v_md public.matchdays%rowtype;
  v_first timestamptz;
  v_done boolean;
  v_count integer:=0;
  d record;
  upoints integer;
  rpoints integer;
  v_result text;
  v_uname text;
  v_rname text;
  v_tone text;
  v_title text;
  v_body text;
  v_margin integer;
begin
  select * into v_md from public.matchdays where id=p_matchday_id;
  if not found then return 0; end if;
  select min(kickoff_at) into v_first from public.matches where matchday_id=p_matchday_id and status<>'cancelled';
  if v_first is null or v_first>now() then return 0; end if;

  insert into public.rival_duels(season_id,matchday_id,user_id,rival_user_id,is_mutual,locked_at)
  select pr.season_id,p_matchday_id,pr.user_id,pr.rival_user_id,
    exists(select 1 from public.player_rivals back where back.season_id=pr.season_id and back.user_id=pr.rival_user_id and back.rival_user_id=pr.user_id),
    v_first
  from public.player_rivals pr
  where pr.season_id=v_md.season_id
  on conflict(season_id,matchday_id,user_id) do nothing;

  select not exists(select 1 from public.matches where matchday_id=p_matchday_id and status not in ('finished','cancelled')) into v_done;
  if not v_done then return 0; end if;

  for d in select * from public.rival_duels where matchday_id=p_matchday_id and finalized_at is null loop
    select coalesce(sum(p.points),0)::integer into upoints
      from public.predictions p join public.matches m on m.id=p.match_id
      where p.user_id=d.user_id and m.matchday_id=p_matchday_id and m.status='finished';
    select coalesce(sum(p.points),0)::integer into rpoints
      from public.predictions p join public.matches m on m.id=p.match_id
      where p.user_id=d.rival_user_id and m.matchday_id=p_matchday_id and m.status='finished';
    v_result:=case when upoints>rpoints then 'win' when upoints<rpoints then 'loss' else 'draw' end;
    update public.rival_duels set user_points=upoints,rival_points=rpoints,result=v_result,finalized_at=now() where id=d.id;
    select username::text into v_uname from public.profiles where id=d.user_id;
    select username::text into v_rname from public.profiles where id=d.rival_user_id;
    select coalesce(owl_tone,'automatic') into v_tone from public.notification_preferences where user_id=d.user_id;
    v_tone:=coalesce(v_tone,'automatic');
    v_margin:=abs(upoints-rpoints);
    if v_tone='sage' then
      v_title:=case v_result when 'win' then '🏆 Duel remporté' when 'loss' then '⚔️ Duel perdu' else '🤝 Match nul' end;
      v_body:=coalesce(v_uname,'Toi')||' '||upoints||' — '||rpoints||' '||coalesce(v_rname,'Rival')||'. Rendez-vous à la prochaine journée.';
    elsif v_tone='sans_pitie' or (v_tone='automatic' and v_margin>=10) then
      v_title:=case v_result when 'win' then '🔥 Rival pulvérisé' when 'loss' then '💀 Le Hibou propose de ne pas en parler.' else '🤝 Deux suspects, aucun vainqueur.' end;
      v_body:=coalesce(v_uname,'Toi')||' '||upoints||' — '||rpoints||' '||coalesce(v_rname,'Rival')||case v_result when 'win' then '. Le Hibou cherche encore les morceaux.' when 'loss' then '. Les preuves seront détruites à l’aube.' else '. Vous avez réussi à vous neutraliser mutuellement.' end;
    else
      v_title:=case v_result when 'win' then '🏆 Rival terrassé' when 'loss' then '💀 Ça pique.' else '🤝 Personne n’a gagné.' end;
      v_body:=coalesce(v_uname,'Toi')||' '||upoints||' — '||rpoints||' '||coalesce(v_rname,'Rival')||case v_result when 'win' then '. Le Hibou prend note avec un sourire gênant.' when 'loss' then '. Le Hibou suggère discrètement de te réveiller.' else '. Une élégante manière d’échouer ensemble.' end;
    end if;
    perform public.create_notification_v060(d.user_id,d.season_id,'rival',v_title,v_body,
      'info','rival',jsonb_build_object('duel_id',d.id,'matchday_id',p_matchday_id,'result',v_result),true,'rival-duel-final:'||d.id::text);
    v_count:=v_count+1;
  end loop;
  return v_count;
end;
$$;

create or replace function public.get_rival_summary_v060(p_season_id uuid,p_user_id uuid default null)
returns table(
  user_id uuid,rival_user_id uuid,duels bigint,wins bigint,draws bigint,losses bigint,
  points_for bigint,points_against bigint,best_margin integer,worst_margin integer,current_win_streak integer,
  mutual boolean
)
language sql stable security definer set search_path=public as $$
with target as (select coalesce(p_user_id,auth.uid()) uid), current_r as (
  select pr.user_id,pr.rival_user_id from public.player_rivals pr,target t where pr.season_id=p_season_id and pr.user_id=t.uid
), ds as (
  select d.* from public.rival_duels d,target t,current_r cr where d.season_id=p_season_id and d.user_id=t.uid and d.rival_user_id=cr.rival_user_id and d.finalized_at is not null
), streak as (
  select count(*)::integer n from (
    select result,row_number() over(order by finalized_at desc) rn,
      sum(case when result<>'win' then 1 else 0 end) over(order by finalized_at desc) grp
    from ds
  ) x where grp=0 and result='win'
)
select cr.user_id,cr.rival_user_id,count(ds.id)::bigint,
  count(*) filter(where ds.result='win')::bigint,count(*) filter(where ds.result='draw')::bigint,count(*) filter(where ds.result='loss')::bigint,
  coalesce(sum(ds.user_points),0)::bigint,coalesce(sum(ds.rival_points),0)::bigint,
  coalesce(max(ds.user_points-ds.rival_points),0)::integer,coalesce(min(ds.user_points-ds.rival_points),0)::integer,
  coalesce((select n from streak),0),
  exists(select 1 from public.player_rivals back where back.season_id=p_season_id and back.user_id=cr.rival_user_id and back.rival_user_id=cr.user_id)
from current_r cr left join ds on true
group by cr.user_id,cr.rival_user_id;
$$;

-- =============================================================================
-- 9. Tickets : création, conversation, statut
-- =============================================================================
create or replace function public.create_support_ticket_v060(
  p_season_id uuid,p_type text,p_subject text,p_message text,p_technical_context jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_ticket uuid;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  insert into public.support_tickets(user_id,season_id,ticket_type,subject,technical_context)
  values(auth.uid(),p_season_id,p_type,trim(p_subject),coalesce(p_technical_context,'{}'::jsonb)) returning id into v_ticket;
  insert into public.support_ticket_messages(ticket_id,author_id,author_kind,body)
  values(v_ticket,auth.uid(),'player',trim(p_message));
  return v_ticket;
end;
$$;

create or replace function public.reply_support_ticket_v060(p_ticket_id uuid,p_body text)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_ticket public.support_tickets%rowtype; v_id uuid; v_owl boolean;
begin
  select * into v_ticket from public.support_tickets where id=p_ticket_id;
  if not found then raise exception 'Ticket introuvable.'; end if;
  v_owl:=public.is_super_admin();
  if not v_owl and v_ticket.user_id<>auth.uid() then raise exception 'Accès refusé.'; end if;
  insert into public.support_ticket_messages(ticket_id,author_id,author_kind,body)
  values(p_ticket_id,auth.uid(),case when v_owl then 'owl' else 'player' end,trim(p_body)) returning id into v_id;
  if v_owl then
    update public.support_tickets set status=case when status='received' then 'in_progress' else status end where id=p_ticket_id;
    perform public.create_notification_v060(v_ticket.user_id,v_ticket.season_id,'support','🦉 Le Hibou a répondu',
      'Une nouvelle réponse t’attend dans « '||v_ticket.subject||' ».','important','support:'||p_ticket_id::text,
      jsonb_build_object('ticket_id',p_ticket_id),true,'ticket-reply:'||v_id::text);
  end if;
  return v_id;
end;
$$;

create or replace function public.resolve_my_support_ticket_v060(p_ticket_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  update public.support_tickets set status='resolved',resolved_by_user_at=now()
  where id=p_ticket_id and user_id=auth.uid() and status not in ('closed','rejected');
  if not found then raise exception 'Ticket introuvable ou déjà clos.'; end if;
end;
$$;

create or replace function public.admin_update_support_ticket_v060(p_ticket_id uuid,p_status text,p_priority text)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  update public.support_tickets set status=p_status,priority=p_priority,
    closed_at=case when p_status in ('closed','rejected') then now() else null end
  where id=p_ticket_id;
  if not found then raise exception 'Ticket introuvable.'; end if;
end;
$$;

-- =============================================================================
-- 10. Messages ciblés du Hibou (Super Admin)
-- =============================================================================
create or replace function public.admin_send_owl_message_v060(
  p_season_id uuid,p_title text,p_body text,p_importance text,p_target_scope text,p_target_id uuid default null,p_push boolean default false
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; r record;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_target_scope='player' and p_target_id is null then raise exception 'Choisis un joueur.'; end if;
  if p_target_scope='team' and p_target_id is null then raise exception 'Choisis une Team.'; end if;
  insert into public.owl_messages(season_id,title,body,importance,target_scope,target_id,push_enabled,created_by)
  values(p_season_id,trim(p_title),trim(p_body),p_importance,p_target_scope,p_target_id,p_push,auth.uid()) returning id into v_id;
  for r in
    select p.id user_id from public.profiles p where p.status='active' and (
      p_target_scope='all'
      or (p_target_scope='player' and p.id=p_target_id)
      or (p_target_scope='team' and exists(select 1 from public.team_memberships tm where tm.team_id=p_target_id and tm.user_id=p.id and tm.left_at is null))
    )
  loop
    perform public.create_notification_v060(r.user_id,p_season_id,'owl','🦉 '||trim(p_title),trim(p_body),p_importance,
      'home',jsonb_build_object('owl_message_id',v_id),p_push,'owl-message:'||v_id::text);
  end loop;
  return v_id;
end;
$$;

create or replace function public.admin_send_system_message_v060(
  p_season_id uuid,p_title text,p_body text,p_push boolean default true
) returns integer language plpgsql security definer set search_path=public as $$
declare r record; v_count integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  for r in select id from public.profiles where status='active' loop
    perform public.create_notification_v060(r.id,p_season_id,'system','🚨 '||trim(p_title),trim(p_body),'urgent','home',jsonb_build_object('critical',true),p_push,
      'system-critical:'||md5(trim(p_title)||trim(p_body)||now()::date::text));
    v_count:=v_count+1;
  end loop;
  insert into public.audit_logs(actor_id,action,entity_type,new_data) values(auth.uid(),'system_message_send','notification',jsonb_build_object('title',p_title,'recipients',v_count,'push',p_push));
  return v_count;
end;
$$;

-- =============================================================================
-- 10b. Notifications automatiques liées aux Teams
-- =============================================================================
create or replace function public.notify_team_event_v060()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  t public.teams%rowtype;
  actor_name text;
  target_name text;
  r record;
begin
  select * into t from public.teams where id=new.team_id;
  if not found then return new; end if;
  select username::text into actor_name from public.profiles where id=new.actor_id;
  select username::text into target_name from public.profiles where id=new.target_user_id;

  if new.event_type='join_requested' and t.captain_user_id is not null then
    perform public.create_notification_v060(t.captain_user_id,new.season_id,'team','🛡 Nouvelle demande d’adhésion',
      coalesce(target_name,'Un joueur')||' veut rejoindre '||t.name||'.','important','teams:management',jsonb_build_object('team_id',new.team_id,'tab','management'),true,'team-event:'||new.id::text||':captain');
  elsif new.event_type='join_rejected' and new.target_user_id is not null then
    perform public.create_notification_v060(new.target_user_id,new.season_id,'team','Demande refusée',
      t.name||' n’a pas accepté ta demande pour le moment.','info','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':target');
  elsif new.event_type='member_joined' and new.target_user_id is not null then
    if new.actor_id is distinct from new.target_user_id then
      perform public.create_notification_v060(new.target_user_id,new.season_id,'team','🛡 Bienvenue dans la Team',
        'Tu rejoins '||t.name||'.','important','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':target');
    end if;
    for r in select user_id from public.team_memberships where team_id=new.team_id and left_at is null and user_id<>new.target_user_id loop
      perform public.create_notification_v060(r.user_id,new.season_id,'team','🛡 Nouveau membre',
        coalesce(target_name,'Un nouveau joueur')||' rejoint '||t.name||'.','info','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':member:'||r.user_id::text);
    end loop;
  elsif new.event_type='member_kicked' and new.target_user_id is not null then
    perform public.create_notification_v060(new.target_user_id,new.season_id,'team','Tu quittes la Team',
      'Tu as été retiré de '||t.name||'.','important','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':target');
  elsif new.event_type='captain_transferred' and new.target_user_id is not null then
    perform public.create_notification_v060(new.target_user_id,new.season_id,'team','👑 Nouveau capitaine',
      'Le capitanat de '||t.name||' t’est confié.','important','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':target');
  elsif new.event_type='team_dissolved' then
    for r in select user_id from public.team_memberships where team_id=new.team_id and left_at is null loop
      perform public.create_notification_v060(r.user_id,new.season_id,'team','🛡 Team dissoute',
        t.name||' vient d’être dissoute et archivée.','important','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':member:'||r.user_id::text);
    end loop;
  elsif new.event_type='identity_changed' then
    for r in select user_id from public.team_memberships where team_id=new.team_id and left_at is null loop
      perform public.create_notification_v060(r.user_id,new.season_id,'team','🎨 Apparence de Team mise à jour',
        t.name||' a rafraîchi son identité.','normal','teams',jsonb_build_object('team_id',new.team_id),false,'team-event:'||new.id::text||':member:'||r.user_id::text);
    end loop;
  end if;
  return new;
end;
$$;
drop trigger if exists notify_team_event_v060 on public.team_events;
create trigger notify_team_event_v060 after insert on public.team_events
for each row execute function public.notify_team_event_v060();

-- =============================================================================
-- 11. RLS
-- =============================================================================
alter table public.notification_preferences enable row level security;
alter table public.notifications enable row level security;
alter table public.push_subscriptions enable row level security;
alter table public.push_delivery_logs enable row level security;
alter table public.player_rivals enable row level security;
alter table public.rival_changes enable row level security;
alter table public.rival_duels enable row level security;
alter table public.ranking_notification_state enable row level security;
alter table public.owl_messages enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_ticket_messages enable row level security;
alter table public.support_ticket_attachments enable row level security;

drop policy if exists notification_preferences_own on public.notification_preferences;
create policy notification_preferences_own on public.notification_preferences for all to authenticated
using(user_id=auth.uid()) with check(user_id=auth.uid());

drop policy if exists notifications_own_read on public.notifications;
create policy notifications_own_read on public.notifications for select to authenticated using(user_id=auth.uid() or public.is_super_admin());
drop policy if exists notifications_own_update on public.notifications;
create policy notifications_own_update on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

drop policy if exists push_subscriptions_own on public.push_subscriptions;
create policy push_subscriptions_own on public.push_subscriptions for all to authenticated
using(user_id=auth.uid() or public.is_super_admin()) with check(user_id=auth.uid() or public.is_super_admin());
drop policy if exists push_delivery_logs_super on public.push_delivery_logs;
create policy push_delivery_logs_super on public.push_delivery_logs for select to authenticated using(public.is_super_admin());

drop policy if exists player_rivals_read on public.player_rivals;
create policy player_rivals_read on public.player_rivals for select to authenticated using(true);
drop policy if exists rival_changes_read on public.rival_changes;
create policy rival_changes_read on public.rival_changes for select to authenticated using(true);
drop policy if exists rival_duels_read on public.rival_duels;
create policy rival_duels_read on public.rival_duels for select to authenticated using(true);
drop policy if exists ranking_notification_state_own on public.ranking_notification_state;
create policy ranking_notification_state_own on public.ranking_notification_state for select to authenticated using(user_id=auth.uid() or public.is_super_admin());

drop policy if exists owl_messages_target_read on public.owl_messages;
create policy owl_messages_target_read on public.owl_messages for select to authenticated using(
  public.is_super_admin()
  or (starts_at<=now() and (show_in_history=true or expires_at is null or expires_at>now()) and (
    target_scope='all'
    or (target_scope='player' and target_id=auth.uid())
    or (target_scope='team' and exists(select 1 from public.team_memberships tm where tm.team_id=target_id and tm.user_id=auth.uid() and tm.left_at is null))
  ))
);
drop policy if exists owl_messages_super_all on public.owl_messages;
create policy owl_messages_super_all on public.owl_messages for all to authenticated using(public.is_super_admin()) with check(public.is_super_admin());

drop policy if exists support_tickets_private on public.support_tickets;
create policy support_tickets_private on public.support_tickets for select to authenticated using(user_id=auth.uid() or public.is_super_admin());
drop policy if exists support_messages_private on public.support_ticket_messages;
create policy support_messages_private on public.support_ticket_messages for select to authenticated using(
  exists(select 1 from public.support_tickets t where t.id=ticket_id and (t.user_id=auth.uid() or public.is_super_admin()))
);
drop policy if exists support_attachments_private on public.support_ticket_attachments;
create policy support_attachments_private on public.support_ticket_attachments for select to authenticated using(
  exists(select 1 from public.support_tickets t where t.id=ticket_id and (t.user_id=auth.uid() or public.is_super_admin()))
);
drop policy if exists support_attachments_insert_own on public.support_ticket_attachments;
create policy support_attachments_insert_own on public.support_ticket_attachments for insert to authenticated with check(
  user_id=auth.uid() and exists(select 1 from public.support_tickets t where t.id=ticket_id and t.user_id=auth.uid())
);

-- Storage captures : utilisateur propriétaire ou Super Admin.
drop policy if exists support_captures_read on storage.objects;
create policy support_captures_read on storage.objects for select to authenticated using(
  bucket_id='support-captures' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_super_admin())
);
drop policy if exists support_captures_insert on storage.objects;
create policy support_captures_insert on storage.objects for insert to authenticated with check(
  bucket_id='support-captures' and (storage.foldername(name))[1]=auth.uid()::text
);
drop policy if exists support_captures_delete on storage.objects;
create policy support_captures_delete on storage.objects for delete to authenticated using(
  bucket_id='support-captures' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_super_admin())
);

-- =============================================================================
-- 12. Privilèges
-- =============================================================================
revoke execute on function public.create_notification_v060(uuid,uuid,text,text,text,text,text,jsonb,boolean,text) from public,anon,authenticated;
revoke execute on function public.seed_notification_preferences_v060() from public,anon,authenticated;
revoke execute on function public.notify_team_event_v060() from public,anon,authenticated;
revoke execute on function public.refresh_rival_duels_v060(uuid) from public,anon,authenticated;
revoke execute on function public.mark_all_notifications_read_v060() from public,anon;
revoke execute on function public.set_my_rival_v060(uuid,uuid,uuid) from public,anon;
revoke execute on function public.get_rival_summary_v060(uuid,uuid) from public,anon;
revoke execute on function public.create_support_ticket_v060(uuid,text,text,text,jsonb) from public,anon;
revoke execute on function public.reply_support_ticket_v060(uuid,text) from public,anon;
revoke execute on function public.resolve_my_support_ticket_v060(uuid) from public,anon;
revoke execute on function public.admin_update_support_ticket_v060(uuid,text,text) from public,anon;
revoke execute on function public.admin_send_owl_message_v060(uuid,text,text,text,text,uuid,boolean) from public,anon;
revoke execute on function public.admin_send_system_message_v060(uuid,text,text,boolean) from public,anon;

grant select,insert,update on public.notification_preferences to authenticated;
grant select on public.notifications to authenticated;
revoke update on public.notifications from authenticated;
grant update(read_at,deleted_at) on public.notifications to authenticated;
grant select,insert,update,delete on public.push_subscriptions to authenticated;
grant select on public.push_delivery_logs to authenticated;
grant select on public.player_rivals,public.rival_changes,public.rival_duels,public.ranking_notification_state to authenticated;
grant select on public.owl_messages to authenticated;
grant insert,update,delete on public.owl_messages to authenticated;
grant select on public.support_tickets,public.support_ticket_messages,public.support_ticket_attachments to authenticated;
grant insert on public.support_ticket_attachments to authenticated;

grant execute on function public.mark_all_notifications_read_v060() to authenticated;
grant execute on function public.set_my_rival_v060(uuid,uuid,uuid) to authenticated;
grant execute on function public.get_rival_summary_v060(uuid,uuid) to authenticated;
grant execute on function public.create_support_ticket_v060(uuid,text,text,text,jsonb) to authenticated;
grant execute on function public.reply_support_ticket_v060(uuid,text) to authenticated;
grant execute on function public.resolve_my_support_ticket_v060(uuid) to authenticated;
grant execute on function public.admin_update_support_ticket_v060(uuid,text,text) to authenticated;
grant execute on function public.admin_send_owl_message_v060(uuid,text,text,text,text,uuid,boolean) to authenticated;
grant execute on function public.admin_send_system_message_v060(uuid,text,text,boolean) to authenticated;

-- L'Edge Function push-dispatch travaille avec service_role. BYPASSRLS ne remplace
-- pas les privilèges SQL sur les objets ni EXECUTE après révocation de PUBLIC.
grant all on public.notification_preferences,public.notifications,public.push_subscriptions,public.push_delivery_logs,
  public.player_rivals,public.rival_changes,public.rival_duels,public.ranking_notification_state to service_role;
grant usage,select on sequence public.push_delivery_logs_id_seq to service_role;
grant execute on function public.refresh_rival_duels_v060(uuid) to service_role;

insert into public.app_settings(key,value)
values ('app_version','"0.6.0"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
-- Le Nid des Champions — V0.6.2
-- Correctif UX : réactions joueurs + cohérence des notifications sociales.
-- Les corrections visuelles Team/avatar sont front-only ; ce patch ajoute seulement
-- la mécanique serveur des réactions rapides.

begin;

alter table public.notification_preferences
  add column if not exists category_social boolean not null default true;

-- La contrainte V0.6.0 ne connaissait pas encore la catégorie social.
alter table public.notifications drop constraint if exists notifications_category_check;
alter table public.notifications
  add constraint notifications_category_check
  check (category in ('matches','champion','results','rival','team','owl','system','ranking','support','social'));

create table if not exists public.player_reactions (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id) on delete cascade,
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null check (emoji in ('👏','🔥','😂','😱','🦉','🏆','💀','❤️')),
  created_at timestamptz not null default now(),
  check (sender_user_id <> recipient_user_id)
);
create index if not exists player_reactions_sender_idx on public.player_reactions(sender_user_id,created_at desc);
create index if not exists player_reactions_recipient_idx on public.player_reactions(recipient_user_id,created_at desc);

alter table public.player_reactions enable row level security;
drop policy if exists player_reactions_own_read on public.player_reactions;
create policy player_reactions_own_read on public.player_reactions
for select to authenticated
using (sender_user_id=auth.uid() or recipient_user_id=auth.uid());

grant select on public.player_reactions to authenticated;

create or replace function public.send_player_reaction_v062(
  p_recipient_user_id uuid,
  p_emoji text,
  p_season_id uuid default null
) returns uuid
language plpgsql security definer set search_path=public as $$
declare
  v_id uuid;
  v_sender_name text;
  v_label text;
  v_hour_count integer;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if p_recipient_user_id is null then raise exception 'Joueur destinataire requis.'; end if;
  if p_recipient_user_id=auth.uid() then raise exception 'Tu ne peux pas t’envoyer une réaction à toi-même.'; end if;
  if p_emoji not in ('👏','🔥','😂','😱','🦉','🏆','💀','❤️') then raise exception 'Réaction non autorisée.'; end if;
  if not exists(select 1 from public.profiles where id=p_recipient_user_id and status='active') then
    raise exception 'Ce joueur n’est pas disponible.';
  end if;

  -- Anti-spam léger : pas deux réactions en rafale et plafond généreux à l'heure.
  if exists(
    select 1 from public.player_reactions
    where sender_user_id=auth.uid() and created_at>now()-interval '8 seconds'
  ) then raise exception 'Doucement sur les plumes : attends quelques secondes.'; end if;

  select count(*) into v_hour_count
  from public.player_reactions
  where sender_user_id=auth.uid() and created_at>now()-interval '1 hour';
  if v_hour_count>=30 then raise exception 'Le Hibou a rangé les confettis : limite de réactions atteinte pour cette heure.'; end if;

  insert into public.player_reactions(season_id,sender_user_id,recipient_user_id,emoji)
  values(p_season_id,auth.uid(),p_recipient_user_id,p_emoji)
  returning id into v_id;

  select username::text into v_sender_name from public.profiles where id=auth.uid();
  v_label:=case p_emoji
    when '👏' then 'Bien joué'
    when '🔥' then 'En feu'
    when '😂' then 'MDR'
    when '😱' then 'Incroyable'
    when '🦉' then 'Hibou'
    when '🏆' then 'Champion'
    when '💀' then 'Ça pique'
    when '❤️' then 'Respect'
    else 'Réaction'
  end;

  perform public.create_notification_v060(
    p_recipient_user_id,
    p_season_id,
    'social',
    p_emoji||' '||coalesce(v_sender_name,'Un joueur')||' réagit',
    v_label||' · réaction rapide du Nid.',
    'info',
    'player:'||auth.uid()::text,
    jsonb_build_object('sender_user_id',auth.uid(),'emoji',p_emoji,'reaction_id',v_id),
    true,
    null
  );

  return v_id;
end;
$$;

grant execute on function public.send_player_reaction_v062(uuid,text,uuid) to authenticated;

insert into public.app_settings(key,value)
values ('app_version','"0.6.2"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

commit;
-- Le Nid des Champions — V0.6.4
-- Correctif Web Push :
-- - réattribution sûre d'un abonnement navigateur lors d'un changement de compte ;
-- - envoi immédiat centralisé pour toute notification push non programmée ;
-- - test Cron Super Admin à heure réglable ;
-- - réveil Cron toutes les minutes.
-- À exécuter avec le rôle postgres dans Supabase SQL Editor après V0.6.2.

begin;

create extension if not exists pg_net;
create extension if not exists pg_cron;

-- -----------------------------------------------------------------------------
-- 1. Enregistrement sûr de l'appareil Push du compte connecté.
-- Le navigateur peut réutiliser le même endpoint quand un autre compte se connecte
-- sur le même profil Chrome. On autorise le transfert uniquement si les deux clés
-- cryptographiques de l'abonnement sont identiques à celles déjà enregistrées.
-- -----------------------------------------------------------------------------
create or replace function public.register_my_push_subscription_v064(
  p_endpoint text,
  p_p256dh text,
  p_auth_key text,
  p_device_name text default null,
  p_user_agent text default null,
  p_platform text default null
) returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_uid uuid := auth.uid();
  v_existing public.push_subscriptions%rowtype;
  v_id uuid;
begin
  if v_uid is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=v_uid and status='active') then
    raise exception 'Compte inactif.';
  end if;
  if nullif(trim(p_endpoint),'') is null or nullif(trim(p_p256dh),'') is null or nullif(trim(p_auth_key),'') is null then
    raise exception 'Abonnement Push incomplet.';
  end if;

  select * into v_existing
  from public.push_subscriptions
  where endpoint=trim(p_endpoint)
  for update;

  if found then
    if v_existing.user_id is distinct from v_uid
       and (v_existing.p256dh is distinct from p_p256dh or v_existing.auth_key is distinct from p_auth_key) then
      raise exception 'Cet abonnement Push appartient à un autre appareil.';
    end if;

    update public.push_subscriptions
    set user_id=v_uid,
        p256dh=p_p256dh,
        auth_key=p_auth_key,
        device_name=nullif(trim(p_device_name),''),
        user_agent=p_user_agent,
        platform=p_platform,
        active=true,
        disabled_at=null,
        failure_count=0,
        last_failure_at=null,
        updated_at=now()
    where id=v_existing.id
    returning id into v_id;
  else
    insert into public.push_subscriptions(
      user_id,endpoint,p256dh,auth_key,device_name,user_agent,platform,active
    ) values(
      v_uid,trim(p_endpoint),p_p256dh,p_auth_key,nullif(trim(p_device_name),''),p_user_agent,p_platform,true
    ) returning id into v_id;
  end if;

  return v_id;
end;
$$;

revoke all on function public.register_my_push_subscription_v064(text,text,text,text,text,text) from public,anon;
grant execute on function public.register_my_push_subscription_v064(text,text,text,text,text,text) to authenticated;

-- RLS reste stricte : un utilisateur ne lit/modifie directement que ses appareils.
drop policy if exists push_subscriptions_own on public.push_subscriptions;
drop policy if exists push_subscriptions_own_select_v064 on public.push_subscriptions;
drop policy if exists push_subscriptions_own_insert_v064 on public.push_subscriptions;
drop policy if exists push_subscriptions_own_update_v064 on public.push_subscriptions;
drop policy if exists push_subscriptions_own_delete_v064 on public.push_subscriptions;

create policy push_subscriptions_own_select_v064 on public.push_subscriptions
for select to authenticated
using(user_id=auth.uid() or public.is_super_admin());

create policy push_subscriptions_own_insert_v064 on public.push_subscriptions
for insert to authenticated
with check(user_id=auth.uid() or public.is_super_admin());

create policy push_subscriptions_own_update_v064 on public.push_subscriptions
for update to authenticated
using(user_id=auth.uid() or public.is_super_admin())
with check(user_id=auth.uid() or public.is_super_admin());

create policy push_subscriptions_own_delete_v064 on public.push_subscriptions
for delete to authenticated
using(user_id=auth.uid() or public.is_super_admin());

-- -----------------------------------------------------------------------------
-- 2. Envoi immédiat centralisé.
-- Toute notification avec push_requested=true et sans push_not_before appelle
-- push-dispatch dès le COMMIT. Si Vault/pg_net sont momentanément indisponibles,
-- la notification reste en attente et le Cron joue le rôle de filet de secours.
-- -----------------------------------------------------------------------------
create or replace function public.dispatch_immediate_push_v064()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  v_url text;
  v_secret text;
begin
  if new.push_requested is distinct from true
     or new.push_sent_at is not null
     or new.push_not_before is not null then
    return new;
  end if;

  begin
    select decrypted_secret into v_url
    from vault.decrypted_secrets
    where name='nid_push_dispatch_url'
    limit 1;

    select decrypted_secret into v_secret
    from vault.decrypted_secrets
    where name='nid_push_cron_secret'
    limit 1;

    if coalesce(v_url,'')<>'' and coalesce(v_secret,'')<>'' then
      perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
          'Content-Type','application/json',
          'x-cron-secret',v_secret
        ),
        body := jsonb_build_object(
          'action','dispatch-one',
          'notification_id',new.id
        )
      );
    end if;
  exception when others then
    -- Ne jamais faire échouer l'action métier à cause du transport Push.
    null;
  end;

  return new;
end;
$$;

revoke all on function public.dispatch_immediate_push_v064() from public,anon,authenticated;

drop trigger if exists dispatch_immediate_push_v064 on public.notifications;
create trigger dispatch_immediate_push_v064
after insert on public.notifications
for each row
when (new.push_requested = true and new.push_not_before is null)
execute function public.dispatch_immediate_push_v064();

-- -----------------------------------------------------------------------------
-- 3. Test Cron Super Admin.
-- L'enregistrement seul ne déclenche aucun Push immédiat grâce à push_not_before.
-- C'est donc bien le Cron qui devra récupérer et livrer cette notification.
-- -----------------------------------------------------------------------------
create or replace function public.admin_schedule_cron_test_v064(
  p_scheduled_at timestamptz,
  p_title text default '🦉 Test Cron du Nid',
  p_body text default 'Le réveil du Hibou fonctionne correctement.'
) returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_id uuid;
  v_when timestamptz := date_trunc('minute',p_scheduled_at);
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if v_when <= now() then raise exception 'Choisis une heure future.'; end if;
  if v_when > now()+interval '48 hours' then raise exception 'Le test Cron doit être programmé dans les 48 prochaines heures.'; end if;

  insert into public.notifications(
    user_id,season_id,category,title,body,importance,deep_link,payload,
    source_key,push_requested,push_not_before,expires_at,created_by
  ) values(
    auth.uid(),null,'system',left(trim(p_title),160),left(trim(p_body),2000),'important','home',
    jsonb_build_object('cron_test',true,'scheduled_at',v_when),
    'cron-test:'||auth.uid()::text||':'||extract(epoch from v_when)::bigint::text||':'||gen_random_uuid()::text,
    true,v_when,v_when+interval '15 minutes',auth.uid()
  ) returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.admin_schedule_cron_test_v064(timestamptz,text,text) from public,anon;
grant execute on function public.admin_schedule_cron_test_v064(timestamptz,text,text) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. Le Cron vérifie désormais chaque minute les événements programmés.
-- On conserve le même nom de job afin de remplacer proprement l'ancien */15.
-- -----------------------------------------------------------------------------
do $$
declare
  v_jobid bigint;
  v_has_url boolean;
  v_has_secret boolean;
begin
  select exists(select 1 from vault.decrypted_secrets where name='nid_push_dispatch_url') into v_has_url;
  select exists(select 1 from vault.decrypted_secrets where name='nid_push_cron_secret') into v_has_secret;

  if v_has_url and v_has_secret then
    select jobid into v_jobid from cron.job where jobname='nid-champions-push-v060' limit 1;
    if v_jobid is not null then perform cron.unschedule(v_jobid); end if;

    perform cron.schedule(
      'nid-champions-push-v060',
      '* * * * *',
      $job$
      select net.http_post(
        url := (select decrypted_secret from vault.decrypted_secrets where name='nid_push_dispatch_url'),
        headers := jsonb_build_object(
          'Content-Type','application/json',
          'x-cron-secret',(select decrypted_secret from vault.decrypted_secrets where name='nid_push_cron_secret')
        ),
        body := '{"action":"run"}'::jsonb
      );
      $job$
    );
  end if;
end $$;

insert into public.app_settings(key,value)
values ('app_version','"0.6.4"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

-- Vérifications finales uniquement : pas de SELECT intermédiaire trompeur.
select key,value from public.app_settings where key='app_version';
select jobid,jobname,schedule,active from cron.job where jobname='nid-champions-push-v060';


-- Le Nid des Champions — V0.6.7
-- Laboratoire Super Admin : calendrier TEST configurable.

begin;

alter table public.matchdays add column if not exists is_test boolean not null default false;
alter table public.matchdays add column if not exists test_enabled boolean not null default true;

alter table public.matches add column if not exists is_test boolean not null default false;
alter table public.matches add column if not exists test_enabled boolean not null default true;
alter table public.matches add column if not exists venue_country text;

create index if not exists matchdays_test_idx on public.matchdays(season_id,is_test,test_enabled,number);
create index if not exists matches_test_idx on public.matches(season_id,is_test,test_enabled,kickoff_at);

-- Les matchs TEST ne ferment jamais les choix champion et ne font jamais
-- avancer artificiellement la phase de ligue.
create or replace function public.champion_first_close_at_v040(p_season_id uuid)
returns timestamptz language sql stable security definer set search_path=public as $$
  select min(m.kickoff_at)
  from public.matches m
  join public.competition_phases ph on ph.id=m.phase_id
  where m.season_id=p_season_id
    and ph.code='LEAGUE'
    and m.status not in ('cancelled','postponed')
    and coalesce(m.is_test,false)=false;
$$;

create or replace function public.league_phase_finished_v040(p_season_id uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.matches m join public.competition_phases ph on ph.id=m.phase_id
    where m.season_id=p_season_id and ph.code='LEAGUE' and m.status<>'cancelled' and coalesce(m.is_test,false)=false
  ) and not exists(
    select 1 from public.matches m join public.competition_phases ph on ph.id=m.phase_id
    where m.season_id=p_season_id and ph.code='LEAGUE' and m.status not in ('finished','cancelled') and coalesce(m.is_test,false)=false
  );
$$;

-- Les matchs TEST restent pronostiquables mais sont exclus des classements officiels.
create or replace function public.get_leaderboard_v030(
  p_season_id uuid,
  p_scope text default 'general',
  p_matchday_id uuid default null,
  p_evening_date date default null,
  p_include_live boolean default true
)
returns table (
  rank bigint,
  previous_rank bigint,
  variation bigint,
  user_id uuid,
  username text,
  avatar_key text,
  club_heart text,
  points numeric,
  official_points numeric,
  exact_scores bigint,
  good_differences bigint,
  good_results bigint,
  played bigint,
  average numeric,
  precision_pct numeric,
  above_gap numeric,
  below_gap numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with params as (
    select coalesce(
      p_evening_date,
      (
        select max((m.kickoff_at at time zone 'Europe/Paris')::date)
        from public.matches m
        where m.season_id = p_season_id
          and m.status in ('live','finished')
          and coalesce(m.is_test,false)=false
      ),
      (now() at time zone 'Europe/Paris')::date
    ) as reference_date
  ),
  scope_matches as (
    select m.*
    from public.matches m, params pa
    where m.season_id = p_season_id
      and coalesce(m.is_test,false)=false
      and (
        p_scope = 'general'
        or (p_scope = 'matchday' and p_matchday_id is not null and m.matchday_id = p_matchday_id)
        or (p_scope = 'evening' and (m.kickoff_at at time zone 'Europe/Paris')::date = coalesce(p_evening_date, pa.reference_date))
      )
  ),
  stats as (
    select
      pr.id as user_id,
      pr.username::text as username,
      pr.avatar_key,
      pr.club_heart,
      coalesce(sum(
        case
          when m.id is null or p.id is null then 0
          when m.status = 'finished' then p.points
          when p_include_live and m.status = 'live' and m.home_score is not null and m.away_score is not null
            then public.score_prediction_values_v030(p_season_id,p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier)
          else 0
        end
      ),0)::numeric as points,
      coalesce(sum(case when m.status='finished' then p.points else 0 end),0)::numeric as official_points,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
          and p.home_score=m.home_score and p.away_score=m.away_score
      ) as exact_scores,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
          and not (p.home_score=m.home_score and p.away_score=m.away_score)
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
          and (p.home_score-p.away_score)=(m.home_score-m.away_score)
      ) as good_differences,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
      ) as good_results,
      count(*) filter (
        where p.id is not null
          and (m.status='finished' or (p_include_live and m.status='live'))
          and m.home_score is not null and m.away_score is not null
      ) as played
    from public.profiles pr
    left join public.predictions p
      on p.user_id = pr.id and p.season_id = p_season_id
    left join scope_matches m on m.id = p.match_id
    where pr.status = 'active'
    group by pr.id,pr.username,pr.avatar_key,pr.club_heart
  ),
  scored as (
    select
      s.*,
      case when played>0 then points/played else 0 end::numeric as average,
      case when played>0 then round((good_results::numeric*100)/played,1) else 0 end::numeric as precision_pct
    from stats s
  ),
  current_ranked as (
    select
      row_number() over(
        order by points desc, exact_scores desc, average desc, good_differences desc, played desc, username asc
      ) as rank,
      *
    from scored
  ),
  baseline_stats as (
    select
      pr.id as user_id,
      pr.username::text as username,
      coalesce(sum(case when m.status='finished' then p.points else 0 end),0)::numeric as points,
      count(*) filter (
        where m.status='finished' and p.id is not null
          and p.home_score=m.home_score and p.away_score=m.away_score
      ) as exact_scores,
      count(*) filter (
        where m.status='finished' and p.id is not null
          and not (p.home_score=m.home_score and p.away_score=m.away_score)
          and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)
          and (p.home_score-p.away_score)=(m.home_score-m.away_score)
      ) as good_differences,
      count(*) filter (where m.status='finished' and p.id is not null) as played
    from public.profiles pr
    left join public.predictions p
      on p.user_id=pr.id and p.season_id=p_season_id
    left join public.matches m
      on m.id=p.match_id
      and m.season_id=p_season_id
      and coalesce(m.is_test,false)=false
      and (m.kickoff_at at time zone 'Europe/Paris')::date < (select reference_date from params)
    where pr.status='active'
    group by pr.id,pr.username
  ),
  baseline_scored as (
    select *, case when played>0 then points/played else 0 end::numeric as average
    from baseline_stats
  ),
  baseline_ranked as (
    select user_id,
      row_number() over(
        order by points desc, exact_scores desc, average desc, good_differences desc, played desc, username asc
      ) as previous_rank
    from baseline_scored
  ),
  joined as (
    select
      c.*,
      case when p_scope='general' then b.previous_rank else null end as previous_rank
    from current_ranked c
    left join baseline_ranked b on b.user_id=c.user_id
  ),
  neighbors as (
    select
      j.*,
      lag(points) over(order by rank) as above_points,
      lead(points) over(order by rank) as below_points
    from joined j
  )
  select
    rank,
    previous_rank,
    case when previous_rank is null then 0 else previous_rank-rank end as variation,
    user_id,username,avatar_key,club_heart,
    points,official_points,exact_scores,good_differences,good_results,played,
    round(average,2) as average,
    precision_pct,
    case when above_points is null then null else above_points-points end as above_gap,
    case when below_points is null then null else points-below_points end as below_gap
  from neighbors
  order by rank;
$$;

grant execute on function public.get_leaderboard_v030(uuid,text,uuid,date,boolean) to authenticated;

create or replace function public.get_collective_stats_v030(
  p_season_id uuid,
  p_scope text default 'general',
  p_matchday_id uuid default null,
  p_evening_date date default null
)
returns table (
  total_predictions bigint,
  home_picks bigint,
  draw_picks bigint,
  away_picks bigint,
  top_scores jsonb,
  exact_predictions bigint,
  settled_predictions bigint,
  reliability_pct numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with reference as (
    select coalesce(
      p_evening_date,
      (
        select max((m.kickoff_at at time zone 'Europe/Paris')::date)
        from public.matches m
        where m.season_id=p_season_id and m.status in ('live','finished') and coalesce(m.is_test,false)=false
      ),
      (now() at time zone 'Europe/Paris')::date
    ) as evening_date
  ),
  scoped_matches as (
    select m.*
    from public.matches m, reference r
    where m.season_id=p_season_id
      and coalesce(m.is_test,false)=false
      and (
        p_scope='general'
        or (p_scope='matchday' and p_matchday_id is not null and m.matchday_id=p_matchday_id)
        or (p_scope='evening' and (m.kickoff_at at time zone 'Europe/Paris')::date=coalesce(p_evening_date,r.evening_date))
      )
      and (m.status in ('live','finished') or (m.status in ('scheduled','postponed') and m.kickoff_at<=now()))
  ),
  locked_predictions as (
    select p.*,m.status,m.home_score as result_home,m.away_score as result_away
    from public.predictions p
    join scoped_matches m on m.id=p.match_id
    join public.profiles pr on pr.id=p.user_id and pr.status='active'
  ),
  score_counts as (
    select home_score,away_score,count(*)::bigint as n
    from locked_predictions
    group by home_score,away_score
    order by n desc,home_score asc,away_score asc
    limit 5
  ),
  aggregates as (
    select
      count(*)::bigint as total_predictions,
      count(*) filter(where home_score>away_score)::bigint as home_picks,
      count(*) filter(where home_score=away_score)::bigint as draw_picks,
      count(*) filter(where home_score<away_score)::bigint as away_picks,
      count(*) filter(
        where status in ('live','finished') and result_home is not null and result_away is not null
          and home_score=result_home and away_score=result_away
      )::bigint as exact_predictions,
      count(*) filter(
        where status in ('live','finished') and result_home is not null and result_away is not null
      )::bigint as settled_predictions,
      count(*) filter(
        where status in ('live','finished') and result_home is not null and result_away is not null
          and sign(home_score-away_score)=sign(result_home-result_away)
      )::bigint as correct_results
    from locked_predictions
  )
  select
    a.total_predictions,a.home_picks,a.draw_picks,a.away_picks,
    coalesce((select jsonb_agg(jsonb_build_object('score',home_score::text || '–' || away_score::text,'count',n) order by n desc,home_score,away_score) from score_counts),'[]'::jsonb) as top_scores,
    a.exact_predictions,a.settled_predictions,
    case when a.settled_predictions>0 then round((a.correct_results::numeric*100)/a.settled_predictions,1) else 0 end::numeric as reliability_pct
  from aggregates a;
$$;

grant execute on function public.get_collective_stats_v030(uuid,text,uuid,date) to authenticated;

-- Classement Teams : les rencontres TEST ne rapportent jamais de points officiels.
create or replace function public.get_team_leaderboard_v050(p_season_id uuid,p_matchday_id uuid default null)
returns table(
  team_id uuid,team_name text,logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  current_members bigint,contributors bigint,total_points numeric,average_points numeric,top3_points numeric,rank_average bigint,rank_top3 bigint
)
language sql stable security definer set search_path=public as $$
with match_points as (
  select tm.team_id,p.user_id,sum(p.points)::numeric as pts
  from public.predictions p
  join public.matches m on m.id=p.match_id
  left join public.matchdays md on md.id=m.matchday_id
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=p.user_id
    and m.kickoff_at>=tm.joined_at and (tm.left_at is null or m.kickoff_at<tm.left_at)
  where p.season_id=p_season_id and m.status='finished' and coalesce(m.is_test,false)=false
    and (p_matchday_id is null or m.matchday_id=p_matchday_id)
    and (md.number is null or md.number<>0)
  group by tm.team_id,p.user_id
), qualifier_points as (
  select tm.team_id,tp.user_id,sum(case when kt.status='finished' and kt.qualified_club_id=tp.qualified_club_id then case when tp.pick_timing='early' then kt.qualifier_bonus_early else kt.qualifier_bonus_late end else 0 end)::numeric as pts
  from public.tie_predictions tp
  join public.knockout_ties kt on kt.id=tp.tie_id
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=tp.user_id
    and (case when kt.is_single_match then kt.leg1_kickoff_at else kt.leg2_kickoff_at end)>=tm.joined_at
    and (tm.left_at is null or (case when kt.is_single_match then kt.leg1_kickoff_at else kt.leg2_kickoff_at end)<tm.left_at)
  where tp.season_id=p_season_id and p_matchday_id is null
  group by tm.team_id,tp.user_id
), champion_points as (
  select tm.team_id,cp.user_id,sum(cp.points)::numeric as pts
  from public.champion_predictions cp
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=cp.user_id
    and coalesce(cp.locked_at,cp.updated_at)>=tm.joined_at and (tm.left_at is null or coalesce(cp.locked_at,cp.updated_at)<tm.left_at)
  where cp.season_id=p_season_id and p_matchday_id is null and cp.points<>0
  group by tm.team_id,cp.user_id
), user_team_points as (
  select team_id,user_id,sum(pts)::numeric as pts from (
    select * from match_points union all select * from qualifier_points union all select * from champion_points
  ) q group by team_id,user_id
), active_zero as (
  select tm.team_id,tm.user_id,0::numeric pts from public.team_memberships tm join public.teams t on t.id=tm.team_id
  where tm.season_id=p_season_id and tm.left_at is null and t.status='active'
), players as (
  select team_id,user_id,sum(pts)::numeric pts from (
    select * from user_team_points union all select * from active_zero
  ) q group by team_id,user_id
), team_stats as (
  select t.id team_id,t.name team_name,t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    (select count(*) from public.team_memberships x where x.team_id=t.id and x.left_at is null)::bigint current_members,
    count(p.user_id)::bigint contributors,coalesce(sum(p.pts),0)::numeric total_points,coalesce(avg(p.pts),0)::numeric average_points,
    coalesce((select sum(z.pts) from (select p2.pts from players p2 where p2.team_id=t.id order by p2.pts desc limit 3) z),0)::numeric top3_points
  from public.teams t left join players p on p.team_id=t.id
  where t.season_id=p_season_id and t.status='active'
  group by t.id
), ranked as (
  select s.*,
    row_number() over(order by average_points desc,top3_points desc,total_points desc,team_name)::bigint rank_average,
    row_number() over(order by top3_points desc,average_points desc,total_points desc,team_name)::bigint rank_top3
  from team_stats s
)
select * from ranked order by rank_average;
$$;

-- =============================================================================
-- 8. RLS + privilèges
-- =============================================================================
alter table public.teams enable row level security;
alter table public.team_memberships enable row level security;
alter table public.team_join_requests enable row level security;
alter table public.team_invites enable row level security;
alter table public.team_events enable row level security;

drop policy if exists teams_read on public.teams;
create policy teams_read on public.teams for select using(true);

drop policy if exists team_memberships_read on public.team_memberships;
create policy team_memberships_read on public.team_memberships for select using(true);

drop policy if exists team_requests_own_or_captain on public.team_join_requests;
create policy team_requests_own_or_captain on public.team_join_requests for select to authenticated using(
  user_id=auth.uid() or public.is_admin() or public.is_team_captain_v050(team_id)
);

drop policy if exists team_invites_captain_read on public.team_invites;
create policy team_invites_captain_read on public.team_invites for select to authenticated using(public.is_admin() or public.is_team_captain_v050(team_id));

drop policy if exists team_events_read on public.team_events;
create policy team_events_read on public.team_events for select using(true);

revoke all on public.teams,public.team_memberships,public.team_join_requests,public.team_invites,public.team_events from anon,authenticated;
grant select on public.teams,public.team_memberships,public.team_events to anon,authenticated;
grant select on public.team_join_requests,public.team_invites to authenticated;

grant execute on function public.is_team_captain_v050(uuid) to authenticated;
grant execute on function public.current_team_id_v050(uuid,uuid) to authenticated;
grant execute on function public.create_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.update_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.join_public_team_v050(uuid) to authenticated;
grant execute on function public.request_team_join_v050(uuid) to authenticated;
grant execute on function public.process_team_join_request_v050(uuid,boolean) to authenticated;
grant execute on function public.regenerate_team_invite_v050(uuid) to authenticated;
grant execute on function public.join_team_by_code_v050(uuid,text) to authenticated;
grant execute on function public.leave_team_v050(uuid) to authenticated;
grant execute on function public.kick_team_member_v050(uuid,uuid) to authenticated;
grant execute on function public.transfer_team_captain_v050(uuid,uuid) to authenticated;
grant execute on function public.dissolve_team_v050(uuid) to authenticated;
grant execute on function public.get_team_directory_v050(uuid) to anon,authenticated;
grant execute on function public.get_my_team_v050(uuid) to authenticated;
grant execute on function public.get_team_member_directory_v050(uuid) to authenticated;
grant execute on function public.get_team_members_v050(uuid) to authenticated;
grant execute on function public.get_team_history_v050(uuid) to authenticated;
grant execute on function public.get_team_join_requests_v050(uuid) to authenticated;
grant execute on function public.get_team_active_invite_v050(uuid) to authenticated;
grant execute on function public.get_team_leaderboard_v050(uuid,uuid) to anon,authenticated;

create or replace function public.admin_create_test_schedule_v067(p_season_id uuid,p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_phase uuid;
  v_base_number integer;
  v_day jsonb;
  v_match jsonb;
  v_day_id uuid;
  v_day_idx integer:=0;
  v_match_count integer:=0;
  v_first timestamptz;
  v_last timestamptz;
  v_home uuid;
  v_away uuid;
  v_kickoff timestamptz;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_season_id is null then raise exception 'Saison manquante.'; end if;
  if jsonb_typeof(p_payload->'days')<>'array' or jsonb_array_length(p_payload->'days')<>2 then
    raise exception 'Le laboratoire attend exactement 2 journées TEST.';
  end if;

  select id into v_phase from public.competition_phases where season_id=p_season_id and code='LEAGUE' limit 1;

  -- Remplace uniquement l'ancien calendrier TEST V0.6.7.
  delete from public.matches where season_id=p_season_id and is_test=true;
  delete from public.matchdays where season_id=p_season_id and is_test=true;

  select coalesce(max(number),0) into v_base_number from public.matchdays where season_id=p_season_id;

  for v_day in select value from jsonb_array_elements(p_payload->'days') loop
    v_day_idx:=v_day_idx+1;
    if jsonb_typeof(v_day->'matches')<>'array' or jsonb_array_length(v_day->'matches')<1 then
      raise exception 'La journée TEST % doit contenir au moins un match.',v_day_idx;
    end if;

    select min((x->>'kickoff_at')::timestamptz),max((x->>'kickoff_at')::timestamptz)
      into v_first,v_last from jsonb_array_elements(v_day->'matches') x;

    insert into public.matchdays(season_id,phase_id,number,name,starts_at,ends_at,is_test,test_enabled)
    values(p_season_id,v_phase,v_base_number+v_day_idx,coalesce(nullif(v_day->>'name',''),'TEST — Journée '||v_day_idx),v_first,v_last,true,true)
    returning id into v_day_id;

    for v_match in select value from jsonb_array_elements(v_day->'matches') loop
      v_home:=(v_match->>'home_club_id')::uuid;
      v_away:=(v_match->>'away_club_id')::uuid;
      v_kickoff:=(v_match->>'kickoff_at')::timestamptz;
      if v_home=v_away then raise exception 'Une équipe ne peut pas jouer contre elle-même.'; end if;
      if not exists(select 1 from public.clubs where id=v_home and is_active=true) then raise exception 'Club domicile invalide.'; end if;
      if not exists(select 1 from public.clubs where id=v_away and is_active=true) then raise exception 'Club extérieur invalide.'; end if;

      insert into public.matches(season_id,phase_id,matchday_id,home_club_id,away_club_id,kickoff_at,stadium,venue_country,status,data_source,is_test,test_enabled)
      values(p_season_id,v_phase,v_day_id,v_home,v_away,v_kickoff,nullif(v_match->>'stadium',''),nullif(v_match->>'country',''),'scheduled','manual',true,true);
      v_match_count:=v_match_count+1;
    end loop;
  end loop;

  return jsonb_build_object('ok',true,'days_created',2,'matches_created',v_match_count);
end;
$$;

grant execute on function public.admin_create_test_schedule_v067(uuid,jsonb) to authenticated;

create or replace function public.admin_set_test_schedule_enabled_v067(p_season_id uuid,p_enabled boolean)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_count integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  update public.matchdays set test_enabled=p_enabled where season_id=p_season_id and is_test=true;
  if not p_enabled then
    update public.notifications n
       set push_requested=false,deleted_at=coalesce(deleted_at,now())
     where n.season_id=p_season_id
       and n.push_sent_at is null
       and n.deleted_at is null
       and (n.payload->>'matchday_id') in (select id::text from public.matchdays where season_id=p_season_id and is_test=true);
  end if;
  update public.matches
     set test_enabled=p_enabled,
         status=case when p_enabled then 'scheduled' else 'cancelled' end,
         home_score=null,
         away_score=null,
         went_to_extra_time=false,
         penalties_home=null,
         penalties_away=null,
         winner_club_id=null,
         updated_at=now()
   where season_id=p_season_id and is_test=true;
  get diagnostics v_count=row_count;
  return jsonb_build_object('ok',true,'enabled',p_enabled,'matches_updated',v_count);
end;
$$;

grant execute on function public.admin_set_test_schedule_enabled_v067(uuid,boolean) to authenticated;

create or replace function public.admin_delete_test_schedule_v067(p_season_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_matches integer:=0;v_days integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  delete from public.matches where season_id=p_season_id and is_test=true;
  get diagnostics v_matches=row_count;
  delete from public.matchdays where season_id=p_season_id and is_test=true;
  get diagnostics v_days=row_count;
  return jsonb_build_object('ok',true,'matches_deleted',v_matches,'matchdays_deleted',v_days);
end;
$$;

grant execute on function public.admin_delete_test_schedule_v067(uuid) to authenticated;

create or replace function public.admin_delete_all_matches_v067(p_season_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_matches integer:=0;v_days integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  -- Supprime absolument toutes les rencontres de la saison : cela inclut les
  -- anciens matchs de test initiaux même s'ils n'avaient pas encore is_test=true.
  delete from public.matches where season_id=p_season_id;
  get diagnostics v_matches=row_count;
  delete from public.matchdays where season_id=p_season_id;
  get diagnostics v_days=row_count;
  return jsonb_build_object('ok',true,'matches_deleted',v_matches,'matchdays_deleted',v_days);
end;
$$;

grant execute on function public.admin_delete_all_matches_v067(uuid) to authenticated;

insert into public.app_settings(key,value)
values('app_version','"0.6.7"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

commit;

select key,value from public.app_settings where key='app_version';

-- Le Nid des Champions — V0.7.0
-- Badges extensibles, records, casseroles, Génie, Musée, laboratoire et LIVE robuste.

begin;

-- -----------------------------------------------------------------------------
-- 1. Notifications gamification
-- -----------------------------------------------------------------------------
alter table public.notification_preferences add column if not exists category_badges boolean not null default true;
alter table public.notification_preferences add column if not exists category_records boolean not null default true;
alter table public.notification_preferences add column if not exists category_gamification boolean not null default true;

alter table public.notifications drop constraint if exists notifications_category_check;
alter table public.notifications add constraint notifications_category_check check (category in ('matches','champion','results','rival','team','owl','system','ranking','support','social','badge','record','gamification'));

-- -----------------------------------------------------------------------------
-- 2. Catalogue des badges (illimité, les 100 historiques ne sont que le seed)
-- -----------------------------------------------------------------------------
create table if not exists public.gamification_badges (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null default '',
  category text not null default 'performance',
  rarity text not null default 'common' check (rarity in ('common','rare','epic','legendary','secret')),
  is_secret boolean not null default false,
  secret_visibility text not null default 'public' check (secret_visibility in ('public','listed','hidden')),
  scope text not null default 'season' check (scope in ('season','career')),
  image_url text,
  default_asset_path text,
  condition_json jsonb not null default '{"manual":true}'::jsonb,
  auto_evaluate boolean not null default false,
  retro_mode text not null default 'season' check (retro_mode in ('none','season','career')),
  active boolean not null default true,
  archived_at timestamptz,
  sort_order integer not null default 1000,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists gamification_badges_active_idx on public.gamification_badges(active,rarity,sort_order);
drop trigger if exists gamification_badges_updated_at on public.gamification_badges;
create trigger gamification_badges_updated_at before update on public.gamification_badges for each row execute function public.set_updated_at();

create table if not exists public.player_badges (
  id uuid primary key default gen_random_uuid(),
  badge_id uuid not null references public.gamification_badges(id) on delete restrict,
  user_id uuid not null references public.profiles(id) on delete cascade,
  season_id uuid references public.seasons(id) on delete cascade,
  earned_at timestamptz not null default now(),
  context jsonb not null default '{}'::jsonb,
  source text not null default 'automatic' check (source in ('automatic','manual','migration','test')),
  is_test boolean not null default false,
  first_discovery boolean not null default false,
  awarded_by uuid references public.profiles(id) on delete set null,
  revoked_at timestamptz,
  revoked_by uuid references public.profiles(id) on delete set null,
  revoke_reason text
);
create unique index if not exists player_badges_unique_active_idx on public.player_badges(badge_id,user_id,coalesce(season_id,'00000000-0000-0000-0000-000000000000'::uuid),is_test) where revoked_at is null;
create index if not exists player_badges_user_idx on public.player_badges(user_id,season_id,earned_at desc);

-- -----------------------------------------------------------------------------
-- 3. Événements parallèles : Casseroles / Génie / narration
-- -----------------------------------------------------------------------------
create table if not exists public.gamification_events (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null check (event_type in ('casserole','genius','narrative','award')),
  subtype text not null default 'generic',
  severity text check (severity is null or severity in ('small','beautiful','industrial','nuclear','inspiration','nice','brilliant','prophetic')),
  points integer not null default 0,
  match_id uuid references public.matches(id) on delete set null,
  matchday_id uuid references public.matchdays(id) on delete set null,
  title text,
  message text,
  media_url text,
  labels jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  is_manual boolean not null default false,
  is_test boolean not null default false,
  is_public boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists gamification_events_auto_match_unique_idx on public.gamification_events(season_id,user_id,event_type,match_id,is_test) where is_manual=false and match_id is not null;
create index if not exists gamification_events_user_idx on public.gamification_events(user_id,season_id,event_type,is_test,created_at desc);
drop trigger if exists gamification_events_updated_at on public.gamification_events;
create trigger gamification_events_updated_at before update on public.gamification_events for each row execute function public.set_updated_at();

create table if not exists public.gamification_records (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  record_key text not null,
  record_name text not null,
  category text not null default 'performance',
  scope text not null default 'nid' check (scope in ('nid','personal')),
  user_id uuid not null references public.profiles(id) on delete cascade,
  value numeric not null,
  previous_value numeric,
  match_id uuid references public.matches(id) on delete set null,
  matchday_id uuid references public.matchdays(id) on delete set null,
  achieved_at timestamptz not null default now(),
  is_test boolean not null default false,
  is_equal boolean not null default false,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb
);
create index if not exists gamification_records_key_idx on public.gamification_records(season_id,record_key,is_test,achieved_at desc);
create index if not exists gamification_records_user_idx on public.gamification_records(user_id,season_id,is_test,achieved_at desc);

create table if not exists public.gamification_settings (
  season_id uuid primary key references public.seasons(id) on delete cascade,
  test_enabled boolean not null default false,
  casserole_thresholds jsonb not null default '{"small":3,"beautiful":4,"industrial":6,"nuclear":8}'::jsonb,
  casserole_points jsonb not null default '{"small":1,"beautiful":3,"industrial":5,"nuclear":10}'::jsonb,
  casserole_rules jsonb not null default '{"zero_small":3,"zero_beautiful":5,"zero_nuclear":8,"full_matchday_severity":"industrial"}'::jsonb,
  champion_casserole_phases jsonb not null default '{"KNOCKOUT_PLAYOFF":"beautiful","ROUND_OF_16":"small","QUARTER_FINAL":"none","SEMI_FINAL":"none","FINAL":"none"}'::jsonb,
  genius_thresholds jsonb not null default '{"minimum_predictions":5,"p20":1,"p10":3,"p5":5,"p2":7,"unique":10,"exact_bonus":2,"max":10}'::jsonb,
  record_thresholds jsonb not null default '{"precision_evening":5,"precision_period":20,"precision_season":30}'::jsonb,
  record_categories jsonb not null default '["performance","precision","series","ranking","rivalries","casseroles","genius","unusual"]'::jsonb,
  secret_retro_notify boolean,
  closed_at timestamptz,
  closed_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.gamification_settings add column if not exists casserole_rules jsonb not null default '{"zero_small":3,"zero_beautiful":5,"zero_nuclear":8,"full_matchday_severity":"industrial"}'::jsonb;
alter table public.gamification_settings add column if not exists champion_casserole_phases jsonb not null default '{"KNOCKOUT_PLAYOFF":"beautiful","ROUND_OF_16":"small","QUARTER_FINAL":"none","SEMI_FINAL":"none","FINAL":"none"}'::jsonb;
alter table public.gamification_settings add column if not exists record_categories jsonb not null default '["performance","precision","series","ranking","rivalries","casseroles","genius","unusual"]'::jsonb;
insert into public.gamification_settings(season_id) select id from public.seasons on conflict(season_id) do nothing;

create table if not exists public.gamification_audit (
  id bigint generated always as identity primary key,
  season_id uuid references public.seasons(id) on delete set null,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  before_data jsonb,
  after_data jsonb,
  reason text,
  is_test boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.gamification_text_templates (
  id bigint generated always as identity primary key,
  event_key text not null,
  tone text not null default 'automatic' check (tone in ('sage','piquant','sans_pitie','automatic')),
  template text not null,
  weight numeric not null default 1,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(event_key,tone,template)
);
create index if not exists gamification_text_templates_key_idx on public.gamification_text_templates(event_key,tone,active);

-- -----------------------------------------------------------------------------
-- 4. Seed initial des 100 badges. Ils sont modifiables et de nouveaux badges
--    peuvent être ajoutés sans changer le schéma.
-- -----------------------------------------------------------------------------
insert into public.gamification_badges(code,name,description,category,rarity,is_secret,secret_visibility,scope,default_asset_path,condition_json,auto_evaluate,sort_order) values
('badge-premier-envol','Premier envol','Enregistrer son premier pronostic.','pronostics','common',false,'public','season','assets/badges/common/badge-common-premier-envol.png','{"metric":"predictions_count","op":">=","value":1}'::jsonb,true,1),
('badge-premiers-points','Premiers points','Marquer ses premiers points.','pronostics','common',false,'public','season','assets/badges/common/badge-common-premiers-points.png','{"metric":"total_points","op":">=","value":1}'::jsonb,true,2),
('badge-premier-exact','Dans le mille','Trouver son premier score exact.','scores','common',false,'public','season','assets/badges/common/badge-common-premier-exact.png','{"metric":"exact_scores","op":">=","value":1}'::jsonb,true,3),
('badge-journee-complete','Carnet rempli','Compléter tous les pronostics d''une journée UEFA.','assiduite','common',false,'public','season','assets/badges/common/badge-common-journee-complete.png','{"metric":"completed_matchdays","op":">=","value":1}'::jsonb,true,4),
('badge-premiere-team','Bienvenue dans la Team','Rejoindre sa première team.','team','common',false,'public','season','assets/badges/common/badge-common-premiere-team.png','{"metric":"team_memberships_count","op":">=","value":1}'::jsonb,true,5),
('badge-premier-duel','Premier duel','Gagner son premier duel contre son rival.','rival','common',false,'public','season','assets/badges/common/badge-common-premier-duel.png','{"metric":"rival_wins","op":">=","value":1}'::jsonb,true,6),
('badge-premiere-casserole','Ça commence bien','Recevoir sa première casserole.','casserole','common',false,'public','season','assets/badges/common/badge-common-premiere-casserole.png','{"metric":"casserole_count","op":">=","value":1}'::jsonb,true,7),
('badge-premier-genie','Éclair de génie','Obtenir son premier coup de génie.','genie','common',false,'public','season','assets/badges/common/badge-common-premier-genie.png','{"metric":"genius_count","op":">=","value":1}'::jsonb,true,8),
('badge-premier-hibou-solitaire','Hibou solitaire','Réussir son premier choix très minoritaire.','performance','common',false,'public','season','assets/badges/common/badge-common-premier-hibou-solitaire.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,9),
('badge-premier-record','Petit record','Détenir son premier mini-record.','records','common',false,'public','season','assets/badges/common/badge-common-premier-record.png','{"metric":"records_count","op":">=","value":1}'::jsonb,true,10),
('badge-cinq-pronos','On prend le rythme','Enregistrer 5 pronostics.','pronostics','common',false,'public','season','assets/badges/common/badge-common-cinq-pronos.png','{"metric":"predictions_count","op":">=","value":5}'::jsonb,true,11),
('badge-dix-pronos','Le carnet chauffe','Enregistrer 10 pronostics.','pronostics','common',false,'public','season','assets/badges/common/badge-common-dix-pronos.png','{"metric":"predictions_count","op":">=","value":10}'::jsonb,true,12),
('badge-vingt-pronos','Habitué du Nid','Enregistrer 20 pronostics.','pronostics','common',false,'public','season','assets/badges/common/badge-common-vingt-pronos.png','{"metric":"predictions_count","op":">=","value":20}'::jsonb,true,13),
('badge-trois-bons-resultats','Bonne lecture','Trouver 3 bons résultats sur une même soirée.','pronostics','common',false,'public','season','assets/badges/common/badge-common-trois-bons-resultats.png','{"metric":"max_good_results_evening","op":">=","value":3}'::jsonb,true,14),
('badge-deux-exacts','Double vision','Trouver 2 scores exacts dans une même journée.','scores','common',false,'public','season','assets/badges/common/badge-common-deux-exacts.png','{"metric":"max_exact_matchday","op":">=","value":2}'::jsonb,true,15),
('badge-sans-oubli-soiree','Présent !','Ne rien oublier sur une soirée complète.','assiduite','common',false,'public','season','assets/badges/common/badge-common-sans-oubli-soiree.png','{"metric":"completed_evenings","op":">=","value":1}'::jsonb,true,16),
('badge-premiere-remontee','Ça remonte','Gagner au moins 3 places au classement.','classement','common',false,'public','season','assets/badges/common/badge-common-premiere-remontee.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,17),
('badge-premier-top10','Top 10','Entrer pour la première fois dans le Top 10.','classement','common',false,'public','season','assets/badges/common/badge-common-premier-top10.png','{"metric":"best_rank","op":"<=","value":10}'::jsonb,true,18),
('badge-premier-top5','Top 5','Entrer pour la première fois dans le Top 5.','classement','common',false,'public','season','assets/badges/common/badge-common-premier-top5.png','{"metric":"best_rank","op":"<=","value":5}'::jsonb,true,19),
('badge-premier-podium','Première plume sur le podium','Entrer pour la première fois sur le podium.','classement','common',false,'public','season','assets/badges/common/badge-common-premier-podium.png','{"metric":"best_rank","op":"<=","value":3}'::jsonb,true,20),
('badge-dix-exacts','Sniper','Cumuler 10 scores exacts sur la saison.','scores','rare',false,'public','season','assets/badges/rare/badge-rare-dix-exacts.png','{"metric":"exact_scores","op":">=","value":10}'::jsonb,true,21),
('badge-vingt-bons-ecarts','Compas dans l''œil','Cumuler 20 bons écarts.','scores','rare',false,'public','season','assets/badges/rare/badge-rare-vingt-bons-ecarts.png','{"metric":"good_differences","op":">=","value":20}'::jsonb,true,22),
('badge-serie-cinq-points','Série propre','Marquer des points sur 5 matchs consécutifs.','series','rare',false,'public','season','assets/badges/rare/badge-rare-serie-cinq-points.png','{"metric":"scoring_streak","op":">=","value":5}'::jsonb,true,23),
('badge-serie-dix-points','Métronome','Marquer des points sur 10 matchs consécutifs.','series','rare',false,'public','season','assets/badges/rare/badge-rare-serie-dix-points.png','{"metric":"scoring_streak","op":">=","value":10}'::jsonb,true,24),
('badge-trois-exacts-soiree','Triple impact','Trouver 3 scores exacts sur une soirée.','scores','rare',false,'public','season','assets/badges/rare/badge-rare-trois-exacts-soiree.png','{"metric":"max_exact_evening","op":">=","value":3}'::jsonb,true,25),
('badge-cinq-journees-completes','Assidu','Compléter 5 journées UEFA sans oubli.','assiduite','rare',false,'public','season','assets/badges/rare/badge-rare-cinq-journees-completes.png','{"metric":"completed_matchdays","op":">=","value":5}'::jsonb,true,26),
('badge-dix-journees-completes','Fidèle au poste','Compléter 10 journées/soirées sans oubli.','assiduite','rare',false,'public','season','assets/badges/rare/badge-rare-dix-journees-completes.png','{"metric":"completed_matchdays","op":">=","value":10}'::jsonb,true,27),
('badge-top3-trois-fois','Habitué du podium','Terminer 3 soirées dans le Top 3.','classement','rare',false,'public','season','assets/badges/rare/badge-rare-top3-trois-fois.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,28),
('badge-leader-une-fois','Chef du Nid','Prendre la tête du classement au moins une fois.','classement','rare',false,'public','season','assets/badges/rare/badge-rare-leader-une-fois.png','{"metric":"best_rank","op":"<=","value":1}'::jsonb,true,29),
('badge-leader-sept-jours','Une semaine au sommet','Rester leader 7 jours cumulés.','classement','rare',false,'public','season','assets/badges/rare/badge-rare-leader-sept-jours.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,30),
('badge-remontee-dix','Ascenseur express','Gagner 10 places sur une journée.','classement','rare',false,'public','season','assets/badges/rare/badge-rare-remontee-dix.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,31),
('badge-aucun-zero-soiree','Soirée sans trou','Marquer sur tous les matchs d''une soirée.','assiduite','rare',false,'public','season','assets/badges/rare/badge-rare-aucun-zero-soiree.png','{"metric":"perfect_scoring_evenings","op":">=","value":1}'::jsonb,true,32),
('badge-outsider-reussi','Le flair','Trouver une victoire très minoritaire.','genie','rare',false,'public','season','assets/badges/rare/badge-rare-outsider-reussi.png','{"metric":"outsider_success_count","op":">=","value":1}'::jsonb,true,33),
('badge-hibou-solitaire-3','Solitaire confirmé','Réussir 3 Hiboux solitaires.','performance','rare',false,'public','season','assets/badges/rare/badge-rare-hibou-solitaire-3.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,34),
('badge-genie-50','Cerveau en fusion','Atteindre 50 points de génie.','genie','rare',false,'public','season','assets/badges/rare/badge-rare-genie-50.png','{"metric":"genius_points","op":">=","value":50}'::jsonb,true,35),
('badge-casserole-50','Cuisine ouverte','Atteindre 50 points de casserole.','casserole','rare',false,'public','season','assets/badges/rare/badge-rare-casserole-50.png','{"metric":"casserole_points","op":">=","value":50}'::jsonb,true,36),
('badge-rival-5','Bête noire','Battre son rival 5 soirées.','rival','rare',false,'public','season','assets/badges/rare/badge-rare-rival-5.png','{"metric":"rival_wins","op":">=","value":5}'::jsonb,true,37),
('badge-team-top3','Team sur le podium','Faire partie d''une team dans le Top 3.','team','rare',false,'public','season','assets/badges/rare/badge-rare-team-top3.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,38),
('badge-precision-60','Œil sûr','Atteindre 60 % de bons résultats sur une période significative.','performance','rare',false,'public','season','assets/badges/rare/badge-rare-precision-60.png','{"all":[{"metric":"played","op":">=","value":20},{"metric":"precision_pct","op":">=","value":60}]}'::jsonb,true,39),
('badge-aucun-oubli-phase','Phase complète','Ne manquer aucun prono d''une phase entière.','assiduite','rare',false,'public','season','assets/badges/rare/badge-rare-aucun-oubli-phase.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,40),
('badge-quatre-exacts-journee','Quatre à la suite','Trouver 4 scores exacts sur une journée UEFA.','scores','epic',false,'public','season','assets/badges/epic/badge-epic-quatre-exacts-journee.png','{"metric":"max_exact_matchday","op":">=","value":4}'::jsonb,true,41),
('badge-leader-trente-jours','Trône occupé','Cumuler 30 jours en tête.','classement','epic',false,'public','season','assets/badges/epic/badge-epic-leader-trente-jours.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,42),
('badge-top3-dix-soirees','Abonné au podium','Finir 10 soirées dans le Top 3.','classement','epic',false,'public','season','assets/badges/epic/badge-epic-top3-dix-soirees.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,43),
('badge-remontee-quinze','Remontada','Gagner au moins 15 places en une journée.','classement','epic',false,'public','season','assets/badges/epic/badge-epic-remontee-quinze.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,44),
('badge-hibou-solitaire-10','Seul contre presque tous','Réussir 10 Hiboux solitaires.','performance','epic',false,'public','season','assets/badges/epic/badge-epic-hibou-solitaire-10.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,45),
('badge-genie-150','Génie européen','Atteindre 150 points de génie.','genie','epic',false,'public','season','assets/badges/epic/badge-epic-genie-150.png','{"metric":"genius_points","op":">=","value":150}'::jsonb,true,46),
('badge-casserole-150','Chef étoilé… autrement','Atteindre 150 points de casserole.','casserole','epic',false,'public','season','assets/badges/epic/badge-epic-casserole-150.png','{"metric":"casserole_points","op":">=","value":150}'::jsonb,true,47),
('badge-exact-finale','Finaliste visionnaire','Trouver le score exact de la finale.','scores','epic',false,'public','season','assets/badges/epic/badge-epic-exact-finale.png','{"metric":"final_exact","op":">=","value":1}'::jsonb,true,48),
('badge-qualifies-parfaits-phase','Tableau limpide','Trouver tous les qualifiés d''une phase donnée.','performance','epic',false,'public','season','assets/badges/epic/badge-epic-qualifies-parfaits-phase.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,49),
('badge-phase-top1','Roi d''une phase','Terminer premier d''une phase complète.','classement','epic',false,'public','season','assets/badges/epic/badge-epic-phase-top1.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,50),
('badge-serie-20-points','Inarrêtable','Marquer sur 20 matchs consécutifs.','series','epic',false,'public','season','assets/badges/epic/badge-epic-serie-20-points.png','{"metric":"scoring_streak","op":">=","value":20}'::jsonb,true,51),
('badge-precision-70','Chirurgical','Atteindre 70 % de bons résultats sur une période significative.','performance','epic',false,'public','season','assets/badges/epic/badge-epic-precision-70.png','{"all":[{"metric":"played","op":">=","value":20},{"metric":"precision_pct","op":">=","value":70}]}'::jsonb,true,52),
('badge-rival-10','Némésis','Battre son rival 10 fois.','rival','epic',false,'public','season','assets/badges/epic/badge-epic-rival-10.png','{"metric":"rival_wins","op":">=","value":10}'::jsonb,true,53),
('badge-team-champion-phase','Team dominante','Faire partie de la meilleure team sur une phase.','team','epic',false,'public','season','assets/badges/epic/badge-epic-team-champion-phase.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,54),
('badge-cinq-exacts-semaine','Semaine magique','Trouver 5 scores exacts sur une même semaine UEFA.','scores','epic',false,'public','season','assets/badges/epic/badge-epic-cinq-exacts-semaine.png','{"metric":"max_exact_week","op":">=","value":5}'::jsonb,true,55),
('badge-outsider-3','Flair insolent','Réussir 3 gros outsiders.','genie','epic',false,'public','season','assets/badges/epic/badge-epic-outsider-3.png','{"metric":"outsider_success_count","op":">=","value":3}'::jsonb,true,56),
('badge-podium-50-jours','Installé là-haut','Cumuler 50 jours sur le podium.','classement','epic',false,'public','season','assets/badges/epic/badge-epic-podium-50-jours.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,57),
('badge-aucun-oubli-long','Mémoire de fer','Ne rien oublier pendant une très longue période.','assiduite','epic',false,'public','season','assets/badges/epic/badge-epic-aucun-oubli-long.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,58),
('badge-double-champion-vivant','Double espoir','Avoir encore ses deux choix champion en course très tard dans la saison.','performance','epic',false,'public','season','assets/badges/epic/badge-epic-double-champion-vivant.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,59),
('badge-hibou-nuit-5','Noctambule d''élite','Être Hibou de la nuit 5 fois.','performance','epic',false,'public','season','assets/badges/epic/badge-epic-hibou-nuit-5.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,60),
('badge-prophete','Le Prophète','Trouver 5 scores exacts lors d''une même journée UEFA.','scores','legendary',false,'public','season','assets/badges/legendary/badge-legendary-prophete.png','{"metric":"max_exact_matchday","op":">=","value":5}'::jsonb,true,61),
('badge-seul-contre-le-nid','Seul contre le Nid','Être l''unique joueur à choisir un vainqueur et avoir raison.','genie','legendary',false,'public','season','assets/badges/legendary/badge-legendary-seul-contre-le-nid.png','{"metric":"unique_correct_count","op":">=","value":1}'::jsonb,true,62),
('badge-nid-tappartient','Le Nid t''appartient','Cumuler 100 jours en tête du classement.','performance','legendary',false,'public','season','assets/badges/legendary/badge-legendary-nid-tappartient.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,63),
('badge-nuit-parfaite','Nuit parfaite','Marquer sur tous les matchs d''une grande soirée avec plusieurs scores exacts.','performance','legendary',false,'public','season','assets/badges/legendary/badge-legendary-nuit-parfaite.png','{"all":[{"metric":"perfect_scoring_evenings","op":">=","value":1},{"metric":"max_exact_evening","op":">=","value":2}]}'::jsonb,true,64),
('badge-oracle-europeen','Oracle européen','Enchaîner plusieurs résultats très improbables correctement.','genie','legendary',false,'public','season','assets/badges/legendary/badge-legendary-oracle-europeen.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,65),
('badge-immortel','Immortel','Compléter plusieurs saisons sans abandonner de pronostics.','assiduite','legendary',false,'public','career','assets/badges/legendary/badge-legendary-immortel.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,66),
('badge-champion-nid','Champion du Nid','Remporter le classement général d''une saison.','performance','legendary',false,'public','season','assets/badges/legendary/badge-legendary-champion-nid.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,67),
('badge-double-champion','Double champion','Remporter deux saisons du Nid.','performance','legendary',false,'public','career','assets/badges/legendary/badge-legendary-double-champion.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,68),
('badge-triple-champion','Dynastie','Remporter trois saisons.','performance','legendary',false,'public','career','assets/badges/legendary/badge-legendary-triple-champion.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,69),
('badge-exact-finale-x4','L''œil du trophée','Trouver le score exact de la finale avec multiplicateur maximal actif.','scores','legendary',false,'public','season','assets/badges/legendary/badge-legendary-exact-finale-x4.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,70),
('badge-100-exacts-carriere','Cent impacts','Atteindre 100 scores exacts en carrière.','carriere','legendary',false,'public','career','assets/badges/legendary/badge-legendary-100-exacts-carriere.png','{"metric":"career_exact_scores","op":">=","value":100}'::jsonb,true,71),
('badge-500-pronos-sans-oubli','Machine à pronos','Enregistrer 500 pronostics sans oubli de journée.','carriere','legendary',false,'public','career','assets/badges/legendary/badge-legendary-500-pronos-sans-oubli.png','{"metric":"career_predictions_count","op":">=","value":500}'::jsonb,true,72),
('badge-hibou-solitaire-impossible','Contre l''univers','Réussir un choix unique sur un résultat extrêmement improbable.','performance','legendary',false,'public','season','assets/badges/legendary/badge-legendary-hibou-solitaire-impossible.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,73),
('badge-genie-500','Cerveau légendaire','Atteindre 500 points de génie.','genie','legendary',false,'public','season','assets/badges/legendary/badge-legendary-genie-500.png','{"metric":"genius_points","op":">=","value":500}'::jsonb,true,74),
('badge-poele-or','Poêle d''Or','Finir premier du classement casserole d''une saison.','casserole','legendary',false,'public','season','assets/badges/legendary/badge-legendary-poele-or.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,75),
('badge-invincible-rival','Rivalité à sens unique','Battre son rival 15 fois consécutivement.','rival','legendary',false,'public','season','assets/badges/legendary/badge-legendary-invincible-rival.png','{"metric":"rival_win_streak","op":">=","value":15}'::jsonb,true,76),
('badge-team-dynastie','Dynastie de Team','Gagner plusieurs saisons avec la même team.','team','legendary',false,'public','career','assets/badges/legendary/badge-legendary-team-dynastie.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,77),
('badge-top3-toute-saison','Jamais descendu','Rester dans le Top 3 pendant toute une saison après y être entré.','classement','legendary',false,'public','season','assets/badges/legendary/badge-legendary-top3-toute-saison.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,78),
('badge-champion-allin','All-in parfait','Choisir deux fois le même champion et le voir gagner.','performance','legendary',false,'public','season','assets/badges/legendary/badge-legendary-champion-allin.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,79),
('badge-grand-chelem','Grand Chelem du Nid','Cumuler plusieurs grandes distinctions majeures sur une même saison.','performance','legendary',false,'public','season','assets/badges/legendary/badge-legendary-grand-chelem.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,80),
('badge-derniere-seconde','Derniere Seconde','Modifier un prono dans les 10 dernières secondes avant verrouillage.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-derniere-seconde.png','{"metric":"last_second_prediction","op":">=","value":1}'::jsonb,true,81),
('badge-om-par-defaut','OM Par Defaut','Laisser le Nid choisir Marseille comme champion par défaut.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-om-par-defaut.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,82),
('badge-quinze-zero','Quinze Zero','Oser un pronostic 15-0 ou plus.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-quinze-zero.png','{"metric":"max_prediction_score","op":">=","value":15}'::jsonb,true,83),
('badge-zero-partout','Zero Partout','Réaliser une soirée complète à zéro point.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-zero-partout.png','{"metric":"zero_point_evenings","op":">=","value":1}'::jsonb,true,84),
('badge-casserole-mauvaise-foi','Casserole Mauvaise Foi','Recevoir une casserole manuelle pour mauvaise foi.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-casserole-mauvaise-foi.png','{"metric":"bad_faith_casseroles","op":">=","value":1}'::jsonb,true,85),
('badge-hibou-masque-contact','Hibou Masque Contact','Écrire au Hibou masqué dans une circonstance particulière.','secret','secret',true,'hidden','season','assets/badges/secret/badge-secret-hibou-masque-contact.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,86),
('badge-retour-de-nulle-part','Retour De Nulle Part','Réaliser une remontée extrêmement improbable.','classement','secret',true,'hidden','season','assets/badges/secret/badge-secret-retour-de-nulle-part.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,87),
('badge-var-maudit','VAR Maudit','Rater plusieurs pronostics sur des événements tardifs.','assiduite','secret',true,'listed','season','assets/badges/secret/badge-secret-var-maudit.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,88),
('badge-90plus','90plus','Perdre plusieurs scores exacts à cause de buts très tardifs.','scores','secret',true,'listed','season','assets/badges/secret/badge-secret-90plus.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,89),
('badge-team-traitre','Team Traitre','Changer de team dans une circonstance historique ou amusante.','team','secret',true,'listed','season','assets/badges/secret/badge-secret-team-traitre.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,90),
('badge-capitaine-abandonne','Capitaine Abandonne','Transmettre son capitanat dans une circonstance particulière.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-capitaine-abandonne.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,91),
('badge-faux-prophete','Faux Prophete','Faire un pronostic extravagant qui échoue spectaculairement.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-faux-prophete.png','{"metric":"spectacular_wrong_count","op":">=","value":1}'::jsonb,true,92),
('badge-tout-le-monde-a-tort','Tout Le Monde A Tort','Participer à une catastrophe collective massive.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-tout-le-monde-a-tort.png','{"metric":"collective_disaster_count","op":">=","value":1}'::jsonb,true,93),
('badge-tout-le-monde-a-raison','Tout Le Monde A Raison','Participer à une prédiction collective presque unanime et correcte.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-tout-le-monde-a-raison.png','{"metric":"collective_success_count","op":">=","value":1}'::jsonb,true,94),
('badge-hibou-insomniaque','Hibou Insomniaque','Interagir avec le Nid à une heure improbable lors d''une soirée européenne.','secret','secret',true,'hidden','season','assets/badges/secret/badge-secret-hibou-insomniaque.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,95),
('badge-pile-ou-face','Pile Ou Face','Enchaîner une séquence statistique improbable.','secret','secret',true,'hidden','season','assets/badges/secret/badge-secret-pile-ou-face.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,96),
('badge-exact-maudit','Exact Maudit','Accumuler plusieurs scores à un but près de l''exact.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-exact-maudit.png','{"metric":"near_exact_misses","op":">=","value":5}'::jsonb,true,97),
('badge-sept-zero','Sept Zero','Rencontrer une condition liée à un score extrême.','secret','secret',true,'listed','season','assets/badges/secret/badge-secret-sept-zero.png','{"metric":"extreme_score_events","op":">=","value":1}'::jsonb,true,98),
('badge-fantome-du-nid','Fantome Du Nid','Revenir après une longue absence et marquer immédiatement fort.','secret','secret',true,'hidden','season','assets/badges/secret/badge-secret-fantome-du-nid.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,99),
('badge-secret-ultime','Secret Ultime','Condition exceptionnelle gardée secrète par le Super Admin.','secret','secret',true,'hidden','season','assets/badges/secret/badge-secret-secret-ultime.png','{"manual":true,"note":"Condition conservée dans le catalogue ; attribution manuelle ou moteur futur."}'::jsonb,false,100)
on conflict(code) do update set
  name=excluded.name,description=excluded.description,category=excluded.category,rarity=excluded.rarity,
  is_secret=excluded.is_secret,secret_visibility=excluded.secret_visibility,scope=excluded.scope,
  default_asset_path=excluded.default_asset_path,condition_json=excluded.condition_json,
  auto_evaluate=excluded.auto_evaluate,sort_order=excluded.sort_order;

-- -----------------------------------------------------------------------------
-- 5. Métriques joueurs et évaluateur de conditions JSON.
-- -----------------------------------------------------------------------------
create or replace function public.gamification_metrics_v070(p_user_id uuid,p_season_id uuid,p_is_test boolean default false)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare v jsonb;
begin
  with eligible_matches as (
    select m.* from public.matches m
    where m.season_id=p_season_id and coalesce(m.is_test,false)=p_is_test
      and (not p_is_test or coalesce(m.test_enabled,true)=true)
  ), pp as (
    select p.*,m.status,m.home_score rh,m.away_score ra,m.matchday_id,m.kickoff_at,m.phase_id,m.points_multiplier,
      case when m.home_score is null or m.away_score is null then null
           when p.home_score=m.home_score and p.away_score=m.away_score then 'exact'
           when sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score) and (p.home_score-p.away_score)=(m.home_score-m.away_score) then 'difference'
           when sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score) then 'result' else 'wrong' end as grade
    from public.predictions p join eligible_matches m on m.id=p.match_id
    where p.user_id=p_user_id
  ), settled as (select * from pp where status='finished'),
  streak as (
    select coalesce(max(cnt),0)::int as best from (
      select grp,count(*) cnt from (
        select *, row_number() over(order by kickoff_at)-row_number() over(partition by (coalesce(points,0)>0) order by kickoff_at) grp
        from settled
      ) q where coalesce(points,0)>0 group by grp
    ) s
  ), per_md as (
    select matchday_id,sum(coalesce(points,0)) pts,count(*) filter(where grade='exact') exacts
    from settled group by matchday_id
  ), per_evening as (
    select (kickoff_at at time zone 'Europe/Paris')::date d, count(*) played,count(*) filter(where grade='exact') exacts,
      count(*) filter(where coalesce(points,0)>0) scoring,count(*) filter(where grade in ('result','difference','exact')) good
    from settled group by 1
  ), complete_md as (
    select md.id,
      count(em.id) filter(where em.status<>'cancelled') total,
      count(p.id) filter(where em.status<>'cancelled') predicted
    from public.matchdays md join eligible_matches em on em.matchday_id=md.id
    left join public.predictions p on p.match_id=em.id and p.user_id=p_user_id
    where md.season_id=p_season_id group by md.id
  ), rank_now as (
    select rank from public.get_leaderboard_v040(p_season_id,'general',null,null,true) where not p_is_test and user_id=p_user_id
    union all
    select rank from public.get_test_leaderboard_v070(p_season_id,true) where p_is_test and user_id=p_user_id
  ), career as (
    select count(*) predictions,count(*) filter(where m.status='finished' and p.home_score=m.home_score and p.away_score=m.away_score) exacts
    from public.predictions p join public.matches m on m.id=p.match_id where p.user_id=p_user_id and coalesce(m.is_test,false)=false
  )
  select jsonb_build_object(
    'predictions_count',(select count(*) from pp),
    'career_predictions_count',(select predictions from career),
    'total_points',(select coalesce(sum(points),0) from settled),
    'played',(select count(*) from settled),
    'exact_scores',(select count(*) from settled where grade='exact'),
    'career_exact_scores',(select exacts from career),
    'good_differences',(select count(*) from settled where grade in ('difference','exact')),
    'good_results',(select count(*) from settled where grade in ('result','difference','exact')),
    'precision_pct',(select case when count(*)=0 then 0 else round(100.0*count(*) filter(where grade in ('result','difference','exact'))/count(*),2) end from settled),
    'completed_matchdays',(select count(*) from complete_md where total>0 and predicted=total),
    'completed_evenings',(select count(*) from per_evening where played>0),
    'perfect_scoring_evenings',(select count(*) from per_evening where played>=1 and scoring=played),
    'zero_point_evenings',(select count(*) from per_evening where played>=1 and scoring=0),
    'max_exact_matchday',(select coalesce(max(exacts),0) from per_md),
    'max_points_matchday',(select coalesce(max(pts),0) from per_md),
    'max_exact_evening',(select coalesce(max(exacts),0) from per_evening),
    'max_good_results_evening',(select coalesce(max(good),0) from per_evening),
    'max_exact_week',0,
    'scoring_streak',(select best from streak),
    'best_rank',coalesce((select rank from rank_now),9999),
    'team_memberships_count',(select count(*) from public.team_memberships where user_id=p_user_id and season_id=p_season_id),
    'rival_wins',(select count(*) from public.rival_duels where user_id=p_user_id and season_id=p_season_id and result='win'),
    'rival_win_streak',0,
    'genius_points',(select coalesce(sum(points),0) from public.gamification_events where user_id=p_user_id and season_id=p_season_id and event_type='genius' and is_test=p_is_test),
    'genius_count',(select count(*) from public.gamification_events where user_id=p_user_id and season_id=p_season_id and event_type='genius' and is_test=p_is_test),
    'casserole_points',(select coalesce(sum(points),0) from public.gamification_events where user_id=p_user_id and season_id=p_season_id and event_type='casserole' and is_test=p_is_test),
    'casserole_count',(select count(*) from public.gamification_events where user_id=p_user_id and season_id=p_season_id and event_type='casserole' and is_test=p_is_test),
    'records_count',(select count(*) from public.gamification_records where user_id=p_user_id and season_id=p_season_id and active and is_test=p_is_test),
    'outsider_success_count',(select count(*) from public.gamification_events where user_id=p_user_id and season_id=p_season_id and event_type='genius' and points>=5 and is_test=p_is_test),
    'unique_correct_count',(select count(*) from public.gamification_events where user_id=p_user_id and season_id=p_season_id and event_type='genius' and (metadata->>'unique')::boolean is true and is_test=p_is_test),
    'max_prediction_score',(select coalesce(max(greatest(home_score,away_score)),0) from pp),
    'last_second_prediction',(select count(*) from pp where updated_at between kickoff_at-interval '10 seconds' and kickoff_at),
    'bad_faith_casseroles',(select count(*) from public.gamification_events where user_id=p_user_id and season_id=p_season_id and event_type='casserole' and subtype='bad_faith' and is_test=p_is_test),
    'spectacular_wrong_count',(select count(*) from settled where grade='wrong' and abs((home_score-away_score)-(rh-ra))>=8),
    'near_exact_misses',(select count(*) from settled where abs(home_score-rh)+abs(away_score-ra)=1),
    'extreme_score_events',(select count(*) from settled where greatest(rh,ra)>=7),
    'final_exact',(select count(*) from settled s join public.competition_phases ph on ph.id=s.phase_id where ph.code='FINAL' and s.grade='exact'),
    'collective_disaster_count',0,'collective_success_count',0
  ) into v;
  return v;
end;$$;

create or replace function public.narrative_text_v070(p_event_key text,p_vars jsonb default '{}'::jsonb,p_fallback text default '',p_tone text default 'automatic')
returns text language plpgsql volatile security definer set search_path=public as $$
declare v_text text; kv record;
begin
  select t.template into v_text
  from public.gamification_text_templates t
  where t.event_key=p_event_key and t.active and t.tone in (coalesce(nullif(p_tone,''),'automatic'),'automatic')
  order by (-ln(greatest(random(),0.000001)) / greatest(t.weight,0.05)) asc
  limit 1;
  v_text:=coalesce(v_text,p_fallback,'');
  for kv in select key,value from jsonb_each_text(coalesce(p_vars,'{}'::jsonb)) loop
    v_text:=replace(v_text,'{'||kv.key||'}',kv.value);
  end loop;
  return v_text;
end;$$;

create or replace function public.eval_badge_condition_v070(p_condition jsonb,p_metrics jsonb)
returns boolean language plpgsql immutable as $$
declare item jsonb; v_num numeric; target numeric; op text;
begin
  if coalesce((p_condition->>'manual')::boolean,false) then return false; end if;
  if p_condition ? 'all' then
    for item in select value from jsonb_array_elements(p_condition->'all') loop if not public.eval_badge_condition_v070(item,p_metrics) then return false; end if; end loop; return true;
  end if;
  if p_condition ? 'any' then
    for item in select value from jsonb_array_elements(p_condition->'any') loop if public.eval_badge_condition_v070(item,p_metrics) then return true; end if; end loop; return false;
  end if;
  if not (p_condition ? 'metric') then return false; end if;
  v_num:=coalesce((p_metrics->>(p_condition->>'metric'))::numeric,0); target:=coalesce((p_condition->>'value')::numeric,0); op:=coalesce(p_condition->>'op','>=');
  return case op when '>=' then v_num>=target when '>' then v_num>target when '<=' then v_num<=target when '<' then v_num<target when '=' then v_num=target else false end;
end;$$;

create or replace function public.evaluate_badges_v070(p_user_id uuid,p_season_id uuid,p_is_test boolean default false,p_source text default 'automatic')
returns integer language plpgsql security definer set search_path=public as $$
declare
  b record; metrics jsonb; awarded int:=0; first_found boolean; pb_id uuid;
  awarded_ids jsonb:='[]'::jsonb; awarded_names jsonb:='[]'::jsonb;
  highest_rarity text:='common'; highest_rank int:=0; current_rank int:=0;
  last_name text; last_description text; last_secret boolean:=false; last_badge_id uuid;
  v_settings public.gamification_settings%rowtype;
begin
  metrics:=public.gamification_metrics_v070(p_user_id,p_season_id,p_is_test);
  select * into v_settings from public.gamification_settings where season_id=p_season_id;
  for b in select * from public.gamification_badges where active and archived_at is null and auto_evaluate order by sort_order loop
    if public.eval_badge_condition_v070(b.condition_json,metrics) and not exists(
      select 1 from public.player_badges x where x.badge_id=b.id and x.user_id=p_user_id and coalesce(x.season_id,p_season_id)=p_season_id and x.is_test=p_is_test and x.revoked_at is null
    ) then
      first_found:=b.is_secret and not exists(select 1 from public.player_badges x where x.badge_id=b.id and x.is_test=p_is_test and x.revoked_at is null);
      insert into public.player_badges(badge_id,user_id,season_id,context,source,is_test,first_discovery)
      values(b.id,p_user_id,case when b.scope='career' then null else p_season_id end,jsonb_build_object('metrics',metrics),p_source,p_is_test,first_found)
      returning id into pb_id;
      awarded:=awarded+1; awarded_ids:=awarded_ids||jsonb_build_array(b.id); awarded_names:=awarded_names||jsonb_build_array(b.name);
      last_name:=b.name;last_description:=b.description;last_secret:=b.is_secret;last_badge_id:=b.id;
      current_rank:=case b.rarity when 'secret' then 5 when 'legendary' then 4 when 'epic' then 3 when 'rare' then 2 else 1 end;
      if current_rank>highest_rank then highest_rank:=current_rank;highest_rarity:=b.rarity;end if;

      -- Une découverte secrète n'est annoncée au Nid qu'une fois dans l'histoire du badge.
      -- Lors d'une migration rétroactive, le Super Admin choisit via secret_retro_notify.
      if first_found and not p_is_test and (p_source<>'migration' or coalesce(v_settings.secret_retro_notify,false)) then
        insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
        select p.id,p_season_id,'badge','🕵️ Un secret du Nid a été découvert',
          public.narrative_text_v070('secret_found',jsonb_build_object('player',pr.username,'team',coalesce(t.name,'')),pr.username||coalesce(' de la Team '||t.name,'')||' vient de découvrir quelque chose. Le Hibou ne dira absolument pas quoi.','automatic'),
          'important','museum:badges',jsonb_build_object('discoverer_id',p_user_id,'badge_hidden',true),'secret-first:'||b.id::text||':'||p.id::text,true
        from public.profiles p cross join public.profiles pr
        left join public.team_memberships tm on tm.user_id=p_user_id and tm.season_id=p_season_id and tm.left_at is null
        left join public.teams t on t.id=tm.team_id
        where pr.id=p_user_id and p.status='active' and p.id<>p_user_id
        on conflict(user_id,source_key) where source_key is not null do nothing;
      end if;
    end if;
  end loop;

  -- Plusieurs badges d'un même passage moteur = UNE notification groupée.
  if awarded>0 and not p_is_test then
    insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
    values(
      p_user_id,p_season_id,'badge',
      case when awarded=1 and last_secret then '🕵️ Secret découvert' when awarded=1 then '🏅 Nouveau badge' else '🏅 '||awarded||' nouveaux badges' end,
      case when awarded=1 then
        public.narrative_text_v070(case when last_secret then 'secret_found' else 'badge_'||highest_rarity end,
          jsonb_build_object('player',(select username from public.profiles where id=p_user_id),'badge',last_name,'rarity',highest_rarity,'count',awarded),
          case when last_secret then 'Le Hibou vient de lever un coin du voile. Ton Musée connaît désormais ce secret.' else last_name||' — '||coalesce(last_description,'') end,
          coalesce((select owl_tone from public.notification_preferences where user_id=p_user_id),'automatic'))
      else
        public.narrative_text_v070('badge_group',jsonb_build_object('player',(select username from public.profiles where id=p_user_id),'count',awarded,'rarity',highest_rarity),'Le Musée a fouillé tes archives : '||awarded||' badges viennent de rejoindre ta collection.',coalesce((select owl_tone from public.notification_preferences where user_id=p_user_id),'automatic'))
      end,
      case when highest_rank>=3 then 'important' else 'info' end,'museum:badges',jsonb_build_object('badge_ids',awarded_ids,'badge_names',awarded_names,'count',awarded,'highest_rarity',highest_rarity),
      'badge-group:'||p_user_id::text||':'||replace(gen_random_uuid()::text,'-',''),highest_rank>=2
    );
  end if;
  return awarded;
end;$$;

-- -----------------------------------------------------------------------------
-- 6. Casseroles / Génie automatiques lors d'un match terminé.
-- -----------------------------------------------------------------------------
create or replace function public.process_match_gamification_v070(p_match_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare m public.matches%rowtype; total int; r record; actual_pick text; pred_pick text; pick_count int; pct numeric; genius int; exact_bonus int; odds numeric; margin_error int; severity text; cpoints int; labels jsonb; is_t boolean; settings public.gamification_settings%rowtype; zero_streak int; md_count int; md_finished int; md_zero int; full_severity text;
begin
  select * into m from public.matches where id=p_match_id; if not found or m.status<>'finished' or m.home_score is null or m.away_score is null then return jsonb_build_object('processed',false); end if;
  is_t:=coalesce(m.is_test,false); select * into settings from public.gamification_settings where season_id=m.season_id;
  if is_t and coalesce(settings.test_enabled,false)=false then return jsonb_build_object('processed',false,'reason','test_disabled'); end if;
  -- En cas de correction d’un score final, reconstruire les événements automatiques du match.
  delete from public.gamification_events where match_id=m.id and is_manual=false and is_test=is_t;
  select count(*) into total from public.predictions where match_id=m.id;
  actual_pick:=case when m.home_score>m.away_score then 'H' when m.home_score<m.away_score then 'A' else 'D' end;
  for r in select p.* from public.predictions p where p.match_id=m.id loop
    pred_pick:=case when r.home_score>r.away_score then 'H' when r.home_score<r.away_score then 'A' else 'D' end;
    -- Génie : bon résultat minoritaire.
    genius:=0;
    if pred_pick=actual_pick and total>=coalesce((settings.genius_thresholds->>'minimum_predictions')::int,5) then
      select count(*) into pick_count from public.predictions p where p.match_id=m.id and (case when p.home_score>p.away_score then 'H' when p.home_score<p.away_score then 'A' else 'D' end)=actual_pick;
      pct:=case when total>0 then 100.0*pick_count/total else 100 end;
      genius:=case when pick_count=1 then 10 when pct<2 then 7 when pct<=5 then 5 when pct<=10 then 3 when pct<=20 then 1 else 0 end;
      exact_bonus:=case when r.home_score=m.home_score and r.away_score=m.away_score and genius>0 then coalesce((settings.genius_thresholds->>'exact_bonus')::int,2) else 0 end;
      odds:=case actual_pick when 'H' then m.odds_home when 'D' then m.odds_draw else m.odds_away end;
      if genius>0 and odds is not null then genius:=genius+case when odds>=8 then 3 when odds>=5 then 2 when odds>=3 then 1 else 0 end; end if;
      genius:=least(coalesce((settings.genius_thresholds->>'max')::int,10),genius+exact_bonus);
    end if;
    if genius>0 then
      insert into public.gamification_events(season_id,user_id,event_type,subtype,severity,points,match_id,matchday_id,title,message,labels,metadata,is_test)
      values(m.season_id,r.user_id,'genius','rare_outcome',case when genius>=10 then 'prophetic' when genius>=7 then 'brilliant' when genius>=3 then 'nice' else 'inspiration' end,genius,m.id,m.matchday_id,'Coup de génie',
        public.narrative_text_v070(case when genius>=10 then 'genius_10' when genius>=7 then 'genius_7' when genius>=5 then 'genius_5' when genius>=3 then 'genius_3' else 'genius_1' end,
          jsonb_build_object('player',(select username from public.profiles where id=r.user_id),'points',genius,'prediction',r.home_score||'–'||r.away_score,'club_home',coalesce((select short_name from public.clubs where id=m.home_club_id),'Domicile'),'club_away',coalesce((select short_name from public.clubs where id=m.away_club_id),'Extérieur')),'Le Hibou vient de noter un coup de génie à +'||genius||'.','automatic'),
        jsonb_build_array('résultat minoritaire')||case when exact_bonus>0 then jsonb_build_array('score exact') else '[]'::jsonb end,jsonb_build_object('pick_pct',pct,'pick_count',pick_count,'total',total,'odds',odds,'unique',pick_count=1),is_t)
      on conflict do nothing;
      if not is_t then
        insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
        values(r.user_id,m.season_id,'gamification',case when genius>=7 then '✨ Gros coup de génie' else '✨ Coup de génie' end,
          public.narrative_text_v070(case when genius>=10 then 'genius_10' when genius>=7 then 'genius_7' when genius>=5 then 'genius_5' when genius>=3 then 'genius_3' else 'genius_1' end,
            jsonb_build_object('player',(select username from public.profiles where id=r.user_id),'points',genius,'prediction',r.home_score||'–'||r.away_score,'club_home',coalesce(m.home_club_id::text,'club domicile'),'club_away',coalesce(m.away_club_id::text,'club extérieur')),
            'Le Hibou vient de noter un coup de génie à +'||genius||'.',coalesce((select owl_tone from public.notification_preferences where user_id=r.user_id),'automatic')),
          case when genius>=7 then 'important' else 'info' end,'museum:genius',jsonb_build_object('match_id',m.id,'points',genius),'genius:'||m.id::text||':'||r.user_id::text,genius>=5)
        on conflict(user_id,source_key) where source_key is not null do nothing;
        if genius>=7 then
          insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
          select p.id,m.season_id,'gamification','✨ Le Nid vient de voir un gros coup',
            public.narrative_text_v070(case when genius>=10 then 'genius_10' else 'genius_7' end,jsonb_build_object('player',pr.username,'points',genius),'Un coup de génie à +'||genius||' vient de tomber dans le Nid.','automatic'),
            'important','museum:genius',jsonb_build_object('match_id',m.id,'player_id',r.user_id,'points',genius),'genius-global:'||m.id::text||':'||r.user_id::text||':'||p.id::text,true
          from public.profiles p cross join public.profiles pr where p.status='active' and pr.id=r.user_id and p.id<>r.user_id
          on conflict(user_id,source_key) where source_key is not null do nothing;
        end if;
      end if;
    end if;
    -- Casserole : écart entre différences de buts + mauvais choix unique.
    if pred_pick<>actual_pick then
      margin_error:=abs((r.home_score-r.away_score)-(m.home_score-m.away_score)); labels:='[]'::jsonb; severity:=null; cpoints:=0;
      -- Série de zéros : 3 / 5 / 8 par défaut, configurable.
      select count(*) into zero_streak from (
        select p2.points,
          sum(case when coalesce(p2.points,0)>0 then 1 else 0 end) over(order by m2.kickoff_at desc,m2.id rows between unbounded preceding and current row) as positive_seen
        from public.predictions p2 join public.matches m2 on m2.id=p2.match_id
        where p2.user_id=r.user_id and p2.season_id=m.season_id and m2.status='finished' and coalesce(m2.is_test,false)=is_t
          and (m2.kickoff_at<m.kickoff_at or (m2.kickoff_at=m.kickoff_at and m2.id<=m.id))
      ) z where z.positive_seen=0 and coalesce(z.points,0)=0;
      if zero_streak>=coalesce((settings.casserole_rules->>'zero_nuclear')::int,8) then severity:='nuclear'; labels:=labels||jsonb_build_array('série de '||zero_streak||' zéros');
      elsif zero_streak>=coalesce((settings.casserole_rules->>'zero_beautiful')::int,5) then severity:='beautiful'; labels:=labels||jsonb_build_array('série de '||zero_streak||' zéros');
      elsif zero_streak>=coalesce((settings.casserole_rules->>'zero_small')::int,3) then severity:='small'; labels:=labels||jsonb_build_array('série de '||zero_streak||' zéros'); end if;
      -- Journée entière à zéro, évaluée lorsque tous les matchs officiels/TEST de la journée sont terminés.
      select count(*),count(*) filter(where status='finished') into md_count,md_finished from public.matches m3 where m3.matchday_id=m.matchday_id and coalesce(m3.is_test,false)=is_t and m3.status not in ('cancelled','postponed');
      if md_count>0 and md_count=md_finished then
        select count(*) into md_zero from public.predictions p3 join public.matches m3 on m3.id=p3.match_id where p3.user_id=r.user_id and m3.matchday_id=m.matchday_id and m3.status='finished' and coalesce(m3.is_test,false)=is_t and coalesce(p3.points,0)=0;
        if md_zero=md_count then
          labels:=labels||jsonb_build_array('journée complète à zéro'); full_severity:=coalesce(settings.casserole_rules->>'full_matchday_severity','industrial');
          if full_severity='nuclear' then severity:='nuclear';
          elsif full_severity='industrial' and coalesce(severity,'') not in ('nuclear','industrial') then severity:='industrial';
          elsif full_severity='beautiful' and coalesce(severity,'') not in ('nuclear','industrial','beautiful') then severity:='beautiful';
          elsif full_severity='small' and severity is null then severity:='small';
          end if;
        end if;
      end if;
      if margin_error>=coalesce((settings.casserole_thresholds->>'nuclear')::int,8) then severity:='nuclear';
      elsif margin_error>=coalesce((settings.casserole_thresholds->>'industrial')::int,6) and coalesce(severity,'')<>'nuclear' then severity:='industrial';
      elsif margin_error>=coalesce((settings.casserole_thresholds->>'beautiful')::int,4) and coalesce(severity,'') not in ('nuclear','industrial') then severity:='beautiful';
      elsif margin_error>=coalesce((settings.casserole_thresholds->>'small')::int,3) and severity is null then severity:='small'; end if;
      if margin_error>=coalesce((settings.casserole_thresholds->>'small')::int,3) then labels:=labels||jsonb_build_array('écart monumental'); end if;
      select count(*) into pick_count from public.predictions p where p.match_id=m.id and (case when p.home_score>p.away_score then 'H' when p.home_score<p.away_score then 'A' else 'D' end)=pred_pick;
      if pick_count=1 then labels:=labels||jsonb_build_array('seul à se tromper'); if severity is null or severity='small' then severity='beautiful'; end if; end if;
      cpoints:=case severity when 'nuclear' then coalesce((settings.casserole_points->>'nuclear')::int,10) when 'industrial' then coalesce((settings.casserole_points->>'industrial')::int,5) when 'beautiful' then coalesce((settings.casserole_points->>'beautiful')::int,3) when 'small' then coalesce((settings.casserole_points->>'small')::int,1) else 0 end;
      if cpoints>0 then
        insert into public.gamification_events(season_id,user_id,event_type,subtype,severity,points,match_id,matchday_id,title,message,labels,metadata,is_test)
        values(m.season_id,r.user_id,'casserole','prediction_disaster',severity,cpoints,m.id,m.matchday_id,'Casserole',
          public.narrative_text_v070('casserole_'||severity,jsonb_build_object('player',(select username from public.profiles where id=r.user_id),'points',cpoints,'prediction',r.home_score||'–'||r.away_score,'margin',margin_error,'club_home',coalesce((select short_name from public.clubs where id=m.home_club_id),'Domicile'),'club_away',coalesce((select short_name from public.clubs where id=m.away_club_id),'Extérieur')),'Le Hibou ajoute +'||cpoints||' points casserole au Musée.','automatic'),
          labels,jsonb_build_object('margin_error',margin_error,'unique_wrong',pick_count=1,'zero_streak',zero_streak),is_t) on conflict do nothing;
        if not is_t then
          insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
          values(r.user_id,m.season_id,'gamification',case severity when 'nuclear' then '☢️ Casserole nucléaire' when 'industrial' then '🔥 Casserole industrielle' else '🍳 Casserole' end,
            public.narrative_text_v070('casserole_'||severity,jsonb_build_object('player',(select username from public.profiles where id=r.user_id),'points',cpoints,'prediction',r.home_score||'–'||r.away_score,'margin',margin_error),'Le Hibou ajoute +'||cpoints||' points casserole au Musée.',coalesce((select owl_tone from public.notification_preferences where user_id=r.user_id),'automatic')),
            case when severity in ('industrial','nuclear') then 'important' else 'info' end,'museum:casseroles',jsonb_build_object('match_id',m.id,'points',cpoints,'severity',severity),'casserole:'||m.id::text||':'||r.user_id::text,severity in ('industrial','nuclear'))
          on conflict(user_id,source_key) where source_key is not null do nothing;
          if severity in ('industrial','nuclear') then
            insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
            select p.id,m.season_id,'gamification',case when severity='nuclear' then '☢️ CASSEROLE NUCLÉAIRE' else '🔥 Casserole industrielle' end,
              public.narrative_text_v070('casserole_'||severity,jsonb_build_object('player',pr.username,'points',cpoints,'prediction',r.home_score||'–'||r.away_score,'margin',margin_error),'Une grosse casserole vient d’entrer au Musée du Nid.','automatic'),
              'important','museum:casseroles',jsonb_build_object('match_id',m.id,'player_id',r.user_id,'points',cpoints,'severity',severity),'casserole-global:'||m.id::text||':'||r.user_id::text||':'||p.id::text,true
            from public.profiles p cross join public.profiles pr where p.status='active' and pr.id=r.user_id and p.id<>r.user_id
            on conflict(user_id,source_key) where source_key is not null do nothing;
          end if;
        end if;
      end if;
    end if;
    perform public.evaluate_badges_v070(r.user_id,m.season_id,is_t,'automatic');
  end loop;
  perform public.refresh_records_v070(m.season_id,m.matchday_id,is_t);
  -- Les records d'une journée ne sont connus qu'après sa clôture : réévaluer les
  -- badges liés aux records une fois le rafraîchissement effectué.
  for r in select distinct p.user_id from public.predictions p join public.matches mx on mx.id=p.match_id where mx.matchday_id=m.matchday_id and coalesce(mx.is_test,false)=is_t loop
    perform public.evaluate_badges_v070(r.user_id,m.season_id,is_t,'automatic');
  end loop;
  return jsonb_build_object('processed',true,'predictions',total,'test',is_t);
end;$$;

-- -----------------------------------------------------------------------------
-- 7. Records principaux + historique. Premier chronologique garde une égalité.
-- -----------------------------------------------------------------------------
create or replace function public.upsert_record_candidate_v070(p_season_id uuid,p_key text,p_name text,p_category text,p_user_id uuid,p_value numeric,p_matchday_id uuid,p_is_test boolean)
returns void language plpgsql security definer set search_path=public as $$
declare cur record;
begin
  select * into cur from public.gamification_records where season_id=p_season_id and record_key=p_key and scope='nid' and is_test=p_is_test and active order by value desc,achieved_at asc limit 1;
  if cur.id is null or p_value>cur.value then
    if cur.id is not null then update public.gamification_records set active=false where id=cur.id; end if;
    insert into public.gamification_records(season_id,record_key,record_name,category,scope,user_id,value,previous_value,matchday_id,is_test) values(p_season_id,p_key,p_name,p_category,'nid',p_user_id,p_value,cur.value,p_matchday_id,p_is_test);
    if not p_is_test then
      insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested) values(p_user_id,p_season_id,'record','🏆 RECORD DU NID',public.narrative_text_v070('record_broken',jsonb_build_object('player',(select username from public.profiles where id=p_user_id),'record',p_name,'value',p_value),'Nouveau Record du Nid : '||p_name||' à '||p_value||'.','automatic'),'important','museum:records',jsonb_build_object('record_key',p_key,'value',p_value),'record:'||p_key||':'||p_user_id||':'||p_value,true) on conflict(user_id,source_key) where source_key is not null do nothing;
      if cur.id is not null then insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested) values(cur.user_id,p_season_id,'record','Ton record vient de tomber',public.narrative_text_v070('record_lost',jsonb_build_object('player',(select username from public.profiles where id=cur.user_id),'record',p_name,'previous',cur.value,'new_holder',(select username from public.profiles where id=p_user_id),'value',p_value),'Ton record vient de tomber.','automatic'),'info','museum:records',jsonb_build_object('record_key',p_key),'record-lost:'||cur.id,false) on conflict(user_id,source_key) where source_key is not null do nothing; end if;
    end if;
  elsif p_value=cur.value and p_user_id<>cur.user_id and not exists(select 1 from public.gamification_records where season_id=p_season_id and record_key=p_key and user_id=p_user_id and value=p_value and is_test=p_is_test) then
    insert into public.gamification_records(season_id,record_key,record_name,category,scope,user_id,value,previous_value,matchday_id,is_test,is_equal,active) values(p_season_id,p_key,p_name,p_category,'nid',p_user_id,p_value,cur.value,p_matchday_id,p_is_test,true,false);
    if not p_is_test then insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested) values(p_user_id,p_season_id,'record','🏆 Record égalé',public.narrative_text_v070('record_equal',jsonb_build_object('player',(select username from public.profiles where id=p_user_id),'record',p_name,'value',p_value),'Record égalé : le premier détenteur reste officiellement devant.','automatic'),'info','museum:records',jsonb_build_object('record_key',p_key),'record-equal:'||p_key||':'||p_user_id,false); end if;
  end if;
end;$$;

create or replace function public.upsert_personal_record_v070(p_season_id uuid,p_key text,p_name text,p_category text,p_user_id uuid,p_value numeric,p_matchday_id uuid,p_is_test boolean)
returns void language plpgsql security definer set search_path=public as $$
declare cur record;
begin
  select * into cur from public.gamification_records where season_id=p_season_id and record_key=p_key and scope='personal' and user_id=p_user_id and is_test=p_is_test and active order by value desc,achieved_at asc limit 1;
  if cur.id is null or p_value>cur.value then
    if cur.id is not null then update public.gamification_records set active=false where id=cur.id; end if;
    insert into public.gamification_records(season_id,record_key,record_name,category,scope,user_id,value,previous_value,matchday_id,is_test,active)
    values(p_season_id,p_key,p_name,p_category,'personal',p_user_id,p_value,cur.value,p_matchday_id,p_is_test,true);
  end if;
end;$$;

create or replace function public.refresh_records_v070(p_season_id uuid,p_matchday_id uuid,p_is_test boolean default false)
returns void language plpgsql security definer set search_path=public as $$
declare r record; total_matches int; finished_matches int;
begin
  -- Les records de journée ne bougent qu'une fois la journée entièrement close.
  select count(*),count(*) filter(where m.status='finished') into total_matches,finished_matches
  from public.matches m
  where m.matchday_id=p_matchday_id and coalesce(m.is_test,false)=p_is_test
    and (not p_is_test or coalesce(m.test_enabled,true)=true)
    and m.status not in ('cancelled','postponed');
  if total_matches=0 or finished_matches<>total_matches then return; end if;

  -- Records personnels : chacun garde son meilleur résultat historique.
  for r in
    select p.user_id,sum(coalesce(p.points,0))::numeric points,count(*) filter(where p.home_score=m.home_score and p.away_score=m.away_score)::numeric exacts
    from public.predictions p join public.matches m on m.id=p.match_id
    where p.season_id=p_season_id and m.matchday_id=p_matchday_id and m.status='finished' and coalesce(m.is_test,false)=p_is_test
    group by p.user_id order by p.user_id
  loop
    perform public.upsert_personal_record_v070(p_season_id,'personal_best_matchday_points','Record personnel · meilleure journée','performance',r.user_id,r.points,p_matchday_id,p_is_test);
    perform public.upsert_personal_record_v070(p_season_id,'personal_best_matchday_exacts','Record personnel · exacts sur une journée','precision',r.user_id,r.exacts,p_matchday_id,p_is_test);
  end loop;

  -- Record du Nid : traiter d'abord la meilleure valeur de la journée évite
  -- plusieurs faux records transitoires au moment du dernier coup de sifflet.
  for r in
    select p.user_id,sum(coalesce(p.points,0))::numeric value
    from public.predictions p join public.matches m on m.id=p.match_id
    where p.season_id=p_season_id and m.matchday_id=p_matchday_id and m.status='finished' and coalesce(m.is_test,false)=p_is_test
    group by p.user_id order by value desc,p.user_id
  loop
    perform public.upsert_record_candidate_v070(p_season_id,'best_matchday_points','Meilleure journée','performance',r.user_id,r.value,p_matchday_id,p_is_test);
  end loop;

  for r in
    select p.user_id,count(*) filter(where p.home_score=m.home_score and p.away_score=m.away_score)::numeric value
    from public.predictions p join public.matches m on m.id=p.match_id
    where p.season_id=p_season_id and m.matchday_id=p_matchday_id and m.status='finished' and coalesce(m.is_test,false)=p_is_test
    group by p.user_id order by value desc,p.user_id
  loop
    perform public.upsert_record_candidate_v070(p_season_id,'best_matchday_exacts','Scores exacts sur une journée','precision',r.user_id,r.value,p_matchday_id,p_is_test);
  end loop;
end;$$;

create or replace function public.gamification_after_match_v070() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status='finished' and (old.status is distinct from new.status or old.home_score is distinct from new.home_score or old.away_score is distinct from new.away_score) then perform public.recalculate_match_points(new.id); perform public.process_match_gamification_v070(new.id); end if;
  return new;
end;$$;
drop trigger if exists z_gamification_after_match_v070 on public.matches;
drop trigger if exists gamification_after_match_v070 on public.matches;
create trigger z_gamification_after_match_v070 after update on public.matches for each row execute function public.gamification_after_match_v070();

-- Les badges de premiers pas doivent tomber au moment de l'action, pas au F5
-- ni au match suivant. Ces déclencheurs ne modifient jamais les vrais points.
create or replace function public.gamification_after_prediction_v070() returns trigger language plpgsql security definer set search_path=public as $$
declare tst boolean;
begin
  select coalesce(is_test,false) into tst from public.matches where id=new.match_id;
  perform public.evaluate_badges_v070(new.user_id,new.season_id,coalesce(tst,false),'automatic');
  return new;
end;$$;
drop trigger if exists gamification_after_prediction_v070 on public.predictions;
create trigger gamification_after_prediction_v070 after insert or update of home_score,away_score on public.predictions for each row execute function public.gamification_after_prediction_v070();

create or replace function public.gamification_after_team_membership_v070() returns trigger language plpgsql security definer set search_path=public as $$
begin
  perform public.evaluate_badges_v070(new.user_id,new.season_id,false,'automatic');
  return new;
end;$$;
drop trigger if exists gamification_after_team_membership_v070 on public.team_memberships;
create trigger gamification_after_team_membership_v070 after insert on public.team_memberships for each row execute function public.gamification_after_team_membership_v070();

create or replace function public.gamification_after_rival_duel_v070() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.result is not null then perform public.evaluate_badges_v070(new.user_id,new.season_id,false,'automatic'); end if;
  return new;
end;$$;
drop trigger if exists gamification_after_rival_duel_v070 on public.rival_duels;
create trigger gamification_after_rival_duel_v070 after insert or update of result on public.rival_duels for each row execute function public.gamification_after_rival_duel_v070();

-- -----------------------------------------------------------------------------
-- 7b. Casserole champion éliminé : uniquement phases précoces configurées.
-- Par défaut : barrage = belle, huitièmes = petite, quarts et après = aucune.
-- -----------------------------------------------------------------------------
create or replace function public.gamification_after_champion_elimination_v070()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_phase text; v_severity text; v_points int; v_matchday uuid; v_settings public.gamification_settings%rowtype; v_event uuid;
begin
  if new.eliminated_at is null or old.eliminated_at is not null then return new; end if;
  select * into v_settings from public.gamification_settings where season_id=new.season_id;
  select ph.code,m.matchday_id into v_phase,v_matchday
  from public.knockout_ties t
  join public.competition_phases ph on ph.id=t.phase_id
  left join lateral (
    select mm.matchday_id,mm.kickoff_at from public.matches mm where mm.tie_id=t.id order by mm.kickoff_at desc limit 1
  ) m on true
  where t.season_id=new.season_id and t.status='finished' and (t.team_a_club_id=new.club_id or t.team_b_club_id=new.club_id) and t.qualified_club_id is distinct from new.club_id
  order by ph.sort_order desc limit 1;
  if v_phase is null then return new; end if;
  v_severity:=coalesce(v_settings.champion_casserole_phases->>v_phase,'none');
  if v_severity='none' or v_severity not in ('small','beautiful','industrial','nuclear') then return new; end if;
  if exists(select 1 from public.gamification_events e where e.season_id=new.season_id and e.user_id=new.user_id and e.event_type='casserole' and e.subtype='champion_eliminated' and not e.is_test and e.metadata->>'club_id'=new.club_id::text) then return new; end if;
  v_points:=case v_severity when 'nuclear' then coalesce((v_settings.casserole_points->>'nuclear')::int,10) when 'industrial' then coalesce((v_settings.casserole_points->>'industrial')::int,5) when 'beautiful' then coalesce((v_settings.casserole_points->>'beautiful')::int,3) else coalesce((v_settings.casserole_points->>'small')::int,1) end;
  insert into public.gamification_events(season_id,user_id,event_type,subtype,severity,points,matchday_id,title,message,labels,metadata,is_manual,is_test,is_public)
  values(new.season_id,new.user_id,'casserole','champion_eliminated',v_severity,v_points,v_matchday,'Champion éliminé',public.narrative_text_v070('champion_out',jsonb_build_object('player',(select username from public.profiles where id=new.user_id),'phase',v_phase,'points',v_points),'Ton champion quitte la compétition plus tôt que prévu.','automatic'),jsonb_build_array('champion éliminé',v_phase),jsonb_build_object('club_id',new.club_id,'pick_number',new.pick_number,'phase',v_phase),false,false,true)
  returning id into v_event;
  insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
  values(new.user_id,new.season_id,'gamification','🍳 Champion éliminé',public.narrative_text_v070('champion_out',jsonb_build_object('player',(select username from public.profiles where id=new.user_id),'phase',v_phase,'points',v_points),'Le Hibou sort une petite poêle pour ce champion éliminé.','automatic'),'info','museum:casseroles',jsonb_build_object('event_id',v_event,'club_id',new.club_id,'phase',v_phase),'champion-casserole:'||new.user_id::text||':'||new.club_id::text,true)
  on conflict(user_id,source_key) where source_key is not null do nothing;
  perform public.evaluate_badges_v070(new.user_id,new.season_id,false,'automatic');
  return new;
end;$$;
drop trigger if exists gamification_after_champion_elimination_v070 on public.champion_predictions;
create trigger gamification_after_champion_elimination_v070 after update of eliminated_at on public.champion_predictions for each row execute function public.gamification_after_champion_elimination_v070();

-- -----------------------------------------------------------------------------
-- 8. Classement LIVE TEST séparé.
-- -----------------------------------------------------------------------------
create or replace function public.get_test_leaderboard_v070(p_season_id uuid,p_include_live boolean default true)
returns table(rank bigint,previous_rank bigint,variation bigint,user_id uuid,username text,avatar_key text,club_heart text,points numeric,official_points numeric,exact_scores bigint,good_differences bigint,good_results bigint,played bigint,average numeric,precision_pct numeric,above_gap numeric,below_gap numeric)
language sql stable security definer set search_path=public as $$
with stats as (
 select pr.id user_id,pr.username::text username,pr.avatar_key,pr.club_heart,
 coalesce(sum(case when p.id is null then 0 when m.status='finished' then p.points when p_include_live and m.status='live' and m.home_score is not null and m.away_score is not null then public.score_prediction_values_v030(p_season_id,p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier) else 0 end),0)::numeric points,
 coalesce(sum(case when m.status='finished' then p.points else 0 end),0)::numeric official_points,
 count(*) filter(where p.id is not null and m.status in ('live','finished') and p.home_score=m.home_score and p.away_score=m.away_score) exact_scores,
 count(*) filter(where p.id is not null and m.status in ('live','finished') and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score) and (p.home_score-p.away_score)=(m.home_score-m.away_score)) good_differences,
 count(*) filter(where p.id is not null and m.status in ('live','finished') and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)) good_results,
 count(*) filter(where p.id is not null and m.status in ('live','finished')) played
 from public.profiles pr cross join public.matches m left join public.predictions p on p.match_id=m.id and p.user_id=pr.id
 where pr.status='active' and m.season_id=p_season_id and coalesce(m.is_test,false)=true and coalesce(m.test_enabled,true)=true
 group by pr.id,pr.username,pr.avatar_key,pr.club_heart
), ranked as (select *,case when played>0 then round(points/played,2) else 0 end average,case when played>0 then round(100.0*good_results/played,1) else 0 end precision_pct,rank() over(order by points desc,exact_scores desc,good_differences desc,played desc,username) rank from stats)
select rank,null::bigint previous_rank,0::bigint variation,user_id,username,avatar_key,club_heart,points,official_points,exact_scores,good_differences,good_results,played,average,precision_pct,null::numeric above_gap,null::numeric below_gap from ranked order by rank,username;
$$;

-- -----------------------------------------------------------------------------
-- 9. RPC Musée et administration.
-- -----------------------------------------------------------------------------
create or replace function public.get_museum_summary_v070(p_user_id uuid,p_season_id uuid,p_is_test boolean default false)
returns jsonb language sql stable security definer set search_path=public as $$
with visible_badges as (
  select b.*,
         pb.id as player_badge_id,pb.earned_at,pb.first_discovery,
         (pb.id is not null) as obtained,
         (public.is_super_admin() or exists(
           select 1 from public.player_badges mine
           where mine.badge_id=b.id and mine.user_id=auth.uid() and mine.revoked_at is null and mine.is_test=p_is_test
         )) as viewer_knows_secret
  from public.gamification_badges b
  left join public.player_badges pb on pb.badge_id=b.id and pb.user_id=p_user_id and pb.revoked_at is null and pb.is_test=p_is_test and (b.scope='career' or pb.season_id=p_season_id)
  where b.active and b.archived_at is null
    and (b.secret_visibility<>'hidden' or public.is_super_admin() or exists(
      select 1 from public.player_badges mine
      where mine.badge_id=b.id and mine.user_id=auth.uid() and mine.revoked_at is null and mine.is_test=p_is_test
    ))
)
select jsonb_build_object(
 'metrics',public.gamification_metrics_v070(p_user_id,p_season_id,p_is_test),
 'badges',(select coalesce(jsonb_agg(jsonb_build_object(
   'player_badge_id',player_badge_id,'badge_id',id,
   'code',case when is_secret and not viewer_knows_secret then null else code end,
   'name',case when is_secret and not viewer_knows_secret then '???' else name end,
   'description',case when is_secret and not viewer_knows_secret then 'Secret non découvert' else description end,
   'category',category,'rarity',rarity,'is_secret',is_secret,'secret_visibility',secret_visibility,'scope',scope,
   'image_url',case when is_secret and not viewer_knows_secret then null else image_url end,
   'default_asset_path',case when is_secret and not viewer_knows_secret then null else default_asset_path end,
   'condition_json',case when is_secret and not viewer_knows_secret then null else condition_json end,
   'auto_evaluate',case when is_secret and not viewer_knows_secret then false else auto_evaluate end,
   'earned_at',earned_at,'first_discovery',case when viewer_knows_secret then coalesce(first_discovery,false) else false end,
   'obtained',obtained,'secret_known_to_viewer',viewer_knows_secret
 ) order by sort_order), '[]'::jsonb) from visible_badges),
 'events',(select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at desc),'[]'::jsonb) from (select * from public.gamification_events where user_id=p_user_id and season_id=p_season_id and is_test=p_is_test and (is_public or user_id=auth.uid() or public.is_super_admin()) order by created_at desc limit 100) e),
 'records',(select coalesce(jsonb_agg(to_jsonb(r) order by r.achieved_at desc),'[]'::jsonb) from (select * from public.gamification_records where user_id=p_user_id and season_id=p_season_id and is_test=p_is_test order by achieved_at desc limit 100) r),
 'casserole_ranking',(select coalesce(jsonb_agg(to_jsonb(x) order by x.rank),'[]'::jsonb) from (
   select rank() over(order by sum(e.points) desc,count(*) filter(where e.severity='nuclear') desc,count(*) filter(where e.severity='industrial') desc,count(*) filter(where e.severity='beautiful') desc,min(e.created_at)) rank,e.user_id,p.username,sum(e.points)::int points,count(*)::int total,count(*) filter(where e.severity='nuclear')::int nuclear,count(*) filter(where e.severity='industrial')::int industrial,count(*) filter(where e.severity='beautiful')::int beautiful,count(*) filter(where e.severity='small')::int small
   from public.gamification_events e join public.profiles p on p.id=e.user_id where e.season_id=p_season_id and e.is_test=p_is_test and e.event_type='casserole' group by e.user_id,p.username order by points desc limit 100
 ) x),
 'genius_ranking',(select coalesce(jsonb_agg(to_jsonb(x) order by x.rank),'[]'::jsonb) from (
   select rank() over(order by sum(e.points) desc,count(*) filter(where e.points>=10) desc,min(e.created_at)) rank,e.user_id,p.username,sum(e.points)::int points,count(*)::int total,count(*) filter(where e.points>=10)::int prophetic
   from public.gamification_events e join public.profiles p on p.id=e.user_id where e.season_id=p_season_id and e.is_test=p_is_test and e.event_type='genius' group by e.user_id,p.username order by points desc limit 100
 ) x)
);$$;

create or replace function public.admin_upsert_badge_v070(p_badge_id uuid,p_payload jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; before_row jsonb;
begin if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
 if p_badge_id is not null then select to_jsonb(b) into before_row from public.gamification_badges b where id=p_badge_id; update public.gamification_badges set name=coalesce(p_payload->>'name',name),description=coalesce(p_payload->>'description',description),category=coalesce(p_payload->>'category',category),rarity=coalesce(p_payload->>'rarity',rarity),is_secret=coalesce((p_payload->>'is_secret')::boolean,is_secret),secret_visibility=coalesce(p_payload->>'secret_visibility',secret_visibility),scope=coalesce(p_payload->>'scope',scope),image_url=case when p_payload ? 'image_url' then nullif(p_payload->>'image_url','') else image_url end,condition_json=coalesce(p_payload->'condition_json',condition_json),auto_evaluate=coalesce((p_payload->>'auto_evaluate')::boolean,auto_evaluate),retro_mode=coalesce(p_payload->>'retro_mode',retro_mode),active=coalesce((p_payload->>'active')::boolean,active) where id=p_badge_id returning id into v_id;
 else insert into public.gamification_badges(code,name,description,category,rarity,is_secret,secret_visibility,scope,image_url,condition_json,auto_evaluate,retro_mode,active,sort_order,created_by) values(coalesce(nullif(p_payload->>'code',''),'badge-'||replace(gen_random_uuid()::text,'-','')),p_payload->>'name',coalesce(p_payload->>'description',''),coalesce(p_payload->>'category','performance'),coalesce(p_payload->>'rarity','common'),coalesce((p_payload->>'is_secret')::boolean,false),coalesce(p_payload->>'secret_visibility','public'),coalesce(p_payload->>'scope','season'),nullif(p_payload->>'image_url',''),coalesce(p_payload->'condition_json','{"manual":true}'::jsonb),coalesce((p_payload->>'auto_evaluate')::boolean,false),coalesce(p_payload->>'retro_mode','season'),coalesce((p_payload->>'active')::boolean,true),(select coalesce(max(sort_order),0)+1 from public.gamification_badges),auth.uid()) returning id into v_id; end if;
 insert into public.gamification_audit(actor_id,action,entity_type,entity_id,before_data,after_data) select auth.uid(),case when p_badge_id is null then 'create' else 'update' end,'badge',v_id::text,before_row,to_jsonb(b) from public.gamification_badges b where b.id=v_id; return v_id; end;$$;

create or replace function public.admin_archive_badge_v070(p_badge_id uuid,p_reason text default null) returns void language plpgsql security definer set search_path=public as $$
declare before_row jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  select to_jsonb(b) into before_row from public.gamification_badges b where b.id=p_badge_id;
  if before_row is null then raise exception 'Badge introuvable.'; end if;
  update public.gamification_badges set active=false,archived_at=coalesce(archived_at,now()) where id=p_badge_id;
  insert into public.gamification_audit(actor_id,action,entity_type,entity_id,before_data,after_data,reason)
  select auth.uid(),'archive','badge',b.id::text,before_row,to_jsonb(b),p_reason from public.gamification_badges b where b.id=p_badge_id;
end;$$;

create or replace function public.admin_award_badge_v070(p_badge_id uuid,p_user_id uuid,p_season_id uuid,p_context jsonb default '{}'::jsonb,p_is_test boolean default false,p_notify boolean default true) returns uuid language plpgsql security definer set search_path=public as $$
declare v uuid; b public.gamification_badges%rowtype; first_found boolean;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  select * into b from public.gamification_badges where id=p_badge_id; if not found then raise exception 'Badge introuvable.'; end if;
  first_found:=b.is_secret and not exists(select 1 from public.player_badges where badge_id=b.id and revoked_at is null and is_test=p_is_test);
  insert into public.player_badges(badge_id,user_id,season_id,context,source,is_test,first_discovery,awarded_by)
  values(b.id,p_user_id,case when b.scope='career' then null else p_season_id end,p_context,case when p_is_test then 'test' else 'manual' end,p_is_test,first_found,auth.uid()) returning id into v;
  insert into public.gamification_audit(season_id,actor_id,action,entity_type,entity_id,after_data,is_test) values(p_season_id,auth.uid(),'award','player_badge',v::text,p_context,p_is_test);
  if p_notify and not p_is_test then
    insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
    values(p_user_id,p_season_id,'badge','🏅 Badge attribué par le Hibou',case when b.is_secret then 'Un secret vient de rejoindre ton Musée.' else b.name||' — '||b.description end,'important','museum:badges',jsonb_build_object('badge_id',b.id),'badge-manual:'||v,true)
    on conflict(user_id,source_key) where source_key is not null do nothing;
  end if;
  if first_found and not p_is_test then
    insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
    select p.id,p_season_id,'badge','🕵️ Un secret du Nid a été découvert',
      public.narrative_text_v070('secret_found',jsonb_build_object('player',pr.username,'team',coalesce(t.name,'')),pr.username||coalesce(' de la Team '||t.name,'')||' vient de découvrir quelque chose. Le Hibou ne dira absolument pas quoi.','automatic'),
      'important','museum:badges',jsonb_build_object('discoverer_id',p_user_id,'badge_hidden',true),'secret-first:'||b.id::text||':'||p.id::text,true
    from public.profiles p cross join public.profiles pr
    left join public.team_memberships tm on tm.user_id=p_user_id and tm.season_id=p_season_id and tm.left_at is null
    left join public.teams t on t.id=tm.team_id
    where pr.id=p_user_id and p.status='active' and p.id<>p_user_id
    on conflict(user_id,source_key) where source_key is not null do nothing;
  end if;
  return v;
end;$$;

create or replace function public.admin_revoke_badge_v070(p_player_badge_id uuid,p_reason text) returns void language plpgsql security definer set search_path=public as $$
declare before_row jsonb; sid uuid; tst boolean; begin if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if; select to_jsonb(pb),pb.season_id,pb.is_test into before_row,sid,tst from public.player_badges pb where id=p_player_badge_id; update public.player_badges set revoked_at=now(),revoked_by=auth.uid(),revoke_reason=p_reason where id=p_player_badge_id; insert into public.gamification_audit(season_id,actor_id,action,entity_type,entity_id,before_data,reason,is_test) values(sid,auth.uid(),'revoke','player_badge',p_player_badge_id::text,before_row,p_reason,tst); end;$$;

create or replace function public.admin_add_gamification_event_v070(p_payload jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare v uuid; sid uuid; uid uuid; typ text; tst boolean; pub boolean; notify_user boolean; announce_global boolean; pts int; ttl text; msg text;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  sid:=(p_payload->>'season_id')::uuid; uid:=(p_payload->>'user_id')::uuid; typ:=p_payload->>'event_type'; tst:=coalesce((p_payload->>'is_test')::boolean,false); pub:=coalesce((p_payload->>'is_public')::boolean,true); notify_user:=coalesce((p_payload->>'notify')::boolean,true); announce_global:=coalesce((p_payload->>'announce_global')::boolean,false); pts:=coalesce((p_payload->>'points')::int,0); ttl:=nullif(p_payload->>'title',''); msg:=nullif(p_payload->>'message','');
  if typ not in ('casserole','genius') then raise exception 'Type manuel invalide.'; end if;
  insert into public.gamification_events(season_id,user_id,event_type,subtype,severity,points,match_id,matchday_id,title,message,media_url,labels,metadata,is_manual,is_test,is_public,created_by)
  values(sid,uid,typ,coalesce(p_payload->>'subtype','manual'),nullif(p_payload->>'severity',''),pts,nullif(p_payload->>'match_id','')::uuid,nullif(p_payload->>'matchday_id','')::uuid,ttl,msg,nullif(p_payload->>'media_url',''),coalesce(p_payload->'labels','[]'::jsonb),coalesce(p_payload->'metadata','{}'::jsonb),true,tst,pub,auth.uid()) returning id into v;
  insert into public.gamification_audit(season_id,actor_id,action,entity_type,entity_id,after_data,is_test) values(sid,auth.uid(),'create','gamification_event',v::text,p_payload,tst);
  perform public.evaluate_badges_v070(uid,sid,tst,'manual');
  if notify_user and not tst then
    insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
    values(uid,sid,'gamification',coalesce(ttl,case when typ='casserole' then '🍳 Casserole du Hibou' else '✨ Coup de génie du Hibou' end),coalesce(msg,'Le Hibou vient d’ajouter une pièce à ton Musée.'),'important',case when typ='casserole' then 'museum:casseroles' else 'museum:genius' end,jsonb_build_object('event_id',v,'event_type',typ,'points',pts),'manual-gami:'||v::text,true)
    on conflict(user_id,source_key) where source_key is not null do nothing;
  end if;
  if announce_global and pub and not tst then
    insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
    select p.id,sid,'gamification',coalesce(ttl,case when typ='casserole' then '🍳 Le Hibou sort la poêle' else '✨ Le Hibou salue un coup de génie' end),coalesce(msg,(select username from public.profiles where id=uid)||' vient d’entrer au Musée.'),'important',case when typ='casserole' then 'museum:casseroles' else 'museum:genius' end,jsonb_build_object('event_id',v,'player_id',uid,'event_type',typ,'points',pts),'manual-gami-global:'||v::text||':'||p.id::text,true
    from public.profiles p where p.status='active' and p.id<>uid
    on conflict(user_id,source_key) where source_key is not null do nothing;
  end if;
  return v;
end;$$;

create or replace function public.admin_update_gamification_event_v070(p_event_id uuid,p_points int,p_message text,p_reason text) returns void language plpgsql security definer set search_path=public as $$
declare b jsonb; a jsonb; sid uuid; tst boolean; begin if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if; select to_jsonb(e),e.season_id,e.is_test into b,sid,tst from public.gamification_events e where id=p_event_id; update public.gamification_events set points=p_points,message=p_message where id=p_event_id; select to_jsonb(e) into a from public.gamification_events e where e.id=p_event_id; insert into public.gamification_audit(season_id,actor_id,action,entity_type,entity_id,before_data,after_data,reason,is_test) values(sid,auth.uid(),'update','gamification_event',p_event_id::text,b,a,p_reason,tst); end;$$;

create or replace function public.admin_update_gamification_settings_v070(p_season_id uuid,p_payload jsonb) returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  insert into public.gamification_settings(season_id,casserole_thresholds,casserole_points,casserole_rules,champion_casserole_phases,genius_thresholds,record_thresholds,record_categories,secret_retro_notify)
  values(p_season_id,
    coalesce(p_payload->'casserole_thresholds','{"small":3,"beautiful":4,"industrial":6,"nuclear":8}'::jsonb),
    coalesce(p_payload->'casserole_points','{"small":1,"beautiful":3,"industrial":5,"nuclear":10}'::jsonb),
    coalesce(p_payload->'casserole_rules','{"zero_small":3,"zero_beautiful":5,"zero_nuclear":8,"full_matchday_severity":"industrial"}'::jsonb),
    coalesce(p_payload->'champion_casserole_phases','{"KNOCKOUT_PLAYOFF":"beautiful","ROUND_OF_16":"small","QUARTER_FINAL":"none","SEMI_FINAL":"none","FINAL":"none"}'::jsonb),
    coalesce(p_payload->'genius_thresholds','{"minimum_predictions":5,"p20":1,"p10":3,"p5":5,"p2":7,"unique":10,"exact_bonus":2,"max":10}'::jsonb),
    coalesce(p_payload->'record_thresholds','{"precision_evening":5,"precision_period":20,"precision_season":30}'::jsonb),
    coalesce(p_payload->'record_categories','["performance","precision","series","ranking","rivalries","casseroles","genius","unusual"]'::jsonb),
    case when p_payload ? 'secret_retro_notify' then (p_payload->>'secret_retro_notify')::boolean else null end)
  on conflict(season_id) do update set
    casserole_thresholds=coalesce(p_payload->'casserole_thresholds',gamification_settings.casserole_thresholds),
    casserole_points=coalesce(p_payload->'casserole_points',gamification_settings.casserole_points),
    casserole_rules=coalesce(p_payload->'casserole_rules',gamification_settings.casserole_rules),
    champion_casserole_phases=coalesce(p_payload->'champion_casserole_phases',gamification_settings.champion_casserole_phases),
    genius_thresholds=coalesce(p_payload->'genius_thresholds',gamification_settings.genius_thresholds),
    record_thresholds=coalesce(p_payload->'record_thresholds',gamification_settings.record_thresholds),
    record_categories=coalesce(p_payload->'record_categories',gamification_settings.record_categories),
    secret_retro_notify=case when p_payload ? 'secret_retro_notify' then (p_payload->>'secret_retro_notify')::boolean else gamification_settings.secret_retro_notify end,
    updated_at=now();
  insert into public.gamification_audit(season_id,actor_id,action,entity_type,after_data) values(p_season_id,auth.uid(),'update','gamification_settings',p_payload);
end;$$;

create or replace function public.admin_upsert_narrative_template_v070(p_id bigint,p_payload jsonb) returns bigint language plpgsql security definer set search_path=public as $$
declare v bigint;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_id is null then
    insert into public.gamification_text_templates(event_key,tone,template,weight,active)
    values(p_payload->>'event_key',coalesce(p_payload->>'tone','automatic'),p_payload->>'template',coalesce((p_payload->>'weight')::numeric,1),coalesce((p_payload->>'active')::boolean,true)) returning id into v;
  else
    update public.gamification_text_templates set event_key=coalesce(p_payload->>'event_key',event_key),tone=coalesce(p_payload->>'tone',tone),template=coalesce(p_payload->>'template',template),weight=coalesce((p_payload->>'weight')::numeric,weight),active=coalesce((p_payload->>'active')::boolean,active) where id=p_id returning id into v;
  end if;
  if v is null then raise exception 'Texte narratif introuvable.'; end if;
  insert into public.gamification_audit(actor_id,action,entity_type,entity_id,after_data) values(auth.uid(),case when p_id is null then 'create' else 'update' end,'narrative_template',v::text,p_payload);
  return v;
end;$$;

create or replace function public.admin_set_gamification_test_enabled_v070(p_season_id uuid,p_enabled boolean) returns void language plpgsql security definer set search_path=public as $$ begin if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if; insert into public.gamification_settings(season_id,test_enabled) values(p_season_id,p_enabled) on conflict(season_id) do update set test_enabled=excluded.test_enabled,updated_at=now(); end;$$;

create or replace function public.admin_clear_gamification_test_v070(p_season_id uuid) returns jsonb language plpgsql security definer set search_path=public as $$
declare b int;e int;r int; begin if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if; select count(*) into b from public.player_badges where season_id=p_season_id and is_test; select count(*) into e from public.gamification_events where season_id=p_season_id and is_test; select count(*) into r from public.gamification_records where season_id=p_season_id and is_test; insert into public.gamification_audit(season_id,actor_id,action,entity_type,after_data,is_test) values(p_season_id,auth.uid(),'clear_test','gamification_test',jsonb_build_object('badges',b,'events',e,'records',r),true); delete from public.player_badges where season_id=p_season_id and is_test; delete from public.gamification_events where season_id=p_season_id and is_test; delete from public.gamification_records where season_id=p_season_id and is_test; return jsonb_build_object('badges',b,'events',e,'records',r); end;$$;

create or replace function public.admin_recalculate_gamification_v070(p_season_id uuid,p_is_test boolean default false,p_execute boolean default false) returns jsonb language plpgsql security definer set search_path=public as $$
declare u record; would_award int:=0; total_preview int:=0; actual int:=0; begin if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if; for u in select id from public.profiles where status='active' loop if p_execute then actual:=actual+public.evaluate_badges_v070(u.id,p_season_id,p_is_test,'migration'); else select count(*) into would_award from public.gamification_badges b where b.active and b.auto_evaluate and public.eval_badge_condition_v070(b.condition_json,public.gamification_metrics_v070(u.id,p_season_id,p_is_test)) and not exists(select 1 from public.player_badges pb where pb.badge_id=b.id and pb.user_id=u.id and pb.revoked_at is null and pb.is_test=p_is_test); total_preview:=total_preview+would_award; end if; end loop; if p_execute then insert into public.gamification_audit(season_id,actor_id,action,entity_type,after_data,is_test) values(p_season_id,auth.uid(),'recalculate','season',jsonb_build_object('awarded',actual),p_is_test); return jsonb_build_object('execute',true,'awarded',actual); end if; return jsonb_build_object('execute',false,'would_award',total_preview,'preview_note','Aucun retrait automatique : seuls de nouveaux badges peuvent être attribués.'); end;$$;

create or replace function public.admin_preview_gamification_close_v070(p_season_id uuid) returns jsonb language sql stable security definer set search_path=public as $$
with casserole_stats as (
  select e.user_id,sum(e.points)::int as points,
         count(*) filter(where e.severity='nuclear')::int as nuclear,
         count(*) filter(where e.severity='industrial')::int as industrial,
         count(*) filter(where e.severity='beautiful')::int as beautiful,
         count(*) filter(where e.severity='small')::int as small
  from public.gamification_events e where e.season_id=p_season_id and e.event_type='casserole' and not e.is_test group by e.user_id
), casserole_top as (
  select * from casserole_stats order by points desc,nuclear desc,industrial desc,beautiful desc limit 1
), poele as (
  select s.* from casserole_stats s,casserole_top t where (s.points,s.nuclear,s.industrial,s.beautiful)=(t.points,t.nuclear,t.industrial,t.beautiful)
), genius_stats as (
  select e.user_id,sum(e.points)::int as points,count(*)::int as events from public.gamification_events e where e.season_id=p_season_id and e.event_type='genius' and not e.is_test group by e.user_id
), genius_top as (select coalesce(max(points),0) points from genius_stats), genius as (select s.* from genius_stats s,genius_top t where s.points=t.points and t.points>0)
select case when not public.is_super_admin() then (select jsonb_build_object('error','Réservé au Super Admin.')) else jsonb_build_object(
 'poele_winners',coalesce((select jsonb_agg(jsonb_build_object('user_id',p.user_id,'username',pr.username,'points',p.points,'nuclear',p.nuclear,'industrial',p.industrial,'beautiful',p.beautiful,'small',p.small) order by pr.username) from poele p join public.profiles pr on pr.id=p.user_id),'[]'::jsonb),
 'genius_winners',coalesce((select jsonb_agg(jsonb_build_object('user_id',g.user_id,'username',pr.username,'points',g.points,'events',g.events) order by pr.username) from genius g join public.profiles pr on pr.id=g.user_id),'[]'::jsonb),
 'records',(select count(*) from public.gamification_records where season_id=p_season_id and not is_test),
 'active_records',(select count(*) from public.gamification_records where season_id=p_season_id and not is_test and active),
 'closed',exists(select 1 from public.gamification_settings where season_id=p_season_id and closed_at is not null)
) end;
$$;

create or replace function public.admin_close_gamification_v070(p_season_id uuid) returns jsonb language plpgsql security definer set search_path=public as $$
declare preview jsonb; w jsonb; badge_id uuid; u record;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if exists(select 1 from public.gamification_settings where season_id=p_season_id and closed_at is not null) then raise exception 'La gamification est déjà clôturée.'; end if;
  -- Dernier recalcul avant gel : ajoute uniquement ce qui manque, sans retirer de badge.
  for u in select id from public.profiles where status='active' loop perform public.evaluate_badges_v070(u.id,p_season_id,false,'automatic'); end loop;
  preview:=public.admin_preview_gamification_close_v070(p_season_id);
  select id into badge_id from public.gamification_badges where code='badge-poele-or' limit 1;
  if badge_id is not null then
    for w in select value from jsonb_array_elements(coalesce(preview->'poele_winners','[]'::jsonb)) loop
      if not exists(select 1 from public.player_badges pb where pb.badge_id=badge_id and pb.user_id=(w->>'user_id')::uuid and pb.season_id=p_season_id and not pb.is_test and pb.revoked_at is null) then
        perform public.admin_award_badge_v070(badge_id,(w->>'user_id')::uuid,p_season_id,jsonb_build_object('reason','Poêle d''Or','final_points',w->>'points'),false,true);
      end if;
    end loop;
  end if;
  update public.gamification_settings set closed_at=now(),closed_by=auth.uid(),updated_at=now() where season_id=p_season_id;
  insert into public.gamification_audit(season_id,actor_id,action,entity_type,after_data) values(p_season_id,auth.uid(),'close','season',preview);
  return preview||jsonb_build_object('closed',true,'closed_at',now());
end;$$;

create or replace function public.admin_reopen_gamification_v070(p_season_id uuid,p_reason text) returns void language plpgsql security definer set search_path=public as $$ begin if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if; update public.gamification_settings set closed_at=null,closed_by=null,updated_at=now() where season_id=p_season_id; insert into public.gamification_audit(season_id,actor_id,action,entity_type,reason) values(p_season_id,auth.uid(),'reopen','season',p_reason); end;$$;

-- -----------------------------------------------------------------------------
-- 9b. Laboratoire accéléré : faux pronostics et fin de match TEST.
-- -----------------------------------------------------------------------------
create or replace function public.admin_seed_test_predictions_v070(p_match_id uuid,p_home_pct int,p_draw_pct int,p_away_pct int)
returns jsonb language plpgsql security definer set search_path=public as $$
declare m public.matches%rowtype; u record; i int:=0; total int:=0; h int:=0; d int:=0; a int:=0; bucket numeric;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  select * into m from public.matches where id=p_match_id and coalesce(is_test,false)=true;
  if not found then raise exception 'Match TEST introuvable.'; end if;
  if p_home_pct<0 or p_draw_pct<0 or p_away_pct<0 or p_home_pct+p_draw_pct+p_away_pct<>100 then raise exception 'Les pourcentages doivent totaliser 100.'; end if;
  select count(*) into total from public.profiles where status='active';
  delete from public.predictions where match_id=p_match_id;
  for u in select id from public.profiles where status='active' order by id loop
    i:=i+1; bucket:=((i-1)*100.0/greatest(total,1));
    if bucket<p_home_pct then
      insert into public.predictions(season_id,match_id,user_id,home_score,away_score) values(m.season_id,m.id,u.id,2,1); h:=h+1;
    elsif bucket<p_home_pct+p_draw_pct then
      insert into public.predictions(season_id,match_id,user_id,home_score,away_score) values(m.season_id,m.id,u.id,1,1); d:=d+1;
    else
      insert into public.predictions(season_id,match_id,user_id,home_score,away_score) values(m.season_id,m.id,u.id,1,2); a:=a+1;
    end if;
  end loop;
  insert into public.gamification_audit(season_id,actor_id,action,entity_type,entity_id,after_data,is_test)
  values(m.season_id,auth.uid(),'seed_test_predictions','match',m.id::text,jsonb_build_object('home',h,'draw',d,'away',a),true);
  return jsonb_build_object('total',total,'home',h,'draw',d,'away',a);
end;$$;

create or replace function public.admin_simulate_test_match_v070(p_match_id uuid,p_home_score int,p_away_score int)
returns jsonb language plpgsql security definer set search_path=public as $$
declare m public.matches%rowtype; res jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  select * into m from public.matches where id=p_match_id and coalesce(is_test,false)=true;
  if not found then raise exception 'Match TEST introuvable.'; end if;
  update public.matches set status='finished',home_score=greatest(0,p_home_score),away_score=greatest(0,p_away_score),updated_at=now() where id=p_match_id;
  res:=public.process_match_gamification_v070(p_match_id);
  return res;
end;$$;

create or replace function public.admin_preview_badge_v070(p_badge_id uuid,p_user_id uuid,p_season_id uuid,p_is_test boolean default false)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare b public.gamification_badges%rowtype; metrics jsonb;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  select * into b from public.gamification_badges where id=p_badge_id;
  if not found then raise exception 'Badge introuvable.'; end if;
  metrics:=public.gamification_metrics_v070(p_user_id,p_season_id,p_is_test);
  return jsonb_build_object('badge_id',b.id,'name',b.name,'condition',b.condition_json,'metrics',metrics,'eligible',public.eval_badge_condition_v070(b.condition_json,metrics));
end;$$;

grant execute on function public.admin_seed_test_predictions_v070(uuid,int,int,int) to authenticated;
grant execute on function public.admin_simulate_test_match_v070(uuid,int,int) to authenticated;
grant execute on function public.admin_preview_badge_v070(uuid,uuid,uuid,boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- 9c. Médias Gamification : images, mèmes, captures et visuels de badges.
-- -----------------------------------------------------------------------------
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('gamification-media','gamification-media',true,5242880,array['image/png','image/jpeg','image/webp'])
on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists gamification_media_public_read on storage.objects;
create policy gamification_media_public_read on storage.objects for select using(bucket_id='gamification-media');
drop policy if exists gamification_media_super_insert on storage.objects;
create policy gamification_media_super_insert on storage.objects for insert to authenticated with check(bucket_id='gamification-media' and public.is_super_admin());
drop policy if exists gamification_media_super_update on storage.objects;
create policy gamification_media_super_update on storage.objects for update to authenticated using(bucket_id='gamification-media' and public.is_super_admin()) with check(bucket_id='gamification-media' and public.is_super_admin());
drop policy if exists gamification_media_super_delete on storage.objects;
create policy gamification_media_super_delete on storage.objects for delete to authenticated using(bucket_id='gamification-media' and public.is_super_admin());

-- -----------------------------------------------------------------------------
-- 9d. Notification ciblée du laboratoire Gamification.
-- Jamais de diffusion globale depuis ce RPC.
-- -----------------------------------------------------------------------------
create or replace function public.admin_send_gamification_test_notification_v070(
  p_user_id uuid,
  p_season_id uuid,
  p_title text,
  p_body text,
  p_push boolean default true
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_source text;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if not exists(select 1 from public.profiles where id=p_user_id and status='active') then raise exception 'Joueur introuvable ou inactif.'; end if;
  v_source:='gami-test:'||replace(gen_random_uuid()::text,'-','');
  insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested)
  values(p_user_id,p_season_id,'gamification','🧪 '||trim(coalesce(nullif(p_title,''),'TEST Gamification')),trim(coalesce(nullif(p_body,''),'Notification du laboratoire Gamification.')),'info','museum',jsonb_build_object('is_test',true,'source','gamification_lab'),v_source,p_push)
  returning id into v_id;
  insert into public.gamification_audit(season_id,actor_id,action,entity_type,entity_id,after_data,is_test)
  values(p_season_id,auth.uid(),'send_test_notification','notification',v_id::text,jsonb_build_object('target_user_id',p_user_id,'push',p_push),true);
  return v_id;
end;$$;
grant execute on function public.admin_send_gamification_test_notification_v070(uuid,uuid,text,text,boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- 10. RLS. Musée public, mutations réservées au Super Admin.
-- -----------------------------------------------------------------------------
alter table public.gamification_badges enable row level security; alter table public.player_badges enable row level security; alter table public.gamification_events enable row level security; alter table public.gamification_records enable row level security; alter table public.gamification_settings enable row level security; alter table public.gamification_audit enable row level security; alter table public.gamification_text_templates enable row level security;
drop policy if exists gamification_badges_read on public.gamification_badges;
create policy gamification_badges_read on public.gamification_badges for select to authenticated using(
  public.is_super_admin() or (active and not is_secret) or (active and is_secret and exists(
    select 1 from public.player_badges mine where mine.badge_id=gamification_badges.id and mine.user_id=auth.uid() and mine.revoked_at is null and mine.is_test=false
  ))
);
drop policy if exists player_badges_read on public.player_badges;
create policy player_badges_read on public.player_badges for select to authenticated using(user_id=auth.uid() or public.is_super_admin());
drop policy if exists gamification_events_read on public.gamification_events; create policy gamification_events_read on public.gamification_events for select to authenticated using(is_public or user_id=auth.uid() or public.is_super_admin());
drop policy if exists gamification_records_read on public.gamification_records; create policy gamification_records_read on public.gamification_records for select to authenticated using(true);
drop policy if exists gamification_settings_read on public.gamification_settings; create policy gamification_settings_read on public.gamification_settings for select to authenticated using(true);
drop policy if exists gamification_audit_super on public.gamification_audit; create policy gamification_audit_super on public.gamification_audit for select to authenticated using(public.is_super_admin());
drop policy if exists gamification_text_read on public.gamification_text_templates; create policy gamification_text_read on public.gamification_text_templates for select to authenticated using(active or public.is_super_admin());

grant select on public.gamification_badges,public.player_badges,public.gamification_events,public.gamification_records,public.gamification_settings,public.gamification_text_templates to authenticated;
grant select on public.gamification_audit to authenticated;
grant execute on function public.gamification_metrics_v070(uuid,uuid,boolean) to authenticated;
grant execute on function public.narrative_text_v070(text,jsonb,text,text) to authenticated;
grant execute on function public.get_museum_summary_v070(uuid,uuid,boolean) to authenticated;
grant execute on function public.get_test_leaderboard_v070(uuid,boolean) to authenticated;
grant execute on function public.admin_upsert_badge_v070(uuid,jsonb) to authenticated;
grant execute on function public.admin_archive_badge_v070(uuid,text) to authenticated;
grant execute on function public.admin_award_badge_v070(uuid,uuid,uuid,jsonb,boolean,boolean) to authenticated;
grant execute on function public.admin_revoke_badge_v070(uuid,text) to authenticated;
grant execute on function public.admin_add_gamification_event_v070(jsonb) to authenticated;
grant execute on function public.admin_update_gamification_event_v070(uuid,int,text,text) to authenticated;
grant execute on function public.admin_update_gamification_settings_v070(uuid,jsonb) to authenticated;
grant execute on function public.admin_upsert_narrative_template_v070(bigint,jsonb) to authenticated;
grant execute on function public.admin_set_gamification_test_enabled_v070(uuid,boolean) to authenticated;
grant execute on function public.admin_clear_gamification_test_v070(uuid) to authenticated;
grant execute on function public.admin_recalculate_gamification_v070(uuid,boolean,boolean) to authenticated;
grant execute on function public.admin_preview_gamification_close_v070(uuid) to authenticated;
grant execute on function public.admin_close_gamification_v070(uuid) to authenticated;
grant execute on function public.admin_reopen_gamification_v070(uuid,text) to authenticated;

-- Publication Realtime : corrige les comptes joueurs qui devaient faire F5.
do $$ begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='matches') then alter publication supabase_realtime add table public.matches; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='matchdays') then alter publication supabase_realtime add table public.matchdays; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='predictions') then alter publication supabase_realtime add table public.predictions; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='player_badges') then alter publication supabase_realtime add table public.player_badges; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='gamification_events') then alter publication supabase_realtime add table public.gamification_events; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='gamification_records') then alter publication supabase_realtime add table public.gamification_records; end if;
  end if;
end $$;

insert into public.app_settings(key,value) values('app_version','"0.7.0"'::jsonb) on conflict(key) do update set value=excluded.value,updated_at=now();

commit;

-- Le Nid des Champions — V0.7.0
-- Grande banque narrative : 40 formulations par sujet.

begin;
insert into public.gamification_text_templates(event_key,tone,template,weight,active) values
('points_0','automatic','Aïe. {player} repart avec 0 point. On passe au suivant.',1,true),
('points_0','automatic','Aïe. {player} repart avec 0 point. Les archives ont tout vu.',1,true),
('points_0','automatic','Aïe. Le compteur reste à zéro pour {player}. On passe au suivant.',1,true),
('points_0','automatic','Aïe. Le compteur reste à zéro pour {player}. Les archives ont tout vu.',1,true),
('points_0','automatic','Aïe. Aucun point sur {club_home} – {club_away}. On passe au suivant.',1,true),
('points_0','automatic','Aïe. Aucun point sur {club_home} – {club_away}. Les archives ont tout vu.',1,true),
('points_0','automatic','Aïe. Le prono {prediction} ne rapporte rien. On passe au suivant.',1,true),
('points_0','automatic','Aïe. Le prono {prediction} ne rapporte rien. Les archives ont tout vu.',1,true),
('points_0','automatic','Bon… {player} repart avec 0 point. On passe au suivant.',1,true),
('points_0','automatic','Bon… {player} repart avec 0 point. Les archives ont tout vu.',1,true),
('points_0','automatic','Bon… Le compteur reste à zéro pour {player}. On passe au suivant.',1,true),
('points_0','automatic','Bon… Le compteur reste à zéro pour {player}. Les archives ont tout vu.',1,true),
('points_0','automatic','Bon… Aucun point sur {club_home} – {club_away}. On passe au suivant.',1,true),
('points_0','automatic','Bon… Aucun point sur {club_home} – {club_away}. Les archives ont tout vu.',1,true),
('points_0','automatic','Bon… Le prono {prediction} ne rapporte rien. On passe au suivant.',1,true),
('points_0','automatic','Bon… Le prono {prediction} ne rapporte rien. Les archives ont tout vu.',1,true),
('points_0','automatic','Le Hibou note ça. {player} repart avec 0 point. On passe au suivant.',1,true),
('points_0','automatic','Le Hibou note ça. {player} repart avec 0 point. Les archives ont tout vu.',1,true),
('points_0','automatic','Le Hibou note ça. Le compteur reste à zéro pour {player}. On passe au suivant.',1,true),
('points_0','automatic','Le Hibou note ça. Le compteur reste à zéro pour {player}. Les archives ont tout vu.',1,true),
('points_0','automatic','Le Hibou note ça. Aucun point sur {club_home} – {club_away}. On passe au suivant.',1,true),
('points_0','automatic','Le Hibou note ça. Aucun point sur {club_home} – {club_away}. Les archives ont tout vu.',1,true),
('points_0','automatic','Le Hibou note ça. Le prono {prediction} ne rapporte rien. On passe au suivant.',1,true),
('points_0','automatic','Le Hibou note ça. Le prono {prediction} ne rapporte rien. Les archives ont tout vu.',1,true),
('points_0','automatic','Ce match-là… {player} repart avec 0 point. On passe au suivant.',1,true),
('points_0','automatic','Ce match-là… {player} repart avec 0 point. Les archives ont tout vu.',1,true),
('points_0','automatic','Ce match-là… Le compteur reste à zéro pour {player}. On passe au suivant.',1,true),
('points_0','automatic','Ce match-là… Le compteur reste à zéro pour {player}. Les archives ont tout vu.',1,true),
('points_0','automatic','Ce match-là… Aucun point sur {club_home} – {club_away}. On passe au suivant.',1,true),
('points_0','automatic','Ce match-là… Aucun point sur {club_home} – {club_away}. Les archives ont tout vu.',1,true),
('points_0','automatic','Ce match-là… Le prono {prediction} ne rapporte rien. On passe au suivant.',1,true),
('points_0','automatic','Ce match-là… Le prono {prediction} ne rapporte rien. Les archives ont tout vu.',1,true),
('points_0','automatic','On respire. {player} repart avec 0 point. On passe au suivant.',1,true),
('points_0','automatic','On respire. {player} repart avec 0 point. Les archives ont tout vu.',1,true),
('points_0','automatic','On respire. Le compteur reste à zéro pour {player}. On passe au suivant.',1,true),
('points_0','automatic','On respire. Le compteur reste à zéro pour {player}. Les archives ont tout vu.',1,true),
('points_0','automatic','On respire. Aucun point sur {club_home} – {club_away}. On passe au suivant.',1,true),
('points_0','automatic','On respire. Aucun point sur {club_home} – {club_away}. Les archives ont tout vu.',1,true),
('points_0','automatic','On respire. Le prono {prediction} ne rapporte rien. On passe au suivant.',1,true),
('points_0','automatic','On respire. Le prono {prediction} ne rapporte rien. Les archives ont tout vu.',1,true),
('points_3','automatic','Propre. {player} prend 3 points. Le Hibou valide.',1,true),
('points_3','automatic','Propre. {player} prend 3 points. Ça fait avancer.',1,true),
('points_3','automatic','Propre. Bon résultat : +3 pour {player}. Le Hibou valide.',1,true),
('points_3','automatic','Propre. Bon résultat : +3 pour {player}. Ça fait avancer.',1,true),
('points_3','automatic','Propre. {prediction} avait la bonne issue. Le Hibou valide.',1,true),
('points_3','automatic','Propre. {prediction} avait la bonne issue. Ça fait avancer.',1,true),
('points_3','automatic','Propre. Trois points tombent dans le panier. Le Hibou valide.',1,true),
('points_3','automatic','Propre. Trois points tombent dans le panier. Ça fait avancer.',1,true),
('points_3','automatic','Bien lu. {player} prend 3 points. Le Hibou valide.',1,true),
('points_3','automatic','Bien lu. {player} prend 3 points. Ça fait avancer.',1,true),
('points_3','automatic','Bien lu. Bon résultat : +3 pour {player}. Le Hibou valide.',1,true),
('points_3','automatic','Bien lu. Bon résultat : +3 pour {player}. Ça fait avancer.',1,true),
('points_3','automatic','Bien lu. {prediction} avait la bonne issue. Le Hibou valide.',1,true),
('points_3','automatic','Bien lu. {prediction} avait la bonne issue. Ça fait avancer.',1,true),
('points_3','automatic','Bien lu. Trois points tombent dans le panier. Le Hibou valide.',1,true),
('points_3','automatic','Bien lu. Trois points tombent dans le panier. Ça fait avancer.',1,true),
('points_3','automatic','Le résultat est là. {player} prend 3 points. Le Hibou valide.',1,true),
('points_3','automatic','Le résultat est là. {player} prend 3 points. Ça fait avancer.',1,true),
('points_3','automatic','Le résultat est là. Bon résultat : +3 pour {player}. Le Hibou valide.',1,true),
('points_3','automatic','Le résultat est là. Bon résultat : +3 pour {player}. Ça fait avancer.',1,true),
('points_3','automatic','Le résultat est là. {prediction} avait la bonne issue. Le Hibou valide.',1,true),
('points_3','automatic','Le résultat est là. {prediction} avait la bonne issue. Ça fait avancer.',1,true),
('points_3','automatic','Le résultat est là. Trois points tombent dans le panier. Le Hibou valide.',1,true),
('points_3','automatic','Le résultat est là. Trois points tombent dans le panier. Ça fait avancer.',1,true),
('points_3','automatic','Pas parfait, mais juste. {player} prend 3 points. Le Hibou valide.',1,true),
('points_3','automatic','Pas parfait, mais juste. {player} prend 3 points. Ça fait avancer.',1,true),
('points_3','automatic','Pas parfait, mais juste. Bon résultat : +3 pour {player}. Le Hibou valide.',1,true),
('points_3','automatic','Pas parfait, mais juste. Bon résultat : +3 pour {player}. Ça fait avancer.',1,true),
('points_3','automatic','Pas parfait, mais juste. {prediction} avait la bonne issue. Le Hibou valide.',1,true),
('points_3','automatic','Pas parfait, mais juste. {prediction} avait la bonne issue. Ça fait avancer.',1,true),
('points_3','automatic','Pas parfait, mais juste. Trois points tombent dans le panier. Le Hibou valide.',1,true),
('points_3','automatic','Pas parfait, mais juste. Trois points tombent dans le panier. Ça fait avancer.',1,true),
('points_3','automatic','Ça rentre. {player} prend 3 points. Le Hibou valide.',1,true),
('points_3','automatic','Ça rentre. {player} prend 3 points. Ça fait avancer.',1,true),
('points_3','automatic','Ça rentre. Bon résultat : +3 pour {player}. Le Hibou valide.',1,true),
('points_3','automatic','Ça rentre. Bon résultat : +3 pour {player}. Ça fait avancer.',1,true),
('points_3','automatic','Ça rentre. {prediction} avait la bonne issue. Le Hibou valide.',1,true),
('points_3','automatic','Ça rentre. {prediction} avait la bonne issue. Ça fait avancer.',1,true),
('points_3','automatic','Ça rentre. Trois points tombent dans le panier. Le Hibou valide.',1,true),
('points_3','automatic','Ça rentre. Trois points tombent dans le panier. Ça fait avancer.',1,true),
('points_5','automatic','Très propre. {player} prend 5 points pour le bon écart. Pas loin du plein centre.',1,true),
('points_5','automatic','Très propre. {player} prend 5 points pour le bon écart. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Très propre. Bon résultat et bon écart : +5. Pas loin du plein centre.',1,true),
('points_5','automatic','Très propre. Bon résultat et bon écart : +5. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Très propre. Le prono {prediction} colle presque parfaitement. Pas loin du plein centre.',1,true),
('points_5','automatic','Très propre. Le prono {prediction} colle presque parfaitement. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Très propre. Cinq points mérités. Pas loin du plein centre.',1,true),
('points_5','automatic','Très propre. Cinq points mérités. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Joli compas. {player} prend 5 points pour le bon écart. Pas loin du plein centre.',1,true),
('points_5','automatic','Joli compas. {player} prend 5 points pour le bon écart. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Joli compas. Bon résultat et bon écart : +5. Pas loin du plein centre.',1,true),
('points_5','automatic','Joli compas. Bon résultat et bon écart : +5. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Joli compas. Le prono {prediction} colle presque parfaitement. Pas loin du plein centre.',1,true),
('points_5','automatic','Joli compas. Le prono {prediction} colle presque parfaitement. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Joli compas. Cinq points mérités. Pas loin du plein centre.',1,true),
('points_5','automatic','Joli compas. Cinq points mérités. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Ça se précise. {player} prend 5 points pour le bon écart. Pas loin du plein centre.',1,true),
('points_5','automatic','Ça se précise. {player} prend 5 points pour le bon écart. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Ça se précise. Bon résultat et bon écart : +5. Pas loin du plein centre.',1,true),
('points_5','automatic','Ça se précise. Bon résultat et bon écart : +5. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Ça se précise. Le prono {prediction} colle presque parfaitement. Pas loin du plein centre.',1,true),
('points_5','automatic','Ça se précise. Le prono {prediction} colle presque parfaitement. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Ça se précise. Cinq points mérités. Pas loin du plein centre.',1,true),
('points_5','automatic','Ça se précise. Cinq points mérités. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Le Hibou hausse un sourcil. {player} prend 5 points pour le bon écart. Pas loin du plein centre.',1,true),
('points_5','automatic','Le Hibou hausse un sourcil. {player} prend 5 points pour le bon écart. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Le Hibou hausse un sourcil. Bon résultat et bon écart : +5. Pas loin du plein centre.',1,true),
('points_5','automatic','Le Hibou hausse un sourcil. Bon résultat et bon écart : +5. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Le Hibou hausse un sourcil. Le prono {prediction} colle presque parfaitement. Pas loin du plein centre.',1,true),
('points_5','automatic','Le Hibou hausse un sourcil. Le prono {prediction} colle presque parfaitement. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Le Hibou hausse un sourcil. Cinq points mérités. Pas loin du plein centre.',1,true),
('points_5','automatic','Le Hibou hausse un sourcil. Cinq points mérités. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Belle lecture. {player} prend 5 points pour le bon écart. Pas loin du plein centre.',1,true),
('points_5','automatic','Belle lecture. {player} prend 5 points pour le bon écart. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Belle lecture. Bon résultat et bon écart : +5. Pas loin du plein centre.',1,true),
('points_5','automatic','Belle lecture. Bon résultat et bon écart : +5. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Belle lecture. Le prono {prediction} colle presque parfaitement. Pas loin du plein centre.',1,true),
('points_5','automatic','Belle lecture. Le prono {prediction} colle presque parfaitement. Ça commence à sentir le flair.',1,true),
('points_5','automatic','Belle lecture. Cinq points mérités. Pas loin du plein centre.',1,true),
('points_5','automatic','Belle lecture. Cinq points mérités. Ça commence à sentir le flair.',1,true),
('points_7','automatic','Plein centre. {player} claque le score exact : +7. Très propre.',1,true),
('points_7','automatic','Plein centre. {player} claque le score exact : +7. Presque suspect.',1,true),
('points_7','automatic','Plein centre. {prediction}, exactement : sept points. Très propre.',1,true),
('points_7','automatic','Plein centre. {prediction}, exactement : sept points. Presque suspect.',1,true),
('points_7','automatic','Plein centre. Score exact sur {club_home} – {club_away}. Très propre.',1,true),
('points_7','automatic','Plein centre. Score exact sur {club_home} – {club_away}. Presque suspect.',1,true),
('points_7','automatic','Plein centre. Sept points, aucune discussion. Très propre.',1,true),
('points_7','automatic','Plein centre. Sept points, aucune discussion. Presque suspect.',1,true),
('points_7','automatic','Bingo. {player} claque le score exact : +7. Très propre.',1,true),
('points_7','automatic','Bingo. {player} claque le score exact : +7. Presque suspect.',1,true),
('points_7','automatic','Bingo. {prediction}, exactement : sept points. Très propre.',1,true),
('points_7','automatic','Bingo. {prediction}, exactement : sept points. Presque suspect.',1,true),
('points_7','automatic','Bingo. Score exact sur {club_home} – {club_away}. Très propre.',1,true),
('points_7','automatic','Bingo. Score exact sur {club_home} – {club_away}. Presque suspect.',1,true),
('points_7','automatic','Bingo. Sept points, aucune discussion. Très propre.',1,true),
('points_7','automatic','Bingo. Sept points, aucune discussion. Presque suspect.',1,true),
('points_7','automatic','Exact. {player} claque le score exact : +7. Très propre.',1,true),
('points_7','automatic','Exact. {player} claque le score exact : +7. Presque suspect.',1,true),
('points_7','automatic','Exact. {prediction}, exactement : sept points. Très propre.',1,true),
('points_7','automatic','Exact. {prediction}, exactement : sept points. Presque suspect.',1,true),
('points_7','automatic','Exact. Score exact sur {club_home} – {club_away}. Très propre.',1,true),
('points_7','automatic','Exact. Score exact sur {club_home} – {club_away}. Presque suspect.',1,true),
('points_7','automatic','Exact. Sept points, aucune discussion. Très propre.',1,true),
('points_7','automatic','Exact. Sept points, aucune discussion. Presque suspect.',1,true),
('points_7','automatic','Le futur avait envoyé un mémo. {player} claque le score exact : +7. Très propre.',1,true),
('points_7','automatic','Le futur avait envoyé un mémo. {player} claque le score exact : +7. Presque suspect.',1,true),
('points_7','automatic','Le futur avait envoyé un mémo. {prediction}, exactement : sept points. Très propre.',1,true),
('points_7','automatic','Le futur avait envoyé un mémo. {prediction}, exactement : sept points. Presque suspect.',1,true),
('points_7','automatic','Le futur avait envoyé un mémo. Score exact sur {club_home} – {club_away}. Très propre.',1,true),
('points_7','automatic','Le futur avait envoyé un mémo. Score exact sur {club_home} – {club_away}. Presque suspect.',1,true),
('points_7','automatic','Le futur avait envoyé un mémo. Sept points, aucune discussion. Très propre.',1,true),
('points_7','automatic','Le futur avait envoyé un mémo. Sept points, aucune discussion. Presque suspect.',1,true),
('points_7','automatic','Le Hibou vérifie ses sources. {player} claque le score exact : +7. Très propre.',1,true),
('points_7','automatic','Le Hibou vérifie ses sources. {player} claque le score exact : +7. Presque suspect.',1,true),
('points_7','automatic','Le Hibou vérifie ses sources. {prediction}, exactement : sept points. Très propre.',1,true),
('points_7','automatic','Le Hibou vérifie ses sources. {prediction}, exactement : sept points. Presque suspect.',1,true),
('points_7','automatic','Le Hibou vérifie ses sources. Score exact sur {club_home} – {club_away}. Très propre.',1,true),
('points_7','automatic','Le Hibou vérifie ses sources. Score exact sur {club_home} – {club_away}. Presque suspect.',1,true),
('points_7','automatic','Le Hibou vérifie ses sources. Sept points, aucune discussion. Très propre.',1,true),
('points_7','automatic','Le Hibou vérifie ses sources. Sept points, aucune discussion. Presque suspect.',1,true),
('summary_good','automatic','Belle soirée. {player} termine avec {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Belle soirée. {player} termine avec {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Belle soirée. {points} points, rang {rank}, et une soirée solide. À garder dans les archives.',1,true),
('summary_good','automatic','Belle soirée. {points} points, rang {rank}, et une soirée solide. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Belle soirée. {player} gagne {rank_delta} place(s) avec {points} points. À garder dans les archives.',1,true),
('summary_good','automatic','Belle soirée. {player} gagne {rank_delta} place(s) avec {points} points. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Belle soirée. Le bilan affiche {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Belle soirée. Le bilan affiche {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Le Nid a vu ça. {player} termine avec {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Le Nid a vu ça. {player} termine avec {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Le Nid a vu ça. {points} points, rang {rank}, et une soirée solide. À garder dans les archives.',1,true),
('summary_good','automatic','Le Nid a vu ça. {points} points, rang {rank}, et une soirée solide. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Le Nid a vu ça. {player} gagne {rank_delta} place(s) avec {points} points. À garder dans les archives.',1,true),
('summary_good','automatic','Le Nid a vu ça. {player} gagne {rank_delta} place(s) avec {points} points. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Le Nid a vu ça. Le bilan affiche {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Le Nid a vu ça. Le bilan affiche {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Ça plane haut ce soir. {player} termine avec {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Ça plane haut ce soir. {player} termine avec {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Ça plane haut ce soir. {points} points, rang {rank}, et une soirée solide. À garder dans les archives.',1,true),
('summary_good','automatic','Ça plane haut ce soir. {points} points, rang {rank}, et une soirée solide. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Ça plane haut ce soir. {player} gagne {rank_delta} place(s) avec {points} points. À garder dans les archives.',1,true),
('summary_good','automatic','Ça plane haut ce soir. {player} gagne {rank_delta} place(s) avec {points} points. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Ça plane haut ce soir. Le bilan affiche {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Ça plane haut ce soir. Le bilan affiche {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Les plumes sont bien rangées. {player} termine avec {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Les plumes sont bien rangées. {player} termine avec {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Les plumes sont bien rangées. {points} points, rang {rank}, et une soirée solide. À garder dans les archives.',1,true),
('summary_good','automatic','Les plumes sont bien rangées. {points} points, rang {rank}, et une soirée solide. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Les plumes sont bien rangées. {player} gagne {rank_delta} place(s) avec {points} points. À garder dans les archives.',1,true),
('summary_good','automatic','Les plumes sont bien rangées. {player} gagne {rank_delta} place(s) avec {points} points. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Les plumes sont bien rangées. Le bilan affiche {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Les plumes sont bien rangées. Le bilan affiche {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Le Hibou approuve presque. {player} termine avec {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Le Hibou approuve presque. {player} termine avec {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Le Hibou approuve presque. {points} points, rang {rank}, et une soirée solide. À garder dans les archives.',1,true),
('summary_good','automatic','Le Hibou approuve presque. {points} points, rang {rank}, et une soirée solide. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Le Hibou approuve presque. {player} gagne {rank_delta} place(s) avec {points} points. À garder dans les archives.',1,true),
('summary_good','automatic','Le Hibou approuve presque. {player} gagne {rank_delta} place(s) avec {points} points. Demain, il faudra recommencer.',1,true),
('summary_good','automatic','Le Hibou approuve presque. Le bilan affiche {points} points et {exacts} exact(s). À garder dans les archives.',1,true),
('summary_good','automatic','Le Hibou approuve presque. Le bilan affiche {points} points et {exacts} exact(s). Demain, il faudra recommencer.',1,true),
('summary_neutral','automatic','Soirée correcte. {player} termine avec {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','Soirée correcte. {player} termine avec {points} points. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Soirée correcte. Bilan : {points} points, rang {rank}. Ça se prend.',1,true),
('summary_neutral','automatic','Soirée correcte. Bilan : {points} points, rang {rank}. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Soirée correcte. {points} points et {exacts} exact(s). Ça se prend.',1,true),
('summary_neutral','automatic','Soirée correcte. {points} points et {exacts} exact(s). Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Soirée correcte. La soirée se ferme à {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','Soirée correcte. La soirée se ferme à {points} points. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Ni drame ni légende. {player} termine avec {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','Ni drame ni légende. {player} termine avec {points} points. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Ni drame ni légende. Bilan : {points} points, rang {rank}. Ça se prend.',1,true),
('summary_neutral','automatic','Ni drame ni légende. Bilan : {points} points, rang {rank}. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Ni drame ni légende. {points} points et {exacts} exact(s). Ça se prend.',1,true),
('summary_neutral','automatic','Ni drame ni légende. {points} points et {exacts} exact(s). Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Ni drame ni légende. La soirée se ferme à {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','Ni drame ni légende. La soirée se ferme à {points} points. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Le Nid classe ça dans « solide ». {player} termine avec {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','Le Nid classe ça dans « solide ». {player} termine avec {points} points. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Le Nid classe ça dans « solide ». Bilan : {points} points, rang {rank}. Ça se prend.',1,true),
('summary_neutral','automatic','Le Nid classe ça dans « solide ». Bilan : {points} points, rang {rank}. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Le Nid classe ça dans « solide ». {points} points et {exacts} exact(s). Ça se prend.',1,true),
('summary_neutral','automatic','Le Nid classe ça dans « solide ». {points} points et {exacts} exact(s). Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Le Nid classe ça dans « solide ». La soirée se ferme à {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','Le Nid classe ça dans « solide ». La soirée se ferme à {points} points. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','On a vu pire. {player} termine avec {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','On a vu pire. {player} termine avec {points} points. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','On a vu pire. Bilan : {points} points, rang {rank}. Ça se prend.',1,true),
('summary_neutral','automatic','On a vu pire. Bilan : {points} points, rang {rank}. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','On a vu pire. {points} points et {exacts} exact(s). Ça se prend.',1,true),
('summary_neutral','automatic','On a vu pire. {points} points et {exacts} exact(s). Le classement, lui, continue.',1,true),
('summary_neutral','automatic','On a vu pire. La soirée se ferme à {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','On a vu pire. La soirée se ferme à {points} points. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Le Hibou reste mesuré. {player} termine avec {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','Le Hibou reste mesuré. {player} termine avec {points} points. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Le Hibou reste mesuré. Bilan : {points} points, rang {rank}. Ça se prend.',1,true),
('summary_neutral','automatic','Le Hibou reste mesuré. Bilan : {points} points, rang {rank}. Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Le Hibou reste mesuré. {points} points et {exacts} exact(s). Ça se prend.',1,true),
('summary_neutral','automatic','Le Hibou reste mesuré. {points} points et {exacts} exact(s). Le classement, lui, continue.',1,true),
('summary_neutral','automatic','Le Hibou reste mesuré. La soirée se ferme à {points} points. Ça se prend.',1,true),
('summary_neutral','automatic','Le Hibou reste mesuré. La soirée se ferme à {points} points. Le classement, lui, continue.',1,true),
('summary_bad','automatic','Ouille. {player} termine avec {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','Ouille. {player} termine avec {points} points. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Ouille. {points} points et {rank_delta} place(s) perdues. On fera mieux mardi.',1,true),
('summary_bad','automatic','Ouille. {points} points et {rank_delta} place(s) perdues. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Ouille. Le compteur s’arrête à {points}. On fera mieux mardi.',1,true),
('summary_bad','automatic','Ouille. Le compteur s’arrête à {points}. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Ouille. Le bilan pique : {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','Ouille. Le bilan pique : {points} points. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Soirée compliquée. {player} termine avec {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','Soirée compliquée. {player} termine avec {points} points. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Soirée compliquée. {points} points et {rank_delta} place(s) perdues. On fera mieux mardi.',1,true),
('summary_bad','automatic','Soirée compliquée. {points} points et {rank_delta} place(s) perdues. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Soirée compliquée. Le compteur s’arrête à {points}. On fera mieux mardi.',1,true),
('summary_bad','automatic','Soirée compliquée. Le compteur s’arrête à {points}. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Soirée compliquée. Le bilan pique : {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','Soirée compliquée. Le bilan pique : {points} points. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Le Hibou demande un rapport. {player} termine avec {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','Le Hibou demande un rapport. {player} termine avec {points} points. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Le Hibou demande un rapport. {points} points et {rank_delta} place(s) perdues. On fera mieux mardi.',1,true),
('summary_bad','automatic','Le Hibou demande un rapport. {points} points et {rank_delta} place(s) perdues. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Le Hibou demande un rapport. Le compteur s’arrête à {points}. On fera mieux mardi.',1,true),
('summary_bad','automatic','Le Hibou demande un rapport. Le compteur s’arrête à {points}. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Le Hibou demande un rapport. Le bilan pique : {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','Le Hibou demande un rapport. Le bilan pique : {points} points. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Les plumes ont pris le vent. {player} termine avec {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','Les plumes ont pris le vent. {player} termine avec {points} points. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Les plumes ont pris le vent. {points} points et {rank_delta} place(s) perdues. On fera mieux mardi.',1,true),
('summary_bad','automatic','Les plumes ont pris le vent. {points} points et {rank_delta} place(s) perdues. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Les plumes ont pris le vent. Le compteur s’arrête à {points}. On fera mieux mardi.',1,true),
('summary_bad','automatic','Les plumes ont pris le vent. Le compteur s’arrête à {points}. Les archives sont cruelles.',1,true),
('summary_bad','automatic','Les plumes ont pris le vent. Le bilan pique : {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','Les plumes ont pris le vent. Le bilan pique : {points} points. Les archives sont cruelles.',1,true),
('summary_bad','automatic','On ne va pas encadrer celle-ci. {player} termine avec {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','On ne va pas encadrer celle-ci. {player} termine avec {points} points. Les archives sont cruelles.',1,true),
('summary_bad','automatic','On ne va pas encadrer celle-ci. {points} points et {rank_delta} place(s) perdues. On fera mieux mardi.',1,true),
('summary_bad','automatic','On ne va pas encadrer celle-ci. {points} points et {rank_delta} place(s) perdues. Les archives sont cruelles.',1,true),
('summary_bad','automatic','On ne va pas encadrer celle-ci. Le compteur s’arrête à {points}. On fera mieux mardi.',1,true),
('summary_bad','automatic','On ne va pas encadrer celle-ci. Le compteur s’arrête à {points}. Les archives sont cruelles.',1,true),
('summary_bad','automatic','On ne va pas encadrer celle-ci. Le bilan pique : {points} points. On fera mieux mardi.',1,true),
('summary_bad','automatic','On ne va pas encadrer celle-ci. Le bilan pique : {points} points. Les archives sont cruelles.',1,true),
('rival_win','automatic','Duel gagné. {player} bat {rival} de {margin} point(s). Jusqu’au prochain round.',1,true),
('rival_win','automatic','Duel gagné. {player} bat {rival} de {margin} point(s). Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Duel gagné. Victoire contre {rival} : {my_points}–{rival_points}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Duel gagné. Victoire contre {rival} : {my_points}–{rival_points}. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Duel gagné. {rival} repart derrière sur cette journée. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Duel gagné. {rival} repart derrière sur cette journée. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Duel gagné. Le duel tourne pour {player}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Duel gagné. Le duel tourne pour {player}. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','La rivalité penche du bon côté. {player} bat {rival} de {margin} point(s). Jusqu’au prochain round.',1,true),
('rival_win','automatic','La rivalité penche du bon côté. {player} bat {rival} de {margin} point(s). Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','La rivalité penche du bon côté. Victoire contre {rival} : {my_points}–{rival_points}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','La rivalité penche du bon côté. Victoire contre {rival} : {my_points}–{rival_points}. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','La rivalité penche du bon côté. {rival} repart derrière sur cette journée. Jusqu’au prochain round.',1,true),
('rival_win','automatic','La rivalité penche du bon côté. {rival} repart derrière sur cette journée. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','La rivalité penche du bon côté. Le duel tourne pour {player}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','La rivalité penche du bon côté. Le duel tourne pour {player}. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Le Hibou savoure. {player} bat {rival} de {margin} point(s). Jusqu’au prochain round.',1,true),
('rival_win','automatic','Le Hibou savoure. {player} bat {rival} de {margin} point(s). Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Le Hibou savoure. Victoire contre {rival} : {my_points}–{rival_points}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Le Hibou savoure. Victoire contre {rival} : {my_points}–{rival_points}. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Le Hibou savoure. {rival} repart derrière sur cette journée. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Le Hibou savoure. {rival} repart derrière sur cette journée. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Le Hibou savoure. Le duel tourne pour {player}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Le Hibou savoure. Le duel tourne pour {player}. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Coup de bec réussi. {player} bat {rival} de {margin} point(s). Jusqu’au prochain round.',1,true),
('rival_win','automatic','Coup de bec réussi. {player} bat {rival} de {margin} point(s). Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Coup de bec réussi. Victoire contre {rival} : {my_points}–{rival_points}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Coup de bec réussi. Victoire contre {rival} : {my_points}–{rival_points}. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Coup de bec réussi. {rival} repart derrière sur cette journée. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Coup de bec réussi. {rival} repart derrière sur cette journée. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Coup de bec réussi. Le duel tourne pour {player}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Coup de bec réussi. Le duel tourne pour {player}. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Némésis repoussée. {player} bat {rival} de {margin} point(s). Jusqu’au prochain round.',1,true),
('rival_win','automatic','Némésis repoussée. {player} bat {rival} de {margin} point(s). Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Némésis repoussée. Victoire contre {rival} : {my_points}–{rival_points}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Némésis repoussée. Victoire contre {rival} : {my_points}–{rival_points}. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Némésis repoussée. {rival} repart derrière sur cette journée. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Némésis repoussée. {rival} repart derrière sur cette journée. Le silence d’en face est délicieux.',1,true),
('rival_win','automatic','Némésis repoussée. Le duel tourne pour {player}. Jusqu’au prochain round.',1,true),
('rival_win','automatic','Némésis repoussée. Le duel tourne pour {player}. Le silence d’en face est délicieux.',1,true),
('rival_loss','automatic','Ça pique. {rival} bat {player} de {margin} point(s). Revanche obligatoire.',1,true),
('rival_loss','automatic','Ça pique. {rival} bat {player} de {margin} point(s). Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Ça pique. Défaite {my_points}–{rival_points} contre {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Ça pique. Défaite {my_points}–{rival_points} contre {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Ça pique. Le duel tourne pour {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Ça pique. Le duel tourne pour {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Ça pique. {player} laisse cette manche à {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Ça pique. {player} laisse cette manche à {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Le rival a frappé. {rival} bat {player} de {margin} point(s). Revanche obligatoire.',1,true),
('rival_loss','automatic','Le rival a frappé. {rival} bat {player} de {margin} point(s). Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Le rival a frappé. Défaite {my_points}–{rival_points} contre {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Le rival a frappé. Défaite {my_points}–{rival_points} contre {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Le rival a frappé. Le duel tourne pour {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Le rival a frappé. Le duel tourne pour {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Le rival a frappé. {player} laisse cette manche à {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Le rival a frappé. {player} laisse cette manche à {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Mauvaise soirée côté duel. {rival} bat {player} de {margin} point(s). Revanche obligatoire.',1,true),
('rival_loss','automatic','Mauvaise soirée côté duel. {rival} bat {player} de {margin} point(s). Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Mauvaise soirée côté duel. Défaite {my_points}–{rival_points} contre {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Mauvaise soirée côté duel. Défaite {my_points}–{rival_points} contre {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Mauvaise soirée côté duel. Le duel tourne pour {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Mauvaise soirée côté duel. Le duel tourne pour {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Mauvaise soirée côté duel. {player} laisse cette manche à {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Mauvaise soirée côté duel. {player} laisse cette manche à {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Le Hibou évite le regard. {rival} bat {player} de {margin} point(s). Revanche obligatoire.',1,true),
('rival_loss','automatic','Le Hibou évite le regard. {rival} bat {player} de {margin} point(s). Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Le Hibou évite le regard. Défaite {my_points}–{rival_points} contre {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Le Hibou évite le regard. Défaite {my_points}–{rival_points} contre {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Le Hibou évite le regard. Le duel tourne pour {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Le Hibou évite le regard. Le duel tourne pour {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Le Hibou évite le regard. {player} laisse cette manche à {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Le Hibou évite le regard. {player} laisse cette manche à {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Cette manche est perdue. {rival} bat {player} de {margin} point(s). Revanche obligatoire.',1,true),
('rival_loss','automatic','Cette manche est perdue. {rival} bat {player} de {margin} point(s). Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Cette manche est perdue. Défaite {my_points}–{rival_points} contre {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Cette manche est perdue. Défaite {my_points}–{rival_points} contre {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Cette manche est perdue. Le duel tourne pour {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Cette manche est perdue. Le duel tourne pour {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_loss','automatic','Cette manche est perdue. {player} laisse cette manche à {rival}. Revanche obligatoire.',1,true),
('rival_loss','automatic','Cette manche est perdue. {player} laisse cette manche à {rival}. Il faudra trouver une excuse crédible.',1,true),
('rival_draw','automatic','Trêve armée. {player} et {rival} terminent à égalité. On remet ça.',1,true),
('rival_draw','automatic','Trêve armée. {player} et {rival} terminent à égalité. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Trêve armée. Match nul dans la rivalité : {my_points}–{rival_points}. On remet ça.',1,true),
('rival_draw','automatic','Trêve armée. Match nul dans la rivalité : {my_points}–{rival_points}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Trêve armée. Aucun vainqueur entre {player} et {rival}. On remet ça.',1,true),
('rival_draw','automatic','Trêve armée. Aucun vainqueur entre {player} et {rival}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Trêve armée. Le duel finit sans départage. On remet ça.',1,true),
('rival_draw','automatic','Trêve armée. Le duel finit sans départage. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Personne ne lâche. {player} et {rival} terminent à égalité. On remet ça.',1,true),
('rival_draw','automatic','Personne ne lâche. {player} et {rival} terminent à égalité. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Personne ne lâche. Match nul dans la rivalité : {my_points}–{rival_points}. On remet ça.',1,true),
('rival_draw','automatic','Personne ne lâche. Match nul dans la rivalité : {my_points}–{rival_points}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Personne ne lâche. Aucun vainqueur entre {player} et {rival}. On remet ça.',1,true),
('rival_draw','automatic','Personne ne lâche. Aucun vainqueur entre {player} et {rival}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Personne ne lâche. Le duel finit sans départage. On remet ça.',1,true),
('rival_draw','automatic','Personne ne lâche. Le duel finit sans départage. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Égalité parfaite. {player} et {rival} terminent à égalité. On remet ça.',1,true),
('rival_draw','automatic','Égalité parfaite. {player} et {rival} terminent à égalité. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Égalité parfaite. Match nul dans la rivalité : {my_points}–{rival_points}. On remet ça.',1,true),
('rival_draw','automatic','Égalité parfaite. Match nul dans la rivalité : {my_points}–{rival_points}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Égalité parfaite. Aucun vainqueur entre {player} et {rival}. On remet ça.',1,true),
('rival_draw','automatic','Égalité parfaite. Aucun vainqueur entre {player} et {rival}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Égalité parfaite. Le duel finit sans départage. On remet ça.',1,true),
('rival_draw','automatic','Égalité parfaite. Le duel finit sans départage. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Le duel refuse de choisir. {player} et {rival} terminent à égalité. On remet ça.',1,true),
('rival_draw','automatic','Le duel refuse de choisir. {player} et {rival} terminent à égalité. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Le duel refuse de choisir. Match nul dans la rivalité : {my_points}–{rival_points}. On remet ça.',1,true),
('rival_draw','automatic','Le duel refuse de choisir. Match nul dans la rivalité : {my_points}–{rival_points}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Le duel refuse de choisir. Aucun vainqueur entre {player} et {rival}. On remet ça.',1,true),
('rival_draw','automatic','Le duel refuse de choisir. Aucun vainqueur entre {player} et {rival}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Le duel refuse de choisir. Le duel finit sans départage. On remet ça.',1,true),
('rival_draw','automatic','Le duel refuse de choisir. Le duel finit sans départage. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Même branche, même hauteur. {player} et {rival} terminent à égalité. On remet ça.',1,true),
('rival_draw','automatic','Même branche, même hauteur. {player} et {rival} terminent à égalité. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Même branche, même hauteur. Match nul dans la rivalité : {my_points}–{rival_points}. On remet ça.',1,true),
('rival_draw','automatic','Même branche, même hauteur. Match nul dans la rivalité : {my_points}–{rival_points}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Même branche, même hauteur. Aucun vainqueur entre {player} et {rival}. On remet ça.',1,true),
('rival_draw','automatic','Même branche, même hauteur. Aucun vainqueur entre {player} et {rival}. Le Hibou range le sifflet.',1,true),
('rival_draw','automatic','Même branche, même hauteur. Le duel finit sans départage. On remet ça.',1,true),
('rival_draw','automatic','Même branche, même hauteur. Le duel finit sans départage. Le Hibou range le sifflet.',1,true),
('ranking_up','automatic','Ça grimpe. {player} gagne {rank_delta} place(s). Continue comme ça.',1,true),
('ranking_up','automatic','Ça grimpe. {player} gagne {rank_delta} place(s). Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Ça grimpe. {player} monte au rang {rank}. Continue comme ça.',1,true),
('ranking_up','automatic','Ça grimpe. {player} monte au rang {rank}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Ça grimpe. +{rank_delta} au classement pour {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Ça grimpe. +{rank_delta} au classement pour {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Ça grimpe. Le rang {rank} accueille {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Ça grimpe. Le rang {rank} accueille {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Ascenseur vers le haut. {player} gagne {rank_delta} place(s). Continue comme ça.',1,true),
('ranking_up','automatic','Ascenseur vers le haut. {player} gagne {rank_delta} place(s). Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Ascenseur vers le haut. {player} monte au rang {rank}. Continue comme ça.',1,true),
('ranking_up','automatic','Ascenseur vers le haut. {player} monte au rang {rank}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Ascenseur vers le haut. +{rank_delta} au classement pour {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Ascenseur vers le haut. +{rank_delta} au classement pour {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Ascenseur vers le haut. Le rang {rank} accueille {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Ascenseur vers le haut. Le rang {rank} accueille {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Belle poussée. {player} gagne {rank_delta} place(s). Continue comme ça.',1,true),
('ranking_up','automatic','Belle poussée. {player} gagne {rank_delta} place(s). Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Belle poussée. {player} monte au rang {rank}. Continue comme ça.',1,true),
('ranking_up','automatic','Belle poussée. {player} monte au rang {rank}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Belle poussée. +{rank_delta} au classement pour {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Belle poussée. +{rank_delta} au classement pour {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Belle poussée. Le rang {rank} accueille {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Belle poussée. Le rang {rank} accueille {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Le classement bouge. {player} gagne {rank_delta} place(s). Continue comme ça.',1,true),
('ranking_up','automatic','Le classement bouge. {player} gagne {rank_delta} place(s). Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Le classement bouge. {player} monte au rang {rank}. Continue comme ça.',1,true),
('ranking_up','automatic','Le classement bouge. {player} monte au rang {rank}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Le classement bouge. +{rank_delta} au classement pour {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Le classement bouge. +{rank_delta} au classement pour {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Le classement bouge. Le rang {rank} accueille {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Le classement bouge. Le rang {rank} accueille {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Des places tombent. {player} gagne {rank_delta} place(s). Continue comme ça.',1,true),
('ranking_up','automatic','Des places tombent. {player} gagne {rank_delta} place(s). Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Des places tombent. {player} monte au rang {rank}. Continue comme ça.',1,true),
('ranking_up','automatic','Des places tombent. {player} monte au rang {rank}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Des places tombent. +{rank_delta} au classement pour {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Des places tombent. +{rank_delta} au classement pour {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_up','automatic','Des places tombent. Le rang {rank} accueille {player}. Continue comme ça.',1,true),
('ranking_up','automatic','Des places tombent. Le rang {rank} accueille {player}. Les voisins commencent à regarder derrière.',1,true),
('ranking_down','automatic','Ça descend. {player} perd {rank_delta} place(s). Il reste du temps.',1,true),
('ranking_down','automatic','Ça descend. {player} perd {rank_delta} place(s). On évite de paniquer.',1,true),
('ranking_down','automatic','Ça descend. {player} glisse au rang {rank}. Il reste du temps.',1,true),
('ranking_down','automatic','Ça descend. {player} glisse au rang {rank}. On évite de paniquer.',1,true),
('ranking_down','automatic','Ça descend. -{rank_delta} au classement. Il reste du temps.',1,true),
('ranking_down','automatic','Ça descend. -{rank_delta} au classement. On évite de paniquer.',1,true),
('ranking_down','automatic','Ça descend. Le rang {rank} est moins confortable. Il reste du temps.',1,true),
('ranking_down','automatic','Ça descend. Le rang {rank} est moins confortable. On évite de paniquer.',1,true),
('ranking_down','automatic','Petit courant d’air. {player} perd {rank_delta} place(s). Il reste du temps.',1,true),
('ranking_down','automatic','Petit courant d’air. {player} perd {rank_delta} place(s). On évite de paniquer.',1,true),
('ranking_down','automatic','Petit courant d’air. {player} glisse au rang {rank}. Il reste du temps.',1,true),
('ranking_down','automatic','Petit courant d’air. {player} glisse au rang {rank}. On évite de paniquer.',1,true),
('ranking_down','automatic','Petit courant d’air. -{rank_delta} au classement. Il reste du temps.',1,true),
('ranking_down','automatic','Petit courant d’air. -{rank_delta} au classement. On évite de paniquer.',1,true),
('ranking_down','automatic','Petit courant d’air. Le rang {rank} est moins confortable. Il reste du temps.',1,true),
('ranking_down','automatic','Petit courant d’air. Le rang {rank} est moins confortable. On évite de paniquer.',1,true),
('ranking_down','automatic','Le classement se venge. {player} perd {rank_delta} place(s). Il reste du temps.',1,true),
('ranking_down','automatic','Le classement se venge. {player} perd {rank_delta} place(s). On évite de paniquer.',1,true),
('ranking_down','automatic','Le classement se venge. {player} glisse au rang {rank}. Il reste du temps.',1,true),
('ranking_down','automatic','Le classement se venge. {player} glisse au rang {rank}. On évite de paniquer.',1,true),
('ranking_down','automatic','Le classement se venge. -{rank_delta} au classement. Il reste du temps.',1,true),
('ranking_down','automatic','Le classement se venge. -{rank_delta} au classement. On évite de paniquer.',1,true),
('ranking_down','automatic','Le classement se venge. Le rang {rank} est moins confortable. Il reste du temps.',1,true),
('ranking_down','automatic','Le classement se venge. Le rang {rank} est moins confortable. On évite de paniquer.',1,true),
('ranking_down','automatic','Oups. {player} perd {rank_delta} place(s). Il reste du temps.',1,true),
('ranking_down','automatic','Oups. {player} perd {rank_delta} place(s). On évite de paniquer.',1,true),
('ranking_down','automatic','Oups. {player} glisse au rang {rank}. Il reste du temps.',1,true),
('ranking_down','automatic','Oups. {player} glisse au rang {rank}. On évite de paniquer.',1,true),
('ranking_down','automatic','Oups. -{rank_delta} au classement. Il reste du temps.',1,true),
('ranking_down','automatic','Oups. -{rank_delta} au classement. On évite de paniquer.',1,true),
('ranking_down','automatic','Oups. Le rang {rank} est moins confortable. Il reste du temps.',1,true),
('ranking_down','automatic','Oups. Le rang {rank} est moins confortable. On évite de paniquer.',1,true),
('ranking_down','automatic','Le Hibou a vu la chute. {player} perd {rank_delta} place(s). Il reste du temps.',1,true),
('ranking_down','automatic','Le Hibou a vu la chute. {player} perd {rank_delta} place(s). On évite de paniquer.',1,true),
('ranking_down','automatic','Le Hibou a vu la chute. {player} glisse au rang {rank}. Il reste du temps.',1,true),
('ranking_down','automatic','Le Hibou a vu la chute. {player} glisse au rang {rank}. On évite de paniquer.',1,true),
('ranking_down','automatic','Le Hibou a vu la chute. -{rank_delta} au classement. Il reste du temps.',1,true),
('ranking_down','automatic','Le Hibou a vu la chute. -{rank_delta} au classement. On évite de paniquer.',1,true),
('ranking_down','automatic','Le Hibou a vu la chute. Le rang {rank} est moins confortable. Il reste du temps.',1,true),
('ranking_down','automatic','Le Hibou a vu la chute. Le rang {rank} est moins confortable. On évite de paniquer.',1,true),
('badge_common','automatic','Nouveau badge. {player} débloque {badge}. Bien joué.',1,true),
('badge_common','automatic','Nouveau badge. {player} débloque {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Nouveau badge. Le badge {badge} rejoint la collection. Bien joué.',1,true),
('badge_common','automatic','Nouveau badge. Le badge {badge} rejoint la collection. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Nouveau badge. {badge} est désormais acquis. Bien joué.',1,true),
('badge_common','automatic','Nouveau badge. {badge} est désormais acquis. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Nouveau badge. Le Musée accueille {badge}. Bien joué.',1,true),
('badge_common','automatic','Nouveau badge. Le Musée accueille {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Une petite plume de plus. {player} débloque {badge}. Bien joué.',1,true),
('badge_common','automatic','Une petite plume de plus. {player} débloque {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Une petite plume de plus. Le badge {badge} rejoint la collection. Bien joué.',1,true),
('badge_common','automatic','Une petite plume de plus. Le badge {badge} rejoint la collection. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Une petite plume de plus. {badge} est désormais acquis. Bien joué.',1,true),
('badge_common','automatic','Une petite plume de plus. {badge} est désormais acquis. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Une petite plume de plus. Le Musée accueille {badge}. Bien joué.',1,true),
('badge_common','automatic','Une petite plume de plus. Le Musée accueille {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Le Musée s’agrandit. {player} débloque {badge}. Bien joué.',1,true),
('badge_common','automatic','Le Musée s’agrandit. {player} débloque {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Le Musée s’agrandit. Le badge {badge} rejoint la collection. Bien joué.',1,true),
('badge_common','automatic','Le Musée s’agrandit. Le badge {badge} rejoint la collection. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Le Musée s’agrandit. {badge} est désormais acquis. Bien joué.',1,true),
('badge_common','automatic','Le Musée s’agrandit. {badge} est désormais acquis. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Le Musée s’agrandit. Le Musée accueille {badge}. Bien joué.',1,true),
('badge_common','automatic','Le Musée s’agrandit. Le Musée accueille {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Déblocage propre. {player} débloque {badge}. Bien joué.',1,true),
('badge_common','automatic','Déblocage propre. {player} débloque {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Déblocage propre. Le badge {badge} rejoint la collection. Bien joué.',1,true),
('badge_common','automatic','Déblocage propre. Le badge {badge} rejoint la collection. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Déblocage propre. {badge} est désormais acquis. Bien joué.',1,true),
('badge_common','automatic','Déblocage propre. {badge} est désormais acquis. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Déblocage propre. Le Musée accueille {badge}. Bien joué.',1,true),
('badge_common','automatic','Déblocage propre. Le Musée accueille {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Ça compte. {player} débloque {badge}. Bien joué.',1,true),
('badge_common','automatic','Ça compte. {player} débloque {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Ça compte. Le badge {badge} rejoint la collection. Bien joué.',1,true),
('badge_common','automatic','Ça compte. Le badge {badge} rejoint la collection. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Ça compte. {badge} est désormais acquis. Bien joué.',1,true),
('badge_common','automatic','Ça compte. {badge} est désormais acquis. Premier pas vers les vitrines pleines.',1,true),
('badge_common','automatic','Ça compte. Le Musée accueille {badge}. Bien joué.',1,true),
('badge_common','automatic','Ça compte. Le Musée accueille {badge}. Premier pas vers les vitrines pleines.',1,true),
('badge_rare','automatic','Ça devient sérieux. {player} débloque {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Ça devient sérieux. {player} débloque {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Ça devient sérieux. {badge} rejoint la collection de {player}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Ça devient sérieux. {badge} rejoint la collection de {player}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Ça devient sérieux. Un badge rare tombe : {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Ça devient sérieux. Un badge rare tombe : {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Ça devient sérieux. {badge} vient de céder. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Ça devient sérieux. {badge} vient de céder. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Badge rare débloqué. {player} débloque {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Badge rare débloqué. {player} débloque {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Badge rare débloqué. {badge} rejoint la collection de {player}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Badge rare débloqué. {badge} rejoint la collection de {player}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Badge rare débloqué. Un badge rare tombe : {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Badge rare débloqué. Un badge rare tombe : {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Badge rare débloqué. {badge} vient de céder. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Badge rare débloqué. {badge} vient de céder. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Le Musée s’allume en bleu. {player} débloque {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Le Musée s’allume en bleu. {player} débloque {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Le Musée s’allume en bleu. {badge} rejoint la collection de {player}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Le Musée s’allume en bleu. {badge} rejoint la collection de {player}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Le Musée s’allume en bleu. Un badge rare tombe : {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Le Musée s’allume en bleu. Un badge rare tombe : {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Le Musée s’allume en bleu. {badge} vient de céder. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Le Musée s’allume en bleu. {badge} vient de céder. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Belle trouvaille. {player} débloque {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Belle trouvaille. {player} débloque {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Belle trouvaille. {badge} rejoint la collection de {player}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Belle trouvaille. {badge} rejoint la collection de {player}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Belle trouvaille. Un badge rare tombe : {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Belle trouvaille. Un badge rare tombe : {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Belle trouvaille. {badge} vient de céder. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Belle trouvaille. {badge} vient de céder. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Le Hibou valide. {player} débloque {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Le Hibou valide. {player} débloque {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Le Hibou valide. {badge} rejoint la collection de {player}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Le Hibou valide. {badge} rejoint la collection de {player}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Le Hibou valide. Un badge rare tombe : {badge}. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Le Hibou valide. Un badge rare tombe : {badge}. Ça mérite un regard de travers.',1,true),
('badge_rare','automatic','Le Hibou valide. {badge} vient de céder. Pas donné à tout le monde.',1,true),
('badge_rare','automatic','Le Hibou valide. {badge} vient de céder. Ça mérite un regard de travers.',1,true),
('badge_epic','automatic','ÉPIQUE. {player} débloque {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','ÉPIQUE. {player} débloque {badge}. À encadrer.',1,true),
('badge_epic','automatic','ÉPIQUE. Badge épique : {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','ÉPIQUE. Badge épique : {badge}. À encadrer.',1,true),
('badge_epic','automatic','ÉPIQUE. {badge} rejoint une collection qui commence à faire peur. Très grosse prise.',1,true),
('badge_epic','automatic','ÉPIQUE. {badge} rejoint une collection qui commence à faire peur. À encadrer.',1,true),
('badge_epic','automatic','ÉPIQUE. Le Nid enregistre {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','ÉPIQUE. Le Nid enregistre {badge}. À encadrer.',1,true),
('badge_epic','automatic','Le Musée vient de trembler. {player} débloque {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Le Musée vient de trembler. {player} débloque {badge}. À encadrer.',1,true),
('badge_epic','automatic','Le Musée vient de trembler. Badge épique : {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Le Musée vient de trembler. Badge épique : {badge}. À encadrer.',1,true),
('badge_epic','automatic','Le Musée vient de trembler. {badge} rejoint une collection qui commence à faire peur. Très grosse prise.',1,true),
('badge_epic','automatic','Le Musée vient de trembler. {badge} rejoint une collection qui commence à faire peur. À encadrer.',1,true),
('badge_epic','automatic','Le Musée vient de trembler. Le Nid enregistre {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Le Musée vient de trembler. Le Nid enregistre {badge}. À encadrer.',1,true),
('badge_epic','automatic','Grosse lumière dans le Nid. {player} débloque {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Grosse lumière dans le Nid. {player} débloque {badge}. À encadrer.',1,true),
('badge_epic','automatic','Grosse lumière dans le Nid. Badge épique : {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Grosse lumière dans le Nid. Badge épique : {badge}. À encadrer.',1,true),
('badge_epic','automatic','Grosse lumière dans le Nid. {badge} rejoint une collection qui commence à faire peur. Très grosse prise.',1,true),
('badge_epic','automatic','Grosse lumière dans le Nid. {badge} rejoint une collection qui commence à faire peur. À encadrer.',1,true),
('badge_epic','automatic','Grosse lumière dans le Nid. Le Nid enregistre {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Grosse lumière dans le Nid. Le Nid enregistre {badge}. À encadrer.',1,true),
('badge_epic','automatic','Ça, c’est lourd. {player} débloque {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Ça, c’est lourd. {player} débloque {badge}. À encadrer.',1,true),
('badge_epic','automatic','Ça, c’est lourd. Badge épique : {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Ça, c’est lourd. Badge épique : {badge}. À encadrer.',1,true),
('badge_epic','automatic','Ça, c’est lourd. {badge} rejoint une collection qui commence à faire peur. Très grosse prise.',1,true),
('badge_epic','automatic','Ça, c’est lourd. {badge} rejoint une collection qui commence à faire peur. À encadrer.',1,true),
('badge_epic','automatic','Ça, c’est lourd. Le Nid enregistre {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Ça, c’est lourd. Le Nid enregistre {badge}. À encadrer.',1,true),
('badge_epic','automatic','Le Hibou se redresse. {player} débloque {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Le Hibou se redresse. {player} débloque {badge}. À encadrer.',1,true),
('badge_epic','automatic','Le Hibou se redresse. Badge épique : {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Le Hibou se redresse. Badge épique : {badge}. À encadrer.',1,true),
('badge_epic','automatic','Le Hibou se redresse. {badge} rejoint une collection qui commence à faire peur. Très grosse prise.',1,true),
('badge_epic','automatic','Le Hibou se redresse. {badge} rejoint une collection qui commence à faire peur. À encadrer.',1,true),
('badge_epic','automatic','Le Hibou se redresse. Le Nid enregistre {badge}. Très grosse prise.',1,true),
('badge_epic','automatic','Le Hibou se redresse. Le Nid enregistre {badge}. À encadrer.',1,true),
('badge_legendary','automatic','LÉGENDAIRE. {player} débloque {badge}. Immense.',1,true),
('badge_legendary','automatic','LÉGENDAIRE. {player} débloque {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','LÉGENDAIRE. Badge légendaire : {badge}. Immense.',1,true),
('badge_legendary','automatic','LÉGENDAIRE. Badge légendaire : {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','LÉGENDAIRE. {badge} vient d’être conquis. Immense.',1,true),
('badge_legendary','automatic','LÉGENDAIRE. {badge} vient d’être conquis. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','LÉGENDAIRE. Le Musée accueille une pièce majeure : {badge}. Immense.',1,true),
('badge_legendary','automatic','LÉGENDAIRE. Le Musée accueille une pièce majeure : {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Le Nid s’arrête une seconde. {player} débloque {badge}. Immense.',1,true),
('badge_legendary','automatic','Le Nid s’arrête une seconde. {player} débloque {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Le Nid s’arrête une seconde. Badge légendaire : {badge}. Immense.',1,true),
('badge_legendary','automatic','Le Nid s’arrête une seconde. Badge légendaire : {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Le Nid s’arrête une seconde. {badge} vient d’être conquis. Immense.',1,true),
('badge_legendary','automatic','Le Nid s’arrête une seconde. {badge} vient d’être conquis. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Le Nid s’arrête une seconde. Le Musée accueille une pièce majeure : {badge}. Immense.',1,true),
('badge_legendary','automatic','Le Nid s’arrête une seconde. Le Musée accueille une pièce majeure : {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Les vitrines viennent de s’illuminer. {player} débloque {badge}. Immense.',1,true),
('badge_legendary','automatic','Les vitrines viennent de s’illuminer. {player} débloque {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Les vitrines viennent de s’illuminer. Badge légendaire : {badge}. Immense.',1,true),
('badge_legendary','automatic','Les vitrines viennent de s’illuminer. Badge légendaire : {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Les vitrines viennent de s’illuminer. {badge} vient d’être conquis. Immense.',1,true),
('badge_legendary','automatic','Les vitrines viennent de s’illuminer. {badge} vient d’être conquis. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Les vitrines viennent de s’illuminer. Le Musée accueille une pièce majeure : {badge}. Immense.',1,true),
('badge_legendary','automatic','Les vitrines viennent de s’illuminer. Le Musée accueille une pièce majeure : {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Le Hibou retire son chapeau. {player} débloque {badge}. Immense.',1,true),
('badge_legendary','automatic','Le Hibou retire son chapeau. {player} débloque {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Le Hibou retire son chapeau. Badge légendaire : {badge}. Immense.',1,true),
('badge_legendary','automatic','Le Hibou retire son chapeau. Badge légendaire : {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Le Hibou retire son chapeau. {badge} vient d’être conquis. Immense.',1,true),
('badge_legendary','automatic','Le Hibou retire son chapeau. {badge} vient d’être conquis. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Le Hibou retire son chapeau. Le Musée accueille une pièce majeure : {badge}. Immense.',1,true),
('badge_legendary','automatic','Le Hibou retire son chapeau. Le Musée accueille une pièce majeure : {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Ça entre dans l’histoire. {player} débloque {badge}. Immense.',1,true),
('badge_legendary','automatic','Ça entre dans l’histoire. {player} débloque {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Ça entre dans l’histoire. Badge légendaire : {badge}. Immense.',1,true),
('badge_legendary','automatic','Ça entre dans l’histoire. Badge légendaire : {badge}. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Ça entre dans l’histoire. {badge} vient d’être conquis. Immense.',1,true),
('badge_legendary','automatic','Ça entre dans l’histoire. {badge} vient d’être conquis. On en reparlera longtemps.',1,true),
('badge_legendary','automatic','Ça entre dans l’histoire. Le Musée accueille une pièce majeure : {badge}. Immense.',1,true),
('badge_legendary','automatic','Ça entre dans l’histoire. Le Musée accueille une pièce majeure : {badge}. On en reparlera longtemps.',1,true),
('secret_found','automatic','Quelque chose vient de bouger dans l’ombre. {player} vient de découvrir un secret du Nid. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Quelque chose vient de bouger dans l’ombre. {player} vient de découvrir un secret du Nid. Inutile de poser des questions.',1,true),
('secret_found','automatic','Quelque chose vient de bouger dans l’ombre. Un secret a été trouvé par {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Quelque chose vient de bouger dans l’ombre. Un secret a été trouvé par {player}. Inutile de poser des questions.',1,true),
('secret_found','automatic','Quelque chose vient de bouger dans l’ombre. {player}{team_phrase} a mis la patte sur quelque chose. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Quelque chose vient de bouger dans l’ombre. {player}{team_phrase} a mis la patte sur quelque chose. Inutile de poser des questions.',1,true),
('secret_found','automatic','Quelque chose vient de bouger dans l’ombre. Le premier découvreur est {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Quelque chose vient de bouger dans l’ombre. Le premier découvreur est {player}. Inutile de poser des questions.',1,true),
('secret_found','automatic','Le Hibou referme brusquement un tiroir. {player} vient de découvrir un secret du Nid. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Le Hibou referme brusquement un tiroir. {player} vient de découvrir un secret du Nid. Inutile de poser des questions.',1,true),
('secret_found','automatic','Le Hibou referme brusquement un tiroir. Un secret a été trouvé par {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Le Hibou referme brusquement un tiroir. Un secret a été trouvé par {player}. Inutile de poser des questions.',1,true),
('secret_found','automatic','Le Hibou referme brusquement un tiroir. {player}{team_phrase} a mis la patte sur quelque chose. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Le Hibou referme brusquement un tiroir. {player}{team_phrase} a mis la patte sur quelque chose. Inutile de poser des questions.',1,true),
('secret_found','automatic','Le Hibou referme brusquement un tiroir. Le premier découvreur est {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Le Hibou referme brusquement un tiroir. Le premier découvreur est {player}. Inutile de poser des questions.',1,true),
('secret_found','automatic','Un verrou secret vient de céder. {player} vient de découvrir un secret du Nid. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Un verrou secret vient de céder. {player} vient de découvrir un secret du Nid. Inutile de poser des questions.',1,true),
('secret_found','automatic','Un verrou secret vient de céder. Un secret a été trouvé par {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Un verrou secret vient de céder. Un secret a été trouvé par {player}. Inutile de poser des questions.',1,true),
('secret_found','automatic','Un verrou secret vient de céder. {player}{team_phrase} a mis la patte sur quelque chose. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Un verrou secret vient de céder. {player}{team_phrase} a mis la patte sur quelque chose. Inutile de poser des questions.',1,true),
('secret_found','automatic','Un verrou secret vient de céder. Le premier découvreur est {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Un verrou secret vient de céder. Le premier découvreur est {player}. Inutile de poser des questions.',1,true),
('secret_found','automatic','Le Musée a entendu un clic. {player} vient de découvrir un secret du Nid. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Le Musée a entendu un clic. {player} vient de découvrir un secret du Nid. Inutile de poser des questions.',1,true),
('secret_found','automatic','Le Musée a entendu un clic. Un secret a été trouvé par {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Le Musée a entendu un clic. Un secret a été trouvé par {player}. Inutile de poser des questions.',1,true),
('secret_found','automatic','Le Musée a entendu un clic. {player}{team_phrase} a mis la patte sur quelque chose. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Le Musée a entendu un clic. {player}{team_phrase} a mis la patte sur quelque chose. Inutile de poser des questions.',1,true),
('secret_found','automatic','Le Musée a entendu un clic. Le premier découvreur est {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Le Musée a entendu un clic. Le premier découvreur est {player}. Inutile de poser des questions.',1,true),
('secret_found','automatic','Il s’est passé quelque chose. {player} vient de découvrir un secret du Nid. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Il s’est passé quelque chose. {player} vient de découvrir un secret du Nid. Inutile de poser des questions.',1,true),
('secret_found','automatic','Il s’est passé quelque chose. Un secret a été trouvé par {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Il s’est passé quelque chose. Un secret a été trouvé par {player}. Inutile de poser des questions.',1,true),
('secret_found','automatic','Il s’est passé quelque chose. {player}{team_phrase} a mis la patte sur quelque chose. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Il s’est passé quelque chose. {player}{team_phrase} a mis la patte sur quelque chose. Inutile de poser des questions.',1,true),
('secret_found','automatic','Il s’est passé quelque chose. Le premier découvreur est {player}. Le Hibou ne dira rien de plus.',1,true),
('secret_found','automatic','Il s’est passé quelque chose. Le premier découvreur est {player}. Inutile de poser des questions.',1,true),
('casserole_small','automatic','Petite casserole. {player} prend {casserole_points} point casserole. Rien de nucléaire.',1,true),
('casserole_small','automatic','Petite casserole. {player} prend {casserole_points} point casserole. On survivra.',1,true),
('casserole_small','automatic','Petite casserole. Une petite casserole pour {player}. Rien de nucléaire.',1,true),
('casserole_small','automatic','Petite casserole. Une petite casserole pour {player}. On survivra.',1,true),
('casserole_small','automatic','Petite casserole. Le prono {prediction} laisse une trace. Rien de nucléaire.',1,true),
('casserole_small','automatic','Petite casserole. Le prono {prediction} laisse une trace. On survivra.',1,true),
('casserole_small','automatic','Petite casserole. {player} ajoute une casserole légère au Musée. Rien de nucléaire.',1,true),
('casserole_small','automatic','Petite casserole. {player} ajoute une casserole légère au Musée. On survivra.',1,true),
('casserole_small','automatic','Ça chauffe un peu. {player} prend {casserole_points} point casserole. Rien de nucléaire.',1,true),
('casserole_small','automatic','Ça chauffe un peu. {player} prend {casserole_points} point casserole. On survivra.',1,true),
('casserole_small','automatic','Ça chauffe un peu. Une petite casserole pour {player}. Rien de nucléaire.',1,true),
('casserole_small','automatic','Ça chauffe un peu. Une petite casserole pour {player}. On survivra.',1,true),
('casserole_small','automatic','Ça chauffe un peu. Le prono {prediction} laisse une trace. Rien de nucléaire.',1,true),
('casserole_small','automatic','Ça chauffe un peu. Le prono {prediction} laisse une trace. On survivra.',1,true),
('casserole_small','automatic','Ça chauffe un peu. {player} ajoute une casserole légère au Musée. Rien de nucléaire.',1,true),
('casserole_small','automatic','Ça chauffe un peu. {player} ajoute une casserole légère au Musée. On survivra.',1,true),
('casserole_small','automatic','Le manche dépasse. {player} prend {casserole_points} point casserole. Rien de nucléaire.',1,true),
('casserole_small','automatic','Le manche dépasse. {player} prend {casserole_points} point casserole. On survivra.',1,true),
('casserole_small','automatic','Le manche dépasse. Une petite casserole pour {player}. Rien de nucléaire.',1,true),
('casserole_small','automatic','Le manche dépasse. Une petite casserole pour {player}. On survivra.',1,true),
('casserole_small','automatic','Le manche dépasse. Le prono {prediction} laisse une trace. Rien de nucléaire.',1,true),
('casserole_small','automatic','Le manche dépasse. Le prono {prediction} laisse une trace. On survivra.',1,true),
('casserole_small','automatic','Le manche dépasse. {player} ajoute une casserole légère au Musée. Rien de nucléaire.',1,true),
('casserole_small','automatic','Le manche dépasse. {player} ajoute une casserole légère au Musée. On survivra.',1,true),
('casserole_small','automatic','Petit bruit de cuisine. {player} prend {casserole_points} point casserole. Rien de nucléaire.',1,true),
('casserole_small','automatic','Petit bruit de cuisine. {player} prend {casserole_points} point casserole. On survivra.',1,true),
('casserole_small','automatic','Petit bruit de cuisine. Une petite casserole pour {player}. Rien de nucléaire.',1,true),
('casserole_small','automatic','Petit bruit de cuisine. Une petite casserole pour {player}. On survivra.',1,true),
('casserole_small','automatic','Petit bruit de cuisine. Le prono {prediction} laisse une trace. Rien de nucléaire.',1,true),
('casserole_small','automatic','Petit bruit de cuisine. Le prono {prediction} laisse une trace. On survivra.',1,true),
('casserole_small','automatic','Petit bruit de cuisine. {player} ajoute une casserole légère au Musée. Rien de nucléaire.',1,true),
('casserole_small','automatic','Petit bruit de cuisine. {player} ajoute une casserole légère au Musée. On survivra.',1,true),
('casserole_small','automatic','Le Hibou sort une petite poêle. {player} prend {casserole_points} point casserole. Rien de nucléaire.',1,true),
('casserole_small','automatic','Le Hibou sort une petite poêle. {player} prend {casserole_points} point casserole. On survivra.',1,true),
('casserole_small','automatic','Le Hibou sort une petite poêle. Une petite casserole pour {player}. Rien de nucléaire.',1,true),
('casserole_small','automatic','Le Hibou sort une petite poêle. Une petite casserole pour {player}. On survivra.',1,true),
('casserole_small','automatic','Le Hibou sort une petite poêle. Le prono {prediction} laisse une trace. Rien de nucléaire.',1,true),
('casserole_small','automatic','Le Hibou sort une petite poêle. Le prono {prediction} laisse une trace. On survivra.',1,true),
('casserole_small','automatic','Le Hibou sort une petite poêle. {player} ajoute une casserole légère au Musée. Rien de nucléaire.',1,true),
('casserole_small','automatic','Le Hibou sort une petite poêle. {player} ajoute une casserole légère au Musée. On survivra.',1,true),
('casserole_beautiful','automatic','Belle casserole. {player} prend {casserole_points} points casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Belle casserole. {player} prend {casserole_points} points casserole. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Belle casserole. Une belle casserole tombe sur {player}. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Belle casserole. Une belle casserole tombe sur {player}. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Belle casserole. {prediction} mérite sa place au Musée. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Belle casserole. {prediction} mérite sa place au Musée. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Belle casserole. Le Nid enregistre une vraie casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Belle casserole. Le Nid enregistre une vraie casserole. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','La cuisine ouvre. {player} prend {casserole_points} points casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','La cuisine ouvre. {player} prend {casserole_points} points casserole. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','La cuisine ouvre. Une belle casserole tombe sur {player}. Ça se raconte.',1,true),
('casserole_beautiful','automatic','La cuisine ouvre. Une belle casserole tombe sur {player}. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','La cuisine ouvre. {prediction} mérite sa place au Musée. Ça se raconte.',1,true),
('casserole_beautiful','automatic','La cuisine ouvre. {prediction} mérite sa place au Musée. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','La cuisine ouvre. Le Nid enregistre une vraie casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','La cuisine ouvre. Le Nid enregistre une vraie casserole. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Ça commence à sentir le brûlé. {player} prend {casserole_points} points casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Ça commence à sentir le brûlé. {player} prend {casserole_points} points casserole. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Ça commence à sentir le brûlé. Une belle casserole tombe sur {player}. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Ça commence à sentir le brûlé. Une belle casserole tombe sur {player}. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Ça commence à sentir le brûlé. {prediction} mérite sa place au Musée. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Ça commence à sentir le brûlé. {prediction} mérite sa place au Musée. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Ça commence à sentir le brûlé. Le Nid enregistre une vraie casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Ça commence à sentir le brûlé. Le Nid enregistre une vraie casserole. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Le Hibou met des gants. {player} prend {casserole_points} points casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Le Hibou met des gants. {player} prend {casserole_points} points casserole. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Le Hibou met des gants. Une belle casserole tombe sur {player}. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Le Hibou met des gants. Une belle casserole tombe sur {player}. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Le Hibou met des gants. {prediction} mérite sa place au Musée. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Le Hibou met des gants. {prediction} mérite sa place au Musée. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Le Hibou met des gants. Le Nid enregistre une vraie casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Le Hibou met des gants. Le Nid enregistre une vraie casserole. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Joli spécimen. {player} prend {casserole_points} points casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Joli spécimen. {player} prend {casserole_points} points casserole. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Joli spécimen. Une belle casserole tombe sur {player}. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Joli spécimen. Une belle casserole tombe sur {player}. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Joli spécimen. {prediction} mérite sa place au Musée. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Joli spécimen. {prediction} mérite sa place au Musée. Celle-là restera un peu.',1,true),
('casserole_beautiful','automatic','Joli spécimen. Le Nid enregistre une vraie casserole. Ça se raconte.',1,true),
('casserole_beautiful','automatic','Joli spécimen. Le Nid enregistre une vraie casserole. Celle-là restera un peu.',1,true),
('casserole_industrial','automatic','CASSEROLE INDUSTRIELLE. {player} prend {casserole_points} points casserole. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','CASSEROLE INDUSTRIELLE. {player} prend {casserole_points} points casserole. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','CASSEROLE INDUSTRIELLE. Le prono {prediction} part au Musée industriel. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','CASSEROLE INDUSTRIELLE. Le prono {prediction} part au Musée industriel. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','CASSEROLE INDUSTRIELLE. {player} signe une casserole massive. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','CASSEROLE INDUSTRIELLE. {player} signe une casserole massive. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','CASSEROLE INDUSTRIELLE. Le Nid vient d’enregistrer un gros morceau. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','CASSEROLE INDUSTRIELLE. Le Nid vient d’enregistrer un gros morceau. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','La cuisine vient de perdre le contrôle. {player} prend {casserole_points} points casserole. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','La cuisine vient de perdre le contrôle. {player} prend {casserole_points} points casserole. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','La cuisine vient de perdre le contrôle. Le prono {prediction} part au Musée industriel. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','La cuisine vient de perdre le contrôle. Le prono {prediction} part au Musée industriel. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','La cuisine vient de perdre le contrôle. {player} signe une casserole massive. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','La cuisine vient de perdre le contrôle. {player} signe une casserole massive. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','La cuisine vient de perdre le contrôle. Le Nid vient d’enregistrer un gros morceau. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','La cuisine vient de perdre le contrôle. Le Nid vient d’enregistrer un gros morceau. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Le Hibou appelle la maintenance. {player} prend {casserole_points} points casserole. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Le Hibou appelle la maintenance. {player} prend {casserole_points} points casserole. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Le Hibou appelle la maintenance. Le prono {prediction} part au Musée industriel. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Le Hibou appelle la maintenance. Le prono {prediction} part au Musée industriel. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Le Hibou appelle la maintenance. {player} signe une casserole massive. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Le Hibou appelle la maintenance. {player} signe une casserole massive. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Le Hibou appelle la maintenance. Le Nid vient d’enregistrer un gros morceau. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Le Hibou appelle la maintenance. Le Nid vient d’enregistrer un gros morceau. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Gros bruit métallique dans le Nid. {player} prend {casserole_points} points casserole. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Gros bruit métallique dans le Nid. {player} prend {casserole_points} points casserole. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Gros bruit métallique dans le Nid. Le prono {prediction} part au Musée industriel. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Gros bruit métallique dans le Nid. Le prono {prediction} part au Musée industriel. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Gros bruit métallique dans le Nid. {player} signe une casserole massive. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Gros bruit métallique dans le Nid. {player} signe une casserole massive. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Gros bruit métallique dans le Nid. Le Nid vient d’enregistrer un gros morceau. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Gros bruit métallique dans le Nid. Le Nid vient d’enregistrer un gros morceau. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Ça fume sérieusement. {player} prend {casserole_points} points casserole. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Ça fume sérieusement. {player} prend {casserole_points} points casserole. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Ça fume sérieusement. Le prono {prediction} part au Musée industriel. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Ça fume sérieusement. Le prono {prediction} part au Musée industriel. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Ça fume sérieusement. {player} signe une casserole massive. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Ça fume sérieusement. {player} signe une casserole massive. Celle-là sera publique.',1,true),
('casserole_industrial','automatic','Ça fume sérieusement. Le Nid vient d’enregistrer un gros morceau. Les voisins ont entendu.',1,true),
('casserole_industrial','automatic','Ça fume sérieusement. Le Nid vient d’enregistrer un gros morceau. Celle-là sera publique.',1,true),
('casserole_nuclear','automatic','☢️ CASSEROLE NUCLÉAIRE. {player} prend {casserole_points} points casserole. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','☢️ CASSEROLE NUCLÉAIRE. {player} prend {casserole_points} points casserole. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','☢️ CASSEROLE NUCLÉAIRE. Le prono {prediction} entre dans une autre dimension. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','☢️ CASSEROLE NUCLÉAIRE. Le prono {prediction} entre dans une autre dimension. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','☢️ CASSEROLE NUCLÉAIRE. {player} vient de produire un objet historique. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','☢️ CASSEROLE NUCLÉAIRE. {player} vient de produire un objet historique. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','☢️ CASSEROLE NUCLÉAIRE. Le Musée réserve une vitrine blindée. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','☢️ CASSEROLE NUCLÉAIRE. Le Musée réserve une vitrine blindée. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Le Nid vient de déclencher une alarme. {player} prend {casserole_points} points casserole. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Le Nid vient de déclencher une alarme. {player} prend {casserole_points} points casserole. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Le Nid vient de déclencher une alarme. Le prono {prediction} entre dans une autre dimension. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Le Nid vient de déclencher une alarme. Le prono {prediction} entre dans une autre dimension. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Le Nid vient de déclencher une alarme. {player} vient de produire un objet historique. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Le Nid vient de déclencher une alarme. {player} vient de produire un objet historique. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Le Nid vient de déclencher une alarme. Le Musée réserve une vitrine blindée. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Le Nid vient de déclencher une alarme. Le Musée réserve une vitrine blindée. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Même le Hibou recule. {player} prend {casserole_points} points casserole. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Même le Hibou recule. {player} prend {casserole_points} points casserole. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Même le Hibou recule. Le prono {prediction} entre dans une autre dimension. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Même le Hibou recule. Le prono {prediction} entre dans une autre dimension. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Même le Hibou recule. {player} vient de produire un objet historique. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Même le Hibou recule. {player} vient de produire un objet historique. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Même le Hibou recule. Le Musée réserve une vitrine blindée. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Même le Hibou recule. Le Musée réserve une vitrine blindée. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Les experts refusent le dossier. {player} prend {casserole_points} points casserole. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Les experts refusent le dossier. {player} prend {casserole_points} points casserole. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Les experts refusent le dossier. Le prono {prediction} entre dans une autre dimension. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Les experts refusent le dossier. Le prono {prediction} entre dans une autre dimension. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Les experts refusent le dossier. {player} vient de produire un objet historique. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Les experts refusent le dossier. {player} vient de produire un objet historique. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','Les experts refusent le dossier. Le Musée réserve une vitrine blindée. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','Les experts refusent le dossier. Le Musée réserve une vitrine blindée. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','On ferme la cuisine. {player} prend {casserole_points} points casserole. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','On ferme la cuisine. {player} prend {casserole_points} points casserole. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','On ferme la cuisine. Le prono {prediction} entre dans une autre dimension. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','On ferme la cuisine. Le prono {prediction} entre dans une autre dimension. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','On ferme la cuisine. {player} vient de produire un objet historique. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','On ferme la cuisine. {player} vient de produire un objet historique. Aucun commentaire ne suffira.',1,true),
('casserole_nuclear','automatic','On ferme la cuisine. Le Musée réserve une vitrine blindée. Les générations futures jugeront.',1,true),
('casserole_nuclear','automatic','On ferme la cuisine. Le Musée réserve une vitrine blindée. Aucun commentaire ne suffira.',1,true),
('genius_1','automatic','Petit éclair. {player} prend {genius_points} point Génie. Bien vu.',1,true),
('genius_1','automatic','Petit éclair. {player} prend {genius_points} point Génie. À confirmer.',1,true),
('genius_1','automatic','Petit éclair. Un choix minoritaire rapporte du Génie. Bien vu.',1,true),
('genius_1','automatic','Petit éclair. Un choix minoritaire rapporte du Génie. À confirmer.',1,true),
('genius_1','automatic','Petit éclair. {prediction} était bien senti. Bien vu.',1,true),
('genius_1','automatic','Petit éclair. {prediction} était bien senti. À confirmer.',1,true),
('genius_1','automatic','Petit éclair. Le coup passe. Bien vu.',1,true),
('genius_1','automatic','Petit éclair. Le coup passe. À confirmer.',1,true),
('genius_1','automatic','Le flair a parlé. {player} prend {genius_points} point Génie. Bien vu.',1,true),
('genius_1','automatic','Le flair a parlé. {player} prend {genius_points} point Génie. À confirmer.',1,true),
('genius_1','automatic','Le flair a parlé. Un choix minoritaire rapporte du Génie. Bien vu.',1,true),
('genius_1','automatic','Le flair a parlé. Un choix minoritaire rapporte du Génie. À confirmer.',1,true),
('genius_1','automatic','Le flair a parlé. {prediction} était bien senti. Bien vu.',1,true),
('genius_1','automatic','Le flair a parlé. {prediction} était bien senti. À confirmer.',1,true),
('genius_1','automatic','Le flair a parlé. Le coup passe. Bien vu.',1,true),
('genius_1','automatic','Le flair a parlé. Le coup passe. À confirmer.',1,true),
('genius_1','automatic','Bonne intuition. {player} prend {genius_points} point Génie. Bien vu.',1,true),
('genius_1','automatic','Bonne intuition. {player} prend {genius_points} point Génie. À confirmer.',1,true),
('genius_1','automatic','Bonne intuition. Un choix minoritaire rapporte du Génie. Bien vu.',1,true),
('genius_1','automatic','Bonne intuition. Un choix minoritaire rapporte du Génie. À confirmer.',1,true),
('genius_1','automatic','Bonne intuition. {prediction} était bien senti. Bien vu.',1,true),
('genius_1','automatic','Bonne intuition. {prediction} était bien senti. À confirmer.',1,true),
('genius_1','automatic','Bonne intuition. Le coup passe. Bien vu.',1,true),
('genius_1','automatic','Bonne intuition. Le coup passe. À confirmer.',1,true),
('genius_1','automatic','Le Hibou note le détail. {player} prend {genius_points} point Génie. Bien vu.',1,true),
('genius_1','automatic','Le Hibou note le détail. {player} prend {genius_points} point Génie. À confirmer.',1,true),
('genius_1','automatic','Le Hibou note le détail. Un choix minoritaire rapporte du Génie. Bien vu.',1,true),
('genius_1','automatic','Le Hibou note le détail. Un choix minoritaire rapporte du Génie. À confirmer.',1,true),
('genius_1','automatic','Le Hibou note le détail. {prediction} était bien senti. Bien vu.',1,true),
('genius_1','automatic','Le Hibou note le détail. {prediction} était bien senti. À confirmer.',1,true),
('genius_1','automatic','Le Hibou note le détail. Le coup passe. Bien vu.',1,true),
('genius_1','automatic','Le Hibou note le détail. Le coup passe. À confirmer.',1,true),
('genius_1','automatic','Ça mérite un point de génie. {player} prend {genius_points} point Génie. Bien vu.',1,true),
('genius_1','automatic','Ça mérite un point de génie. {player} prend {genius_points} point Génie. À confirmer.',1,true),
('genius_1','automatic','Ça mérite un point de génie. Un choix minoritaire rapporte du Génie. Bien vu.',1,true),
('genius_1','automatic','Ça mérite un point de génie. Un choix minoritaire rapporte du Génie. À confirmer.',1,true),
('genius_1','automatic','Ça mérite un point de génie. {prediction} était bien senti. Bien vu.',1,true),
('genius_1','automatic','Ça mérite un point de génie. {prediction} était bien senti. À confirmer.',1,true),
('genius_1','automatic','Ça mérite un point de génie. Le coup passe. Bien vu.',1,true),
('genius_1','automatic','Ça mérite un point de génie. Le coup passe. À confirmer.',1,true),
('genius_3','automatic','Beau coup. {player} prend {genius_points} points Génie. Solide.',1,true),
('genius_3','automatic','Beau coup. {player} prend {genius_points} points Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Beau coup. {prediction} rapporte du Génie. Solide.',1,true),
('genius_3','automatic','Beau coup. {prediction} rapporte du Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Beau coup. Le choix de {player} était rare et juste. Solide.',1,true),
('genius_3','automatic','Beau coup. Le choix de {player} était rare et juste. Pas mal du tout.',1,true),
('genius_3','automatic','Beau coup. Un beau coup entre au Musée. Solide.',1,true),
('genius_3','automatic','Beau coup. Un beau coup entre au Musée. Pas mal du tout.',1,true),
('genius_3','automatic','Le flair se confirme. {player} prend {genius_points} points Génie. Solide.',1,true),
('genius_3','automatic','Le flair se confirme. {player} prend {genius_points} points Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Le flair se confirme. {prediction} rapporte du Génie. Solide.',1,true),
('genius_3','automatic','Le flair se confirme. {prediction} rapporte du Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Le flair se confirme. Le choix de {player} était rare et juste. Solide.',1,true),
('genius_3','automatic','Le flair se confirme. Le choix de {player} était rare et juste. Pas mal du tout.',1,true),
('genius_3','automatic','Le flair se confirme. Un beau coup entre au Musée. Solide.',1,true),
('genius_3','automatic','Le flair se confirme. Un beau coup entre au Musée. Pas mal du tout.',1,true),
('genius_3','automatic','Ça commence à sentir le cerveau. {player} prend {genius_points} points Génie. Solide.',1,true),
('genius_3','automatic','Ça commence à sentir le cerveau. {player} prend {genius_points} points Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Ça commence à sentir le cerveau. {prediction} rapporte du Génie. Solide.',1,true),
('genius_3','automatic','Ça commence à sentir le cerveau. {prediction} rapporte du Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Ça commence à sentir le cerveau. Le choix de {player} était rare et juste. Solide.',1,true),
('genius_3','automatic','Ça commence à sentir le cerveau. Le choix de {player} était rare et juste. Pas mal du tout.',1,true),
('genius_3','automatic','Ça commence à sentir le cerveau. Un beau coup entre au Musée. Solide.',1,true),
('genius_3','automatic','Ça commence à sentir le cerveau. Un beau coup entre au Musée. Pas mal du tout.',1,true),
('genius_3','automatic','Le Hibou approuve. {player} prend {genius_points} points Génie. Solide.',1,true),
('genius_3','automatic','Le Hibou approuve. {player} prend {genius_points} points Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Le Hibou approuve. {prediction} rapporte du Génie. Solide.',1,true),
('genius_3','automatic','Le Hibou approuve. {prediction} rapporte du Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Le Hibou approuve. Le choix de {player} était rare et juste. Solide.',1,true),
('genius_3','automatic','Le Hibou approuve. Le choix de {player} était rare et juste. Pas mal du tout.',1,true),
('genius_3','automatic','Le Hibou approuve. Un beau coup entre au Musée. Solide.',1,true),
('genius_3','automatic','Le Hibou approuve. Un beau coup entre au Musée. Pas mal du tout.',1,true),
('genius_3','automatic','Jolie lecture minoritaire. {player} prend {genius_points} points Génie. Solide.',1,true),
('genius_3','automatic','Jolie lecture minoritaire. {player} prend {genius_points} points Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Jolie lecture minoritaire. {prediction} rapporte du Génie. Solide.',1,true),
('genius_3','automatic','Jolie lecture minoritaire. {prediction} rapporte du Génie. Pas mal du tout.',1,true),
('genius_3','automatic','Jolie lecture minoritaire. Le choix de {player} était rare et juste. Solide.',1,true),
('genius_3','automatic','Jolie lecture minoritaire. Le choix de {player} était rare et juste. Pas mal du tout.',1,true),
('genius_3','automatic','Jolie lecture minoritaire. Un beau coup entre au Musée. Solide.',1,true),
('genius_3','automatic','Jolie lecture minoritaire. Un beau coup entre au Musée. Pas mal du tout.',1,true),
('genius_5','automatic','GROS COUP. {player} prend {genius_points} points Génie. Respect.',1,true),
('genius_5','automatic','GROS COUP. {player} prend {genius_points} points Génie. Là, ça cause.',1,true),
('genius_5','automatic','GROS COUP. {prediction} était franchement osé. Respect.',1,true),
('genius_5','automatic','GROS COUP. {prediction} était franchement osé. Là, ça cause.',1,true),
('genius_5','automatic','GROS COUP. Le choix rare de {player} passe. Respect.',1,true),
('genius_5','automatic','GROS COUP. Le choix rare de {player} passe. Là, ça cause.',1,true),
('genius_5','automatic','GROS COUP. Un gros coup de génie est enregistré. Respect.',1,true),
('genius_5','automatic','GROS COUP. Un gros coup de génie est enregistré. Là, ça cause.',1,true),
('genius_5','automatic','Le Nid lève les yeux. {player} prend {genius_points} points Génie. Respect.',1,true),
('genius_5','automatic','Le Nid lève les yeux. {player} prend {genius_points} points Génie. Là, ça cause.',1,true),
('genius_5','automatic','Le Nid lève les yeux. {prediction} était franchement osé. Respect.',1,true),
('genius_5','automatic','Le Nid lève les yeux. {prediction} était franchement osé. Là, ça cause.',1,true),
('genius_5','automatic','Le Nid lève les yeux. Le choix rare de {player} passe. Respect.',1,true),
('genius_5','automatic','Le Nid lève les yeux. Le choix rare de {player} passe. Là, ça cause.',1,true),
('genius_5','automatic','Le Nid lève les yeux. Un gros coup de génie est enregistré. Respect.',1,true),
('genius_5','automatic','Le Nid lève les yeux. Un gros coup de génie est enregistré. Là, ça cause.',1,true),
('genius_5','automatic','Ça devient brillant. {player} prend {genius_points} points Génie. Respect.',1,true),
('genius_5','automatic','Ça devient brillant. {player} prend {genius_points} points Génie. Là, ça cause.',1,true),
('genius_5','automatic','Ça devient brillant. {prediction} était franchement osé. Respect.',1,true),
('genius_5','automatic','Ça devient brillant. {prediction} était franchement osé. Là, ça cause.',1,true),
('genius_5','automatic','Ça devient brillant. Le choix rare de {player} passe. Respect.',1,true),
('genius_5','automatic','Ça devient brillant. Le choix rare de {player} passe. Là, ça cause.',1,true),
('genius_5','automatic','Ça devient brillant. Un gros coup de génie est enregistré. Respect.',1,true),
('genius_5','automatic','Ça devient brillant. Un gros coup de génie est enregistré. Là, ça cause.',1,true),
('genius_5','automatic','Le Hibou vérifie les probabilités. {player} prend {genius_points} points Génie. Respect.',1,true),
('genius_5','automatic','Le Hibou vérifie les probabilités. {player} prend {genius_points} points Génie. Là, ça cause.',1,true),
('genius_5','automatic','Le Hibou vérifie les probabilités. {prediction} était franchement osé. Respect.',1,true),
('genius_5','automatic','Le Hibou vérifie les probabilités. {prediction} était franchement osé. Là, ça cause.',1,true),
('genius_5','automatic','Le Hibou vérifie les probabilités. Le choix rare de {player} passe. Respect.',1,true),
('genius_5','automatic','Le Hibou vérifie les probabilités. Le choix rare de {player} passe. Là, ça cause.',1,true),
('genius_5','automatic','Le Hibou vérifie les probabilités. Un gros coup de génie est enregistré. Respect.',1,true),
('genius_5','automatic','Le Hibou vérifie les probabilités. Un gros coup de génie est enregistré. Là, ça cause.',1,true),
('genius_5','automatic','Très gros flair. {player} prend {genius_points} points Génie. Respect.',1,true),
('genius_5','automatic','Très gros flair. {player} prend {genius_points} points Génie. Là, ça cause.',1,true),
('genius_5','automatic','Très gros flair. {prediction} était franchement osé. Respect.',1,true),
('genius_5','automatic','Très gros flair. {prediction} était franchement osé. Là, ça cause.',1,true),
('genius_5','automatic','Très gros flair. Le choix rare de {player} passe. Respect.',1,true),
('genius_5','automatic','Très gros flair. Le choix rare de {player} passe. Là, ça cause.',1,true),
('genius_5','automatic','Très gros flair. Un gros coup de génie est enregistré. Respect.',1,true),
('genius_5','automatic','Très gros flair. Un gros coup de génie est enregistré. Là, ça cause.',1,true),
('genius_7','automatic','COUP DE GÉNIE. {player} prend {genius_points} points Génie. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','COUP DE GÉNIE. {player} prend {genius_points} points Génie. Ça mérite une annonce.',1,true),
('genius_7','automatic','COUP DE GÉNIE. Le choix de {player} était rarissime et juste. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','COUP DE GÉNIE. Le choix de {player} était rarissime et juste. Ça mérite une annonce.',1,true),
('genius_7','automatic','COUP DE GÉNIE. {prediction} vient de faire du bruit. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','COUP DE GÉNIE. {prediction} vient de faire du bruit. Ça mérite une annonce.',1,true),
('genius_7','automatic','COUP DE GÉNIE. Un gros Génie rejoint le Musée. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','COUP DE GÉNIE. Un gros Génie rejoint le Musée. Ça mérite une annonce.',1,true),
('genius_7','automatic','Le Nid s’agite. {player} prend {genius_points} points Génie. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Le Nid s’agite. {player} prend {genius_points} points Génie. Ça mérite une annonce.',1,true),
('genius_7','automatic','Le Nid s’agite. Le choix de {player} était rarissime et juste. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Le Nid s’agite. Le choix de {player} était rarissime et juste. Ça mérite une annonce.',1,true),
('genius_7','automatic','Le Nid s’agite. {prediction} vient de faire du bruit. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Le Nid s’agite. {prediction} vient de faire du bruit. Ça mérite une annonce.',1,true),
('genius_7','automatic','Le Nid s’agite. Un gros Génie rejoint le Musée. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Le Nid s’agite. Un gros Génie rejoint le Musée. Ça mérite une annonce.',1,true),
('genius_7','automatic','Très peu l’avaient vu venir. {player} prend {genius_points} points Génie. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Très peu l’avaient vu venir. {player} prend {genius_points} points Génie. Ça mérite une annonce.',1,true),
('genius_7','automatic','Très peu l’avaient vu venir. Le choix de {player} était rarissime et juste. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Très peu l’avaient vu venir. Le choix de {player} était rarissime et juste. Ça mérite une annonce.',1,true),
('genius_7','automatic','Très peu l’avaient vu venir. {prediction} vient de faire du bruit. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Très peu l’avaient vu venir. {prediction} vient de faire du bruit. Ça mérite une annonce.',1,true),
('genius_7','automatic','Très peu l’avaient vu venir. Un gros Génie rejoint le Musée. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Très peu l’avaient vu venir. Un gros Génie rejoint le Musée. Ça mérite une annonce.',1,true),
('genius_7','automatic','Le Hibou commence à soupçonner quelque chose. {player} prend {genius_points} points Génie. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Le Hibou commence à soupçonner quelque chose. {player} prend {genius_points} points Génie. Ça mérite une annonce.',1,true),
('genius_7','automatic','Le Hibou commence à soupçonner quelque chose. Le choix de {player} était rarissime et juste. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Le Hibou commence à soupçonner quelque chose. Le choix de {player} était rarissime et juste. Ça mérite une annonce.',1,true),
('genius_7','automatic','Le Hibou commence à soupçonner quelque chose. {prediction} vient de faire du bruit. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Le Hibou commence à soupçonner quelque chose. {prediction} vient de faire du bruit. Ça mérite une annonce.',1,true),
('genius_7','automatic','Le Hibou commence à soupçonner quelque chose. Un gros Génie rejoint le Musée. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Le Hibou commence à soupçonner quelque chose. Un gros Génie rejoint le Musée. Ça mérite une annonce.',1,true),
('genius_7','automatic','Ça frôle la prophétie. {player} prend {genius_points} points Génie. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Ça frôle la prophétie. {player} prend {genius_points} points Génie. Ça mérite une annonce.',1,true),
('genius_7','automatic','Ça frôle la prophétie. Le choix de {player} était rarissime et juste. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Ça frôle la prophétie. Le choix de {player} était rarissime et juste. Ça mérite une annonce.',1,true),
('genius_7','automatic','Ça frôle la prophétie. {prediction} vient de faire du bruit. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Ça frôle la prophétie. {prediction} vient de faire du bruit. Ça mérite une annonce.',1,true),
('genius_7','automatic','Ça frôle la prophétie. Un gros Génie rejoint le Musée. Tout le Nid est prévenu.',1,true),
('genius_7','automatic','Ça frôle la prophétie. Un gros Génie rejoint le Musée. Ça mérite une annonce.',1,true),
('genius_10','automatic','🧠 PROPHÉTIQUE. {player} prend 10 points Génie. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','🧠 PROPHÉTIQUE. {player} prend 10 points Génie. C’est presque indécent.',1,true),
('genius_10','automatic','🧠 PROPHÉTIQUE. {player} était seul ou presque, et avait raison. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','🧠 PROPHÉTIQUE. {player} était seul ou presque, et avait raison. C’est presque indécent.',1,true),
('genius_10','automatic','🧠 PROPHÉTIQUE. {prediction} devient un coup prophétique. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','🧠 PROPHÉTIQUE. {prediction} devient un coup prophétique. C’est presque indécent.',1,true),
('genius_10','automatic','🧠 PROPHÉTIQUE. Le Musée vient de gagner une pièce majeure. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','🧠 PROPHÉTIQUE. Le Musée vient de gagner une pièce majeure. C’est presque indécent.',1,true),
('genius_10','automatic','Le futur a manifestement fuité. {player} prend 10 points Génie. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Le futur a manifestement fuité. {player} prend 10 points Génie. C’est presque indécent.',1,true),
('genius_10','automatic','Le futur a manifestement fuité. {player} était seul ou presque, et avait raison. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Le futur a manifestement fuité. {player} était seul ou presque, et avait raison. C’est presque indécent.',1,true),
('genius_10','automatic','Le futur a manifestement fuité. {prediction} devient un coup prophétique. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Le futur a manifestement fuité. {prediction} devient un coup prophétique. C’est presque indécent.',1,true),
('genius_10','automatic','Le futur a manifestement fuité. Le Musée vient de gagner une pièce majeure. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Le futur a manifestement fuité. Le Musée vient de gagner une pièce majeure. C’est presque indécent.',1,true),
('genius_10','automatic','Le Hibou demande un contrôle antidopage temporel. {player} prend 10 points Génie. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Le Hibou demande un contrôle antidopage temporel. {player} prend 10 points Génie. C’est presque indécent.',1,true),
('genius_10','automatic','Le Hibou demande un contrôle antidopage temporel. {player} était seul ou presque, et avait raison. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Le Hibou demande un contrôle antidopage temporel. {player} était seul ou presque, et avait raison. C’est presque indécent.',1,true),
('genius_10','automatic','Le Hibou demande un contrôle antidopage temporel. {prediction} devient un coup prophétique. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Le Hibou demande un contrôle antidopage temporel. {prediction} devient un coup prophétique. C’est presque indécent.',1,true),
('genius_10','automatic','Le Hibou demande un contrôle antidopage temporel. Le Musée vient de gagner une pièce majeure. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Le Hibou demande un contrôle antidopage temporel. Le Musée vient de gagner une pièce majeure. C’est presque indécent.',1,true),
('genius_10','automatic','Personne ou presque n’avait osé. {player} prend 10 points Génie. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Personne ou presque n’avait osé. {player} prend 10 points Génie. C’est presque indécent.',1,true),
('genius_10','automatic','Personne ou presque n’avait osé. {player} était seul ou presque, et avait raison. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Personne ou presque n’avait osé. {player} était seul ou presque, et avait raison. C’est presque indécent.',1,true),
('genius_10','automatic','Personne ou presque n’avait osé. {prediction} devient un coup prophétique. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Personne ou presque n’avait osé. {prediction} devient un coup prophétique. C’est presque indécent.',1,true),
('genius_10','automatic','Personne ou presque n’avait osé. Le Musée vient de gagner une pièce majeure. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Personne ou presque n’avait osé. Le Musée vient de gagner une pièce majeure. C’est presque indécent.',1,true),
('genius_10','automatic','Ça entre directement dans les archives. {player} prend 10 points Génie. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Ça entre directement dans les archives. {player} prend 10 points Génie. C’est presque indécent.',1,true),
('genius_10','automatic','Ça entre directement dans les archives. {player} était seul ou presque, et avait raison. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Ça entre directement dans les archives. {player} était seul ou presque, et avait raison. C’est presque indécent.',1,true),
('genius_10','automatic','Ça entre directement dans les archives. {prediction} devient un coup prophétique. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Ça entre directement dans les archives. {prediction} devient un coup prophétique. C’est presque indécent.',1,true),
('genius_10','automatic','Ça entre directement dans les archives. Le Musée vient de gagner une pièce majeure. Le Nid entier doit le savoir.',1,true),
('genius_10','automatic','Ça entre directement dans les archives. Le Musée vient de gagner une pièce majeure. C’est presque indécent.',1,true),
('record_broken','automatic','RECORD DU NID. {player} établit {record} à {value}. Historique.',1,true),
('record_broken','automatic','RECORD DU NID. {player} établit {record} à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','RECORD DU NID. {record} passe désormais à {value}. Historique.',1,true),
('record_broken','automatic','RECORD DU NID. {record} passe désormais à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','RECORD DU NID. {player} prend le record avec {value}. Historique.',1,true),
('record_broken','automatic','RECORD DU NID. {player} prend le record avec {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','RECORD DU NID. Le nouveau record est {value}. Historique.',1,true),
('record_broken','automatic','RECORD DU NID. Le nouveau record est {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Le plafond vient de bouger. {player} établit {record} à {value}. Historique.',1,true),
('record_broken','automatic','Le plafond vient de bouger. {player} établit {record} à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Le plafond vient de bouger. {record} passe désormais à {value}. Historique.',1,true),
('record_broken','automatic','Le plafond vient de bouger. {record} passe désormais à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Le plafond vient de bouger. {player} prend le record avec {value}. Historique.',1,true),
('record_broken','automatic','Le plafond vient de bouger. {player} prend le record avec {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Le plafond vient de bouger. Le nouveau record est {value}. Historique.',1,true),
('record_broken','automatic','Le plafond vient de bouger. Le nouveau record est {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Nouveau sommet. {player} établit {record} à {value}. Historique.',1,true),
('record_broken','automatic','Nouveau sommet. {player} établit {record} à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Nouveau sommet. {record} passe désormais à {value}. Historique.',1,true),
('record_broken','automatic','Nouveau sommet. {record} passe désormais à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Nouveau sommet. {player} prend le record avec {value}. Historique.',1,true),
('record_broken','automatic','Nouveau sommet. {player} prend le record avec {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Nouveau sommet. Le nouveau record est {value}. Historique.',1,true),
('record_broken','automatic','Nouveau sommet. Le nouveau record est {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Les archives sont réécrites. {player} établit {record} à {value}. Historique.',1,true),
('record_broken','automatic','Les archives sont réécrites. {player} établit {record} à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Les archives sont réécrites. {record} passe désormais à {value}. Historique.',1,true),
('record_broken','automatic','Les archives sont réécrites. {record} passe désormais à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Les archives sont réécrites. {player} prend le record avec {value}. Historique.',1,true),
('record_broken','automatic','Les archives sont réécrites. {player} prend le record avec {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Les archives sont réécrites. Le nouveau record est {value}. Historique.',1,true),
('record_broken','automatic','Les archives sont réécrites. Le nouveau record est {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Le Hibou change la plaque. {player} établit {record} à {value}. Historique.',1,true),
('record_broken','automatic','Le Hibou change la plaque. {player} établit {record} à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Le Hibou change la plaque. {record} passe désormais à {value}. Historique.',1,true),
('record_broken','automatic','Le Hibou change la plaque. {record} passe désormais à {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Le Hibou change la plaque. {player} prend le record avec {value}. Historique.',1,true),
('record_broken','automatic','Le Hibou change la plaque. {player} prend le record avec {value}. Le précédent détenteur a été prévenu.',1,true),
('record_broken','automatic','Le Hibou change la plaque. Le nouveau record est {value}. Historique.',1,true),
('record_broken','automatic','Le Hibou change la plaque. Le nouveau record est {value}. Le précédent détenteur a été prévenu.',1,true),
('record_equal','automatic','Record égalé. {player} égale {record} avec {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Record égalé. {player} égale {record} avec {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Record égalé. {record} est égalé à {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Record égalé. {record} est égalé à {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Record égalé. {player} rejoint la marque de {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Record égalé. {player} rejoint la marque de {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Record égalé. La meilleure marque est rejointe. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Record égalé. La meilleure marque est rejointe. Chronologie oblige.',1,true),
('record_equal','automatic','Même hauteur. {player} égale {record} avec {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Même hauteur. {player} égale {record} avec {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Même hauteur. {record} est égalé à {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Même hauteur. {record} est égalé à {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Même hauteur. {player} rejoint la marque de {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Même hauteur. {player} rejoint la marque de {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Même hauteur. La meilleure marque est rejointe. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Même hauteur. La meilleure marque est rejointe. Chronologie oblige.',1,true),
('record_equal','automatic','Le sommet est rejoint. {player} égale {record} avec {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Le sommet est rejoint. {player} égale {record} avec {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Le sommet est rejoint. {record} est égalé à {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Le sommet est rejoint. {record} est égalé à {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Le sommet est rejoint. {player} rejoint la marque de {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Le sommet est rejoint. {player} rejoint la marque de {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Le sommet est rejoint. La meilleure marque est rejointe. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Le sommet est rejoint. La meilleure marque est rejointe. Chronologie oblige.',1,true),
('record_equal','automatic','Ça touche le plafond. {player} égale {record} avec {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Ça touche le plafond. {player} égale {record} avec {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Ça touche le plafond. {record} est égalé à {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Ça touche le plafond. {record} est égalé à {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Ça touche le plafond. {player} rejoint la marque de {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Ça touche le plafond. {player} rejoint la marque de {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Ça touche le plafond. La meilleure marque est rejointe. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Ça touche le plafond. La meilleure marque est rejointe. Chronologie oblige.',1,true),
('record_equal','automatic','Le Hibou note une égalité. {player} égale {record} avec {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Le Hibou note une égalité. {player} égale {record} avec {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Le Hibou note une égalité. {record} est égalé à {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Le Hibou note une égalité. {record} est égalé à {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Le Hibou note une égalité. {player} rejoint la marque de {value}. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Le Hibou note une égalité. {player} rejoint la marque de {value}. Chronologie oblige.',1,true),
('record_equal','automatic','Le Hibou note une égalité. La meilleure marque est rejointe. Le premier détenteur reste devant.',1,true),
('record_equal','automatic','Le Hibou note une égalité. La meilleure marque est rejointe. Chronologie oblige.',1,true),
('record_lost','automatic','Ton record vient de tomber. {player} vient de perdre le record {record}. Courage.',1,true),
('record_lost','automatic','Ton record vient de tomber. {player} vient de perdre le record {record}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Ton record vient de tomber. {record} a été battu par {other_player}. Courage.',1,true),
('record_lost','automatic','Ton record vient de tomber. {record} a été battu par {other_player}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Ton record vient de tomber. La marque de {value} n’est plus la meilleure. Courage.',1,true),
('record_lost','automatic','Ton record vient de tomber. La marque de {value} n’est plus la meilleure. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Ton record vient de tomber. {other_player} prend le record. Courage.',1,true),
('record_lost','automatic','Ton record vient de tomber. {other_player} prend le record. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Aïe, la plaque change de nom. {player} vient de perdre le record {record}. Courage.',1,true),
('record_lost','automatic','Aïe, la plaque change de nom. {player} vient de perdre le record {record}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Aïe, la plaque change de nom. {record} a été battu par {other_player}. Courage.',1,true),
('record_lost','automatic','Aïe, la plaque change de nom. {record} a été battu par {other_player}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Aïe, la plaque change de nom. La marque de {value} n’est plus la meilleure. Courage.',1,true),
('record_lost','automatic','Aïe, la plaque change de nom. La marque de {value} n’est plus la meilleure. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Aïe, la plaque change de nom. {other_player} prend le record. Courage.',1,true),
('record_lost','automatic','Aïe, la plaque change de nom. {other_player} prend le record. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Le Musée vient de déplacer ton trophée. {player} vient de perdre le record {record}. Courage.',1,true),
('record_lost','automatic','Le Musée vient de déplacer ton trophée. {player} vient de perdre le record {record}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Le Musée vient de déplacer ton trophée. {record} a été battu par {other_player}. Courage.',1,true),
('record_lost','automatic','Le Musée vient de déplacer ton trophée. {record} a été battu par {other_player}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Le Musée vient de déplacer ton trophée. La marque de {value} n’est plus la meilleure. Courage.',1,true),
('record_lost','automatic','Le Musée vient de déplacer ton trophée. La marque de {value} n’est plus la meilleure. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Le Musée vient de déplacer ton trophée. {other_player} prend le record. Courage.',1,true),
('record_lost','automatic','Le Musée vient de déplacer ton trophée. {other_player} prend le record. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Quelqu’un est passé devant. {player} vient de perdre le record {record}. Courage.',1,true),
('record_lost','automatic','Quelqu’un est passé devant. {player} vient de perdre le record {record}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Quelqu’un est passé devant. {record} a été battu par {other_player}. Courage.',1,true),
('record_lost','automatic','Quelqu’un est passé devant. {record} a été battu par {other_player}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Quelqu’un est passé devant. La marque de {value} n’est plus la meilleure. Courage.',1,true),
('record_lost','automatic','Quelqu’un est passé devant. La marque de {value} n’est plus la meilleure. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Quelqu’un est passé devant. {other_player} prend le record. Courage.',1,true),
('record_lost','automatic','Quelqu’un est passé devant. {other_player} prend le record. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Le Hibou apporte une mauvaise nouvelle. {player} vient de perdre le record {record}. Courage.',1,true),
('record_lost','automatic','Le Hibou apporte une mauvaise nouvelle. {player} vient de perdre le record {record}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Le Hibou apporte une mauvaise nouvelle. {record} a été battu par {other_player}. Courage.',1,true),
('record_lost','automatic','Le Hibou apporte une mauvaise nouvelle. {record} a été battu par {other_player}. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Le Hibou apporte une mauvaise nouvelle. La marque de {value} n’est plus la meilleure. Courage.',1,true),
('record_lost','automatic','Le Hibou apporte une mauvaise nouvelle. La marque de {value} n’est plus la meilleure. Il va falloir le reprendre.',1,true),
('record_lost','automatic','Le Hibou apporte une mauvaise nouvelle. {other_player} prend le record. Courage.',1,true),
('record_lost','automatic','Le Hibou apporte une mauvaise nouvelle. {other_player} prend le record. Il va falloir le reprendre.',1,true),
('reminder_missing','automatic','Petit rappel. Il manque {missing} pronostic(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Petit rappel. Il manque {missing} pronostic(s). Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Petit rappel. {missing} case(s) sont encore vides. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Petit rappel. {missing} case(s) sont encore vides. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Petit rappel. Tu as encore {missing} prono(s) à saisir. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Petit rappel. Tu as encore {missing} prono(s) à saisir. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Petit rappel. Le Nid attend {missing} réponse(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Petit rappel. Le Nid attend {missing} réponse(s). Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Le Hibou compte les cases. Il manque {missing} pronostic(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Le Hibou compte les cases. Il manque {missing} pronostic(s). Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Le Hibou compte les cases. {missing} case(s) sont encore vides. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Le Hibou compte les cases. {missing} case(s) sont encore vides. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Le Hibou compte les cases. Tu as encore {missing} prono(s) à saisir. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Le Hibou compte les cases. Tu as encore {missing} prono(s) à saisir. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Le Hibou compte les cases. Le Nid attend {missing} réponse(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Le Hibou compte les cases. Le Nid attend {missing} réponse(s). Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Ça verrouille bientôt. Il manque {missing} pronostic(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Ça verrouille bientôt. Il manque {missing} pronostic(s). Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Ça verrouille bientôt. {missing} case(s) sont encore vides. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Ça verrouille bientôt. {missing} case(s) sont encore vides. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Ça verrouille bientôt. Tu as encore {missing} prono(s) à saisir. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Ça verrouille bientôt. Tu as encore {missing} prono(s) à saisir. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Ça verrouille bientôt. Le Nid attend {missing} réponse(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Ça verrouille bientôt. Le Nid attend {missing} réponse(s). Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Horloge en marche. Il manque {missing} pronostic(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Horloge en marche. Il manque {missing} pronostic(s). Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Horloge en marche. {missing} case(s) sont encore vides. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Horloge en marche. {missing} case(s) sont encore vides. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Horloge en marche. Tu as encore {missing} prono(s) à saisir. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Horloge en marche. Tu as encore {missing} prono(s) à saisir. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','Horloge en marche. Le Nid attend {missing} réponse(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','Horloge en marche. Le Nid attend {missing} réponse(s). Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','On évite le drame de dernière minute. Il manque {missing} pronostic(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','On évite le drame de dernière minute. Il manque {missing} pronostic(s). Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','On évite le drame de dernière minute. {missing} case(s) sont encore vides. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','On évite le drame de dernière minute. {missing} case(s) sont encore vides. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','On évite le drame de dernière minute. Tu as encore {missing} prono(s) à saisir. Il reste {minutes} min.',1,true),
('reminder_missing','automatic','On évite le drame de dernière minute. Tu as encore {missing} prono(s) à saisir. Verrouillage dans {minutes} min.',1,true),
('reminder_missing','automatic','On évite le drame de dernière minute. Le Nid attend {missing} réponse(s). Il reste {minutes} min.',1,true),
('reminder_missing','automatic','On évite le drame de dernière minute. Le Nid attend {missing} réponse(s). Verrouillage dans {minutes} min.',1,true),
('champion_alive','automatic','Toujours vivant. {champion} est toujours en course. Pour l’instant.',1,true),
('champion_alive','automatic','Toujours vivant. {champion} est toujours en course. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Toujours vivant. Ton choix {champion} continue. Pour l’instant.',1,true),
('champion_alive','automatic','Toujours vivant. Ton choix {champion} continue. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Toujours vivant. {champion} reste debout. Pour l’instant.',1,true),
('champion_alive','automatic','Toujours vivant. {champion} reste debout. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Toujours vivant. Le champion choisi avance encore. Pour l’instant.',1,true),
('champion_alive','automatic','Toujours vivant. Le champion choisi avance encore. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Le plan tient. {champion} est toujours en course. Pour l’instant.',1,true),
('champion_alive','automatic','Le plan tient. {champion} est toujours en course. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Le plan tient. Ton choix {champion} continue. Pour l’instant.',1,true),
('champion_alive','automatic','Le plan tient. Ton choix {champion} continue. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Le plan tient. {champion} reste debout. Pour l’instant.',1,true),
('champion_alive','automatic','Le plan tient. {champion} reste debout. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Le plan tient. Le champion choisi avance encore. Pour l’instant.',1,true),
('champion_alive','automatic','Le plan tient. Le champion choisi avance encore. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Ton champion respire encore. {champion} est toujours en course. Pour l’instant.',1,true),
('champion_alive','automatic','Ton champion respire encore. {champion} est toujours en course. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Ton champion respire encore. Ton choix {champion} continue. Pour l’instant.',1,true),
('champion_alive','automatic','Ton champion respire encore. Ton choix {champion} continue. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Ton champion respire encore. {champion} reste debout. Pour l’instant.',1,true),
('champion_alive','automatic','Ton champion respire encore. {champion} reste debout. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Ton champion respire encore. Le champion choisi avance encore. Pour l’instant.',1,true),
('champion_alive','automatic','Ton champion respire encore. Le champion choisi avance encore. On ne s’emballe pas.',1,true),
('champion_alive','automatic','La coupe reste possible. {champion} est toujours en course. Pour l’instant.',1,true),
('champion_alive','automatic','La coupe reste possible. {champion} est toujours en course. On ne s’emballe pas.',1,true),
('champion_alive','automatic','La coupe reste possible. Ton choix {champion} continue. Pour l’instant.',1,true),
('champion_alive','automatic','La coupe reste possible. Ton choix {champion} continue. On ne s’emballe pas.',1,true),
('champion_alive','automatic','La coupe reste possible. {champion} reste debout. Pour l’instant.',1,true),
('champion_alive','automatic','La coupe reste possible. {champion} reste debout. On ne s’emballe pas.',1,true),
('champion_alive','automatic','La coupe reste possible. Le champion choisi avance encore. Pour l’instant.',1,true),
('champion_alive','automatic','La coupe reste possible. Le champion choisi avance encore. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Le Hibou surveille. {champion} est toujours en course. Pour l’instant.',1,true),
('champion_alive','automatic','Le Hibou surveille. {champion} est toujours en course. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Le Hibou surveille. Ton choix {champion} continue. Pour l’instant.',1,true),
('champion_alive','automatic','Le Hibou surveille. Ton choix {champion} continue. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Le Hibou surveille. {champion} reste debout. Pour l’instant.',1,true),
('champion_alive','automatic','Le Hibou surveille. {champion} reste debout. On ne s’emballe pas.',1,true),
('champion_alive','automatic','Le Hibou surveille. Le champion choisi avance encore. Pour l’instant.',1,true),
('champion_alive','automatic','Le Hibou surveille. Le champion choisi avance encore. On ne s’emballe pas.',1,true),
('champion_out','automatic','Fin de route. {champion} est éliminé. Il faudra vivre avec.',1,true),
('champion_out','automatic','Fin de route. {champion} est éliminé. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Fin de route. Ton champion {champion} quitte la compétition. Il faudra vivre avec.',1,true),
('champion_out','automatic','Fin de route. Ton champion {champion} quitte la compétition. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Fin de route. Le parcours de {champion} s’arrête ici. Il faudra vivre avec.',1,true),
('champion_out','automatic','Fin de route. Le parcours de {champion} s’arrête ici. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Fin de route. Le choix {champion} ne gagnera pas la coupe. Il faudra vivre avec.',1,true),
('champion_out','automatic','Fin de route. Le choix {champion} ne gagnera pas la coupe. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Aïe. {champion} est éliminé. Il faudra vivre avec.',1,true),
('champion_out','automatic','Aïe. {champion} est éliminé. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Aïe. Ton champion {champion} quitte la compétition. Il faudra vivre avec.',1,true),
('champion_out','automatic','Aïe. Ton champion {champion} quitte la compétition. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Aïe. Le parcours de {champion} s’arrête ici. Il faudra vivre avec.',1,true),
('champion_out','automatic','Aïe. Le parcours de {champion} s’arrête ici. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Aïe. Le choix {champion} ne gagnera pas la coupe. Il faudra vivre avec.',1,true),
('champion_out','automatic','Aïe. Le choix {champion} ne gagnera pas la coupe. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Le choix champion vient de tomber. {champion} est éliminé. Il faudra vivre avec.',1,true),
('champion_out','automatic','Le choix champion vient de tomber. {champion} est éliminé. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Le choix champion vient de tomber. Ton champion {champion} quitte la compétition. Il faudra vivre avec.',1,true),
('champion_out','automatic','Le choix champion vient de tomber. Ton champion {champion} quitte la compétition. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Le choix champion vient de tomber. Le parcours de {champion} s’arrête ici. Il faudra vivre avec.',1,true),
('champion_out','automatic','Le choix champion vient de tomber. Le parcours de {champion} s’arrête ici. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Le choix champion vient de tomber. Le choix {champion} ne gagnera pas la coupe. Il faudra vivre avec.',1,true),
('champion_out','automatic','Le choix champion vient de tomber. Le choix {champion} ne gagnera pas la coupe. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Le Hibou enlève une épingle du tableau. {champion} est éliminé. Il faudra vivre avec.',1,true),
('champion_out','automatic','Le Hibou enlève une épingle du tableau. {champion} est éliminé. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Le Hibou enlève une épingle du tableau. Ton champion {champion} quitte la compétition. Il faudra vivre avec.',1,true),
('champion_out','automatic','Le Hibou enlève une épingle du tableau. Ton champion {champion} quitte la compétition. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Le Hibou enlève une épingle du tableau. Le parcours de {champion} s’arrête ici. Il faudra vivre avec.',1,true),
('champion_out','automatic','Le Hibou enlève une épingle du tableau. Le parcours de {champion} s’arrête ici. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Le Hibou enlève une épingle du tableau. Le choix {champion} ne gagnera pas la coupe. Il faudra vivre avec.',1,true),
('champion_out','automatic','Le Hibou enlève une épingle du tableau. Le choix {champion} ne gagnera pas la coupe. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Ça fait mal. {champion} est éliminé. Il faudra vivre avec.',1,true),
('champion_out','automatic','Ça fait mal. {champion} est éliminé. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Ça fait mal. Ton champion {champion} quitte la compétition. Il faudra vivre avec.',1,true),
('champion_out','automatic','Ça fait mal. Ton champion {champion} quitte la compétition. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Ça fait mal. Le parcours de {champion} s’arrête ici. Il faudra vivre avec.',1,true),
('champion_out','automatic','Ça fait mal. Le parcours de {champion} s’arrête ici. Les archives n’oublieront pas.',1,true),
('champion_out','automatic','Ça fait mal. Le choix {champion} ne gagnera pas la coupe. Il faudra vivre avec.',1,true),
('champion_out','automatic','Ça fait mal. Le choix {champion} ne gagnera pas la coupe. Les archives n’oublieront pas.',1,true),
('team_event','automatic','La Team bouge. {team} vient de vivre un nouvel événement. Le Nid suit ça.',1,true),
('team_event','automatic','La Team bouge. {team} vient de vivre un nouvel événement. À surveiller.',1,true),
('team_event','automatic','La Team bouge. Quelque chose change chez {team}. Le Nid suit ça.',1,true),
('team_event','automatic','La Team bouge. Quelque chose change chez {team}. À surveiller.',1,true),
('team_event','automatic','La Team bouge. La Team {team} fait parler d’elle. Le Nid suit ça.',1,true),
('team_event','automatic','La Team bouge. La Team {team} fait parler d’elle. À surveiller.',1,true),
('team_event','automatic','La Team bouge. Un mouvement est enregistré pour {team}. Le Nid suit ça.',1,true),
('team_event','automatic','La Team bouge. Un mouvement est enregistré pour {team}. À surveiller.',1,true),
('team_event','automatic','Ça remue dans le blason. {team} vient de vivre un nouvel événement. Le Nid suit ça.',1,true),
('team_event','automatic','Ça remue dans le blason. {team} vient de vivre un nouvel événement. À surveiller.',1,true),
('team_event','automatic','Ça remue dans le blason. Quelque chose change chez {team}. Le Nid suit ça.',1,true),
('team_event','automatic','Ça remue dans le blason. Quelque chose change chez {team}. À surveiller.',1,true),
('team_event','automatic','Ça remue dans le blason. La Team {team} fait parler d’elle. Le Nid suit ça.',1,true),
('team_event','automatic','Ça remue dans le blason. La Team {team} fait parler d’elle. À surveiller.',1,true),
('team_event','automatic','Ça remue dans le blason. Un mouvement est enregistré pour {team}. Le Nid suit ça.',1,true),
('team_event','automatic','Ça remue dans le blason. Un mouvement est enregistré pour {team}. À surveiller.',1,true),
('team_event','automatic','Nouvel épisode collectif. {team} vient de vivre un nouvel événement. Le Nid suit ça.',1,true),
('team_event','automatic','Nouvel épisode collectif. {team} vient de vivre un nouvel événement. À surveiller.',1,true),
('team_event','automatic','Nouvel épisode collectif. Quelque chose change chez {team}. Le Nid suit ça.',1,true),
('team_event','automatic','Nouvel épisode collectif. Quelque chose change chez {team}. À surveiller.',1,true),
('team_event','automatic','Nouvel épisode collectif. La Team {team} fait parler d’elle. Le Nid suit ça.',1,true),
('team_event','automatic','Nouvel épisode collectif. La Team {team} fait parler d’elle. À surveiller.',1,true),
('team_event','automatic','Nouvel épisode collectif. Un mouvement est enregistré pour {team}. Le Nid suit ça.',1,true),
('team_event','automatic','Nouvel épisode collectif. Un mouvement est enregistré pour {team}. À surveiller.',1,true),
('team_event','automatic','Le vestiaire s’anime. {team} vient de vivre un nouvel événement. Le Nid suit ça.',1,true),
('team_event','automatic','Le vestiaire s’anime. {team} vient de vivre un nouvel événement. À surveiller.',1,true),
('team_event','automatic','Le vestiaire s’anime. Quelque chose change chez {team}. Le Nid suit ça.',1,true),
('team_event','automatic','Le vestiaire s’anime. Quelque chose change chez {team}. À surveiller.',1,true),
('team_event','automatic','Le vestiaire s’anime. La Team {team} fait parler d’elle. Le Nid suit ça.',1,true),
('team_event','automatic','Le vestiaire s’anime. La Team {team} fait parler d’elle. À surveiller.',1,true),
('team_event','automatic','Le vestiaire s’anime. Un mouvement est enregistré pour {team}. Le Nid suit ça.',1,true),
('team_event','automatic','Le vestiaire s’anime. Un mouvement est enregistré pour {team}. À surveiller.',1,true),
('team_event','automatic','Le Hibou regarde la Team. {team} vient de vivre un nouvel événement. Le Nid suit ça.',1,true),
('team_event','automatic','Le Hibou regarde la Team. {team} vient de vivre un nouvel événement. À surveiller.',1,true),
('team_event','automatic','Le Hibou regarde la Team. Quelque chose change chez {team}. Le Nid suit ça.',1,true),
('team_event','automatic','Le Hibou regarde la Team. Quelque chose change chez {team}. À surveiller.',1,true),
('team_event','automatic','Le Hibou regarde la Team. La Team {team} fait parler d’elle. Le Nid suit ça.',1,true),
('team_event','automatic','Le Hibou regarde la Team. La Team {team} fait parler d’elle. À surveiller.',1,true),
('team_event','automatic','Le Hibou regarde la Team. Un mouvement est enregistré pour {team}. Le Nid suit ça.',1,true),
('team_event','automatic','Le Hibou regarde la Team. Un mouvement est enregistré pour {team}. À surveiller.',1,true)
on conflict(event_key,tone,template) do nothing;
-- Déblocages groupés : une seule notification même lorsque plusieurs badges tombent ensemble.
insert into public.gamification_text_templates(event_key,tone,template,weight,active) values
('badge_group','automatic','Le Musée s’agrandit. {count} badges rejoignent ta collection.',1,true),
('badge_group','automatic','Le Musée s’agrandit. {count} nouvelles pièces viennent d’arriver au Musée.',1,true),
('badge_group','automatic','Le Musée s’agrandit. {count} distinctions viennent de tomber d’un coup.',1,true),
('badge_group','automatic','Le Musée s’agrandit. Le bilan est net : {count} nouveaux badges.',1,true),
('badge_group','automatic','Le Musée s’agrandit. Tu repars avec {count} badges supplémentaires.',1,true),
('badge_group','automatic','Le Musée s’agrandit. {count} récompenses viennent de s’allumer.',1,true),
('badge_group','automatic','Le Musée s’agrandit. Le Musée ajoute {count} badges à ton nom.',1,true),
('badge_group','automatic','Le Musée s’agrandit. {count} badges de plus. Le Hibou a vérifié deux fois.',1,true),
('badge_group','automatic','Le Hibou a fouillé les archives. {count} badges rejoignent ta collection.',1,true),
('badge_group','automatic','Le Hibou a fouillé les archives. {count} nouvelles pièces viennent d’arriver au Musée.',1,true),
('badge_group','automatic','Le Hibou a fouillé les archives. {count} distinctions viennent de tomber d’un coup.',1,true),
('badge_group','automatic','Le Hibou a fouillé les archives. Le bilan est net : {count} nouveaux badges.',1,true),
('badge_group','automatic','Le Hibou a fouillé les archives. Tu repars avec {count} badges supplémentaires.',1,true),
('badge_group','automatic','Le Hibou a fouillé les archives. {count} récompenses viennent de s’allumer.',1,true),
('badge_group','automatic','Le Hibou a fouillé les archives. Le Musée ajoute {count} badges à ton nom.',1,true),
('badge_group','automatic','Le Hibou a fouillé les archives. {count} badges de plus. Le Hibou a vérifié deux fois.',1,true),
('badge_group','automatic','Ça tombe en grappe. {count} badges rejoignent ta collection.',1,true),
('badge_group','automatic','Ça tombe en grappe. {count} nouvelles pièces viennent d’arriver au Musée.',1,true),
('badge_group','automatic','Ça tombe en grappe. {count} distinctions viennent de tomber d’un coup.',1,true),
('badge_group','automatic','Ça tombe en grappe. Le bilan est net : {count} nouveaux badges.',1,true),
('badge_group','automatic','Ça tombe en grappe. Tu repars avec {count} badges supplémentaires.',1,true),
('badge_group','automatic','Ça tombe en grappe. {count} récompenses viennent de s’allumer.',1,true),
('badge_group','automatic','Ça tombe en grappe. Le Musée ajoute {count} badges à ton nom.',1,true),
('badge_group','automatic','Ça tombe en grappe. {count} badges de plus. Le Hibou a vérifié deux fois.',1,true),
('badge_group','automatic','La vitrine vient de bouger. {count} badges rejoignent ta collection.',1,true),
('badge_group','automatic','La vitrine vient de bouger. {count} nouvelles pièces viennent d’arriver au Musée.',1,true),
('badge_group','automatic','La vitrine vient de bouger. {count} distinctions viennent de tomber d’un coup.',1,true),
('badge_group','automatic','La vitrine vient de bouger. Le bilan est net : {count} nouveaux badges.',1,true),
('badge_group','automatic','La vitrine vient de bouger. Tu repars avec {count} badges supplémentaires.',1,true),
('badge_group','automatic','La vitrine vient de bouger. {count} récompenses viennent de s’allumer.',1,true),
('badge_group','automatic','La vitrine vient de bouger. Le Musée ajoute {count} badges à ton nom.',1,true),
('badge_group','automatic','La vitrine vient de bouger. {count} badges de plus. Le Hibou a vérifié deux fois.',1,true),
('badge_group','automatic','Le Nid recompte les plumes. {count} badges rejoignent ta collection.',1,true),
('badge_group','automatic','Le Nid recompte les plumes. {count} nouvelles pièces viennent d’arriver au Musée.',1,true),
('badge_group','automatic','Le Nid recompte les plumes. {count} distinctions viennent de tomber d’un coup.',1,true),
('badge_group','automatic','Le Nid recompte les plumes. Le bilan est net : {count} nouveaux badges.',1,true),
('badge_group','automatic','Le Nid recompte les plumes. Tu repars avec {count} badges supplémentaires.',1,true),
('badge_group','automatic','Le Nid recompte les plumes. {count} récompenses viennent de s’allumer.',1,true),
('badge_group','automatic','Le Nid recompte les plumes. Le Musée ajoute {count} badges à ton nom.',1,true),
('badge_group','automatic','Le Nid recompte les plumes. {count} badges de plus. Le Hibou a vérifié deux fois.',1,true)
on conflict(event_key,tone,template) do nothing;

commit;
