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
  "css/career.css","css/admin095.css","css/finale098.css","css/final-report098.css",
  "js/core.js","js/data.js","js/profile.js","js/career.js","js/admin.js","js/admin095.js","js/finale098.js","js/final-report098.js","js/app.js","js/auth.js","js/realtime.js",
  "finale.html","diplome.html",
  "sql/025_patch_v0.9.0_season_career_memory.sql","sql/026_patch_v0.9.5_admin_hardening.sql","sql/027_patch_v0.9.8_finale_pdf.sql","sql/HOTFIX_V0.9.8_EXISTING_DB.sql","sql/000_INSTALL_FRESH_V0.9.8.sql",
  "tests/test-center-v0.8.1.html","tests/test-center-v0.9.0.html","tests/test-center-v0.9.5.html","tests/test-center-v0.9.8.html",
  "docs/TEST_CHECKLIST_V0.9.8.md","docs/TEST_MATRIX_V0.9.8.md",
  "INSTALLATION_V0.9.8.txt","PATCH_NOTES_V0.9.8.txt","README_TEST_SYSTEM_V0.9.8.md"
];
for(const rel of required)need("file:"+rel,exists(rel),exists(rel)?`Présent: ${rel}`:`Absent: ${rel}`);

// Release / cache / intégration.
need("version.file",read("VERSION").trim()==="0.9.8",`VERSION = ${read("VERSION").trim()||"absent"} (attendu 0.9.8)`);
need("version.config",contains("config.js",'APP_VERSION: "0.9.8"'),"config.js annonce 0.9.8");
need("version.config-example",contains("config.example.js",'APP_VERSION: "0.9.8"'),"config.example.js annonce 0.9.8");
need("version.cache",contains("sw.js","nid-champions-v0.9.8"),"Cache Service Worker V0.9.8");
need("version.assets",contains("assets/assets-manifest.json",'"version": "0.9.8"'),"Manifest des assets V0.9.8");
need("front.098-assets",contains("index.html","css/finale098.css","js/finale098.js","seasonFinaleRootV098","adminFinalSeasonPanelV098"),"UI Fin de saison V0.9.8 branchée dans index.html");
need("front.report-pages",contains("finale.html","js/final-report098.js")&&contains("diplome.html","js/final-report098.js"),"Pages Collector et diplôme branchées");
need("sw.098-assets",["./css/finale098.css","./css/final-report098.css","./js/finale098.js","./js/final-report098.js","./finale.html","./diplome.html"].every(t=>read("sw.js").includes(t)),"Service Worker pré-cache la fin de saison V0.9.8");
need("assets.098-manifest",["finale098.css","final-report098.css","finale098.js","final-report098.js","finale.html","diplome.html"].every(t=>read("assets/assets-manifest.json").includes(t)),"Manifest d'assets référence les composants V0.9.8");

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
need("front.final.render-hook",app.includes("renderFinalSeasonHubV098")&&app.includes("renderAdminFinaleV098"),"V0.9.8 intégrée au rendu général");
need("front.final.season-reset",career.includes("resetFinalSeasonDataV098"),"Changement de saison réinitialise la fin de saison");
need("front.final.links",index.includes('href="tests/test-center-v0.9.8.html"')&&index.includes("1 660 contrôles"),"Admin pointe vers le Centre de tests V0.9.8");
need("front.final.test-history",["test-center-v0.8.1.html","test-center-v0.9.0.html","test-center-v0.9.5.html","test-center-v0.9.8.html"].every(t=>index.includes(t)),"Historique des centres de tests accessible dans Admin");
need("front.final.search",admin95.includes('0.9.8')&&admin95.includes('["Fin de saison & PDF"'),"Recherche Admin indexe V0.9.8 et Fin de saison & PDF");
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

// SQL V0.9.8.
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
need("db098.app-version",sql98.includes("'app_version','\"0.9.8\"'::jsonb"),"Version backend mise à 0.9.8");
need("db098.position-safe",!(/category text,\s*position integer/.test(sql98)),"Aucune régression du mot réservé position dans V0.9.8");
const hotfix98=read("sql/HOTFIX_V0.9.8_EXISTING_DB.sql");
need("sql098.hotfix-sync",hotfix98===sql98,"HOTFIX V0.9.8 identique au patch SQL validé");
const fresh98=read("sql/000_INSTALL_FRESH_V0.9.8.sql");
need("sql098.fresh-090",fresh98.includes("get_player_career_v090")&&fresh98.includes('category text,"position" integer'),"Installation fraîche conserve la V0.9.0 corrigée");
need("sql098.fresh-095",fresh98.includes("admin_restore_backup_v095")&&fresh98.includes("admin_diagnostics_v095"),"Installation fraîche contient le durcissement V0.9.5");
need("sql098.fresh-098",fresh98.includes("admin_archive_season_v098")&&fresh98.includes("season_guestbook_entries_v098"),"Installation fraîche contient V0.9.8");

// Centre de tests et documentation.
const matrix=read("docs/TEST_MATRIX_V0.9.8.md");
const ids=[...matrix.matchAll(/\*\*(T\d{4})\*\*/g)].map(m=>m[1]);
need("tests.matrix-count",ids.length===1660,`Matrice: ${ids.length} contrôles (attendu 1660)`);
need("tests.matrix-unique",new Set(ids).size===ids.length,"IDs de la matrice uniques");
need("tests.matrix-last",ids.at(-1)==="T1660",`Dernier contrôle: ${ids.at(-1)||"absent"} (attendu T1660)`);
const center=read("tests/test-center-v0.9.8.html");
need("tests.center-count",(center.match(/"id":"T\d{4}"/g)||[]).length===1660,"Centre web contient 1660 tests manuels");
need("tests.center-version",center.includes("Centre de tests — V0.9.8")&&center.includes("Régression complète V0.1.x → V0.9.8")&&center.includes("cfg.APP_VERSION==='0.9.8'"),"Centre de tests V0.9.8 cohérent");
need("tests.center-diagnostic",center.includes("admin_diagnostics_v098")&&center.includes("v098.guestbook")&&center.includes("v098.archive")&&center.includes("v098.readiness"),"Centre web exécute les diagnostics V0.9.8");
need("tests.windows-safe",read("tests/run-all-v0.9.8.mjs").includes("fileURLToPath(import.meta.url)"),"Runner compatible chemins Windows");
need("docs.checklist-count",(read("docs/TEST_CHECKLIST_V0.9.8.md").match(/\*\*T\d{4}\*\*/g)||[]).length===170,"Checklist V0.9.8 contient 170 contrôles spécifiques");

// Vérifie qu'aucun libellé de version courante n'est resté à 0.9.5 dans les surfaces actuelles.
const stale=[];
for(const rel of ["VERSION","config.js","config.example.js","sw.js","assets/assets-manifest.json","finale.html","diplome.html","js/finale098.js","js/final-report098.js"]){
  const t=read(rel); if(/APP_VERSION\s*:\s*["']0\.9\.5/.test(t)||/nid-champions-v0\.9\.5/.test(t)||/schema_version["']?\s*[:,]\s*["']0\.9\.5/.test(t)) stale.push(rel);
}
need("version.no-stale-current",stale.length===0,"Aucune référence technique de version courante V0.9.5 dans les surfaces V0.9.8",stale.join(", "));

if(baseUrl){
  const remote=async rel=>{try{const r=await fetch(`${baseUrl}/${rel}`,{cache:"no-store"});return {ok:r.ok,status:r.status,text:r.ok?await r.text():""};}catch(e){return {ok:false,status:0,text:"",error:String(e)}}};
  const remoteChecks=[
    ["VERSION",t=>t.trim()==="0.9.8"],
    ["config.js",t=>t.includes('APP_VERSION: "0.9.8"')],
    ["sw.js",t=>t.includes("nid-champions-v0.9.8")&&t.includes("./js/finale098.js")&&t.includes("./finale.html")&&t.includes("./diplome.html")],
    ["index.html",t=>t.includes("js/finale098.js")&&t.includes("seasonFinaleRootV098")&&t.includes("test-center-v0.9.8.html")],
    ["js/finale098.js",t=>t.includes("renderFinalSeasonHubV098")&&t.includes("admin_archive_season_v098")],
    ["js/final-report098.js",t=>t.includes("get_final_season_report_v098")&&t.includes("window.print")],
    ["css/finale098.css",t=>t.includes("final098")],
    ["css/final-report098.css",t=>t.includes("@page")&&t.includes("A4")],
    ["finale.html",t=>t.includes("js/final-report098.js")],
    ["diplome.html",t=>t.includes("js/final-report098.js")],
    ["tests/test-center-v0.9.8.html",t=>t.includes("Centre de tests — V0.9.8")&&t.includes('"id":"T1660"')]
  ];
  for(const [rel,fn] of remoteChecks){const r=await remote(rel);add("remote:"+rel,r.ok&&fn(r.text)?"PASS":"FAIL",r.ok?`Déployé et conforme: ${rel}`:`Impossible/non conforme: ${rel} (HTTP ${r.status||0})`,r.error||"");}
}

const summary={total:checks.length,passed:checks.filter(x=>x.status==="PASS").length,warnings:checks.filter(x=>x.status==="WARN").length,failed:checks.filter(x=>x.status==="FAIL").length};
const report={version:"0.9.8",generated_at:new Date().toISOString(),base_url:baseUrl,summary,checks};
fs.writeFileSync(path.join(root,"tests","test-report-v0.9.8.json"),JSON.stringify(report,null,2)+"\n");
for(const c of checks)console.log(`${c.status.padEnd(4)} ${c.id} — ${c.message}${c.details?` · ${c.details}`:""}`);
console.log(`\nRésumé V0.9.8: ${summary.passed} PASS · ${summary.warnings} WARN · ${summary.failed} FAIL / ${summary.total}`);
console.log("Rapport: tests/test-report-v0.9.8.json");
if(summary.failed)process.exitCode=1;
