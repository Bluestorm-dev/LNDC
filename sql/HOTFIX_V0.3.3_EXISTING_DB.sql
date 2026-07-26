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
