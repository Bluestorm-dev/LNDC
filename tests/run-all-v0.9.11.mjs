import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename=fileURLToPath(import.meta.url);
const root=path.resolve(path.dirname(__filename),"..");
const args=process.argv.slice(2);
const urlArg=args.find(a=>a.startsWith("--url="));
const baseUrl=urlArg?urlArg.slice(6).replace(/\/+$/,"" ):null;
const checks=[];
const add=(id,status,message,details="")=>checks.push({id,status,message,...(details?{details}:{})});
const need=(id,ok,msg,details="")=>add(id,ok?"PASS":"FAIL",msg,details);
const exists=rel=>fs.existsSync(path.join(root,rel));
const read=rel=>exists(rel)?fs.readFileSync(path.join(root,rel),"utf8"):"";
const contains=(rel,...tokens)=>tokens.every(t=>read(rel).includes(t));

const required=[
  "VERSION","config.js","config.example.js","index.html","sw.js","assets/assets-manifest.json",
  "css/career.css","css/admin095.css","css/finale098.css","css/final-report098.css","css/preseason099.css",
  "js/core.js","js/data.js","js/profile.js","js/career.js","js/admin.js","js/admin095.js","js/finale098.js","js/final-report098.js","js/preseason099.js","js/app.js","js/auth.js","js/realtime.js",
  "finale.html","diplome.html",
  "sql/025_patch_v0.9.0_season_career_memory.sql","sql/026_patch_v0.9.5_admin_hardening.sql","sql/027_patch_v0.9.8_finale_pdf.sql","sql/028_patch_v0.9.9_preseason.sql","sql/HOTFIX_V0.9.9_EXISTING_DB.sql","sql/000_INSTALL_FRESH_V0.9.9.sql",
  "tests/test-center-v0.8.1.html","tests/test-center-v0.9.0.html","tests/test-center-v0.9.5.html","tests/test-center-v0.9.8.html","tests/test-center-v0.9.9.html","tests/road-check-v0.9.9.html",
  "docs/TEST_CHECKLIST_V0.9.9.md","docs/TEST_MATRIX_V0.9.9.md",
  "INSTALLATION_V0.9.9.txt","PATCH_NOTES_V0.9.9.txt","README_TEST_SYSTEM_V0.9.9.md",
  "css/preprod0910.css","js/preprod0910.js","assets/data/ucl-2026-27-official.json",
  "sql/029_patch_v0.9.10_preprod_safety.sql","sql/HOTFIX_V0.9.10_EXISTING_DB.sql","sql/000_INSTALL_FRESH_V0.9.10.sql",
  "tests/test-center-v0.9.10.html","docs/TEST_CHECKLIST_V0.9.10.md","docs/TEST_MATRIX_V0.9.10.md",
  "INSTALLATION_V0.9.10.txt","PATCH_NOTES_V0.9.10.txt","README_TEST_SYSTEM_V0.9.10.md",
  "sql/HOTFIX_V0.9.10_R3_ADMIN_CALENDAR_ODDS.sql",
  "css/release0911.css","js/release0911.js",
  "sql/030_patch_v0.9.11_betclic_feature_gates.sql","sql/HOTFIX_V0.9.11_EXISTING_DB.sql","sql/000_INSTALL_FRESH_V0.9.11.sql",
  "supabase/functions/sync-betclic-odds/index.ts",
  "tests/test-center-v0.9.11.html","docs/TEST_CHECKLIST_V0.9.11.md","docs/TEST_MATRIX_V0.9.11.md",
  "INSTALLATION_V0.9.11.txt","PATCH_NOTES_V0.9.11.txt","README_TEST_SYSTEM_V0.9.11.md"
];
for(const rel of required)need("file:"+rel,exists(rel),exists(rel)?`Présent: ${rel}`:`Absent: ${rel}`);

// Release / cache / intégration.
need("version.file",read("VERSION").trim()==="0.9.11",`VERSION = ${read("VERSION").trim()||"absent"} (attendu 0.9.11)`);
need("version.config",contains("config.js",'APP_VERSION: "0.9.11"'),"config.js annonce 0.9.11");
need("version.config-example",contains("config.example.js",'APP_VERSION: "0.9.11"'),"config.example.js annonce 0.9.11");
need("version.cache",contains("sw.js","nid-champions-v0.9.11"),"Cache Service Worker V0.9.11");
need("version.assets",contains("assets/assets-manifest.json",'"version": "0.9.11"'),"Manifest des assets V0.9.11");
need("front.098-assets",contains("index.html","css/finale098.css","js/finale098.js","seasonFinaleRootV098","adminFinalSeasonPanelV098"),"UI Fin de saison V0.9.9 branchée dans index.html");
need("front.report-pages",contains("finale.html","js/final-report098.js")&&contains("diplome.html","js/final-report098.js"),"Pages Collector et diplôme branchées");
need("sw.098-assets",["./css/finale098.css","./css/final-report098.css","./js/finale098.js","./js/final-report098.js","./finale.html","./diplome.html"].every(t=>read("sw.js").includes(t)),"Service Worker pré-cache la fin de saison V0.9.9");
need("assets.098-manifest",["finale098.css","final-report098.css","finale098.js","final-report098.js","finale.html","diplome.html"].every(t=>read("assets/assets-manifest.json").includes(t)),"Manifest d'assets référence les composants V0.9.9");

// Régressions importantes.
const sql90=read("sql/025_patch_v0.9.0_season_career_memory.sql");
const sql95=read("sql/026_patch_v0.9.5_admin_hardening.sql");
const admin95=read("js/admin095.js");
for(const [id,ok,msg] of [
  ["preserve.090.multiseason",sql90.includes("admin_set_active_season_v090")&&sql90.includes("season_is_writable_v090"),"Multi-saisons V0.9.0 conservé"],
  ["preserve.090.career",sql90.includes("get_player_career_v090")&&sql90.includes("get_player_season_profile_v090"),"Carrière V0.9.0 conservée"],
  ["preserve.090.hall",sql90.includes("get_hall_of_fame_v090")&&sql90.includes("get_season_replay_v090"),"Hall of Fame et Replay conservés"],
  ["preserve.090.worldcup",sql90.includes("admin_set_world_cup_winner_v090"),"Vainqueur Coupe du monde conservé"],
  ["preserve.090.position",sql90.includes('category text,"position" integer'),"Correctif SQL du mot réservé position conservé"],
  ["preserve.095.backups",sql95.includes("admin_create_backup_v095")&&sql95.includes("admin_restore_backup_v095"),"Sauvegardes V0.9.5 conservées"],
  ["preserve.095.security",sql95.includes("admin_set_app_setting_v095")&&sql95.includes("public.is_super_admin()"),"Durcissement V0.9.5 conservé"],
  ["preserve.095.ux",admin95.includes("adminGlobalSearchV095")&&admin95.includes("renderAdminHealthV095"),"Cockpit Admin V0.9.5 conservé"]
]) need(id,ok,msg);

const edge=read("supabase/functions/sync-football-data/index.ts");
need("fd.081-preserved",edge.includes("season_not_available")&&edge.includes("footballDataStatus"),"Correctif Football-Data V0.8.1 conservé");
need("fd.no-fallback-2025",!(/fallback[^\n]{0,140}2025/i.test(edge)),"Aucun fallback explicite vers 2025/26 détecté");
need("fd.strict-season",edge.includes("sourceSeasonYear"),"Synchronisation Football-Data reste pilotée par la saison source");

// Module fin de saison.
const finalJs=read("js/finale098.js"), reportJs=read("js/final-report098.js"), reportCss=read("css/final-report098.css"), finalCss=read("css/finale098.css"), index=read("index.html"), app=read("js/app.js"), career=read("js/career.js");
for(const [id,token,msg] of [
  ["front.final.load","loadFinalSeasonDataV098","Chargement état de clôture"],
  ["front.final.hub","renderFinalSeasonHubV098","Hub Fin de saison"],
  ["front.final.guestbook","save_guestbook_entry_v098","Livre d'or côté joueur"],
  ["front.final.admin","renderAdminFinaleV098","Panneau Admin fin de saison"],
  ["front.final.export","get_final_season_report_v098","Export global JSON"],
  ["front.final.archive","admin_archive_season_v098","Archivage définitif"],
  ["front.final.confirm",'prompt("Cette action fige la saison. Tape ARCHIVER',"Confirmation explicite ARCHIVER"],
  ["front.final.moderation","admin_set_guestbook_status_v098","Modération Livre d'or"]
]) need(id,finalJs.includes(token),msg);
need("front.final.render-hook",app.includes("renderFinalSeasonHubV098")&&app.includes("renderAdminFinaleV098"),"V0.9.9 intégrée au rendu général");
need("front.final.season-reset",career.includes("resetFinalSeasonDataV098"),"Changement de saison réinitialise la fin de saison");
need("front.final.links",index.includes('href="tests/test-center-v0.9.11.html"')&&index.includes("1 940 contrôles")&&index.includes('href="tests/test-center-v0.9.10.html"')&&index.includes('href="tests/test-center-v0.9.9.html"'),"Admin pointe vers le Centre V0.9.11 et conserve les centres historiques");
need("front.final.test-history",["test-center-v0.8.1.html","test-center-v0.9.0.html","test-center-v0.9.5.html","test-center-v0.9.9.html"].every(t=>index.includes(t)),"Historique des centres de tests accessible dans Admin");
need("front.final.search",admin95.includes('0.9.9')&&admin95.includes('["Fin de saison & PDF"'),"Recherche Admin indexe V0.9.9 et Fin de saison & PDF");
need("front.final.mobile",finalCss.includes("@media"),"Hub fin de saison responsive");
need("print.a4",reportCss.includes("@page")&&reportCss.includes("A4"),"Styles d'impression A4 présents");
need("print.landscape",reportCss.includes("landscape"),"Diplôme A4 paysage prévu");
need("print.hide-toolbar",reportCss.includes("@media print")&&reportCss.includes(".report-toolbar"),"Barre web masquée à l'impression");
for(const [id,token,msg] of [
  ["report.season","get_final_season_report_v098","Collector utilise le rapport saison"],
  ["report.player","get_final_player_report_v098","Carnet utilise le rapport joueur"],
  ["report.print","window.print","Impression navigateur / PDF disponible"],
  ["report.collector","renderSeason","Rendu Collector saison"],
  ["report.replay-subtitle","e.subtitle||e.description","Texte Replay V0.9.0 repris dans le Collector"],
  ["report.personal","renderPlayer","Rendu carnet personnel"],
  ["report.diploma","diploma","Rendu diplôme"],
  ["report.batch-diplomas",'params.get("all")==="1"',"Export de tous les diplômes"],
  ["report.superadmin",'me.role!=="super_admin"',"Tous les diplômes réservés au Super Admin"]
]) need(id,reportJs.includes(token),msg);

// SQL V0.9.9.
const sql98=read("sql/027_patch_v0.9.8_finale_pdf.sql");
for(const [id,token,msg] of [
  ["db098.guestbook-table","public.season_guestbook_entries_v098","Table Livre d'or"],
  ["db098.archive-table","public.season_final_archives_v098","Table archive finale"],
  ["db098.guestbook-read","get_guestbook_v098","RPC lecture Livre d'or"],
  ["db098.guestbook-save","save_guestbook_entry_v098","RPC écriture Livre d'or"],
  ["db098.guestbook-moderate","admin_set_guestbook_status_v098","RPC modération Livre d'or"],
  ["db098.readiness","get_season_closeout_readiness_v098","RPC préparation clôture"],
  ["db098.season-report","get_final_season_report_v098","RPC rapport saison"],
  ["db098.player-report","get_final_player_report_v098","RPC rapport joueur"],
  ["db098.build-archive","admin_create_final_archive_v098","RPC construction archive"],
  ["db098.final-archive","admin_archive_season_v098","RPC archivage définitif"],
  ["db098.archive-meta","get_final_archive_meta_v098","RPC métadonnées archive"],
  ["db098.diagnostic","admin_diagnostics_v098","Diagnostic V0.9.8"]
]) need(id,sql98.includes(token),msg);
need("db098.guestbook-length",sql98.includes("between 2 and 500"),"Livre d'or limité à 2–500 caractères");
need("db098.guestbook-unique",sql98.includes("unique(season_id,user_id)"),"Une contribution Livre d'or par joueur et saison");
need("db098.guestbook-rls",sql98.includes("enable row level security")&&sql98.includes("season_guestbook_v098_read"),"RLS Livre d'or activée");
need("db098.archive-rls",sql98.includes("season_final_archives_v098_read"),"RLS archive finale activée");
need("db098.no-email",!(/email/i.test(sql98)),"Aucune adresse e-mail n'est incluse dans le rapport final V0.9.8");
need("db098.test-exclusion",sql98.includes("coalesce(is_test,false)=false")&&sql98.includes("not pb.is_test")&&sql98.includes("not r.is_test"),"Données TEST exclues des statistiques finales");
need("db098.superadmin",sql98.includes("if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'"),"Archivage protégé côté serveur par rôle Super Admin");
need("db098.confirm",sql98.includes("p_confirmation<>'ARCHIVER'"),"Confirmation ARCHIVER contrôlée côté serveur");
need("db098.hash",sql98.includes("md5(payload::text)"),"Snapshot final possède un hash");
need("db098.replay-fields",sql98.includes("order by x.event_at,x.event_type")&&!sql98.includes("x.event_key"),"Rapport Replay utilise uniquement les colonnes V0.9.0 existantes");
need("db098.archived-snapshot",sql98.includes("status='archived'")&&sql98.includes("select a.snapshot into result"),"Une saison archivée relit son snapshot final figé");
need("db098.audit",sql98.includes("season_final_archive")&&sql98.includes("season_archive_final")&&sql98.includes("guestbook_"),"Actions sensibles V0.9.8 journalisées");
need("db098.archive-readonly",sql98.includes("status='archived'")&&sql98.includes("is_active=false"),"Clôture passe la saison en archive inactive");
need("db098.transaction",/^\s*begin;/m.test(sql98)&&/\ncommit;\s*$/m.test(sql98),"Migration V0.9.8 encapsulée dans une transaction");
need("db098.app-version",sql98.includes("'app_version','\"0.9.8\"'::jsonb"),"Version backend V0.9.8 présente dans son patch historique");
need("db098.position-safe",!(/category text,\s*position integer/.test(sql98)),"Aucune régression du mot réservé position dans V0.9.8");
const hotfix98=read("sql/HOTFIX_V0.9.8_EXISTING_DB.sql");
need("sql098.hotfix-sync",hotfix98===sql98,"HOTFIX V0.9.8 historique identique à son patch SQL");
const fresh98=read("sql/000_INSTALL_FRESH_V0.9.9.sql");
need("sql098.fresh-090",fresh98.includes("get_player_career_v090")&&fresh98.includes('category text,"position" integer'),"Installation fraîche conserve la V0.9.0 corrigée");
need("sql098.fresh-095",fresh98.includes("admin_restore_backup_v095")&&fresh98.includes("admin_diagnostics_v095"),"Installation fraîche contient le durcissement V0.9.5");
need("sql098.fresh-098",fresh98.includes("admin_archive_season_v098")&&fresh98.includes("season_guestbook_entries_v098"),"Installation fraîche contient V0.9.8");
need("sql099.fresh",fresh98.includes("admin_create_preseason_run_v099")&&fresh98.includes("admin_diagnostics_v099"),"Installation fraîche contient V0.9.9");

// Centre de tests et documentation.

// V0.9.9 — répétition générale.
const sql99=read("sql/028_patch_v0.9.9_preseason.sql"), pre99=read("js/preseason099.js"), preCss=read("css/preseason099.css"), idx99=read("index.html");
need("sql099.hotfix-sync",read("sql/HOTFIX_V0.9.9_EXISTING_DB.sql")===sql99,"HOTFIX V0.9.9 identique au patch SQL validé");
for(const [id,token,msg] of [
  ["db099.run-table","preseason_runs_v099","Table de scénarios pré-saison"],
  ["db099.virtual-players","preseason_virtual_players_v099","Joueurs virtuels isolés"],
  ["db099.virtual-matches","preseason_virtual_matches_v099","Matchs virtuels isolés"],
  ["db099.virtual-predictions","preseason_virtual_predictions_v099","Pronostics virtuels isolés"],
  ["db099.virtual-teams","preseason_virtual_teams_v099","Teams virtuelles isolées"],
  ["db099.load","admin_preseason_load_test_v099","Test de charge"],
  ["db099.cleanup","admin_cleanup_preseason_v099","Nettoyage confirmé"],
  ["db099.onboarding","user_onboarding_v099","Progression onboarding"],
  ["db099.diagnostic","admin_diagnostics_v099","Diagnostic V0.9.9"],
  ["db099.owl","v099_onboarding_welcome","Textes Hibou V0.9.9"]
]) need(id,sql99.includes(token),msg);
need("db099.isolation",!sql99.includes("insert into public.predictions")&&!sql99.includes("insert into public.matches")&&!sql99.includes("insert into public.profiles"),"Bac à sable sans insertion dans matches/predictions/profiles");
need("db099.superadmin",sql99.includes("if not public.is_super_admin() then raise exception"),"RPC de répétition protégés côté serveur");
need("db099.cleanup-confirm",sql99.includes("p_confirmation<>'NETTOYER'"),"Nettoyage exige NETTOYER");
need("front099.assets",idx99.includes("css/preseason099.css")&&idx99.includes("js/preseason099.js")&&idx99.includes("adminPreseasonPanelV099"),"UI pré-saison branchée");
need("front099.admin",pre99.includes("renderAdminPreseasonV099")&&pre99.includes("admin_create_preseason_run_v099"),"Cockpit répétition générale");
need("front099.steps",["live","scores","champion","teams","badges","notifications","finale","pdf","complete"].every(x=>pre99.includes(`[\"${x}\"`)||pre99.includes(`["${x}"`)),"Étapes de répétition couvertes");
need("front099.onboarding",pre99.includes("openTutorialV099")&&pre99.includes("tutorialSteps")&&pre99.includes("const q=(s,root=document)=>root.querySelector(s)"),"Tutoriel V0.9.9 intégré et boutons correctement ciblés");
need("front099.mobile",preCss.includes("@media")&&preCss.includes("tutorial-overlay-v099"),"Pré-saison / tutoriel responsive");
need("front099.roadcheck",idx99.includes("tests/road-check-v0.9.9.html")&&contains("tests/road-check-v0.9.9.html","24 missions guidées"),"Grand road-check V1 accessible");
need("front099.testcenter",idx99.includes("tests/test-center-v0.9.9.html")&&contains("tests/test-center-v0.9.9.html","V0.9.9"),"Centre de tests V0.9.9 accessible");
need("sw099.assets",contains("sw.js","./css/preseason099.css","./js/preseason099.js"),"Service Worker pré-cache V0.9.9");
need("assets099.manifest",contains("assets/assets-manifest.json","preseason099.css","preseason099.js","road-check-v0.9.9.html"),"Manifest référence les assets V0.9.9");

// V0.9.10 — sécurisation pré-production.
const sql10=read("sql/029_patch_v0.9.10_preprod_safety.sql");
const pre10=read("js/preprod0910.js");
const fixture10=JSON.parse(read("assets/data/ucl-2026-27-official.json")||"{}");
const fixtureRows=Array.isArray(fixture10.fixtures)?fixture10.fixtures:[];
need("v0910.fixture.count",fixtureRows.length===144,"Calendrier UEFA intégré: 144 matchs");
const byDay=new Map();const appearances=new Map();const pairs=new Set();
for(const f of fixtureRows){byDay.set(Number(f.matchday),(byDay.get(Number(f.matchday))||0)+1);for(const n of [f.home,f.away])appearances.set(n,(appearances.get(n)||0)+1);pairs.add([f.home,f.away].sort().join("::"));}
need("v0910.fixture.days",[1,2,3,4,5,6,7,8].every(d=>byDay.get(d)===18),"Calendrier UEFA: 8 journées × 18");
need("v0910.fixture.clubs",appearances.size===36&&[...appearances.values()].every(n=>n===8),"Calendrier UEFA: 36 clubs × 8 matchs");
need("v0910.fixture.unique",pairs.size===144,"Calendrier UEFA: aucune affiche dupliquée");
need("v0910.sql.manual-lock",sql10.includes("manual_schedule_lock")&&sql10.includes("manual_metadata_lock"),"SQL protège les corrections manuelles matchs + clubs");
need("v0910.sql.seed",sql10.includes("admin_seed_official_calendar_v0910")&&sql10.includes("exactement 144 matchs"),"RPC de chargement du calendrier officiel");
need("v0910.sql.champion",sql10.includes("club_catalog_memberships")&&sql10.includes("season_start_year_v0910")&&sql10.includes("champion_first_close_at_v040"),"Champion 1 disponible depuis le catalogue C1 avant calendrier fournisseur");
need("v0910.sql.reset",sql10.includes("admin_prelaunch_reset_v0910")&&sql10.includes("RESET AVANT OUVERTURE")&&sql10.includes("delete from public.player_badges")&&sql10.includes("delete from public.season_guestbook_entries_v098")&&sql10.includes("delete from public.season_final_archives_v098"),"Reset pré-production sécurisé et traces de recette finales nettoyées");
need("v0910.sql.hotfix-sync",read("sql/HOTFIX_V0.9.10_EXISTING_DB.sql")===sql10,"HOTFIX V0.9.10 identique au patch SQL validé");
need("v0910.sql.fresh",read("sql/000_INSTALL_FRESH_V0.9.10.sql").includes("admin_prelaunch_reset_v0910")&&read("sql/000_INSTALL_FRESH_V0.9.10.sql").includes("app_version','\"0.9.10\"'"),"Installation fraîche contient la V0.9.10");
need("v0910.front.admin",pre10.includes("seedOfficialCalendarV0910")&&pre10.includes("openClubEditorV0910")&&pre10.includes("openMatchScheduleEditorV0910"),"UI Admin calendrier/équipes/matchs manuels");
need("v0910.front.reset",pre10.includes("openPrelaunchResetV0910")&&index.includes("prelaunchResetBtnV0910"),"UI reset avant ouverture");
need("v0910.fd.partial",edge.includes("Un lot partiel")&&!edge.includes("leagueMatches.length !== EXPECTED_LEAGUE_MATCHES"),"Football-Data accepte les lots partiels");
need("v0910.fd.no-delete",!edge.includes("staleIds")&&!edge.includes("expectedExternalIds"),"Un lot partiel Football-Data ne supprime aucun match local");
need("v0910.fd.pair",edge.includes("matchedByPair")&&edge.includes("home_club_id"),"Rapprochement calendrier local ↔ Football-Data par affiche");
need("v0910.fd.club-lock",edge.includes("manual_metadata_lock")&&edge.includes("provider_metadata_updated_at"),"Métadonnées club manuelles protégées");
need("v0910.ui.clean",!read("js/ucl.js").includes("Migration V0.8.0")&&!read("js/evenings.js").includes("🗳️ V0.8.0")&&!read("js/evenings.js").includes("Migration V0.8.0 requise")&&!read("js/gamification.js").includes("Migration V0.7.0 absente"),"Numéros de version techniques retirés des surfaces visibles Centre C1 / Soirées / Musée");
need("v0910.manual-create-lock",read("js/admin.js").includes('schedule_source:"manual"')&&read("js/admin.js").includes("manual_schedule_lock:true"),"Les matchs créés manuellement sont verrouillés contre l’écrasement fournisseur");
const badgeCat=JSON.parse(read("assets/badges/badge-catalog.json")||"{}");
need("v0910.badges100",Number(badgeCat.count)===100&&Array.isArray(badgeCat.items)&&badgeCat.items.length===100,"Les 100 succès intégrés sont conservés");

// V0.9.10 R3 — gestion calendrier par journée, cotes manuelles et robustesse fournisseur.
const hotfixR3=read("sql/HOTFIX_V0.9.10_R3_ADMIN_CALENDAR_ODDS.sql");
need("v0910r3.matchday-editor",pre10.includes("openMatchdayEditorV0910")&&pre10.includes("data-edit-matchday-v0910")&&pre10.includes("data-edit-match-v0910"),"Les 8 journées ouvrent une liste de matchs modifiables");
need("v0910r3.manual-odds-front",pre10.includes("Cotes 1N2 manuelles")&&pre10.includes("admin_update_match_odds_v0910")&&pre10.includes("saveOddsV0910"),"Saisie manuelle 1/N/2 intégrée à l’éditeur de match");
need("v0910r3.manual-odds-sql",hotfixR3.includes("admin_update_match_odds_v0910")&&hotfixR3.includes("odds_provider='manual'")&&hotfixR3.includes("après le coup d''envoi"),"RPC cotes manuelles sécurisé avant coup d’envoi");
need("v0910r3.club-scope-front",pre10.includes("editableClubsV0910")&&pre10.includes("club_catalog_memberships")&&pre10.includes("metadata_source==='manual'"),"Sélecteur de clubs limité à la C1 + clubs créés manuellement");
need("v0910r3.club-scope-sql",hotfixR3.includes("competition_code='CL'")&&hotfixR3.includes("metadata_source='manual'")&&hotfixR3.includes("Seuls les clubs de la Ligue des champions"),"Restriction clubs également imposée côté serveur");
need("v0910r3.champion2-unlock",read("js/champions.js").includes("championSecondUnlockInfo")&&read("js/champions.js").includes("S'ouvre")&&read("js/champions.js").includes("dernière rencontre prévue"),"L’interface indique quand le deuxième choix Champion doit se déverrouiller");
need("v0910r3.provider-5xx",edge.includes("provider_unavailable")&&edge.includes("fdStatus >= 500")&&edge.includes("sync_internal_error")&&edge.includes("}, 200)"),"Les erreurs fournisseur/Function reviennent sous forme d’état métier exploitable par l’Admin");
need("v0910r3.odds-fallback-ui",read("js/admin.js").includes("saisie manuelle en secours")&&read("js/admin.js").includes("Football-Data")&&read("js/admin.js").includes("Betclic"),"Bouton Cotes 1N2 conserve le repli manuel après ajout de Betclic");

// V0.9.11 — Betclic expérimental + ouverture progressive.
const sql11=read("sql/030_patch_v0.9.11_betclic_feature_gates.sql");
const betclicEdge=read("supabase/functions/sync-betclic-odds/index.ts");
const release11=read("js/release0911.js");
const admin9511=read("js/admin095.js");
const realtime11=read("js/realtime.js");
need("v0911.betclic-edge",betclicEdge.includes("GetMatchesBySportWithNotifications")&&betclicEdge.includes("GetMatchWithNotification")&&betclicEdge.includes("ca_ftb_rslt"),"Edge Function Betclic gRPC-web présente et limitée au marché résultat");
need("v0911.betclic-no-secret",!betclicEdge.includes("BETCLIC_API_KEY")&&!betclicEdge.includes("password"),"Aucun secret/compte Betclic requis");
need("v0911.betclic-manual-preserved",betclicEdge.includes('String(m.odds_provider||"")!=="manual"'),"Les cotes manuelles sont protégées contre Betclic");
need("v0911.betclic-alias-aek",betclicEdge.includes("aek athens")&&betclicEdge.includes("pae aek"),"Alias AEK présents dans le rapprochement Betclic");
need("v0911r1.betclic-search-service",
  betclicEdge.includes("SearchMatchesWithNotifications")&&betclicEdge.includes("searchBetclic"),
  "Fallback SearchService Betclic présent quand les 400 premiers matchs ne suffisent pas"
);
need("v0911r1.betclic-targeted-search",
  betclicEdge.includes("preferredClubSearch"),
  "Recherche ciblée par club conservée ; la recherche compétition a été remplacée en R6"
);
need("v0911r1.betclic-diagnostics",
  betclicEdge.includes("searchQueries")&&betclicEdge.includes("searchReceived")&&betclicEdge.includes("discoveredFrom")&&release11.includes("Plage Betclic explorée"),
  "Diagnostic Betclic expose recherches ciblées et plage de dates"
);
need("v0911r2.betclic-season-scope",
  release11.includes("matchdayId:null")&&release11.includes("limit:50"),
  "La synchro Betclic Admin travaille par défaut sur toute la saison"
);
need("v0911r2.local-null-test-tolerated",
  betclicEdge.includes("m?.is_test!==true")&&betclicEdge.includes("allEligible"),
  "Les anciennes lignes is_test=NULL restent éligibles"
);
need("v0911r2.matchday-fallback",
  betclicEdge.includes("matchdayFallback")&&betclicEdge.includes("scopedEligible.length===0"),
  "Une journée vide retombe automatiquement sur la saison"
);
need("v0911r2.search-always",
  betclicEdge.includes("searchBetclic")&&betclicEdge.includes("preferredClubSearch"),
  "Le moteur de recherche Betclic reste actif ; R6 évite volontairement la requête compétition ambiguë"
);
need("v0911r2.local-diagnostics",
  release11.includes("match(s) locaux dans la saison")&&betclicEdge.includes("localSeasonRows")&&betclicEdge.includes("manualProtected"),
  "Le diagnostic expose les matchs locaux et les cotes manuelles protégées"
);
need("v0911r3.sync-no-400-feed",
  betclicEdge.includes('if(action==="probe")')&&betclicEdge.includes('mode:"search-only-batched"'),
  "La synchro Betclic n'analyse plus le flux général de 400 matchs"
);
need("v0911r3.detail-batch",
  betclicEdge.includes("DETAIL_BATCH_SIZE=4")&&betclicEdge.includes("pairsToProcess")&&betclicEdge.includes("deferred"),
  "Les marchés Betclic restent traités par petits lots, réduits à 4 en R6"
);
need("v0911r3.search-cap",
  betclicEdge.includes("FIXTURE_SEARCH_BATCH=4"),
  "La synchro limite les recherches Betclic à 4 fixtures par exécution"
);
need("v0911r3.upstream-cap",
  betclicEdge.includes("while(total<220000)"),
  "Les réponses gRPC Betclic sont plafonnées à environ 220 Ko"
);
need("v0911r3.http546-ui",
  release11.includes("HTTP 546")&&release11.includes("limite de ressources")&&release11.includes("lot suivant"),
  "L'Admin explique le 546 et la synchronisation par lots"
);
need("v0911r4.search-name-fallback",
  betclicEdge.includes("splitEventName")&&betclicEdge.includes("eventTeamPair")&&betclicEdge.includes("SearchService peut fournir uniquement"),
  "Le matcher sait lire Club A - Club B même sans objets teams"
);
need("v0911r4.provisional-date",
  betclicEdge.includes("eventDateCompatible")&&betclicEdge.includes("allowMissing=true"),
  "Une date absente dans SearchService n'empêche plus l'appariement provisoire"
);
need("v0911r4.strict-detail-validation",
  betclicEdge.includes("detailMatchesLocalStrict")&&betclicEdge.includes('status:"detail_mismatch"'),
  "Le détail Betclic est revalidé strictement avant toute écriture de cote"
);
need("v0911r4.detail-rejected-ui",
  release11.includes("rejeté(s) après vérification")&&betclicEdge.includes("detailRejected"),
  "L'Admin distingue appariements provisoires et rejets après détail"
);
need("v0911r5diag.search-diagnostics",
  betclicEdge.includes("diagnoseSearchEvent")&&betclicEdge.includes("searchDiagnosticCounts")&&betclicEdge.includes("searchDiagnosticRows"),
  "Le backend explique pourquoi les résultats Betclic ne sont pas rapprochés"
);
need("v0911r5diag.ui-details",
  release11.includes("Diagnostic Betclic du lot")&&release11.includes("Résultat hors fixture recherchée")&&release11.includes("écart(s) de date"),
  "L'Admin affiche toujours le diagnostic détaillé des résultats Betclic"
);
need("v0911r5diag.no-relaxed-write",
  betclicEdge.includes("detailMatchesLocalStrict")&&betclicEdge.includes('status:"detail_mismatch"'),
  "Le diagnostic n'assouplit pas la validation avant écriture"
);
need("v0911r6.fixture-search",
  betclicEdge.includes("FIXTURE_SEARCH_BATCH=4")&&betclicEdge.includes("pairFromPool([local],found,pairs,used,1)"),
  "La recherche Betclic part directement des fixtures C1 locales"
);
need("v0911r6.no-generic-champions-search",
  !betclicEdge.includes('for(const q of ["Ligue des Champions","Champions League"])'),
  "La recherche générique Ligue des Champions, ambiguë avec le hockey, est supprimée"
);
need("v0911r6.cursor",
  betclicEdge.includes("nextCursor")&&release11.includes("nidc_betclic_cursor_v0911"),
  "Un curseur fait tourner les lots de fixtures sans cote"
);
need("v0911r6.club-brugge-alias",
  betclicEdge.includes('"club brugge":["club bruges"')&&betclicEdge.includes('"club bruges":["club brugge"'),
  "Alias Club Brugge / Club Bruges ajouté"
);
need("v0911r6.resource-safe",
  betclicEdge.includes("DETAIL_BATCH_SIZE=4")&&betclicEdge.includes("FIXTURE_SEARCH_BATCH=4"),
  "Recherche et détails limités à quatre fixtures par exécution"
);
need("v0911r7.barcelona-alias",
  betclicEdge.includes('"barcelona":["barcelone"')&&betclicEdge.includes('"barcelone":["barcelona"'),
  "Alias Barcelona / Barcelone ajouté depuis le diagnostic réel"
);
need("v0911r7.fixture-centric-diagnostic",
  release11.includes("fixture(s) C1 du lot reconnue(s)")&&release11.includes("Résultat hors fixture recherchée"),
  "Le diagnostic distingue les fixtures C1 du bruit des résultats Betclic"
);
need("v0911.betclic-admin",release11.includes("Tester Betclic")&&release11.includes("Synchroniser Betclic")&&release11.includes("sync-betclic-odds"),"Panneau Admin Betclic branché");
need("v0911.betclic-fallback",release11.includes("saisie manuelle")&&release11.includes("source non officielle"),"UI rappelle le fallback manuel et le caractère expérimental");
need("v0911.feature-defaults",["feature_knockout:false","feature_ucl_center:false","feature_evenings:false","feature_teams:false","feature_gamification:false","feature_messages:false","feature_rivals:false","feature_polls:false","feature_solitary_owl:false"].every(t=>admin9511.includes(t)),"Fonctions optionnelles fermées aux joueurs par défaut");
need("v0911.feature-superadmin",admin9511.includes('state.profile?.role==="super_admin"')&&admin9511.includes("OUVERT")&&admin9511.includes("VERROUILLÉ"),"Super Admin conserve le bypass et voit l’état des fonctions");
need("v0911.feature-direct-guard",read("js/core.js").includes("featureViewAllowedV0911")&&read("js/core.js").includes("Cette fonction n’est pas encore ouverte aux joueurs"),"Accès direct à une vue verrouillée bloqué");
need("v0911.feature-messages",admin9511.includes("#notificationBell")&&admin9511.includes(".home-owl-card")&&admin9511.includes("#homePushPrompt"),"Gate Messages masque cloche, Hibou et Push");
need("v0911.feature-realtime",realtime11.includes('table:"app_settings"')&&realtime11.includes('queueRealtimeRefresh("settings")')&&realtime11.includes("applyFeatureFlagsV095"),"Feature gates propagés via Realtime");
need("v0911.settings-sql",["feature_knockout","feature_ucl_center","feature_evenings","feature_teams","feature_gamification","feature_messages","feature_rivals","feature_polls","feature_solitary_owl","feature_betclic_odds"].every(k=>sql11.includes("'"+k+"'")),"Tous les feature gates sont déclarés côté SQL");
need("v0911.message-purge",sql11.includes("admin_purge_messages_v0911")&&release11.includes("SUPPRIMER TOUS LES MESSAGES"),"Purge globale de communication disponible avec confirmation forte");
need("v0911.message-safe-delete",!(/delete\s+from\s+public\.[a-z0-9_]+\s*;/i.test(sql11)),"Aucun DELETE sans WHERE dans le patch V0.9.11");
need("v0911.message-preserve-push",!sql11.includes("delete from public.push_subscriptions"),"La purge ne supprime pas les abonnements Push");
need("v0911.reset-fixed",sql11.includes("delete from public.user_onboarding_v099 where user_id is not null"),"Reset pré-ouverture garde un WHERE explicite");
need("v0911.merge-rpc",sql11.includes("admin_merge_clubs_v0910")&&sql11.includes("drop function if exists public.admin_merge_clubs_v0910"),"RPC fusion de clubs réparée cumulativement");
need("v0911.modal-r4",!read("js/preprod0910.js").includes("root.remove()")&&read("js/core.js").includes('root.id = "modalRoot"'),"Correctif modales R4 conservé");
need("v0911.assets",contains("index.html","css/release0911.css","js/release0911.js","adminBetclicPanelV0911","adminMessageCleanupV0911")&&contains("sw.js","./css/release0911.css","./js/release0911.js"),"Assets V0.9.11 branchés et pré-cachés");
need("v0911.function-config",contains("supabase/config.toml","[functions.sync-betclic-odds]","verify_jwt = true"),"sync-betclic-odds protégée par JWT");
need("v0911.app-version-sql",sql11.includes("app_version")&&sql11.includes("0.9.11"),"Backend passe app_version à 0.9.11");
need("v0911.diagnostic",sql11.includes("admin_diagnostics_v0911"),"Diagnostic SQL V0.9.11 présent");
need("v0911.badges100",Number(badgeCat.count)===100&&badgeCat.items.length===100,"Les 100 succès restent intégrés");

const matrix=read("docs/TEST_MATRIX_V0.9.11.md");
const ids=[...matrix.matchAll(/\*\*(T\d{4})\*\*/g)].map(m=>m[1]);
need("tests.matrix-count",ids.length===1940,`Matrice: ${ids.length} contrôles (attendu 1940)`);
need("tests.matrix-unique",new Set(ids).size===ids.length,"IDs de la matrice uniques");
need("tests.matrix-last",ids.at(-1)==="T1940",`Dernier contrôle: ${ids.at(-1)||"absent"} (attendu T1940)`);
const center=read("tests/test-center-v0.9.11.html");
need("tests.center-count",(center.match(/"id":"T\d{4}"/g)||[]).length===1940,"Centre web contient 1940 tests manuels");
need("tests.center-version",center.includes("Centre de tests — V0.9.11")&&center.includes("Régression complète V0.1.x → V0.9.11")&&center.includes("cfg.APP_VERSION==='0.9.11'"),"Centre de tests V0.9.11 cohérent");
need("tests.center-diagnostic",center.includes("admin_diagnostics_v0911")&&center.includes("admin_diagnostics_v0910")&&center.includes("admin_diagnostics_v099")&&center.includes("v0910.calendar")&&center.includes("v099.runs")&&center.includes("v099.onboarding"),"Centre web exécute le diagnostic V0.9.11 et les diagnostics historiques");
need("tests.center-readiness-scope",!center.includes("p_season_id:season.id")&&center.includes("État de clôture non testé : aucune saison active lisible"),"Test readiness résout explicitement la saison active");
need("tests.center-v095-compat",center.includes("historicalVersionCheck")&&center.includes("backend courant"),"Diagnostic historique V0.9.5 tolère le backend courant sans masquer V0.9.11");
need("tests.center-current-release",
  center.includes("t=>t.trim()==='0.9.11'") &&
  center.includes("nid-champions-v0.9.11") &&
  center.includes("Cache Service Worker V0.9.11") &&
  center.includes("js/preseason099.js"),
  "Centre web contrôle réellement la release courante V0.9.11"
);
need("tests.center-v099-compat-r2",
  center.includes("x.test==='Version'") &&
  center.includes("app_settings.app_version") &&
  center.includes("backend courant 0.9.11"),
  "Diagnostic historique V0.9.9 tolère le backend courant V0.9.11"
);
need("ui.no-stale-public-099",
  !index.includes("Phases finales · V0.9.9") &&
  !index.includes("Le Nid est connecté</span><small>V0.9.9") &&
  !index.includes('<span class="eyebrow gold">V0.9.9</span>') &&
  !index.includes('<dd id="adminAppVersion">0.9.9</dd>'),
  "Aucun marquage V0.9.9 obsolète dans les surfaces visibles courantes"
);
need("tests.windows-safe",read("tests/run-all-v0.9.11.mjs").includes("fileURLToPath(import.meta.url)"),"Runner V0.9.11 compatible chemins Windows");
need("docs.checklist-count",(read("docs/TEST_CHECKLIST_V0.9.11.md").match(/\*\*[TX]\d{2,4}\*\*/g)||[]).length===40,"Checklist V0.9.11 contient 40 contrôles spécifiques");

// Vérifie qu’aucune surface courante V0.9.9 ne reste techniquement en V0.9.8.
const stale=[];
for(const rel of ["VERSION","config.js","config.example.js","sw.js","assets/assets-manifest.json","index.html","js/app.js","js/preseason099.js","js/preprod0910.js"]){
  const t=read(rel); if(/APP_VERSION\s*:\s*["']0\.9\.8/.test(t)||/nid-champions-v0\.9\.8/.test(t)||(/version courante/i.test(t)&&/0\.9\.8/.test(t))) stale.push(rel);
}
need("version.no-stale-current",stale.length===0,"Aucune référence technique obsolète dans les surfaces courantes V0.9.11",stale.join(", "));

if(baseUrl){
  const remote=async rel=>{try{const r=await fetch(`${baseUrl}/${rel}`,{cache:"no-store"});return {ok:r.ok,status:r.status,text:r.ok?await r.text():""};}catch(e){return {ok:false,status:0,text:"",error:String(e)}}};
  const remoteChecks=[
    ["VERSION",t=>t.trim()==="0.9.11"],
    ["config.js",t=>t.includes('APP_VERSION: "0.9.11"')],
    ["sw.js",t=>t.includes("nid-champions-v0.9.11")&&t.includes("./js/preseason099.js")&&t.includes("./js/preprod0910.js")&&t.includes("./js/release0911.js")],
    ["index.html",t=>t.includes("js/preseason099.js")&&t.includes("js/preprod0910.js")&&t.includes("js/release0911.js")&&t.includes("test-center-v0.9.11.html")&&t.includes("road-check-v0.9.9.html")],
    ["js/preseason099.js",t=>t.includes("renderAdminPreseasonV099")&&t.includes("openTutorialV099")],
    ["css/preseason099.css",t=>t.includes("preseason-layout-v099")&&t.includes("tutorial-overlay-v099")],
    ["js/preprod0910.js",t=>t.includes("renderPreprodSafetyV0910")&&t.includes("admin_seed_official_calendar_v0910")],
    ["assets/data/ucl-2026-27-official.json",t=>t.includes('"schema_version": "0.9.10"')&&t.includes('"matchday": 8')],
    ["tests/test-center-v0.9.11.html",t=>t.includes("Centre de tests — V0.9.11")&&t.includes('"id":"T1940"')&&t.includes("admin_diagnostics_v0911")],
    ["tests/road-check-v0.9.9.html",t=>t.includes("Grand road-check")&&t.includes("24 missions guidées")]
  ];
  for(const [rel,fn] of remoteChecks){const r=await remote(rel);add("remote:"+rel,r.ok&&fn(r.text)?"PASS":"FAIL",r.ok?`Déployé et conforme: ${rel}`:`Impossible/non conforme: ${rel} (HTTP ${r.status||0})`,r.error||"");}
}

need("v0910.r5.reset-where",
  read("sql/HOTFIX_V0.9.10_R5_RESET_CLUB_MERGE.sql").includes("delete from public.user_onboarding_v099 where user_id is not null"),
  "Reset pré-ouverture n'utilise plus de DELETE sans WHERE"
);
need("v0910.r5.club-merge",
  read("sql/HOTFIX_V0.9.10_R5_RESET_CLUB_MERGE.sql").includes("admin_merge_clubs_v0910") &&
  read("js/preprod0910.js").includes("clubMergeSourceV0910") &&
  read("js/preprod0910.js").includes("admin_merge_clubs_v0910"),
  "Fusion de doublons de clubs disponible dans l'Admin"
);
need("v0910.r5.aek-alias",
  read("js/preprod0910.js").includes('"aek athens":"pae aek"') &&
  read("supabase/functions/sync-football-data/index.ts").includes('"pae aek": ["aek athens", "aek athenes", "aek"]'),
  "AEK Athens/Athènes et PAE AEK sont rapprochés"
);
need("ui.modal-root-preserved-r4",
  !read("js/preprod0910.js").includes("root.remove()"),
  "Les éditeurs V0.9.10 ne suppriment jamais #modalRoot"
);


const summary={total:checks.length,passed:checks.filter(x=>x.status==="PASS").length,warnings:checks.filter(x=>x.status==="WARN").length,failed:checks.filter(x=>x.status==="FAIL").length};
const report={version:"0.9.11",generated_at:new Date().toISOString(),base_url:baseUrl,summary,checks};
fs.writeFileSync(path.join(root,"tests","test-report-v0.9.11.json"),JSON.stringify(report,null,2)+"\n");
for(const c of checks)console.log(`${c.status.padEnd(4)} ${c.id} — ${c.message}${c.details?` · ${c.details}`:""}`);
console.log(`\nRésumé V0.9.11: ${summary.passed} PASS · ${summary.warnings} WARN · ${summary.failed} FAIL / ${summary.total}`);
console.log("Rapport: tests/test-report-v0.9.11.json");
if(summary.failed)process.exitCode=1;
