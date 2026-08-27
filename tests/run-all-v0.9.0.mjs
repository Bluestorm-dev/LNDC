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
  "VERSION","config.js","config.example.js","index.html","sw.js",
  "css/career.css","js/core.js","js/data.js","js/profile.js","js/career.js","js/app.js","js/auth.js","js/realtime.js",
  "sql/025_patch_v0.9.0_season_career_memory.sql","sql/HOTFIX_V0.9.0_EXISTING_DB.sql","sql/000_INSTALL_FRESH_V0.9.0.sql",
  "tests/test-center-v0.9.0.html","docs/TEST_CHECKLIST_V0.9.0.md","docs/TEST_MATRIX_V0.9.0.md",
  "INSTALLATION_V0.9.0.txt","PATCH_NOTES_V0.9.0.txt","README_TEST_SYSTEM_V0.9.0.md"
];
for(const rel of required)need("file:"+rel,exists(rel),exists(rel)?`Présent: ${rel}`:`Absent: ${rel}`);

need("version.file",read("VERSION").trim()==="0.9.0",`VERSION = ${read("VERSION").trim()||"absent"} (attendu 0.9.0)`);
need("version.config",contains("config.js",'APP_VERSION: "0.9.0"'),"config.js annonce 0.9.0");
need("version.config-example",contains("config.example.js",'APP_VERSION: "0.9.0"'),"config.example.js annonce 0.9.0");
need("version.cache",contains("sw.js","nid-champions-v0.9.0"),"Cache Service Worker V0.9.0");
need("version.assets",contains("assets/assets-manifest.json",'"version": "0.9.0"'),"Manifest des assets V0.9.0");
need("front.module",contains("index.html","css/career.css","js/career.js","seasonMemoryRoot","profileCareerRoot","adminSeasonManagementPanel"),"UI V0.9.0 branchée dans index.html");
need("sw.module",contains("sw.js","./css/career.css","./js/career.js"),"Service Worker pré-cache le module V0.9.0");

const career=read("js/career.js");
for(const [id,token,msg] of [
  ["front.switch-season","switchSeasonV090","Sélecteur multi-saisons"],
  ["front.season-profile","seasonOverviewHTMLV090","Profil de saison complet"],
  ["front.career-board","careerLeaderboardHTMLV090","Classement carrière"],
  ["front.hall","hallOfFameHTMLV090","Hall of Fame"],
  ["front.replay","replayHTMLV090","Replay de saison"],
  ["front.polls","pollsHTMLV090","Sondages généraux"],
  ["front.admin-polls","renderAdminGeneralPollPanelV090","Admin sondages"],
  ["front.distinction","renderAdminDistinctionPanelV090","Admin distinctions"],
  ["front.world-cup-winner","admin_set_world_cup_winner_v090","Attribution manuelle du vainqueur Coupe du monde"],
  ["front.admin-seasons","renderAdminSeasonManagementV090","Admin multi-saisons"],
  ["front.archive","season-readonly-chip","Signal archive lecture seule"]
]) need(id,career.includes(token),msg);

const sql=read("sql/025_patch_v0.9.0_season_career_memory.sql");
for(const [id,token,msg] of [
  ["db.rank-history","public.player_rank_history","Historique du rang"],
  ["db.capture","capture_season_snapshot_v090","Snapshots de classement"],
  ["db.distinctions","public.player_distinctions","Distinctions persistantes"],
  ["db.world-cup-winner","admin_set_world_cup_winner_v090","RPC vainqueur Nid des Pronos Coupe du monde"],
  ["db.polls","public.polls","Sondages généraux"],
  ["db.memory-events","public.season_memory_events","Événements de mémoire"],
  ["db.profile","get_player_season_profile_v090","Profil saison RPC"],
  ["db.career-board","get_career_leaderboard_v090","Classement carrière RPC"],
  ["db.career-player","get_player_career_v090","Carrière joueur RPC"],
  ["db.title-holder","get_title_holder_v090","Champion en titre RPC"],
  ["db.hall","get_hall_of_fame_v090","Hall of Fame RPC"],
  ["db.replay","get_season_replay_v090","Replay RPC"],
  ["db.create-season","admin_create_season_v090","Création de saison"],
  ["db.activate-season","admin_set_active_season_v090","Activation de saison"],
  ["db.status-season","admin_set_season_status_v090","Statut de saison"],
  ["db.archive-readonly","season_is_writable_v090","Archives lecture seule"],
  ["db.archive-teams","guard_archived_team_mutation_v090","Teams figées dans les archives"],
  ["db.diagnostic","admin_run_diagnostics_v090","Diagnostic V0.9.0"]
]) need(id,sql.includes(token),msg);

need("db.archive.predictions",sql.includes("Cette saison est terminée et consultable en lecture seule.")&&sql.includes("create or replace function public.guard_prediction_write"),"Pronostics officiels protégés dans les archives");
need("db.archive.qualifier",sql.includes("create or replace function public.guard_tie_prediction_v040"),"Pronostics qualifiés protégés dans les archives");
need("db.archive.champion",sql.includes("create or replace function public.save_champion_pick_v040"),"Choix Champion protégés dans les archives");
need("db.lead.freeze",sql.includes("when s.status in ('finished','archived')")&&sql.includes("lead(h.captured_at,1,(select end_at from season_end))"),"Jours en tête figés sur les saisons closes");
need("db.hall.full",["'best_score'::text","'best_exact'::text","'poele_or'::text","'genius'::text","'solitary'::text","'team'::text","'record'::text"].every(t=>sql.includes(t)),"Hall of Fame couvre les catégories attendues");
need("db.transaction",/^\s*begin;/m.test(sql)&&/\ncommit;\s*\n/m.test(sql),"Migration encapsulée dans une transaction");
need("db.app-version",sql.includes(`values('app_version','"0.9.0"'::jsonb)`)||sql.includes(`values ('app_version','"0.9.0"'::jsonb)`),"Version backend mise à 0.9.0");

const edge=read("supabase/functions/sync-football-data/index.ts");
need("fd.081-preserved",edge.includes("season_not_available")&&edge.includes("footballDataStatus"),"Correctif Football-Data V0.8.1 conservé");
need("fd.no-fallback-2025",!(/fallback[^\n]{0,140}2025/i.test(edge)),"Aucun fallback explicite vers 2025/26 détecté");
need("fd.strict-season",edge.includes("sourceSeasonYear"),"Synchronisation Football-Data reste pilotée par la saison source");

const matrix=read("docs/TEST_MATRIX_V0.9.0.md");
const ids=[...matrix.matchAll(/\*\*(T\d{4})\*\*/g)].map(m=>m[1]);
need("tests.matrix-count",ids.length===1330,`Matrice: ${ids.length} contrôles (attendu 1330)`);
need("tests.matrix-unique",new Set(ids).size===ids.length,"IDs de la matrice uniques");
need("tests.matrix-last",ids.at(-1)==="T1330",`Dernier contrôle: ${ids.at(-1)||"absent"} (attendu T1330)`);
need("tests.center-count",(read("tests/test-center-v0.9.0.html").match(/"id":"T\d{4}"/g)||[]).length===1330,"Centre web contient 1330 tests manuels");
need("tests.windows-safe",read("tests/run-all-v0.9.0.mjs").includes("fileURLToPath(import.meta.url)"),"Runner compatible chemins Windows");

const currentFiles=["index.html","config.js","config.example.js","sw.js","js/core.js","js/app.js","js/career.js"];
const stale=currentFiles.flatMap(rel=>{
  const t=read(rel),found=[];
  if(/APP_VERSION:\s*"0\.8\.1"/.test(t)||/nid-champions-v0\.8\.1/.test(t))found.push(rel);
  return found;
});
need("version.no-stale-current",stale.length===0,"Aucune référence technique V0.8.1 résiduelle dans les fichiers courants",stale.join(", "));

if(baseUrl){
  const remote=async rel=>{try{const r=await fetch(`${baseUrl}/${rel}`,{cache:"no-store"});return {ok:r.ok,status:r.status,text:r.ok?await r.text():""};}catch(e){return {ok:false,status:0,text:"",error:String(e)}}};
  const remoteChecks=[
    ["VERSION",t=>t.trim()==="0.9.0"],
    ["config.js",t=>t.includes('APP_VERSION: "0.9.0"')],
    ["sw.js",t=>t.includes("nid-champions-v0.9.0")&&t.includes("./js/career.js")],
    ["index.html",t=>t.includes("js/career.js")&&t.includes("css/career.css")],
    ["js/career.js",t=>t.includes("renderAdminSeasonManagementV090")&&t.includes("renderSeasonMemory")]
  ];
  for(const [rel,fn] of remoteChecks){
    const r=await remote(rel);
    add("remote:"+rel,r.ok&&fn(r.text)?"PASS":"FAIL",r.ok?`Déployé et conforme: ${rel}`:`Impossible/non conforme: ${rel} (HTTP ${r.status||0})`,r.error||"");
  }
}

const summary={
  total:checks.length,
  passed:checks.filter(x=>x.status==="PASS").length,
  warnings:checks.filter(x=>x.status==="WARN").length,
  failed:checks.filter(x=>x.status==="FAIL").length
};
const report={version:"0.9.0",generated_at:new Date().toISOString(),base_url:baseUrl,summary,checks};
fs.writeFileSync(path.join(root,"tests","test-report-v0.9.0.json"),JSON.stringify(report,null,2)+"\n");

for(const c of checks)console.log(`${c.status.padEnd(4)} ${c.id} — ${c.message}${c.details?` · ${c.details}`:""}`);
console.log(`\nRésumé V0.9.0: ${summary.passed} PASS · ${summary.warnings} WARN · ${summary.failed} FAIL / ${summary.total}`);
console.log("Rapport: tests/test-report-v0.9.0.json");
if(summary.failed)process.exitCode=1;
