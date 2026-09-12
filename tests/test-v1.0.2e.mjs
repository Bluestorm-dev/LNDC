import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
const __dirname=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(__dirname,"..");
const read=rel=>fs.readFileSync(path.join(root,rel),"utf8");
let pass=0,fail=0;
const check=(name,ok)=>{if(ok){pass++;console.log("PASS",name);}else{fail++;console.error("FAIL",name);}};

const index=read("index.html");
const app=read("js/app.js");
const r101=read("js/release101.js");
const r102e=read("js/release102e.js");
const sw=read("sw.js");
const sql=read("sql/HOTFIX_V1.0.2e_REPAIR_UCL_CLUBS.sql");

check("index.102e",index.includes('js/release102e.js'));
check("index.order",index.indexOf('js/release102d.js')<index.indexOf('js/release102e.js'));
check("app.hook",app.includes('renderRelease102e()'));
check("renderer.resolver",r101.includes('uclResolvePlayerClubV102e'));
check("runtime.static-map",r102e.includes('playerClubRaw'));
check("runtime.cross-table",r102e.includes('resolveFromSiblingRowsV102e'));
check("runtime.loaded-active-club",r102e.includes('validClubByIdV102e'));
check("sql.inactive-remap",sql.includes('inactive_to_active'));
check("sql.j1-map",sql.includes('player_map(player_name,club_key)'));
check("sql.active-clubs",sql.includes('coalesce(c.is_active,true)=true'));
check("sql.controls",sql.includes('buteurs_sans_club_actif')&&sql.includes('cartons_sans_club_actif'));
check("version",read("VERSION").trim()==="1.0.2e");
check("cache",sw.includes('v1.0.2e-ucl-club-repair')&&sw.includes('./js/release102e.js'));

console.log(`\n${pass} PASS · ${fail} FAIL`);
process.exit(fail?1:0);
