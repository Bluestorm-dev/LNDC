"use strict";

// Le Nid des Champions V0.9.8 — cockpit Admin + accès fin de saison
(function(){
  const defaults={
    registration_open:true,maintenance:false,feature_rivals:true,feature_polls:true,feature_api:true,
    feature_solitary_owl:true,feature_gamification:true,feature_teams:true
  };
  state.appSettings=state.appSettings||{...defaults};
  state.admin095=state.admin095||{loaded:false,loading:false,dashboard:null,backups:[],audit:[],auditTotal:0,auditPage:0,deletions:[],preview:null};

  const commands=[
    ["Saisir un score LIVE","match score résultat live","matches","#adminMatches","⚽"],
    ["Créer une journée","journée calendrier matchday","matches",".admin-builder","＋"],
    ["Ajouter un match","rencontre coup envoi stade","matches",".admin-builder","⚽"],
    ["Synchroniser le calendrier C1","api football data calendrier champions","competition","#syncCalendarBtn","↻"],
    ["Synchroniser le Centre C1","classement résultats champions league","competition","#syncUclCenterBtn","⭐"],
    ["Synchroniser les clubs","logos clubs bibliothèque","competition","#syncClubsBtn","🛡"],
    ["Synchroniser les cotes","odds 1n2 api","competition","#syncOddsBtn","📊"],
    ["Phases finales","tirage barrage huitième quart demi finale","competition",".knockout-admin-card","🏆"],
    ["Trouver un joueur","compte pseudo rôle profil","players","#adminPlayerSearch","♟"],
    ["Demandes d'inscription","nouveau compte accepter refuser","players","#registrationAdminSection","🚪"],
    ["Modérer les avatars","photo valider refuser image","players","#avatarModerationPanel","🖼"],
    ["Vainqueur Coupe du monde 2026","distinction champion nid pronos","players","#adminDistinctionPanel","🌍"],
    ["Aperçu comme un joueur","impersonation vue joueur debug","players","#adminImpersonationPanelV095","👁"],
    ["Demandes de suppression","compte rgpd anonymisation","players","#adminDeletionPanelV095","🗑"],
    ["Gérer les Teams","équipe capitaine communauté","teams","#adminTeamsPanel","🛡"],
    ["Badges & Musée","gamification badge casserole génie record","gamification","#adminGamificationPanel","🏛"],
    ["Sondages","vote sondage général mensuel","gamification","#adminGeneralPollPanel","🗳"],
    ["Envoyer un message du Hibou","message communication hibou","communication","#adminOwlPanel","🦉"],
    ["Tickets joueurs","support bug question demande","communication","#adminSupportPanel","🎫"],
    ["Notifications Push","push appareil cron notification","communication","#adminNotificationsPanel","🔔"],
    ["Gérer les saisons","saison active archive création","application","#adminSeasonManagementPanel","◇"],
    ["Fin de saison & PDF","collector diplôme livre or export archive clôture","application","#adminFinalSeasonPanelV098","📘"],
    ["Maintenance","maintenance fermer application","application","#adminSettingsPanelV095","🛠"],
    ["Ouvrir / fermer les inscriptions","registration compte","application","#adminSettingsPanelV095","🚪"],
    ["Feature flags","fonction activer désactiver rival sondage api","application","#adminSettingsPanelV095","🚩"],
    ["Créer une sauvegarde","backup snapshot restaurer","application","#adminBackupPanelV095","💾"],
    ["Exporter les données","json csv export saison joueurs audit","application","#adminExportPanelV095","⇩"],
    ["Journal d'audit","logs historique modification sécurité","application","#adminAuditPanelV095","📜"],
    ["Nettoyer le cache PWA","service worker cache actualiser","application","#adminRefreshPwaBtn","↻"],
    ["Tests techniques","diagnostic test cron calendrier","test","#adminTestPanelSection","🧪"],
    ["Centres de tests","tests page validation 0.8.1 0.9.0 0.9.5 0.9.8 road check matrice","test","#adminTestCentersV095","✅"]
  ].map((x,i)=>({id:`cmd-${i+1}`,label:x[0],keywords:x[1],section:x[2],selector:x[3],icon:x[4]}));

  function boolSetting(key,fallback=true){const v=state.appSettings?.[key];return typeof v==="boolean"?v:(v==null?fallback:Boolean(v));}
  window.featureEnabledV095=(key,fallback=true)=>boolSetting(key,fallback);

  async function loadPublicAppSettingsV095(){
    if(demoMode){state.appSettings={...defaults};return state.appSettings;}
    const {data,error}=await sb.from("app_settings").select("key,value").in("key",Object.keys(defaults).concat(["app_version"]));
    if(error){console.warn("V0.9.5 app_settings",error);state.appSettings={...defaults,...state.appSettings};return state.appSettings;}
    const map={...defaults};(data||[]).forEach(r=>map[r.key]=r.value);state.appSettings=map;return map;
  }
  window.loadPublicAppSettingsV095=loadPublicAppSettingsV095;

  async function registrationOpenV095(){
    if(demoMode)return true;
    try{const {data,error}=await sb.from("app_settings").select("value").eq("key","registration_open").maybeSingle();return error?true:(data?.value!==false);}catch(_){return true;}
  }
  window.registrationOpenV095=registrationOpenV095;

  function applyFeatureFlagsV095(){
    const teams=boolSetting("feature_teams"),gamification=boolSetting("feature_gamification"),rivals=boolSetting("feature_rivals"),polls=boolSetting("feature_polls"),solitary=boolSetting("feature_solitary_owl");
    $$('[data-view="teams"]').forEach(x=>x.classList.toggle("feature-hidden-v095",!teams));
    $$('[data-view="museum"]').forEach(x=>x.classList.toggle("feature-hidden-v095",!gamification));
    const museumView=$("#view-museum");if(museumView)museumView.dataset.featureEnabled=String(gamification);
    const teamsView=$("#view-teams");if(teamsView)teamsView.dataset.featureEnabled=String(teams);
    const rivalHome=$("#homeRivalCard");if(rivalHome&&!rivals)rivalHome.classList.add("feature-hidden-v095");
    const rivalView=$("#view-rival");if(rivalView)rivalView.dataset.featureEnabled=String(rivals);
    const pollTab=$('[data-memory-tab="polls"]');if(pollTab)pollTab.classList.toggle("feature-hidden-v095",!polls);
    if(!polls&&state.seasonMemoryTab==="polls"){state.seasonMemoryTab="overview";if(typeof renderSeasonMemory==="function")renderSeasonMemory();}
    const solitaryTab=$('[data-evening-tab="solitary"]');if(solitaryTab)solitaryTab.classList.toggle("feature-hidden-v095",!solitary);
    if(!solitary&&state.eveningTab==="solitary"){state.eveningTab="summary";if(typeof renderEveningHub==="function")renderEveningHub();}
    const api=boolSetting("feature_api");["#syncClubsBtn","#syncClubCatalogBtn","#syncCalendarBtn","#syncUclCenterBtn","#syncOddsBtn"].forEach(sel=>{const el=$(sel);if(el){el.disabled=!api;el.title=api?"":"API désactivée dans les Feature flags";}});
    const pollAdmin=$("#adminGeneralPollPanel");if(pollAdmin)pollAdmin.classList.toggle("feature-hidden-v095",!polls);
    const gamiNav=$("#adminGamificationNav");if(gamiNav&&state.profile?.role==="super_admin")gamiNav.classList.toggle("feature-soft-disabled-v095",!gamification);
  }
  window.applyFeatureFlagsV095=applyFeatureFlagsV095;

  function ensureNetworkBanner(){
    let b=$("#networkBannerV095");if(b)return b;
    b=document.createElement("div");b.id="networkBannerV095";b.className="network-banner-v095 hidden";b.setAttribute("role","status");b.setAttribute("aria-live","polite");
    const app=$("#appScreen");if(app)app.prepend(b);return b;
  }
  function updateNetworkStateV095(){const b=ensureNetworkBanner();if(!b)return;const offline=!navigator.onLine;b.classList.toggle("hidden",!offline);b.innerHTML=offline?"📡 <b>Connexion perdue.</b> Le Nid reste affiché, mais aucune modification ne sera envoyée tant que le réseau n’est pas revenu.":"";}
  window.addEventListener("online",()=>{updateNetworkStateV095();toast("📡 Connexion rétablie.");});
  window.addEventListener("offline",updateNetworkStateV095);
  window.addEventListener("unhandledrejection",e=>{if(state.profile&&isAdminProfile())console.warn("[V0.9.5] Rejet non géré",e.reason);});

  function enforceMaintenanceV095(){
    const maintenance=boolSetting("maintenance",false);const superAdmin=state.profile?.role==="super_admin";
    $("#maintenanceOverlayV095")?.remove();
    if(!maintenance)return true;
    if(superAdmin){document.body.classList.add("maintenance-bypass-v095");return true;}
    const ov=document.createElement("div");ov.id="maintenanceOverlayV095";ov.className="maintenance-overlay-v095";ov.innerHTML=`<div class="card card-pad"><span class="eyebrow gold">Maintenance</span><h2>Le Hibou travaille dans le Nid 🛠️</h2><p>Une maintenance est en cours. Tes données sont conservées ; reviens dans quelques minutes.</p><button id="maintenanceLogoutV095" class="btn secondary">Déconnexion</button></div>`;document.body.appendChild(ov);$("#maintenanceLogoutV095",ov).onclick=logout;return false;
  }
  window.enforceMaintenanceV095=enforceMaintenanceV095;

  async function loadAdmin095Data(force=false){
    if(!isAdminProfile())return;
    const s=state.admin095;if(s.loading||(!force&&s.loaded))return;s.loading=true;
    try{
      await loadPublicAppSettingsV095();
      if(demoMode){s.dashboard={players_active:state.demoUsers.length,players_pending:0,matches:(state.allMatches||[]).length,matches_live:(state.allMatches||[]).filter(m=>m.status==="live").length,teams:(state.teamDirectory||[]).length,tickets_open:0,avatars_pending:0,push_failed_24h:0,deletion_requests:0,audit_24h:0};s.backups=[];s.audit=[];s.auditTotal=0;s.deletions=[];s.loaded=true;return;}
      const requests=[sb.rpc("admin_dashboard_v095",{p_season_id:state.season?.id||null})];
      if(state.profile?.role==="super_admin"){
        requests.push(sb.from("admin_backups_v095").select("id,label,season_id,scope,stats,created_at,created_by").order("created_at",{ascending:false}).limit(30));
        requests.push(sb.from("account_deletion_requests_v095").select("id,user_id,reason,status,requested_at,reviewed_at,admin_note").in("status",["requested","reviewing"]).order("requested_at",{ascending:false}).limit(50));
      }
      const out=await Promise.all(requests);if(out[0].error)throw out[0].error;s.dashboard=out[0].data||{};
      if(state.profile?.role==="super_admin"){s.backups=out[1].error?[]:(out[1].data||[]);s.deletions=out[2].error?[]:(out[2].data||[]);}else{s.backups=[];s.deletions=[];}
      await loadAuditPageV095(0,false);s.loaded=true;
    }catch(err){console.warn("V0.9.5 admin data",err);s.error=friendlyError(err);}finally{s.loading=false;}
  }
  window.loadAdmin095Data=loadAdmin095Data;

  async function loadAuditPageV095(page=0,render=true){
    if(!isAdminProfile()||demoMode){state.admin095.audit=[];state.admin095.auditTotal=0;return;}
    const q=$("#adminAuditSearchV095")?.value.trim()||null;const action=$("#adminAuditActionV095")?.value||null;const limit=25;
    const {data,error}=await sb.rpc("admin_audit_v095",{p_limit:limit,p_offset:page*limit,p_action:action||null,p_entity_type:null,p_search:q});
    if(error){state.admin095.audit=[];state.admin095.auditTotal=0;state.admin095.auditError=friendlyError(error);}else{state.admin095.audit=data||[];state.admin095.auditTotal=Number(data?.[0]?.total_count||0);state.admin095.auditPage=page;state.admin095.auditError=null;}
    if(render)renderAdminAuditV095();
  }
  window.loadAuditPageV095=loadAuditPageV095;

  function renderAdmin095(){
    if(!isAdminProfile())return;applyFeatureFlagsV095();updateNetworkStateV095();renderAdminCommandSearchV095();renderAdminHealthV095();renderAdminQuickActionsV095();renderAdminSettingsV095();renderAdminBackupsV095();renderAdminExportsV095();renderAdminAuditV095();renderAdminImpersonationV095();renderAdminDeletionV095();
  }
  window.renderAdmin095=renderAdmin095;

  function renderAdminCommandSearchV095(){
    const input=$("#adminGlobalSearchV095"),results=$("#adminSearchResultsV095");if(!input||!results)return;
    if(input.dataset.bound)return;input.dataset.bound="1";
    const draw=()=>{const q=input.value.trim().toLocaleLowerCase("fr");if(!q){results.classList.add("hidden");results.innerHTML="";return;}const rows=commands.filter(c=>`${c.label} ${c.keywords}`.toLocaleLowerCase("fr").includes(q)).slice(0,9);results.innerHTML=rows.length?rows.map(c=>`<button type="button" data-admin-command="${c.id}"><span>${c.icon}</span><span><strong>${esc(c.label)}</strong><small>${esc(c.section==="application"?"Système & sécurité":c.section)}</small></span><i>↵</i></button>`).join(""):`<div class="admin-search-empty">Aucune option trouvée. Essaie « sauvegarde », « joueur », « C1 »…</div>`;results.classList.remove("hidden");$$('[data-admin-command]',results).forEach(b=>b.onclick=()=>runAdminCommandV095(b.dataset.adminCommand));};
    input.addEventListener("input",draw);input.addEventListener("keydown",e=>{if(e.key==="Escape"){input.value="";draw();input.blur();}if(e.key==="Enter"){const first=$('[data-admin-command]',results);if(first){e.preventDefault();runAdminCommandV095(first.dataset.adminCommand);}}});
    document.addEventListener("keydown",e=>{if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==="k"&&$("#view-admin")&&!$("#view-admin").classList.contains("hidden")){e.preventDefault();input.focus();input.select();}});
    document.addEventListener("click",e=>{if(!e.target.closest(".admin-search-v095"))results.classList.add("hidden");});
  }

  function runAdminCommandV095(id){const c=commands.find(x=>x.id===id);if(!c)return;if(c.section==="test"&&state.profile?.role!=="super_admin")return toast("Réservé au Super Admin.","error");setAdminSection(c.section,{scroll:false});const input=$("#adminGlobalSearchV095");if(input)input.value="";$("#adminSearchResultsV095")?.classList.add("hidden");setTimeout(()=>{const target=$(c.selector);if(target){target.scrollIntoView({behavior:"smooth",block:"center"});target.classList.add("admin-find-flash-v095");setTimeout(()=>target.classList.remove("admin-find-flash-v095"),1400);if(target.matches("input,select,textarea,button"))target.focus({preventScroll:true});}},80);}
  window.runAdminCommandV095=runAdminCommandV095;

  function renderAdminHealthV095(){
    const root=$("#adminHealthV095");if(!root)return;const d=state.admin095.dashboard||{};const maintenance=boolSetting("maintenance",false),api=boolSetting("feature_api",true),online=navigator.onLine;
    const issues=[];if(Number(d.players_pending||0))issues.push({icon:"🚪",n:d.players_pending,label:"inscription(s) à traiter",cmd:"cmd-10"});if(Number(d.avatars_pending||0))issues.push({icon:"🖼",n:d.avatars_pending,label:"avatar(s) à modérer",cmd:"cmd-11"});if(Number(d.tickets_open||0))issues.push({icon:"🎫",n:d.tickets_open,label:"ticket(s) ouvert(s)",cmd:"cmd-19"});if(Number(d.push_failed_24h||0))issues.push({icon:"⚠",n:d.push_failed_24h,label:"push en échec sur 24 h",cmd:"cmd-20"});if(Number(d.deletion_requests||0))issues.push({icon:"🗑",n:d.deletion_requests,label:"suppression(s) demandée(s)",cmd:"cmd-14"});
    root.innerHTML=`<div class="admin-health-strip-v095"><span class="${online?'ok':'bad'}"><i></i>${online?'Réseau OK':'Hors ligne'}</span><span class="${maintenance?'warn':'ok'}"><i></i>${maintenance?'Maintenance active':'Application ouverte'}</span><span class="${api?'ok':'warn'}"><i></i>${api?'API autorisée':'API désactivée'}</span><span><i></i>${esc(state.season?.name||'Saison')}</span></div><div class="admin-action-center-v095"><div class="section-title compact"><div><span class="eyebrow gold">À traiter</span><h3>${issues.length?`${issues.length} point${issues.length>1?'s':''} à surveiller`:'Rien d’urgent'}</h3><p>${issues.length?'Le Nid te remonte uniquement ce qui réclame une action.':'Pas besoin de fouiller tous les menus : tout est calme.'}</p></div><span class="chip">V0.9.5</span></div><div class="admin-action-list-v095">${issues.length?issues.map(x=>`<button type="button" data-admin-health-command="${x.cmd}"><span>${x.icon}</span><b>${Number(x.n||0)}</b><em>${esc(x.label)}</em><i>›</i></button>`).join(''):'<div class="admin-all-clear-v095">✓ Aucun signal critique dans les données chargées.</div>'}</div></div>`;
    $$('[data-admin-health-command]',root).forEach(b=>b.onclick=()=>runAdminCommandV095(b.dataset.adminHealthCommand));
  }

  function renderAdminQuickActionsV095(){const root=$("#adminQuickActionsV095");if(!root)return;const items=[["⚽","Saisir un score","cmd-1"],["⭐","Synchroniser C1","cmd-5"],["♟","Trouver un joueur","cmd-9"],["🦉","Message du Hibou","cmd-18"],["💾","Sauvegarder","cmd-25"],["⚙","Réglages","cmd-23"]];root.innerHTML=`<div class="admin-quick-grid-v095">${items.map(x=>`<button type="button" data-admin-quick-command="${x[2]}"><span>${x[0]}</span><b>${esc(x[1])}</b></button>`).join('')}</div>`;$$('[data-admin-quick-command]',root).forEach(b=>b.onclick=()=>runAdminCommandV095(b.dataset.adminQuickCommand));}

  function settingRow(key,title,desc,superOnly=true){const checked=boolSetting(key,defaults[key]);const disabled=superOnly&&state.profile?.role!=="super_admin";return `<label class="admin-setting-row-v095"><span><strong>${esc(title)}</strong><small>${esc(desc)}</small></span><input type="checkbox" data-admin-setting-v095="${esc(key)}" ${checked?'checked':''} ${disabled?'disabled':''}></label>`;}
  function renderAdminSettingsV095(){
    const root=$("#adminSettingsPanelV095");if(!root)return;
    root.innerHTML=`<div class="section-title compact"><div><span class="eyebrow gold">Réglages globaux</span><h3>Ouverture & fonctionnalités</h3><p>Les réglages les plus sensibles sont réunis ici et chaque changement est journalisé.</p></div><span class="chip">SUPER ADMIN</span></div><div class="admin-settings-grid-v095"><section><h4>Accès</h4>${settingRow("maintenance","Mode maintenance","Bloque temporairement l’application pour les joueurs. Le Super Admin garde l’accès.")}${settingRow("registration_open","Inscriptions ouvertes","Autorise la création de nouvelles demandes de compte.")}</section><section><h4>Feature flags</h4>${settingRow("feature_api","Synchronisations API","Autorise les boutons Football-Data et cotes.")}${settingRow("feature_teams","Teams","Affiche les espaces Teams aux joueurs.")}${settingRow("feature_gamification","Musée & gamification","Affiche Musée, badges et gamification.")}${settingRow("feature_polls","Sondages","Affiche et autorise les sondages généraux.")}${settingRow("feature_rivals","Rivalités","Active les zones de rivalité.")}${settingRow("feature_solitary_owl","Hibou solitaire","Active le classement parallèle des soirées.")}</section></div><div id="adminSettingsMsgV095" class="form-msg"></div>`;
    $$('[data-admin-setting-v095]',root).forEach(input=>input.onchange=()=>saveSettingV095(input.dataset.adminSettingV095,input.checked,input));
  }
  async function saveSettingV095(key,value,input){if(state.profile?.role!=="super_admin")return;const risky=key==="maintenance"&&value;if(risky&&!confirm("Activer le mode maintenance ? Les joueurs seront bloqués jusqu’à sa désactivation.")){input.checked=false;return;}setMsg("#adminSettingsMsgV095","Enregistrement…");try{if(demoMode){state.appSettings[key]=value;}else{const {error}=await sb.rpc("admin_set_app_setting_v095",{p_key:key,p_value:value,p_reason:"Modification depuis le cockpit V0.9.5"});if(error)throw error;state.appSettings[key]=value;}applyFeatureFlagsV095();renderAdminHealthV095();setMsg("#adminSettingsMsgV095","Réglage enregistré.","ok");toast("Réglage mis à jour.");}catch(err){input.checked=!value;setMsg("#adminSettingsMsgV095",friendlyError(err),"error");}}

  function renderAdminBackupsV095(){
    const root=$("#adminBackupPanelV095");if(!root)return;if(state.profile?.role!=="super_admin"){root.innerHTML='<div class="empty">Sauvegardes réservées au Super Admin.</div>';return;}
    const rows=state.admin095.backups||[];root.innerHTML=`<div class="section-title compact"><div><span class="eyebrow gold">Sauvegardes</span><h3>Points de restauration</h3><p>Une copie logique de la saison est conservée dans Supabase et peut aussi être téléchargée en JSON.</p></div><button id="createBackupV095" class="btn gold small" type="button">💾 Nouvelle sauvegarde</button></div><div class="admin-backup-list-v095">${rows.length?rows.map(b=>`<div class="admin-backup-row-v095"><div><strong>${esc(b.label)}</strong><small>${esc(fmtDate(b.created_at))} · ${Number(b.stats?.matches||0)} matchs · ${Number(b.stats?.predictions||0)} pronos · ${Number(b.stats?.teams||0)} Teams</small></div><div class="actions"><button class="btn secondary small" data-backup-download-v095="${b.id}">JSON</button><button class="btn secondary small" data-backup-restore-v095="${b.id}">Restaurer</button><button class="btn danger small" data-backup-delete-v095="${b.id}">Supprimer</button></div></div>`).join(''):'<div class="empty">Aucune sauvegarde. Crée un point avant une opération importante.</div>'}</div><div id="adminBackupMsgV095" class="form-msg"></div>`;
    $("#createBackupV095",root).onclick=createBackupV095;$$('[data-backup-download-v095]',root).forEach(b=>b.onclick=()=>downloadBackupV095(b.dataset.backupDownloadV095));$$('[data-backup-delete-v095]',root).forEach(b=>b.onclick=()=>deleteBackupV095(b.dataset.backupDeleteV095));$$('[data-backup-restore-v095]',root).forEach(b=>b.onclick=()=>restoreBackupV095(b.dataset.backupRestoreV095));
  }
  async function createBackupV095(){const label=prompt("Nom de la sauvegarde",`Avant modification · ${new Date().toLocaleDateString('fr-FR')}`);if(label===null)return;setMsg("#adminBackupMsgV095","Création de la sauvegarde…");try{if(demoMode)return setMsg("#adminBackupMsgV095","Mode démo : sauvegarde serveur non créée.");const {error}=await sb.rpc("admin_create_backup_v095",{p_label:label,p_season_id:state.season.id});if(error)throw error;state.admin095.loaded=false;await loadAdmin095Data(true);renderAdmin095();setMsg("#adminBackupMsgV095","Sauvegarde créée.","ok");toast("💾 Sauvegarde créée.");}catch(err){setMsg("#adminBackupMsgV095",friendlyError(err),"error");}}
  async function fetchBackupPayloadV095(id){const {data,error}=await sb.from("admin_backups_v095").select("id,label,season_id,scope,payload,stats,created_at").eq("id",id).single();if(error)throw error;return data;}
  async function downloadBackupV095(id){try{const b=await fetchBackupPayloadV095(id);downloadTextV095(`nid-backup-${safeFileV095(b.label)}-${new Date(b.created_at).toISOString().slice(0,10)}.json`,JSON.stringify({id:b.id,label:b.label,season_id:b.season_id,scope:b.scope,stats:b.stats,created_at:b.created_at,payload:b.payload},null,2),"application/json");toast("Sauvegarde JSON téléchargée.");}catch(err){toast(friendlyError(err),"error");}}
  async function deleteBackupV095(id){if(!confirm("Supprimer définitivement ce point de sauvegarde ?"))return;try{const {error}=await sb.rpc("admin_delete_backup_v095",{p_backup_id:id});if(error)throw error;await loadAdmin095Data(true);renderAdmin095();toast("Sauvegarde supprimée.");}catch(err){toast(friendlyError(err),"error");}}
  async function restoreBackupV095(id){const b=(state.admin095.backups||[]).find(x=>String(x.id)===String(id));if(!b)return;if(!boolSetting("maintenance",false))return toast("Active d’abord le mode maintenance avant une restauration.","error");const confirmWord=prompt(`⚠ Restaurer « ${b.label} » ?\n\nLes données actuelles de cette saison seront remplacées. Tape RESTAURER pour confirmer.`);if(confirmWord!=="RESTAURER")return;setMsg("#adminBackupMsgV095","Restauration en cours… ne ferme pas la page.");try{const {data,error}=await sb.rpc("admin_restore_backup_v095",{p_backup_id:id,p_confirmation:"RESTAURER"});if(error)throw error;await loadData();await loadAdmin095Data(true);renderAll();setAdminSection("application",{scroll:false});setMsg("#adminBackupMsgV095",`Restauration terminée · ${Number(data?.stats?.matches||0)} matchs restaurés.`,"ok");toast("✓ Sauvegarde restaurée.");}catch(err){setMsg("#adminBackupMsgV095",friendlyError(err),"error");}}

  function renderAdminExportsV095(){const root=$("#adminExportPanelV095");if(!root)return;root.innerHTML=`<div class="section-title compact"><div><span class="eyebrow">Exports</span><h3>Sortir les données sans les abîmer</h3><p>Exports locaux en CSV/JSON pour contrôle ou archivage.</p></div></div><div class="admin-export-grid-v095"><button id="exportPlayersV095" class="btn secondary">♟ Annuaire joueurs · CSV</button><button id="exportRankingV095" class="btn secondary">🏆 Classement · CSV</button><button id="exportAuditV095" class="btn secondary">📜 Audit affiché · CSV</button><button id="exportSeasonSnapshotV095" class="btn secondary" ${state.profile?.role!=="super_admin"?'disabled':''}>💾 Saison complète · JSON</button></div>`;$("#exportPlayersV095",root).onclick=exportPlayersV095;$("#exportRankingV095",root).onclick=exportRankingV095;$("#exportAuditV095",root).onclick=exportAuditV095;if($("#exportSeasonSnapshotV095",root))$("#exportSeasonSnapshotV095",root).onclick=async()=>{if(state.profile?.role!=="super_admin")return;await createBackupV095();const first=state.admin095.backups?.[0];if(first)downloadBackupV095(first.id);};}
  function csvCellV095(v){const s=String(v??"").replace(/"/g,'""');return `"${s}"`;}
  function downloadTextV095(name,text,type="text/plain"){const blob=new Blob([text],{type:`${type};charset=utf-8`});const a=document.createElement("a");a.href=URL.createObjectURL(blob);a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1500);}
  function safeFileV095(s){return String(s||"backup").normalize("NFD").replace(/[\u0300-\u036f]/g,"").replace(/[^a-z0-9_-]+/gi,"-").replace(/^-+|-+$/g,"").toLowerCase()||"backup";}
  function exportPlayersV095(){const rows=[...state.profileDirectory.values()].sort((a,b)=>String(a.username).localeCompare(String(b.username),'fr'));const csv=[["id","pseudo","rôle","statut","club"],...rows.map(p=>[p.id,p.username,p.role,p.status,p.club_heart])].map(r=>r.map(csvCellV095).join(";")).join("\r\n");downloadTextV095(`nid-joueurs-${Date.now()}.csv`,`\ufeff${csv}`,"text/csv");}
  function exportRankingV095(){const rows=state.standings||state.rankingRows||[];const csv=[["rang","id","pseudo","points","joués","exacts"],...rows.map(r=>[r.rank,r.user_id,r.username,r.points,r.played,r.exact_scores])].map(r=>r.map(csvCellV095).join(";")).join("\r\n");downloadTextV095(`nid-classement-${safeFileV095(state.season?.slug)}.csv`,`\ufeff${csv}`,"text/csv");}
  function exportAuditV095(){const rows=state.admin095.audit||[];const csv=[["date","acteur","action","type","entité"],...rows.map(r=>[r.created_at,r.actor_username,r.action,r.entity_type,r.entity_id])].map(r=>r.map(csvCellV095).join(";")).join("\r\n");downloadTextV095(`nid-audit-${Date.now()}.csv`,`\ufeff${csv}`,"text/csv");}

  function renderAdminAuditV095(){const root=$("#adminAuditPanelV095");if(!root)return;const rows=state.admin095.audit||[],page=state.admin095.auditPage||0,total=state.admin095.auditTotal||0,pages=Math.max(1,Math.ceil(total/25));const actions=[...new Set(rows.map(x=>x.action).filter(Boolean))].sort();root.innerHTML=`<div class="section-title compact"><div><span class="eyebrow">Journal</span><h3>Audit & traçabilité</h3><p>Qui a changé quoi, et quand. Les opérations sensibles 0.9.5 y sont ajoutées automatiquement.</p></div><span class="chip">${total} entrée${total>1?'s':''}</span></div><div class="admin-audit-toolbar-v095"><input id="adminAuditSearchV095" type="search" placeholder="Acteur, action, entité…"><select id="adminAuditActionV095"><option value="">Toutes les actions</option>${actions.map(a=>`<option value="${esc(a)}">${esc(a)}</option>`).join('')}</select><button id="adminAuditRefreshV095" class="btn secondary small">Actualiser</button></div>${state.admin095.auditError?`<div class="form-msg error">${esc(state.admin095.auditError)}</div>`:''}<div class="admin-audit-list-v095">${rows.length?rows.map(a=>`<details><summary><span>${esc(fmtDate(a.created_at))}</span><strong>${esc(a.action)}</strong><em>${esc(a.actor_username||'Système')} · ${esc(a.entity_type)}${a.entity_id?` · ${esc(a.entity_id)}`:''}</em></summary><pre>${esc(JSON.stringify({avant:a.old_data,après:a.new_data},null,2))}</pre></details>`).join(''):'<div class="empty">Aucune trace pour ce filtre.</div>'}</div><div class="admin-pagination-v095"><button id="auditPrevV095" class="btn secondary small" ${page<=0?'disabled':''}>← Précédent</button><span>Page ${page+1} / ${pages}</span><button id="auditNextV095" class="btn secondary small" ${page>=pages-1?'disabled':''}>Suivant →</button></div>`;
    $("#adminAuditRefreshV095",root).onclick=()=>loadAuditPageV095(0,true);$("#adminAuditSearchV095",root).onkeydown=e=>{if(e.key==="Enter")loadAuditPageV095(0,true);};$("#adminAuditActionV095",root).onchange=()=>loadAuditPageV095(0,true);$("#auditPrevV095",root).onclick=()=>loadAuditPageV095(Math.max(0,page-1),true);$("#auditNextV095",root).onclick=()=>loadAuditPageV095(Math.min(pages-1,page+1),true);
  }

  function renderAdminImpersonationV095(){const root=$("#adminImpersonationPanelV095");if(!root)return;if(state.profile?.role!=="super_admin"){root.classList.add("hidden");return;}root.classList.remove("hidden");const players=[...state.profileDirectory.values()].filter(p=>p.status==="active"&&p.role==="player").sort((a,b)=>String(a.username).localeCompare(String(b.username),'fr'));root.innerHTML=`<div class="section-title compact"><div><span class="eyebrow gold">Diagnostic joueur</span><h3>Aperçu sans mot de passe</h3><p>Lecture seule : vérifie les données privées essentielles d’un joueur sans pouvoir pronostiquer à sa place.</p></div><span class="chip">JOURNALISÉ</span></div><div class="admin-impersonation-row-v095"><select id="adminPreviewPlayerV095">${players.map(p=>`<option value="${p.id}">${esc(p.username)}</option>`).join('')}</select><button id="adminPreviewStartV095" class="btn secondary">👁 Ouvrir l’aperçu</button></div><div id="adminPreviewMsgV095" class="form-msg"></div>`;$("#adminPreviewStartV095",root).onclick=openPlayerPreviewV095;}
  async function openPlayerPreviewV095(){const uid=$("#adminPreviewPlayerV095")?.value;if(!uid)return;setMsg("#adminPreviewMsgV095","Chargement…");try{const {data,error}=await sb.rpc("admin_player_preview_v095",{p_user_id:uid,p_season_id:state.season.id});if(error)throw error;await sb.rpc("admin_log_impersonation_v095",{p_target_user_id:uid,p_event:"start"});const p=data?.profile||{};const preds=data?.predictions||[],champs=data?.champions||[],team=data?.team;const root=modal(`👁 Aperçu joueur · ${p.username||'Joueur'}`,`<div class="admin-player-preview-v095"><div class="admin-preview-banner-v095">🔒 Lecture seule · aucune action n’est exécutée au nom du joueur.</div><div class="admin-preview-profile-v095">${avatarHTML({...p,user_id:p.id})}<div><h3>${esc(p.username||'Joueur')}</h3><p>${esc(p.club_heart||'Aucun club de cœur')} · ${esc(p.status||'—')}</p></div></div><div class="admin-preview-kpis-v095"><span><b>${preds.length}</b><small>pronostics</small></span><span><b>${preds.filter(x=>Number(x.points||0)>0).length}</b><small>scorés</small></span><span><b>${champs.length}</b><small>champion(s)</small></span><span><b>${Number(data?.notifications_unread||0)}</b><small>notif. non lues</small></span></div><section><h4>Champions</h4>${champs.length?champs.map(c=>`<p>Choix ${c.pick_number} · ${esc(clubById(c.club_id)?.name||c.club_id)} · ${Number(c.points||0)} pts</p>`).join(''):'<p class="muted">Aucun choix.</p>'}</section><section><h4>Team</h4><p>${team?`${esc(team.name)}${team.is_captain?' · 👑 capitaine':''}`:'Aucune Team active.'}</p></section><section><h4>Derniers pronostics</h4><div class="admin-preview-preds-v095">${preds.slice(0,12).map(x=>{const m=state.allMatches.find(m=>String(m.id)===String(x.match_id));return `<div><span>${esc(m?`${m.home_club?.short_name||m.home_club?.name} – ${m.away_club?.short_name||m.away_club?.name}`:x.match_id)}</span><b>${x.home_score}–${x.away_score}</b><em>${Number(x.points||0)} pt</em></div>`;}).join('')||'<div class="empty">Aucun prono.</div>'}</div></section></div>`);root.addEventListener("close",()=>{});const closeObserver=new MutationObserver(()=>{if(!document.body.contains(root)){sb.rpc("admin_log_impersonation_v095",{p_target_user_id:uid,p_event:"stop"}).catch(()=>{});closeObserver.disconnect();}});closeObserver.observe(document.body,{childList:true,subtree:true});setMsg("#adminPreviewMsgV095","Aperçu ouvert.","ok");}catch(err){setMsg("#adminPreviewMsgV095",friendlyError(err),"error");}}

  function renderAdminDeletionV095(){const root=$("#adminDeletionPanelV095");if(!root)return;if(state.profile?.role!=="super_admin"){root.classList.add("hidden");return;}root.classList.remove("hidden");const rows=state.admin095.deletions||[];root.innerHTML=`<div class="section-title compact"><div><span class="eyebrow danger">Comptes</span><h3>Demandes de suppression</h3><p>Traitement manuel et traçable. « Traiter » anonymise le profil applicatif et désactive les Push ; le compte Auth reste à supprimer depuis Supabase Auth si nécessaire.</p></div><span class="chip">${rows.length}</span></div><div class="admin-deletion-list-v095">${rows.length?rows.map(r=>{const p=state.profileDirectory.get(String(r.user_id));return `<div><span><strong>${esc(p?.username||r.user_id)}</strong><small>${esc(fmtDate(r.requested_at))}${r.reason?` · ${esc(r.reason)}`:''}</small></span><div class="actions"><button class="btn secondary small" data-deletion-review-v095="${r.id}">En cours</button><button class="btn danger small" data-deletion-process-v095="${r.id}">Anonymiser</button><button class="btn secondary small" data-deletion-reject-v095="${r.id}">Refuser</button></div></div>`;}).join(''):'<div class="empty">Aucune demande de suppression.</div>'}</div>`;$$('[data-deletion-review-v095]',root).forEach(b=>b.onclick=()=>processDeletionV095(b.dataset.deletionReviewV095,"reviewing"));$$('[data-deletion-process-v095]',root).forEach(b=>b.onclick=()=>processDeletionV095(b.dataset.deletionProcessV095,"processed"));$$('[data-deletion-reject-v095]',root).forEach(b=>b.onclick=()=>processDeletionV095(b.dataset.deletionRejectV095,"rejected"));}
  async function processDeletionV095(id,decision){if(decision==="processed"&&!confirm("Anonymiser ce joueur dans l’application ? Cette action est sensible et sera journalisée."))return;const note=prompt("Note administrative (facultative)","")||null;try{const {error}=await sb.rpc("admin_process_account_deletion_v095",{p_request_id:id,p_decision:decision,p_note:note});if(error)throw error;await Promise.all([loadProfileDirectory(),loadAdmin095Data(true)]);renderAll();toast("Demande mise à jour.");}catch(err){toast(friendlyError(err),"error");}}

  function renderAccountPrivacyV095(){const root=$("#accountPrivacyPanelV095");if(!root||!state.user)return;root.innerHTML=`<div class="section-title compact"><div><span class="eyebrow">Mes données</span><h3>Suppression du compte</h3><p>Tu peux demander la suppression de ton compte. Le Super Admin traitera la demande avant anonymisation.</p></div></div><button id="requestDeletionV095" class="btn secondary small" type="button">Demander la suppression de mon compte</button><div id="requestDeletionMsgV095" class="form-msg"></div>`;$("#requestDeletionV095",root).onclick=async()=>{if(!confirm("Envoyer une demande de suppression de compte ?"))return;const reason=prompt("Motif facultatif","")||null;try{if(demoMode)return setMsg("#requestDeletionMsgV095","Mode démo : demande simulée.","ok");const {error}=await sb.rpc("request_account_deletion_v095",{p_reason:reason});if(error)throw error;setMsg("#requestDeletionMsgV095","Demande envoyée au Super Admin.","ok");}catch(err){setMsg("#requestDeletionMsgV095",friendlyError(err),"error");}};}
  window.renderAccountPrivacyV095=renderAccountPrivacyV095;

  function bindAdminKeyboardV095(){if(document.documentElement.dataset.admin095Keys)return;document.documentElement.dataset.admin095Keys="1";document.addEventListener("keydown",e=>{if(e.key==="/"&&!/input|textarea|select/i.test(document.activeElement?.tagName||"")&&!$("#view-admin")?.classList.contains("hidden")){e.preventDefault();$("#adminGlobalSearchV095")?.focus();}});}
  bindAdminKeyboardV095();updateNetworkStateV095();
})();
