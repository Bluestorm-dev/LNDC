import fs from 'node:fs';
const root=new URL('../',import.meta.url);
const read=(p)=>fs.readFileSync(new URL(p,root),'utf8');
const checks=[
  ['avatars loader',read('js/avatars.js').includes('loadAvatarAwardHoldersV0914b')],
  ['distinction code',read('js/avatars.js').includes('nid-pronos-world-cup-2026')],
  ['star markup',read('js/avatars.js').includes('avatar-distinction-star-worldcup')],
  ['admin live refresh',read('js/career.js').includes('loadAvatarAwardHoldersV0914b')],
  ['star CSS',read('css/avatars.css').includes('V0.9.14b — Étoile historique')],
  ['version',read('VERSION').trim()==='0.9.14b'],
  ['cache',read('sw.js').includes('v0.9.14b-winner-star')],
  ['hotfix SQL',read('sql/HOTFIX_V0.9.14b_EXISTING_DB.sql').includes('0.9.14b')]
];
let fail=0;
for(const [name,ok] of checks){console.log(`${ok?'PASS':'FAIL'}  ${name}`);if(!ok)fail++;}
console.log(`\n${checks.length-fail} PASS · ${fail} FAIL`);
process.exitCode=fail?1:0;
