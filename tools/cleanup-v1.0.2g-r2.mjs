import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const required = [
  "index.html",
  path.join("js", "core.js"),
  path.join("assets", "icons", "runtime")
];

const missing = required.filter(p => !fs.existsSync(path.join(root, p)));
if (missing.length) {
  console.error("ERREUR : lance ce script depuis la racine du dépôt LNDC.");
  console.error("Dossier courant :", root);
  console.error("Éléments introuvables :", missing.join(", "));
  process.exit(1);
}

const targets = [
  "assets/icons/app",
  "assets/icons/ui",
  "assets/icons/football",
  "assets/icons/icon-catalog.json",
  "assets/avatars/source-sheets",
  "assets/badges/source-sheets",
  "assets/source-sheets"
];

console.log("LNDC V1.0.2g — nettoyage correctif R2");
console.log("Racine utilisée :", root);

for (const rel of targets) {
  const full = path.join(root, rel);
  if (fs.existsSync(full)) {
    fs.rmSync(full, { recursive: true, force: true, maxRetries: 3, retryDelay: 150 });
    console.log("SUPPRIMÉ ·", rel);
  } else {
    console.log("DÉJÀ ABSENT ·", rel);
  }
}

console.log("\nVérification immédiate :");
let fail = 0;
for (const rel of targets) {
  const ok = !fs.existsSync(path.join(root, rel));
  console.log(`${ok ? "PASS" : "FAIL"} · ${rel}`);
  if (!ok) fail++;
}

if (fail) {
  console.error(`\n${fail} élément(s) n'ont pas pu être supprimé(s).`);
  process.exit(2);
}

console.log("\nOK — les 7 anciens ensembles ont bien été supprimés du dépôt courant.");
console.log("Tu peux maintenant relancer : node tests\\test-v1.0.2g-cleanup.mjs");
console.log("Puis : git add -A");
