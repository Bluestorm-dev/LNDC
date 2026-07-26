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
