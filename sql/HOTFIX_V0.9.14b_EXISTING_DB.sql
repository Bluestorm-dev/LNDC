-- Le Nid des Champions — V0.9.14b
-- Mini-hotfix visuel : étoile au-dessus de l'avatar du vainqueur du Nid des Pronos 2026.
-- Aucun changement de schéma. La distinction utilise le code existant : nid-pronos-world-cup-2026.
insert into public.app_settings(key,value,updated_at)
values('app_version','"0.9.14b"'::jsonb,now())
on conflict(key) do update set value=excluded.value,updated_at=excluded.updated_at;
