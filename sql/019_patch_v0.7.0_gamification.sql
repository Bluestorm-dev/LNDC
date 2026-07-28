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
