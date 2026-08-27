import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const root = path.resolve(path.dirname(__filename), "..");
const args=process.argv.slice(2);
const urlArg=args.find(a=>a.startsWith("--url="));
const baseUrl=urlArg?urlArg.slice(6).replace(/\/+$/,''):null;
const checks=[];
const add=(id,status,message,details={})=>checks.push({id,status,message,...details});
const exists=rel=>fs.existsSync(path.join(root,rel));
const read=rel=>exists(rel)?fs.readFileSync(path.join(root,rel),'utf8'):'';
const need=(id,ok,msg)=>add(id,ok?'PASS':'FAIL',msg);
const warn=(id,ok,msg)=>add(id,ok?'PASS':'WARN',msg);

for(const rel of ['VERSION','config.js','index.html','sw.js','js/core.js','js/app.js','js/admin.js','js/admin-test.js','js/predictions.js','js/ranking.js','js/teams.js','js/notifications.js','js/rivals.js','js/support.js','js/gamification.js','supabase/functions/sync-football-data/index.ts','sql/HOTFIX_V0.8.1_DIAGNOSTICS.sql','tests/test-center-v0.8.1.html','docs/TEST_MATRIX_V0.8.1.md'])
  need('file:'+rel,exists(rel),exists(rel)?`Présent: ${rel}`:`Absent: ${rel}`);

need('version.file',read('VERSION').trim()==='0.8.1',`VERSION = ${read('VERSION').trim()||'absent'} (attendu 0.8.1)`);
need('version.config',read('config.js').includes('APP_VERSION: "0.8.1"'),'config.js annonce 0.8.1');
need('version.cache',read('sw.js').includes('nid-champions-v0.8.1'),'cache Service Worker V0.8.1');

const edge=read('supabase/functions/sync-football-data/index.ts');
need('fd.strict-season',edge.includes('sourceSeasonYear') && !edge.includes('TEST_SOURCE_SEASON_YEAR') && !edge.includes('shiftTestDate'),'Football-Data reste strictement sur la saison demandée, sans ancien décalage 2025/26');
need('fd.404',edge.includes('season_not_available') && edge.includes('footballDataStatus'),'404 Football-Data traité comme saison indisponible');
need('fd.no-fallback-2025',!edge.includes('2025') || !/fallback[^\n]{0,100}2025/i.test(edge),'Aucun fallback explicite vers 2025 détecté');

const allJs=['js/core.js','js/app.js','js/admin.js','js/admin-test.js','js/predictions.js','js/ranking.js','js/teams.js','js/notifications.js','js/rivals.js','js/support.js','js/gamification.js'].map(read).join('\n');
need('feature.predictions',/prediction|pronostic/i.test(allJs),'Moteur pronostics détecté');
need('feature.live',/realtime|LIVE/i.test(allJs),'LIVE / Realtime détecté');
need('feature.teams',/create_team_v050|team/i.test(read('js/teams.js')),'Teams détectées');
need('feature.push',/push|notification/i.test(read('js/notifications.js')),'Notifications / Push détectés');
need('feature.rivals',/rival/i.test(read('js/rivals.js')),'Rivalités détectées');
need('feature.support',/ticket|support/i.test(read('js/support.js')),'Support / tickets détectés');
need('feature.gamification',/badge|museum|gamification/i.test(read('js/gamification.js')),'Gamification / Musée détectés');

const sql080Candidates=['sql/HOTFIX_V0.8.0_EXISTING_DB.sql','sql/024_patch_v0.8.0_evenings_ucl.sql'];
const sql080=sql080Candidates.map(read).join('\n');
warn('feature.ucl-schema',/ucl_matches/.test(sql080)||/ucl_matches/.test(allJs),'Schéma / frontend Centre C1 détecté');
warn('feature.solitary',/hibou_solitaire/i.test(sql080)||/hibou solitaire/i.test(allJs),'Hibou solitaire détecté');
warn('feature.polls',/monthly_polls/i.test(sql080)||/monthly_poll/i.test(allJs),'Votes mensuels détectés');

if (baseUrl) {
  const remote=async(rel)=>{try{const r=await fetch(`${baseUrl}/${rel}`,{cache:'no-store'});return {ok:r.ok,status:r.status,text:r.ok?await r.text():''};}catch(e){return {ok:false,status:0,text:'',error:String(e)}}};
  for(const rel of ['VERSION','config.js','sw.js','index.html']){
    const r=await remote(rel); add('remote:'+rel,r.ok?'PASS':'FAIL',r.ok?`Déployé: ${rel}`:`Impossible de lire ${rel} (${r.status||r.error})`);
    if(rel==='VERSION'&&r.ok) need('remote.version',r.text.trim()==='0.8.1',`Version déployée: ${r.text.trim()}`);
    if(rel==='config.js'&&r.ok) need('remote.config',r.text.includes('APP_VERSION: "0.8.1"'),'config.js déployé annonce 0.8.1');
    if(rel==='sw.js'&&r.ok) need('remote.cache',r.text.includes('nid-champions-v0.8.1'),'Service Worker déployé utilise le cache V0.8.1');
  }
}

const summary={total:checks.length,passed:checks.filter(x=>x.status==='PASS').length,warnings:checks.filter(x=>x.status==='WARN').length,failed:checks.filter(x=>x.status==='FAIL').length};
const report={version:'0.8.1',generated_at:new Date().toISOString(),base_url:baseUrl,summary,checks};
fs.writeFileSync(path.join(root,'tests','test-report-v0.8.1.json'),JSON.stringify(report,null,2)+"\n");
for(const c of checks) console.log(`${c.status.padEnd(4)} ${c.id} — ${c.message}`);
console.log(`\nRésumé: ${summary.passed} PASS · ${summary.warnings} WARN · ${summary.failed} FAIL / ${summary.total}`);
console.log('Rapport: tests/test-report-v0.8.1.json');
if(summary.failed) process.exitCode=1;
