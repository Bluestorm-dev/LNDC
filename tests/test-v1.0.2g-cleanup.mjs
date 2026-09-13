import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename=fileURLToPath(import.meta.url);
const __dirname=path.dirname(__filename);
const root=path.resolve(__dirname,"..");
const E=p=>fs.existsSync(path.join(root,p));
const R=p=>fs.readFileSync(path.join(root,p),"utf8");
const results=[];
const t=(name,ok)=>results.push([name,!!ok]);

t("VERSION = 1.0.2g",R("VERSION").trim()==="1.0.2g");
t("runtime icons conservées",E("assets/icons/runtime/home.png")&&E("assets/icons/runtime/trophy.png"));
t("4 icônes PWA conservées",["icon-192.png","icon-512.png","icon-maskable-192.png","icon-maskable-512.png"].every(x=>E("assets/icons/"+x)));
t("ancien pack app supprimé",!E("assets/icons/app"));
t("ancien pack ui supprimé",!E("assets/icons/ui"));
t("ancien pack football supprimé",!E("assets/icons/football"));
t("catalogue ancien supprimé",!E("assets/icons/icon-catalog.json"));
t("planches avatars supprimées",!E("assets/avatars/source-sheets"));
t("planches badges supprimées",!E("assets/badges/source-sheets"));
t("planches icônes supprimées",!E("assets/source-sheets"));
const core=R("js/core.js");
t("Ukraine reconnue",core.includes('Ukraine:["Ukraine","ua"]'));
t("Shakhtar forcé sur Ukraine",core.includes('identity.includes("shakhtar")')&&core.includes('name:"Ukraine",code:"ua"'));
const all=["index.html","manifest.webmanifest","sw.js",...fs.readdirSync(path.join(root,"js")).filter(x=>x.endsWith(".js")).map(x=>"js/"+x),...fs.readdirSync(path.join(root,"css")).filter(x=>x.endsWith(".css")).map(x=>"css/"+x)].map(R).join("\n");
t("aucune référence front vers anciens packs",!/assets\/icons\/(app|ui|football)\//.test(all));

for(const [name,ok] of results)console.log(`${ok?"PASS":"FAIL"} · ${name}`);
const fail=results.filter(([,ok])=>!ok).length;
console.log(`\n${results.length-fail} PASS · ${fail} FAIL`);
process.exitCode=fail?1:0;
