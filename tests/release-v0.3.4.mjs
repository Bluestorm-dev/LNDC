import fs from 'node:fs';
import assert from 'node:assert/strict';
const src=fs.readFileSync(new URL('../supabase/functions/sync-football-data/index.ts', import.meta.url),'utf8');
assert.match(src,/\.eq\("external_id", team\.id\)/,'canonical provider id lookup missing');
assert.doesNotMatch(src,/\.eq\("tla", team\.tla\)/,'TLA must never be used as global identity');
assert.doesNotMatch(src,/\.eq\("short_name", team\.shortName\)/,'short name must never be used as global identity');
assert.match(src,/\.is\("external_provider", null\)/,'manual exact-name merge safeguard missing');
console.log('V0.3.4 identity regression tests: OK');
