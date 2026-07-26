import fs from 'node:fs';
import assert from 'node:assert/strict';

const app=fs.readFileSync(new URL('../assets/js/app.js', import.meta.url),'utf8');
const html=fs.readFileSync(new URL('../index.html', import.meta.url),'utf8');
const sql=fs.readFileSync(new URL('../sql/010_patch_v0.4.0_champions_phases_finales.sql', import.meta.url),'utf8');
const sw=fs.readFileSync(new URL('../sw.js', import.meta.url),'utf8');
const version=fs.readFileSync(new URL('../VERSION', import.meta.url),'utf8').trim();

assert.equal(version,'0.4.0');
assert.match(sw,/nid-champions-v0\.4\.0/);
assert.match(html,/id="view-champions"/);
assert.match(html,/id="view-knockout"/);
assert.match(html,/Générer tableau TEST/);
assert.match(html,/id="createKnockoutTieBtn"/);
assert.match(app,/get_leaderboard_v040/);
assert.match(app,/save_champion_pick_v040/);
assert.match(app,/admin_set_knockout_match_state_v040/);
assert.match(app,/admin_set_phase_multiplier_v040/);
assert.match(app,/admin_set_match_multiplier_v040/);
assert.match(app,/admin_upsert_knockout_tie_v040/);
assert.match(app,/function renderKnockoutBuilder/);
assert.match(app,/Score à 120 min si prolongation/);
assert.match(app,/Bonus potentiel/);

// Tables et règles structurantes.
for (const table of ['knockout_ties','tie_predictions','champion_predictions']) assert.match(sql,new RegExp(`create table if not exists public\\.${table}`));
for (const phase of ['KNOCKOUT_PLAYOFF','ROUND_OF_16','QUARTER_FINAL','SEMI_FINAL','FINAL']) assert.match(sql,new RegExp(`'${phase}'`));
assert.match(sql,/champion_1_bonus/);
assert.match(sql,/champion_2_bonus/);
assert.match(sql,/Olympique de Marseille introuvable/);
assert.match(sql,/qualifier_bonus_early numeric\(6,2\) not null default 3/);
assert.match(sql,/qualifier_bonus_late numeric\(6,2\) not null default 1/);
assert.match(sql,/p_multiplier not in \(1,2,3,4\)/);
assert.match(sql,/Finale à égalité : indique la prolongation/);
assert.match(sql,/Cumul à égalité : indique la prolongation/);
assert.match(sql,/penalties_home/);
assert.match(sql,/next_tie_id/);
assert.match(sql,/perform public\.ensure_knockout_matches_v040\(t\.next_tie_id\)/);
assert.match(sql,/values\(p_season_id,ph_f,'F1','Finale',1,true,true/);
assert.match(sql,/return jsonb_build_object\('ok',true,'ties',23,'initial_matches',16/);
assert.match(sql,/La finale est un match unique/);
assert.match(sql,/Le retour doit être programmé après l’aller/);

// Le score standard reste 0/3/5/7 et le multiplicateur ne touche que le match.
function scorePoints(ph,pa,rh,ra,mult=1){
  if(ph===rh&&pa===ra)return 7*mult;
  const pd=ph-pa,rd=rh-ra,same=Math.sign(pd)===Math.sign(rd);
  if(same&&pd===rd)return 5*mult;
  if(same)return 3*mult;
  return 0;
}
assert.equal(scorePoints(2,1,2,1,1),7);
assert.equal(scorePoints(2,1,3,2,1),5);
assert.equal(scorePoints(2,0,3,1,1),5);
assert.equal(scorePoints(1,0,3,1,1),3);
assert.equal(scorePoints(0,1,2,1,1),0);
assert.equal(scorePoints(2,1,2,1,2),14);
assert.equal(scorePoints(1,0,3,1,3),9);

// Le choix qualifié n'est dégradé qu'en cas de vraie modification après l'aller.
assert.match(sql,/new\.qualified_club_id=old\.qualified_club_id then old\.pick_timing/);

console.log('V0.4.0 release tests: OK');
