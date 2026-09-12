import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const root = path.resolve(__dirname, "..");
const read = p => fs.readFileSync(path.join(root,p), "utf8");
const write = (p,s) => fs.writeFileSync(path.join(root,p), s.replace(/\r?\n/g,"\n"), "utf8");

for(const needed of ["index.html","sw.js","js/release102f.js"]){
  if(!fs.existsSync(path.join(root,needed))) throw new Error(`Fichier absent: ${needed}. Décompresse le patch à la racine LNDC.`);
}

let index = read("index.html");
if(!index.includes('js/release102f.js')){
  const marker = '  <script src="js/release102e.js"></script>';
  if(!index.includes(marker)) throw new Error("release102e.js introuvable dans index.html");
  index = index.replace(marker, `${marker}\n  <script src="js/release102f.js"></script>`);
  write("index.html", index);
}

let sw = read("sw.js");
sw = sw.replace(/const CACHE = "[^"]+";/, 'const CACHE = "nid-champions-v1.0.2f-ucl-club-display";');
if(!sw.includes('"./js/release102f.js"')){
  sw = sw.replace('"./js/release102e.js"', '"./js/release102e.js","./js/release102f.js"');
}
write("sw.js", sw);

for(const p of ["config.js","config.example.js"]){
  const full = path.join(root,p);
  if(!fs.existsSync(full)) continue;
  let s = fs.readFileSync(full,"utf8");
  s = s.replace(/APP_VERSION\s*:\s*"[^"]+"/, 'APP_VERSION: "1.0.2f"');
  fs.writeFileSync(full,s,"utf8");
}

fs.writeFileSync(path.join(root,"VERSION"),"1.0.2f\n","utf8");
console.log("✅ Hotfix V1.0.2f appliqué.");
console.log("   - le résolveur utilise maintenant le vrai `state`");
console.log("   - clubs/blasons des buteurs et cartons restaurés");
console.log("   - dédoublonnage frontal réactivé");
console.log("   - cache PWA passé en 1.0.2f");
