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

-- Phase + journée + 4 matchs fictifs à J+7.
do $$
declare
  v_season uuid;
  v_phase uuid;
  v_md uuid;
  psg uuid; bay uuid; rma uuid; ars uuid; inter_id uuid; bar uuid; liv uuid; bvb uuid;
begin
  select id into v_season from public.seasons where slug='ucl-2026-27';
  insert into public.competition_phases(season_id,code,name,sort_order,default_multiplier)
  values(v_season,'LEAGUE','Phase de ligue',10,1)
  on conflict(season_id,code) do update set name=excluded.name
  returning id into v_phase;

  insert into public.matchdays(season_id,phase_id,number,name,starts_at,ends_at)
  values(v_season,v_phase,0,'Journée TEST',now()+interval '7 days',now()+interval '8 days')
  on conflict(season_id,number) do update set name=excluded.name
  returning id into v_md;

  select id into psg from public.clubs where name='Paris SG';
  select id into bay from public.clubs where name='Bayern Munich';
  select id into rma from public.clubs where name='Real Madrid';
  select id into ars from public.clubs where name='Arsenal';
  select id into inter_id from public.clubs where name='Inter Milan';
  select id into bar from public.clubs where name='FC Barcelone';
  select id into liv from public.clubs where name='Liverpool';
  select id into bvb from public.clubs where name='Dortmund';

  if not exists(select 1 from public.matches where matchday_id=v_md) then
    insert into public.matches(season_id,phase_id,matchday_id,home_club_id,away_club_id,kickoff_at,stadium) values
    (v_season,v_phase,v_md,psg,bay,now()+interval '7 days','Stade test Paris'),
    (v_season,v_phase,v_md,rma,ars,now()+interval '7 days 10 minutes','Stade test Madrid'),
    (v_season,v_phase,v_md,inter_id,bar,now()+interval '7 days 30 minutes','Stade test Milan'),
    (v_season,v_phase,v_md,liv,bvb,now()+interval '7 days 40 minutes','Stade test Liverpool');
  end if;
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
