"use strict";

// Le Nid des Champions V0.6.4 — accueil, matchs et pronostics
  function renderHome() {
    const welcome=$("#welcomeTitle");
    if(welcome) welcome.textContent=`Salut ${state.profile?.username||"Hibou"}, prêt pour l'Europe ?`;
    const heroAvatar=$("#homeHeroAvatar");
    if(heroAvatar) heroAvatar.innerHTML=avatarHTML(state.profile||{username:"Hibou",avatar_key:"avatar-hibou-humour-personnages-chanceux"},{allowPending:true});

    const now=Date.now();
    const live=state.allMatches.find(m=>m.status==="live");
    const upcoming=[...state.allMatches]
      .filter(m=>m.status!=="cancelled" && (m.status==="live" || new Date(m.kickoff_at).getTime()>now))
      .sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at));
    const next=live||upcoming[0]||null;
    const nextRoot=$("#homeNextMatch");
    const nextAction=$("#homeNextAction");
    if(nextRoot){
      if(!next){
        nextRoot.innerHTML='<div class="home-empty-state"><strong>Aucun match à venir pour le moment.</strong><span>Le Hibou garde un œil sur le calendrier.</span></div>';
      }else{
        const pred=state.predictions.get(next.id);
        const locked=isLocked(next);
        const targetView=next.tie_id?"knockout":"matches";
        const status=next.status==="live"?'<span class="home-live-pill">● LIVE</span>':`<span>${esc(fmtDate(next.kickoff_at))}</span>`;
        nextRoot.innerHTML=`<div class="home-next-meta">${status}<small>${next.stadium?esc(next.stadium):next.tie_id?'Phase finale':'Champions League'}</small></div>
          <div class="home-next-fixture">
            <div class="home-next-team">${crestHTML(next.home_club,true)}<strong>${esc(compactClubName(next.home_club))}</strong>${clubCountryHTML(next.home_club)}</div>
            <div class="home-next-center"><span>${next.status==='live'?`${next.home_score??0} – ${next.away_score??0}`:'VS'}</span><small>${pred?`Ton prono ${pred.home_score}–${pred.away_score}`:locked?'Verrouillé':'Prono à faire'}</small></div>
            <div class="home-next-team">${crestHTML(next.away_club,true)}<strong>${esc(compactClubName(next.away_club))}</strong>${clubCountryHTML(next.away_club)}</div>
          </div>`;
        if(nextAction){nextAction.textContent=next.tie_id?'Ouvrir les phases finales →':'Voir les pronostics →';nextAction.onclick=()=>setView(targetView);}
      }
    }

    const md=selectedMatchday();
    const p=progressFor(state.selectedMatchdayId);
    const pctDone=p.total?Math.round(p.done/p.total*100):0;
    const ring=$("#homeProgressRing");
    if(ring)ring.style.setProperty('--progress',String(pctDone));
    if($("#homeProgressPct"))$("#homeProgressPct").textContent=`${pctDone}%`;
    if($("#homeProgressBadge"))$("#homeProgressBadge").textContent=`${p.done}/${p.total}`;
    if($("#homeProgressTitle"))$("#homeProgressTitle").textContent=md?.name||"Progression";
    if($("#homeProgressText")){
      const left=Math.max(0,p.total-p.done);
      $("#homeProgressText").textContent=!p.total?"Aucun match dans cette journée.":left===0?"Tout est posé. Tu peux respirer jusqu'au coup d'envoi.":`${left} pronostic${left>1?'s':''} encore à poser.`;
    }

    const croot=$("#homeChampionSummary");
    if(croot){
      const st=state.championStatus||{};
      const item=(number)=>{
        const id=number===1?st.first_club_id:st.second_club_id;
        const name=number===1?st.first_club_name:st.second_club_name;
        const open=number===1?st.first_open:st.second_open;
        const def=number===1&&st.first_default;
        const eliminated=number===1?st.first_eliminated_at:st.second_eliminated_at;
        const club=clubById(id);
        const label=number===1?'Champion n°1 · 100 pts':'Champion n°2 · 50 pts';
        const statusText=id?(eliminated?'Éliminé':def?'OM par défaut':'En course'):(open?'À choisir':'Pas encore ouvert');
        return `<div class="home-champion-row ${eliminated?'eliminated':''}"><span class="home-champion-number">${number}</span>${club?crestHTML(club):'<span class="home-champion-placeholder">?</span>'}<span class="home-champion-copy"><small>${label}</small><strong>${esc(name||club?.name||(number===1?'Aucun choix':'En attente'))}</strong></span><b>${esc(statusText)}</b></div>`;
      };
      croot.innerHTML=item(1)+item(2);
    }
  }

  function updateKpis() {
    const mine=state.standings.find(x=>x.user_id===state.user?.id);
    const p=progressFor(state.selectedMatchdayId);
    $("#kpiRank").textContent=mine?`#${mine.rank}`:"—";
    $("#kpiPoints").textContent=mine?.points??0;
    $("#kpiProgress").textContent=`${p.done}/${p.total}`;
    $("#matchdayProgressChip").textContent=`${p.done}/${p.total}`;
  }

  function renderMatchdayTabs() {
    const make = target => {
      if(!target) return;
      target.innerHTML=state.matchdays.map(md=>{
        const p=progressFor(md.id);
        return `<button type="button" class="matchday-tab ${md.id===state.selectedMatchdayId?'active':''}" data-md="${md.id}"><b>J${md.number}</b><span>${p.done}/${p.total}</span></button>`;
      }).join("") || '<span class="muted">Aucune journée.</span>';
      $$('[data-md]',target).forEach(btn=>btn.onclick=()=>selectMatchday(btn.dataset.md));
    };
    make($("#matchdayTabs")); make($("#adminMatchdayTabs"));
  }

  function renderMatchPanels() {
    const panel=$("#matchesPanel");
    if(!panel)return;
    panel.innerHTML=matchdayHTML(true);
    bindMatchControls(panel);
  }

  function groupMatchesByDay(matches) {
    const groups=new Map();
    matches.forEach(m=>{
      const key=new Intl.DateTimeFormat("fr-CA",{year:"numeric",month:"2-digit",day:"2-digit",timeZone:"Europe/Paris"}).format(new Date(m.kickoff_at));
      if(!groups.has(key)) groups.set(key,[]);
      groups.get(key).push(m);
    });
    return [...groups.values()];
  }

  function matchdayHTML(editable) {
    const md=selectedMatchday();
    const p=progressFor(state.selectedMatchdayId);
    const groups=groupMatchesByDay(state.matches);
    const body=groups.map(group=>`<div class="calendar-day"><div class="calendar-day-title"><strong>${esc(fmtShortDate(group[0].kickoff_at))}</strong><span>${group.length} match${group.length>1?'s':''}</span></div>${group.map(m=>matchHTML(m,editable)).join("")}</div>`).join("");
    return `<div class="matchday-head"><div><strong>${esc(md?.name||"Journée")}</strong><div class="progress"><i style="width:${p.pct}%"></i></div></div><span class="chip">${p.done}/${p.total}</span></div><div class="match-list">${body||'<div class="empty">Aucun match dans cette journée.</div>'}</div>`;
  }

  function matchHTML(m,editable) {
    const p=state.predictions.get(m.id), locked=isLocked(m), hs=p?.home_score??0, as=p?.away_score??0;
    const cancelled=m.status==="cancelled";
    const result=m.status==="finished"?`${m.home_score}–${m.away_score}`:m.status==="live"?`${m.home_score??0}–${m.away_score??0}`:"";
    const stateText=cancelled?"🚫 Match annulé":locked?"🔒 Verrouillé":p?"✓ Enregistré":"À pronostiquer";
    const reveal=locked&&!cancelled?`<div class="match-reveal"><button type="button" class="reveal-btn" data-reveal-match="${m.id}">Voir les pronos du Nid</button></div>`:"";
    const hasOdds=[m.odds_home,m.odds_draw,m.odds_away].every(v=>v!==null&&v!==undefined&&Number.isFinite(Number(v)));
    const oddsSource=m.odds_bookmaker||m.odds_provider||"";
    const oddsNote=m.odds_is_test_shifted&&m.odds_source_season?` · source ${m.odds_source_season}`:"";
    const oddsUpdated=m.odds_updated_at?` · maj ${fmtTime(m.odds_updated_at)}`:"";
    const odds=hasOdds?`<div class="match-odds" title="Cotes 1N2 pré-match${oddsSource?` · ${esc(oddsSource)}`:""}${oddsNote}${oddsUpdated}">
      <span class="odds-caption">Cotes 1N2${oddsSource?` · ${esc(oddsSource)}`:""}${oddsNote}${oddsUpdated}</span>
      <span class="odds-pill"><b>1</b>${fmtOdds(m.odds_home)}</span>
      <span class="odds-pill"><b>N</b>${fmtOdds(m.odds_draw)}</span>
      <span class="odds-pill"><b>2</b>${fmtOdds(m.odds_away)}</span>
    </div>`:"";
    return `<article class="match ${statusClass(m.status)} ${m.is_test?'match-test':''}" data-match="${m.id}">
      <div class="match-top"><span>${m.is_test?'<b class="test-pill">TEST</b> · ':''}${esc(fmtTime(m.kickoff_at))}${m.stadium?` · ${esc(m.stadium)}`:""}${m.venue_country?` · ${esc(m.venue_country)}`:""}${m.tie_id?` · ${m.leg_number===2?'retour':'aller'}`:""}</span><span class="match-top-right">${Number(m.points_multiplier||1)>1?`<b class="multiplier-badge">×${Number(m.points_multiplier)}</b>`:""}<span class="status-label ${statusClass(m.status)}">${esc(statusLabel(m.status))}${result?` · ${esc(result)}`:""}${m.penalties_home!=null&&m.penalties_away!=null?` · TAB ${m.penalties_home}–${m.penalties_away}`:""}</span></span></div>
      <div class="teams">
        <div class="team" title="${esc(m.home_club?.name||compactClubName(m.home_club))}">${crestHTML(m.home_club)}<strong>${esc(compactClubName(m.home_club))}</strong>${clubCountryHTML(m.home_club)}</div>
        <div class="prediction-center">
          <div class="scorebox"><div class="score-control"><button data-delta="-1" data-side="home" ${locked||!editable||cancelled?'disabled':''}>−</button><input data-score="home" data-filled="${p?'true':'false'}" inputmode="numeric" min="0" max="99" value="${hs}" ${locked||!editable||cancelled?'disabled':''}/><button data-delta="1" data-side="home" ${locked||!editable||cancelled?'disabled':''}>+</button></div><span class="score-sep">–</span><div class="score-control"><button data-delta="-1" data-side="away" ${locked||!editable||cancelled?'disabled':''}>−</button><input data-score="away" data-filled="${p?'true':'false'}" inputmode="numeric" min="0" max="99" value="${as}" ${locked||!editable||cancelled?'disabled':''}/><button data-delta="1" data-side="away" ${locked||!editable||cancelled?'disabled':''}>+</button></div></div>
          <div class="save-state ${cancelled?'cancelled':locked?'locked':p?'saved':''}">${stateText}</div>${m.tie_id&&m.leg_number===2?'<small class="ko-score-hint">Score à 120 min si prolongation</small>':''}
          ${reveal}
        </div>
        <div class="team" title="${esc(m.away_club?.name||compactClubName(m.away_club))}">${crestHTML(m.away_club)}<strong>${esc(compactClubName(m.away_club))}</strong>${clubCountryHTML(m.away_club)}</div>
      </div>
      ${odds}
    </article>`;
  }

  function bindMatchControls(root) {
    $$('[data-reveal-match]',root).forEach(btn=>btn.onclick=()=>showMatchPredictions(btn.dataset.revealMatch));
    const cards=$$('[data-match]',root);
    cards.forEach((card,cardIndex)=>{
      const id=card.dataset.match, home=$("[data-score=home]",card), away=$("[data-score=away]",card);
      if(!home||home.disabled) return;
      const save=debounce(()=>savePrediction(id,Number(home.value),Number(away.value),card),280);
      const nextEditableHome=()=>{
        for(let i=cardIndex+1;i<cards.length;i++){
          const candidate=$("[data-score=home]",cards[i]);
          if(candidate&&!candidate.disabled)return candidate;
        }
        return null;
      };
      bindAlternatingScorePair(home,away,save,nextEditableHome);
      $$('[data-delta]',card).forEach(btn=>{
        btn.onpointerdown=e=>e.preventDefault();
        btn.onclick=()=>{
          const input=$(`[data-score=${btn.dataset.side}]`,card);
          input.value=String(Math.max(0,Math.min(99,Number(input.value||0)+Number(btn.dataset.delta))));
          input.dataset.filled="true";
          save();
        };
      });
    });
  }

  function bindAlternatingScorePair(home,away,onChange,getNextHome=()=>null) {
    const inputs=[home,away];
    const pair=home.closest?.("[data-match]")||home.parentElement;
    const resetCycle=()=>{home.dataset.cycleTouched="false";away.dataset.cycleTouched="false";};
    resetCycle();

    const advance=input=>{
      const other=input===home?away:home;
      input.dataset.cycleTouched="true";
      const otherTouched=other.dataset.cycleTouched==="true";
      requestAnimationFrame(()=>{
        if(!otherTouched){
          other.focus({preventScroll:true});
          return;
        }
        const next=getNextHome();
        resetCycle();
        if(next){
          next.focus({preventScroll:true});
          next.closest?.("[data-match]")?.scrollIntoView?.({behavior:"smooth",block:"nearest"});
        }
      });
    };

    inputs.forEach(input=>{
      input.onkeydown=e=>{
        if(/^\d$/.test(e.key) && !e.ctrlKey && !e.metaKey && !e.altKey){
          e.preventDefault();
          input.value=e.key;
          input.dataset.filled="true";
          onChange();
          advance(input);
        }
      };
      input.oninput=()=>{
        input.value=String(Math.max(0,Math.min(99,parseInt(input.value||"0",10)||0)));
        input.dataset.filled="true";
        onChange();
        advance(input);
      };
    });

    pair?.addEventListener?.("focusout",()=>setTimeout(()=>{
      if(!pair.contains?.(document.activeElement))resetCycle();
    },0));
  }

  async function savePrediction(matchId,home,away,card) {
    const m=state.allMatches.find(x=>x.id===matchId);
    if(!m||isLocked(m)||m.status==="cancelled") return;
    const status=$(".save-state",card); status.textContent="Enregistrement…"; status.className="save-state";
    try {
      if(demoMode) {
        const key=`${state.user.id}:${matchId}`, all=JSON.parse(localStorage.getItem("nidc_demo_predictions")||"{}");
        all[key]={id:key,match_id:matchId,user_id:state.user.id,home_score:home,away_score:away,points:0,updated_at:new Date().toISOString()};
        localStorage.setItem("nidc_demo_predictions",JSON.stringify(all)); state.predictions.set(matchId,all[key]); buildDemoStandings(); buildLocalHistory();
      } else {
        const {data,error}=await sb.from("predictions").upsert({user_id:state.user.id,match_id:matchId,home_score:home,away_score:away},{onConflict:"user_id,match_id"}).select("id,match_id,home_score,away_score,points,updated_at").single();
        if(error) throw error;
        state.predictions.set(matchId,data);
        const {data:hist}=await sb.rpc("get_my_prediction_history",{p_season_id:state.season.id});
        state.history=hist||[];
      }
      status.textContent="✓ Enregistré"; status.className="save-state saved";
      await loadRankingData(state.rankingScope,false); updateKpis(); renderRanking(); renderCollectiveStats(); renderHistory(); renderMatchdayTabs();
      const pr=progressFor(state.selectedMatchdayId);
      if(pr.total>0&&pr.done===pr.total) toast("🦉 Journée complète. Le carnet est fermé… enfin presque.");
    } catch(err) { status.textContent="Erreur d'enregistrement"; status.className="save-state red"; toast(friendlyError(err),"error"); }
  }

  function scorePoints(ph,pa,rh,ra,mult=1) {
    if(rh==null||ra==null)return 0;
    const s=state.season;
    if(ph===rh&&pa===ra)return Number(s.points_exact??7)*mult;
    const predDiff=ph-pa, realDiff=rh-ra, sameResult=Math.sign(predDiff)===Math.sign(realDiff);
    if(sameResult&&predDiff===realDiff)return Number(s.points_difference??5)*mult;
    if(sameResult)return Number(s.points_result??3)*mult;
    return Number(s.points_wrong??0)*mult;
  }

  function buildDemoStandings() {
    state.standings=buildDemoLeaderboard("general");
  }

  function demoPredictionPool() {
    const all=JSON.parse(localStorage.getItem("nidc_demo_predictions")||"{}");
    const seeded={
      "demo-ju:m1":{home_score:2,away_score:1},"demo-ju:m2":{home_score:1,away_score:1},"demo-ju:m3":{home_score:1,away_score:2},"demo-ju:m4":{home_score:2,away_score:0},
      "demo-tourteau:m1":{home_score:1,away_score:2},"demo-tourteau:m2":{home_score:2,away_score:0},"demo-tourteau:m3":{home_score:2,away_score:2},"demo-tourteau:m4":{home_score:1,away_score:0}
    };
    Object.entries(seeded).forEach(([k,v])=>{if(!all[k])all[k]={id:k,user_id:k.split(":")[0],match_id:k.split(":")[1],...v};});
    return all;
  }

  function buildDemoLeaderboard(scope="general") {
    const all=demoPredictionPool();
    const evening=state.selectedEveningDate||deriveEveningDate();
    const scoped=state.allMatches.filter(m=>scope==="general"||(scope==="matchday"&&m.matchday_id===state.selectedMatchdayId)||(scope==="evening"&&localDateKey(m.kickoff_at)===evening));
    const rows=state.demoUsers.filter(u=>u.status==="active").map(u=>{
      let points=0,official=0,exacts=0,diffs=0,good=0,played=0;
      scoped.forEach(m=>{
        const p=all[`${u.id}:${m.id}`]; if(!p||!["finished","live"].includes(m.status)||m.home_score==null||m.away_score==null)return;
        played++; const pts=scorePoints(p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier||1); points+=pts; if(m.status==="finished")official+=pts;
        const exact=p.home_score===m.home_score&&p.away_score===m.away_score;
        const same=Math.sign(p.home_score-p.away_score)===Math.sign(m.home_score-m.away_score);
        if(exact)exacts++; else if(same&&(p.home_score-p.away_score)===(m.home_score-m.away_score))diffs++; if(same)good++;
      });
      return{user_id:u.id,username:u.username,avatar_key:u.avatar_key,club_heart:u.club_heart,points,official_points:official,exact_scores:exacts,good_differences:diffs,good_results:good,played,average:played?points/played:0,precision_pct:played?good*100/played:0,previous_rank:null,variation:0};
    });
    rows.sort((a,b)=>b.points-a.points||b.exact_scores-a.exact_scores||b.average-a.average||b.good_differences-a.good_differences||b.played-a.played||a.username.localeCompare(b.username));
    rows.forEach((r,i)=>{r.rank=i+1;r.above_gap=i?rows[i-1].points-r.points:null;r.below_gap=i<rows.length-1?r.points-rows[i+1].points:null;});
    return rows;
  }

  function buildDemoCollective(scope="general") {
    const all=demoPredictionPool(), evening=state.selectedEveningDate||deriveEveningDate();
    const scoped=state.allMatches.filter(m=>(scope==="general"||(scope==="matchday"&&m.matchday_id===state.selectedMatchdayId)||(scope==="evening"&&localDateKey(m.kickoff_at)===evening))&&isLocked(m));
    let home=0,draw=0,away=0,total=0,settled=0,correct=0,exact=0; const scores=new Map();
    Object.values(all).forEach(p=>{const m=scoped.find(x=>x.id===p.match_id);if(!m)return;total++;const d=p.home_score-p.away_score;if(d>0)home++;else if(d<0)away++;else draw++;const key=`${p.home_score}–${p.away_score}`;scores.set(key,(scores.get(key)||0)+1);if(["live","finished"].includes(m.status)&&m.home_score!=null&&m.away_score!=null){settled++;const same=Math.sign(d)===Math.sign(m.home_score-m.away_score);if(same)correct++;if(p.home_score===m.home_score&&p.away_score===m.away_score)exact++;}});
    return{total_predictions:total,home_picks:home,draw_picks:draw,away_picks:away,top_scores:[...scores].sort((a,b)=>b[1]-a[1]).slice(0,5).map(([score,count])=>({score,count})),exact_predictions:exact,settled_predictions:settled,reliability_pct:settled?correct*100/settled:0};
  }

  function buildLocalHistory() {
    state.history=state.allMatches.map(m=>{
      const p=state.predictions.get(m.id); if(!p)return null;
      const md=state.matchdays.find(x=>x.id===m.matchday_id);
      return {match_id:m.id,matchday_id:m.matchday_id,matchday_number:md?.number,matchday_name:md?.name,kickoff_at:m.kickoff_at,match_status:m.status,home_name:m.home_club.name,home_short:m.home_club.short_name,home_logo_url:publicLogoUrl(m.home_club),away_name:m.away_club.name,away_short:m.away_club.short_name,away_logo_url:publicLogoUrl(m.away_club),prediction_home:p.home_score,prediction_away:p.away_score,result_home:m.home_score,result_away:m.away_score,points:m.status==="finished"?scorePoints(p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier||1):0,prediction_updated_at:p.updated_at,modification_count:1};
    }).filter(Boolean).sort((a,b)=>new Date(b.kickoff_at)-new Date(a.kickoff_at));
  }
