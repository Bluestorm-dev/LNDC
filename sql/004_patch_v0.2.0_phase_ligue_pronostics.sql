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
