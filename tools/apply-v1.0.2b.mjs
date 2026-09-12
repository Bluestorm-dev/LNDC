import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// IMPORTANT : tools/ est directement dans le dépôt LNDC.
// L'ancien script 1.0.2a faisait ".." une fois de trop et modifiait le dossier parent.
const root = path.resolve(__dirname, "..");

function mustRead(p){
  if(!fs.existsSync(p)) throw new Error(`Fichier introuvable: ${p}`);
  return fs.readFileSync(p,"utf8");
}
function write(p,s){
  fs.writeFileSync(p,s,"utf8");
  console.log("OK",path.relative(root,p));
}
function ensureFile(rel){
  const p=path.join(root,rel);
  if(!fs.existsSync(p)) throw new Error(`Le patch doit contenir ${rel}`);
}

ensureFile("css/release102a.css");
ensureFile("js/release102a.js");

// 1) INDEX : charger le hotfix APRES release102 pour qu'il ait le dernier mot.
const indexPath=path.join(root,"index.html");
let html=mustRead(indexPath);
html=html.replace(/\s*<link rel="stylesheet" href="css\/release102a\.css" \/>/g,"");
html=html.replace(/\s*<script src="js\/release102a\.js"><\/script>/g,"");
if(!html.includes('<link rel="stylesheet" href="css/release102.css" />')) throw new Error("release102.css introuvable dans index.html");
if(!html.includes('<script src="js/release102.js"></script>')) throw new Error("release102.js introuvable dans index.html");
html=html.replace(
  '<link rel="stylesheet" href="css/release102.css" />',
  '<link rel="stylesheet" href="css/release102.css" />\n  <link rel="stylesheet" href="css/release102a.css" />'
);
html=html.replace(
  '<script src="js/release102.js"></script>',
  '<script src="js/release102.js"></script>\n  <script src="js/release102a.js"></script>'
);
// Version visible uniquement : ne touche pas aux noms des tests 1.0.2.
html=html.replace(/V1\.0\.2(?:a|b)?/g,"V1.0.2b");
html=html.replace(/>1\.0\.2(?:a|b)?</g,">1.0.2b<");
write(indexPath,html);

// 2) APP : appel explicite du correctif après release102.
const appPath=path.join(root,"js","app.js");
let app=mustRead(appPath);
if(!app.includes('renderRelease102a')){
  const needle='if(typeof renderRelease102==="function")renderRelease102();';
  if(!app.includes(needle)) throw new Error("Point d'insertion renderRelease102 introuvable dans js/app.js");
  app=app.replace(needle,needle+' if(typeof renderRelease102a==="function")renderRelease102a();');
}
write(appPath,app);

// 3) VERSION / CONFIG.
for(const name of ["config.js","config.example.js"]){
  const p=path.join(root,name);
  if(!fs.existsSync(p)) continue;
  let s=mustRead(p);
  s=s.replace(/APP_VERSION\s*:\s*["']1\.0\.2(?:a|b)?["']/,'APP_VERSION: "1.0.2b"');
  write(p,s);
}
write(path.join(root,"VERSION"),"1.0.2b\n");

// 4) SERVICE WORKER : nouveau cache + actifs 102a APRES 102.
const swPath=path.join(root,"sw.js");
let sw=mustRead(swPath);
sw=sw.replace(/^const CACHE = .*;$/m,'const CACHE = "nid-champions-v1.0.2b-ui-hotfix";');
sw=sw.replace(/,"\.\/css\/release102a\.css"/g,"").replace(/"\.\/css\/release102a\.css",/g,"");
sw=sw.replace(/,"\.\/js\/release102a\.js"/g,"").replace(/"\.\/js\/release102a\.js",/g,"");
if(!sw.includes('"./css/release102.css"')) throw new Error("release102.css introuvable dans sw.js");
if(!sw.includes('"./js/release102.js"')) throw new Error("release102.js introuvable dans sw.js");
sw=sw.replace('"./css/release102.css"','"./css/release102.css","./css/release102a.css"');
sw=sw.replace('"./js/release102.js"','"./js/release102.js","./js/release102a.js"');
write(swPath,sw);

console.log("\n✅ Hotfix V1.0.2b appliqué AU BON DÉPÔT.");
console.log("Ensuite : exécute sql/HOTFIX_V1.0.2b_EXISTING_DB.sql dans Supabase puis node tests/test-v1.0.2b.mjs");
