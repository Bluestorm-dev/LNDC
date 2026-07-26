"use strict";

// Le Nid des Champions V0.5.5 — historique, classements et live
  function renderHistory() {
    const panel=$("#historyPanel"); if(!panel)return;
    const rows=state.history.filter(r=>["finished","cancelled"].includes(r.match_status));
    $("#historyCount").textContent=String(rows.length);
    panel.innerHTML=rows.length?rows.map(r=>{
      const cancelled=r.match_status==="cancelled";
      return `<div class="history-row"><div class="history-meta"><b>J${r.matchday_number??"?"}</b><span>${esc(fmtDate(r.kickoff_at))}</span></div><div class="history-fixture"><span>${esc(r.home_short)}</span><strong>${r.prediction_home}–${r.prediction_away}</strong><span>${esc(r.away_short)}</span></div><div class="history-result">${cancelled?'Annulé':`Résultat ${r.result_home}–${r.result_away}`}</div><div class="history-points ${Number(r.points)>0?'positive':''}">${cancelled?'—':`${Number(r.points||0)} pts`}</div></div>`;
    }).join(""):'<div class="empty">Ton historique apparaîtra ici dès qu’un match sera terminé.</div>';
  }

  function renderRanking() {
    const body=$("#rankingBody"); if(!body)return;
    let rows=[...(state.rankingRows||[])];
    if(state.rankingScope==="precision") rows.sort((a,b)=>Number(b.precision_pct||0)-Number(a.precision_pct||0)||Number(b.exact_scores||0)-Number(a.exact_scores||0)||Number(b.points||0)-Number(a.points||0)||String(a.username).localeCompare(String(b.username)));
    if(state.rankingScope==="exacts") rows.sort((a,b)=>Number(b.exact_scores||0)-Number(a.exact_scores||0)||Number(b.points||0)-Number(a.points||0)||Number(b.precision_pct||0)-Number(a.precision_pct||0)||String(a.username).localeCompare(String(b.username)));
    const metric=r=>state.rankingScope==="precision"?Number(r.precision_pct||0):state.rankingScope==="exacts"?Number(r.exact_scores||0):Number(r.points||0);
    rows=rows.map((r,i)=>({...r,display_rank:i+1,display_above:i?metric(rows[i-1])-metric(r):null,display_below:i<rows.length-1?metric(r)-metric(rows[i+1]):null}));
    const scopeLabel={general:"Général",matchday:`J${selectedMatchday()?.number||"?"}`,evening:"Soirée",precision:"Précision",exacts:"Scores exacts"}[state.rankingScope]||"Général";
    $("#rankingSubtitle").textContent=state.rankingScope==="general"?"Points → exacts → moyenne → bons écarts → pronostics joués.":state.rankingScope==="matchday"?`Classement limité à ${selectedMatchday()?.name||"la journée sélectionnée"}.`:state.rankingScope==="evening"?`Classement de la soirée du ${state.selectedEveningDate||"—"}.`:state.rankingScope==="precision"?"Taux de bons résultats sur les rencontres scorées.":"Qui empile le plus de scores parfaitement exacts.";
    $("#rankingContext").innerHTML=`<span class="context-pill">${esc(scopeLabel)}</span><span class="context-pill">${rows.length} joueur${rows.length>1?'s':''}</span>${state.rankingScope==="general"?'<span class="context-pill">Variation = rang avant la soirée</span>':''}`;
    $("#collectiveScopeChip").textContent=scopeLabel;
    const gapText=value=>value==null?"—":`${Number(value).toFixed(state.rankingScope==="precision"?1:0)}${state.rankingScope==="precision"?' pt%':''}`;
    const rowHTML=r=>{
      const rank=Number(r.display_rank), variation=state.rankingScope==="general"?Number(r.variation||0):0;
      const varHtml=variation>0?`<span class="rank-var up">▲ ${variation}</span>`:variation<0?`<span class="rank-var down">▼ ${Math.abs(variation)}</span>`:`<span class="rank-var same">—</span>`;
      const gapAbove=r.display_above==null?"—":`↑ <b>${gapText(r.display_above)}</b>`;
      const gapBelow=r.display_below==null?"—":`↓ <b>${gapText(r.display_below)}</b>`;
      return `<tr class="${r.user_id===state.user?.id?'me ':''}${rank<=3?`podium-${rank}`:''}"><td><span class="rank-medal">${rank}</span></td><td>${varHtml}</td><td><div class="player-cell">${avatarHTML(r)}<span class="player-name-stack"><strong>${esc(r.username)}</strong>${teamForUser(r.user_id)?`<small>${esc(teamForUser(r.user_id).team_name||'')}</small>`:''}</span></div></td><td><b>${Number(r.points||0).toFixed(0)}</b>${Number(r.points||0)!==Number(r.official_points||0)?`<small class="muted"> · ${Number(r.official_points||0).toFixed(0)} off.</small>`:''}</td><td>${Number(r.exact_scores||0)}</td><td><span class="precision-pill">${Number(r.precision_pct||0).toFixed(1)}%</span></td><td>${Number(r.average||0).toFixed(2)}</td><td><div class="gap-cell">${gapAbove}<br>${gapBelow}</div></td><td>${Number(r.played||0)}</td></tr>`;
    };
    body.innerHTML=rows.map(rowHTML).join("")||'<tr><td colspan="9" class="empty">Aucun classement.</td></tr>';

    const mine=rows.find(r=>r.user_id===state.user?.id), sticky=$("#myRankingSticky");
    if(sticky){
      sticky.classList.toggle("hidden",!mine);
      if(mine){
        const variation=state.rankingScope==="general"?Number(mine.variation||0):0;
        const varHtml=variation>0?`<span class="rank-var up">▲ ${variation}</span>`:variation<0?`<span class="rank-var down">▼ ${Math.abs(variation)}</span>`:`<span class="rank-var same">—</span>`;
        sticky.innerHTML=`<span class="sticky-rank">#${mine.display_rank}</span>${varHtml}<span class="sticky-name">${avatarHTML(mine)}<b>${esc(mine.username)}</b></span><span><b>${Number(mine.points||0).toFixed(0)}</b><small> pts</small></span><span><b>${Number(mine.exact_scores||0)}</b><small> exacts</small></span><span><b>${Number(mine.precision_pct||0).toFixed(1)}%</b><small> précision</small></span>`;
      }
    }
    updateKpis();
  }

  function renderCollectiveStats() {
    const c=state.collectiveStats||{}; const total=Number(c.total_predictions||0);
    const hp=pct(c.home_picks,total),dp=pct(c.draw_picks,total),ap=pct(c.away_picks,total);
    [["#pickHomeBar",hp],["#pickDrawBar",dp],["#pickAwayBar",ap]].forEach(([sel,v])=>{const el=$(sel);if(el)el.style.width=`${v}%`;});
    if($("#pickHomePct"))$("#pickHomePct").textContent=`${hp}%`;
    if($("#pickDrawPct"))$("#pickDrawPct").textContent=`${dp}%`;
    if($("#pickAwayPct"))$("#pickAwayPct").textContent=`${ap}%`;
    const scores=Array.isArray(c.top_scores)?c.top_scores:[];
    if($("#topScores"))$("#topScores").innerHTML=scores.length?scores.map(x=>`<span class="score-chip">${esc(x.score)}<small>×${Number(x.count||0)}</small></span>`).join(""):'<span class="muted">Aucune donnée verrouillée.</span>';
    const reliability=Number(c.reliability_pct||0);
    if($("#reliabilityPct"))$("#reliabilityPct").textContent=`${reliability.toFixed(1)}%`;
    if($("#reliabilityText"))$("#reliabilityText").textContent=Number(c.settled_predictions||0)?`${Number(c.exact_predictions||0)} exact(s) · ${Number(c.settled_predictions||0)} pronostic(s) confrontés à un score.`:"Les résultats vont bientôt tester les plumes.";
  }

  function renderLiveTicker() {
    const live=state.allMatches.filter(m=>m.status==="live");
    const ticker=$("#liveTicker"), badge=$("#rankingLiveBadge");
    if(ticker){ticker.classList.toggle("hidden",!live.length);ticker.innerHTML=live.length?`<span class="live-word">LIVE</span>${live.map(m=>`<b>${esc(m.home_club?.short_name||"?")} ${m.home_score??0}–${m.away_score??0} ${esc(m.away_club?.short_name||"?")}</b>`).join(" · ")}`:"";}
    if(badge){badge.classList.toggle("live",!!live.length);badge.innerHTML=live.length?`<span class="pulse-dot"></span><b>CLASSEMENT LIVE</b><small>${live.length} match${live.length>1?'s':''} en cours</small>`:`<span class="pulse-dot"></span><b>HORS LIVE</b><small>Aucun match en cours</small>`;}
  }

  function renderSeason() {
    const total=state.matchdays.length;
    const finished=state.matchdays.filter(md=>{
      const ms=state.allMatches.filter(m=>m.matchday_id===md.id);
      return ms.length>0 && ms.every(m=>["finished","cancelled"].includes(m.status));
    }).length;
    $("#seasonProgressTitle").textContent=`${finished}/${total} journées terminées`;
    const koTotal=state.knockoutTies.length,koDone=state.knockoutTies.filter(t=>t.status==="finished").length;
    $("#seasonProgressText").textContent=total?`${state.allMatches.length} rencontres enregistrées · phases finales ${koDone}/${koTotal}.`:"Le calendrier attend ses premières rencontres.";
    $("#seasonCalendar").innerHTML=state.matchdays.map(md=>{
      const ms=state.allMatches.filter(m=>m.matchday_id===md.id);
      const p=progressFor(md.id);
      const first=ms[0]?.kickoff_at, last=ms[ms.length-1]?.kickoff_at;
      return `<button class="season-day" data-season-md="${md.id}"><span><b>J${md.number}</b><small>${esc(md.name)}</small></span><span class="season-day-dates">${first?esc(fmtShortDate(first)):"Date à définir"}${last&&fmtShortDate(last)!==fmtShortDate(first)?` → ${esc(fmtShortDate(last))}`:""}</span><span class="chip">${p.done}/${p.total}</span></button>`;
    }).join("")||'<div class="empty">Aucune journée.</div>';
    $$('[data-season-md]',$("#seasonCalendar")).forEach(btn=>btn.onclick=async()=>{await selectMatchday(btn.dataset.seasonMd);setView("matches");});
  }
