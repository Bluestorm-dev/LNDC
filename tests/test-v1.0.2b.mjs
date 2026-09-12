import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,"..");
const read=rel=>fs.readFileSync(path.join(root,rel),"utf8");
const checks=[];
const test=(name,ok)=>checks.push([name,Boolean(ok)]);

const html=read("index.html");
const app=read("js/app.js");
const js=read("js/release102a.js");
const css=read("css/release102a.css");
const sw=read("sw.js");
const sql=read("sql/HOTFIX_V1.0.2b_EXISTING_DB.sql");
const version=read("VERSION").trim();
const config=read("config.example.js");

const css102=html.indexOf('css/release102.css');
const css102a=html.indexOf('css/release102a.css');
const js102=html.indexOf('js/release102.js');
const js102a=html.indexOf('js/release102a.js');
const appScript=html.indexOf('js/app.js');

test("VERSION = 1.0.2b",version==="1.0.2b");
test("APP_VERSION = 1.0.2b",/APP_VERSION\s*:\s*["']1\.0\.2b["']/.test(config));
test("CSS 102a chargé après 102",css102>=0&&css102a>css102);
test("JS 102a chargé après 102 et avant app",js102>=0&&js102a>js102&&appScript>js102a);
test("renderRelease102a appelé",app.includes('if(typeof renderRelease102a==="function")renderRelease102a();'));
test("Nouveau cache SW",sw.includes('nid-champions-v1.0.2b-ui-hotfix'));
test("SW cache CSS 102a",sw.includes('"./css/release102.css","./css/release102a.css"'));
test("SW cache JS 102a",sw.includes('"./js/release102.js","./js/release102a.js"'));
test("Classement sans max-height",css.includes("max-height:none!important"));
test("Carte classement non sticky",css.includes("#view-ranking .my-ranking-sticky")&&css.includes("position:relative!important"));
test("Matchs sans couleurs Team",css.includes("AUCUNE couleur Team sur les cartes match"));
test("Team uniquement par joueur",js.includes("teamForUser(userId)")&&js.includes("data-story-player-v102a"));
test("Détails prono / résultat",js.includes("Prono")&&js.includes("Résultat")&&js.includes("eventDetailHTML102a"));
test("RPC détails événements",sql.includes("get_gamification_event_details_v102a"));
test("app_settings sans description",!sql.includes("key,value,description"));

for(const [n,ok] of checks) console.log(`${ok?"PASS":"FAIL"} - ${n}`);
const failed=checks.filter(x=>!x[1]);
if(failed.length){console.error(`\n${failed.length} FAIL`);process.exit(1);}
console.log(`\n${checks.length} PASS · 0 FAIL`);
