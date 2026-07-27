import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');

assert.equal(read('VERSION').trim(),'0.6.6');
assert.match(read('config.js'),/APP_VERSION:\s*"0\.6\.6"/);
assert.match(read('config.example.js'),/APP_VERSION:\s*"0\.6\.6"/);
assert.match(read('sw.js'),/nid-champions-v0\.6\.6/);
assert.equal(JSON.parse(read('assets/assets-manifest.json')).version,'0.6.6');

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

console.log('Release V0.6.6: OK');
