"use strict";

// Le Nid des Champions V0.9.12 — refonte desktop UX/UI et cockpit matchs
(() => {
  const DESKTOP_QUERY = "(min-width: 901px)";
  const isDesktopV0912 = () => window.matchMedia?.(DESKTOP_QUERY).matches ?? window.innerWidth >= 901;
  const byId = id => document.getElementById(id);
  const safeArray = value => Array.isArray(value) ? value : [];

  const baseSetView = window.setView;
  const baseRenderHome = window.renderHome;
  const baseRenderMatchPanels = window.renderMatchPanels;
  const baseRenderRanking = window.renderRanking;
  const baseRenderProfile = window.renderProfile;
  const baseRenderUclCenter = window.renderUclCenter;
  const baseRenderAdminMatches = window.renderAdminMatches;

  state.profileTabV0912 = state.profileTabV0912 || "identity";
  state.uclInfoTabV0912 = state.uclInfoTabV0912 || "calendar";
  state._uclLoadRequestedV0912 = false;

  function rankingStartedV0912(){
    return safeArray(state.allMatches).some(m => !m.is_test && m.status === "finished" && m.home_score != null && m.away_score != null);
  }

  function standingForClubV0912(clubId){
    return safeArray(state.uclStandings).find(r => String(r.club_id) === String(clubId)) || null;
  }

  function localClubMatchListV0912(clubId){
    return safeArray(state.allMatches).filter(m => !m.is_test && (String(m.home_club?.id) === String(clubId) || String(m.away_club?.id) === String(clubId)));
  }

  async function ensureUclDataV0912(){
    if(state.uclCenterLoaded || state.uclCenterLoading || state._uclLoadRequestedV0912 || typeof loadUclCenterData !== "function") return;
    state._uclLoadRequestedV0912 = true;
    try{
      await loadUclCenterData();
      if(isDesktopV0912()){
        enhancePredictionCardsV0912();
        renderHomeCarouselsV0912();
      }
    }catch(_){
      // L'interface reste utilisable sans classement C1.
    }finally{
      state._uclLoadRequestedV0912 = false;
    }
  }

  function goToMatchV0912(matchId){
    const match = safeArray(state.allMatches).find(m => String(m.id) === String(matchId));
    if(!match) return toast("Match introuvable.", "error");
    const open = async () => {
      if(match.matchday_id && typeof selectMatchday === "function") await selectMatchday(match.matchday_id);
      baseSetView("matches");
      requestAnimationFrame(() => requestAnimationFrame(() => {
        const card = document.querySelector(`[data-match="${CSS.escape(String(match.id))}"]`);
        if(card){
          card.scrollIntoView({behavior:"smooth",block:"center"});
          card.classList.add("focus-match-v0912");
          setTimeout(()=>card.classList.remove("focus-match-v0912"),1800);
        }
      }));
    };
    open().catch(err=>toast(friendlyError(err),"error"));
  }
  window.goToMatchV0912 = goToMatchV0912;

  function matchPredictionStateV0912(m){
    const p = state.predictions?.get?.(m.id);
    if(p) return {key:"done", label:`✓ Prono ${p.home_score}–${p.away_score}`};
    if(typeof isLocked === "function" && isLocked(m)) return {key:"locked",label:"🔒 Verrouillé"};
    return {key:"todo",label:"⚠ Prono à faire"};
  }

  const HOME_CAROUSEL_DELAY_V0912 = 5000;
  const homeCarouselTimersV0912 = new Map();

  function stopAutoCarouselV0912(root){
    if(!root)return;
    const timer=homeCarouselTimersV0912.get(root.id);
    if(timer)clearInterval(timer);
    homeCarouselTimersV0912.delete(root.id);
  }

  function startAutoCarouselV0912(root){
    if(!root)return;
    stopAutoCarouselV0912(root);
    const slides=[...root.querySelectorAll(".home-carousel-card-v0912")];
    if(!slides.length){
      delete root.dataset.autoIndexV0912;
      return;
    }

    let index=Number(root.dataset.autoIndexV0912||0);
    if(!Number.isFinite(index)||index<0||index>=slides.length)index=0;

    const show=(next)=>{
      index=((next%slides.length)+slides.length)%slides.length;
      slides.forEach((slide,i)=>{
        const active=i===index;
        slide.classList.toggle("active-auto-v0912",active);
        slide.setAttribute("aria-hidden",active?"false":"true");
        if(slide.matches("button,[tabindex]"))slide.tabIndex=active?0:-1;
      });
      root.dataset.autoIndexV0912=String(index);
    };

    show(index);
    if(slides.length>1){
      const timer=setInterval(()=>{
        if(document.hidden)return;
        show(index+1);
      },HOME_CAROUSEL_DELAY_V0912);
      homeCarouselTimersV0912.set(root.id,timer);
    }
  }

  function renderHomeCarouselsV0912(){
    const upcomingRoot = byId("homeUpcomingCarouselV0912");
    if(upcomingRoot){
      const now = Date.now();
      const upcoming = safeArray(state.allMatches)
        .filter(m => !m.is_test && m.status !== "cancelled" && (m.status === "live" || new Date(m.kickoff_at).getTime() > now))
        .sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at)).slice(0,12);
      upcomingRoot.innerHTML = upcoming.length ? upcoming.map(m=>{
        const st=matchPredictionStateV0912(m);
        return `<button type="button" class="home-carousel-card-v0912" data-home-match-v0912="${esc(m.id)}">
          <div class="meta"><span>${esc(fmtDate(m.kickoff_at))} · ${esc(fmtTime(m.kickoff_at))}</span><span>${esc(m.status==="live"?"LIVE":"C1")}</span></div>
          <div class="fixture fixture-visual-v0912">
            <span class="fixture-team-v0912">${crestHTML(m.home_club)}<strong>${esc(compactClubName(m.home_club))}</strong>${clubCountryHTML(m.home_club)}</span>
            <b>VS</b>
            <span class="fixture-team-v0912">${crestHTML(m.away_club)}<strong>${esc(compactClubName(m.away_club))}</strong>${clubCountryHTML(m.away_club)}</span>
          </div>
          <div class="meta venue-meta-v0912"><span>📍 ${esc(m.stadium||m.home_club?.venue||"Stade à confirmer")}</span><span>${esc(m.venue_country||m.home_club?.country||"")}</span></div>
          <div class="state ${st.key}"><span>Pronostic</span><strong>${esc(st.label)}</strong></div>
        </button>`;
      }).join("") : '<div class="empty">Aucun rendez-vous à venir.</div>';
      upcomingRoot.querySelectorAll("[data-home-match-v0912]").forEach(b=>b.onclick=()=>goToMatchV0912(b.dataset.homeMatchV0912));
      startAutoCarouselV0912(upcomingRoot);
    }

    const activityRoot = byId("homeActivityCarouselV0912");
    if(activityRoot){
      const items=[];
      const rankingStarted=rankingStartedV0912();
      const badges=safeArray(state.museumSummary?.badges)
        .filter(b=>b.obtained && (rankingStarted || String(b.category||"").toLowerCase()!=="classement"))
        .map(b=>({kind:"badge",date:b.earned_at||b.updated_at||"",icon:"🏅",title:b.name||"Nouveau badge",text:b.description||"Une nouvelle pièce rejoint le Musée."}));
      const events=safeArray(state.gamificationEvents).map(e=>({kind:e.event_type||"event",date:e.created_at||"",icon:e.event_type==="casserole"?"🍳":e.event_type==="genius"?"✨":"🦉",title:e.title||"Le Nid bouge",text:e.message||""}));
      const records=safeArray(state.gamificationRecords).filter(r=>r.active!==false).map(r=>({kind:"record",date:r.achieved_at||"",icon:"🏆",title:r.record_name||r.record_key||"Nouveau record",text:`${state.profileDirectory?.get?.(String(r.user_id))?.username||"Un joueur"} · ${Number(r.value||0)}`}));
      items.push(...badges,...events,...records);
      items.sort((a,b)=>new Date(b.date||0)-new Date(a.date||0));
      const unique=items.filter((x,i,arr)=>i===arr.findIndex(y=>`${y.kind}|${y.title}|${y.date}`===`${x.kind}|${x.title}|${x.date}`)).slice(0,18);
      activityRoot.innerHTML=unique.length?unique.map(x=>`<article class="home-carousel-card-v0912 home-life-card-v0912"><div class="life-icon">${x.icon}</div><small>${x.date?esc(fmtDate(x.date)):"Le Nid"}</small><h4>${esc(x.title)}</h4><p>${esc(x.text)}</p></article>`).join(""):'<div class="empty">Les casseroles, badges et records apparaîtront ici après les premiers matchs.</div>';
      startAutoCarouselV0912(activityRoot);
    }
  }

  function enhanceHomeNextV0912(){
    if(!isDesktopV0912())return;
    const card=byId("homeNextCardV0912");if(!card)return;
    const now=Date.now();
    const match=safeArray(state.allMatches).filter(m=>!m.is_test&&m.status!=="cancelled"&&(m.status==="live"||new Date(m.kickoff_at).getTime()>now)).sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at))[0];
    if(!match){card.onclick=null;return;}
    const open=()=>goToMatchV0912(match.id);
    const action=byId("homeNextAction");
    if(action) action.onclick=e=>{e.preventDefault();e.stopPropagation();open();};
    card.onclick=e=>{if(e.target.closest("button,a,input,select,textarea"))return;open();};
    card.onkeydown=e=>{if(e.key==="Enter"||e.key===" "){e.preventDefault();open();}};
  }

  function enhancePredictionCardsV0912(){
    document.querySelectorAll("#matchesPanel .match[data-match]").forEach(card=>{
      const m=safeArray(state.matches).find(x=>String(x.id)===String(card.dataset.match))||safeArray(state.allMatches).find(x=>String(x.id)===String(card.dataset.match));
      if(!m)return;
      if(!card.querySelector(".match-venue-v0912")){
        const venue=document.createElement("div");venue.className="match-venue-v0912";venue.textContent=[m.stadium||m.home_club?.venue||"Stade à confirmer",m.venue_country||m.home_club?.country||""].filter(Boolean).join(" · ");
        card.querySelector(".match-top")?.after(venue);
      }
      const teams=card.querySelectorAll(".teams>.team");
      [[teams[0],m.home_club],[teams[1],m.away_club]].forEach(([el,club])=>{
        if(!el||!club)return;
        el.setAttribute("role","button");el.setAttribute("tabindex","0");el.title=`Voir la fiche de ${club.name}`;
        let rank=el.querySelector(".team-rank-v0912");if(!rank){rank=document.createElement("small");rank.className="team-rank-v0912";el.appendChild(rank);}
        const s=standingForClubV0912(club.id);rank.textContent=s?.position?`C1 · #${s.position}`:"C1 · —";
        const open=()=>openClubSheetV0912(club.id);
        el.onclick=e=>{if(e.target.closest("button,input"))return;open();};
        el.onkeydown=e=>{if(e.key==="Enter"||e.key===" "){e.preventDefault();open();}};
      });
    });
    ensureUclDataV0912();
  }

  function clubFixtureRowV0912(m,clubId,upcoming){
    const home=String(m.home_club?.id)===String(clubId);const mine=home?m.home_club:m.away_club;const opp=home?m.away_club:m.home_club;
    const score=m.status==="finished"?`${m.home_score??0}–${m.away_score??0}`:m.status==="live"?`${m.home_score??0}–${m.away_score??0}`:"VS";
    return `<div class="club-fixture-row-v0912"><time>${esc(fmtDate(m.kickoff_at))}<br>${esc(fmtTime(m.kickoff_at))}</time><strong>${esc(compactClubName(mine))} ${score} ${esc(compactClubName(opp))}</strong>${upcoming?`<button class="btn small" type="button" data-club-prono-v0912="${esc(m.id)}">Pronostiquer</button>`:"<span class=\"chip\">${esc(statusLabel(m.status))}</span>"}</div>`;
  }

  function openClubSheetV0912(clubId){
    const club=safeArray(state.clubs).find(c=>String(c.id)===String(clubId));if(!club)return;
    const standing=standingForClubV0912(clubId);const now=Date.now();const matches=localClubMatchListV0912(clubId).sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at));
    const recent=matches.filter(m=>m.status==="finished").slice(-5).reverse();
    const next=matches.filter(m=>m.status!=="cancelled"&&new Date(m.kickoff_at).getTime()>now).slice(0,5);
    const root=modal(`⚽ ${club.name}`,`<div class="club-sheet-v0912"><div class="club-sheet-head-v0912">${crestHTML(club,true)}<div><span class="eyebrow">Fiche club</span><h2>${esc(club.name)}</h2><p>${esc([club.country,club.venue].filter(Boolean).join(" · ")||"Informations club")}</p></div></div><div class="club-sheet-kpis-v0912"><div><b>${standing?.position?`#${standing.position}`:"—"}</b><small>Classement C1</small></div><div><b>${Number(standing?.points||0)}</b><small>Points</small></div><div><b>${standing?`${Number(standing.won||0)}-${Number(standing.draw||0)}-${Number(standing.lost||0)}`:"—"}</b><small>V-N-D</small></div><div>${standing?uclFormHTML(standing.form):"<b>—</b>"}<small>Forme</small></div></div><div><div class="section-title compact"><div><h4>Prochains matchs</h4><p>Pronostique directement depuis la fiche.</p></div></div><div class="club-fixtures-v0912">${next.length?next.map(m=>clubFixtureRowV0912(m,clubId,true)).join(""):'<div class="empty">Aucun match à venir.</div>'}</div></div><div><div class="section-title compact"><div><h4>Derniers matchs</h4><p>Les cinq derniers résultats disponibles.</p></div></div><div class="club-fixtures-v0912">${recent.length?recent.map(m=>clubFixtureRowV0912(m,clubId,false)).join(""):'<div class="empty">Aucun résultat pour le moment.</div>'}</div></div></div>`);
    root.querySelectorAll("[data-club-prono-v0912]").forEach(b=>b.onclick=()=>{root.innerHTML="";goToMatchV0912(b.dataset.clubPronoV0912);});
  }
  window.openClubSheetV0912=openClubSheetV0912;

  function standingsLegendV0912(){
    return `<div class="ucl-zones-v0912"><span class="direct"><b>1–8</b> Huitièmes directs</span><span class="playoff"><b>9–24</b> Barrages</span><span class="out"><b>25–36</b> Éliminés</span></div>`;
  }
  function uclInfoHTMLV0912(){
    const tab=state.uclInfoTabV0912||"calendar";
    return `<div class="leaderboard-toolbar ucl-info-tabs-v0912"><button type="button" data-ucl-info-v0912="calendar" class="${tab==="calendar"?"active":""}">Calendrier & résultats</button><button type="button" data-ucl-info-v0912="clubs" class="${tab==="clubs"?"active":""}">Clubs</button></div><div class="ucl-info-body-v0912">${tab==="clubs"?uclClubsHTML():uclCalendarHTML()}</div>`;
  }
  function renderUclCenterV0912(){
    const root=byId("uclCenterRoot");if(!root)return;
    if(state.uclCenterLoading){root.innerHTML='<article class="card card-pad"><div class="empty">Chargement du Centre Ligue des champions…</div></article>';return;}
    let tab=state.uclTab||"standings";if(!["standings","knockout","info"].includes(tab))tab="standings";state.uclTab=tab;
    const body=tab==="standings"?`${standingsLegendV0912()}${uclStandingsHTML()}`:tab==="knockout"?uclPhaseBracketHTML():uclInfoHTMLV0912();
    root.innerHTML=`<div class="ucl-hero card card-pad"><div><span class="eyebrow gold">Ligue des champions</span><h2>La compétition, au bon endroit</h2><p>Classement, tableau final et informations utiles. Les statistiques individuelles viendront après les premiers résultats.</p></div><button id="uclRefreshBtn" class="btn ${isAdminProfile()?"gold":"secondary"} small">↻ ${isAdminProfile()?"Synchroniser":"Actualiser"}</button></div><div class="ucl-tabs"><button data-ucl-tab="standings" class="${tab==="standings"?"active":""}">Classement</button><button data-ucl-tab="knockout" class="${tab==="knockout"?"active":""}">Phases finales</button><button data-ucl-tab="info" class="${tab==="info"?"active":""}">Infos</button></div><div id="uclTabBody">${body}</div>`;
    bindUclCenterEvents(root);
    root.querySelectorAll("[data-ucl-info-v0912]").forEach(b=>b.onclick=()=>{state.uclInfoTabV0912=b.dataset.uclInfoV0912;renderUclCenterV0912();});
    root.querySelectorAll("[data-ucl-club]").forEach(b=>b.onclick=()=>b.dataset.uclClub&&openClubSheetV0912(b.dataset.uclClub));
  }

  function setupProfileDomV0912(){
    const identity=byId("profileIdentityV0912"),prefs=byId("profilePreferencesV0912");if(!identity||!prefs||identity.dataset.arrangedV0912)return;
    identity.dataset.arrangedV0912="1";
    const move=(selector)=>{const el=document.querySelector(selector);if(el)identity.appendChild(el);};
    move(".avatar-profile-title");move("#avatarDrawerV0912");move(".profile-team-title");move("#profileTeamCard");move(".champions-profile-title");move(".profile-champion-grid");move(".champion-profile-note");move(".champion-board-details");
    document.querySelectorAll("[data-profile-tab-v0912]").forEach(b=>b.onclick=()=>setProfileTabV0912(b.dataset.profileTabV0912));
    const toggle=byId("toggleAvatarEditorV0912");if(toggle)toggle.onclick=()=>{const d=byId("avatarDrawerV0912");const willOpen=d.classList.contains("hidden");d.classList.toggle("hidden",!willOpen);toggle.textContent=willOpen?"Refermer la bibliothèque":"🎭 Changer mon avatar";if(willOpen)renderAvatarEditor?.();};
  }
  function setProfileTabV0912(tab){
    state.profileTabV0912=tab||"identity";
    document.querySelectorAll("[data-profile-tab-v0912]").forEach(b=>b.classList.toggle("active",b.dataset.profileTabV0912===state.profileTabV0912));
    document.querySelectorAll("[data-profile-panel-v0912]").forEach(p=>p.classList.toggle("active",p.dataset.profilePanelV0912===state.profileTabV0912));
    if(state.profileTabV0912==="season")renderProfileSeasonV0912();
  }
  function renderProfileSeasonV0912(){
    const root=byId("profileSeasonSummaryV0912");if(!root)return;
    const total=state.matchdays?.length||0;const finished=safeArray(state.matchdays).filter(md=>{const ms=safeArray(state.allMatches).filter(m=>m.matchday_id===md.id&&!m.is_test);return ms.length&&ms.every(m=>["finished","cancelled"].includes(m.status));}).length;
    const next=safeArray(state.allMatches).filter(m=>!m.is_test&&m.status!=="cancelled"&&new Date(m.kickoff_at).getTime()>Date.now()).sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at))[0];
    root.innerHTML=`<div class="profile-season-grid-v0912"><article class="card"><span class="eyebrow">Saison active</span><h3>${esc(state.season?.name||"—")}</h3><p class="muted">${esc(state.season?.status||"préparation")}</p></article><article class="card"><span class="eyebrow">Progression</span><h3>${finished}/${total} journées</h3><p class="muted">${safeArray(state.allMatches).filter(m=>!m.is_test).length} rencontres au calendrier</p></article><article class="card"><span class="eyebrow">Prochain match</span><h3>${next?`${esc(next.home_club?.short_name||"?")} – ${esc(next.away_club?.short_name||"?")}`:"—"}</h3><p class="muted">${next?esc(fmtDate(next.kickoff_at)):"Aucun rendez-vous"}</p></article></div><article class="card card-pad"><div class="section-title compact"><div><h4>Calendrier de la saison</h4><p>Accès direct aux journées de pronostics.</p></div></div><div class="profile-season-calendar-v0912">${safeArray(state.matchdays).map(md=>{const p=progressFor(md.id);return `<button type="button" data-profile-md-v0912="${esc(md.id)}"><b>J${Number(md.number||0)}</b><small>${esc(md.name||"")} · ${p.done}/${p.total} pronos</small></button>`;}).join("")||'<div class="empty">Aucune journée.</div>'}</div></article>`;
    root.querySelectorAll("[data-profile-md-v0912]").forEach(b=>b.onclick=async()=>{await selectMatchday(b.dataset.profileMdV0912);baseSetView("matches");});
  }

  function renderAdminMatchOpsV0912(){
    if(!isDesktopV0912()||!isAdminProfile())return;
    const root=byId("adminMatchOpsV0912");if(!root)return;
    const md=selectedMatchday();const rows=safeArray(state.matches);
    root.innerHTML=`<div class="admin-match-ops-head-v0912"><div><span class="eyebrow">Cockpit de journée</span><h4>${esc(md?.name||"Journée")}</h4><p class="admin-bulk-note-v0912">Cotes au clavier, résultats LIVE/final et accès immédiat aux paramètres du match.</p></div><div class="actions"><button id="saveAllOddsV0912" class="btn gold small" type="button">💾 Enregistrer toutes les cotes</button></div></div><div class="admin-match-ops-list-v0912">${rows.map(m=>adminMatchOpRowV0912(m)).join("")||'<div class="empty">Aucun match dans cette journée.</div>'}</div><div id="adminMatchOpsMsgV0912" class="form-msg" style="padding:0 14px 12px"></div>`;
    root.querySelectorAll("[data-admin-op-row-v0912]").forEach(bindAdminOpRowV0912);
    const saveAll=byId("saveAllOddsV0912");if(saveAll)saveAll.onclick=saveAllOddsV0912;
  }
  function adminMatchOpRowV0912(m){
    const bookmaker=m.odds_bookmaker||m.odds_provider||"Manuel";
    return `<div class="admin-op-row-v0912" data-admin-op-row-v0912="${esc(m.id)}"><div class="admin-op-fixture-v0912"><strong>${esc(compactClubName(m.home_club))} – ${esc(compactClubName(m.away_club))}</strong><small>${esc(fmtDate(m.kickoff_at))} · ${esc(fmtTime(m.kickoff_at))}</small><small>📍 ${esc([m.stadium||m.home_club?.venue,m.venue_country||m.home_club?.country].filter(Boolean).join(" · ")||"Lieu à confirmer")}</small></div><div class="admin-op-odds-v0912"><label>1<input data-op-odd="home" inputmode="decimal" value="${m.odds_home??""}"></label><label>N<input data-op-odd="draw" inputmode="decimal" value="${m.odds_draw??""}"></label><label>2<input data-op-odd="away" inputmode="decimal" value="${m.odds_away??""}"></label><label>Source<input data-op-bookmaker value="${esc(bookmaker)}"></label></div><div class="admin-op-score-v0912"><label>Dom.<input data-op-score="home" type="number" min="0" max="99" value="${m.home_score??0}"></label><label>Ext.<input data-op-score="away" type="number" min="0" max="99" value="${m.away_score??0}"></label><label>État<select data-op-status><option value="scheduled" ${m.status==="scheduled"?"selected":""}>À venir</option><option value="live" ${m.status==="live"?"selected":""}>LIVE</option><option value="finished" ${m.status==="finished"?"selected":""}>Terminé</option><option value="postponed" ${m.status==="postponed"?"selected":""}>Reporté</option><option value="cancelled" ${m.status==="cancelled"?"selected":""}>Annulé</option></select></label></div><div class="admin-op-actions-v0912"><button type="button" class="btn secondary small" data-op-save-odds>💶 Cotes</button><button type="button" class="btn small" data-op-save-result>${m.status==="finished"?"Corriger":"Score / état"}</button><button type="button" class="btn secondary small" data-op-settings>⚙ Paramètres</button></div></div>`;
  }
  function bindAdminOpRowV0912(row){
    row.querySelectorAll("input,select").forEach(input=>input.addEventListener("input",()=>row.classList.add("admin-op-dirty-v0912")));
    row.querySelector("[data-op-save-odds]")?.addEventListener("click",()=>saveOneOddsV0912(row));
    row.querySelector("[data-op-save-result]")?.addEventListener("click",()=>saveOneResultV0912(row));
    row.querySelector("[data-op-settings]")?.addEventListener("click",()=>openMatchScheduleEditorV0910?.(row.dataset.adminOpRowV0912));
  }
  function oddsPayloadFromRowV0912(row){
    const val=side=>{const raw=row.querySelector(`[data-op-odd="${side}"]`)?.value.trim();return raw===""?null:Number(String(raw).replace(",","."));};
    return {match_id:row.dataset.adminOpRowV0912,odds_home:val("home"),odds_draw:val("draw"),odds_away:val("away"),bookmaker:row.querySelector("[data-op-bookmaker]")?.value.trim()||"Manuel"};
  }
  async function saveOneOddsV0912(row){
    try{
      const p=oddsPayloadFromRowV0912(row);if([p.odds_home,p.odds_draw,p.odds_away].some(v=>v==null||!Number.isFinite(v)||v<=1))throw new Error("Les trois cotes doivent être supérieures à 1,00.");
      if(demoMode){const m=state.allMatches.find(x=>String(x.id)===String(p.match_id));Object.assign(m,{odds_home:p.odds_home,odds_draw:p.odds_draw,odds_away:p.odds_away,odds_provider:"manual",odds_bookmaker:p.bookmaker});}
      else{const {error}=await sb.rpc("admin_update_match_odds_v0910",{p_match_id:p.match_id,p_odds_home:p.odds_home,p_odds_draw:p.odds_draw,p_odds_away:p.odds_away,p_bookmaker:p.bookmaker,p_clear:false});if(error)throw error;await loadData();}
      row.classList.remove("admin-op-dirty-v0912");renderAdminMatchOpsV0912();toast("💶 Cotes enregistrées.");
    }catch(err){setMsg("#adminMatchOpsMsgV0912",friendlyError(err),"error");}
  }
  async function saveAllOddsV0912(){
    const root=byId("adminMatchOpsV0912");const rows=[...root.querySelectorAll("[data-admin-op-row-v0912]")];const payload=rows.map(oddsPayloadFromRowV0912).filter(p=>[p.odds_home,p.odds_draw,p.odds_away].every(v=>Number.isFinite(v)&&v>1));
    if(!payload.length)return setMsg("#adminMatchOpsMsgV0912","Aucune ligne complète à enregistrer.","error");
    try{
      if(demoMode){for(const p of payload){const m=state.allMatches.find(x=>String(x.id)===String(p.match_id));if(m)Object.assign(m,{odds_home:p.odds_home,odds_draw:p.odds_draw,odds_away:p.odds_away,odds_provider:"manual",odds_bookmaker:p.bookmaker});}}
      else{const {data,error}=await sb.rpc("admin_save_matchday_odds_v0912",{p_matchday_id:state.selectedMatchdayId,p_rows:payload});if(error)throw error;await loadData();}
      renderAll();setMsg("#adminMatchOpsMsgV0912",`✓ ${payload.length} ligne(s) de cotes enregistrée(s).`,"ok");
    }catch(err){setMsg("#adminMatchOpsMsgV0912",friendlyError(err),"error");}
  }
  async function saveOneResultV0912(row){
    const id=row.dataset.adminOpRowV0912;const m=state.allMatches.find(x=>String(x.id)===String(id));const status=row.querySelector("[data-op-status]")?.value||"scheduled";const home=Math.max(0,Number(row.querySelector('[data-op-score="home"]')?.value||0));const away=Math.max(0,Number(row.querySelector('[data-op-score="away"]')?.value||0));
    if(status==="finished"){
      const correction=m?.status==="finished"&&(Number(m.home_score)!==home||Number(m.away_score)!==away);
      const message=correction
        ?`Corriger un résultat déjà terminé ?\n\n${m.home_club?.short_name||"Dom."} ${m.home_score}–${m.away_score} ${m.away_club?.short_name||"Ext."}\n→ ${home}–${away}\n\nLe classement officiel sera recalculé.`
        :`Valider le résultat final ${home}–${away} ?\nLe classement officiel sera recalculé.`;
      if(!confirm(message))return;
    }
    try{
      if(demoMode){if(m){m.status=status;m.home_score=["live","finished"].includes(status)?home:null;m.away_score=["live","finished"].includes(status)?away:null;}}
      else{const {error}=await sb.rpc("admin_set_match_state",{p_match_id:id,p_status:status,p_home_score:["live","finished"].includes(status)?home:null,p_away_score:["live","finished"].includes(status)?away:null,p_kickoff_at:null});if(error)throw error;await loadData();}
      renderAll();toast(status==="finished"?"✅ Résultat final enregistré.":status==="live"?`🔴 LIVE ${home}–${away}`:`État du match : ${statusLabel(status)}.`);
    }catch(err){setMsg("#adminMatchOpsMsgV0912",friendlyError(err),"error");}
  }

  function applyConnectionBadgeV0912(){
    if(!isDesktopV0912())return;
    const status=byId("backendStatus");if(status&&!demoMode)status.innerHTML='<i class="status-dot"></i><span>Le Nid est connecté</span>';
    const v=byId("appVersionChipV0912");if(v)v.textContent=`V${CFG.APP_VERSION||"0.9.12"}`;
  }



  function openMobileSidebarV0912(){
    if(isDesktopV0912())return;
    document.querySelector(".sidebar")?.classList.add("mobile-open-v0912");
    byId("mobileSidebarBackdropV0912")?.classList.add("open");
    byId("mobileSidebarBackdropV0912")?.setAttribute("aria-hidden","false");
    byId("mobileSidebarTriggerV0912")?.setAttribute("aria-expanded","true");
    document.body.classList.add("mobile-sidebar-open-v0912");
  }

  function closeMobileSidebarV0912(){
    document.querySelector(".sidebar")?.classList.remove("mobile-open-v0912");
    byId("mobileSidebarBackdropV0912")?.classList.remove("open");
    byId("mobileSidebarBackdropV0912")?.setAttribute("aria-hidden","true");
    byId("mobileSidebarTriggerV0912")?.setAttribute("aria-expanded","false");
    document.body.classList.remove("mobile-sidebar-open-v0912");
  }

  function setupMobileSidebarV0912(){
    const trigger=byId("mobileSidebarTriggerV0912");
    if(!trigger||trigger.dataset.boundV0912)return;
    trigger.dataset.boundV0912="1";
    trigger.onclick=openMobileSidebarV0912;
    byId("mobileSidebarCloseV0912")&&(byId("mobileSidebarCloseV0912").onclick=closeMobileSidebarV0912);
    byId("mobileSidebarBackdropV0912")&&(byId("mobileSidebarBackdropV0912").onclick=closeMobileSidebarV0912);
    document.querySelectorAll(".sidebar [data-view]").forEach(el=>el.addEventListener("click",()=>setTimeout(closeMobileSidebarV0912,0)));
    document.addEventListener("keydown",e=>{if(e.key==="Escape")closeMobileSidebarV0912();});
    window.addEventListener("resize",()=>{if(isDesktopV0912())closeMobileSidebarV0912();});
  }

  function syncAdminMobileSectionV0912(){
    const select=byId("adminMobileSectionV0912");
    if(!select)return;
    const rows=[...document.querySelectorAll(".admin-nav [data-admin-section]")]
      .filter(btn=>!btn.classList.contains("hidden"))
      .map(btn=>({value:btn.dataset.adminSection,label:btn.querySelector("b")?.textContent?.trim()||btn.dataset.adminSection}));
    const signature=rows.map(x=>`${x.value}:${x.label}`).join("|");
    if(select.dataset.signatureV0912!==signature){
      select.innerHTML=rows.map(x=>`<option value="${esc(x.value)}">${esc(x.label)}</option>`).join("");
      select.dataset.signatureV0912=signature;
      select.onchange=()=>{if(typeof setAdminSection==="function")setAdminSection(select.value,{scroll:false});};
    }
    if(typeof currentAdminSection==="function")select.value=currentAdminSection();
  }

  function setupStaticV0912(){
    setupProfileDomV0912();
    setProfileTabV0912(state.profileTabV0912);
    setupMobileSidebarV0912();
    syncAdminMobileSectionV0912();
  }

  window.setView = function(name){
    if(isDesktopV0912() && name==="knockout"){state.uclTab="knockout";name="ucl";}
    if(isDesktopV0912() && name==="season"){state.profileTabV0912="season";name="profile";}
    const result=baseSetView(name);
    if(isDesktopV0912()){
      if(name==="ranking" && byId("pageTitle"))byId("pageTitle").textContent="Classement du Nid";
      if(name==="profile")setProfileTabV0912(state.profileTabV0912||"identity");
      if(name==="ucl" && (!["standings","knockout","info"].includes(state.uclTab)))state.uclTab="standings";
      setTimeout(()=>{enhancePredictionCardsV0912();renderAdminMatchOpsV0912();},0);
    }else{
      if(name==="profile"){setupProfileDomV0912();setProfileTabV0912(state.profileTabV0912||"identity");}
      closeMobileSidebarV0912();
      if(name==="admin")setTimeout(syncAdminMobileSectionV0912,0);
    }
    return result;
  };

  window.renderHome = function(){baseRenderHome?.();renderHomeCarouselsV0912();if(isDesktopV0912())enhanceHomeNextV0912();applyConnectionBadgeV0912();};
  window.renderMatchPanels = function(){baseRenderMatchPanels?.();enhancePredictionCardsV0912();};
  window.renderRanking = function(){baseRenderRanking?.();if(isDesktopV0912()&&byId("pageTitle")&&!byId("view-ranking")?.classList.contains("hidden"))byId("pageTitle").textContent="Classement du Nid";};
  window.renderProfile = function(){baseRenderProfile?.();setupProfileDomV0912();setProfileTabV0912(state.profileTabV0912||"identity");renderProfileSeasonV0912();};
  window.renderUclCenter = renderUclCenterV0912;
  window.renderAdminMatches = function(){baseRenderAdminMatches?.();renderAdminMatchOpsV0912();};

  window.renderRelease0912 = function(){
    setupStaticV0912();applyConnectionBadgeV0912();renderHomeCarouselsV0912();enhancePredictionCardsV0912();renderProfileSeasonV0912();renderAdminMatchOpsV0912();
  };

  setupStaticV0912();
})();
