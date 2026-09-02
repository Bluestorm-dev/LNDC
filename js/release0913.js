"use strict";

// Le Nid des Champions V0.9.13 — mobile, onboarding & fiches clubs
(function(){
  const q=(s,r=document)=>r.querySelector(s), qa=(s,r=document)=>Array.from(r.querySelectorAll(s));
  state.release0913=state.release0913||{onboardingDraft:null};

  function v0913AvatarChoices(filter=""){
    const f=String(filter||"").trim().toLocaleLowerCase("fr");
    return OFFICIAL_AVATARS.filter(a=>!f||`${a.l} ${a.c}`.toLocaleLowerCase("fr").includes(f));
  }

  function onboardingDraftV0913(){
    if(state.release0913.onboardingDraft)return state.release0913.onboardingDraft;
    const heart=String(state.profile?.club_heart||"");
    const heartClub=state.clubs.find(c=>c.name===heart||c.short_name===heart)||null;
    const prefs={...defaultNotificationPreferences(),...(state.notificationPreferences||{})};
    state.release0913.onboardingDraft={
      avatarKey:normalizedAvatarKey(state.profile?.avatar_key),
      favoriteClubId:heartClub?.id||"",
      championClubId:state.championStatus?.first_club_id||"",
      notificationPreset:"essential",
      enablePush:false,
      prefs
    };
    return state.release0913.onboardingDraft;
  }

  function onboardingClubOptionsV0913(){
    return [...state.clubs].sort((a,b)=>String(a.name).localeCompare(String(b.name),"fr")).map(c=>`<option value="${esc(c.id)}">${esc(compactClubName(c))} · ${esc(c.country||"")}</option>`).join("");
  }
  function onboardingChampionOptionsV0913(){
    const rows=state.championCandidates?.[1]?.length?state.championCandidates[1]:state.clubs;
    return rows.map(x=>{const id=x.club_id||x.id, club=clubById(id)||x;return `<option value="${esc(id)}">${esc(compactClubName(club))}</option>`}).join("");
  }

  function onboardingStepHTMLV0913(step){
    const d=onboardingDraftV0913();
    if(step===0)return `<div class="onboarding-welcome-v0913"><img src="assets/branding/owl/owl-masked-main.png" alt=""><h2>Bienvenue dans le Nid</h2><p>En deux minutes, on prépare ton profil avant ton premier prono.</p><div class="onboarding-feature-grid-v0913"><span>⚽<b>Pronostics</b><small>Les scores s’enregistrent automatiquement.</small></span><span>🏆<b>Champion</b><small>Ton grand favori vaut 100 points.</small></span><span>🦉<b>Teams & Musée</b><small>Badges, records, casseroles et rivalités.</small></span><span>🔔<b>Notifications</b><small>Tu choisis ce que le Nid peut t’envoyer.</small></span></div></div>`;
    if(step===1)return `<div class="onboarding-step-v0913"><span class="eyebrow gold">Ton identité</span><h2>Choisis ton avatar</h2><p>Tu pourras le changer plus tard dans ton Profil.</p><input id="onboardingAvatarSearchV0913" class="onboarding-search-v0913" type="search" placeholder="Chercher un avatar…"><div id="onboardingAvatarGridV0913" class="onboarding-avatar-grid-v0913"></div></div>`;
    if(step===2){const selected=clubById(d.favoriteClubId);return `<div class="onboarding-step-v0913"><span class="eyebrow gold">Club de cœur</span><h2>Quelle équipe tu supportes ?</h2><p>Ce choix apparaît sur ton profil. Il ne change pas tes pronostics.</p><label class="onboarding-select-card-v0913"><span>Mon club préféré</span><select id="onboardingFavoriteClubV0913"><option value="">Aucun club de cœur</option>${onboardingClubOptionsV0913()}</select></label><div id="onboardingClubPreviewV0913" class="onboarding-club-preview-v0913">${selected?`${crestHTML(selected,true)}<div><strong>${esc(selected.name)}</strong><small>${esc([selected.country,selected.venue].filter(Boolean).join(" · "))}</small></div>`:'<span class="muted">Aucun club sélectionné.</span>'}</div></div>`;}
    if(step===3){const open=!!state.championStatus?.first_open, current=state.championStatus?.first_club_id;return `<div class="onboarding-step-v0913"><span class="eyebrow gold">La grande intuition</span><h2>Ton vainqueur de la Ligue des champions</h2><p>${open?'Choisis ton Champion n°1. Il peut rapporter 100 points.':'Le choix du Champion est actuellement verrouillé ; tu pourras consulter ton choix dans le Profil.'}</p>${open?`<label class="onboarding-select-card-v0913"><span>Champion n°1 · 100 pts</span><select id="onboardingChampionV0913"><option value="">Choisir une équipe…</option>${onboardingChampionOptionsV0913()}</select></label><div class="onboarding-champion-note-v0913">🔒 Ton choix reste secret jusqu’au verrouillage de la fenêtre.</div>`:`<div class="onboarding-champion-note-v0913">${current?'✅ Ton Champion est déjà enregistré.':'🔒 Aucun choix disponible maintenant.'}</div>`}</div>`;}
    const preset=d.notificationPreset;
    return `<div class="onboarding-step-v0913"><span class="eyebrow gold">Notifications</span><h2>À quel point le Hibou doit-il parler ?</h2><p>Tu pourras tout ajuster ensuite dans Profil → Préférences.</p><div class="notification-presets-v0913"><button type="button" data-notif-preset-v0913="essential" class="${preset==='essential'?'active':''}"><b>Essentiel</b><small>Rappels de pronos, résultats importants et Champion.</small></button><button type="button" data-notif-preset-v0913="all" class="${preset==='all'?'active':''}"><b>Tout le Nid</b><small>Matchs, Teams, rivalités, Musée et Hibou.</small></button><button type="button" data-notif-preset-v0913="quiet" class="${preset==='quiet'?'active':''}"><b>Discret</b><small>Seulement les rappels indispensables.</small></button></div><label class="onboarding-push-toggle-v0913"><input id="onboardingEnablePushV0913" type="checkbox" ${d.enablePush?'checked':''}><span><b>Activer les notifications Push sur cet appareil</b><small>Le navigateur demandera l’autorisation à la fin.</small></span></label></div>`;
  }

  function renderAvatarGridV0913(root,filter=""){
    const d=onboardingDraftV0913(),grid=q("#onboardingAvatarGridV0913",root);if(!grid)return;
    const rows=v0913AvatarChoices(filter);
    grid.innerHTML=rows.map(a=>`<button type="button" class="${a.k===d.avatarKey?'active':''}" data-onboarding-avatar-v0913="${esc(a.k)}"><img src="${esc(officialAvatarUrl(a.k))}" alt=""><span>${esc(a.l)}</span></button>`).join("")||'<div class="empty">Aucun avatar trouvé.</div>';
    qa("[data-onboarding-avatar-v0913]",grid).forEach(b=>b.onclick=()=>{d.avatarKey=b.dataset.onboardingAvatarV0913;renderAvatarGridV0913(root,q("#onboardingAvatarSearchV0913",root)?.value||"")});
  }

  function notificationPresetPrefsV0913(preset){
    const base={...defaultNotificationPreferences(),user_id:state.user.id};
    if(preset==="all")return {...base,reminder_24h:true,reminder_3h:true,reminder_1h:true,reminder_30m:true,category_social:true,category_team:true,category_rival:true,category_gamification:true};
    if(preset==="quiet")return {...base,category_rival:false,category_team:false,category_social:false,category_ranking:false,category_badges:false,category_records:false,category_gamification:false,reminder_24h:false,reminder_3h:true,reminder_1h:false,reminder_30m:false};
    return {...base,category_social:false,category_ranking:false,category_records:false,reminder_24h:false,reminder_3h:true,reminder_1h:false,reminder_30m:true};
  }

  async function completeOnboardingV0913(root){
    const d=onboardingDraftV0913(),btn=q("#onboardingNextV0913",root);btn.disabled=true;
    try{
      if(state.championStatus?.first_open&&!d.championClubId&&!state.championStatus?.first_club_id)throw new Error("Choisis ton Champion avant de terminer.");
      const fav=clubById(d.favoriteClubId);
      if(demoMode){state.profile.avatar_key=d.avatarKey;state.profile.avatar_source="library";state.profile.club_heart=fav?.name||null;localStorage.setItem(`nidc_demo_notification_preferences:${state.user.id}`,JSON.stringify(notificationPresetPrefsV0913(d.notificationPreset)));}
      else{
        const av=await sb.rpc("select_player_avatar_v053",{p_avatar_key:d.avatarKey});if(av.error)throw av.error;
        const pr=await sb.from("profiles").update({club_heart:fav?.name||null}).eq("id",state.user.id);if(pr.error)throw pr.error;
        if(state.championStatus?.first_open&&d.championClubId&&String(d.championClubId)!==String(state.championStatus?.first_club_id||"")){const cp=await sb.rpc("save_champion_pick_v040",{p_pick_number:1,p_club_id:d.championClubId,p_season_id:state.season.id});if(cp.error)throw cp.error;}
        const prefs=notificationPresetPrefsV0913(d.notificationPreset);const np=await sb.from("notification_preferences").upsert(prefs,{onConflict:"user_id"});if(np.error)throw np.error;
        const ob=await sb.rpc("save_my_onboarding_v099",{p_step:4,p_completed:true,p_dismissed:false});if(ob.error)throw ob.error;
      }
      if(d.enablePush&&typeof enablePushNotifications==="function"){try{await enablePushNotifications();}catch(_){} }
      if(!demoMode){await loadProfile();await Promise.all([loadChampionData(),loadNotificationData()]);}
      state.preseason099&&(state.preseason099.onboardingLoaded=false);
      state.release0913.onboardingDraft=null;root.remove();renderAll();toast("🦉 Ton Nid est prêt. Bienvenue !");
    }catch(err){btn.disabled=false;const box=q("#onboardingMsgV0913",root);if(box){box.textContent=friendlyError(err);box.className="form-msg error";}}
  }

  function openOnboardingV0913(manual=false){
    q("#onboardingOverlayV0913")?.remove();let step=0;onboardingDraftV0913();
    const root=document.createElement("div");root.id="onboardingOverlayV0913";root.className="onboarding-overlay-v0913";root.setAttribute("role","dialog");root.setAttribute("aria-modal","true");
    const draw=()=>{
      root.innerHTML=`<div class="onboarding-modal-v0913"><div class="onboarding-top-v0913"><div><span class="eyebrow">Première connexion</span><strong>Configuration du Nid</strong></div><span>${step+1}/5</span></div><div class="onboarding-progress-v0913"><i style="width:${((step+1)/5)*100}%"></i></div><div class="onboarding-body-v0913">${onboardingStepHTMLV0913(step)}</div><div id="onboardingMsgV0913" class="form-msg"></div><div class="onboarding-actions-v0913">${step>0?'<button id="onboardingPrevV0913" class="btn secondary" type="button">← Retour</button>':'<span></span>'}${manual?'<button id="onboardingCloseV0913" class="btn secondary" type="button">Fermer</button>':'<span></span>'}<button id="onboardingNextV0913" class="btn gold" type="button">${step===4?'Terminer':'Continuer →'}</button></div></div>`;
      if(step===1){renderAvatarGridV0913(root);q("#onboardingAvatarSearchV0913",root).oninput=e=>renderAvatarGridV0913(root,e.target.value);}
      if(step===2){const sel=q("#onboardingFavoriteClubV0913",root);sel.value=onboardingDraftV0913().favoriteClubId||"";sel.onchange=()=>{onboardingDraftV0913().favoriteClubId=sel.value;draw()};}
      if(step===3&&q("#onboardingChampionV0913",root)){const sel=q("#onboardingChampionV0913",root);sel.value=onboardingDraftV0913().championClubId||"";sel.onchange=()=>onboardingDraftV0913().championClubId=sel.value;}
      if(step===4){qa("[data-notif-preset-v0913]",root).forEach(b=>b.onclick=()=>{onboardingDraftV0913().notificationPreset=b.dataset.notifPresetV0913;draw()});const p=q("#onboardingEnablePushV0913",root);p.onchange=()=>onboardingDraftV0913().enablePush=p.checked;}
      q("#onboardingPrevV0913",root)?.addEventListener("click",()=>{step=Math.max(0,step-1);draw()});
      q("#onboardingCloseV0913",root)?.addEventListener("click",()=>root.remove());
      q("#onboardingNextV0913",root).onclick=()=>{if(step===4)return completeOnboardingV0913(root);step++;draw()};
    };
    draw();document.body.appendChild(root);
  }
  window.openOnboardingV0913=openOnboardingV0913;

  async function maybeOfferOnboardingV0913(){
    if(!state.user||!state.profile)return;
    if(typeof loadOnboardingV099==="function")await loadOnboardingV099(true);
    const done=!!state.preseason099?.onboarding?.completed_at;if(done)return;
    if(sessionStorage.getItem("nidc-v0913-onboarding-offered"))return;
    sessionStorage.setItem("nidc-v0913-onboarding-offered","1");setTimeout(()=>openOnboardingV0913(false),350);
  }
  window.maybeOfferTutorialV099=maybeOfferOnboardingV0913;
  window.openTutorialV099=()=>openOnboardingV0913(true);
  window.renderOnboardingCardV099=function(){
    const old=q("#profileOnboardingV099");if(!old||!state.profile)return;
    const done=!!state.preseason099?.onboarding?.completed_at;
    old.innerHTML=`<div><span class="eyebrow gold">Prise en main</span><h4>${done?'Configuration terminée':'Configurer mon Nid'}</h4><p>Avatar, club de cœur, Champion et notifications au même endroit.</p></div><button id="openOnboardingV0913FromProfile" class="btn secondary small" type="button">${done?'↻ Revoir':'▶ Commencer'}</button>`;
    q("#openOnboardingV0913FromProfile",old)?.addEventListener("click",()=>openOnboardingV0913(true));
  };

  function clubPronoRowV0913(m,clubId){
    const home=String(m.home_club?.id)===String(clubId), p=state.predictions.get(m.id),locked=isLocked(m)||m.status==="cancelled";
    const hs=p?.home_score??0,as=p?.away_score??0;
    return `<article class="club-prono-card-v0913" data-club-prono-card-v0913="${esc(m.id)}"><div class="club-prono-meta-v0913"><time>${esc(fmtDate(m.kickoff_at))} · ${esc(fmtTime(m.kickoff_at))}</time><span>${esc([m.stadium||m.home_club?.venue,m.venue_country||m.home_club?.country].filter(Boolean).join(" · ")||"Lieu à confirmer")}</span></div><div class="club-prono-teams-v0913"><div>${crestHTML(m.home_club)}<strong>${esc(compactClubName(m.home_club))}</strong></div><b>VS</b><div>${crestHTML(m.away_club)}<strong>${esc(compactClubName(m.away_club))}</strong></div></div><div class="club-prono-control-v0913"><div class="mini-score-v0913"><button type="button" data-mini-delta="-1" data-mini-side="home" ${locked?'disabled':''}>−</button><input data-mini-score="home" inputmode="numeric" value="${hs}" ${locked?'disabled':''}><button type="button" data-mini-delta="1" data-mini-side="home" ${locked?'disabled':''}>+</button></div><span>–</span><div class="mini-score-v0913"><button type="button" data-mini-delta="-1" data-mini-side="away" ${locked?'disabled':''}>−</button><input data-mini-score="away" inputmode="numeric" value="${as}" ${locked?'disabled':''}><button type="button" data-mini-delta="1" data-mini-side="away" ${locked?'disabled':''}>+</button></div></div><div class="save-state ${locked?'locked':p?'saved':''}">${locked?'🔒 Verrouillé':p?'✓ Enregistré':'À pronostiquer'}</div></article>`;
  }

  function bindClubPronosV0913(root){
    qa("[data-club-prono-card-v0913]",root).forEach(card=>{
      const id=card.dataset.clubPronoCardV0913,home=q('[data-mini-score="home"]',card),away=q('[data-mini-score="away"]',card);if(!home||home.disabled)return;
      const save=debounce(()=>savePrediction(id,Number(home.value||0),Number(away.value||0),card),260);
      [home,away].forEach(i=>i.oninput=()=>{i.value=String(Math.max(0,Math.min(99,parseInt(i.value||"0",10)||0)));save()});
      qa("[data-mini-delta]",card).forEach(b=>b.onclick=()=>{const input=q(`[data-mini-score="${b.dataset.miniSide}"]`,card);input.value=String(Math.max(0,Math.min(99,Number(input.value||0)+Number(b.dataset.miniDelta))));save()});
    });
  }

  function openClubSheetV0913(clubId){
    const club=state.clubs.find(c=>String(c.id)===String(clubId));if(!club)return;
    const standing=(Array.isArray(state.uclStandings)?state.uclStandings:[]).find(r=>String(r.club_id)===String(clubId))||null,now=Date.now();
    const matches=state.allMatches.filter(m=>String(m.home_club?.id)===String(clubId)||String(m.away_club?.id)===String(clubId)).sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at));
    const next=matches.filter(m=>m.status!=="cancelled"&&new Date(m.kickoff_at).getTime()>now).slice(0,4),recent=matches.filter(m=>m.status==="finished").slice(-4).reverse();
    const recentHtml=recent.map(m=>{const home=String(m.home_club?.id)===String(clubId),score=`${m.home_score??0}–${m.away_score??0}`,opp=home?m.away_club:m.home_club;return `<div class="club-result-row-v0913"><time>${esc(fmtDate(m.kickoff_at))}</time>${crestHTML(opp)}<strong>${home?score.split('–')[0]:score.split('–')[1]} – ${home?score.split('–')[1]:score.split('–')[0]}</strong><span>${esc(compactClubName(opp))}</span></div>`}).join("");
    const root=modal(club.name,`<div class="club-sheet-v0913"><header class="club-sheet-hero-v0913">${crestHTML(club,true)}<div><span class="eyebrow gold">Fiche équipe</span><h2>${esc(compactClubName(club))}</h2><p>${esc([club.country,club.venue].filter(Boolean).join(" · ")||"Ligue des champions")}</p></div></header><div class="club-sheet-stats-v0913"><span><b>${standing?.position?`#${standing.position}`:'—'}</b><small>Classement</small></span><span><b>${Number(standing?.points||0)}</b><small>Points</small></span><span><b>${standing?`${Number(standing.won||0)}-${Number(standing.draw||0)}-${Number(standing.lost||0)}`:'—'}</b><small>V-N-D</small></span><span><b>${standing?.form?esc(standing.form):'—'}</b><small>Forme</small></span></div><section><div class="section-title compact"><div><h4>Prochains matchs</h4><p>Tu peux pronostiquer ici, sans quitter la fiche.</p></div></div><div class="club-pronos-v0913">${next.length?next.map(m=>clubPronoRowV0913(m,clubId)).join(''):'<div class="empty">Aucun match à venir.</div>'}</div></section><section><div class="section-title compact"><div><h4>Derniers résultats</h4></div></div><div class="club-results-v0913">${recentHtml||'<div class="empty">Aucun résultat.</div>'}</div></section></div>`);
    q(".modal-card",root)?.classList.add("club-sheet-modal-v0913");bindClubPronosV0913(root);
  }
  window.openClubSheetV0913=openClubSheetV0913;

  function enhanceMatchCardsV0913(){
    qa(".calendar-day [data-match]").forEach(card=>{
      const m=state.allMatches.find(x=>String(x.id)===String(card.dataset.match));if(!m)return;
      const teams=card.querySelectorAll(".teams>.team");[[teams[0],m.home_club],[teams[1],m.away_club]].forEach(([el,club])=>{if(!el||!club)return;const open=()=>openClubSheetV0913(club.id);el.onclick=e=>{if(e.target.closest("button,input"))return;open()};el.onkeydown=e=>{if(e.key==="Enter"||e.key===" "){e.preventDefault();open()}};});
    });
  }

  const baseRenderMatchPanelsV0913=window.renderMatchPanels;
  if(typeof baseRenderMatchPanelsV0913==="function")window.renderMatchPanels=function(){const r=baseRenderMatchPanelsV0913.apply(this,arguments);setTimeout(enhanceMatchCardsV0913,0);return r;};

  function renderRelease0913(){
    enhanceMatchCardsV0913();
    q("#registrationAdminSection")?.classList.add("hidden");
  }
  window.renderRelease0913=renderRelease0913;
})();
