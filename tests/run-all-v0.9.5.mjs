import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename=fileURLToPath(import.meta.url);
const root=path.resolve(path.dirname(__filename),"..");
const args=process.argv.slice(2);
const urlArg=args.find(a=>a.startsWith("--url="));
const baseUrl=urlArg?urlArg.slice(6).replace(/\/+$/,""):null;
const checks=[];
const add=(id,status,message,details="")=>checks.push({id,status,message,...(details?{details}:{})});
const need=(id,ok,msg,details="")=>add(id,ok?"PASS":"FAIL",msg,details);
const warn=(id,ok,msg,details="")=>add(id,ok?"PASS":"WARN",msg,details);
const exists=rel=>fs.existsSync(path.join(root,rel));
const read=rel=>exists(rel)?fs.readFileSync(path.join(root,rel),"utf8"):"";
const contains=(rel,...tokens)=>tokens.every(t=>read(rel).includes(t));

const required=[
  "VERSION","config.js","config.example.js","index.html","sw.js","assets/assets-manifest.json",
  "css/career.css","css/admin.css","css/admin095.css",
  "js/core.js","js/data.js","js/profile.js","js/career.js","js/admin.js","js/admin095.js","js/app.js","js/auth.js","js/realtime.js",
  "sql/025_patch_v0.9.0_season_career_memory.sql","sql/026_patch_v0.9.5_admin_hardening.sql","sql/HOTFIX_V0.9.5_EXISTING_DB.sql","sql/000_INSTALL_FRESH_V0.9.5.sql",
  "tests/test-center-v0.9.5.html","docs/TEST_CHECKLIST_V0.9.5.md","docs/TEST_MATRIX_V0.9.5.md",
  "INSTALLATION_V0.9.5.txt","PATCH_NOTES_V0.9.5.txt","README_TEST_SYSTEM_V0.9.5.md"
];
for(const rel of required)need("file:"+rel,exists(rel),exists(rel)?`Présent: ${rel}`:`Absent: ${rel}`);

need("version.file",read("VERSION").trim()==="0.9.5",`VERSION = ${read("VERSION").trim()||"absent"} (attendu 0.9.5)`);
need("version.config",contains("config.js",'APP_VERSION: "0.9.5"'),"config.js annonce 0.9.5");
need("version.config-example",contains("config.example.js",'APP_VERSION: "0.9.5"'),"config.example.js annonce 0.9.5");
need("version.cache",contains("sw.js","nid-champions-v0.9.5"),"Cache Service Worker V0.9.5");
need("version.assets",contains("assets/assets-manifest.json",'"version": "0.9.5"'),"Manifest des assets V0.9.5");
need("front.095-assets",contains("index.html","css/admin095.css","js/admin095.js"),"UI Admin V0.9.5 branchée dans index.html");
need("sw.095-assets",contains("sw.js","./css/admin095.css","./js/admin095.js"),"Service Worker pré-cache les assets Admin V0.9.5");
need("front.090-preserved",contains("index.html","css/career.css","js/career.js","seasonMemoryRoot","profileCareerRoot","adminSeasonManagementPanel"),"Fonctions V0.9.0 conservées");

const admin95=read("js/admin095.js");
for(const [id,token,msg] of [
  ["ux.command-search","adminGlobalSearchV095","Recherche globale Admin"],
  ["ux.ctrl-k","e.ctrlKey||e.metaKey","Raccourci Ctrl/Cmd+K"],
  ["ux.slash-shortcut",'e.key==="/"',"Raccourci /"],
  ["ux.health","renderAdminHealthV095","Centre d’action du Dashboard"],
  ["ux.quick-actions","renderAdminQuickActionsV095","Actions rapides Admin"],
  ["ux.settings","renderAdminSettingsV095","Réglages regroupés"],
  ["ux.backups","renderAdminBackupsV095","Gestion des sauvegardes"],
  ["ux.exports","renderAdminExportsV095","Exports Admin"],
  ["ux.audit","renderAdminAuditV095","Journal d’audit paginé"],
  ["ux.preview","renderAdminImpersonationV095","Aperçu joueur lecture seule"],
  ["ux.deletion","renderAdminDeletionV095","Traitement demandes suppression"],
  ["ux.privacy","renderAccountPrivacyV095","Demande de suppression côté joueur"],
  ["ux.network","networkBannerV095","Bandeau réseau"],
  ["ux.maintenance","maintenanceOverlayV095","Écran Maintenance"],
  ["ux.flags","applyFeatureFlagsV095","Feature flags appliqués au front"],
  ["ux.registration","registrationOpenV095","Ouverture/fermeture inscriptions"]
]) need(id,admin95.includes(token),msg);

need("ux.command-count",(admin95.match(/\["[^\n]+","[^\n]+","(?:matches|competition|players|teams|gamification|communication|application|test)"/g)||[]).length>=25,"Recherche Admin indexe au moins 25 actions");
need("ux.search-help",admin95.includes("Aucune option trouvée")&&admin95.includes("sauvegarde")&&admin95.includes("C1"),"Recherche Admin donne des exemples si aucun résultat");
need("ux.readonly-preview",admin95.includes("Lecture seule")&&admin95.includes("aucune action n’est exécutée"),"Aperçu joueur explicitement non destructif");
need("ux.restore-maintenance",admin95.includes('if(!boolSetting("maintenance",false))')&&admin95.includes('Tape RESTAURER'),"Restauration protégée par Maintenance + confirmation");
need("ux.csv-bom",admin95.includes("\\ufeff")||admin95.includes("﻿"),"Exports CSV prévoient l’encodage Excel/accents");

const admin=read("js/admin.js");
need("admin.pagination",admin.includes("pageSize=25")&&admin.includes("adminPlayersPrevV095")&&admin.includes("adminPlayersNextV095"),"Liste joueurs paginée à 25");
need("admin.search-page-reset",admin.includes("state.adminPlayerPage=0")&&admin.includes("adminPlayerSearch"),"Recherche joueur revient en page 1");
need("admin.render-095",admin.includes("renderAdmin095")&&admin.includes("loadAdmin095Data"),"Cockpit V0.9.5 intégré au rendu Admin");

const index=read("index.html");
for(const [id,token,msg] of [
  ["html.search","adminGlobalSearchV095","Champ Trouver une option"],
  ["html.health","adminHealthV095","Zone état du Nid"],
  ["html.quick","adminQuickActionsV095","Zone raccourcis"],
  ["html.preview","adminImpersonationPanelV095","Zone aperçu joueur"],
  ["html.deletions","adminDeletionPanelV095","Zone suppressions"],
  ["html.settings","adminSettingsPanelV095","Zone réglages"],
  ["html.backups","adminBackupPanelV095","Zone sauvegardes"],
  ["html.exports","adminExportPanelV095","Zone exports"],
  ["html.audit","adminAuditPanelV095","Zone audit"],
  ["html.privacy","accountPrivacyPanelV095","Zone confidentialité profil"]
]) need(id,index.includes(token),msg);
need("html.nav-groups",["Pilotage","Communauté","Technique","Système & sécurité","Joueurs & accès","Contenu & Musée","Laboratoire"].every(t=>index.includes(t)),"Navigation Admin regroupée et renommée");

const css=read("css/admin095.css");
need("css.mobile",css.includes("@media")&&css.includes("admin-quick-grid-v095"),"Responsive Admin V0.9.5");
need("css.reduced-motion",css.includes("prefers-reduced-motion"),"Respect prefers-reduced-motion");
need("css.forced-colors",css.includes("forced-colors"),"Compatibilité forced-colors");
need("css.search",css.includes("admin-search-v095")&&css.includes("admin-search-results-v095"),"Palette de recherche stylée");
need("css.network",css.includes("network-banner-v095")&&css.includes("maintenance-overlay-v095"),"États réseau/maintenance stylés");

const sql90=read("sql/025_patch_v0.9.0_season_career_memory.sql");
for(const [id,token,msg] of [
  ["db090.rank-history","public.player_rank_history","Historique du rang V0.9.0 conservé"],
  ["db090.world-cup","admin_set_world_cup_winner_v090","Vainqueur Coupe du monde conservé"],
  ["db090.career","get_player_career_v090","Carrière multi-saisons conservée"],
  ["db090.hall","get_hall_of_fame_v090","Hall of Fame conservé"],
  ["db090.replay","get_season_replay_v090","Replay conservé"],
  ["db090.archive","season_is_writable_v090","Archives lecture seule conservées"]
]) need(id,sql90.includes(token),msg);
need("db090.position-fix",sql90.includes('category text,"position" integer'),"Correctif SQL du mot réservé position conservé");

const sql95=read("sql/026_patch_v0.9.5_admin_hardening.sql");
for(const [id,token,msg] of [
  ["db095.backup-table","public.admin_backups_v095","Table sauvegardes"],
  ["db095.delete-table","public.account_deletion_requests_v095","Table demandes suppression"],
  ["db095.setting-rpc","admin_set_app_setting_v095","RPC réglages"],
  ["db095.dashboard-rpc","admin_dashboard_v095","RPC Dashboard"],
  ["db095.audit-rpc","admin_audit_v095","RPC audit"],
  ["db095.preview-rpc","admin_player_preview_v095","RPC aperçu joueur"],
  ["db095.preview-log","admin_log_impersonation_v095","Journalisation aperçu joueur"],
  ["db095.backup-create","admin_create_backup_v095","Création sauvegarde"],
  ["db095.backup-restore","admin_restore_backup_v095","Restauration sauvegarde"],
  ["db095.backup-delete","admin_delete_backup_v095","Suppression sauvegarde"],
  ["db095.delete-request","request_account_deletion_v095","Demande suppression joueur"],
  ["db095.delete-process","admin_process_account_deletion_v095","Traitement suppression Admin"],
  ["db095.diagnostic","admin_diagnostics_v095","Diagnostic SQL V0.9.5"]
]) need(id,sql95.includes(token),msg);

for(const key of ["registration_open","maintenance","feature_rivals","feature_polls","feature_api","feature_solitary_owl","feature_gamification","feature_teams"])
  need("setting:"+key,sql95.includes(`'${key}'`),`Réglage ${key}`);

need("db095.setting-whitelist",sql95.includes("p_key not in")&&sql95.includes("Réglage non autorisé"),"Liste blanche des réglages côté SQL");
need("db095.rls-backups",sql95.includes("alter table public.admin_backups_v095 enable row level security")&&sql95.includes("public.is_super_admin()"),"RLS Super Admin sur sauvegardes");
need("db095.rls-deletions",sql95.includes("alter table public.account_deletion_requests_v095 enable row level security")&&sql95.includes("user_id=auth.uid() or public.is_admin()"),"RLS demandes suppression");
need("db095.unique-open-request",sql95.includes("create unique index account_deletion_requests_v095_open_uidx")&&sql95.includes("status in ('requested','reviewing')"),"Une seule demande de suppression ouverte par joueur");
need("db095.restore-confirm",sql95.includes("p_confirmation <> 'RESTAURER'"),"Confirmation serveur pour restauration");
need("db095.backup-schema",sql95.includes("'schema_version','0.9.5'"),"Snapshots versionnés 0.9.5");
for(const token of ["'team_join_requests'","'team_invites'","'gamification_settings'","'monthly_polls'","'monthly_poll_candidates'","'monthly_poll_votes'","'polls'","'ucl_matches'","'ucl_standings'"])
  need("backup:"+token.replace(/[^a-z_]/gi,""),sql95.includes(token),`Sauvegarde contient ${token.replaceAll("'","")}`);
need("db095.transaction",(/^\s*begin;/m.test(sql95)&&(sql95.match(/\ncommit;\s*/g)||[]).length>=2),"Migration V0.9.5 encapsulée dans des transactions");
need("db095.app-version",sql95.includes("'app_version','\"0.9.5\"'::jsonb"),"Version backend mise à 0.9.5");

const hotfix=read("sql/HOTFIX_V0.9.5_EXISTING_DB.sql");
need("sql.hotfix-sync",hotfix===sql95,"HOTFIX V0.9.5 identique au patch SQL validé");
const fresh=read("sql/000_INSTALL_FRESH_V0.9.5.sql");
need("sql.fresh-090",fresh.includes("get_player_career_v090")&&fresh.includes('category text,"position" integer'),"Installation fraîche contient la V0.9.0 corrigée");
need("sql.fresh-095",fresh.includes("admin_restore_backup_v095")&&fresh.includes("admin_diagnostics_v095"),"Installation fraîche contient le durcissement V0.9.5");

const auth=read("js/auth.js"), data=read("js/data.js"), app=read("js/app.js");
need("front.registration-guard",auth.includes("registrationOpenV095")&&auth.includes("Les inscriptions sont temporairement fermées"),"Inscription protégée par le réglage V0.9.5");
need("front.admin-data-login",auth.includes("loadAdmin095Data(true)"),"Données Admin chargées après connexion Admin");
need("front.settings-load",data.includes("loadPublicAppSettingsV095"),"Réglages globaux chargés avec les données");
need("front.privacy-render",app.includes("renderAccountPrivacyV095"),"Confidentialité rendue dans le profil");
need("front.flags-render",app.includes("applyFeatureFlagsV095"),"Feature flags réappliqués au rendu");

const edge=read("supabase/functions/sync-football-data/index.ts");
need("fd.081-preserved",edge.includes("season_not_available")&&edge.includes("footballDataStatus"),"Correctif Football-Data V0.8.1 conservé");
need("fd.no-fallback-2025",!(/fallback[^\n]{0,140}2025/i.test(edge)),"Aucun fallback explicite vers 2025/26 détecté");
need("fd.strict-season",edge.includes("sourceSeasonYear"),"Synchronisation Football-Data reste pilotée par la saison source");

const matrix=read("docs/TEST_MATRIX_V0.9.5.md");
const ids=[...matrix.matchAll(/\*\*(T\d{4})\*\*/g)].map(m=>m[1]);
need("tests.matrix-count",ids.length===1490,`Matrice: ${ids.length} contrôles (attendu 1490)`);
need("tests.matrix-unique",new Set(ids).size===ids.length,"IDs de la matrice uniques");
need("tests.matrix-last",ids.at(-1)==="T1490",`Dernier contrôle: ${ids.at(-1)||"absent"} (attendu T1490)`);
need("tests.center-count",(read("tests/test-center-v0.9.5.html").match(/"id":"T\d{4}"/g)||[]).length===1490,"Centre web contient 1490 tests manuels");
need("tests.windows-safe",read("tests/run-all-v0.9.5.mjs").includes("fileURLToPath(import.meta.url)"),"Runner compatible chemins Windows");
need("tests.center-v095-diagnostic",contains("tests/test-center-v0.9.5.html","admin_diagnostics_v095","v095.settings","v095.backups"),"Centre web inclut les diagnostics V0.9.5");

const staleCurrent=["index.html","config.js","config.example.js","sw.js","assets/assets-manifest.json","js/admin095.js"].filter(rel=>{
  const t=read(rel);return /APP_VERSION:\s*"0\.9\.0"/.test(t)||/nid-champions-v0\.9\.0/.test(t)||/"version":\s*"0\.9\.0"/.test(t);
});
need("version.no-stale-current",staleCurrent.length===0,"Aucune référence de version courante V0.9.0 résiduelle",staleCurrent.join(", "));

if(baseUrl){
  const remote=async rel=>{try{const r=await fetch(`${baseUrl}/${rel}`,{cache:"no-store"});return {ok:r.ok,status:r.status,text:r.ok?await r.text():""};}catch(e){return {ok:false,status:0,text:"",error:String(e)}}};
  const remoteChecks=[
    ["VERSION",t=>t.trim()==="0.9.5"],
    ["config.js",t=>t.includes('APP_VERSION: "0.9.5"')],
    ["sw.js",t=>t.includes("nid-champions-v0.9.5")&&t.includes("./js/admin095.js")&&t.includes("./css/admin095.css")],
    ["index.html",t=>t.includes("js/admin095.js")&&t.includes("css/admin095.css")&&t.includes("adminGlobalSearchV095")],
    ["js/admin095.js",t=>t.includes("renderAdminHealthV095")&&t.includes("admin_restore_backup_v095")],
    ["css/admin095.css",t=>t.includes("admin-search-v095")&&t.includes("prefers-reduced-motion")]
  ];
  for(const [rel,fn] of remoteChecks){const r=await remote(rel);add("remote:"+rel,r.ok&&fn(r.text)?"PASS":"FAIL",r.ok?`Déployé et conforme: ${rel}`:`Impossible/non conforme: ${rel} (HTTP ${r.status||0})`,r.error||"");}
}

const summary={total:checks.length,passed:checks.filter(x=>x.status==="PASS").length,warnings:checks.filter(x=>x.status==="WARN").length,failed:checks.filter(x=>x.status==="FAIL").length};
const report={version:"0.9.5",generated_at:new Date().toISOString(),base_url:baseUrl,summary,checks};
fs.writeFileSync(path.join(root,"tests","test-report-v0.9.5.json"),JSON.stringify(report,null,2)+"\n");
for(const c of checks)console.log(`${c.status.padEnd(4)} ${c.id} — ${c.message}${c.details?` · ${c.details}`:""}`);
console.log(`\nRésumé V0.9.5: ${summary.passed} PASS · ${summary.warnings} WARN · ${summary.failed} FAIL / ${summary.total}`);
console.log("Rapport: tests/test-report-v0.9.5.json");
if(summary.failed)process.exitCode=1;
