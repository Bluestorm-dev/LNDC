-- Le Nid des Champions — V0.9.13
-- Auto-validation comptes + onboarding V0.9.13
begin;

insert into public.app_settings(key,value,updated_at)
values('app_version','"0.9.13"'::jsonb,now())
on conflict(key) do update set value=excluded.value,updated_at=excluded.updated_at;

-- Les nouveaux comptes entrent directement dans le Nid.
alter table public.profiles alter column status set default 'active';

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare v_username text; v_first_name text;
begin
  v_username:=nullif(trim(new.raw_user_meta_data->>'username'),'');
  v_first_name:=nullif(trim(new.raw_user_meta_data->>'first_name'),'');
  if v_username is null then raise exception 'Le pseudo est obligatoire.'; end if;
  insert into public.profiles(id,username,status) values(new.id,v_username,'active');
  insert into public.profile_private(user_id,first_name) values(new.id,v_first_name);
  return new;
end;$$;

-- Les demandes encore en attente de l'ancien système sont ouvertes.
update public.profiles set status='active',updated_at=now() where status='pending';

-- L'ancien Push « demande à valider » n'a plus de raison d'être.
drop trigger if exists notify_super_admin_registration_v0912 on public.profiles;
drop function if exists public.notify_super_admin_registration_v0912();

-- Le Super Admin reste informé d'une nouvelle inscription, mais il n'a rien à valider.
create or replace function public.notify_super_admin_registration_v0913()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare v_admin record; v_season_id uuid;
begin
  if new.status<>'active' then return new; end if;
  select id into v_season_id from public.seasons where is_active=true order by created_at desc limit 1;
  for v_admin in select id from public.profiles where role='super_admin' and status='active' and id<>new.id loop
    insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,source_key,push_requested,created_at)
    values(v_admin.id,v_season_id,'system','🦉 Nouveau joueur dans le Nid',coalesce(nullif(new.username::text,''),'Un joueur')||' vient de créer son compte.','normal','admin:players',jsonb_build_object('section','players','new_user_id',new.id,'username',new.username::text),'registration-auto:'||new.id::text,true,now())
    on conflict(user_id,source_key) where source_key is not null do nothing;
  end loop;
  return new;
end;$$;

drop trigger if exists notify_super_admin_registration_v0913 on public.profiles;
create trigger notify_super_admin_registration_v0913
after insert on public.profiles
for each row execute function public.notify_super_admin_registration_v0913();

commit;

select * from (values
 ('Version','Backend',case when coalesce((select value#>>'{}' from public.app_settings where key='app_version'),'')='0.9.13' then 'PASS' else 'FAIL' end),
 ('Comptes','Validation automatique',case when (select column_default from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='status') like '%active%' then 'PASS' else 'FAIL' end),
 ('Comptes','Anciennes demandes',case when not exists(select 1 from public.profiles where status='pending') then 'PASS' else 'WARN' end),
 ('Notifications','Nouveau joueur',case when to_regprocedure('public.notify_super_admin_registration_v0913()') is not null then 'PASS' else 'FAIL' end)
) as t(section,test,status);
