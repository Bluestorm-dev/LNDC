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
