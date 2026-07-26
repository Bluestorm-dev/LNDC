import fs from 'node:fs';
import assert from 'node:assert/strict';

const app=fs.readFileSync(new URL('../assets/js/app.js', import.meta.url),'utf8');
const html=fs.readFileSync(new URL('../index.html', import.meta.url),'utf8');
const css=fs.readFileSync(new URL('../assets/css/app.css', import.meta.url),'utf8');
const sql=fs.readFileSync(new URL('../sql/010_patch_v0.4.0_champions_phases_finales.sql', import.meta.url),'utf8');
const sw=fs.readFileSync(new URL('../sw.js', import.meta.url),'utf8');
const version=fs.readFileSync(new URL('../VERSION', import.meta.url),'utf8').trim();

assert.equal(version,'0.4.1');
assert.match(sw,/nid-champions-v0\.4\.1/);

// V0.4.1 navigation / UX.
assert.match(html,/class="sidebar"/);
assert.match(html,/class="side-nav"/);
assert.match(html,/id="pageTitle"/);
assert.doesNotMatch(html,/id="view-champions"/);
assert.doesNotMatch(html,/id="homeMatchday"/);
assert.match(html,/id="homeNextMatch"/);
assert.match(html,/id="homeChampionSummary"/);
assert.match(html,/id="view-profile"/);
assert.match(html,/id="championFirstCard"/);
assert.match(html,/id="championSecondCard"/);
assert.match(html,/Profil & champions/);
assert.match(html,/OM est attribué automatiquement/);
assert.match(app,/if\(name === "champions"\) name = "profile"/);
assert.match(app,/function renderHome\(\)/);
assert.match(app,/function renderChampions\(\)/);
assert.match(app,/save_champion_pick_v040/);
assert.match(app,/get_champion_status_v040/);

// Le motif à petits points de l'ancienne UI ne doit plus exister.
assert.doesNotMatch(css,/background-size:57px 57px/);
assert.doesNotMatch(css,/radial-gradient\(circle,#fff 0 1px,transparent 1\.5px\)/);
assert.match(css,/V0\.4\.1 — Refonte UX\/UI Champions League/);
assert.match(css,/--sidebar-w:268px/);
assert.match(css,/\.home-dashboard/);
assert.match(css,/\.profile-champion-grid/);

// Non-régression moteur V0.4.0.
assert.match(html,/id="view-knockout"/);
assert.match(html,/Générer tableau TEST/);
assert.match(app,/get_leaderboard_v040/);
assert.match(app,/admin_set_knockout_match_state_v040/);
assert.match(app,/admin_set_phase_multiplier_v040/);
assert.match(app,/admin_set_match_multiplier_v040/);
for (const table of ['knockout_ties','tie_predictions','champion_predictions']) {
  assert.match(sql,new RegExp(`create table if not exists public\\.${table}`));
}
assert.match(sql,/qualifier_bonus_early numeric\(6,2\) not null default 3/);
assert.match(sql,/qualifier_bonus_late numeric\(6,2\) not null default 1/);
assert.match(sql,/p_multiplier not in \(1,2,3,4\)/);

console.log('V0.4.1 release tests: OK');
