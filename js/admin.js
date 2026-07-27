"use strict";

// Le Nid des Champions V0.6.2 — administration modulaire
  const ADMIN_SECTIONS = new Set(["dashboard","matches","competition","players","teams","communication","application"]);

  function currentAdminSection(){
    const saved=localStorage.getItem("nidc_admin_section")||"dashboard";
    return ADMIN_SECTIONS.has(saved)?saved:"dashboard";
  }

  function setAdminSection(name,{scroll=true}={}){
    const section=ADMIN_SECTIONS.has(name)?name:"dashboard";
    localStorage.setItem("nidc_admin_section",section);
    $$('[data-admin-panel]').forEach(p=>p.classList.toggle("active",p.dataset.adminPanel===section));
    $$('[data-admin-section]').forEach(b=>b.classList.toggle("active",b.dataset.adminSection===section));
    if(section==="players")renderAdminPlayers();
    if(section==="application")renderAdminAppState();
    if(section==="dashboard")renderAdminDashboard();
    if(scroll){const view=$("#view-admin");if(view)window.scrollTo({top:Math.max(0,view.offsetTop-72),behavior:"smooth"});}
  }

  function bindAdminNavigation(){
    $$('[data-admin-section]').forEach(b=>b.onclick=()=>setAdminSection(b.dataset.adminSection));
    $$('[data-admin-go]').forEach(b=>b.onclick=()=>setAdminSection(b.dataset.adminGo));
    const search=$("#adminPlayerSearch");if(search)search.oninput=renderAdminPlayers;
    const reload=$("#adminReloadDataBtn");if(reload)reload.onclick=reloadAdminData;
    const refresh=$("#adminRefreshPwaBtn");if(refresh)refresh.onclick=refreshAdminPwa;
    setAdminSection(currentAdminSection(),{scroll:false});
  }

  function renderAdminDashboard(){
    const matches=(state.allMatches||[]).length;
    const players=[...state.profileDirectory.values()].filter(p=>p.status==="active").length;
    const teams=(state.teamDirectory||[]).filter(t=>t.status==="active").length;
    const tickets=state.profile?.role==="super_admin"?(state.adminSupportTickets||[]).filter(t=>!["closed","rejected","resolved"].includes(t.status)).length:"—";
    if($("#adminDashMatches"))$("#adminDashMatches").textContent=String(matches);
    if($("#adminDashPlayers"))$("#adminDashPlayers").textContent=String(players);
    if($("#adminDashTeams"))$("#adminDashTeams").textContent=String(teams);
    if($("#adminDashTickets"))$("#adminDashTickets").textContent=String(tickets);
    if($("#adminDashSeason"))$("#adminDashSeason").textContent=state.season?.name||"Saison";
  }

  function adminRoleLabel(role){return ({super_admin:"Super Admin",admin:"Admin",captain:"Capitaine",player:"Joueur"}[role]||role||"Joueur");}

  function renderAdminPlayers(){
    const root=$("#adminPlayersPanel");if(!root)return;
    const q=String($("#adminPlayerSearch")?.value||"").trim().toLocaleLowerCase("fr");
    const players=[...state.profileDirectory.values()].filter(p=>{const hay=[p.username,p.first_name,p.role,p.status].filter(Boolean).join(" ").toLocaleLowerCase("fr");return !q||hay.includes(q);}).sort((a,b)=>String(a.username||"").localeCompare(String(b.username||""),"fr"));
    const summary=$("#adminPlayersSummary");if(summary)summary.textContent=`${players.length} joueur${players.length>1?"s":""} affiché${players.length>1?"s":""}`;
    root.innerHTML=players.length?players.map(p=>`<div class="admin-player-row" data-admin-player="${p.id||p.user_id}">${avatarHTML(p)}<div class="admin-player-copy"><strong>${esc(p.username||"Joueur")}</strong><div class="admin-player-meta"><span class="chip admin-role-${esc(p.role||"player")}">${esc(adminRoleLabel(p.role))}</span><span>${esc(p.status||"active")}</span>${p.first_name?`<span>· ${esc(p.first_name)}</span>`:""}</div></div><div class="admin-player-actions"><button class="btn secondary small" type="button" data-admin-player-open>Voir le profil</button></div></div>`).join(""):'<div class="empty">Aucun joueur correspondant.</div>';
    $$('[data-admin-player]',root).forEach(row=>{const open=$('[data-admin-player-open]',row);if(open)open.onclick=()=>openPlayerQuickProfile(row.dataset.adminPlayer);});
  }

  function renderAdminAppState(){
    if($("#adminAppVersion"))$("#adminAppVersion").textContent=CFG.APP_VERSION||"0.6.2";
    if($("#adminAppSeason"))$("#adminAppSeason").textContent=state.season?.name||"—";
    if($("#adminAppBackend"))$("#adminAppBackend").textContent=demoMode?"Démo locale":"Supabase";
    if($("#adminAppRole"))$("#adminAppRole").textContent=adminRoleLabel(state.profile?.role);
  }

  async function reloadAdminData(){
    setMsg("#adminMaintenanceMsg","Rechargement des données…");
    try{await loadData();renderAll();setAdminSection("application",{scroll:false});setMsg("#adminMaintenanceMsg","Données rechargées.","ok");toast("↻ Données du Nid rechargées.");}catch(err){setMsg("#adminMaintenanceMsg",friendlyError(err),"error");}
  }

  async function refreshAdminPwa(){
    if(!confirm("Nettoyer le cache PWA du Nid puis recharger la page ? Aucune donnée Supabase ne sera supprimée."))return;
    setMsg("#adminMaintenanceMsg","Nettoyage du cache…");
    try{if("caches" in window){const keys=await caches.keys();await Promise.all(keys.filter(k=>k.startsWith("nid-champions-")).map(k=>caches.delete(k)));}if("serviceWorker" in navigator){const reg=await navigator.serviceWorker.getRegistration();if(reg)await reg.update();}setMsg("#adminMaintenanceMsg","Cache nettoyé. Rechargement…","ok");setTimeout(()=>location.reload(),450);}catch(err){setMsg("#adminMaintenanceMsg",friendlyError(err),"error");}
  }

  function renderAdmin() {
    renderAdminBuilder(); renderKnockoutBuilder(); renderAdminMatches(); renderClubPreview(); renderAdminKnockout(); renderPhaseMultipliers(); renderAdminTeams(); renderAdminPlayers(); loadAvatarModeration(); renderAdminOwl(); renderAdminSupport(); renderAdminNotifications();
    const section=$("#registrationAdminSection");
    if(section){const allowed=state.profile?.role==="super_admin";section.classList.toggle("hidden",!allowed);if(allowed)loadRegistrationRequests();}
    renderAdminDashboard();renderAdminAppState();bindAdminNavigation();
  }

  function renderAdminBuilder() {
    const mdSel=$("#adminMatchdaySelect"), homeSel=$("#adminHomeClub"), awaySel=$("#adminAwayClub");
    if(!mdSel)return;
    const mdOptions=state.matchdays.map(md=>`<option value="${md.id}">${esc(md.name)}</option>`).join("");
    mdSel.innerHTML=mdOptions;
    if(state.selectedMatchdayId)mdSel.value=state.selectedMatchdayId;
    const clubOptions=state.clubs.map(c=>`<option value="${c.id}">${esc(c.short_name)} — ${esc(c.name)}</option>`).join("");
    homeSel.innerHTML=clubOptions; awaySel.innerHTML=clubOptions;
    if(state.clubs[1])awaySel.value=state.clubs[1].id;
    const next=new Date(Date.now()+7*24*3600_000); next.setMinutes(0,0,0);
    $("#adminKickoff").value=toLocalDateTimeInput(next);
  }

  function phaseDefaultTiePrefix(code) {
    return ({KNOCKOUT_PLAYOFF:"PO",ROUND_OF_16:"R16",QUARTER_FINAL:"QF",SEMI_FINAL:"SF",FINAL:"F"}[code] || "KO");
  }

  function localInputValue(date) {
    const d = new Date(date);
    const pad = n => String(n).padStart(2,"0");
    return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
  }

  function toggleKnockoutBuilderLeg2() {
    const single = Boolean($("#adminKoSingle")?.checked);
    const field = $("#adminKoLeg2Field");
    if (field) field.classList.toggle("hidden", single);
    const phaseSel = $("#adminKoPhase");
    if (single && phaseSel && [...phaseSel.options].some(o=>o.value==="FINAL")) phaseSel.value="FINAL";
  }

  function renderKnockoutBuilder() {
    const phaseSel=$("#adminKoPhase"),teamA=$("#adminKoTeamA"),teamB=$("#adminKoTeamB");
    if(!phaseSel||!teamA||!teamB)return;

    const phases=state.phases.filter(p=>KO_PHASES.includes(p.code)).sort((a,b)=>Number(a.sort_order||0)-Number(b.sort_order||0));
    const oldPhase=phaseSel.value;
    phaseSel.innerHTML=phases.map(p=>`<option value="${esc(p.code)}">${esc(p.name)}</option>`).join("");
    if(phases.some(p=>p.code===oldPhase))phaseSel.value=oldPhase;

    const c1Ids=new Set(state.clubMemberships.filter(m=>m.competition_code==="CL").map(m=>m.club_id));
    const clubs=state.clubs.filter(c=>c.is_active!==false&&(!c1Ids.size||c1Ids.has(c.id))).slice().sort((a,b)=>String(a.name||a.short_name).localeCompare(String(b.name||b.short_name),"fr"));
    const options=clubs.map(c=>`<option value="${c.id}">${esc(c.short_name||c.tla||c.name)} — ${esc(c.name)}</option>`).join("");
    const oldA=teamA.value,oldB=teamB.value;
    teamA.innerHTML=options;teamB.innerHTML=options;
    if(clubs.some(c=>c.id===oldA))teamA.value=oldA;
    if(clubs.some(c=>c.id===oldB))teamB.value=oldB;else if(clubs[1])teamB.value=clubs[1].id;

    const now = new Date();
    if(!$("#adminKoLeg1").value){const d1=new Date(now.getTime()+7*24*3600_000);d1.setMinutes(0,0,0);$("#adminKoLeg1").value=localInputValue(d1);}
    if(!$("#adminKoLeg2").value){const d2=new Date(now.getTime()+14*24*3600_000);d2.setMinutes(0,0,0);$("#adminKoLeg2").value=localInputValue(d2);}

    const syncDefaults=()=>{
      const phase=phaseSel.value||"KNOCKOUT_PLAYOFF";
      const samePhase=state.knockoutTies.filter(t=>phaseById(t.phase_id)?.code===phase);
      const n=samePhase.length+1;
      if(!$("#adminKoCode").dataset.touched)$("#adminKoCode").value=`${phaseDefaultTiePrefix(phase)}${phase==="ROUND_OF_16"?"-":""}${n}`;
      if(!$("#adminKoLabel").dataset.touched){
        const ph=phases.find(p=>p.code===phase);
        $("#adminKoLabel").value=phase==="FINAL"?"Finale":`${ph?.name||"Confrontation"} ${n}`;
      }
      const shouldSingle=phase==="FINAL";
      $("#adminKoSingle").checked=shouldSingle;
      toggleKnockoutBuilderLeg2();
    };
    phaseSel.onchange=()=>{delete $("#adminKoCode").dataset.touched;delete $("#adminKoLabel").dataset.touched;syncDefaults();};
    $("#adminKoCode").oninput=()=>$("#adminKoCode").dataset.touched="1";
    $("#adminKoLabel").oninput=()=>$("#adminKoLabel").dataset.touched="1";
    if(!$("#adminKoCode").value&&!$("#adminKoLabel").value)syncDefaults();
    else toggleKnockoutBuilderLeg2();
  }

  async function createKnockoutTie() {
    const phaseCode=$("#adminKoPhase")?.value;
    const code=$("#adminKoCode")?.value.trim().toUpperCase();
    const label=$("#adminKoLabel")?.value.trim();
    const teamA=$("#adminKoTeamA")?.value,teamB=$("#adminKoTeamB")?.value;
    const leg1=$("#adminKoLeg1")?.value,leg2=$("#adminKoLeg2")?.value;
    const single=Boolean($("#adminKoSingle")?.checked);
    try{
      if(!phaseCode||!code||!label||!teamA||!teamB||!leg1)throw new Error("Complète la phase, le code, le libellé, les deux clubs et la date.");
      if(teamA===teamB)throw new Error("Une confrontation doit opposer deux clubs différents.");
      if(!single&&!leg2)throw new Error("La date du match retour est obligatoire.");
      const leg1Iso=new Date(leg1).toISOString(),leg2Iso=single?null:new Date(leg2).toISOString();
      if(!single&&new Date(leg2Iso)<=new Date(leg1Iso))throw new Error("Le match retour doit être programmé après l'aller.");
      if(phaseCode==="FINAL"&&!single)throw new Error("La finale doit être créée en match unique.");
      if(phaseCode!=="FINAL"&&single)throw new Error("Seule la finale est un match unique dans cette V0.4.0.");

      setMsg("#knockoutAdminStatus",`Création de ${label}…`);
      if(demoMode){
        const ph=state.phases.find(p=>p.code===phaseCode);
        const id=`demo-tie-${Date.now()}`;
        const tie={id,season_id:state.season.id,phase_id:ph?.id,code,label,sort_order:state.knockoutTies.filter(t=>t.phase_id===ph?.id).length+1,team_a_club_id:teamA,team_b_club_id:teamB,qualified_club_id:null,status:"scheduled",is_single_match:single,is_test:false,leg1_kickoff_at:leg1Iso,leg2_kickoff_at:leg2Iso,qualifier_bonus_early:3,qualifier_bonus_late:1};
        state.knockoutTies.push(tie);localStorage.setItem("nidc_demo_knockout_ties",JSON.stringify(state.knockoutTies));
      }else{
        const {error}=await sb.rpc("admin_upsert_knockout_tie_v040",{p_season_id:state.season.id,p_phase_code:phaseCode,p_code:code,p_label:label,p_team_a:teamA,p_team_b:teamB,p_leg1_kickoff_at:leg1Iso,p_leg2_kickoff_at:leg2Iso,p_is_single_match:single});
        if(error)throw error;
        await loadData();
      }
      state.selectedKnockoutPhase=phaseCode;
      delete $("#adminKoCode").dataset.touched;delete $("#adminKoLabel").dataset.touched;
      $("#adminKoCode").value="";$("#adminKoLabel").value="";
      renderAll();setMsg("#knockoutAdminStatus",`✓ ${label} enregistrée. Les matchs ${single?"de finale":"aller-retour"} sont prêts.`,"ok");toast("⚔️ Confrontation enregistrée.");
    }catch(err){setMsg("#knockoutAdminStatus",friendlyError(err),"error");}
  }

  function renderClubPreview() {
    const box=$("#clubPreview"); if(!box)return;
    const filter=$("#clubPreviewFilter")?.value||state.clubPreviewFilter||"CL";
    state.clubPreviewFilter=filter;
    const membershipIds=new Set(state.clubMemberships.filter(m=>filter==="ALL"||m.competition_code===filter).map(m=>m.club_id));
    let clubs=filter==="ALL"?state.clubs.filter(c=>c.external_provider==="football-data"):state.clubs.filter(c=>membershipIds.has(c.id));
    if(!state.clubMemberships.length&&filter==="CL")clubs=state.clubs.filter(c=>c.external_provider==="football-data").slice(0,36);
    const logos=clubs.filter(c=>publicLogoUrl(c)).length;
    const label={ALL:"Tous les clubs",CL:"Champions League",FL1:"Ligue 1",PL:"Premier League",PD:"Liga",SA:"Serie A",BL1:"Bundesliga"}[filter]||filter;
    $("#clubLibrarySummary").textContent=`${label} · ${clubs.length} clubs · ${logos} logos`;
    box.innerHTML=clubs.length?clubs.map(c=>`<div class="club-mini">${crestHTML(c,true)}<span><b>${esc(c.short_name)}</b><small>${esc(c.name)} · ${esc(clubCountry(c).name||"")}</small></span></div>`).join(""):'<div class="empty">Aucun club dans cette bibliothèque. Lance la synchronisation correspondante.</div>';
  }

  function renderAdminMatches() {
    const box=$("#adminMatches"); if(!box)return;
    box.innerHTML=state.matches.map(m=>`<div class="admin-match-v2 ${m.status==="live"?'live-admin':''}" data-admin-match="${m.id}">
      <div class="admin-match-title">${crestHTML(m.home_club)}<strong>${esc(m.home_club.short_name)} – ${esc(m.away_club.short_name)}</strong>${crestHTML(m.away_club)}<span class="chip ${statusClass(m.status)}">${esc(statusLabel(m.status))}</span></div>
      ${[m.odds_home,m.odds_draw,m.odds_away].every(v=>v!=null)?`<div class="admin-odds">1 ${fmtOdds(m.odds_home)} · N ${fmtOdds(m.odds_draw)} · 2 ${fmtOdds(m.odds_away)} <span>${esc(m.odds_bookmaker||m.odds_provider||"")}</span></div>`:""}
      <div class="admin-score"><input data-admin-home inputmode="numeric" type="number" min="0" max="99" value="${m.home_score??0}"><span>–</span><input data-admin-away inputmode="numeric" type="number" min="0" max="99" value="${m.away_score??0}"></div>
      <div class="admin-match-actions"><button class="btn small live-update" data-admin-action="live">${m.status==="live"?'Actualiser LIVE':'Passer LIVE'}</button><button class="btn small" data-admin-action="finish">Terminer</button><button class="btn secondary small" data-admin-action="postpone">Reporter</button><button class="btn secondary small" data-admin-action="cancel">Annuler</button><button class="btn secondary small" data-admin-action="reopen">Réouvrir</button></div>
    </div>`).join("")||'<div class="empty">Aucun match dans cette journée.</div>';
    $$('[data-admin-match]',box).forEach(row=>{
      const h=$("[data-admin-home]",row),a=$("[data-admin-away]",row); if(h&&a)bindAlternatingScorePair(h,a,()=>{});
      $$('[data-admin-action]',row).forEach(btn=>btn.onclick=()=>adminMatchAction(row,btn.dataset.adminAction));
    });
  }


  function renderPhaseMultipliers(){
    const box=$("#adminPhaseMultipliers");if(!box)return;
    box.innerHTML=state.phases.filter(p=>KO_PHASES.includes(p.code)).map(ph=>`<div class="phase-multiplier"><span><b>${esc(ph.name)}</b><small>Barème score × multiplicateur</small></span><select data-phase-multiplier="${ph.id}">${[1,2,3,4].map(v=>`<option value="${v}" ${Number(ph.default_multiplier||1)===v?'selected':''}>×${v}</option>`).join('')}</select></div>`).join('')||'<div class="empty">Phases V0.4.0 absentes.</div>';
    $$('[data-phase-multiplier]',box).forEach(sel=>sel.onchange=()=>setPhaseMultiplier(sel.dataset.phaseMultiplier,Number(sel.value)));
  }

  async function setPhaseMultiplier(phaseId,multiplier){
    try{
      if(demoMode){const ph=state.phases.find(p=>p.id===phaseId);if(ph)ph.default_multiplier=multiplier;state.allMatches.filter(m=>m.phase_id===phaseId&&["scheduled","postponed"].includes(m.status)).forEach(m=>m.points_multiplier=multiplier);}
      else{const {error}=await sb.rpc("admin_set_phase_multiplier_v040",{p_phase_id:phaseId,p_multiplier:multiplier,p_apply_to_upcoming:true});if(error)throw error;await loadData();}
      renderAll();toast(`Multiplicateur ×${multiplier} appliqué aux matchs à venir.`);
    }catch(err){toast(friendlyError(err),"error");}
  }

  async function seedKnockoutTest(){
    setMsg("#knockoutAdminStatus","Création du tableau complet : 8 barrages → finale…");
    try{
      if(demoMode)throw new Error("Le générateur complet utilise les 24 clubs C1 de Supabase. Configure le projet pour ce test.");
      const {data,error}=await sb.rpc("admin_seed_knockout_test_v040",{p_season_id:state.season.id,p_start_at:new Date(Date.now()+2*24*3600_000).toISOString()});if(error)throw error;
      await loadData();state.selectedKnockoutPhase="KNOCKOUT_PLAYOFF";renderAll();setMsg("#knockoutAdminStatus",`✓ Tableau TEST complet créé : ${data?.ties||23} confrontations. Les gagnants alimenteront automatiquement le tour suivant.`,"ok");toast("⚔️ Phases finales TEST prêtes.");
    }catch(err){setMsg("#knockoutAdminStatus",friendlyError(err),"error");}
  }

  async function assignDefaultChampion(){
    try{
      if(demoMode){toast("En démo, le premier champion est encore ouvert.");return;}
      const {data,error}=await sb.rpc("admin_assign_default_champion_v040",{p_season_id:state.season.id});if(error)throw error;await loadChampionData();renderChampions();toast(`${Number(data||0)} joueur(s) sans choix → OM.`);
    }catch(err){toast(friendlyError(err),"error");}
  }

  function renderAdminKnockout(){
    const box=$("#adminKnockoutMatches");if(!box)return;
    const ties=state.knockoutTies.slice().sort((a,b)=>(phaseById(a.phase_id)?.sort_order||0)-(phaseById(b.phase_id)?.sort_order||0)||a.sort_order-b.sort_order);
    box.innerHTML=ties.length?ties.map(t=>{
      const a=clubById(t.team_a_club_id),b=clubById(t.team_b_club_id),agg=aggregateForTie(t),ms=tieMatches(t);
      return `<div class="admin-tie"><div class="admin-tie-head"><span><b>${esc(phaseById(t.phase_id)?.name||'Phase')}</b><small>${esc(t.label)} · cumul ${agg.a}–${agg.b}</small></span><span class="chip ${t.status==='finished'?'finished':t.status==='live'?'live':''}">${esc(t.status)}</span></div><div class="admin-tie-clubs">${a?crestHTML(a):''}<strong>${a?esc(a.short_name||a.name):'?'}</strong><span>vs</span><strong>${b?esc(b.short_name||b.name):'?'}</strong>${b?crestHTML(b):''}</div>${ms.map(m=>adminKnockoutMatchHTML(m,t)).join('')||'<div class="empty small-empty">Adversaire en attente.</div>'}</div>`;
    }).join(''):'<div class="empty">Aucune phase finale. Utilise « Générer tableau TEST ».</div>';
    $$('[data-admin-ko-match]',box).forEach(row=>{
      $$('[data-admin-ko-action]',row).forEach(btn=>btn.onclick=()=>adminKnockoutMatchAction(row,btn.dataset.adminKoAction));
      const mult=$('[data-ko-match-multiplier]',row);if(mult)mult.onchange=()=>setMatchMultiplier(row.dataset.adminKoMatch,Number(mult.value));
    });
  }

  async function setMatchMultiplier(matchId,multiplier){
    try{if(demoMode){const m=state.allMatches.find(x=>x.id===matchId);if(m)m.points_multiplier=multiplier;}else{const {error}=await sb.rpc("admin_set_match_multiplier_v040",{p_match_id:matchId,p_multiplier:multiplier});if(error)throw error;await loadData();}renderAll();toast(`Match réglé sur ×${multiplier}.`);}catch(err){toast(friendlyError(err),"error");}
  }

  function adminKnockoutMatchHTML(m,tie){
    const canPens=m.leg_number===2||tie.is_single_match;
    return `<div class="admin-ko-match ${m.status==='live'?'live-admin':''}" data-admin-ko-match="${m.id}"><div class="admin-ko-meta"><b>${tie.is_single_match?'Finale':m.leg_number===1?'Aller':'Retour'}</b><span>${esc(fmtDate(m.kickoff_at))}</span><label class="ko-mult-admin">Coef. <select data-ko-match-multiplier>${[1,2,3,4].map(v=>`<option value="${v}" ${Number(m.points_multiplier||1)===v?'selected':''}>×${v}</option>`).join('')}</select></label></div><div class="admin-ko-score"><span>${esc(m.home_club?.short_name||'?')}</span><input data-ko-home type="number" min="0" max="99" value="${m.home_score??0}"><b>–</b><input data-ko-away type="number" min="0" max="99" value="${m.away_score??0}"><span>${esc(m.away_club?.short_name||'?')}</span></div>${canPens?`<div class="admin-ko-extra"><label><input data-ko-et type="checkbox" ${m.went_to_extra_time?'checked':''}> Prolongation · score saisi à 120 min</label><label>TAB <input data-ko-pen-home type="number" min="0" max="20" value="${m.penalties_home??''}"> – <input data-ko-pen-away type="number" min="0" max="20" value="${m.penalties_away??''}"></label></div>`:''}<div class="admin-match-actions"><button class="btn small live-update" data-admin-ko-action="live">${m.status==='live'?'Actualiser LIVE':'Passer LIVE'}</button><button class="btn small" data-admin-ko-action="finish">Terminer</button></div></div>`;
  }

  async function adminKnockoutMatchAction(row,action){
    const id=row.dataset.adminKoMatch,home=Math.max(0,Number($("[data-ko-home]",row).value||0)),away=Math.max(0,Number($("[data-ko-away]",row).value||0));
    const et=Boolean($("[data-ko-et]",row)?.checked),ph=$("[data-ko-pen-home]",row)?.value,pa=$("[data-ko-pen-away]",row)?.value;
    const penHome=ph===""||ph==null?null:Math.max(0,Number(ph)),penAway=pa===""||pa==null?null:Math.max(0,Number(pa));
    const status=action==="finish"?"finished":action==="live"?"live":"scheduled";
    try{
      if(demoMode)throw new Error("Saisie phases finales complète : utilise Supabase avec le patch V0.4.0.");
      const {error}=await sb.rpc("admin_set_knockout_match_state_v040",{p_match_id:id,p_status:status,p_home_score:["live","finished"].includes(status)?home:null,p_away_score:["live","finished"].includes(status)?away:null,p_went_to_extra_time:et,p_penalties_home:penHome,p_penalties_away:penAway,p_kickoff_at:null});if(error)throw error;
      await loadData();renderAll();toast(status==="finished"?"Match terminé · cumul et qualifié recalculés.":status==="live"?"🔴 Score LIVE mis à jour.":"Match rouvert.");
    }catch(err){toast(friendlyError(err),"error");}
  }

  async function loadAvatarModeration() {
    const box=$("#avatarModerationPanel");if(!box||!isAdminProfile())return;
    box.innerHTML='<div class="empty">Chargement des avatars…</div>';
    try{
      let rows=[];
      if(demoMode){rows=state.demoUsers.filter(p=>p.avatar_source==="upload"&&["pending","rejected"].includes(p.avatar_moderation_status)).map(p=>({user_id:p.id,username:p.username,avatar_storage_path:p.avatar_storage_path,avatar_moderation_status:p.avatar_moderation_status,avatar_rejection_reason:p.avatar_rejection_reason,avatar_updated_at:new Date().toISOString(),avatar_key:p.avatar_key}));}
      else{const {data,error}=await sb.rpc("admin_list_avatar_moderation_v053");if(error)throw error;rows=(data||[]).map(r=>({...r,id:r.user_id,avatar_source:"upload"}));await signAvatarRows(rows,{allowPendingForAdmin:true});}
      box.innerHTML=rows.length?rows.map(r=>`<div class="avatar-moderation-row" data-avatar-user="${r.user_id}"><div class="avatar-moderation-preview">${avatarCoreHTML({id:r.user_id,user_id:r.user_id,username:r.username,avatar_source:"upload",avatar_storage_path:r.avatar_storage_path,avatar_moderation_status:r.avatar_moderation_status,avatar_key:r.avatar_key},{allowPending:true})}</div><div><strong>${esc(r.username)}</strong><small>${r.avatar_moderation_status==="pending"?'En attente':`Refusé${r.avatar_rejection_reason?` · ${esc(r.avatar_rejection_reason)}`:''}`} · ${r.avatar_updated_at?esc(fmtDate(r.avatar_updated_at)):''}</small></div><div class="actions">${r.avatar_moderation_status==="pending"?`<button class="btn small" data-avatar-decision="approve">Valider</button><button class="btn secondary small" data-avatar-decision="reject">Refuser</button>`:'<span class="chip">Historique</span>'}</div></div>`).join(''):'<div class="empty">🦉 Aucun avatar en attente de modération.</div>';
      $$('[data-avatar-user]',box).forEach(row=>$$('[data-avatar-decision]',row).forEach(btn=>btn.onclick=()=>moderateAvatar(row.dataset.avatarUser,btn.dataset.avatarDecision)));
    }catch(err){box.innerHTML=`<div class="empty red">${esc(friendlyError(err))}</div>`;}
  }

  async function moderateAvatar(userId,decision) {
    let reason=null;if(decision==="reject"){reason=prompt("Motif du refus (facultatif)","")||null;}
    try{
      if(demoMode){const p=state.demoUsers.find(u=>u.id===userId);if(p){p.avatar_moderation_status=decision==="approve"?"approved":"rejected";p.avatar_rejection_reason=decision==="reject"?reason:null;localStorage.setItem("nidc_demo_users",JSON.stringify(state.demoUsers));}}
      else{const {error}=await sb.rpc("admin_moderate_avatar_v053",{p_user_id:userId,p_decision:decision,p_reason:reason});if(error)throw error;}
      await loadProfileDirectory();if(String(userId)===String(state.user?.id)&&!demoMode)await loadProfile();renderRanking();renderTeams();renderProfile();await loadAvatarModeration();toast(decision==="approve"?"Avatar validé.":"Avatar refusé.");
    }catch(err){toast(friendlyError(err),"error");}
  }

  async function loadRegistrationRequests() {
    const box=$("#registrationRequests");if(!box)return;
    box.innerHTML='<div class="empty">Chargement des demandes…</div>';
    try {
      if(demoMode){box.innerHTML='<div class="empty">Mode démo : aucune demande Supabase.</div>';return;}
      const {data,error}=await sb.rpc("admin_list_registration_requests");if(error)throw error;
      const rows=data||[];
      box.innerHTML=rows.length?rows.map(r=>`<div class="registration-request" data-registration="${r.user_id}"><div><strong>${esc(r.username)}</strong><div class="muted">${esc(r.first_name||"Prénom non renseigné")} · ${esc(r.email||"E-mail indisponible")}</div><div class="request-meta"><span class="chip">${esc(r.status)}</span><span>${esc(fmtDate(r.created_at))}</span></div></div><div class="request-actions"><button class="btn small" data-decision="approve">Autoriser</button><button class="btn secondary small" data-decision="reject">Refuser</button></div></div>`).join(""):'<div class="empty">🦉 Aucune demande en attente.</div>';
      $$('[data-registration]',box).forEach(row=>$$('[data-decision]',row).forEach(btn=>btn.onclick=()=>reviewRegistration(row.dataset.registration,btn.dataset.decision)));
    } catch(err) { box.innerHTML=`<div class="empty red">${esc(friendlyError(err))}</div>`; }
  }

  async function reviewRegistration(userId,decision) {
    try{const {data,error}=await sb.rpc("admin_review_registration",{p_user_id:userId,p_decision:decision});if(error)throw error;toast(data==="active"?"🦉 Joueur autorisé à entrer dans le Nid.":"Demande refusée.");await loadRegistrationRequests();}catch(err){toast(friendlyError(err),"error");}
  }

  function seasonStartYear() {
    const match=String(state.season?.slug||state.season?.name||"").match(/(20\d{2})/);
    return match ? Number(match[1]) : new Date().getFullYear();
  }

  async function syncFootballData(action) {
    const pending = action === "clubs"
      ? "Synchronisation des 36 clubs et logos Champions League 2025/26…"
      : action === "catalog"
        ? "Import de la bibliothèque clubs + logos : Ligue 1, Premier League, Liga, Serie A et Bundesliga…"
        : action === "odds"
          ? "Actualisation des cotes 1N2 pré-match depuis football-data.org…"
          : "Import strict des 144 matchs (8 × 18), cotes disponibles incluses, puis décalage en 2026/27…";
    setMsg("#syncStatus", pending);
    try {
      if(demoMode){setMsg("#syncStatus",action==="odds"?"Mode démo : les cotes affichées sont fictives et servent uniquement à tester l’interface.":"Mode démo : la synchronisation distante n'est pas appelée.","ok");return;}
      const {data,error}=await sb.functions.invoke("sync-football-data",{body:{action,seasonYear:seasonStartYear(),seasonSlug:state.season.slug,competitionCode:"CL"}});
      if(error) throw new Error("La fonction sync-football-data ne répond pas. Vérifie son déploiement et le secret FOOTBALL_DATA_API_KEY.");
      if(!data?.ok) throw new Error(data?.error||"Synchronisation impossible.");
      if(action==="catalog"){
        const details=Object.entries(data.catalogByCompetition||{}).map(([code,v])=>`${code} ${v.clubs||0}`).join(" · ");
        setMsg("#syncStatus",`✓ Bibliothèque Top 5 : ${data.catalogClubCount||0} clubs uniques · ${data.catalogLogoCount||0} logos${details?` · ${details}`:""}`,"ok");
        await loadData(); state.clubPreviewFilter="ALL"; if($("#clubPreviewFilter"))$("#clubPreviewFilter").value="ALL"; renderAll(); toast("Bibliothèque clubs Top 5 actualisée.");
        return;
      }
      const common=`source ${data.sourceSeasonYear||2025}/26 → saison test 2026/27 · ${data.clubCount||0} clubs · ${data.logoCount||0} logos · ${data.matchdayCount||0} journées · ${data.matchCount||0} matchs`;
      if(action==="odds" && Number(data.oddsCount||0)===0){
        setMsg("#syncStatus",`⚠️ ${common} · aucune cote 1N2 reçue. Le flux football-data.org renvoie actuellement odds=null ; l’option Odds doit être disponible sur l’abonnement pour remplir ces valeurs.`);
      } else {
        setMsg("#syncStatus",`✓ ${common} · ${data.oddsCount||0} match(s) avec cotes 1N2${Number(data.repairedLegacyClubs||0)>0?` · ${data.repairedLegacyClubs} doublon(s) TEST réparé(s)`:""}`,"ok");
      }
      await loadData(); renderAll(); toast(action==="odds"?`${data.oddsCount||0} match(s) avec cotes 1N2.`:"Synchronisation V0.4.0 terminée.");
    } catch(err) { setMsg("#syncStatus",friendlyError(err),"error"); }
  }

  async function syncOdds() {
    setMsg("#syncStatus", "Recherche des cotes 1N2 : Football-Data puis source externe si nécessaire…");
    try {
      if (demoMode) {
        setMsg("#syncStatus", "Mode démo : les cotes affichées sont fictives et servent uniquement à tester l’interface.", "ok");
        return;
      }

      const fd = await sb.functions.invoke("sync-football-data", {
        body: { action: "odds", seasonYear: seasonStartYear(), seasonSlug: state.season.slug, competitionCode: "CL" }
      });
      if (fd.error) throw new Error("La fonction sync-football-data ne répond pas. Vérifie son déploiement et FOOTBALL_DATA_API_KEY.");
      if (!fd.data?.ok) throw new Error(fd.data?.error || "Synchronisation Football-Data impossible.");

      const fdCount = Number(fd.data.oddsCount || 0);
      let external = null;
      let externalUnavailable = false;

      // Complément optionnel pour les vraies rencontres à venir. La saison TEST est
      // transposée d'un an, donc une source de cotes courantes peut ne rien retrouver.
      if (CFG.ODDS_EXTERNAL_ENABLED === true) {
        try {
          const ext = await sb.functions.invoke("sync-odds", {
            body: { seasonSlug: state.season.slug, matchdayId: state.selectedMatchdayId || null }
          });
          if (!ext.error && ext.data?.ok) external = ext.data;
          else externalUnavailable = true;
        } catch (_) {
          externalUnavailable = true;
        }
      }

      await loadData();
      renderAll();

      const extUpdated = Number(external?.updated || 0);
      const extMatched = Number(external?.matched || 0);
      const totalNow = state.allMatches.filter(m => [m.odds_home,m.odds_draw,m.odds_away].every(v => v != null)).length;
      const sourceBits = [`Football-Data : ${fdCount}`];
      if (external) sourceBits.push(`source externe : ${extUpdated} mise(s) à jour sur ${extMatched} match(s) reconnu(s)`);
      else if (externalUnavailable) sourceBits.push("source externe activée mais indisponible");
      else if (CFG.ODDS_EXTERNAL_ENABLED !== true) sourceBits.push("source externe désactivée");

      if (totalNow > 0) {
        setMsg("#syncStatus", `✓ ${totalNow} match(s) avec cotes 1N2 · ${sourceBits.join(" · ")}`, "ok");
        toast(`${totalNow} match(s) avec cotes 1N2.`);
      } else {
        setMsg("#syncStatus", `⚠️ Aucune cote reçue · ${sourceBits.join(" · ")}. Football-Data nécessite l’accès Odds ; la source externe nécessite ODDS_API_KEY. Le Nid n’invente aucune cote.`);
        toast("Aucune cote 1N2 disponible pour ces rencontres.");
      }
    } catch (err) {
      setMsg("#syncStatus", friendlyError(err), "error");
    }
  }

  async function createMatchday() {
    const number=Number($("#adminMdNumber").value), name=$("#adminMdName").value.trim()||`Journée ${number}`;
    try {
      if(!number)throw new Error("Numéro de journée invalide.");
      if(demoMode){const id=`md-${Date.now()}`;state.matchdays.push({id,season_id:state.season.id,number,name});state.matchdays.sort((a,b)=>a.number-b.number);state.selectedMatchdayId=id;state.matches=[];renderAll();toast("Journée créée en démo.");return;}
      const {data:phase}=await sb.from("competition_phases").select("id").eq("season_id",state.season.id).eq("code","LEAGUE").maybeSingle();
      const {data,error}=await sb.from("matchdays").insert({season_id:state.season.id,phase_id:phase?.id||null,number,name}).select("id").single();
      if(error)throw error;state.selectedMatchdayId=data.id;await loadData();renderAll();toast("Journée créée.");
    }catch(err){toast(friendlyError(err),"error");}
  }

  async function createMatch() {
    const matchday_id=$("#adminMatchdaySelect").value,home_club_id=$("#adminHomeClub").value,away_club_id=$("#adminAwayClub").value,stadium=$("#adminStadium").value.trim();
    const kickoff=parseFrenchLocalInput($("#adminKickoff").value);
    try {
      if(!matchday_id||!home_club_id||!away_club_id||!kickoff)throw new Error("Informations du match incomplètes.");
      if(home_club_id===away_club_id)throw new Error("Un club ne peut pas jouer contre lui-même.");
      if(demoMode){const id=`m-${Date.now()}`;state.allMatches.push({id,season_id:state.season.id,matchday_id,kickoff_at:kickoff,status:"scheduled",data_source:"manual",home_score:null,away_score:null,stadium,home_club:state.clubs.find(c=>c.id===home_club_id),away_club:state.clubs.find(c=>c.id===away_club_id)});state.selectedMatchdayId=matchday_id;state.matches=state.allMatches.filter(m=>m.matchday_id===matchday_id);renderAll();toast("Match ajouté en démo.");return;}
      const md=state.matchdays.find(x=>x.id===matchday_id);
      const phaseId=(await sb.from("competition_phases").select("id").eq("season_id",state.season.id).eq("code","LEAGUE").maybeSingle()).data?.id||null;
      const {error}=await sb.from("matches").insert({season_id:state.season.id,phase_id:phaseId,matchday_id,home_club_id,away_club_id,kickoff_at:kickoff,stadium:stadium||null,status:"scheduled",data_source:"manual"});
      if(error)throw error;state.selectedMatchdayId=md?.id||matchday_id;await loadData();renderAll();toast("Match ajouté au calendrier.");
    }catch(err){toast(friendlyError(err),"error");}
  }

  async function adminMatchAction(row,action) {
    const id=row.dataset.adminMatch, home=Math.max(0,Number($("[data-admin-home]",row).value||0)), away=Math.max(0,Number($("[data-admin-away]",row).value||0));
    try {
      let status=action==="finish"?"finished":action==="live"?"live":action==="postpone"?"postponed":action==="cancel"?"cancelled":"scheduled";
      let kickoff=null;
      if(action==="postpone") {
        const m=state.allMatches.find(x=>x.id===id);
        const suggested=toLocalDateTimeInput(new Date(Math.max(Date.now()+3600_000,new Date(m.kickoff_at).getTime()+24*3600_000)));
        const value=prompt("Nouvelle date/heure française (AAAA-MM-JJTHH:MM)",suggested);
        if(!value)return;
        kickoff=parseFrenchLocalInput(value);
        if(!kickoff)throw new Error("Nouvelle date invalide.");
      }
      if(demoMode){
        const results=JSON.parse(localStorage.getItem("nidc_demo_results")||"{}"),old=results[id]||{};
        results[id]={...old,status,home_score:["live","finished"].includes(status)?home:(status==="scheduled"?null:old.home_score??null),away_score:["live","finished"].includes(status)?away:(status==="scheduled"?null:old.away_score??null),kickoff_at:kickoff||old.kickoff_at};
        localStorage.setItem("nidc_demo_results",JSON.stringify(results));
        const target=state.allMatches.find(x=>x.id===id);if(target){target.status=status;if(["live","finished"].includes(status)){target.home_score=home;target.away_score=away;}if(status==="scheduled"){target.home_score=null;target.away_score=null;}if(kickoff)target.kickoff_at=kickoff;}
        buildLocalHistory();await loadRankingData(state.rankingScope,false);
      } else {
        const {error}=await sb.rpc("admin_set_match_state",{p_match_id:id,p_status:status,p_home_score:["live","finished"].includes(status)?home:null,p_away_score:["live","finished"].includes(status)?away:null,p_kickoff_at:kickoff});
        if(error)throw error;await loadData();
      }
      renderAll();toast(status==="finished"?"Résultat final enregistré. Classement officiel recalculé.":status==="live"?`🔴 LIVE ${home}–${away} : classement provisoire mis à jour.`:`Match : ${statusLabel(status)}.`);
    }catch(err){toast(friendlyError(err),"error");}
  }

  async function saveProfile() {
    const username=$("#profileUsernameInput").value.trim(),clubInput=$("#profileClubInput").value.trim(),club_heart=findClubByHeart(clubInput)?.name||clubInput;setMsg("#profileMsg","Enregistrement…");
    try {if(demoMode){state.profile.username=username;state.profile.club_heart=club_heart;const i=state.demoUsers.findIndex(u=>u.id===state.user.id);if(i>=0)state.demoUsers[i]={...state.demoUsers[i],...state.profile};localStorage.setItem("nidc_demo_users",JSON.stringify(state.demoUsers));buildDemoStandings();}else{const {error}=await sb.from("profiles").update({username,club_heart}).eq("id",state.user.id);if(error)throw error;await loadProfile();}await loadProfileDirectory();renderProfile();renderRanking();renderTeams();setMsg("#profileMsg","Profil enregistré.","ok");toast("Profil mis à jour.");}catch(err){setMsg("#profileMsg",friendlyError(err),"error");}
  }
