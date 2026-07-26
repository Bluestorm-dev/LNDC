"use strict";

// Le Nid des Champions V0.5.5 — champions et phases finales
  function findClubByHeart(value) {
    const normalize=v=>String(v||"").normalize("NFD").replace(/[\u0300-\u036f]/g,"").trim().toLocaleLowerCase("fr");
    const needle=normalize(value);
    if(!needle)return null;
    const exact=state.clubs.find(c=>[c.name,c.short_name,c.tla].filter(Boolean).some(v=>normalize(v)===needle));
    if(exact)return exact;
    if(needle.length<4)return null;
    const fuzzy=state.clubs.filter(c=>[c.name,c.short_name].filter(Boolean).some(v=>{const x=normalize(v);return x.includes(needle)||needle.includes(x);}));
    return fuzzy.length===1?fuzzy[0]:null;
  }


  function championLockText(open,closeAt){
    if(open) return closeAt?`Ouvert · jusqu'au ${fmtDate(closeAt)}`:"Ouvert";
    return "🔒 Verrouillé";
  }

  function championPickHTML(number) {
    const st=state.championStatus||{};
    const open=number===1?st.first_open:st.second_open;
    const clubId=number===1?st.first_club_id:st.second_club_id;
    const clubName=number===1?st.first_club_name:st.second_club_name;
    const eliminated=number===1?st.first_eliminated_at:st.second_eliminated_at;
    const points=number===1?Number(st.first_points||0):Number(st.second_points||0);
    const candidates=state.championCandidates[number]||[];
    const currentClub=clubById(clubId)||candidates.find(c=>c.club_id===clubId)||null;
    const selected=currentClub?`<div class="champion-current ${eliminated?'eliminated':''}">${crestHTML(currentClub,true)}<div><span>${number===1&&st.first_default?'🦉 OM attribué par défaut':'Ton choix'}</span><strong>${esc(clubName||currentClub.name||'')}</strong>${clubCountryHTML(currentClub)}<small>${eliminated?'Éliminé · le Hibou a sorti le mouchoir.':points?`🏆 +${points} points`:'Toujours en course'}</small></div></div>`:'';
    if(!open){
      if(selected)return selected;
      return `<div class="champion-locked-empty"><b>${number===1?'OM attribué automatiquement si aucun choix n’a été fait.':'Le deuxième choix n’était pas renseigné.'}</b><span>Le choix est désormais verrouillé.</span></div>`;
    }
    if(number===2&&!candidates.length)return `<div class="champion-locked-empty"><b>Pas encore ouvert.</b><span>Le deuxième champion apparaît une fois la phase de ligue terminée et le tableau final connu.</span></div>`;
    const opts=candidates.map(c=>{const fullClub=clubById(c.club_id||c.id)||c;const country=clubCountry(fullClub);return `<option value="${c.club_id||c.id}" ${String(c.club_id||c.id)===String(clubId)?'selected':''}>${esc(c.short_name||c.name)} — ${esc(c.name)}${country.name?` · ${esc(country.name)}`:''}</option>`;}).join('');
    return `${selected}<div class="champion-picker"><select data-champion-select="${number}"><option value="">Choisir un club…</option>${opts}</select><button class="btn ${number===1?'gold':''} small" data-save-champion="${number}">Enregistrer</button></div>${number===1?'<p class="champion-rule">Pas de choix au coup d’envoi du premier match ? <b>Olympique de Marseille</b> devient ton champion. Pas de réclamation au plumage.</p>':'<p class="champion-rule">Le même club peut être choisi deux fois : all-in possible à <b>150 points</b>.</p>'}`;
  }

  function renderChampions() {
    if(!$("#championFirstBody"))return;
    const st=state.championStatus||{};
    $("#championFirstLock").textContent=championLockText(Boolean(st.first_open),st.first_close_at);
    $("#championSecondLock").textContent=championLockText(Boolean(st.second_open),st.second_close_at);
    $("#championFirstBody").innerHTML=championPickHTML(1);
    $("#championSecondBody").innerHTML=championPickHTML(2);
    $$('[data-save-champion]').forEach(btn=>btn.onclick=()=>saveChampionPick(Number(btn.dataset.saveChampion)));
    const board=$("#championBoard");
    const sections=[1,2].map(n=>{
      const rows=state.championBoards[n]||[];
      const open=n===1?st.first_open:st.second_open;
      if(open)return `<div class="champion-board-section"><h4>Choix ${n} · ${n===1?'100':'50'} pts</h4><div class="secret-picks">🔒 Choix cachés jusqu'au verrouillage.</div></div>`;
      return `<div class="champion-board-section"><h4>Choix ${n} · ${n===1?'100':'50'} pts</h4>${rows.length?rows.map(r=>{const c=clubById(r.club_id);return `<div class="champion-board-row">${c?crestHTML(c):''}<strong>${esc(r.username)}</strong><span>${esc(r.club_name)}</span><b class="${r.eliminated_at?'red':''}">${r.points?`+${r.points}`:r.eliminated_at?'Éliminé':'En course'}</b></div>`}).join(''):'<div class="empty">Aucun choix enregistré.</div>'}</div>`;
    }).join('');
    board.innerHTML=sections;
  }

  async function saveChampionPick(number){
    const select=$(`[data-champion-select="${number}"]`); const clubId=select?.value;
    if(!clubId)return toast("Choisis d’abord un club.","error");
    try{
      if(demoMode){
        const all=JSON.parse(localStorage.getItem("nidc_demo_champions")||"{}");all[`${state.user.id}:${number}`]={club_id:clubId};localStorage.setItem("nidc_demo_champions",JSON.stringify(all));loadDemoChampionState();
      }else{
        const {error}=await sb.rpc("save_champion_pick_v040",{p_pick_number:number,p_club_id:clubId,p_season_id:state.season.id});if(error)throw error;await loadChampionData();
      }
      renderChampions();renderHome();await loadRankingData(state.rankingScope,false);renderRanking();toast(number===1?"🏆 Premier champion enregistré et gardé secret.":"🏆 Deuxième champion enregistré et gardé secret.");
    }catch(err){toast(friendlyError(err),"error");}
  }

  const KO_PHASES=["KNOCKOUT_PLAYOFF","ROUND_OF_16","QUARTER_FINAL","SEMI_FINAL","FINAL"];
  function tieMatches(tie){return state.allMatches.filter(m=>m.tie_id===tie.id).sort((a,b)=>Number(a.leg_number||1)-Number(b.leg_number||1));}
  function aggregateForTie(tie){
    let a=0,b=0;tieMatches(tie).filter(m=>["live","finished"].includes(m.status)&&m.home_score!=null&&m.away_score!=null).forEach(m=>{
      if(m.home_club?.id===tie.team_a_club_id){a+=Number(m.home_score);b+=Number(m.away_score)}else{a+=Number(m.away_score);b+=Number(m.home_score)}
    });return{a,b};
  }
  function tiePredictionOpen(tie){const close=tie.is_single_match?tie.leg1_kickoff_at:tie.leg2_kickoff_at;return tie.status!=="finished"&&tie.status!=="cancelled"&&close&&new Date(close).getTime()>Date.now()&&tie.team_a_club_id&&tie.team_b_club_id;}
  function qualifierBonusNow(tie){return new Date().getTime()<new Date(tie.leg1_kickoff_at).getTime()?Number(tie.qualifier_bonus_early||3):Number(tie.qualifier_bonus_late||1);}

  function renderKnockout(){
    const tabs=$("#knockoutPhaseTabs"),panel=$("#knockoutPanel"),summary=$("#knockoutSummary");if(!tabs||!panel)return;
    const phases=state.phases.filter(p=>KO_PHASES.includes(p.code)).sort((a,b)=>a.sort_order-b.sort_order);
    if(!phases.some(p=>p.code===state.selectedKnockoutPhase))state.selectedKnockoutPhase=phases.find(p=>state.knockoutTies.some(t=>t.phase_id===p.id))?.code||phases[0]?.code||"KNOCKOUT_PLAYOFF";
    tabs.innerHTML=phases.map(p=>{const count=state.knockoutTies.filter(t=>t.phase_id===p.id).length;return `<button class="${p.code===state.selectedKnockoutPhase?'active':''}" data-ko-phase="${p.code}"><b>${esc(p.name)}</b><span>${count}</span></button>`}).join('');
    $$('[data-ko-phase]',tabs).forEach(b=>b.onclick=()=>{state.selectedKnockoutPhase=b.dataset.koPhase;renderKnockout();});
    const phase=phaseByCode(state.selectedKnockoutPhase);const ties=state.knockoutTies.filter(t=>t.phase_id===phase?.id).sort((a,b)=>a.sort_order-b.sort_order);
    const done=ties.filter(t=>t.status==="finished").length;
    summary.innerHTML=phase?`<span class="chip">${esc(phase.name)}</span><span class="chip">${done}/${ties.length} confrontation${ties.length>1?'s':''} terminée${done>1?'s':''}</span><span class="chip multiplier-chip">×${Number(phase.default_multiplier||1)}</span>`:'';
    panel.innerHTML=ties.length?ties.map(tie=>knockoutTieHTML(tie)).join(''):'<article class="card card-pad"><div class="empty">Aucune confrontation dans cette phase. L’Admin peut générer le tableau TEST ou préparer le tirage réel.</div></article>';
    bindMatchControls(panel);
    $$('[data-save-qualifier]',panel).forEach(btn=>btn.onclick=()=>saveTiePrediction(btn.dataset.saveQualifier));
  }

  function knockoutTieHTML(tie){
    const aClub=clubById(tie.team_a_club_id),bClub=clubById(tie.team_b_club_id),qClub=clubById(tie.qualified_club_id),agg=aggregateForTie(tie),matches=tieMatches(tie),tp=state.tiePredictions.get(tie.id),open=tiePredictionOpen(tie),bonus=qualifierBonusNow(tie);
    const earned=tie.status==='finished'&&tp&&tp.qualified_club_id===tie.qualified_club_id?(tp.pick_timing==='early'?Number(tie.qualifier_bonus_early||3):Number(tie.qualifier_bonus_late||1)):0;
    const qualifier=(aClub&&bClub)?`<div class="qualifier-box ${open?'':'locked'}"><div><span class="eyebrow">Qualifié</span><strong>${qClub?`${esc(qClub.name)} · qualifié`:(tp?`Ton choix : ${esc(clubById(tp.qualified_club_id)?.name||'')}`:'Choisis qui passe')}</strong><small>${tie.status==='finished'?`Bonus obtenu : +${earned}`:open?`Bonus potentiel : +${bonus} pt${bonus>1?'s':''}${bonus<Number(tie.qualifier_bonus_early||3)?' · choix modifié après l’aller':''}`:'Choix verrouillé'}</small></div>${open?`<div class="qualifier-actions"><select data-qualifier-select="${tie.id}"><option value="${aClub.id}" ${tp?.qualified_club_id===aClub.id?'selected':''}>${esc(aClub.short_name||aClub.name)}</option><option value="${bClub.id}" ${tp?.qualified_club_id===bClub.id?'selected':''}>${esc(bClub.short_name||bClub.name)}</option></select><button class="btn small" data-save-qualifier="${tie.id}">Valider</button></div>`:''}</div>`:'<div class="qualifier-box waiting">Le prochain adversaire sera injecté automatiquement après la confrontation précédente.</div>';
    const legs=matches.length?matches.map((m,i)=>`<div class="ko-leg"><div class="ko-leg-label"><b>${tie.is_single_match?'Finale':`Match ${i===0?'aller':'retour'}`}</b><span>${m.leg_number===2||tie.is_single_match?'Score pronostiqué à 120 min si prolongation':'90 minutes'}</span>${Number(m.points_multiplier||1)>1?`<strong>×${Number(m.points_multiplier)}</strong>`:''}</div>${matchHTML(m,true)}</div>`).join(''):'<div class="ko-placeholder">Adversaire en attente · les matchs seront créés automatiquement.</div>';
    return `<article class="card knockout-tie ${tie.status}"><div class="tie-head"><div><span class="eyebrow">${esc(tie.code)}</span><h3>${esc(tie.label)}</h3></div><div class="aggregate-score"><span>${aClub?esc(aClub.short_name||aClub.name):'?'}</span><b>${agg.a}–${agg.b}</b><span>${bClub?esc(bClub.short_name||bClub.name):'?'}</span><small>Cumul</small></div></div><div class="tie-teams"><div>${aClub?crestHTML(aClub,true):''}<strong>${aClub?esc(aClub.name):'À déterminer'}</strong>${aClub?clubCountryHTML(aClub):''}</div><span>VS</span><div>${bClub?crestHTML(bClub,true):''}<strong>${bClub?esc(bClub.name):'À déterminer'}</strong>${bClub?clubCountryHTML(bClub):''}</div></div>${legs}${qualifier}</article>`;
  }

  async function saveTiePrediction(tieId){
    const tie=state.knockoutTies.find(t=>t.id===tieId),select=$(`[data-qualifier-select="${tieId}"]`);if(!tie||!select?.value)return;
    try{
      if(demoMode){const all=JSON.parse(localStorage.getItem("nidc_demo_tie_predictions")||"{}");const key=`${state.user.id}:${tieId}`;all[key]={id:key,user_id:state.user.id,tie_id:tieId,qualified_club_id:select.value,pick_timing:new Date()<new Date(tie.leg1_kickoff_at)?'early':'late',points:0};localStorage.setItem("nidc_demo_tie_predictions",JSON.stringify(all));state.tiePredictions.set(tieId,all[key]);}
      else{const {data,error}=await sb.from("tie_predictions").upsert({user_id:state.user.id,tie_id:tieId,qualified_club_id:select.value},{onConflict:"user_id,tie_id"}).select("id,tie_id,qualified_club_id,pick_timing,points,updated_at").single();if(error)throw error;state.tiePredictions.set(tieId,data);}
      renderKnockout();toast(`Qualifié enregistré · bonus potentiel +${qualifierBonusNow(tie)}.`);
    }catch(err){toast(friendlyError(err),"error");}
  }
