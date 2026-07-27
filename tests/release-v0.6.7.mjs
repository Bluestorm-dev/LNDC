import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');

assert.equal(read('VERSION').trim(),'0.6.7');
assert.match(read('config.js'),/APP_VERSION:\s*"0\.6\.7"/);
assert.match(read('config.example.js'),/APP_VERSION:\s*"0\.6\.7"/);
assert.match(read('sw.js'),/nid-champions-v0\.6\.7/);
assert.equal(JSON.parse(read('assets/assets-manifest.json')).version,'0.6.7');

const core=read('js/core.js');
assert.match(core,/https:\/\/flagcdn\.com\/\$\{safe\}\.svg/);
for(const code of ['fr','de','es','gb-eng','gb-sct','gb-wls','gb-nir','it','pt','nl','be','dk','no','gr','tr','cz','at','ch','cy','az','kz']) {
  assert.ok(core.includes(`"${code}"`),`code FlagCDN absent: ${code}`);
}
for(const emoji of ['🇫🇷','🇪🇸','🇩🇪','🇮🇹','🇵🇹','🇳🇱','🇧🇪','🇩🇰','🇳🇴','🇬🇷','🇹🇷','🇨🇿','🇦🇹','🇨🇭','🇨🇾','🇦🇿','🇰🇿']) {
  assert.ok(!core.includes(emoji),`emoji pays encore présent: ${emoji}`);
}

const html=read('index.html');
assert.match(html,/rel="preconnect" href="https:\/\/flagcdn\.com"/);
const css=read('css/layout.css');
for(const cls of ['country-flag-wrap','country-flag','country-flag-fallback']) assert.ok(css.includes(`.${cls}`));

console.log('Release V0.6.7: OK');

const admin=read('js/admin.js');
const adminTest=read('js/admin-test.js');
const data=read('js/data.js');
const sql=read('sql/HOTFIX_V0.6.7_EXISTING_DB.sql');
assert.match(admin,/"test"/);
for(const id of ['adminTestNav','adminTestDays','adminDisableTestsBtn','adminEnableTestsBtn','adminDeleteAllMatchesBtn']) assert.ok(html.includes(id),`UI TEST absente: ${id}`);
for(const fn of ['admin_create_test_schedule_v067','admin_set_test_schedule_enabled_v067','admin_delete_test_schedule_v067','admin_delete_all_matches_v067']) assert.ok(sql.includes(fn),`RPC absente: ${fn}`);
for(const field of ['venue_country','is_test','test_enabled']) assert.ok(data.includes(field),`champ match absent du loader: ${field}`);
assert.match(adminTest,/équipe ne peut pas jouer contre elle-même/i);
assert.match(adminTest,/écris exactement VIDER/i);
console.log('Laboratoire V0.6.7: OK');
