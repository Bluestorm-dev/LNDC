-- Le Nid des Champions — V0.9.14
-- Aucun changement de schéma : la release remplace les assets des 100 succès
-- et ajoute les animations/détails du Musée côté frontend.
insert into public.app_settings(key,value,updated_at)
values('app_version','"0.9.14"'::jsonb,now())
on conflict(key) do update set value=excluded.value,updated_at=excluded.updated_at;
