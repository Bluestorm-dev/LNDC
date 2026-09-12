import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const __filename=fileURLToPath(import.meta.url);
const __dirname=path.dirname(__filename);
const root=path.resolve(__dirname,"..");
const read=p=>fs.readFileSync(path.join(root,p),"utf8");
let pass=0,fail=0;
const test=(name,ok)=>{if(ok){pass++;console.log(`PASS  ${name}`)}else{fail++;console.error(`FAIL  ${name}`)}};

const index=read("index.html");
const sw=read("sw.js");
const js=read("js/release102f.js");
const cfg=fs.existsSync(path.join(root,"config.js"))?read("config.js"):"";

test("release102f chargé", index.includes('js/release102f.js'));
test("release102f après release102e", index.indexOf('js/release102f.js') > index.indexOf('js/release102e.js'));
test("release102f avant app.js", index.indexOf('js/release102f.js') < index.indexOf('js/app.js'));
test("cache PWA 1.0.2f", sw.includes('nid-champions-v1.0.2f-ucl-club-display'));
test("service worker précharge release102f", sw.includes('./js/release102f.js'));
test("VERSION 1.0.2f", read("VERSION").trim()==="1.0.2f");
test("config 1.0.2f", !cfg || cfg.includes('APP_VERSION: "1.0.2f"'));
test("aucun accès runtime à window.state", !js.includes("safe(window.state") && !js.includes("window.state?.") && !js.includes("window.state."));
test("utilise le binding state", js.includes('typeof state !== "undefined"'));
test("utilise clubById", js.includes('clubById(id)'));
test("écrase le résolveur 1.0.2e", js.includes('window.uclResolvePlayerClubV102e = resolveClubV102f'));
test("réactive le dédoublonnage", js.includes('window.uclDedupeRowsV102d'));
test("mapping Ferran Torres", js.includes('"Ferran Torres":"psg"'));
test("mapping Serhou Guirassy", js.includes('"Serhou Guirassy":"dortmund"'));
try{execFileSync(process.execPath,["--check",path.join(root,"js/release102f.js")],{stdio:"pipe"});test("syntaxe release102f",true);}catch{test("syntaxe release102f",false);}
console.log(`\n${pass} PASS · ${fail} FAIL`);
process.exitCode=fail?1:0;
