"use strict";

// Le Nid des Champions V0.9.11 — Betclic expérimental + verrouillage progressif + nettoyage communication
(function(){
  state.release0911 = state.release0911 || {
    betclicProbe:null,
    betclicLastSync:null,
    messageCounts:null,
    loadingCounts:false
  };

  function setting0911(key,fallback=false){
    const v=state.appSettings?.[key];
    return typeof v==="boolean"?v:(v==null?fallback:Boolean(v));
  }

  function renderBetclicPanelV0911(){
    const root=$("#adminBetclicPanelV0911"); if(!root)return;
    const enabled=setting0911("feature_betclic_odds",true);
    const apiEnabled=setting0911("feature_api",true);
    const probe=state.release0911.betclicProbe;
    const sync=state.release0911.betclicLastSync;
    const sample=(probe?.sample||[]).slice(0,8);
    root.innerHTML=`
      <div class="admin-sync-row">
        <div>
          <span class="eyebrow gold">Cotes 1N2 · expérimental</span>
          <h3>Betclic — source non officielle</h3>
          <p class="muted">Lecture seule des cotes publiques via le backend gRPC-web utilisé par le site Betclic. Aucun compte Betclic, aucune clé et aucun pari automatisé. Si le flux casse, le Nid conserve Football-Data et la saisie manuelle.</p>
        </div>
        <div class="actions">
          <button id="probeBetclicBtnV0911" class="btn secondary small" ${(!apiEnabled||!enabled)&&state.profile?.role!=="super_admin"?"disabled":""}>🧪 Tester Betclic</button>
          <button id="syncBetclicOddsBtnV0911" class="btn gold small" ${(!apiEnabled||!enabled)&&state.profile?.role!=="super_admin"?"disabled":""}>💶 Synchroniser Betclic</button>
        </div>
      </div>
      <div class="betclic-health-v0911">
        <span class="${enabled?"ok":"off"}"><i></i>${enabled?"Source autorisée":"Source désactivée"}</span>
        <span><i></i>Fallback manuel conservé</span>
        <span><i></i>Sans secret API</span>
      </div>
      ${probe?`<details class="betclic-debug-v0911"><summary>Dernier test · ${Number(probe.received||0)} rencontre(s) reçue(s)</summary>
        ${probe.feedFrom||probe.feedTo?`<p class="muted">Plage du flux général : ${probe.feedFrom?esc(new Date(probe.feedFrom).toLocaleString("fr-FR")):"?"} → ${probe.feedTo?esc(new Date(probe.feedTo).toLocaleString("fr-FR")):"?"}</p>`:""}
        <div class="betclic-sample-v0911">${sample.length?sample.map(m=>`<div><b>${esc(m.name||"Match")}</b><small>${esc(m.competition||"")}${m.date?` · ${esc(new Date(m.date).toLocaleString("fr-FR"))}`:""}</small></div>`).join(""):'<div class="empty">Aucun match lisible dans la réponse.</div>'}</div>
      </details>`:""}
      ${sync?`<div class="betclic-last-sync-v0911"><b>Dernière synchro</b><span>${Number(sync.matched||0)} apparié(s) · ${Number(sync.updated||0)} cote(s) mise(s) à jour · ${Number(sync.noMarket||0)} sans marché 1N2 · ${Number(sync.failed||0)} erreur(s)</span>${Number(sync.searchQueries||0)>0?`<small>${Number(sync.searchQueries||0)} recherche(s) ciblée(s) · ${Number(sync.searchReceived||0)} résultat(s) de recherche · ${Number(sync.matchedFromSearch||0)} rapprochement(s) via recherche</small>`:""}</div>`:""}
      <div id="betclicStatusV0911" class="form-msg"></div>
      <p class="admin-test-note-v095">⚠️ Source expérimentale et non affiliée à Betclic. Elle peut changer sans préavis. Le bouton ne remplace jamais les cotes saisies manuellement.</p>`;
    const probeBtn=$("#probeBetclicBtnV0911",root),syncBtn=$("#syncBetclicOddsBtnV0911",root);
    if(probeBtn)probeBtn.onclick=probeBetclicV0911;
    if(syncBtn)syncBtn.onclick=syncBetclicV0911;
    if(typeof applyFeatureFlagsV095==="function")applyFeatureFlagsV095();
  }

  async function probeBetclicV0911(){
    setMsg("#betclicStatusV0911","Connexion au flux Betclic…");
    try{
      if(demoMode){
        state.release0911.betclicProbe={received:2,sample:[
          {name:"Paris SG - Arsenal",competition:"Ligue des champions",date:new Date(Date.now()+86400000).toISOString()},
          {name:"Real Madrid - Bayern Munich",competition:"Ligue des champions",date:new Date(Date.now()+172800000).toISOString()}
        ]};
        renderBetclicPanelV0911(); setMsg("#betclicStatusV0911","Mode démo : réponse simulée.","ok"); return;
      }
      const {data,error}=await sb.functions.invoke("sync-betclic-odds",{body:{action:"probe",seasonSlug:state.season?.slug||"ucl-2026-27"}});
      if(error)throw new Error("La fonction sync-betclic-odds ne répond pas. Vérifie son déploiement Supabase.");
      if(!data?.ok)throw new Error(data?.error||"Flux Betclic indisponible.");
      state.release0911.betclicProbe=data;
      renderBetclicPanelV0911();
      setMsg("#betclicStatusV0911",`✓ ${Number(data.received||0)} rencontre(s) Betclic lues. Aucun changement en base.`,"ok");
    }catch(err){setMsg("#betclicStatusV0911",friendlyError(err),"error");}
  }

  async function syncBetclicV0911(){
    setMsg("#betclicStatusV0911","Recherche et rapprochement des matchs C1…");
    try{
      if(demoMode){
        state.release0911.betclicLastSync={matched:3,updated:3,noMarket:0,failed:0};
        renderBetclicPanelV0911(); setMsg("#betclicStatusV0911","Mode démo : 3 cotes simulées.","ok"); return;
      }
      const body={action:"sync",seasonSlug:state.season?.slug||"ucl-2026-27",matchdayId:state.selectedMatchdayId||null,limit:24};
      const {data,error}=await sb.functions.invoke("sync-betclic-odds",{body});
      if(error)throw new Error("La fonction sync-betclic-odds ne répond pas. Déploie-la puis consulte ses logs.");
      if(!data?.ok)throw new Error(data?.error||"Synchronisation Betclic impossible.");
      state.release0911.betclicLastSync=data;
      await loadData();
      renderAll();
      renderBetclicPanelV0911();
      if(Number(data.updated||0)>0){
        setMsg("#betclicStatusV0911",`✓ ${Number(data.updated||0)} match(s) mis à jour depuis Betclic sur ${Number(data.matched||0)} reconnu(s).`,"ok");
        toast(`💶 Betclic : ${Number(data.updated||0)} cote(s) 1N2 mise(s) à jour.`);
      }else if(Number(data.matched||0)===0){
        const range=data.discoveredFrom||data.discoveredTo
          ?` Plage Betclic explorée : ${data.discoveredFrom?new Date(data.discoveredFrom).toLocaleDateString("fr-FR"):"?"} → ${data.discoveredTo?new Date(data.discoveredTo).toLocaleDateString("fr-FR"):"?"}.`
          :"";
        setMsg("#betclicStatusV0911",`⚠️ Aucun match C1 rapproché. ${Number(data.received||0)} dans le flux général + ${Number(data.searchReceived||0)} résultat(s) via ${Number(data.searchQueries||0)} recherche(s) ciblée(s).${range} Si les dates C1 ne sont pas encore proposées par Betclic, c’est normal.`);
      }else{
        setMsg("#betclicStatusV0911",`⚠️ ${Number(data.matched||0)} match(s) C1 rapproché(s), mais aucun marché 1N2 exploitable. La saisie manuelle reste disponible.`);
      }
    }catch(err){setMsg("#betclicStatusV0911",friendlyError(err),"error");}
  }

  async function loadMessageCountsV0911(force=false){
    if(state.profile?.role!=="super_admin"||demoMode)return;
    if(state.release0911.loadingCounts||(!force&&state.release0911.messageCounts))return;
    state.release0911.loadingCounts=true;
    try{
      const {data,error}=await sb.rpc("admin_message_counts_v0911");
      if(error)throw error;
      state.release0911.messageCounts=data||{};
    }catch(err){
      console.warn("V0.9.11 message counts",err);
      state.release0911.messageCounts={error:friendlyError(err)};
    }finally{
      state.release0911.loadingCounts=false;
    }
  }

  function renderMessageCleanupV0911(){
    const root=$("#adminMessageCleanupV0911");if(!root)return;
    if(state.profile?.role!=="super_admin"){root.innerHTML='<div class="empty">Nettoyage réservé au Super Admin.</div>';return;}
    const c=state.release0911.messageCounts||{};
    root.innerHTML=`
      <div class="section-title compact">
        <div><span class="eyebrow danger">Pré-production</span><h3>Vider toute la communication de test</h3><p>Supprime les messages du Hibou, notifications, journaux Push, tickets/support, demandes d’aide mot de passe et Livre d’or. Les comptes, préférences et abonnements Push restent conservés.</p></div>
        <span class="chip">SUPER ADMIN</span>
      </div>
      <div class="message-counts-v0911">
        <span><b>${Number(c.owl_messages||0)}</b><small>Hibou</small></span>
        <span><b>${Number(c.notifications||0)}</b><small>notifications</small></span>
        <span><b>${Number(c.support_tickets||0)}</b><small>tickets</small></span>
        <span><b>${Number(c.support_messages||0)}</b><small>réponses support</small></span>
        <span><b>${Number(c.guestbook||0)}</b><small>Livre d’or</small></span>
      </div>
      ${c.error?`<div class="form-msg error">${esc(c.error)}</div>`:""}
      <div class="actions"><button id="refreshMessageCountsV0911" class="btn secondary small">↻ Recompter</button><button id="purgeMessagesV0911" class="btn danger">🗑 Supprimer tous les messages</button></div>
      <div id="messageCleanupStatusV0911" class="form-msg"></div>`;
    $("#refreshMessageCountsV0911",root).onclick=async()=>{state.release0911.messageCounts=null;await loadMessageCountsV0911(true);renderMessageCleanupV0911();};
    $("#purgeMessagesV0911",root).onclick=purgeMessagesV0911;
  }

  async function purgeMessagesV0911(){
    const confirmation=prompt("⚠ Cette action supprime toute la communication de test du site.\n\nTape exactement : SUPPRIMER TOUS LES MESSAGES");
    if(confirmation!=="SUPPRIMER TOUS LES MESSAGES")return;
    setMsg("#messageCleanupStatusV0911","Suppression en cours…");
    try{
      if(demoMode){
        localStorage.removeItem("nidc_demo_owl_messages");
        state.owlMessages=[];state.notifications=[];state.release0911.messageCounts={owl_messages:0,notifications:0,support_tickets:0,support_messages:0,guestbook:0};
        renderMessageCleanupV0911();toast("Messages de démo supprimés.");return;
      }
      const {data,error}=await sb.rpc("admin_purge_messages_v0911",{p_confirmation:"SUPPRIMER TOUS LES MESSAGES"});
      if(error)throw error;
      state.release0911.messageCounts=data||{};
      state.owlMessages=[];state.notifications=[];
      await Promise.allSettled([loadOwlData?.(),loadNotificationData?.()]);
      renderOwlHome?.();renderNotificationBell?.();renderMessageCleanupV0911();
      setMsg("#messageCleanupStatusV0911","✓ Toute la communication de test a été supprimée.","ok");
      toast("🧹 Messages et notifications de test supprimés.");
    }catch(err){setMsg("#messageCleanupStatusV0911",friendlyError(err),"error");}
  }

  async function renderRelease0911Admin(){
    if(!["admin","super_admin"].includes(state.profile?.role||""))return;
    renderBetclicPanelV0911();
    if(state.profile?.role==="super_admin"){
      await loadMessageCountsV0911(false);
      renderMessageCleanupV0911();
    }else renderMessageCleanupV0911();
  }

  window.renderBetclicPanelV0911=renderBetclicPanelV0911;
  window.probeBetclicV0911=probeBetclicV0911;
  window.syncBetclicV0911=syncBetclicV0911;
  window.renderMessageCleanupV0911=renderMessageCleanupV0911;
  window.renderRelease0911Admin=renderRelease0911Admin;
})();
