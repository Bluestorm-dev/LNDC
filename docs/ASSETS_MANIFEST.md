# V0.6.0 — note assets

La V0.6.0 ne nécessite aucun nouveau visuel binaire : elle réutilise les icônes PWA, avatars et le Hibou officiel déjà présents. Le manifeste machine `assets/assets-manifest.json` est porté en V0.6.0.

---

# Le Nid des Champions — Manifeste maître des assets

> **Source de vérité pour tous les fichiers graphiques du projet.**
>
> Chaque ajout, suppression ou renommage d'un asset doit être reporté ici dans la même version.

## Règle de maintenance

1. Créer l'asset dans le dossier prévu.
2. Respecter le nom normalisé.
3. Ajouter ou mettre à jour sa ligne dans ce document.
4. Mettre à jour `README.md` si l'asset accompagne une nouvelle fonctionnalité ou une nouvelle famille d'assets.
5. Mettre à jour `CHANGELOG.md` si l'ajout appartient à une version publiée.
6. Ne jamais supprimer silencieusement un asset : le marquer obsolète avant nettoyage.

---

# 1. Convention de nommage

- minuscules ;
- sans accents ni espaces ;
- mots séparés par `-` ;
- `.png` pour les assets listés ici ;
- fond transparent sauf backgrounds ;
- jamais `final`, `final2`, `v3`, `bis`, etc.

Bon : `badge-legendary-prophete.png`  
À bannir : `badge_prophete_final_v4_bis.png`

---

# 2. Arborescence

```text
assets/
├── branding/{logo,owl,backgrounds}/
├── icons/{navigation,actions,status}/
├── clubs/{ucl,favourites}/
├── avatars/nid/
├── badges/{common,rare,epic,legendary,secret}/
├── trophies/
├── teams/{default,shapes}/
└── reports/{backgrounds,decorations}/
```

# 3. Dimensions

| Famille | Taille de travail | Fond |
|---|---:|---|
| Logo | 1024×1024 | transparent |
| Hibou | 1024×1024 | transparent |
| Background | 1920×1080 min. | opaque |
| Icône UI | 256×256 | transparent |
| Club | 512×512 | transparent |
| Avatar | 512×512 | transparent |
| Badge | 512×512 | transparent |
| Trophée | 1024×1024 | transparent |
| Forme Team | 1024×512 | alpha / monochrome |

# 4. Branding principal

- `assets/branding/logo/logo-nid-des-champions.png` — Logo principal
- `assets/branding/logo/logo-nid-des-champions-horizontal.png` — Logo horizontal
- `assets/branding/owl/owl-masked-main.png` — Hibou principal
- `assets/branding/owl/owl-masked-live.png` — Hibou live
- `assets/branding/owl/owl-masked-warning.png` — Hibou avertissement
- `assets/branding/owl/owl-masked-celebration.png` — Hibou célébration
- `assets/branding/owl/owl-masked-pan.png` — Hibou casserole
- `assets/branding/owl/owl-masked-genius.png` — Hibou génie
- `assets/branding/backgrounds/bg-main-night.png` — Fond principal
- `assets/branding/backgrounds/bg-live-stadium.png` — Fond live
- `assets/branding/backgrounds/bg-login-stars.png` — Fond login
- `assets/branding/backgrounds/bg-hall-of-fame.png` — Fond Hall of Fame


## V0.5.0 — Assets réellement livrés

| Fichier | Statut | Usage |
|---|---|---|
| `assets/branding/owl/owl-masked-main.png` | **DONE** | Hibou masqué officiel du site : cape bleu nuit/or, masque, front vierge, médaillon vierge, sans ballon, fond réellement transparent. |

### Identité Teams V0.5.0

Les **12 formes**, **12 cadres/matières** et les fonds/dégradés Teams sont générés en CSS afin de rester légers et recolorables. Ils ne nécessitent donc pas un PNG par variante.

La bibliothèque initiale de logos Team (`Hibou`, `Étoile`, `Garde`, `Éclair`, `Couronne`, `Lune`, `Plume`, `Flamme`, `Football`, `Tour`, `Diamant`, `Aigle`) est rendue par glyphes. Depuis la **V0.5.2**, ces symboles sont affichés **sans fond opaque** afin de laisser visibles la forme et les couleurs de la Team. Les futurs PNG/SVG officiels transparents pourront remplacer ces glyphes sans changer le modèle de données.

Les uploads personnalisés sont stockés dans le bucket Supabase public `team-logos`.

# 5. Icônes UI

| Fichier | Fonction |
|---|---|
| `assets/icons/icon-home.png` | Accueil |
| `assets/icons/icon-matches.png` | Matchs / Pronostics |
| `assets/icons/icon-ranking.png` | Classements |
| `assets/icons/icon-season.png` | Saison |
| `assets/icons/icon-profile.png` | Profil |
| `assets/icons/icon-teams.png` | Teams |
| `assets/icons/icon-records.png` | Records |
| `assets/icons/icon-owl.png` | Hibou masqué |
| `assets/icons/icon-notification.png` | Notifications |
| `assets/icons/icon-settings.png` | Réglages |
| `assets/icons/icon-admin.png` | Administration |
| `assets/icons/icon-live.png` | Live |
| `assets/icons/icon-lock.png` | Pronostic verrouillé |
| `assets/icons/icon-unlock.png` | Pronostic ouvert |
| `assets/icons/icon-check.png` | Enregistré / validé |
| `assets/icons/icon-warning.png` | Alerte |
| `assets/icons/icon-calendar.png` | Calendrier / journée |
| `assets/icons/icon-trophy.png` | Trophée |
| `assets/icons/icon-badge.png` | Badge |
| `assets/icons/icon-rival.png` | Rival |
| `assets/icons/icon-genius.png` | Génie |
| `assets/icons/icon-pan.png` | Casserole |
| `assets/icons/icon-solo.png` | Hibou solitaire |
| `assets/icons/icon-poll.png` | Sondage |
| `assets/icons/icon-ticket.png` | Message au Hibou |
| `assets/icons/icon-camera.png` | Capture |
| `assets/icons/icon-download.png` | Export |
| `assets/icons/icon-install.png` | Installer la PWA |
| `assets/icons/icon-maintenance.png` | Maintenance |
| `assets/icons/icon-history.png` | Historique |
| `assets/icons/icon-arrow-up.png` | Progression |
| `assets/icons/icon-arrow-down.png` | Baisse |
| `assets/icons/icon-equal.png` | Stable |
| `assets/icons/icon-search.png` | Recherche |
| `assets/icons/icon-filter.png` | Filtre |
| `assets/icons/icon-menu.png` | Menu |

# 6. Clubs

Compétition : `assets/clubs/ucl/club-<slug>.png`  
Club de cœur hors compétition : `assets/clubs/favourites/club-<slug>.png`

Exemples :
- `club-psg.png`
- `club-real-madrid.png`
- `club-arsenal.png`
- `club-bayern-munich.png`
- `club-barcelona.png`
- `club-inter-milan.png`
- `club-liverpool.png`
- `club-borussia-dortmund.png`
- `club-stade-brestois.png`

> La liste réelle des clubs sera remplie saison par saison après validation du plateau officiel.

# 7. Avatars officiels — 168 PNG

Dossier : `assets/avatars/nid/`  
Convention : `avatar-<slug>.png`

## Hiboux nobles

| # | Fichier | Nom |
|---:|---|---|
| 1 | `avatar-hibou-royal.png` | Royal |
| 2 | `avatar-hibou-argent.png` | Argent |
| 3 | `avatar-hibou-or.png` | Or |
| 4 | `avatar-hibou-saphir.png` | Saphir |
| 5 | `avatar-hibou-amethyste.png` | Amethyste |
| 6 | `avatar-hibou-velours.png` | Velours |
| 7 | `avatar-hibou-couronne.png` | Couronne |
| 8 | `avatar-hibou-imperial.png` | Imperial |
| 9 | `avatar-hibou-europe.png` | Europe |
| 10 | `avatar-hibou-prestige.png` | Prestige |

## Hiboux nocturnes

| # | Fichier | Nom |
|---:|---|---|
| 11 | `avatar-hibou-minuit.png` | Minuit |
| 12 | `avatar-hibou-eclipse.png` | Eclipse |
| 13 | `avatar-hibou-lunaire.png` | Lunaire |
| 14 | `avatar-hibou-nebuleuse.png` | Nebuleuse |
| 15 | `avatar-hibou-astral.png` | Astral |
| 16 | `avatar-hibou-constellation.png` | Constellation |
| 17 | `avatar-hibou-etoile.png` | Etoile |
| 18 | `avatar-hibou-comete.png` | Comete |
| 19 | `avatar-hibou-orbite.png` | Orbite |
| 20 | `avatar-hibou-galaxie.png` | Galaxie |

## Hiboux supporters

| # | Fichier | Nom |
|---:|---|---|
| 21 | `avatar-hibou-echarpe.png` | Echarpe |
| 22 | `avatar-hibou-tambour.png` | Tambour |
| 23 | `avatar-hibou-tribune.png` | Tribune |
| 24 | `avatar-hibou-ultra.png` | Ultra |
| 25 | `avatar-hibou-drapeau.png` | Drapeau |
| 26 | `avatar-hibou-chant.png` | Chant |
| 27 | `avatar-hibou-stade.png` | Stade |
| 28 | `avatar-hibou-kop.png` | Kop |
| 29 | `avatar-hibou-tifo.png` | Tifo |
| 30 | `avatar-hibou-fumigene.png` | Fumigene |

## Hiboux football

| # | Fichier | Nom |
|---:|---|---|
| 31 | `avatar-hibou-buteur.png` | Buteur |
| 32 | `avatar-hibou-gardien.png` | Gardien |
| 33 | `avatar-hibou-coach.png` | Coach |
| 34 | `avatar-hibou-arbitre.png` | Arbitre |
| 35 | `avatar-hibou-capitaine.png` | Capitaine |
| 36 | `avatar-hibou-meneur.png` | Meneur |
| 37 | `avatar-hibou-defenseur.png` | Defenseur |
| 38 | `avatar-hibou-ailier.png` | Ailier |
| 39 | `avatar-hibou-numero10.png` | Numero10 |
| 40 | `avatar-hibou-remplacant.png` | Remplacant |

## Hiboux champions

| # | Fichier | Nom |
|---:|---|---|
| 41 | `avatar-hibou-coupe.png` | Coupe |
| 42 | `avatar-hibou-medaille.png` | Medaille |
| 43 | `avatar-hibou-champion.png` | Champion |
| 44 | `avatar-hibou-finale.png` | Finale |
| 45 | `avatar-hibou-podium.png` | Podium |
| 46 | `avatar-hibou-victoire.png` | Victoire |
| 47 | `avatar-hibou-etoile-or.png` | Etoile Or |
| 48 | `avatar-hibou-trophee.png` | Trophee |
| 49 | `avatar-hibou-legende.png` | Legende |
| 50 | `avatar-hibou-dynastie.png` | Dynastie |

## Hiboux humoristiques

| # | Fichier | Nom |
|---:|---|---|
| 51 | `avatar-hibou-casserole.png` | Casserole |
| 52 | `avatar-hibou-poele.png` | Poele |
| 53 | `avatar-hibou-boulet.png` | Boulet |
| 54 | `avatar-hibou-perdu.png` | Perdu |
| 55 | `avatar-hibou-endormi.png` | Endormi |
| 56 | `avatar-hibou-retard.png` | Retard |
| 57 | `avatar-hibou-var.png` | Var |
| 58 | `avatar-hibou-carton.png` | Carton |
| 59 | `avatar-hibou-zero.png` | Zero |
| 60 | `avatar-hibou-mauvaise-foi.png` | Mauvaise Foi |

## Hiboux mystérieux

| # | Fichier | Nom |
|---:|---|---|
| 61 | `avatar-hibou-masque.png` | Masque |
| 62 | `avatar-hibou-ombre.png` | Ombre |
| 63 | `avatar-hibou-fantome.png` | Fantome |
| 64 | `avatar-hibou-secret.png` | Secret |
| 65 | `avatar-hibou-oracle.png` | Oracle |
| 66 | `avatar-hibou-prophete.png` | Prophete |
| 67 | `avatar-hibou-mage.png` | Mage |
| 68 | `avatar-hibou-alchimiste.png` | Alchimiste |
| 69 | `avatar-hibou-sorcier.png` | Sorcier |
| 70 | `avatar-hibou-enigme.png` | Enigme |

## Hiboux futuristes

| # | Fichier | Nom |
|---:|---|---|
| 71 | `avatar-hibou-neon.png` | Neon |
| 72 | `avatar-hibou-cyber.png` | Cyber |
| 73 | `avatar-hibou-hologramme.png` | Hologramme |
| 74 | `avatar-hibou-quantique.png` | Quantique |
| 75 | `avatar-hibou-electrique.png` | Electrique |
| 76 | `avatar-hibou-plasma.png` | Plasma |
| 77 | `avatar-hibou-vector.png` | Vector |
| 78 | `avatar-hibou-digital.png` | Digital |
| 79 | `avatar-hibou-android.png` | Android |
| 80 | `avatar-hibou-cosmos.png` | Cosmos |

## Hiboux rares

| # | Fichier | Nom |
|---:|---|---|
| 81 | `avatar-hibou-cristal.png` | Cristal |
| 82 | `avatar-hibou-diamant.png` | Diamant |
| 83 | `avatar-hibou-obsidienne.png` | Obsidienne |
| 84 | `avatar-hibou-rubis.png` | Rubis |
| 85 | `avatar-hibou-emeraude.png` | Emeraude |
| 86 | `avatar-hibou-opale.png` | Opale |
| 87 | `avatar-hibou-titane.png` | Titane |
| 88 | `avatar-hibou-platine.png` | Platine |
| 89 | `avatar-hibou-arcane.png` | Arcane |
| 90 | `avatar-hibou-aurora.png` | Aurora |

### Extension avatars 2026-08-28

La bibliothèque conserve les 90 Hiboux historiques et ajoute **168 avatars** rangés dans des sous-dossiers :

- `clubs/ligue-1/` — 18 avatars de clubs français ;
- `clubs/europe/` — 18 grands clubs européens ;
- `clubs/stade-brestois/` — 12 variantes spéciales Brest ;
- `humour/` — 120 avatars répartis en Apéro, Tribune, Canapé, Arbitrage, Victoire, Poisse, BBQ, Déguisements, Café & PMU et Personnages.

Le chemin de fichier est porté par `avatar-catalog.json` : une clé d’avatar n’est donc plus obligatoirement située directement à la racine de `assets/avatars/nid/`.

**Total : 168 avatars.**

### Statut V0.5.3

**DONE — les 168 PNG sont livrés** dans `assets/avatars/nid/` et référencés par `assets/avatars/avatar-catalog.json`. Ils sont utilisés par le sélecteur du Profil. Les uploads personnels ne remplacent pas cette bibliothèque : ils sont stockés séparément dans le bucket Supabase `player-avatars` et soumis à modération Admin.

# 8. Badges — 100 PNG

Convention : `badge-<classe>-<slug>.png`

## ⚪ Communs

Dossier : `assets/badges/common/`

| # | Fichier | Nom | Description |
|---:|---|---|---|
| 1 | `badge-common-premier-envol.png` | **Premier envol** | Enregistrer son premier pronostic. |
| 2 | `badge-common-premiers-points.png` | **Premiers points** | Marquer ses premiers points. |
| 3 | `badge-common-premier-exact.png` | **Dans le mille** | Trouver son premier score exact. |
| 4 | `badge-common-journee-complete.png` | **Carnet rempli** | Compléter tous les pronostics d'une journée UEFA. |
| 5 | `badge-common-premiere-team.png` | **Bienvenue dans la Team** | Rejoindre sa première team. |
| 6 | `badge-common-premier-duel.png` | **Premier duel** | Gagner son premier duel contre son rival. |
| 7 | `badge-common-premiere-casserole.png` | **Ça commence bien** | Recevoir sa première casserole. |
| 8 | `badge-common-premier-genie.png` | **Éclair de génie** | Obtenir son premier coup de génie. |
| 9 | `badge-common-premier-hibou-solitaire.png` | **Hibou solitaire** | Réussir son premier choix très minoritaire. |
| 10 | `badge-common-premier-record.png` | **Petit record** | Détenir son premier mini-record. |
| 11 | `badge-common-cinq-pronos.png` | **On prend le rythme** | Enregistrer 5 pronostics. |
| 12 | `badge-common-dix-pronos.png` | **Le carnet chauffe** | Enregistrer 10 pronostics. |
| 13 | `badge-common-vingt-pronos.png` | **Habitué du Nid** | Enregistrer 20 pronostics. |
| 14 | `badge-common-trois-bons-resultats.png` | **Bonne lecture** | Trouver 3 bons résultats sur une même soirée. |
| 15 | `badge-common-deux-exacts.png` | **Double vision** | Trouver 2 scores exacts dans une même journée. |
| 16 | `badge-common-sans-oubli-soiree.png` | **Présent !** | Ne rien oublier sur une soirée complète. |
| 17 | `badge-common-premiere-remontee.png` | **Ça remonte** | Gagner au moins 3 places au classement. |
| 18 | `badge-common-premier-top10.png` | **Top 10** | Entrer pour la première fois dans le Top 10. |
| 19 | `badge-common-premier-top5.png` | **Top 5** | Entrer pour la première fois dans le Top 5. |
| 20 | `badge-common-premier-podium.png` | **Première plume sur le podium** | Entrer pour la première fois sur le podium. |

## 🔵 Rares

Dossier : `assets/badges/rare/`

| # | Fichier | Nom | Description |
|---:|---|---|---|
| 21 | `badge-rare-dix-exacts.png` | **Sniper** | Cumuler 10 scores exacts sur la saison. |
| 22 | `badge-rare-vingt-bons-ecarts.png` | **Compas dans l'œil** | Cumuler 20 bons écarts. |
| 23 | `badge-rare-serie-cinq-points.png` | **Série propre** | Marquer des points sur 5 matchs consécutifs. |
| 24 | `badge-rare-serie-dix-points.png` | **Métronome** | Marquer des points sur 10 matchs consécutifs. |
| 25 | `badge-rare-trois-exacts-soiree.png` | **Triple impact** | Trouver 3 scores exacts sur une soirée. |
| 26 | `badge-rare-cinq-journees-completes.png` | **Assidu** | Compléter 5 journées UEFA sans oubli. |
| 27 | `badge-rare-dix-journees-completes.png` | **Fidèle au poste** | Compléter 10 journées/soirées sans oubli. |
| 28 | `badge-rare-top3-trois-fois.png` | **Habitué du podium** | Terminer 3 soirées dans le Top 3. |
| 29 | `badge-rare-leader-une-fois.png` | **Chef du Nid** | Prendre la tête du classement au moins une fois. |
| 30 | `badge-rare-leader-sept-jours.png` | **Une semaine au sommet** | Rester leader 7 jours cumulés. |
| 31 | `badge-rare-remontee-dix.png` | **Ascenseur express** | Gagner 10 places sur une journée. |
| 32 | `badge-rare-aucun-zero-soiree.png` | **Soirée sans trou** | Marquer sur tous les matchs d'une soirée. |
| 33 | `badge-rare-outsider-reussi.png` | **Le flair** | Trouver une victoire très minoritaire. |
| 34 | `badge-rare-hibou-solitaire-3.png` | **Solitaire confirmé** | Réussir 3 Hiboux solitaires. |
| 35 | `badge-rare-genie-50.png` | **Cerveau en fusion** | Atteindre 50 points de génie. |
| 36 | `badge-rare-casserole-50.png` | **Cuisine ouverte** | Atteindre 50 points de casserole. |
| 37 | `badge-rare-rival-5.png` | **Bête noire** | Battre son rival 5 soirées. |
| 38 | `badge-rare-team-top3.png` | **Team sur le podium** | Faire partie d'une team dans le Top 3. |
| 39 | `badge-rare-precision-60.png` | **Œil sûr** | Atteindre 60 % de bons résultats sur une période significative. |
| 40 | `badge-rare-aucun-oubli-phase.png` | **Phase complète** | Ne manquer aucun prono d'une phase entière. |

## 🟣 Épiques

Dossier : `assets/badges/epic/`

| # | Fichier | Nom | Description |
|---:|---|---|---|
| 41 | `badge-epic-quatre-exacts-journee.png` | **Quatre à la suite** | Trouver 4 scores exacts sur une journée UEFA. |
| 42 | `badge-epic-leader-trente-jours.png` | **Trône occupé** | Cumuler 30 jours en tête. |
| 43 | `badge-epic-top3-dix-soirees.png` | **Abonné au podium** | Finir 10 soirées dans le Top 3. |
| 44 | `badge-epic-remontee-quinze.png` | **Remontada** | Gagner au moins 15 places en une journée. |
| 45 | `badge-epic-hibou-solitaire-10.png` | **Seul contre presque tous** | Réussir 10 Hiboux solitaires. |
| 46 | `badge-epic-genie-150.png` | **Génie européen** | Atteindre 150 points de génie. |
| 47 | `badge-epic-casserole-150.png` | **Chef étoilé… autrement** | Atteindre 150 points de casserole. |
| 48 | `badge-epic-exact-finale.png` | **Finaliste visionnaire** | Trouver le score exact de la finale. |
| 49 | `badge-epic-qualifies-parfaits-phase.png` | **Tableau limpide** | Trouver tous les qualifiés d'une phase donnée. |
| 50 | `badge-epic-phase-top1.png` | **Roi d'une phase** | Terminer premier d'une phase complète. |
| 51 | `badge-epic-serie-20-points.png` | **Inarrêtable** | Marquer sur 20 matchs consécutifs. |
| 52 | `badge-epic-precision-70.png` | **Chirurgical** | Atteindre 70 % de bons résultats sur une période significative. |
| 53 | `badge-epic-rival-10.png` | **Némésis** | Battre son rival 10 fois. |
| 54 | `badge-epic-team-champion-phase.png` | **Team dominante** | Faire partie de la meilleure team sur une phase. |
| 55 | `badge-epic-cinq-exacts-semaine.png` | **Semaine magique** | Trouver 5 scores exacts sur une même semaine UEFA. |
| 56 | `badge-epic-outsider-3.png` | **Flair insolent** | Réussir 3 gros outsiders. |
| 57 | `badge-epic-podium-50-jours.png` | **Installé là-haut** | Cumuler 50 jours sur le podium. |
| 58 | `badge-epic-aucun-oubli-long.png` | **Mémoire de fer** | Ne rien oublier pendant une très longue période. |
| 59 | `badge-epic-double-champion-vivant.png` | **Double espoir** | Avoir encore ses deux choix champion en course très tard dans la saison. |
| 60 | `badge-epic-hibou-nuit-5.png` | **Noctambule d'élite** | Être Hibou de la nuit 5 fois. |

## 🟡 Légendaires

Dossier : `assets/badges/legendary/`

| # | Fichier | Nom | Description |
|---:|---|---|---|
| 61 | `badge-legendary-prophete.png` | **Le Prophète** | Trouver 5 scores exacts lors d'une même journée UEFA. |
| 62 | `badge-legendary-seul-contre-le-nid.png` | **Seul contre le Nid** | Être l'unique joueur à choisir un vainqueur et avoir raison. |
| 63 | `badge-legendary-nid-tappartient.png` | **Le Nid t'appartient** | Cumuler 100 jours en tête du classement. |
| 64 | `badge-legendary-nuit-parfaite.png` | **Nuit parfaite** | Marquer sur tous les matchs d'une grande soirée avec plusieurs scores exacts. |
| 65 | `badge-legendary-oracle-europeen.png` | **Oracle européen** | Enchaîner plusieurs résultats très improbables correctement. |
| 66 | `badge-legendary-immortel.png` | **Immortel** | Compléter plusieurs saisons sans abandonner de pronostics. |
| 67 | `badge-legendary-champion-nid.png` | **Champion du Nid** | Remporter le classement général d'une saison. |
| 68 | `badge-legendary-double-champion.png` | **Double champion** | Remporter deux saisons du Nid. |
| 69 | `badge-legendary-triple-champion.png` | **Dynastie** | Remporter trois saisons. |
| 70 | `badge-legendary-exact-finale-x4.png` | **L'œil du trophée** | Trouver le score exact de la finale avec multiplicateur maximal actif. |
| 71 | `badge-legendary-100-exacts-carriere.png` | **Cent impacts** | Atteindre 100 scores exacts en carrière. |
| 72 | `badge-legendary-500-pronos-sans-oubli.png` | **Machine à pronos** | Enregistrer 500 pronostics sans oubli de journée. |
| 73 | `badge-legendary-hibou-solitaire-impossible.png` | **Contre l'univers** | Réussir un choix unique sur un résultat extrêmement improbable. |
| 74 | `badge-legendary-genie-500.png` | **Cerveau légendaire** | Atteindre 500 points de génie. |
| 75 | `badge-legendary-poele-or.png` | **Poêle d'Or** | Finir premier du classement casserole d'une saison. |
| 76 | `badge-legendary-invincible-rival.png` | **Rivalité à sens unique** | Battre son rival 15 fois consécutivement. |
| 77 | `badge-legendary-team-dynastie.png` | **Dynastie de Team** | Gagner plusieurs saisons avec la même team. |
| 78 | `badge-legendary-top3-toute-saison.png` | **Jamais descendu** | Rester dans le Top 3 pendant toute une saison après y être entré. |
| 79 | `badge-legendary-champion-allin.png` | **All-in parfait** | Choisir deux fois le même champion et le voir gagner. |
| 80 | `badge-legendary-grand-chelem.png` | **Grand Chelem du Nid** | Cumuler plusieurs grandes distinctions majeures sur une même saison. |

## 🕵️ Secrets

Dossier : `assets/badges/secret/`

| # | Fichier | Nom | Description |
|---:|---|---|---|
| 81 | `badge-secret-derniere-seconde.png` | **???** | Modifier un prono dans les 10 dernières secondes avant verrouillage. |
| 82 | `badge-secret-om-par-defaut.png` | **???** | Laisser le Nid choisir Marseille comme champion par défaut. |
| 83 | `badge-secret-quinze-zero.png` | **???** | Oser un pronostic 15-0 ou plus. |
| 84 | `badge-secret-zero-partout.png` | **???** | Réaliser une soirée complète à zéro point. |
| 85 | `badge-secret-casserole-mauvaise-foi.png` | **???** | Recevoir une casserole manuelle pour mauvaise foi. |
| 86 | `badge-secret-hibou-masque-contact.png` | **???** | Écrire au Hibou masqué dans une circonstance particulière. |
| 87 | `badge-secret-retour-de-nulle-part.png` | **???** | Réaliser une remontée extrêmement improbable. |
| 88 | `badge-secret-var-maudit.png` | **???** | Rater plusieurs pronostics sur des événements tardifs. |
| 89 | `badge-secret-90plus.png` | **???** | Perdre plusieurs scores exacts à cause de buts très tardifs. |
| 90 | `badge-secret-team-traitre.png` | **???** | Changer de team dans une circonstance historique ou amusante. |
| 91 | `badge-secret-capitaine-abandonne.png` | **???** | Transmettre son capitanat dans une circonstance particulière. |
| 92 | `badge-secret-faux-prophete.png` | **???** | Faire un pronostic extravagant qui échoue spectaculairement. |
| 93 | `badge-secret-tout-le-monde-a-tort.png` | **???** | Participer à une catastrophe collective massive. |
| 94 | `badge-secret-tout-le-monde-a-raison.png` | **???** | Participer à une prédiction collective presque unanime et correcte. |
| 95 | `badge-secret-hibou-insomniaque.png` | **???** | Interagir avec le Nid à une heure improbable lors d'une soirée européenne. |
| 96 | `badge-secret-pile-ou-face.png` | **???** | Enchaîner une séquence statistique improbable. |
| 97 | `badge-secret-exact-maudit.png` | **???** | Accumuler plusieurs scores à un but près de l'exact. |
| 98 | `badge-secret-sept-zero.png` | **???** | Rencontrer une condition liée à un score extrême. |
| 99 | `badge-secret-fantome-du-nid.png` | **???** | Revenir après une longue absence et marquer immédiatement fort. |
| 100 | `badge-secret-secret-ultime.png` | **???** | Condition exceptionnelle gardée secrète par le Super Admin. |

**Total : 100 badges.**

### Direction visuelle

- Commun : argent / bleu, halo discret.
- Rare : bleu électrique.
- Épique : violet profond et effets stellaires.
- Légendaire : or / blanc, effets nettement plus spectaculaires.
- Secret : identité masquée jusqu'au déblocage.

Asset générique avant découverte : `assets/badges/secret/badge-secret-locked.png`

# 9. Trophées

| Fichier | Nom | Usage |
|---|---|---|
| `assets/trophies/trophee-champion-saison.png` | **Champion du Nid** | Vainqueur du général. |
| `assets/trophies/trophee-podium-or.png` | **Trophée Or** | 1re place. |
| `assets/trophies/trophee-podium-argent.png` | **Trophée Argent** | 2e place. |
| `assets/trophies/trophee-podium-bronze.png` | **Trophée Bronze** | 3e place. |
| `assets/trophies/trophee-team.png` | **Trophée Team** | Meilleure team. |
| `assets/trophies/trophee-hibou-nuit.png` | **Hibou de la nuit** | Meilleur joueur d'une soirée. |
| `assets/trophies/trophee-genie.png` | **Trophée Génie** | Meilleur score de génie. |
| `assets/trophies/trophee-poele-or.png` | **Poêle d'Or** | Champion des casseroles. |
| `assets/trophies/trophee-hibou-solitaire.png` | **Hibou solitaire** | Meilleur score solitaire. |
| `assets/trophies/trophee-record.png` | **Record du Nid** | Record majeur. |
| `assets/trophies/trophee-hall-of-fame.png` | **Hall of Fame** | Distinction historique. |
| `assets/trophies/trophee-champion-en-titre.png` | **Champion en titre** | Affichage saison suivante. |
| `assets/trophies/trophee-cdm-2026.png` | **Champion Coupe du monde 2026** | Héritage du Nid des Pronos. |
| `assets/trophies/trophee-carriere.png` | **Trophée Carrière** | Palmarès multi-saisons. |

# 10. Formes de Team

- `assets/teams/shapes/shape-diagonal.png` — Diagonale
- `assets/teams/shapes/shape-wave.png` — Vague
- `assets/teams/shapes/shape-chevron.png` — Chevron
- `assets/teams/shapes/shape-burst.png` — Éclat
- `assets/teams/shapes/shape-stripes.png` — Rayures
- `assets/teams/shapes/shape-hexagons.png` — Hexagones
- `assets/teams/shapes/shape-star.png` — Étoile
- `assets/teams/shapes/shape-feather.png` — Plume

Les formes sont blanches/alpha puis teintées dynamiquement par l'application.

# 11. Logos Team par défaut

- `assets/teams/default/team-default-01.png`
- `assets/teams/default/team-default-02.png`
- `assets/teams/default/team-default-03.png`
- `assets/teams/default/team-default-04.png`
- `assets/teams/default/team-default-05.png`
- `assets/teams/default/team-default-06.png`
- `assets/teams/default/team-default-07.png`
- `assets/teams/default/team-default-08.png`
- `assets/teams/default/team-default-09.png`
- `assets/teams/default/team-default-10.png`
- `assets/teams/default/team-default-11.png`
- `assets/teams/default/team-default-12.png`

# 12. PDF / Collector

- `assets/reports/report-bg-cover.png` — Couverture
- `assets/reports/report-bg-profile.png` — Profil
- `assets/reports/report-bg-ranking.png` — Classements
- `assets/reports/report-bg-badges.png` — Badges
- `assets/reports/report-bg-records.png` — Records
- `assets/reports/report-bg-casseroles.png` — Casseroles
- `assets/reports/report-bg-hall-of-fame.png` — Hall of Fame
- `assets/reports/report-bg-diploma-landscape.png` — Diplôme
- `assets/reports/report-decoration-stars.png` — Étoiles
- `assets/reports/report-decoration-owl.png` — Hibou

> Les fonds PDF doivent être créés directement au ratio A4 portrait/paysage.

# 13. Statuts de production

- `TODO` : à créer
- `WIP` : en cours
- `DONE` : validé et présent
- `REWORK` : à retravailler
- `DEPRECATED` : destiné à disparaître

# 14. Manifest machine

**DONE en V0.5.3** : `assets/assets-manifest.json` centralise la version, le branding principal, les icônes PWA, les **168 avatars officiels**, le catalogue et les contraintes du bucket `player-avatars`.

```json
{
  "avatars": {
    "hibou-royal": "assets/avatars/nid/avatar-hibou-royal.png"
  },
  "badges": {
    "premier-envol": "assets/badges/common/badge-common-premier-envol.png"
  },
  "clubs": {
    "psg": "assets/clubs/ucl/club-psg.png"
  }
}
```

# 15. Checklist obligatoire à chaque version

- [ ] Nouveaux PNG rangés dans le bon dossier
- [ ] Noms conformes
- [ ] `docs/ASSETS_MANIFEST.md` mis à jour
- [ ] `README.md` mis à jour si une nouvelle famille/fonction apparaît
- [ ] `CHANGELOG.md` mis à jour
- [ ] Aucun asset orphelin
- [ ] Aucun chemin cassé
- [ ] Affichage mobile vérifié
- [ ] Poids des PNG contrôlé

**Le manifeste doit évoluer en même temps que le produit.**

## V0.2.0 — Logos clubs automatiques
Les logos de clubs peuvent être synchronisés via football-data.org puis stockés dans le bucket Supabase `club-logos`. `assets/clubs/ucl/` est réservé aux overrides manuels.
