-- Le Nid des Champions — V0.7.1
-- Correctif blason front + classement LIVE TEST / Realtime.
begin;

-- Une identité complète rend les changements UPDATE fiables dans Realtime.
alter table public.matches replica identity full;
alter table public.predictions replica identity full;

create or replace function public.get_test_leaderboard_v071(p_season_id uuid,p_include_live boolean default true)
returns table(rank bigint,previous_rank bigint,variation bigint,user_id uuid,username text,avatar_key text,club_heart text,points numeric,official_points numeric,exact_scores bigint,good_differences bigint,good_results bigint,played bigint,average numeric,precision_pct numeric,above_gap numeric,below_gap numeric)
language sql stable security definer set search_path=public as $$
with scored_matches as (
  select m.*
  from public.matches m
  where m.season_id=p_season_id
    and coalesce(m.is_test,false)=true
    and coalesce(m.test_enabled,true)=true
    and (m.status='finished' or (p_include_live and m.status='live'))
    and m.home_score is not null and m.away_score is not null
), stats as (
  select pr.id user_id,pr.username::text username,pr.avatar_key,pr.club_heart,
    coalesce(sum(case
      when p.id is null then 0
      when m.status='finished' then public.score_prediction_values_v030(p_season_id,p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier)
      else public.score_prediction_values_v030(p_season_id,p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier) end),0)::numeric points,
    coalesce(sum(case when p.id is not null and m.status='finished' then public.score_prediction_values_v030(p_season_id,p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier) else 0 end),0)::numeric official_points,
    count(*) filter(where p.id is not null and p.home_score=m.home_score and p.away_score=m.away_score) exact_scores,
    count(*) filter(where p.id is not null and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score) and (p.home_score-p.away_score)=(m.home_score-m.away_score)) good_differences,
    count(*) filter(where p.id is not null and sign(p.home_score-p.away_score)=sign(m.home_score-m.away_score)) good_results,
    count(*) filter(where p.id is not null) played
  from public.profiles pr
  cross join scored_matches m
  left join public.predictions p on p.match_id=m.id and p.user_id=pr.id and p.season_id=p_season_id
  where pr.status='active'
  group by pr.id,pr.username,pr.avatar_key,pr.club_heart
), ranked as (
  select *,
    case when played>0 then round(points/played,2) else 0 end average,
    case when played>0 then round(100.0*good_results/played,1) else 0 end precision_pct,
    rank() over(order by points desc,exact_scores desc,good_differences desc,played desc,username) rank
  from stats
)
select rank,null::bigint previous_rank,0::bigint variation,user_id,username,avatar_key,club_heart,points,official_points,exact_scores,good_differences,good_results,played,average,precision_pct,null::numeric above_gap,null::numeric below_gap
from ranked order by rank,username;
$$;

grant execute on function public.get_test_leaderboard_v071(uuid,boolean) to authenticated;

do $$ begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='matches') then
      alter publication supabase_realtime add table public.matches;
    end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='predictions') then
      alter publication supabase_realtime add table public.predictions;
    end if;
  end if;
end $$;

insert into public.app_settings(key,value) values('app_version','"0.7.1"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

commit;
