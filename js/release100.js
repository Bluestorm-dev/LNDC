"use strict";

// Le Nid des Champions V1.0.0 — UX LIVE, classement mobile, cockpit matchs et mouvement du Nid.
(() => {
  const baseRenderHomeV100 = window.renderHome;
  const baseRenderMatchPanelsV100 = window.renderMatchPanels;

  const safe = v => Array.isArray(v) ? v : [];
  const byId = id => document.getElementById(id);
  const statusWeight = s => s === "live" ? 0 : ["scheduled","postponed"].includes(s) ? 1 : s === "finished" ? 2 : 3;
  const isFinished = m => ["finished","cancelled"].includes(m?.status);
  const teamName = c => compactClubName?.(c) || c?.short_name || c?.name || "?";

  function liveMatchesV100(){
    return safe(state.allMatches).filter(m=>!m.is_test && m.status === "live")
      .sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at));
  }

  const carouselTimersV100=new Map();
  function startSimpleCarouselV100(root){
    if(!root)return;
    const old=carouselTimersV100.get(root.id);if(old)clearInterval(old);
    const cards=[...root.querySelectorAll(".home-carousel-card-v0912")];
    if(!cards.length)return;
    let index=Math.min(Number(root.dataset.autoIndexV100||0)||0,cards.length-1);
    const show=i=>{
      index=((i%cards.length)+cards.length)%cards.length;
      cards.forEach((card,n)=>{const active=n===index;card.classList.toggle("active-auto-v0912",active);card.setAttribute("aria-hidden",active?"false":"true");if(card.matches("button,[tabindex]"))card.tabIndex=active?0:-1;});
      root.dataset.autoIndexV100=String(index);
    };
    show(index);
    if(cards.length>1)carouselTimersV100.set(root.id,setInterval(()=>{if(!document.hidden)show(index+1);},5200));
  }

  function renderHomeLiveCarouselV100(){
    const root=byId("homeUpcomingCarouselV0912"); if(!root)return;
    const live=liveMatchesV100();
    const section=root.closest(".home-carousel-section-v0912");
    const eyebrow=section?.querySelector(".eyebrow");
    const title=section?.querySelector("h3");
    if(!live.length){
      if(eyebrow)eyebrow.textContent="Prochains rendez-vous";
      if(title)title.textContent="Mes prochains matchs";
      return;
    }
    if(eyebrow)eyebrow.textContent=`LIVE · ${live.length} match${live.length>1?"s":""}`;
    if(title)title.textContent="Les matchs en direct";
    root.innerHTML=live.map(m=>`<button type="button" class="home-carousel-card-v0912 home-live-match-v100" data-live-pronos-v100="${esc(m.id)}">
      <div class="meta"><span class="live-pill-v100">● LIVE</span><span>${esc(fmtTime(m.kickoff_at))}</span></div>
      <div class="live-fixture-v100">
        <span>${crestHTML(m.home_club)}<strong>${esc(teamName(m.home_club))}</strong></span>
        <b>${Number(m.home_score??0)}–${Number(m.away_score??0)}</b>
        <span>${crestHTML(m.away_club)}<strong>${esc(teamName(m.away_club))}</strong></span>
      </div>
      <div class="live-open-v100">Voir les pronos du Nid <span>→</span></div>
    </button>`).join("");
    root.querySelectorAll("[data-live-pronos-v100]").forEach(btn=>btn.onclick=()=>{
      if(typeof showMatchPredictions === "function") showMatchPredictions(btn.dataset.livePronosV100);
    });
    startSimpleCarouselV100(root);
  }

  function profileForStoryV100(userId){
    return state.profileDirectory?.get?.(String(userId)) || safe(state.rankingRows).find(r=>String(r.user_id)===String(userId)) || null;
  }

  function storyPlayerV100(p){
    if(!p)return "";
    return `<div class="nid-story-player-v100">${avatarHTML({...p,user_id:p.user_id||p.id})}<strong>${esc(p.username||"Joueur")}</strong></div>`;
  }

  function movementStoriesV100(){
    const rows=safe(state.nidMovementRankingV100?.length?state.nidMovementRankingV100:state.rankingRows)
      .filter(r=>r?.user_id).slice().sort((a,b)=>Number(a.rank||999)-Number(b.rank||999));
    const stories=[];
    const leader=rows[0];
    if(leader)stories.push({kind:"leader",icon:"👑",eyebrow:"Au sommet",title:"Le patron du Nid",p:leader,value:`#1 · ${Number(leader.points||0).toFixed(0)} pts`,text:`${Number(leader.exact_scores||0)} exact${Number(leader.exact_scores||0)>1?"s":""} · ${Number(leader.precision_pct||0).toFixed(1)}% de précision`});
    const played=rows.filter(r=>Number(r.played||0)>0);
    const exact=played.slice().sort((a,b)=>Number(b.exact_scores||0)-Number(a.exact_scores||0)||Number(b.points||0)-Number(a.points||0))[0];
    if(exact)stories.push({kind:"exact",icon:"🎯",eyebrow:"Dans le mille",title:"Le sniper du moment",p:exact,value:`${Number(exact.exact_scores||0)} exact${Number(exact.exact_scores||0)>1?"s":""}`,text:`${Number(exact.points||0).toFixed(0)} pts au classement`});
    const precision=played.filter(r=>Number(r.played||0)>=2).slice().sort((a,b)=>Number(b.precision_pct||0)-Number(a.precision_pct||0)||Number(b.points||0)-Number(a.points||0))[0];
    if(precision && String(precision.user_id)!==String(exact?.user_id))stories.push({kind:"precision",icon:"🔥",eyebrow:"Hibou en feu",title:"Ça vise juste",p:precision,value:`${Number(precision.precision_pct||0).toFixed(1)}%`,text:`${Number(precision.played||0)} pronostics déjà scorés`});

    const latestC=safe(state.gamificationEvents).find(e=>e.event_type==="casserole");
    if(latestC){const p=profileForStoryV100(latestC.user_id);stories.push({kind:"casserole",icon:"🍳",eyebrow:"Casserole du Nid",title:latestC.title||"La poêle est sortie",p,value:`${Number(latestC.points||0)} 🍳`,text:latestC.message||"Le Hibou a noté ça dans son carnet."});}
    const latestG=safe(state.gamificationEvents).find(e=>e.event_type==="genius");
    if(latestG){const p=profileForStoryV100(latestG.user_id);stories.push({kind:"genius",icon:"💡",eyebrow:"Coup de génie",title:latestG.title||"Le cerveau a chauffé",p,value:`+${Number(latestG.points||0)} ✨`,text:latestG.message||"Une intuition qui mérite sa place dans le Nid."});}
    safe(state.gamificationRecords).filter(r=>r.active!==false && String(r.scope||"nid")==="nid").slice(0,4).forEach(r=>{
      const p=profileForStoryV100(r.user_id);stories.push({kind:"record",icon:"🏆",eyebrow:"Record du Nid",title:r.record_name||r.record_key||"Nouveau record",p,value:String(Number(r.value||0)),text:`${p?.username||"Un joueur"} laisse une trace dans le marbre.`});
    });
    const seen=new Set();return stories.filter(s=>{const k=`${s.kind}:${s.title}:${s.p?.user_id||s.p?.id||""}`;if(seen.has(k))return false;seen.add(k);return true;}).slice(0,12);
  }

  function renderNidMovementV100(){
    const root=byId("homeActivityCarouselV0912");if(!root)return;
    const section=root.closest(".home-life-section-v0912");
    const title=section?.querySelector("h3");if(title)title.textContent="Ce qui fait parler le Nid";
    const stories=movementStoriesV100();
    root.innerHTML=stories.length?stories.map((s,i)=>`<article class="home-carousel-card-v0912 home-life-card-v0912 nid-story-v100 story-${esc(s.kind)}" ${s.p?`data-story-player-v100="${esc(s.p.user_id||s.p.id)}" tabindex="0" role="button"`:""}>
      <div class="nid-story-top-v100"><span class="nid-story-icon-v100">${s.icon}</span><span class="eyebrow">${esc(s.eyebrow)}</span></div>
      ${s.p?storyPlayerV100(s.p):""}
      <h4>${esc(s.title)}</h4><strong class="nid-story-value-v100">${esc(s.value||"")}</strong><p>${esc(s.text||"")}</p>
      <small>${i===0?"Le Nid maintenant":"La vie du Nid"}</small>
    </article>`).join(""):'<div class="empty">Le Nid attend encore ses premières histoires : leaders, exacts, casseroles, génies et records apparaîtront ici.</div>';
    root.querySelectorAll("[data-story-player-v100]").forEach(card=>{
      const open=()=>openPlayerQuickProfile?.(card.dataset.storyPlayerV100);
      card.onclick=open;card.onkeydown=e=>{if(e.key==="Enter"||e.key===" "){e.preventDefault();open();}};
    });
    startSimpleCarouselV100(root);
  }

  async function refreshMovementRankingV100(){
    if(!state.user||!state.season||demoMode)return;
    const now=Date.now();if(state.nidMovementLoadingV100||now-Number(state.nidMovementLoadedAtV100||0)<15000)return;
    state.nidMovementLoadingV100=true;
    try{
      const {data,error}=await sb.rpc("get_leaderboard_v040",{p_season_id:state.season.id,p_scope:"general",p_matchday_id:null,p_evening_date:null,p_include_live:true});
      if(!error){state.nidMovementRankingV100=data||[];state.nidMovementLoadedAtV100=Date.now();if(!byId("view-home")?.classList.contains("hidden"))renderNidMovementV100();}
    }catch(_){}finally{state.nidMovementLoadingV100=false;}
  }

  window.renderHome=function(){
    baseRenderHomeV100?.();
    renderHomeLiveCarouselV100();renderNidMovementV100();refreshMovementRankingV100();
  };

  // Pronostics : LIVE / à venir d'abord, matchs terminés en bas de la journée.
  window.renderMatchPanels=function(){
    const original=state.matches;
    state.matches=safe(original).slice().sort((a,b)=>statusWeight(a.status)-statusWeight(b.status)||new Date(a.kickoff_at)-new Date(b.kickoff_at));
    try{baseRenderMatchPanelsV100?.();}finally{state.matches=original;}
    const list=byId("matchesPanel")?.querySelector(".match-list");
    if(list){
      const groups=[...list.querySelectorAll(":scope > .calendar-day")];
      groups.sort((a,b)=>{
        const af=[...a.querySelectorAll(".match")].every(x=>x.classList.contains("finished")||x.classList.contains("cancelled"));
        const bf=[...b.querySelectorAll(".match")].every(x=>x.classList.contains("finished")||x.classList.contains("cancelled"));
        return Number(af)-Number(bf);
      }).forEach(g=>list.appendChild(g));
      const firstFinished=[...list.querySelectorAll(".match.finished,.match.cancelled")][0];
      if(firstFinished && !list.querySelector(".finished-separator-v100")){
        const sep=document.createElement("div");sep.className="finished-separator-v100";sep.innerHTML="<span>Matchs terminés</span>";
        firstFinished.closest(".calendar-day")?.before(sep);
      }
    }
  };

  function rankingRowsV100(){
    let rows=safe(state.rankingRows).slice();
    if(state.rankingScope==="precision")rows.sort((a,b)=>Number(b.precision_pct||0)-Number(a.precision_pct||0)||Number(b.exact_scores||0)-Number(a.exact_scores||0)||Number(b.points||0)-Number(a.points||0));
    if(state.rankingScope==="exacts")rows.sort((a,b)=>Number(b.exact_scores||0)-Number(a.exact_scores||0)||Number(b.points||0)-Number(a.points||0)||Number(b.precision_pct||0)-Number(a.precision_pct||0));
    return rows.map((r,i)=>({...r,display_rank:i+1}));
  }
  function rankVariationV100(v){v=Number(v||0);return v>0?`<span class="rank-var up">▲ ${v}</span>`:v<0?`<span class="rank-var down">▼ ${Math.abs(v)}</span>`:`<span class="rank-var same">—</span>`;}
  function rankingPrimaryV100(r){
    if(state.rankingScope==="precision")return [`${Number(r.precision_pct||0).toFixed(1)}%`,"précision"];
    if(state.rankingScope==="exacts")return [String(Number(r.exact_scores||0)),"exacts"];
    return [String(Number(r.points||0).toFixed(0)),"points"];
  }
  function rankingSubtitleV100(){
    if(state.rankingScope==="general")return "Le plus de points gagne. En cas d’égalité : exacts, moyenne, bons écarts puis pronostics joués.";
    if(state.rankingScope==="matchday")return `Seulement ${selectedMatchday()?.name||"la journée sélectionnée"}.`;
    if(state.rankingScope==="evening")return `La photo de la soirée du ${state.selectedEveningDate||"jour sélectionné"}.`;
    if(state.rankingScope==="precision")return "Qui transforme le plus souvent ses pronostics en bons résultats.";
    if(state.rankingScope==="exacts")return "Qui trouve le plus de scores parfaitement exacts.";
    return "Classement de laboratoire, séparé de la compétition officielle.";
  }

  window.renderRanking=function(){
    const body=byId("rankingBody");if(!body)return;
    document.querySelectorAll("[data-ranking-scope]").forEach(btn=>btn.classList.toggle("active",btn.dataset.rankingScope===state.rankingScope));
    const rows=rankingRowsV100();
    const scopeLabel={general:"Général",matchday:`J${selectedMatchday()?.number||"?"}`,evening:"Soirée",precision:"Précision",exacts:"Scores exacts",test:"🧪 TEST"}[state.rankingScope]||"Général";
    if(byId("rankingSubtitle"))byId("rankingSubtitle").textContent=rankingSubtitleV100();
    if(byId("rankingContext"))byId("rankingContext").innerHTML=`<span class="context-pill">${esc(scopeLabel)}</span><span class="context-pill">${rows.length} joueur${rows.length>1?"s":""}</span>${liveMatchesV100().length&&state.rankingScope==="general"?'<span class="context-pill live-context-v100">● provisoire LIVE</span>':""}`;
    if(byId("collectiveScopeChip"))byId("collectiveScopeChip").textContent=scopeLabel;
    body.innerHTML=rows.length?rows.map(r=>{
      const rank=Number(r.display_rank),isMe=String(r.user_id)===String(state.user?.id),isRival=String(r.user_id)===String(state.currentRival?.rival_user_id||"");
      const [primary,primaryLabel]=rankingPrimaryV100(r);const team=teamForUser(r.user_id);
      return `<article class="ranking-row-v100 ${isMe?"me":""} ${isRival?"rival":""} ${rank<=3?`podium-${rank}`:""}">
        <div class="ranking-pos-v100"><span class="rank-medal">${rank}</span>${state.rankingScope==="general"?rankVariationV100(r.variation):""}</div>
        <div class="ranking-player-v100">${avatarHTML(r)}<div><div class="ranking-name-line-v100"><button data-player-profile="${esc(r.user_id)}" type="button">${esc(r.username)}</button>${reactionButtonHTML(r.user_id,true)}${isRival?'<span class="rival-mini-v100">⚔ Rival</span>':""}</div>${team?`<small>${esc(team.team_name||team.name||"")}</small>`:""}</div></div>
        <div class="ranking-main-v100"><strong>${esc(primary)}</strong><small>${esc(primaryLabel)}</small></div>
        <div class="ranking-details-v100"><span><b>${Number(r.points||0).toFixed(0)}</b> pts</span><span><b>${Number(r.exact_scores||0)}</b> exacts</span><span><b>${Number(r.precision_pct||0).toFixed(1)}%</b> précis.</span><span><b>${Number(r.played||0)}</b> joués</span></div>
      </article>`;
    }).join(""):'<div class="empty">Aucun classement.</div>';
    body.querySelectorAll("[data-player-profile]").forEach(b=>b.onclick=e=>{e.stopPropagation();openPlayerQuickProfile?.(b.dataset.playerProfile);});
    if(typeof bindPlayerReactionButtons==="function")bindPlayerReactionButtons(body);
    const mine=rows.find(r=>String(r.user_id)===String(state.user?.id)),sticky=byId("myRankingSticky");
    if(sticky){sticky.classList.toggle("hidden",!mine);if(mine){const [primary,label]=rankingPrimaryV100(mine);sticky.innerHTML=`<span class="sticky-rank">#${mine.display_rank}</span>${state.rankingScope==="general"?rankVariationV100(mine.variation):""}<span class="sticky-name">${avatarHTML(mine)}<b>${esc(mine.username)}</b></span><span class="sticky-main-v100"><b>${esc(primary)}</b><small>${esc(label)}</small></span>`;}}
    if(typeof updateKpis==="function")updateKpis();
  };

  function adminMatchRowV100(m){
    const closed=isFinished(m);const live=m.status==="live";
    return `<div class="admin-match-row-v100 ${live?"live":""} ${closed?"closed":""}" data-admin-match="${esc(m.id)}">
      <div class="admin-match-fixture-v100"><div>${crestHTML(m.home_club)}<strong>${esc(teamName(m.home_club))}</strong></div><span>${esc(fmtTime(m.kickoff_at))}</span><div>${crestHTML(m.away_club)}<strong>${esc(teamName(m.away_club))}</strong></div></div>
      <span class="chip ${statusClass(m.status)}">${esc(statusLabel(m.status))}</span>
      <div class="admin-quick-score-v100"><input data-admin-home type="number" min="0" max="99" inputmode="numeric" value="${m.home_score??0}" aria-label="Score domicile"><b>–</b><input data-admin-away type="number" min="0" max="99" inputmode="numeric" value="${m.away_score??0}" aria-label="Score extérieur"></div>
      <div class="admin-match-actions-v100">
        ${!closed?`<button class="btn small ${live?"live-update":""}" data-admin-action="live">${live?"Mettre à jour":"LIVE"}</button><button class="btn gold small" data-admin-action="finish">Terminer</button>`:`<button class="btn secondary small" data-admin-action="reopen">Réouvrir</button>`}
        <button class="btn secondary small" data-edit-match-v0910="${esc(m.id)}">⚙ Match</button>
      </div>
    </div>`;
  }

  function matchdaySortV100(a,b){
    const ma=safe(state.adminAllMatches).filter(m=>String(m.matchday_id)===String(a.id)&&!m.is_test),mb=safe(state.adminAllMatches).filter(m=>String(m.matchday_id)===String(b.id)&&!m.is_test);
    const score=arr=>arr.some(m=>m.status==="live")?0:arr.some(m=>!isFinished(m))?1:2;
    return score(ma)-score(mb)||Number(a.number||999)-Number(b.number||999);
  }

  window.renderAdminMatches=function(){
    const root=byId("adminMatchOpsV0912");if(!root)return;
    byId("adminMatches")?.classList.add("hidden");byId("adminMatchdayTabs")?.classList.add("hidden");
    const days=safe(state.adminAllMatchdays?.length?state.adminAllMatchdays:state.matchdays).filter(md=>!md.is_test).slice().sort(matchdaySortV100);
    const all=safe(state.adminAllMatches?.length?state.adminAllMatches:state.allMatches).filter(m=>!m.is_test);
    const liveCount=all.filter(m=>m.status==="live").length,remaining=all.filter(m=>!["finished","cancelled"].includes(m.status)).length;
    root.innerHTML=`<div class="admin-live-summary-v100"><span><b>${liveCount}</b><small>LIVE</small></span><span><b>${remaining}</b><small>à gérer</small></span><span><b>${all.filter(m=>m.status==="finished").length}</b><small>terminés</small></span></div><div class="admin-matchday-groups-v100">${days.map(md=>{
      const matches=all.filter(m=>String(m.matchday_id)===String(md.id)).sort((a,b)=>statusWeight(a.status)-statusWeight(b.status)||new Date(a.kickoff_at)-new Date(b.kickoff_at));if(!matches.length)return"";
      const live=matches.filter(m=>m.status==="live").length;const closed=matches.every(isFinished);const pending=matches.filter(m=>!isFinished(m)).length;
      return `<details class="admin-matchday-group-v100 ${live?"has-live":""} ${closed?"closed":""}" ${!closed||live?"open":""}><summary><span><b>${esc(md.name||`Journée ${md.number}`)}</b><small>${live?`🔴 ${live} LIVE · `:""}${pending} à gérer · ${matches.length} matchs</small></span><span>${closed?"Terminée":"⌄"}</span></summary><div>${matches.map(adminMatchRowV100).join("")}</div></details>`;
    }).join("")||'<div class="empty">Aucun match.</div>'}</div><div id="adminMatchOpsMsgV100" class="form-msg"></div>`;
    root.querySelectorAll("[data-admin-match]").forEach(row=>{
      const h=row.querySelector("[data-admin-home]"),a=row.querySelector("[data-admin-away]");if(h&&a&&typeof bindAlternatingScorePair==="function")bindAlternatingScorePair(h,a,()=>{});
      row.querySelectorAll("[data-admin-action]").forEach(btn=>btn.onclick=()=>adminMatchAction(row,btn.dataset.adminAction));
      row.querySelector("[data-edit-match-v0910]")?.addEventListener("click",e=>openMatchScheduleEditorV0910?.(e.currentTarget.dataset.editMatchV0910));
    });
  };

  window.renderRelease100=function(){
    renderHomeLiveCarouselV100();renderNidMovementV100();
    if(!byId("view-ranking")?.classList.contains("hidden"))window.renderRanking();
    if(["admin","super_admin"].includes(state.profile?.role) && !document.querySelector('[data-admin-panel="matches"]')?.classList.contains("hidden"))window.renderAdminMatches();
  };
})();
