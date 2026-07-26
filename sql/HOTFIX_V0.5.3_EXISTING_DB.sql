-- Le Nid des Champions — V0.5.3
-- Avatars joueurs : bibliothèque officielle, upload, Storage, RLS et modération Admin.

begin;

alter table public.profiles add column if not exists avatar_source text not null default 'library';
alter table public.profiles add column if not exists avatar_storage_path text;
alter table public.profiles add column if not exists avatar_moderation_status text not null default 'approved';
alter table public.profiles add column if not exists avatar_rejection_reason text;
alter table public.profiles add column if not exists avatar_updated_at timestamptz not null default now();
alter table public.profiles alter column avatar_key set default 'avatar-hibou-or';

alter table public.profiles drop constraint if exists profiles_avatar_source_check;
alter table public.profiles add constraint profiles_avatar_source_check check (avatar_source in ('library','upload'));
alter table public.profiles drop constraint if exists profiles_avatar_moderation_status_check;
alter table public.profiles add constraint profiles_avatar_moderation_status_check check (avatar_moderation_status in ('approved','pending','rejected'));

-- Compatibilité avec les trois clés historiques du mode démo / premières versions.
update public.profiles set avatar_key='avatar-hibou-or' where avatar_key='owl-gold';
update public.profiles set avatar_key='avatar-hibou-saphir' where avatar_key='owl-blue';
update public.profiles set avatar_key='avatar-hibou-amethyste' where avatar_key='owl-violet';
update public.profiles set avatar_key='avatar-hibou-or' where avatar_key is null or btrim(avatar_key)='';

-- Les colonnes de modération ne sont volontairement PAS accordées en UPDATE direct.
-- Le joueur passe par les RPC ci-dessous ; l'Admin passe par la RPC de modération.
grant select on public.profiles to authenticated;
revoke update(avatar_key) on public.profiles from authenticated;

-- -----------------------------------------------------------------------------
-- Catalogue officiel V0.5.3 : 90 assets livrés avec le front.
-- -----------------------------------------------------------------------------
create table if not exists public.player_avatar_catalog (
  avatar_key text primary key,
  label text not null,
  category text not null,
  sort_order integer not null,
  asset_path text not null,
  active boolean not null default true
);

alter table public.player_avatar_catalog enable row level security;
drop policy if exists player_avatar_catalog_read on public.player_avatar_catalog;
create policy player_avatar_catalog_read on public.player_avatar_catalog
for select using (true);
grant select on public.player_avatar_catalog to anon,authenticated;

insert into public.player_avatar_catalog(avatar_key,label,category,sort_order,asset_path,active)
values
  ('avatar-hibou-royal','Royal','Nobles',1,'assets/avatars/nid/avatar-hibou-royal.png',true),
  ('avatar-hibou-argent','Argent','Nobles',2,'assets/avatars/nid/avatar-hibou-argent.png',true),
  ('avatar-hibou-or','Or','Nobles',3,'assets/avatars/nid/avatar-hibou-or.png',true),
  ('avatar-hibou-saphir','Saphir','Nobles',4,'assets/avatars/nid/avatar-hibou-saphir.png',true),
  ('avatar-hibou-amethyste','Amethyste','Nobles',5,'assets/avatars/nid/avatar-hibou-amethyste.png',true),
  ('avatar-hibou-velours','Velours','Nobles',6,'assets/avatars/nid/avatar-hibou-velours.png',true),
  ('avatar-hibou-couronne','Couronne','Nobles',7,'assets/avatars/nid/avatar-hibou-couronne.png',true),
  ('avatar-hibou-imperial','Imperial','Nobles',8,'assets/avatars/nid/avatar-hibou-imperial.png',true),
  ('avatar-hibou-europe','Europe','Nobles',9,'assets/avatars/nid/avatar-hibou-europe.png',true),
  ('avatar-hibou-prestige','Prestige','Nobles',10,'assets/avatars/nid/avatar-hibou-prestige.png',true),
  ('avatar-hibou-minuit','Minuit','Nocturnes',11,'assets/avatars/nid/avatar-hibou-minuit.png',true),
  ('avatar-hibou-eclipse','Eclipse','Nocturnes',12,'assets/avatars/nid/avatar-hibou-eclipse.png',true),
  ('avatar-hibou-lunaire','Lunaire','Nocturnes',13,'assets/avatars/nid/avatar-hibou-lunaire.png',true),
  ('avatar-hibou-nebuleuse','Nebuleuse','Nocturnes',14,'assets/avatars/nid/avatar-hibou-nebuleuse.png',true),
  ('avatar-hibou-astral','Astral','Nocturnes',15,'assets/avatars/nid/avatar-hibou-astral.png',true),
  ('avatar-hibou-constellation','Constellation','Nocturnes',16,'assets/avatars/nid/avatar-hibou-constellation.png',true),
  ('avatar-hibou-etoile','Etoile','Nocturnes',17,'assets/avatars/nid/avatar-hibou-etoile.png',true),
  ('avatar-hibou-comete','Comete','Nocturnes',18,'assets/avatars/nid/avatar-hibou-comete.png',true),
  ('avatar-hibou-orbite','Orbite','Nocturnes',19,'assets/avatars/nid/avatar-hibou-orbite.png',true),
  ('avatar-hibou-galaxie','Galaxie','Nocturnes',20,'assets/avatars/nid/avatar-hibou-galaxie.png',true),
  ('avatar-hibou-echarpe','Echarpe','Supporters',21,'assets/avatars/nid/avatar-hibou-echarpe.png',true),
  ('avatar-hibou-tambour','Tambour','Supporters',22,'assets/avatars/nid/avatar-hibou-tambour.png',true),
  ('avatar-hibou-tribune','Tribune','Supporters',23,'assets/avatars/nid/avatar-hibou-tribune.png',true),
  ('avatar-hibou-ultra','Ultra','Supporters',24,'assets/avatars/nid/avatar-hibou-ultra.png',true),
  ('avatar-hibou-drapeau','Drapeau','Supporters',25,'assets/avatars/nid/avatar-hibou-drapeau.png',true),
  ('avatar-hibou-chant','Chant','Supporters',26,'assets/avatars/nid/avatar-hibou-chant.png',true),
  ('avatar-hibou-stade','Stade','Supporters',27,'assets/avatars/nid/avatar-hibou-stade.png',true),
  ('avatar-hibou-kop','Kop','Supporters',28,'assets/avatars/nid/avatar-hibou-kop.png',true),
  ('avatar-hibou-tifo','Tifo','Supporters',29,'assets/avatars/nid/avatar-hibou-tifo.png',true),
  ('avatar-hibou-fumigene','Fumigene','Supporters',30,'assets/avatars/nid/avatar-hibou-fumigene.png',true),
  ('avatar-hibou-buteur','Buteur','Football',31,'assets/avatars/nid/avatar-hibou-buteur.png',true),
  ('avatar-hibou-gardien','Gardien','Football',32,'assets/avatars/nid/avatar-hibou-gardien.png',true),
  ('avatar-hibou-coach','Coach','Football',33,'assets/avatars/nid/avatar-hibou-coach.png',true),
  ('avatar-hibou-arbitre','Arbitre','Football',34,'assets/avatars/nid/avatar-hibou-arbitre.png',true),
  ('avatar-hibou-capitaine','Capitaine','Football',35,'assets/avatars/nid/avatar-hibou-capitaine.png',true),
  ('avatar-hibou-meneur','Meneur','Football',36,'assets/avatars/nid/avatar-hibou-meneur.png',true),
  ('avatar-hibou-defenseur','Defenseur','Football',37,'assets/avatars/nid/avatar-hibou-defenseur.png',true),
  ('avatar-hibou-ailier','Ailier','Football',38,'assets/avatars/nid/avatar-hibou-ailier.png',true),
  ('avatar-hibou-numero10','Numero10','Football',39,'assets/avatars/nid/avatar-hibou-numero10.png',true),
  ('avatar-hibou-remplacant','Remplacant','Football',40,'assets/avatars/nid/avatar-hibou-remplacant.png',true),
  ('avatar-hibou-coupe','Coupe','Champions',41,'assets/avatars/nid/avatar-hibou-coupe.png',true),
  ('avatar-hibou-medaille','Medaille','Champions',42,'assets/avatars/nid/avatar-hibou-medaille.png',true),
  ('avatar-hibou-champion','Champion','Champions',43,'assets/avatars/nid/avatar-hibou-champion.png',true),
  ('avatar-hibou-finale','Finale','Champions',44,'assets/avatars/nid/avatar-hibou-finale.png',true),
  ('avatar-hibou-podium','Podium','Champions',45,'assets/avatars/nid/avatar-hibou-podium.png',true),
  ('avatar-hibou-victoire','Victoire','Champions',46,'assets/avatars/nid/avatar-hibou-victoire.png',true),
  ('avatar-hibou-etoile-or','Etoile Or','Champions',47,'assets/avatars/nid/avatar-hibou-etoile-or.png',true),
  ('avatar-hibou-trophee','Trophee','Champions',48,'assets/avatars/nid/avatar-hibou-trophee.png',true),
  ('avatar-hibou-legende','Legende','Champions',49,'assets/avatars/nid/avatar-hibou-legende.png',true),
  ('avatar-hibou-dynastie','Dynastie','Champions',50,'assets/avatars/nid/avatar-hibou-dynastie.png',true),
  ('avatar-hibou-casserole','Casserole','Humour',51,'assets/avatars/nid/avatar-hibou-casserole.png',true),
  ('avatar-hibou-poele','Poele','Humour',52,'assets/avatars/nid/avatar-hibou-poele.png',true),
  ('avatar-hibou-boulet','Boulet','Humour',53,'assets/avatars/nid/avatar-hibou-boulet.png',true),
  ('avatar-hibou-perdu','Perdu','Humour',54,'assets/avatars/nid/avatar-hibou-perdu.png',true),
  ('avatar-hibou-endormi','Endormi','Humour',55,'assets/avatars/nid/avatar-hibou-endormi.png',true),
  ('avatar-hibou-retard','Retard','Humour',56,'assets/avatars/nid/avatar-hibou-retard.png',true),
  ('avatar-hibou-var','Var','Humour',57,'assets/avatars/nid/avatar-hibou-var.png',true),
  ('avatar-hibou-carton','Carton','Humour',58,'assets/avatars/nid/avatar-hibou-carton.png',true),
  ('avatar-hibou-zero','Zero','Humour',59,'assets/avatars/nid/avatar-hibou-zero.png',true),
  ('avatar-hibou-mauvaise-foi','Mauvaise Foi','Humour',60,'assets/avatars/nid/avatar-hibou-mauvaise-foi.png',true),
  ('avatar-hibou-masque','Masque','Mystérieux',61,'assets/avatars/nid/avatar-hibou-masque.png',true),
  ('avatar-hibou-ombre','Ombre','Mystérieux',62,'assets/avatars/nid/avatar-hibou-ombre.png',true),
  ('avatar-hibou-fantome','Fantome','Mystérieux',63,'assets/avatars/nid/avatar-hibou-fantome.png',true),
  ('avatar-hibou-secret','Secret','Mystérieux',64,'assets/avatars/nid/avatar-hibou-secret.png',true),
  ('avatar-hibou-oracle','Oracle','Mystérieux',65,'assets/avatars/nid/avatar-hibou-oracle.png',true),
  ('avatar-hibou-prophete','Prophete','Mystérieux',66,'assets/avatars/nid/avatar-hibou-prophete.png',true),
  ('avatar-hibou-mage','Mage','Mystérieux',67,'assets/avatars/nid/avatar-hibou-mage.png',true),
  ('avatar-hibou-alchimiste','Alchimiste','Mystérieux',68,'assets/avatars/nid/avatar-hibou-alchimiste.png',true),
  ('avatar-hibou-sorcier','Sorcier','Mystérieux',69,'assets/avatars/nid/avatar-hibou-sorcier.png',true),
  ('avatar-hibou-enigme','Enigme','Mystérieux',70,'assets/avatars/nid/avatar-hibou-enigme.png',true),
  ('avatar-hibou-neon','Neon','Futuristes',71,'assets/avatars/nid/avatar-hibou-neon.png',true),
  ('avatar-hibou-cyber','Cyber','Futuristes',72,'assets/avatars/nid/avatar-hibou-cyber.png',true),
  ('avatar-hibou-hologramme','Hologramme','Futuristes',73,'assets/avatars/nid/avatar-hibou-hologramme.png',true),
  ('avatar-hibou-quantique','Quantique','Futuristes',74,'assets/avatars/nid/avatar-hibou-quantique.png',true),
  ('avatar-hibou-electrique','Electrique','Futuristes',75,'assets/avatars/nid/avatar-hibou-electrique.png',true),
  ('avatar-hibou-plasma','Plasma','Futuristes',76,'assets/avatars/nid/avatar-hibou-plasma.png',true),
  ('avatar-hibou-vector','Vector','Futuristes',77,'assets/avatars/nid/avatar-hibou-vector.png',true),
  ('avatar-hibou-digital','Digital','Futuristes',78,'assets/avatars/nid/avatar-hibou-digital.png',true),
  ('avatar-hibou-android','Android','Futuristes',79,'assets/avatars/nid/avatar-hibou-android.png',true),
  ('avatar-hibou-cosmos','Cosmos','Futuristes',80,'assets/avatars/nid/avatar-hibou-cosmos.png',true),
  ('avatar-hibou-cristal','Cristal','Rares',81,'assets/avatars/nid/avatar-hibou-cristal.png',true),
  ('avatar-hibou-diamant','Diamant','Rares',82,'assets/avatars/nid/avatar-hibou-diamant.png',true),
  ('avatar-hibou-obsidienne','Obsidienne','Rares',83,'assets/avatars/nid/avatar-hibou-obsidienne.png',true),
  ('avatar-hibou-rubis','Rubis','Rares',84,'assets/avatars/nid/avatar-hibou-rubis.png',true),
  ('avatar-hibou-emeraude','Emeraude','Rares',85,'assets/avatars/nid/avatar-hibou-emeraude.png',true),
  ('avatar-hibou-opale','Opale','Rares',86,'assets/avatars/nid/avatar-hibou-opale.png',true),
  ('avatar-hibou-titane','Titane','Rares',87,'assets/avatars/nid/avatar-hibou-titane.png',true),
  ('avatar-hibou-platine','Platine','Rares',88,'assets/avatars/nid/avatar-hibou-platine.png',true),
  ('avatar-hibou-arcane','Arcane','Rares',89,'assets/avatars/nid/avatar-hibou-arcane.png',true),
  ('avatar-hibou-aurora','Aurora','Rares',90,'assets/avatars/nid/avatar-hibou-aurora.png',true)
on conflict(avatar_key) do update
set label=excluded.label,category=excluded.category,sort_order=excluded.sort_order,asset_path=excluded.asset_path,active=excluded.active;

-- -----------------------------------------------------------------------------
-- Storage player-avatars : privé ; lecture RLS propriétaire/Admin/approuvé, écriture limitée au dossier du joueur.
-- La publication dans l'UI reste conditionnée par avatar_moderation_status='approved'.
-- -----------------------------------------------------------------------------
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('player-avatars','player-avatars',false,3145728,array['image/png','image/jpeg','image/webp'])
on conflict(id) do update
set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists player_avatars_public_read on storage.objects;
drop policy if exists player_avatars_authorized_read on storage.objects;
create policy player_avatars_authorized_read on storage.objects
for select to authenticated
using (
  bucket_id='player-avatars'
  and (
    (storage.foldername(name))[1]=auth.uid()::text
    or public.is_admin()
    or exists(
      select 1 from public.profiles p
      where p.avatar_source='upload'
        and p.avatar_storage_path=name
        and p.avatar_moderation_status='approved'
        and p.status='active'
    )
  )
);

drop policy if exists player_avatars_own_insert on storage.objects;
create policy player_avatars_own_insert on storage.objects
for insert to authenticated
with check (
  bucket_id='player-avatars'
  and (storage.foldername(name))[1]=auth.uid()::text
  and lower(storage.extension(name)) in ('png','jpg','jpeg','webp')
);

drop policy if exists player_avatars_own_update on storage.objects;
create policy player_avatars_own_update on storage.objects
for update to authenticated
using (
  bucket_id='player-avatars'
  and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin())
)
with check (
  bucket_id='player-avatars'
  and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin())
  and lower(storage.extension(name)) in ('png','jpg','jpeg','webp')
);

drop policy if exists player_avatars_own_delete on storage.objects;
create policy player_avatars_own_delete on storage.objects
for delete to authenticated
using (
  bucket_id='player-avatars'
  and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin())
);

-- -----------------------------------------------------------------------------
-- Choix d'un avatar officiel : immédiatement approuvé.
-- -----------------------------------------------------------------------------
create or replace function public.select_player_avatar_v053(p_avatar_key text)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare v_key text:=btrim(coalesce(p_avatar_key,''));
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=auth.uid() and status='active') then raise exception 'Compte inactif.'; end if;
  if not exists(select 1 from public.player_avatar_catalog where avatar_key=v_key and active) then raise exception 'Avatar officiel invalide.'; end if;

  update public.profiles
  set avatar_source='library',
      avatar_key=v_key,
      avatar_storage_path=null,
      avatar_moderation_status='approved',
      avatar_rejection_reason=null,
      avatar_updated_at=now()
  where id=auth.uid();
end;
$$;
grant execute on function public.select_player_avatar_v053(text) to authenticated;

-- -----------------------------------------------------------------------------
-- Dépôt d'un upload : reste masqué publiquement jusqu'à validation Admin.
-- -----------------------------------------------------------------------------
create or replace function public.submit_player_avatar_v053(p_storage_path text)
returns void
language plpgsql
security definer
set search_path=public,storage
as $$
declare
  v_path text:=btrim(coalesce(p_storage_path,''));
  v_expected_prefix text:=auth.uid()::text || '/';
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=auth.uid() and status='active') then raise exception 'Compte inactif.'; end if;
  if v_path not like v_expected_prefix || '%' then raise exception 'Chemin avatar interdit.'; end if;
  if lower(storage.extension(v_path)) not in ('png','jpg','jpeg','webp') then raise exception 'Format avatar interdit.'; end if;
  if not exists(select 1 from storage.objects where bucket_id='player-avatars' and name=v_path) then raise exception 'Fichier avatar introuvable.'; end if;

  update public.profiles
  set avatar_source='upload',
      avatar_storage_path=v_path,
      avatar_moderation_status='pending',
      avatar_rejection_reason=null,
      avatar_updated_at=now()
  where id=auth.uid();
end;
$$;
grant execute on function public.submit_player_avatar_v053(text) to authenticated;

-- -----------------------------------------------------------------------------
-- File de modération Admin.
-- -----------------------------------------------------------------------------
create or replace function public.admin_list_avatar_moderation_v053()
returns table(
  user_id uuid,
  username text,
  avatar_key text,
  avatar_storage_path text,
  avatar_moderation_status text,
  avatar_rejection_reason text,
  avatar_updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path=public
as $$
begin
  if not public.is_admin() then raise exception 'Accès Admin requis.'; end if;
  return query
  select p.id,p.username::text,p.avatar_key,p.avatar_storage_path,p.avatar_moderation_status,p.avatar_rejection_reason,p.avatar_updated_at
  from public.profiles p
  where p.avatar_source='upload'
    and p.avatar_storage_path is not null
    and p.avatar_moderation_status in ('pending','rejected')
  order by case when p.avatar_moderation_status='pending' then 0 else 1 end,p.avatar_updated_at desc;
end;
$$;
grant execute on function public.admin_list_avatar_moderation_v053() to authenticated;

create or replace function public.admin_moderate_avatar_v053(
  p_user_id uuid,
  p_decision text,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  v_before jsonb;
  v_after jsonb;
  v_decision text:=lower(btrim(coalesce(p_decision,'')));
begin
  if not public.is_admin() then raise exception 'Accès Admin requis.'; end if;
  if v_decision not in ('approve','reject') then raise exception 'Décision invalide.'; end if;

  select to_jsonb(p) into v_before from public.profiles p where p.id=p_user_id;
  if v_before is null then raise exception 'Joueur introuvable.'; end if;
  if not exists(select 1 from public.profiles where id=p_user_id and avatar_source='upload' and avatar_storage_path is not null) then
    raise exception 'Aucun avatar uploadé à modérer.';
  end if;

  update public.profiles
  set avatar_moderation_status=case when v_decision='approve' then 'approved' else 'rejected' end,
      avatar_rejection_reason=case when v_decision='reject' then nullif(btrim(coalesce(p_reason,'')),'') else null end,
      avatar_updated_at=now()
  where id=p_user_id;

  select to_jsonb(p) into v_after from public.profiles p where p.id=p_user_id;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data,new_data)
  values(auth.uid(),'avatar_'||v_decision,'profile',p_user_id,v_before,v_after);
end;
$$;
grant execute on function public.admin_moderate_avatar_v053(uuid,text,text) to authenticated;

insert into public.app_settings(key,value)
values('app_version','"0.5.3"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
select id,name,public,file_size_limit,allowed_mime_types from storage.buckets where id='player-avatars';
select proname from pg_proc where proname like '%avatar%v053' order by proname;
