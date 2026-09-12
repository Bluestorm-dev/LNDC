-- ============================================================
-- Le Nid des Champions V1.0.2e
-- Réparation des clubs des buteurs / cartons après dédoublonnage
--
-- Ce correctif :
--   1) remappe les références vers d'anciens clubs inactifs ;
--   2) recoupe les deux tables de statistiques ;
--   3) réapplique le mapping J1 déjà utilisé par le patch données ;
--   4) ne recrée aucun doublon joueur.
-- ============================================================

begin;

create or replace function public.lndc_club_key_v102e(p_text text)
returns text
language sql
immutable
as $$
  select trim(
    regexp_replace(
      regexp_replace(lower(coalesce(p_text,'')), '[’''`´._/-]+', ' ', 'g'),
      '\s+', ' ', 'g'
    )
  );
$$;

-- ------------------------------------------------------------
-- 1. Toute statistique pointant vers un ancien club inactif
--    est déplacée vers son équivalent actif lorsqu'il existe.
-- ------------------------------------------------------------

with inactive_to_active as (
  select old.id as old_id, replacement.id as new_id
  from public.clubs old
  join lateral (
    select c.id
    from public.clubs c
    where c.id <> old.id
      and coalesce(c.is_active,true)=true
      and (
        (
          old.external_provider is not null
          and old.external_id is not null
          and c.external_provider=old.external_provider
          and c.external_id=old.external_id
        )
        or exists (
          select 1
          from unnest(array[old.name,old.short_name,old.tla]) old_name
          cross join unnest(array[c.name,c.short_name,c.tla]) new_name
          where nullif(public.lndc_club_key_v102e(old_name),'') is not null
            and public.lndc_club_key_v102e(old_name)=public.lndc_club_key_v102e(new_name)
        )
      )
    order by
      case when old.external_provider is not null
             and old.external_id is not null
             and c.external_provider=old.external_provider
             and c.external_id=old.external_id
           then 0 else 1 end,
      c.provider_metadata_updated_at desc nulls last,
      c.updated_at desc nulls last
    limit 1
  ) replacement on true
  where coalesce(old.is_active,true)=false
)
update public.ucl_player_stats s
set club_id=m.new_id, updated_at=now()
from inactive_to_active m
where s.club_id=m.old_id
  and s.club_id is distinct from m.new_id;

with inactive_to_active as (
  select old.id as old_id, replacement.id as new_id
  from public.clubs old
  join lateral (
    select c.id
    from public.clubs c
    where c.id <> old.id
      and coalesce(c.is_active,true)=true
      and (
        (
          old.external_provider is not null
          and old.external_id is not null
          and c.external_provider=old.external_provider
          and c.external_id=old.external_id
        )
        or exists (
          select 1
          from unnest(array[old.name,old.short_name,old.tla]) old_name
          cross join unnest(array[c.name,c.short_name,c.tla]) new_name
          where nullif(public.lndc_club_key_v102e(old_name),'') is not null
            and public.lndc_club_key_v102e(old_name)=public.lndc_club_key_v102e(new_name)
        )
      )
    order by
      case when old.external_provider is not null
             and old.external_id is not null
             and c.external_provider=old.external_provider
             and c.external_id=old.external_id
           then 0 else 1 end,
      c.provider_metadata_updated_at desc nulls last,
      c.updated_at desc nulls last
    limit 1
  ) replacement on true
  where coalesce(old.is_active,true)=false
)
update public.ucl_discipline_stats s
set club_id=m.new_id, updated_at=now()
from inactive_to_active m
where s.club_id=m.old_id
  and s.club_id is distinct from m.new_id;

-- ------------------------------------------------------------
-- 2. Recoupement buteurs <-> discipline.
--    On ne reprend qu'un club ACTIF.
-- ------------------------------------------------------------

with active_card_clubs as (
  select d.season_id,
         public.lndc_player_key_v102d(d.player_name) as player_key,
         (array_agg(d.club_id order by (d.player_external_id>0) desc,d.updated_at desc nulls last)
           filter (where c.id is not null))[1] as club_id
  from public.ucl_discipline_stats d
  left join public.clubs c on c.id=d.club_id and coalesce(c.is_active,true)=true
  group by d.season_id,public.lndc_player_key_v102d(d.player_name)
)
update public.ucl_player_stats s
set club_id=m.club_id,updated_at=now()
from active_card_clubs m
where s.season_id=m.season_id
  and public.lndc_player_key_v102d(s.player_name)=m.player_key
  and m.club_id is not null
  and not exists (
    select 1 from public.clubs current_club
    where current_club.id=s.club_id
      and coalesce(current_club.is_active,true)=true
  );

with active_scorer_clubs as (
  select s.season_id,
         public.lndc_player_key_v102d(s.player_name) as player_key,
         (array_agg(s.club_id order by (s.player_external_id>0) desc,s.updated_at desc nulls last)
           filter (where c.id is not null))[1] as club_id
  from public.ucl_player_stats s
  left join public.clubs c on c.id=s.club_id and coalesce(c.is_active,true)=true
  group by s.season_id,public.lndc_player_key_v102d(s.player_name)
)
update public.ucl_discipline_stats d
set club_id=m.club_id,updated_at=now()
from active_scorer_clubs m
where d.season_id=m.season_id
  and public.lndc_player_key_v102d(d.player_name)=m.player_key
  and m.club_id is not null
  and not exists (
    select 1 from public.clubs current_club
    where current_club.id=d.club_id
      and coalesce(current_club.is_active,true)=true
  );

-- ------------------------------------------------------------
-- 3. Mapping de secours de la Journée 1.
--    Ce sont exactement les associations joueur -> club utilisées
--    par le patch J1 déjà installé.
-- ------------------------------------------------------------

with active_season as (
  select id
  from public.seasons
  where coalesce(is_active,false)=true
  order by created_at desc nulls last
  limit 1
),
club_aliases(club_key,alias) as (
  values
    ('aek', 'AEK Athens'),
    ('aek', 'AEK Athènes'),
    ('aek', 'AEK'),
    ('lask', 'LASK'),
    ('lask', 'LASK Linz'),
    ('lask', 'Linz ASK'),
    ('brugge', 'Club Brugge'),
    ('brugge', 'Club Brugge KV'),
    ('brugge', 'Club Bruges'),
    ('villa', 'Aston Villa'),
    ('villa', 'Aston Villa FC'),
    ('dortmund', 'Borussia Dortmund'),
    ('dortmund', 'B. Dortmund'),
    ('dortmund', 'Dortmund'),
    ('villarreal', 'Villarreal'),
    ('villarreal', 'Villarreal CF'),
    ('porto', 'FC Porto'),
    ('porto', 'Porto'),
    ('mancity', 'Manchester City'),
    ('mancity', 'Man City'),
    ('mancity', 'Manchester City FC'),
    ('lille', 'Lille'),
    ('lille', 'LOSC'),
    ('lille', 'LOSC Lille'),
    ('betis', 'Real Betis'),
    ('betis', 'Real Betis Balompié'),
    ('betis', 'Betis Séville'),
    ('betis', 'Betis'),
    ('real', 'Real Madrid'),
    ('real', 'Real Madrid CF'),
    ('inter', 'Inter'),
    ('inter', 'Inter Milan'),
    ('inter', 'Internazionale'),
    ('inter', 'FC Internazionale Milano'),
    ('barca', 'FC Barcelona'),
    ('barca', 'Barcelona'),
    ('barca', 'FC Barcelone'),
    ('feyenoord', 'Feyenoord'),
    ('feyenoord', 'Feyenoord Rotterdam'),
    ('stuttgart', 'VfB Stuttgart'),
    ('stuttgart', 'Stuttgart'),
    ('viking', 'Viking'),
    ('viking', 'Viking FK'),
    ('viking', 'Viking Stavanger'),
    ('liverpool', 'Liverpool'),
    ('liverpool', 'Liverpool FC'),
    ('atleti', 'Atlético de Madrid'),
    ('atleti', 'Atletico Madrid'),
    ('atleti', 'Atlético Madrid'),
    ('atleti', 'Atleti'),
    ('psg', 'Paris Saint-Germain'),
    ('psg', 'Paris Saint-Germain FC'),
    ('psg', 'Paris-SG'),
    ('psg', 'PSG'),
    ('psg', 'Paris'),
    ('slovan', 'Slovan Bratislava'),
    ('slovan', 'ŠK Slovan Bratislava'),
    ('slovan', 'S. Bratislava'),
    ('sporting', 'Sporting CP'),
    ('sporting', 'Sporting Portugal'),
    ('sporting', 'Sporting Clube de Portugal'),
    ('sporting', 'Sporting'),
    ('gala', 'Galatasaray'),
    ('gala', 'Galatasaray SK'),
    ('napoli', 'Napoli'),
    ('napoli', 'SSC Napoli'),
    ('napoli', 'Naples'),
    ('arsenal', 'Arsenal'),
    ('arsenal', 'Arsenal FC'),
    ('fener', 'Fenerbahçe'),
    ('fener', 'Fenerbahce'),
    ('fener', 'Fenerbahçe SK'),
    ('roma', 'Roma'),
    ('roma', 'AS Roma'),
    ('roma', 'AS Rome'),
    ('psv', 'PSV'),
    ('psv', 'PSV Eindhoven'),
    ('shakhtar', 'Shakhtar Donetsk'),
    ('shakhtar', 'Chakhtar Donetsk'),
    ('shakhtar', 'Shakhtar'),
    ('como', 'Como'),
    ('como', 'Como 1907'),
    ('como', 'Côme'),
    ('leipzig', 'RB Leipzig'),
    ('leipzig', 'Leipzig'),
    ('bayern', 'Bayern München'),
    ('bayern', 'Bayern Munich'),
    ('bayern', 'FC Bayern München'),
    ('bayern', 'Bayern'),
    ('bodo', 'Bodø/Glimt'),
    ('bodo', 'Bodo/Glimt'),
    ('bodo', 'Bodö/Glimt'),
    ('manutd', 'Manchester United'),
    ('manutd', 'Man United'),
    ('manutd', 'Manchester United FC'),
    ('sabah', 'Sabah'),
    ('sabah', 'Sabah FC'),
    ('sabah', 'Sabah FK'),
    ('slavia', 'Slavia Praha'),
    ('slavia', 'Slavia Prague'),
    ('slavia', 'SK Slavia Praha'),
    ('lens', 'RC Lens'),
    ('lens', 'Lens'),
    ('lens', 'Racing Club de Lens')
),
resolved_clubs as (
  select distinct on (a.club_key)
         a.club_key,c.id as club_id
  from club_aliases a
  join public.clubs c
    on coalesce(c.is_active,true)=true
   and (
     public.lndc_club_key_v102e(c.name)=public.lndc_club_key_v102e(a.alias)
     or public.lndc_club_key_v102e(c.short_name)=public.lndc_club_key_v102e(a.alias)
     or public.lndc_club_key_v102e(c.tla)=public.lndc_club_key_v102e(a.alias)
   )
  order by a.club_key,
           case
             when public.lndc_club_key_v102e(c.name)=public.lndc_club_key_v102e(a.alias) then 0
             when public.lndc_club_key_v102e(c.short_name)=public.lndc_club_key_v102e(a.alias) then 1
             else 2
           end,
           c.provider_metadata_updated_at desc nulls last,
           c.updated_at desc nulls last
),
player_map(player_name,club_key) as (
  values
    ('Răzvan Marin', 'aek'),
    ('Luka Jović', 'aek'),
    ('Melayro Bogarde', 'lask'),
    ('John McGinn', 'villa'),
    ('Emiliano Buendía', 'villa'),
    ('Nicolas Jackson', 'villa'),
    ('Hugo Vetlesen', 'brugge'),
    ('Nicolò Tresoldi', 'brugge'),
    ('Ian Maatsen', 'villa'),
    ('João Gomes', 'villa'),
    ('Hans Vanaken', 'brugge'),
    ('Jan Virgili', 'brugge'),
    ('Romeo Vermant', 'brugge'),
    ('Santiago Mouriño', 'villarreal'),
    ('Serhou Guirassy', 'dortmund'),
    ('Waldemar Anton', 'dortmund'),
    ('Pau Navarro', 'villarreal'),
    ('Sergi Cardona', 'villarreal'),
    ('Erling Haaland', 'mancity'),
    ('Pablo Rosario', 'porto'),
    ('Joško Gvardiol', 'mancity'),
    ('Gianluigi Donnarumma', 'mancity'),
    ('Ayase Ueda', 'lille'),
    ('Alexsandro', 'lille'),
    ('Marc Bartra', 'betis'),
    ('Troy Parrott', 'betis'),
    ('Ethan Mbappé', 'lille'),
    ('Olivier Giroud', 'lille'),
    ('Natan', 'betis'),
    ('Fermín López Bernal', 'betis'),
    ('Marc Roca', 'betis'),
    ('Kylian Mbappé', 'real'),
    ('Federico Valverde', 'real'),
    ('Carlos Augusto', 'inter'),
    ('Dean Huijsen', 'real'),
    ('Hakan Çalhanoğlu', 'inter'),
    ('Lautaro Martínez', 'inter'),
    ('Yann Bisseck', 'inter'),
    ('Raphinha', 'barca'),
    ('Karim Adeyemi', 'barca'),
    ('Lamine Yamal', 'barca'),
    ('Gabriel Jesus', 'barca'),
    ('Sem Steijn', 'feyenoord'),
    ('Dani Olmo', 'barca'),
    ('Casper Vanhoutte', 'feyenoord'),
    ('Ermedin Demirović', 'stuttgart'),
    ('Zlatko Tripić', 'viking'),
    ('Kristoffer Askildsen', 'viking'),
    ('Peter Christiansen', 'viking'),
    ('Joe Bell', 'viking'),
    ('Marcos Llorente', 'atleti'),
    ('Dominik Szoboszlai', 'liverpool'),
    ('Alexis Mac Allister', 'liverpool'),
    ('Marc Pubill', 'atleti'),
    ('Ousmane Dembélé', 'psg'),
    ('Ferran Torres', 'psg'),
    ('Fabián Ruiz', 'psg'),
    ('Suleiman Camara', 'slovan'),
    ('César Blackman', 'slovan'),
    ('Geny Catamo', 'sporting'),
    ('Luis Suárez', 'sporting'),
    ('Rodrigo Zalazar', 'sporting'),
    ('Sergi Altimira', 'sporting'),
    ('Eren Elmalı', 'gala'),
    ('Deniz Gül', 'gala'),
    ('Ismail Jakobs', 'gala'),
    ('Martin Ødegaard', 'arsenal'),
    ('Billy Gilmour', 'napoli'),
    ('Lorenzo Lucca', 'napoli'),
    ('Archie Brown', 'fener'),
    ('Bryan Cristante', 'roma'),
    ('Kerem Aktürkoğlu', 'fener'),
    ('Mert Müldür', 'fener'),
    ('İsmail Yüksek', 'fener'),
    ('Devyne Rensch', 'roma'),
    ('Sergiño Dest', 'psv'),
    ('Gleiker Mendoza', 'shakhtar'),
    ('Armando Obispo', 'psv'),
    ('Ruben van Bommel', 'psv'),
    ('Vinícius Tobias', 'shakhtar'),
    ('Pedro Henrique', 'shakhtar'),
    ('Valeriy Bondar', 'shakhtar'),
    ('Dmytro Kryskiv', 'shakhtar'),
    ('Marlon Gomes', 'shakhtar'),
    ('Martin Baturina', 'como'),
    ('Anastasios Douvikas', 'como'),
    ('Assane Diao', 'como'),
    ('Máximo Perrone', 'como'),
    ('Andrija Maksimović', 'leipzig'),
    ('Nico Paz', 'como'),
    ('Willi Orbán', 'leipzig'),
    ('Christopher Nkunku', 'leipzig'),
    ('Ezechiel Banzuzi', 'leipzig'),
    ('Jamal Musiala', 'bayern'),
    ('Harry Kane', 'bayern'),
    ('Alphonso Davies', 'bayern'),
    ('Michael Olise', 'bayern'),
    ('Sondre Fet', 'bodo'),
    ('Odin Bjørtuft', 'bodo'),
    ('Matheus Cunha', 'manutd'),
    ('Bruno Fernandes', 'manutd'),
    ('Benjamin Šeško', 'manutd'),
    ('Lisandro Martínez', 'manutd'),
    ('Patrick Dorgu', 'manutd'),
    ('Ivan Lepinjica', 'sabah'),
    ('Danijel Šturm', 'slavia'),
    ('Abdallah Sima', 'lens'),
    ('Florian Thauvin', 'lens'),
    ('Ruben Aguilar', 'lens'),
    ('Mikuláš Konečný', 'slavia'),
    ('Ibrahima Ganiou', 'lens')
),
resolved_players as (
  select p.player_name,r.club_id,(select id from active_season) as season_id
  from player_map p
  join resolved_clubs r using(club_key)
)
update public.ucl_player_stats s
set club_id=r.club_id,updated_at=now()
from resolved_players r
where s.season_id=r.season_id
  and public.lndc_player_key_v102d(s.player_name)=public.lndc_player_key_v102d(r.player_name)
  and s.club_id is distinct from r.club_id;

with active_season as (
  select id
  from public.seasons
  where coalesce(is_active,false)=true
  order by created_at desc nulls last
  limit 1
),
club_aliases(club_key,alias) as (
  values
    ('aek', 'AEK Athens'),
    ('aek', 'AEK Athènes'),
    ('aek', 'AEK'),
    ('lask', 'LASK'),
    ('lask', 'LASK Linz'),
    ('lask', 'Linz ASK'),
    ('brugge', 'Club Brugge'),
    ('brugge', 'Club Brugge KV'),
    ('brugge', 'Club Bruges'),
    ('villa', 'Aston Villa'),
    ('villa', 'Aston Villa FC'),
    ('dortmund', 'Borussia Dortmund'),
    ('dortmund', 'B. Dortmund'),
    ('dortmund', 'Dortmund'),
    ('villarreal', 'Villarreal'),
    ('villarreal', 'Villarreal CF'),
    ('porto', 'FC Porto'),
    ('porto', 'Porto'),
    ('mancity', 'Manchester City'),
    ('mancity', 'Man City'),
    ('mancity', 'Manchester City FC'),
    ('lille', 'Lille'),
    ('lille', 'LOSC'),
    ('lille', 'LOSC Lille'),
    ('betis', 'Real Betis'),
    ('betis', 'Real Betis Balompié'),
    ('betis', 'Betis Séville'),
    ('betis', 'Betis'),
    ('real', 'Real Madrid'),
    ('real', 'Real Madrid CF'),
    ('inter', 'Inter'),
    ('inter', 'Inter Milan'),
    ('inter', 'Internazionale'),
    ('inter', 'FC Internazionale Milano'),
    ('barca', 'FC Barcelona'),
    ('barca', 'Barcelona'),
    ('barca', 'FC Barcelone'),
    ('feyenoord', 'Feyenoord'),
    ('feyenoord', 'Feyenoord Rotterdam'),
    ('stuttgart', 'VfB Stuttgart'),
    ('stuttgart', 'Stuttgart'),
    ('viking', 'Viking'),
    ('viking', 'Viking FK'),
    ('viking', 'Viking Stavanger'),
    ('liverpool', 'Liverpool'),
    ('liverpool', 'Liverpool FC'),
    ('atleti', 'Atlético de Madrid'),
    ('atleti', 'Atletico Madrid'),
    ('atleti', 'Atlético Madrid'),
    ('atleti', 'Atleti'),
    ('psg', 'Paris Saint-Germain'),
    ('psg', 'Paris Saint-Germain FC'),
    ('psg', 'Paris-SG'),
    ('psg', 'PSG'),
    ('psg', 'Paris'),
    ('slovan', 'Slovan Bratislava'),
    ('slovan', 'ŠK Slovan Bratislava'),
    ('slovan', 'S. Bratislava'),
    ('sporting', 'Sporting CP'),
    ('sporting', 'Sporting Portugal'),
    ('sporting', 'Sporting Clube de Portugal'),
    ('sporting', 'Sporting'),
    ('gala', 'Galatasaray'),
    ('gala', 'Galatasaray SK'),
    ('napoli', 'Napoli'),
    ('napoli', 'SSC Napoli'),
    ('napoli', 'Naples'),
    ('arsenal', 'Arsenal'),
    ('arsenal', 'Arsenal FC'),
    ('fener', 'Fenerbahçe'),
    ('fener', 'Fenerbahce'),
    ('fener', 'Fenerbahçe SK'),
    ('roma', 'Roma'),
    ('roma', 'AS Roma'),
    ('roma', 'AS Rome'),
    ('psv', 'PSV'),
    ('psv', 'PSV Eindhoven'),
    ('shakhtar', 'Shakhtar Donetsk'),
    ('shakhtar', 'Chakhtar Donetsk'),
    ('shakhtar', 'Shakhtar'),
    ('como', 'Como'),
    ('como', 'Como 1907'),
    ('como', 'Côme'),
    ('leipzig', 'RB Leipzig'),
    ('leipzig', 'Leipzig'),
    ('bayern', 'Bayern München'),
    ('bayern', 'Bayern Munich'),
    ('bayern', 'FC Bayern München'),
    ('bayern', 'Bayern'),
    ('bodo', 'Bodø/Glimt'),
    ('bodo', 'Bodo/Glimt'),
    ('bodo', 'Bodö/Glimt'),
    ('manutd', 'Manchester United'),
    ('manutd', 'Man United'),
    ('manutd', 'Manchester United FC'),
    ('sabah', 'Sabah'),
    ('sabah', 'Sabah FC'),
    ('sabah', 'Sabah FK'),
    ('slavia', 'Slavia Praha'),
    ('slavia', 'Slavia Prague'),
    ('slavia', 'SK Slavia Praha'),
    ('lens', 'RC Lens'),
    ('lens', 'Lens'),
    ('lens', 'Racing Club de Lens')
),
resolved_clubs as (
  select distinct on (a.club_key)
         a.club_key,c.id as club_id
  from club_aliases a
  join public.clubs c
    on coalesce(c.is_active,true)=true
   and (
     public.lndc_club_key_v102e(c.name)=public.lndc_club_key_v102e(a.alias)
     or public.lndc_club_key_v102e(c.short_name)=public.lndc_club_key_v102e(a.alias)
     or public.lndc_club_key_v102e(c.tla)=public.lndc_club_key_v102e(a.alias)
   )
  order by a.club_key,
           case
             when public.lndc_club_key_v102e(c.name)=public.lndc_club_key_v102e(a.alias) then 0
             when public.lndc_club_key_v102e(c.short_name)=public.lndc_club_key_v102e(a.alias) then 1
             else 2
           end,
           c.provider_metadata_updated_at desc nulls last,
           c.updated_at desc nulls last
),
player_map(player_name,club_key) as (
  values
    ('Răzvan Marin', 'aek'),
    ('Luka Jović', 'aek'),
    ('Melayro Bogarde', 'lask'),
    ('John McGinn', 'villa'),
    ('Emiliano Buendía', 'villa'),
    ('Nicolas Jackson', 'villa'),
    ('Hugo Vetlesen', 'brugge'),
    ('Nicolò Tresoldi', 'brugge'),
    ('Ian Maatsen', 'villa'),
    ('João Gomes', 'villa'),
    ('Hans Vanaken', 'brugge'),
    ('Jan Virgili', 'brugge'),
    ('Romeo Vermant', 'brugge'),
    ('Santiago Mouriño', 'villarreal'),
    ('Serhou Guirassy', 'dortmund'),
    ('Waldemar Anton', 'dortmund'),
    ('Pau Navarro', 'villarreal'),
    ('Sergi Cardona', 'villarreal'),
    ('Erling Haaland', 'mancity'),
    ('Pablo Rosario', 'porto'),
    ('Joško Gvardiol', 'mancity'),
    ('Gianluigi Donnarumma', 'mancity'),
    ('Ayase Ueda', 'lille'),
    ('Alexsandro', 'lille'),
    ('Marc Bartra', 'betis'),
    ('Troy Parrott', 'betis'),
    ('Ethan Mbappé', 'lille'),
    ('Olivier Giroud', 'lille'),
    ('Natan', 'betis'),
    ('Fermín López Bernal', 'betis'),
    ('Marc Roca', 'betis'),
    ('Kylian Mbappé', 'real'),
    ('Federico Valverde', 'real'),
    ('Carlos Augusto', 'inter'),
    ('Dean Huijsen', 'real'),
    ('Hakan Çalhanoğlu', 'inter'),
    ('Lautaro Martínez', 'inter'),
    ('Yann Bisseck', 'inter'),
    ('Raphinha', 'barca'),
    ('Karim Adeyemi', 'barca'),
    ('Lamine Yamal', 'barca'),
    ('Gabriel Jesus', 'barca'),
    ('Sem Steijn', 'feyenoord'),
    ('Dani Olmo', 'barca'),
    ('Casper Vanhoutte', 'feyenoord'),
    ('Ermedin Demirović', 'stuttgart'),
    ('Zlatko Tripić', 'viking'),
    ('Kristoffer Askildsen', 'viking'),
    ('Peter Christiansen', 'viking'),
    ('Joe Bell', 'viking'),
    ('Marcos Llorente', 'atleti'),
    ('Dominik Szoboszlai', 'liverpool'),
    ('Alexis Mac Allister', 'liverpool'),
    ('Marc Pubill', 'atleti'),
    ('Ousmane Dembélé', 'psg'),
    ('Ferran Torres', 'psg'),
    ('Fabián Ruiz', 'psg'),
    ('Suleiman Camara', 'slovan'),
    ('César Blackman', 'slovan'),
    ('Geny Catamo', 'sporting'),
    ('Luis Suárez', 'sporting'),
    ('Rodrigo Zalazar', 'sporting'),
    ('Sergi Altimira', 'sporting'),
    ('Eren Elmalı', 'gala'),
    ('Deniz Gül', 'gala'),
    ('Ismail Jakobs', 'gala'),
    ('Martin Ødegaard', 'arsenal'),
    ('Billy Gilmour', 'napoli'),
    ('Lorenzo Lucca', 'napoli'),
    ('Archie Brown', 'fener'),
    ('Bryan Cristante', 'roma'),
    ('Kerem Aktürkoğlu', 'fener'),
    ('Mert Müldür', 'fener'),
    ('İsmail Yüksek', 'fener'),
    ('Devyne Rensch', 'roma'),
    ('Sergiño Dest', 'psv'),
    ('Gleiker Mendoza', 'shakhtar'),
    ('Armando Obispo', 'psv'),
    ('Ruben van Bommel', 'psv'),
    ('Vinícius Tobias', 'shakhtar'),
    ('Pedro Henrique', 'shakhtar'),
    ('Valeriy Bondar', 'shakhtar'),
    ('Dmytro Kryskiv', 'shakhtar'),
    ('Marlon Gomes', 'shakhtar'),
    ('Martin Baturina', 'como'),
    ('Anastasios Douvikas', 'como'),
    ('Assane Diao', 'como'),
    ('Máximo Perrone', 'como'),
    ('Andrija Maksimović', 'leipzig'),
    ('Nico Paz', 'como'),
    ('Willi Orbán', 'leipzig'),
    ('Christopher Nkunku', 'leipzig'),
    ('Ezechiel Banzuzi', 'leipzig'),
    ('Jamal Musiala', 'bayern'),
    ('Harry Kane', 'bayern'),
    ('Alphonso Davies', 'bayern'),
    ('Michael Olise', 'bayern'),
    ('Sondre Fet', 'bodo'),
    ('Odin Bjørtuft', 'bodo'),
    ('Matheus Cunha', 'manutd'),
    ('Bruno Fernandes', 'manutd'),
    ('Benjamin Šeško', 'manutd'),
    ('Lisandro Martínez', 'manutd'),
    ('Patrick Dorgu', 'manutd'),
    ('Ivan Lepinjica', 'sabah'),
    ('Danijel Šturm', 'slavia'),
    ('Abdallah Sima', 'lens'),
    ('Florian Thauvin', 'lens'),
    ('Ruben Aguilar', 'lens'),
    ('Mikuláš Konečný', 'slavia'),
    ('Ibrahima Ganiou', 'lens')
),
resolved_players as (
  select p.player_name,r.club_id,(select id from active_season) as season_id
  from player_map p
  join resolved_clubs r using(club_key)
)
update public.ucl_discipline_stats d
set club_id=r.club_id,updated_at=now()
from resolved_players r
where d.season_id=r.season_id
  and public.lndc_player_key_v102d(d.player_name)=public.lndc_player_key_v102d(r.player_name)
  and d.club_id is distinct from r.club_id;

insert into public.app_settings(key,value,updated_at)
values('app_version','"1.0.2e"'::jsonb,now())
on conflict(key) do update
set value=excluded.value,updated_at=now();

commit;

-- ============================================================
-- CONTRÔLES
-- Les 4 valeurs doivent idéalement être à 0.
-- ============================================================

with active_season as (
  select id from public.seasons
  where coalesce(is_active,false)=true
  order by created_at desc nulls last limit 1
)
select 'buteurs_sans_club_actif' as controle,count(*)::text as valeur
from public.ucl_player_stats s
left join public.clubs c on c.id=s.club_id and coalesce(c.is_active,true)=true
where s.season_id=(select id from active_season) and c.id is null
union all
select 'cartons_sans_club_actif',count(*)::text
from public.ucl_discipline_stats d
left join public.clubs c on c.id=d.club_id and coalesce(c.is_active,true)=true
where d.season_id=(select id from active_season) and c.id is null
union all
select 'doublons_buteurs',count(*)::text
from (
  select public.lndc_player_key_v102d(player_name)
  from public.ucl_player_stats
  where season_id=(select id from active_season)
  group by public.lndc_player_key_v102d(player_name)
  having count(*)>1
) x
union all
select 'doublons_cartons',count(*)::text
from (
  select public.lndc_player_key_v102d(player_name)
  from public.ucl_discipline_stats
  where season_id=(select id from active_season)
  group by public.lndc_player_key_v102d(player_name)
  having count(*)>1
) x;

-- Liste seulement les éventuels cas encore non résolus.
with active_season as (
  select id from public.seasons
  where coalesce(is_active,false)=true
  order by created_at desc nulls last limit 1
)
select 'buteur' as type,s.player_name,s.club_id
from public.ucl_player_stats s
left join public.clubs c on c.id=s.club_id and coalesce(c.is_active,true)=true
where s.season_id=(select id from active_season) and c.id is null
union all
select 'carton',d.player_name,d.club_id
from public.ucl_discipline_stats d
left join public.clubs c on c.id=d.club_id and coalesce(c.is_active,true)=true
where d.season_id=(select id from active_season) and c.id is null
order by 1,2;
