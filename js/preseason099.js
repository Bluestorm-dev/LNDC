"use strict";

// Le Nid des Champions V0.9.9 — pré-saison, répétition générale & onboarding
(function(){
  const q=(s,root=document)=>root.querySelector(s), qa=(s,root=document)=>Array.from(root.querySelectorAll(s));
  state.preseason099=state.preseason099||{runs:[],activeId:null,dashboard:null,loading:false,error:null,onboarding:null,onboardingLoaded:false};

  const tutorialSteps=[
    {icon:"🦉",title:"Bienvenue dans le Nid",body:"Tu pronostiques vite, puis le Nid fait vivre la saison autour de toi : LIVE, classements, Teams, badges et souvenirs."},
    {icon:"⚽",title:"Pronostiquer",body:"Ouvre Pronostics, saisis les deux scores et laisse l’autosauvegarde faire le reste. Au coup d’envoi, le prono se verrouille."},
    {icon:"📈",title:"Suivre le classement",body:"Général, journée, soirée, précision et exacts te permettent de suivre la course sous plusieurs angles."},
    {icon:"🔴",title:"Vivre le LIVE",body:"Quand un match passe LIVE, les scores et le classement provisoire évoluent sans rechargement manuel."},
    {icon:"🛡",title:"Rejoindre une Team",body:"Une Team ajoute une aventure collective. Le capitaine est un rôle de Team : il ne change jamais ton rôle dans l’application."},
    {icon:"🏆",title:"Choisir tes champions",body:"Tes deux choix de champion sont dans Profil. Ils restent secrets jusqu’au verrouillage de leur fenêtre."},
    {icon:"🏛",title:"Badges, records & Hibou",body:"Le Musée garde les badges, records, Casseroles et Coups de Génie. Le Hibou, lui, garde surtout les dossiers."},
    {icon:"🔔",title:"Notifications",body:"Dans Profil, choisis les notifications utiles et les heures où le Nid doit rester silencieux."},
    {icon:"🧭",title:"Saison & carrière",body:"La mémoire multi-saisons conserve tes classements, distinctions et performances dans ta carrière."},
    {icon:"✨",title:"Prêt",body:"Le tutoriel est terminé. Tu peux le relancer à tout moment depuis ton Profil."}
  ];

  async function loadOnboardingV099(force=false){
    if(demoMode||!state.user){state.preseason099.onboarding={current_step:0};state.preseason099.onboardingLoaded=true;return state.preseason099.onboarding;}
    if(state.preseason099.onboardingLoaded&&!force)return state.preseason099.onboarding;
    const {data,error}=await sb.rpc("get_my_onboarding_v099");
    if(error){console.warn("V0.9.9 onboarding",error);return null;}
    state.preseason099.onboarding=data||{};state.preseason099.onboardingLoaded=true;return data;
  }
  window.loadOnboardingV099=loadOnboardingV099;

  async function saveOnboardingV099(step,completed=false,dismissed=false){
    if(demoMode){state.preseason099.onboarding={current_step:step,completed_at:completed?new Date().toISOString():null,dismissed_at:dismissed?new Date().toISOString():null};return;}
    const {data,error}=await sb.rpc("save_my_onboarding_v099",{p_step:step,p_completed:completed,p_dismissed:dismissed});
    if(error)throw error;state.preseason099.onboarding=data||{};
  }

  function ensureOnboardingCardV099(){
    if(!state.profile)return;
    let root=q("#profileOnboardingV099");
    if(!root){
      root=document.createElement("article");root.id="profileOnboardingV099";root.className="card card-pad onboarding-card-v099";
      const privacy=q("#accountPrivacyPanelV095");privacy?.insertAdjacentElement("afterend",root);
    }
    const done=!!state.preseason099.onboarding?.completed_at;
    root.innerHTML=`<div><span class="eyebrow gold">V0.9.9 · Prise en main</span><h4>${done?'Tutoriel terminé':'Découvrir le Nid'}</h4><p>${done?'Tu peux revoir la visite guidée quand tu veux.':'Une visite en 10 écrans pour comprendre l’essentiel sans fouiller partout.'}</p></div><button id="openTutorialV099" class="btn secondary small" type="button">${done?'↻ Revoir':'▶ Commencer'}</button>`;
    q("#openTutorialV099")?.addEventListener("click",()=>openTutorialV099(0,true));
  }
  window.renderOnboardingCardV099=ensureOnboardingCardV099;

  async function maybeOfferTutorialV099(){
    if(!state.user||!state.profile)return;await loadOnboardingV099();ensureOnboardingCardV099();
    const o=state.preseason099.onboarding||{};
    if(o.completed_at||o.dismissed_at||sessionStorage.getItem("nidc-v099-tutorial-offered"))return;
    sessionStorage.setItem("nidc-v099-tutorial-offered","1");setTimeout(()=>openTutorialV099(Number(o.current_step||0),false),500);
  }
  window.maybeOfferTutorialV099=maybeOfferTutorialV099;

  function openTutorialV099(start=0,manual=false){
    q("#tutorialOverlayV099")?.remove();let step=Math.max(0,Math.min(start,tutorialSteps.length-1));
    const ov=document.createElement("div");ov.id="tutorialOverlayV099";ov.className="tutorial-overlay-v099";ov.setAttribute("role","dialog");ov.setAttribute("aria-modal","true");
    const draw=()=>{const x=tutorialSteps[step];ov.innerHTML=`<div class="tutorial-modal-v099"><div class="tutorial-progress-v099"><span style="width:${((step+1)/tutorialSteps.length)*100}%"></span></div><div class="tutorial-icon-v099">${x.icon}</div><span class="eyebrow gold">Étape ${step+1}/${tutorialSteps.length}</span><h2>${x.title}</h2><p>${x.body}</p><div class="tutorial-actions-v099"><button id="tutorialLaterV099" class="btn secondary small" type="button">${manual?'Fermer':'Plus tard'}</button><span></span>${step>0?'<button id="tutorialPrevV099" class="btn secondary small" type="button">← Retour</button>':''}<button id="tutorialNextV099" class="btn gold small" type="button">${step===tutorialSteps.length-1?'Terminer':'Suivant →'}</button></div></div>`;
      q("#tutorialPrevV099",ov)?.addEventListener("click",()=>{step--;draw();});
      q("#tutorialLaterV099",ov)?.addEventListener("click",async()=>{if(!manual)try{await saveOnboardingV099(step,false,true);}catch(_){}ov.remove();ensureOnboardingCardV099();});
      q("#tutorialNextV099",ov)?.addEventListener("click",async()=>{if(step===tutorialSteps.length-1){try{await saveOnboardingV099(step,true,false);}catch(err){toast(friendlyError(err),"error");}ov.remove();ensureOnboardingCardV099();toast("🦉 Tutoriel terminé.");return;}step++;try{await saveOnboardingV099(step,false,false);}catch(_){}draw();});
    };draw();document.body.appendChild(ov);
  }
  window.openTutorialV099=openTutorialV099;

  async function loadPreseasonV099(force=false){
    if(state.profile?.role!=="super_admin")return;
    const s=state.preseason099;if(s.loading)return;if(s.runs.length&&!force){renderAdminPreseasonV099();return;}s.loading=true;s.error=null;
    try{
      if(demoMode){s.runs=[];s.dashboard=null;return;}
      const {data,error}=await sb.from("preseason_runs_v099").select("id,season_id,label,status,config,stats,created_at,started_at,completed_at").order("created_at",{ascending:false}).limit(20);if(error)throw error;
      s.runs=data||[];if(!s.activeId&&s.runs[0])s.activeId=s.runs[0].id;if(s.activeId&&!s.runs.some(r=>r.id===s.activeId))s.activeId=s.runs[0]?.id||null;
      if(s.activeId){const d=await sb.rpc("get_preseason_dashboard_v099",{p_run_id:s.activeId});if(d.error)throw d.error;s.dashboard=d.data||null;}else s.dashboard=null;
    }catch(err){s.error=friendlyError(err);console.warn("V0.9.9 preseason",err);}finally{s.loading=false;renderAdminPreseasonV099();}
  }
  window.loadPreseasonV099=loadPreseasonV099;

  const stepDefs=[
    ["live","🔴","Passer 3 matchs LIVE"],["scores","⚽","Terminer la phase de ligue"],["champion","🏆","Résoudre le champion"],["teams","🛡","Contrôler les Teams"],
    ["badges","🏅","Générer badges & casseroles"],["notifications","🔔","Tester une notification interne"],["finale","🥇","Jouer la finale TEST"],["pdf","📘","Marquer le contrôle PDF"],["complete","✅","Terminer la répétition"]
  ];

  function renderAdminPreseasonV099(){
    const root=q("#adminPreseasonPanelV099");if(!root||state.profile?.role!=="super_admin")return;const s=state.preseason099;
    if(s.loading){root.innerHTML='<div class="empty">Préparation du laboratoire pré-saison…</div>';return;}
    const d=s.dashboard,run=d?.run,counts=d?.counts||{},steps=new Set(d?.steps||[]),load=run?.stats?.load_test;
    root.innerHTML=`<div class="section-title compact"><div><span class="eyebrow gold">V0.9.9 · Répétition générale</span><h3>Pré-saison sans risque pour les vraies données</h3><p>Le bac à sable crée ses propres joueurs, Teams, matchs et pronostics virtuels. Aucun compte réel ni match officiel n’est modifié.</p></div><span class="chip">SUPER ADMIN</span></div>
      ${s.error?`<div class="form-msg error">${esc(s.error)} · Exécute HOTFIX_V0.9.9_EXISTING_DB.sql si nécessaire.</div>`:""}
      <div class="preseason-create-v099"><input id="preseasonLabelV099" placeholder="Nom de la répétition" value="Répétition générale V1"><label>Joueurs<input id="preseasonPlayersV099" type="number" min="4" max="250" value="48"></label><label>Matchs<input id="preseasonMatchesV099" type="number" min="8" max="80" value="24"></label><label>Teams<input id="preseasonTeamsV099" type="number" min="2" max="32" value="8"></label><button id="preseasonCreateV099" class="btn gold small" type="button">＋ Nouveau scénario</button></div>
      <div class="preseason-layout-v099"><aside class="preseason-runs-v099">${s.runs.length?s.runs.map(r=>`<button type="button" class="${r.id===s.activeId?'active':''}" data-preseason-run-v099="${r.id}"><b>${esc(r.label)}</b><small>${esc(r.status)} · ${esc(fmtShortDate(r.created_at))}</small></button>`).join(""):'<div class="empty">Aucune répétition créée.</div>'}</aside>
      <div class="preseason-main-v099">${run?`<div class="preseason-kpis-v099"><span><b>${Number(counts.players||0)}</b><small>joueurs virtuels</small></span><span><b>${Number(counts.teams||0)}</b><small>Teams</small></span><span><b>${Number(counts.matches||0)}</b><small>matchs</small></span><span><b>${Number(counts.predictions||0)}</b><small>pronostics</small></span><span><b>${Number(counts.live||0)}</b><small>LIVE</small></span><span><b>${Number(counts.finished||0)}</b><small>terminés</small></span></div>
        <div class="preseason-steps-v099">${stepDefs.map(x=>`<button type="button" data-preseason-step-v099="${x[0]}" class="${steps.has(x[0])?'done':''}" ${run.status==='completed'&&x[0]!=='complete'?'disabled':''}><span>${x[1]}</span><b>${x[2]}</b><small>${steps.has(x[0])?'✓ exécuté':'à lancer'}</small></button>`).join("")}</div>
        <div class="preseason-load-v099"><div><strong>Test de charge isolé</strong><p>Écrit jusqu’à 100 000 lignes dans la table TEST, mesure le temps puis permet le nettoyage complet.</p></div><input id="preseasonLoadRowsV099" type="number" min="100" max="100000" step="1000" value="20000"><button id="preseasonLoadV099" class="btn secondary small" type="button">⚡ Lancer</button><span>${load?`${Number(load.rows||0).toLocaleString('fr-FR')} lignes · ${load.duration_ms} ms`:'—'}</span></div>
        <div class="preseason-points-v099"><strong>Barème simulé</strong><span>0 pt <b>${Number(d?.points?.zero||0)}</b></span><span>3 pts <b>${Number(d?.points?.three||0)}</b></span><span>5 pts <b>${Number(d?.points?.five||0)}</b></span><span>7 pts <b>${Number(d?.points?.seven||0)}</b></span></div>
        <div class="preseason-links-v099"><a class="btn secondary small" href="tests/road-check-v0.9.9.html" target="_blank" rel="noopener">🧭 Grand road-check V1</a><a class="btn secondary small" href="tests/test-center-v0.9.9.html" target="_blank" rel="noopener">🧪 Centre de tests 0.9.9</a><a class="btn secondary small" href="finale.html?mode=season&season=${encodeURIComponent(state.season?.slug||'')}" target="_blank" rel="noopener">📘 Smoke test PDF</a></div>
        <details class="preseason-events-v099"><summary>Journal de la répétition (${Number(counts.events||0)})</summary>${(d.recent_events||[]).map(e=>`<div><span>${esc(e.step)}</span><b>${esc(e.event_type)}</b><small>${esc(e.detail||'')}</small></div>`).join('')||'<div class="empty">Aucun événement.</div>'}</details>
        <div class="preseason-danger-v099"><div><strong>Nettoyage</strong><p>Supprime uniquement ce scénario et toutes ses données virtuelles.</p></div><button id="preseasonCleanupV099" class="btn danger small" type="button">🧹 Nettoyer ce scénario</button></div>`:'<div class="empty">Crée un scénario pour démarrer la répétition générale.</div>'}</div></div><div id="preseasonMsgV099" class="form-msg"></div>`;
    bindPreseasonV099(root);
  }
  window.renderAdminPreseasonV099=renderAdminPreseasonV099;

  function bindPreseasonV099(root){
    q("#preseasonCreateV099",root)?.addEventListener("click",createRunV099);
    qa("[data-preseason-run-v099]").forEach(b=>b.onclick=async()=>{state.preseason099.activeId=b.dataset.preseasonRunV099;state.preseason099.runs=[];await loadPreseasonV099(true);});
    qa("[data-preseason-step-v099]").forEach(b=>b.onclick=()=>runStepV099(b.dataset.preseasonStepV099));
    q("#preseasonLoadV099",root)?.addEventListener("click",runLoadV099);q("#preseasonCleanupV099",root)?.addEventListener("click",cleanupV099);
  }

  async function createRunV099(){
    setMsg("#preseasonMsgV099","Création du scénario…");try{const {data,error}=await sb.rpc("admin_create_preseason_run_v099",{p_season_id:state.season.id,p_label:q("#preseasonLabelV099")?.value||null,p_players:Number(q("#preseasonPlayersV099")?.value||48),p_matches:Number(q("#preseasonMatchesV099")?.value||24),p_teams:Number(q("#preseasonTeamsV099")?.value||8)});if(error)throw error;state.preseason099.activeId=data;state.preseason099.runs=[];await loadPreseasonV099(true);setMsg("#preseasonMsgV099","Scénario créé dans le bac à sable.","ok");toast("🧪 Répétition créée.");}catch(err){setMsg("#preseasonMsgV099",friendlyError(err),"error");}}
  async function runStepV099(step){setMsg("#preseasonMsgV099",`Étape ${step}…`);try{const {data,error}=await sb.rpc("admin_preseason_step_v099",{p_run_id:state.preseason099.activeId,p_step:step});if(error)throw error;state.preseason099.dashboard=data;await loadPreseasonV099(true);setMsg("#preseasonMsgV099",`Étape ${step} terminée.`,"ok");}catch(err){setMsg("#preseasonMsgV099",friendlyError(err),"error");}}
  async function runLoadV099(){setMsg("#preseasonMsgV099","Test de charge…");try{const {data,error}=await sb.rpc("admin_preseason_load_test_v099",{p_run_id:state.preseason099.activeId,p_rows:Number(q("#preseasonLoadRowsV099")?.value||20000)});if(error)throw error;await loadPreseasonV099(true);setMsg("#preseasonMsgV099",`${Number(data?.rows||0).toLocaleString('fr-FR')} lignes écrites en ${data?.duration_ms} ms.`,"ok");}catch(err){setMsg("#preseasonMsgV099",friendlyError(err),"error");}}
  async function cleanupV099(){const c=prompt("Supprimer uniquement ce scénario TEST ? Tape NETTOYER pour confirmer.","");if(c!=="NETTOYER")return;try{const {error}=await sb.rpc("admin_cleanup_preseason_v099",{p_run_id:state.preseason099.activeId,p_confirmation:"NETTOYER"});if(error)throw error;state.preseason099.activeId=null;state.preseason099.runs=[];state.preseason099.dashboard=null;await loadPreseasonV099(true);toast("🧹 Scénario TEST supprimé.");}catch(err){toast(friendlyError(err),"error");}}

  window.addEventListener("load",()=>setTimeout(()=>maybeOfferTutorialV099().catch(()=>{}),800));
})();
