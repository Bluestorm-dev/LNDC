-- =============================================================================
-- LE NID DES CHAMPIONS — V0.9.10 R3
-- Correctif Admin calendrier / cotes 1N2 / périmètre clubs modifiables.
-- À exécuter sur une base déjà migrée en V0.9.10.
-- =============================================================================

begin;

-- 1) Un Admin ne peut modifier que :
--    - un club présent dans le catalogue Champions League ;
--    - ou un club créé manuellement dans le Nid.
create or replace function public.admin_update_club_metadata_v0910(
  p_club_id uuid,p_name text,p_short_name text,p_tla text default null,p_country text default null,
  p_venue text default null,p_logo_url text default null,p_lock_manual boolean default true
) returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  if not exists(
    select 1
    from public.clubs c
    where c.id=p_club_id
      and (
        c.metadata_source='manual'
        or exists(
          select 1 from public.club_catalog_memberships cm
          where cm.club_id=c.id and cm.competition_code='CL'
        )
      )
  ) then
    raise exception 'Seuls les clubs de la Ligue des champions et les clubs créés manuellement sont modifiables.';
  end if;

  update public.clubs set
    name=coalesce(nullif(trim(p_name),''),name),
    short_name=coalesce(nullif(trim(p_short_name),''),short_name),
    tla=nullif(upper(trim(p_tla)),''),
    country=nullif(trim(p_country),''),
    venue=nullif(trim(p_venue),''),
    logo_url=coalesce(nullif(trim(p_logo_url),''),logo_url),
    metadata_source=case when p_lock_manual then 'manual' else metadata_source end,
    manual_metadata_lock=p_lock_manual,
    manual_metadata_updated_at=case when p_lock_manual then now() else manual_metadata_updated_at end,
    updated_at=now()
  where id=p_club_id;

  update public.club_catalog_memberships
  set country=(select country from public.clubs where id=p_club_id),updated_at=now()
  where club_id=p_club_id;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'club_update_v0910','club',p_club_id::text,
    jsonb_build_object('manual_lock',p_lock_manual,'scope','ucl_or_manual'));
end;$$;
grant execute on function public.admin_update_club_metadata_v0910(uuid,text,text,text,text,text,text,boolean) to authenticated;

-- 2) Saisie manuelle des cotes 1N2.
--    Elle est volontairement impossible après le coup d'envoi pour ne pas réécrire
--    a posteriori une cote utilisée par les statistiques/gamification.
create or replace function public.admin_update_match_odds_v0910(
  p_match_id uuid,
  p_odds_home numeric default null,
  p_odds_draw numeric default null,
  p_odds_away numeric default null,
  p_bookmaker text default null,
  p_clear boolean default false
) returns void language plpgsql security definer set search_path=public as $$
declare
  v_status text;
  v_kickoff timestamptz;
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;

  select status,kickoff_at into v_status,v_kickoff
  from public.matches where id=p_match_id;
  if v_status is null then raise exception 'Match introuvable.'; end if;
  if v_status in ('live','finished') or (v_kickoff is not null and now()>=v_kickoff) then
    raise exception 'Les cotes ne peuvent plus être modifiées après le coup d''envoi.';
  end if;

  if p_clear then
    update public.matches set
      odds_home=null,odds_draw=null,odds_away=null,
      odds_provider=null,odds_bookmaker=null,odds_source_season=null,
      odds_is_test_shifted=false,odds_updated_at=now(),updated_at=now()
    where id=p_match_id;
  else
    if p_odds_home is null or p_odds_draw is null or p_odds_away is null then
      raise exception 'Les trois cotes 1 / N / 2 sont obligatoires.';
    end if;
    if p_odds_home<=1 or p_odds_draw<=1 or p_odds_away<=1
       or p_odds_home>1000 or p_odds_draw>1000 or p_odds_away>1000 then
      raise exception 'Chaque cote doit être comprise entre 1,01 et 1000.';
    end if;

    update public.matches set
      odds_home=round(p_odds_home::numeric,2),
      odds_draw=round(p_odds_draw::numeric,2),
      odds_away=round(p_odds_away::numeric,2),
      odds_provider='manual',
      odds_bookmaker=coalesce(nullif(trim(p_bookmaker),''),'Saisie manuelle'),
      odds_source_season=null,
      odds_is_test_shifted=false,
      odds_updated_at=now(),updated_at=now()
    where id=p_match_id;
  end if;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),case when p_clear then 'match_odds_clear_v0910' else 'match_odds_manual_v0910' end,
    'match',p_match_id::text,
    case when p_clear then jsonb_build_object('cleared',true)
         else jsonb_build_object('home',p_odds_home,'draw',p_odds_draw,'away',p_odds_away,'bookmaker',coalesce(nullif(trim(p_bookmaker),''),'Saisie manuelle')) end);
end;$$;
grant execute on function public.admin_update_match_odds_v0910(uuid,numeric,numeric,numeric,text,boolean) to authenticated;

-- Force PostgREST à recharger rapidement les nouvelles signatures dans les projets
-- où le cache de schéma est activé.
notify pgrst, 'reload schema';

commit;
