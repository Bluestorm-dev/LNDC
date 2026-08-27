import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const log = (...a) => console.log("[V0.8.1]", ...a);
const fail = (m) => { console.error("[V0.8.1] ERREUR:", m); process.exit(1); };
const exists = (rel) => fs.existsSync(path.join(root, rel));
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");
const write = (rel, txt) => fs.writeFileSync(path.join(root, rel), txt, "utf8");
const backup = (rel) => {
  const src = path.join(root, rel), dst = src + ".v080.bak";
  if (fs.existsSync(src) && !fs.existsSync(dst)) fs.copyFileSync(src, dst);
};

if (!exists("config.js")) fail("Lance ce script depuis la racine de Le Nid des Champions V0.8.0.");
const edgeRel = "supabase/functions/sync-football-data/index.ts";
if (!exists(edgeRel)) fail(`Fichier absent: ${edgeRel}`);

// 1) Edge Function : conserver le statut HTTP Football-Data et traiter le 404 comme état métier.
backup(edgeRel);
let edge = read(edgeRel);
if (!edge.includes("footballDataStatus")) {
  const oldFd = /if \(!response\.ok\) \{\s*const body = await response\.text\(\);\s*throw new Error\(`football-data\.org \$\{response\.status\}: \$\{body\.slice\(0, 220\)\}`\);\s*\}/m;
  if (!oldFd.test(edge)) fail("Bloc fdFetch V0.8.0 introuvable. Aucun changement appliqué à l'Edge Function.");
  edge = edge.replace(oldFd, `if (!response.ok) {\n        const body = await response.text();\n        const fdError = new Error(\`football-data.org \${response.status}: \${body.slice(0, 220)}\`);\n        (fdError as any).footballDataStatus = response.status;\n        (fdError as any).footballDataBody = body.slice(0, 500);\n        throw fdError;\n      }`);
}

if (!edge.includes('code: "season_not_available"')) {
  const oldCatch = /console\.error\("sync-football-data", error\);\s*return json\(\{ ok: false, error: error instanceof Error \? error\.message : "Synchronisation impossible\." \}, 500\);/m;
  if (!oldCatch.test(edge)) fail("Bloc catch final V0.8.0 introuvable. Le fichier .v080.bak permet de revenir en arrière.");
  edge = edge.replace(oldCatch, `console.error("sync-football-data", error);\n    const fdStatus = Number((error as any)?.footballDataStatus || 0);\n    if (fdStatus === 404) {\n      // V0.8.1 : un 404 Football-Data signifie que la ressource/saison demandée\n      // n'est pas encore disponible. On renvoie HTTP 200 afin que le frontend\n      // puisse afficher l'erreur métier au lieu d'une panne générique de Function.\n      return json({\n        ok: false,\n        code: "season_not_available",\n        provider_status: 404,\n        error: "La saison 2026/27 n'est pas encore disponible chez Football-Data. Aucun match 2025/26 n'a été importé. Réessaie après la publication du calendrier."\n      }, 200);\n    }\n    if (fdStatus === 401 || fdStatus === 403) {\n      return json({ ok: false, code: "provider_auth_error", provider_status: fdStatus, error: "Football-Data refuse l'accès. Vérifie le secret FOOTBALL_DATA_API_KEY et les droits du compte API." }, 200);\n    }\n    if (fdStatus === 429) {\n      return json({ ok: false, code: "provider_rate_limit", provider_status: 429, error: "Limite de requêtes Football-Data atteinte. Réessaie dans quelques minutes." }, 200);\n    }\n    return json({ ok: false, error: error instanceof Error ? error.message : "Synchronisation impossible." }, 500);`);
}
write(edgeRel, edge);
log("sync-football-data corrigée.");

// 2) Message de secours frontend : ne plus accuser automatiquement le déploiement/secret.
const generic = "La fonction sync-football-data ne répond pas. Vérifie son déploiement et le secret FOOTBALL_DATA_API_KEY.";
const fallback = "La synchronisation Centre C1 a échoué. Si Football-Data n'a pas encore publié 2026/27, réessaie plus tard ; sinon consulte les logs de sync-football-data.";
for (const dir of ["js", "assets/js"]) {
  const abs = path.join(root, dir);
  if (!fs.existsSync(abs)) continue;
  for (const name of fs.readdirSync(abs)) {
    if (!name.endsWith(".js")) continue;
    const rel = path.join(dir, name);
    let txt = read(rel);
    if (txt.includes(generic)) {
      backup(rel); txt = txt.split(generic).join(fallback); write(rel, txt); log(`Message frontend corrigé: ${rel}`);
    }
  }
}

// 3) Version / cache.
function replaceFile(rel, replacements) {
  if (!exists(rel)) return;
  backup(rel);
  let txt = read(rel), before = txt;
  for (const [a,b] of replacements) txt = txt.split(a).join(b);
  if (txt !== before) { write(rel,txt); log(`Version mise à jour: ${rel}`); }
}
if (exists("VERSION")) { backup("VERSION"); write("VERSION", "0.8.1\n"); }
replaceFile("config.js", [[ 'APP_VERSION: "0.8.0"', 'APP_VERSION: "0.8.1"' ]]);
replaceFile("config.example.js", [[ 'APP_VERSION: "0.8.0"', 'APP_VERSION: "0.8.1"' ]]);
replaceFile("sw.js", [["nid-champions-v0.8.0","nid-champions-v0.8.1"],["le-nid-des-champions-v0.8.0","le-nid-des-champions-v0.8.1"],["V0.8.0","V0.8.1"]]);
replaceFile("index.html", [["V0.8.0","V0.8.1"]]);
for (const rel of ["js/core.js","js/app.js","js/admin.js"]) replaceFile(rel, [["V0.8.0","V0.8.1"]]);

const manifestRel = "assets/assets-manifest.json";
if (exists(manifestRel)) {
  backup(manifestRel);
  try {
    const j=JSON.parse(read(manifestRel));
    if (j.version === "0.8.0") j.version="0.8.1";
    fs.writeFileSync(path.join(root,manifestRel), JSON.stringify(j,null,2)+"\n");
  } catch { log("assets-manifest.json non modifié (JSON non lisible)."); }
}

log("Patch fichiers terminé.");
console.log(`\nÉtapes restantes:\n1. Supabase SQL Editor : sql/HOTFIX_V0.8.1_DIAGNOSTICS.sql\n2. npx.cmd supabase functions deploy sync-football-data\n3. node tests\\run-all-v0.8.1.mjs\n4. Déployer le frontend puis Ctrl+F5 / relancer la PWA.\n5. Ouvrir /tests/test-center-v0.8.1.html avec un compte Super Admin.\n`);
