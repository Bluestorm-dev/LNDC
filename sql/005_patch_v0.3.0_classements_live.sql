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
