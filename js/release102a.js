"use strict";

// Le Nid des Champions V1.0.2a
// Correctifs : classement -> Pouls, couleurs Team contextualisées,
// détails explicites Casseroles / Génie.
(() => {
  const safe = value => Array.isArray(value) ? value : [];
  const byId = id => document.getElementById(id);

  function stripTeamTheme102a(card){
    if(!card) return;
    card.classList.remove("team-carousel-v101","story-team-theme-v102a");
    [...card.classList].filter(c=>c.startsWith("bg-")).forEach(c=>card.classList.remove(c));
    ["--team-primary","--team-secondary","--team-accent","--team-text","--team-border"].forEach(k=>card.style.removeProperty(k));
  }

  function applyTeamThemeToStory102a(card,userId){
    stripTeamTheme102a(card);
    card.classList.add("carousel-transition-v102a");
    if(!userId) return;
    const team = typeof teamForUser === "function" ? teamForUser(userId) : null;
    if(!team) return;
    card.classList.add("story-team-theme-v102a",`bg-${team.background_style||"diagonal"}`);
    if(typeof teamVisualVars === "function"){
      const vars=teamVisualVars(team);
      if(vars) card.setAttribute("style",`${card.getAttribute("style")||""};${vars}`);
    }
  }

  function fixHomeCarouselThemes102a(){
    const matches=byId("homeUpcomingCarouselV0912");
    if(matches){
      matches.querySelectorAll(".home-carousel-card-v0912").forEach(card=>{
        stripTeamTheme102a(card);
        card.classList.add("carousel-transition-v102a");
      });
    }
    const movement=byId("homeActivityCarouselV0912");
    if(movement){
      movement.querySelectorAll(".home-carousel-card-v0912").forEach(card=>applyTeamThemeToStory102a(card,card.dataset.storyPlayerV102a||card.dataset.storyPlayerV101||""));
    }
  }
  window.fixHomeCarouselThemes102a=fixHomeCarouselThemes102a;

  function watchHomeCarousels102a(){
    ["homeUpcomingCarouselV0912","homeActivityCarouselV0912"].forEach(id=>{
      const root=byId(id);if(!root||root._teamWatchV102a)return;
      let timer=null;
      const obs=new MutationObserver(()=>{clearTimeout(timer);timer=setTimeout(fixHomeCarouselThemes102a,25);});
      obs.observe(root,{subtree:true,childList:true,attributes:true,attributeFilter:["class","style"]});
      root._teamWatchV102a=obs;
    });
  }

  async function loadEventDetails102a(force=false){
    if(!state?.season||demoMode||!configured||!sb)return;
    const now=Date.now();
    if(!force && now-Number(state.nidEventDetailsLoadedAtV102a||0)<30000 && state.nidEventDetailsV102a instanceof Map)return;
    if(state.nidEventDetailsLoadingV102a)return state.nidEventDetailsPromiseV102a;
    state.nidEventDetailsLoadingV102a=true;
    state.nidEventDetailsPromiseV102a=(async()=>{
      try{
        const {data,error}=await sb.rpc("get_gamification_event_details_v102a",{p_season_id:state.season.id});
        if(error) throw error;
        state.nidEventDetailsV102a=new Map(safe(data).map(x=>[String(x.event_id),x]));
        state.nidEventDetailsLoadedAtV102a=Date.now();
      }catch(err){console.warn("V1.0.2a détails gamification",err);}
      finally{state.nidEventDetailsLoadingV102a=false;}
    })();
    return state.nidEventDetailsPromiseV102a;
  }
  window.loadEventDetails102a=loadEventDetails102a;

  function detailForEvent102a(e){
    if(!e)return null;
    return state.nidEventDetailsV102a?.get?.(String(e.id||e.event_id))||null;
  }

  function score102a(a,b){return Number.isFinite(Number(a))&&Number.isFinite(Number(b))?`${Number(a)}–${Number(b)}`:"—";}

  function reasonText102a(e,d){
    const labels=safe(d?.labels||e?.labels).map(String).filter(Boolean);
    const meta=d?.metadata||e?.metadata||{};
    const bits=[];
    if(labels.length) bits.push(labels.join(" · "));
    if(e?.event_type==="genius"){
      const count=Number(meta.pick_count||0),total=Number(meta.total||0),pct=Number(meta.pick_pct||0),odds=Number(meta.odds||0);
      if(count>0&&total>0) bits.push(`${count}/${total} joueur${count>1?"s":""} sur cette issue${pct?` (${pct.toFixed(1)}%)`:""}`);
      if(odds>0) bits.push(`cote ${odds.toFixed(2)}`);
    }
    if(e?.event_type==="casserole"){
      const margin=Number(meta.margin_error||0),streak=Number(meta.zero_streak||0);
      if(margin>0) bits.push(`écart d'erreur : ${margin}`);
      if(meta.unique_wrong===true) bits.push("seul à se tromper");
      if(streak>=3) bits.push(`série de ${streak} zéros`);
    }
    return [...new Set(bits)].join(" · ");
  }

  function eventDetailHTML102a(e,{compact=false}={}){
    const d=detailForEvent102a(e);if(!d||!d.match_id)return "";
    const match=`${d.home_name||"Domicile"} – ${d.away_name||"Extérieur"}`;
    const pred=score102a(d.prediction_home,d.prediction_away),res=score102a(d.result_home,d.result_away);
    const reason=reasonText102a(e,d);
    return `<div class="gami-detail-v102a ${compact?"compact":""}"><strong>⚽ ${esc(match)}</strong><span><b>Prono</b> ${esc(pred)} <i>→</i> <b>Résultat</b> ${esc(res)}</span>${reason?`<small>${esc(reason)}</small>`:""}</div>`;
  }

  function eventForUser102a(userId,type){
    return safe(state.gamificationEvents)
      .filter(e=>String(e.user_id)===String(userId)&&e.event_type===type&&e.is_test!==true)
      .sort((a,b)=>Number(b.points||0)-Number(a.points||0)||new Date(b.created_at)-new Date(a.created_at))[0]||null;
  }

  function storyPlayer102a(userId){
    const p=state.profileDirectory?.get?.(String(userId));
    return p?`<div class="nid-story-player-v100">${avatarHTML({...p,user_id:userId})}<strong>${esc(p.username||"Joueur")}</strong></div>`:"";
  }

  function movementStories102a(){
    const rows=safe(state.nidMovementRankingV100?.length?state.nidMovementRankingV100:state.rankingRows).filter(r=>r.user_id);
    const stats=safe(state.nidMovementStatsV101),stories=[];
    const leader=rows.slice().sort((a,b)=>Number(a.rank||999)-Number(b.rank||999))[0];
    if(leader)stories.push({kind:"leader",icon:"👑",user:leader.user_id,eyebrow:"Classement",title:"Le patron du Nid",value:`#1 · ${Number(leader.points||0)} pts`,text:`${Number(leader.exact_scores||0)} exact(s) · ${Number(leader.precision_pct||0).toFixed(1)}% de précision`});
    const zero=stats.slice().sort((a,b)=>Number(b.zero_streak||0)-Number(a.zero_streak||0))[0];
    if(Number(zero?.zero_streak||0)>0)stories.push({kind:"zero",icon:"🥶",user:zero.user_id,eyebrow:"Série de zéro",title:"Le trou d’air",value:`${Number(zero.zero_streak)} zéro${Number(zero.zero_streak)>1?"s":""} de suite`,text:"Une série qui commence à laisser des traces."});
    const cass=stats.slice().sort((a,b)=>Number(b.casserole_points||0)-Number(a.casserole_points||0))[0];
    if(Number(cass?.casserole_events||0)>0){const event=eventForUser102a(cass.user_id,"casserole");stories.push({kind:"casserole",icon:"🍳",user:cass.user_id,event,eyebrow:"Casseroles",title:"La poêle chauffe",value:`${Number(cass.casserole_points||0)} pts · ${Number(cass.casserole_events||0)} casserole(s)`,text:event?.message||"Les casseroles sont maintenant détaillées match par match."});}
    const gen=stats.slice().sort((a,b)=>Number(b.genius_points||0)-Number(a.genius_points||0))[0];
    if(Number(gen?.genius_events||0)>0){const event=eventForUser102a(gen.user_id,"genius");stories.push({kind:"genius",icon:"✨",user:gen.user_id,event,eyebrow:"Génie",title:"Les neurones fument",value:`${Number(gen.genius_points||0)} pts · ${Number(gen.genius_events||0)} coup(s)`,text:event?.message||"Le détail du coup de génie est affiché ci-dessous."});}
    safe(state.gamificationEvents).filter(e=>["casserole","genius"].includes(e.event_type)&&e.is_test!==true).slice(0,8).forEach(e=>stories.push({kind:e.event_type,icon:e.event_type==="casserole"?"🍳":"✨",user:e.user_id,event:e,eyebrow:e.event_type==="casserole"?"Casserole récente":"Génie récent",title:e.title||(e.event_type==="casserole"?"Casserole":"Coup de génie"),value:`${e.event_type==="genius"?"+":""}${Number(e.points||0)} pt${Math.abs(Number(e.points||0))>1?"s":""}`,text:e.message||""}));
    safe(state.gamificationRecords).filter(r=>r.active!==false&&String(r.scope||"nid")==="nid").slice(0,5).forEach(r=>stories.push({kind:"record",icon:"🏆",user:r.user_id,eyebrow:"Record du Nid",title:r.record_name||r.record_key||"Record",value:String(Number(r.value||0)),text:r.is_equal?"Record égalé":"Une nouvelle marque à battre"}));
    const seen=new Set();
    return stories.filter(s=>{const k=s.event?.id?`event:${s.event.id}`:`${s.kind}:${s.title}:${s.user||""}`;if(seen.has(k))return false;seen.add(k);return true;}).slice(0,14);
  }

  function startCarousel102a(root){
    const cards=[...root.querySelectorAll(".home-carousel-card-v0912")];if(!cards.length)return;
    let i=0;cards.forEach((c,n)=>c.classList.toggle("active-auto-v0912",n===0));
    if(root._v102aTimer)clearInterval(root._v102aTimer);
    if(cards.length>1)root._v102aTimer=setInterval(()=>{if(document.hidden)return;i=(i+1)%cards.length;cards.forEach((c,n)=>c.classList.toggle("active-auto-v0912",n===i));},5400);
  }

  function renderMovement102a(){
    const root=byId("homeActivityCarouselV0912");if(!root)return;
    const stories=movementStories102a();
    root.innerHTML=stories.length?stories.map(s=>`<article class="home-carousel-card-v0912 home-life-card-v0912 nid-story-v100 nid-story-v102a story-${esc(s.kind)} carousel-transition-v102a" ${s.user?`data-story-player-v102a="${esc(s.user)}" tabindex="0" role="button"`:""}><div class="nid-story-top-v100"><span class="nid-story-icon-v100">${s.icon}</span><span class="eyebrow">${esc(s.eyebrow)}</span></div>${s.user?storyPlayer102a(s.user):""}<h4>${esc(s.title)}</h4><strong class="nid-story-value-v100">${esc(s.value||"")}</strong>${s.event?eventDetailHTML102a(s.event,{compact:true}):""}${s.text?`<p>${esc(s.text)}</p>`:""}</article>`).join(""):'<div class="empty">Le Nid attend ses premières histoires.</div>';
    root.querySelectorAll("[data-story-player-v102a]").forEach(c=>{const open=()=>openPlayerQuickProfile?.(c.dataset.storyPlayerV102a);c.onclick=open;c.onkeydown=e=>{if(e.key==="Enter"||e.key===" "){e.preventDefault();open();}};});
    root.querySelectorAll("[data-story-player-v102a]").forEach(c=>applyTeamThemeToStory102a(c,c.dataset.storyPlayerV102a));
    startCarousel102a(root);
  }
  window.renderMovement102a=renderMovement102a;

  // Musée : conserver le texte du Hibou, mais ajouter la preuve concrète du match.
  window.eventCardHTML=function(e){
    const sev=esc(e.severity||"");
    return `<article class="museum-event ${esc(e.event_type)} ${sev}"><div class="museum-event-icon">${typeof gamificationEventIcon==="function"?gamificationEventIcon(e):(e.event_type==="casserole"?"🍳":"✨")}</div><div><small>${esc(fmtDate(e.created_at))}${e.is_manual?' · Attribuée par le Hibou masqué':''}${e.is_test?' · 🧪 TEST':''}</small><h4>${esc(e.title||(e.event_type==='casserole'?'Casserole':'Coup de génie'))}</h4>${eventDetailHTML102a(e)}<p>${esc(e.message||'')}</p>${e.media_url?`<img class="museum-event-media" src="${esc(e.media_url)}" alt="Illustration de la distinction" loading="lazy">`:''}${safe(e.labels).length?`<div class="event-labels">${safe(e.labels).map(x=>`<span>${esc(x)}</span>`).join('')}</div>`:''}</div><strong>${e.points>0?`+${e.points}`:e.points} ${e.event_type==='casserole'?'🍳':'✨'}</strong></article>`;
  };

  function injectPlayerEvents102a(userId){
    const profile=document.querySelector("#modalRoot .public-player-profile-v101,#modalRoot .public-player-profile");if(!profile)return;
    profile.querySelector(".player-gami-details-v102a")?.remove();
    const events=safe(state.gamificationEvents).filter(e=>String(e.user_id)===String(userId)&&["casserole","genius"].includes(e.event_type)&&e.is_test!==true).slice(0,5);
    if(!events.length)return;
    const block=document.createElement("section");block.className="player-gami-details-v102a";
    block.innerHTML=`<div class="section-title compact"><div><span class="eyebrow gold">Musée</span><h4>Pourquoi ces points Casserole / Génie ?</h4></div></div><div class="player-gami-event-list-v102a">${events.map(e=>`<article class="player-gami-event-v102a ${esc(e.event_type)}"><div><b>${e.event_type==="casserole"?"🍳 Casserole":"✨ Coup de génie"}</b><strong>${e.event_type==="genius"?"+":""}${Number(e.points||0)}</strong></div>${eventDetailHTML102a(e)}${e.message?`<p>${esc(e.message)}</p>`:""}</article>`).join("")}</div>`;
    const actions=profile.querySelector(":scope > .actions");if(actions)profile.insertBefore(block,actions);else profile.appendChild(block);
  }

  const baseOpenPlayer102a=window.openPlayerQuickProfile;
  if(typeof baseOpenPlayer102a==="function")window.openPlayerQuickProfile=async function(userId){await loadEventDetails102a();const out=await baseOpenPlayer102a.apply(this,arguments);injectPlayerEvents102a(userId);return out;};

  const baseRenderMuseum102a=window.renderMuseum;
  if(typeof baseRenderMuseum102a==="function")window.renderMuseum=function(){const out=baseRenderMuseum102a.apply(this,arguments);loadEventDetails102a().then(()=>{if(!byId("view-museum")?.classList.contains("hidden")&&!state._museumRefreshV102a){state._museumRefreshV102a=true;try{baseRenderMuseum102a();}finally{state._museumRefreshV102a=false;}}});return out;};

  function repairRankingLayout102a(){
    const view=byId("view-ranking");if(!view)return;
    const wrap=view.querySelector(".ranking-v100-wrap,.premium-ranking-wrap");
    const pulseTitle=[...view.children].find(el=>el.classList?.contains("section-title")&&/pouls du nid/i.test(el.textContent||""));
    const pulseGrid=view.querySelector(":scope > .collective-grid");
    if(wrap&&pulseTitle&&wrap.nextElementSibling!==pulseTitle)wrap.after(pulseTitle);
    if(pulseTitle&&pulseGrid&&pulseTitle.nextElementSibling!==pulseGrid)pulseTitle.after(pulseGrid);
  }

  const baseRenderRanking102a=window.renderRanking;
  if(typeof baseRenderRanking102a==="function")window.renderRanking=function(){const out=baseRenderRanking102a.apply(this,arguments);repairRankingLayout102a();return out;};

  const baseRenderHome102a=window.renderHome;
  if(typeof baseRenderHome102a==="function")window.renderHome=function(){const out=baseRenderHome102a.apply(this,arguments);watchHomeCarousels102a();fixHomeCarouselThemes102a();loadEventDetails102a().then(()=>{if(!byId("view-home")?.classList.contains("hidden")){renderMovement102a();fixHomeCarouselThemes102a();}});setTimeout(fixHomeCarouselThemes102a,250);setTimeout(fixHomeCarouselThemes102a,1200);return out;};

  window.renderRelease102a=function(){repairRankingLayout102a();watchHomeCarousels102a();fixHomeCarouselThemes102a();loadEventDetails102a().then(()=>{renderMovement102a();fixHomeCarouselThemes102a();});};
})();
