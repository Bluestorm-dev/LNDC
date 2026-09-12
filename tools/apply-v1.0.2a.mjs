import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(__dirname,"..");
const target=path.resolve(root,"..");

function mustRead(p){if(!fs.existsSync(p))throw new Error(`Fichier introuvable: ${p}`);return fs.readFileSync(p,"utf8");}
function write(p,s){fs.writeFileSync(p,s,"utf8");console.log("OK",path.relative(target,p));}

const indexPath=path.join(target,"index.html");
let html=mustRead(indexPath);
if(!html.includes('css/release102a.css')){
  if(html.includes('<link rel="stylesheet" href="css/release101.css" />')) html=html.replace('<link rel="stylesheet" href="css/release101.css" />','<link rel="stylesheet" href="css/release101.css" />\n  <link rel="stylesheet" href="css/release102a.css" />');
  else html=html.replace('</head>','  <link rel="stylesheet" href="css/release102a.css" />\n</head>');
}
if(!html.includes('js/release102a.js')){
  if(html.includes('<script src="js/release101.js"></script>')) html=html.replace('<script src="js/release101.js"></script>','<script src="js/release101.js"></script>\n  <script src="js/release102a.js"></script>');
  else html=html.replace('<script src="js/app.js"></script>','<script src="js/release102a.js"></script>\n  <script src="js/app.js"></script>');
}
html=html.replace(/V1\.0\.2(?!a)/g,"V1.0.2a").replace(/>1\.0\.2</g,">1.0.2a<");
write(indexPath,html);

for(const name of ["config.js","config.example.js"]){
  const p=path.join(target,name);if(!fs.existsSync(p))continue;let s=mustRead(p);s=s.replace(/APP_VERSION\s*:\s*["']1\.0\.2(?:a)?["']/,'APP_VERSION: "1.0.2a"');write(p,s);
}
const versionPath=path.join(target,"VERSION");if(fs.existsSync(versionPath))write(versionPath,"1.0.2a\n");

const swPath=path.join(target,"sw.js");if(fs.existsSync(swPath)){
  let sw=mustRead(swPath);
  sw=sw.replace(/^const CACHE = .*;$/m,'const CACHE = "nid-champions-v1.0.2a-ranking-movement";');
  if(!sw.includes('./css/release102a.css'))sw=sw.replace('"./css/release101.css"','"./css/release101.css","./css/release102a.css"');
  if(!sw.includes('./js/release102a.js'))sw=sw.replace('"./js/release101.js"','"./js/release101.js","./js/release102a.js"');
  write(swPath,sw);
}

console.log("\nPatch V1.0.2a appliqué. Exécute ensuite le SQL HOTFIX_V1.0.2a_EXISTING_DB.sql dans Supabase.");
