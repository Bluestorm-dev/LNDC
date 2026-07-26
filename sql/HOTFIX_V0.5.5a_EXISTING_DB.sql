-- Le Nid des Champions — V0.5.5a
-- Correctif Teams : fonds de prévisualisation lisibles côté front,
-- Teams vacantes/réactivables et suppression définitive Super Admin.
-- À exécuter après V0.5.5 avec le rôle postgres dans Supabase SQL Editor.

begin;

-- Un capitaine peut quitter une Team dont il est le dernier membre.
-- La Team reste alors active mais vacante, donc captain_user_id doit accepter NULL.
alter table public.teams
  alter column captain_user_id drop not null;

-- Annuaire : conserver les Teams vacantes (capitaine NULL) et les archives.
create or replace function public.get_team_directory_v050(p_season_id uuid)
returns table(
  team_id uuid,name text,slug text,slogan text,description text,visibility text,status text,captain_user_id uuid,captain_username text,
  favorite_club_id uuid,favorite_club_name text,favorite_club_short text,favorite_club_logo_url text,favorite_club_logo_storage_path text,
  logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  member_count bigint,created_at timestamptz
)
language sql stable security definer set search_path=public as $$
  select t.id,t.name,t.slug,t.slogan,t.description,t.visibility,t.status,t.captain_user_id,cap.username::text,
    c.id,c.name,c.short_name,coalesce(c.logo_source_url,c.logo_url),c.logo_storage_path,
    t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    count(tm.id) filter(where tm.left_at is null)::bigint,t.created_at
  from public.teams t
  left join public.profiles cap on cap.id=t.captain_user_id
  left join public.clubs c on c.id=t.favorite_club_id
  left join public.team_memberships tm on tm.team_id=t.id
  where t.season_id=p_season_id
  group by t.id,cap.username,c.id,c.name,c.short_name,c.logo_source_url,c.logo_url,c.logo_storage_path
  order by (t.status='active') desc,(t.captain_user_id is null) desc,t.name;
$$;

-- Lecture de la Team courante : LEFT JOIN sur le capitaine pour tolérer les
-- états transitoires/vacants sans casser la RPC.
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
  left join public.profiles cap on cap.id=t.captain_user_id
  left join public.clubs c on c.id=t.favorite_club_id
  where mine.season_id=p_season_id and mine.user_id=auth.uid() and mine.left_at is null and t.status='active'
  order by mine.joined_at desc limit 1;
$$;

-- Quitter :
-- - membre normal => départ classique ;
-- - capitaine avec d'autres membres => transfert obligatoire ;
-- - capitaine seul => départ autorisé, Team conservée active et vacante.
create or replace function public.leave_team_v050(p_season_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  tm public.team_memberships%rowtype;
  t public.teams%rowtype;
  v_other_members integer;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;

  select * into tm
  from public.team_memberships
  where season_id=p_season_id and user_id=auth.uid() and left_at is null
  for update;
  if not found then raise exception 'Tu n’appartiens à aucune Team.'; end if;

  select * into t from public.teams where id=tm.team_id for update;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;

  if t.captain_user_id=auth.uid() then
    select count(*)::integer into v_other_members
    from public.team_memberships
    where team_id=t.id and left_at is null and user_id<>auth.uid();

    if v_other_members>0 then
      raise exception 'Transfère d’abord le capitanat avant de quitter la Team.';
    end if;

    update public.team_memberships set left_at=now(),leave_type='left' where id=tm.id;
    update public.teams set captain_user_id=null where id=t.id;
    update public.team_invites set active=false where team_id=t.id and active=true;
    update public.team_join_requests
      set status='cancelled',processed_at=now(),processed_by=auth.uid()
      where team_id=t.id and status='pending';
    perform public.log_team_event_v050(t.id,'member_left',auth.uid(),'{}'::jsonb);
    perform public.log_team_event_v050(t.id,'team_vacated',null,jsonb_build_object('former_captain_user_id',auth.uid()));
    return;
  end if;

  update public.team_memberships set left_at=now(),leave_type='left' where id=tm.id;
  perform public.log_team_event_v050(t.id,'member_left',auth.uid(),'{}'::jsonb);
end;
$$;

-- Reprendre une Team vacante ou réactiver sa propre Team dissoute.
create or replace function public.reclaim_team_v055a(p_team_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  t public.teams%rowtype;
  v_active_members integer;
  v_was_dissolved boolean;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=auth.uid() and status='active') then raise exception 'Compte inactif.'; end if;

  select * into t from public.teams where id=p_team_id for update;
  if not found then raise exception 'Team introuvable.'; end if;

  if exists(
    select 1 from public.team_memberships
    where season_id=t.season_id and user_id=auth.uid() and left_at is null
  ) then raise exception 'Tu appartiens déjà à une Team.'; end if;

  select count(*)::integer into v_active_members
  from public.team_memberships where team_id=t.id and left_at is null;

  v_was_dissolved := t.status='dissolved';

  if t.status='active' then
    if t.captain_user_id is not null or v_active_members>0 then
      raise exception 'Cette Team n’est plus vacante.';
    end if;
  elsif t.status='dissolved' then
    if t.captain_user_id is distinct from auth.uid() then
      raise exception 'Seul le dernier capitaine peut réactiver cette Team.';
    end if;
    if v_active_members>0 then raise exception 'Cette Team possède encore des membres actifs.'; end if;
  else
    raise exception 'État de Team non pris en charge.';
  end if;

  update public.teams
  set status='active',dissolved_at=null,captain_user_id=auth.uid()
  where id=t.id;

  insert into public.team_memberships(season_id,team_id,user_id,join_type)
  values(t.season_id,t.id,auth.uid(),'public');

  perform public.log_team_event_v050(
    t.id,
    case when v_was_dissolved then 'team_reactivated' else 'team_reclaimed' end,
    auth.uid(),
    jsonb_build_object('was_dissolved',v_was_dissolved)
  );
exception
  when unique_violation then
    raise exception 'Impossible de réactiver cette Team : son nom est désormais utilisé par une autre Team active.';
end;
$$;

-- Suppression physique réservée EXCLUSIVEMENT au Super Admin.
-- Les tables enfants sont en ON DELETE CASCADE ; un audit est conservé avant
-- suppression afin de garder la trace de l'acte de modération.
create or replace function public.super_admin_delete_team_v055a(p_team_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  t public.teams%rowtype;
begin
  if auth.uid() is null or not public.is_super_admin() then
    raise exception 'Suppression définitive réservée au Super Admin.';
  end if;

  select * into t from public.teams where id=p_team_id for update;
  if not found then raise exception 'Team introuvable.'; end if;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data,new_data)
  values(auth.uid(),'team_hard_delete','team',t.id::text,to_jsonb(t),jsonb_build_object('deleted_permanently',true));

  delete from public.teams where id=t.id;
end;
$$;

grant execute on function public.get_team_directory_v050(uuid) to anon,authenticated;
grant execute on function public.get_my_team_v050(uuid) to authenticated;
grant execute on function public.leave_team_v050(uuid) to authenticated;
grant execute on function public.reclaim_team_v055a(uuid) to authenticated;
grant execute on function public.super_admin_delete_team_v055a(uuid) to authenticated;

insert into public.app_settings(key,value)
values ('app_version','"0.5.5a"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
select id,name,status,captain_user_id,dissolved_at from public.teams order by created_at desc limit 20;
