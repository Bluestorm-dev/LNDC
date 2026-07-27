"use strict";

// Le Nid des Champions V0.6.3 — centre de notifications, préférences et Web Push
const NIDC_NOTIFICATION_FILTERS = [
  ["all","Toutes"],["matches","Matchs"],["social","Réactions"],["rival","Rival"],["team","Team"],["owl","Hibou"],["system","Système"]
];

function defaultNotificationPreferences(){
  return {
    notifications_enabled:true,push_enabled:true,category_matches:true,category_champion:true,category_results:true,
    category_rival:true,category_team:true,category_owl:true,category_support:true,category_system:true,category_ranking:true,category_social:true,
    reminder_24h:false,reminder_3h:true,reminder_1h:false,reminder_30m:true,
    quiet_hours_enabled:true,quiet_start:"23:00",quiet_end:"08:00",urgent_bypass_quiet:true,
    owl_tone:"automatic",timezone:Intl.DateTimeFormat().resolvedOptions().timeZone||"Europe/Paris"
  };
}

function notificationDemoSeed(){
  const key=`nidc_demo_notifications:${state.user?.id}`;
  let rows=JSON.parse(localStorage.getItem(key)||"null");
  if(!Array.isArray(rows)){
    rows=[
      {id:"demo-n-1",user_id:state.user?.id,category:"owl",title:"🦉 Le Hibou surveille",body:"La V0.6.3 est réveillée. Les plumes sont branchées.",importance:"info",deep_link:"home",created_at:new Date().toISOString(),read_at:null,deleted_at:null},
      {id:"demo-n-2",user_id:state.user?.id,category:"matches",title:"⏰ Pronostics",body:"Pense à vérifier la prochaine journée UEFA.",importance:"normal",deep_link:"matches",created_at:new Date(Date.now()-3600000).toISOString(),read_at:null,deleted_at:null}
    ];localStorage.setItem(key,JSON.stringify(rows));
  }
  return rows;
}

async function loadNotificationData(){
  if(!state.user)return;
  if(demoMode){
    const prefKey=`nidc_demo_notification_preferences:${state.user.id}`;
    state.notificationPreferences={...defaultNotificationPreferences(),...JSON.parse(localStorage.getItem(prefKey)||"{}")};
    state.notifications=notificationDemoSeed();
    state.pushSubscriptions=JSON.parse(localStorage.getItem(`nidc_demo_push_subscriptions:${state.user.id}`)||"[]");
    if(state.profile?.role==="super_admin") await loadAdminPushData();
    return;
  }
  const [{data:pref,error:pErr},{data:notifs,error:nErr},{data:subs,error:sErr}] = await Promise.all([
    sb.from("notification_preferences").select("*").eq("user_id",state.user.id).maybeSingle(),
    sb.from("notifications").select("*").eq("user_id",state.user.id).is("deleted_at",null).order("created_at",{ascending:false}).limit(200),
    sb.from("push_subscriptions").select("id,device_name,user_agent,platform,active,last_success_at,last_failure_at,disabled_at,created_at").eq("user_id",state.user.id).order("created_at",{ascending:false})
  ]);
  if(pErr||nErr||sErr) throw new Error("Migration V0.6.2 absente : exécute sql/HOTFIX_V0.6.2_EXISTING_DB.sql.");
  state.notificationPreferences={...defaultNotificationPreferences(),...(pref||{})};
  state.notifications=notifs||[];state.pushSubscriptions=subs||[];
  if(state.profile?.role==="super_admin") await loadAdminPushData();
}

function notificationAllowedByPreferences(n){
  if(n?.category==="system")return true;
  const p=state.notificationPreferences||defaultNotificationPreferences();if(p.notifications_enabled===false)return false;
  const key=({matches:"category_matches",champion:"category_champion",results:"category_results",rival:"category_rival",team:"category_team",owl:"category_owl",support:"category_support",ranking:"category_ranking",social:"category_social"})[n?.category];
  return !key||p[key]!==false;
}
function unreadNotificationCount(){return (state.notifications||[]).filter(n=>!n.read_at&&!n.deleted_at&&notificationAllowedByPreferences(n)).length;}

function notificationCategoryLabel(cat){return ({matches:"Matchs",champion:"Champion",results:"Résultats",rival:"Rival",team:"Team",owl:"Hibou",system:"Système",ranking:"Classement",support:"Hibou",social:"Réactions"}[cat]||cat);}

function renderNotificationBell(){
  const btn=$("#notificationBell"),badge=$("#notificationBellCount");if(!btn||!badge)return;
  const count=unreadNotificationCount();badge.textContent=count>99?"99+":String(count);badge.classList.toggle("hidden",count===0);btn.classList.toggle("has-unread",count>0);
}

function ensureNotificationDrawer(){
  let drawer=$("#notificationDrawer");if(drawer)return drawer;
  drawer=document.createElement("aside");drawer.id="notificationDrawer";drawer.className="notification-drawer hidden";drawer.setAttribute("aria-label","Centre de notifications");
  drawer.innerHTML=`<div class="notification-drawer-head"><div><span class="eyebrow">Centre du Nid</span><h3>Notifications</h3></div><button id="notificationDrawerClose" class="btn secondary small" type="button">Fermer</button></div><div id="notificationFilterBar" class="notification-filter-bar"></div><div class="notification-drawer-tools"><button id="notificationMarkAllRead" class="text-action" type="button">Tout marquer comme lu</button></div><div id="notificationList" class="notification-list"></div>`;
  document.body.appendChild(drawer);$("#notificationDrawerClose").onclick=()=>drawer.classList.add("hidden");$("#notificationMarkAllRead").onclick=markAllNotificationsRead;
  return drawer;
}

function openNotificationCenter(filter="all"){
  state.notificationFilter=filter||"all";const drawer=ensureNotificationDrawer();drawer.classList.remove("hidden");renderNotificationCenter();
}

function renderNotificationCenter(){
  const drawer=ensureNotificationDrawer();
  const bar=$("#notificationFilterBar",drawer),list=$("#notificationList",drawer);if(!bar||!list)return;
  const filter=state.notificationFilter||"all";
  bar.innerHTML=NIDC_NOTIFICATION_FILTERS.map(([key,label])=>`<button class="${filter===key?'active':''}" data-notification-filter="${key}" type="button">${label}</button>`).join("");
  $$('[data-notification-filter]',bar).forEach(b=>b.onclick=()=>{state.notificationFilter=b.dataset.notificationFilter;renderNotificationCenter();});
  const rows=(state.notifications||[]).filter(n=>{
    if(n.deleted_at||!notificationAllowedByPreferences(n))return false;
    if(filter==="all")return true;
    if(filter==="matches")return ["matches","champion","results","ranking"].includes(n.category);
    if(filter==="owl")return ["owl","support"].includes(n.category);
    return n.category===filter;
  });
  list.innerHTML=rows.length?rows.map(n=>`<article class="notification-item ${n.read_at?'':'unread'} importance-${esc(n.importance||'normal')}" data-notification-id="${n.id}"><button class="notification-open" type="button"><span class="notification-dot"></span><span><small>${esc(notificationCategoryLabel(n.category))} · ${esc(fmtDate(n.created_at))}</small><strong>${esc(n.title)}</strong><p>${esc(n.body)}</p></span></button><div class="notification-actions"><button data-notification-toggle-read type="button">${n.read_at?'Non lu':'Lu'}</button><button data-notification-delete type="button">Supprimer</button></div></article>`).join(""):'<div class="empty">Rien à signaler. Le Hibou savoure ce silence suspect.</div>';
  $$('[data-notification-id]',list).forEach(row=>{
    const id=row.dataset.notificationId;const n=(state.notifications||[]).find(x=>String(x.id)===String(id));
    $(".notification-open",row).onclick=async()=>{await markNotificationRead(id,true);openNotificationDeepLink(n?.deep_link,n?.payload);drawer.classList.add("hidden");};
    $("[data-notification-toggle-read]",row).onclick=()=>markNotificationRead(id,!n?.read_at);
    $("[data-notification-delete]",row).onclick=()=>deleteNotification(id);
  });
}

async function markNotificationRead(id,read=true){
  const n=(state.notifications||[]).find(x=>String(x.id)===String(id));if(!n)return;
  const value=read?new Date().toISOString():null;
  if(demoMode){n.read_at=value;localStorage.setItem(`nidc_demo_notifications:${state.user.id}`,JSON.stringify(state.notifications));}
  else {const {error}=await sb.from("notifications").update({read_at:value}).eq("id",id).eq("user_id",state.user.id);if(error)return toast(friendlyError(error),"error");n.read_at=value;}
  renderNotificationBell();renderNotificationCenter();
}

async function markAllNotificationsRead(){
  if(demoMode){const at=new Date().toISOString();(state.notifications||[]).forEach(n=>{if(!n.deleted_at)n.read_at=n.read_at||at;});localStorage.setItem(`nidc_demo_notifications:${state.user.id}`,JSON.stringify(state.notifications));}
  else {const {error}=await sb.rpc("mark_all_notifications_read_v060");if(error)return toast(friendlyError(error),"error");(state.notifications||[]).forEach(n=>n.read_at=n.read_at||new Date().toISOString());}
  renderNotificationBell();renderNotificationCenter();
}

async function deleteNotification(id){
  const n=(state.notifications||[]).find(x=>String(x.id)===String(id));if(!n)return;const at=new Date().toISOString();
  if(demoMode){n.deleted_at=at;localStorage.setItem(`nidc_demo_notifications:${state.user.id}`,JSON.stringify(state.notifications));}
  else{const {error}=await sb.from("notifications").update({deleted_at:at}).eq("id",id).eq("user_id",state.user.id);if(error)return toast(friendlyError(error),"error");n.deleted_at=at;}
  renderNotificationBell();renderNotificationCenter();
}

function openNotificationDeepLink(link,payload={}){
  const value=String(link||"home");
  if(value.startsWith("support:")){openSupportTicket(value.split(":")[1]);return;}
  if(value.startsWith("player:")){openPlayerQuickProfile(value.split(":")[1]);return;}
  if(value==="rival"||value.startsWith("rival:")){setView("rival");renderRivalView();return;}
  if(value==="team"||value==="teams"||value.startsWith("team:")||value.startsWith("teams:")){const tab=value.split(":")[1]||payload?.tab;if(tab)state.teamTab=tab;setView("teams");if(typeof renderTeams==="function")renderTeams();return;}
  if(value==="matches"||value.startsWith("matches:")){const matchdayId=value.split(":")[1]||payload?.matchday_id;if(matchdayId&&state.matchdays.some(md=>String(md.id)===String(matchdayId)))selectMatchday(matchdayId);setView("matches");return;}
  setView(["home","profile","admin","ranking","teams","matches","knockout","season"].includes(value)?value:"home");
}

function notificationCheckbox(id,label,checked){return `<label class="notification-toggle"><span>${label}</span><input id="${id}" type="checkbox" ${checked?'checked':''}></label>`;}
function hhmm(v){return String(v||"").slice(0,5)||"00:00";}

function renderNotificationPreferences(){
  const root=$("#notificationPreferencesPanel");if(!root)return;const p=state.notificationPreferences||defaultNotificationPreferences();
  root.innerHTML=`<div class="notification-settings-grid"><section><span class="eyebrow">Le Hibou</span><h4>Caractère</h4><div class="field"><label>Ton préféré</label><select id="owlToneSelect"><option value="sage">🙂 Sage</option><option value="piquant">😏 Piquant</option><option value="sans_pitie">🔥 Sans pitié</option><option value="automatic">🎭 Automatique</option></select></div><small class="muted">Automatique adapte les piques à la situation.</small></section><section><span class="eyebrow">Catégories</span><h4>Ce qui peut me prévenir</h4>${notificationCheckbox("prefMatches","Matchs & pronostics",p.category_matches)}${notificationCheckbox("prefChampion","Champion",p.category_champion)}${notificationCheckbox("prefResults","Résultats",p.category_results)}${notificationCheckbox("prefRival","Rivalités",p.category_rival)}${notificationCheckbox("prefTeam","Teams",p.category_team)}${notificationCheckbox("prefOwl","Hibou masqué",p.category_owl)}${notificationCheckbox("prefSupport","Réponses du Hibou",p.category_support)}${notificationCheckbox("prefRanking","Classement",p.category_ranking)}${notificationCheckbox("prefSocial","Réactions joueurs",p.category_social)}</section><section><span class="eyebrow">Rappels</span><h4>Avant le verrouillage</h4>${notificationCheckbox("pref24h","24 h",p.reminder_24h)}${notificationCheckbox("pref3h","3 h",p.reminder_3h)}${notificationCheckbox("pref1h","1 h",p.reminder_1h)}${notificationCheckbox("pref30m","30 min",p.reminder_30m)}</section><section><span class="eyebrow">Nuit</span><h4>Quiet hours</h4>${notificationCheckbox("prefQuiet","Activer",p.quiet_hours_enabled)}<div class="quiet-time-row"><div class="field"><label>De</label><input id="prefQuietStart" type="time" value="${hhmm(p.quiet_start)}"></div><div class="field"><label>À</label><input id="prefQuietEnd" type="time" value="${hhmm(p.quiet_end)}"></div></div>${notificationCheckbox("prefUrgentBypass","Urgence prono autorisée",p.urgent_bypass_quiet)}<small class="muted">Fuseau détecté : ${esc(p.timezone||"Europe/Paris")}</small></section></div><div class="actions"><button id="saveNotificationPreferencesBtn" class="btn small" type="button">Enregistrer mes préférences</button><button id="enablePushBtn" class="btn gold small" type="button">🔔 Activer les notifications push</button></div><div id="pushPermissionStatus" class="form-msg"></div><div id="pushDevices" class="push-devices"></div>`;
  $("#owlToneSelect").value=p.owl_tone||"automatic";$("#saveNotificationPreferencesBtn").onclick=saveNotificationPreferences;$("#enablePushBtn").onclick=enablePushNotifications;renderPushDevices();
  updatePushPermissionStatus();
}

function collectNotificationPreferences(){
  const base={...(state.notificationPreferences||defaultNotificationPreferences())};
  return {...base,user_id:state.user.id,owl_tone:$("#owlToneSelect").value,category_matches:$("#prefMatches").checked,category_champion:$("#prefChampion").checked,category_results:$("#prefResults").checked,category_rival:$("#prefRival").checked,category_team:$("#prefTeam").checked,category_owl:$("#prefOwl").checked,category_support:$("#prefSupport").checked,category_ranking:$("#prefRanking").checked,category_social:$("#prefSocial").checked,reminder_24h:$("#pref24h").checked,reminder_3h:$("#pref3h").checked,reminder_1h:$("#pref1h").checked,reminder_30m:$("#pref30m").checked,quiet_hours_enabled:$("#prefQuiet").checked,quiet_start:$("#prefQuietStart").value,quiet_end:$("#prefQuietEnd").value,urgent_bypass_quiet:$("#prefUrgentBypass").checked,timezone:Intl.DateTimeFormat().resolvedOptions().timeZone||"Europe/Paris"};
}

async function saveNotificationPreferences(){
  const prefs=collectNotificationPreferences();
  try{
    if(demoMode)localStorage.setItem(`nidc_demo_notification_preferences:${state.user.id}`,JSON.stringify(prefs));
    else{const {error}=await sb.from("notification_preferences").upsert(prefs,{onConflict:"user_id"});if(error)throw error;}
    state.notificationPreferences=prefs;toast("Préférences de notifications enregistrées.");renderHome();
  }catch(err){toast(friendlyError(err),"error");}
}

function updatePushPermissionStatus(){
  const box=$("#pushPermissionStatus");if(!box)return;
  if(!("Notification" in window)){box.textContent="Les notifications push ne sont pas prises en charge par ce navigateur.";box.className="form-msg error";return;}
  box.textContent=Notification.permission==="granted"?"✓ Permission navigateur accordée.":Notification.permission==="denied"?"Notifications refusées dans les réglages du navigateur.":"Le Nid demandera l’autorisation seulement après ton clic.";
  box.className=`form-msg ${Notification.permission==="granted"?'ok':Notification.permission==="denied"?'error':''}`;
}

function renderHomePushPrompt(){
  const root=$("#homePushPrompt");if(!root)return;
  const supported=("Notification" in window)&&("serviceWorker" in navigator)&&("PushManager" in window);
  const hasActive=(state.pushSubscriptions||[]).some(s=>s.active);
  const hidden=!state.user||!supported||hasActive||Notification.permission==="denied";
  root.classList.toggle("hidden",hidden);if(hidden)return;
  root.innerHTML=`<div class="home-push-icon">🔔</div><div><span class="eyebrow gold">Ne rate plus tes pronostics</span><h3>Le Nid peut te prévenir au bon moment.</h3><p>Rappels regroupés, rivalités, Teams et réponses du Hibou. Le navigateur ne demandera l’autorisation qu’après ton clic.</p></div><button id="homeEnablePushBtn" class="btn gold small" type="button">Activer les notifications</button>`;
  $("#homeEnablePushBtn").onclick=enablePushNotifications;
}

function base64UrlToUint8Array(base64String){const padding="=".repeat((4-base64String.length%4)%4);const base64=(base64String+padding).replace(/-/g,"+").replace(/_/g,"/");const raw=atob(base64);return Uint8Array.from([...raw].map(c=>c.charCodeAt(0)));}
function pushDeviceName(){const ua=navigator.userAgent||"Navigateur";if(/Android/i.test(ua))return "Android · "+((navigator.userAgentData?.platform)||"mobile");if(/iPhone|iPad/i.test(ua))return "iPhone / iPad";return `${navigator.userAgentData?.platform||navigator.platform||"Appareil"} · ${/Chrome/i.test(ua)?"Chrome":/Firefox/i.test(ua)?"Firefox":/Safari/i.test(ua)?"Safari":"Navigateur"}`;}

async function enablePushNotifications(){
  try{
    if(!("serviceWorker" in navigator)||!("PushManager" in window)||!("Notification" in window))throw new Error("Web Push indisponible sur ce navigateur.");
    const permission=await Notification.requestPermission();updatePushPermissionStatus();if(permission!=="granted")throw new Error("Autorisation de notification non accordée.");
    if(demoMode){const row={id:"demo-device",device_name:pushDeviceName(),platform:navigator.platform,active:true,created_at:new Date().toISOString(),last_success_at:new Date().toISOString()};state.pushSubscriptions=[row];localStorage.setItem(`nidc_demo_push_subscriptions:${state.user.id}`,JSON.stringify(state.pushSubscriptions));renderPushDevices();renderHomePushPrompt();return toast("Push simulé activé en mode démo.");}
    const {data:keyRes,error:keyErr}=await sb.functions.invoke("push-dispatch",{body:{action:"public-key"}});if(keyErr)throw keyErr;if(!keyRes?.configured||!keyRes?.publicKey)throw new Error("Les clés VAPID ne sont pas encore configurées côté Supabase.");
    const registration=await navigator.serviceWorker.ready;let subscription=await registration.pushManager.getSubscription();
    if(!subscription)subscription=await registration.pushManager.subscribe({userVisibleOnly:true,applicationServerKey:base64UrlToUint8Array(keyRes.publicKey)});
    const j=subscription.toJSON();const row={user_id:state.user.id,endpoint:subscription.endpoint,p256dh:j.keys?.p256dh,auth_key:j.keys?.auth,device_name:pushDeviceName(),user_agent:navigator.userAgent,platform:navigator.userAgentData?.platform||navigator.platform||null,active:true,disabled_at:null};
    const {error}=await sb.from("push_subscriptions").upsert(row,{onConflict:"endpoint"});if(error)throw error;await loadNotificationData();renderNotificationPreferences();renderHomePushPrompt();toast("🔔 Cet appareil recevra les push du Nid.");
  }catch(err){toast(friendlyError(err),"error");}
}

function renderPushDevices(){
  const root=$("#pushDevices");if(!root)return;const rows=state.pushSubscriptions||[];
  root.innerHTML=`<div class="section-title compact"><div><h4>Mes appareils</h4><p>Un même compte peut recevoir les push sur plusieurs appareils.</p></div><span class="chip">${rows.filter(x=>x.active).length} actif(s)</span></div>${rows.length?rows.map(s=>`<div class="push-device ${s.active?'':'inactive'}"><span>📱</span><div><strong>${esc(s.device_name||s.platform||"Appareil")}</strong><small>${s.active?'Actif':'Ancien appareil'}${s.last_success_at?` · dernier succès ${esc(fmtDate(s.last_success_at))}`:''}</small></div>${s.active?`<button class="btn secondary small" data-disable-push="${s.id}">Désactiver</button>`:''}</div>`).join(""):'<div class="empty">Aucun appareil enregistré.</div>'}`;
  $$('[data-disable-push]',root).forEach(b=>b.onclick=()=>disablePushDevice(b.dataset.disablePush));
}

async function disablePushDevice(id){
  try{if(demoMode){state.pushSubscriptions=(state.pushSubscriptions||[]).map(x=>x.id===id?{...x,active:false,disabled_at:new Date().toISOString()}:x);localStorage.setItem(`nidc_demo_push_subscriptions:${state.user.id}`,JSON.stringify(state.pushSubscriptions));}else{const {error}=await sb.from("push_subscriptions").update({active:false,disabled_at:new Date().toISOString()}).eq("id",id);if(error)throw error;await loadNotificationData();}renderPushDevices();toast("Appareil désactivé.");}catch(err){toast(friendlyError(err),"error");}
}

async function loadAdminPushData(){
  if(state.profile?.role!=="super_admin")return;
  if(demoMode){state.pushDeliveryLogs=[{id:1,created_at:new Date().toISOString(),delivery_kind:"test",status:"sent",response_code:201,user_id:state.user.id,subscription_id:"demo-device"}];state.adminPushSubscriptions=state.pushSubscriptions||[];return;}
  const [{data,error},{data:subs,error:sErr}]=await Promise.all([sb.from("push_delivery_logs").select("*").order("created_at",{ascending:false}).limit(100),sb.from("push_subscriptions").select("id,user_id,device_name,platform,active").order("created_at",{ascending:false})]);if(error||sErr)throw error||sErr;state.pushDeliveryLogs=data||[];state.adminPushSubscriptions=subs||[];
}

function renderAdminNotifications(){
  const root=$("#adminNotificationsPanel");if(!root)return;
  if(state.profile?.role!=="super_admin"){root.innerHTML='<div class="empty">Réservé au Super Admin.</div>';return;}
  const players=[...state.profileDirectory.values()].sort((a,b)=>String(a.username).localeCompare(String(b.username),"fr"));
  root.innerHTML=`<div class="grid grid-2"><section><span class="eyebrow gold">Test Push</span><h4>Vérifier un appareil</h4><div class="field"><label>Destinataire</label><select id="pushTestTarget"><option value="${state.user.id}">Moi (${esc(state.profile.username)})</option>${players.filter(p=>p.id!==state.user.id).map(p=>`<option value="${p.id}">${esc(p.username)}</option>`).join('')}</select></div><div class="field"><label>Titre</label><input id="pushTestTitle" value="🔔 Test du Nid"></div><div class="field"><label>Message</label><textarea id="pushTestBody" rows="3">Si tu lis ceci, les plumes sont correctement raccordées.</textarea></div><div class="field"><label>Destination au clic</label><select id="pushTestLink"><option value="home">Accueil</option><option value="matches">Pronostics</option><option value="teams">Team</option><option value="rival">Rival</option><option value="profile">Profil</option></select></div><div class="actions"><button id="pushQuickTestBtn" class="btn gold small">🔔 Envoyer le test</button><button id="pushCustomTestBtn" class="btn secondary small">Envoyer personnalisé</button></div><div id="pushTestStatus" class="form-msg"></div><hr class="soft-separator"><span class="eyebrow danger">Message système critique</span><h4>Prévenir tout le Nid</h4><p class="muted">Pour maintenance ou incident majeur. Toujours visible dans le centre interne ; le push nécessite l’autorisation du navigateur.</p><div class="field"><label>Titre</label><input id="criticalSystemTitle" maxlength="120" placeholder="Maintenance du Nid"></div><div class="field"><label>Message</label><textarea id="criticalSystemBody" rows="3" maxlength="2000"></textarea></div><label class="notification-toggle"><span>Envoyer aussi en push</span><input id="criticalSystemPush" type="checkbox" checked></label><button id="criticalSystemSendBtn" class="btn danger small" type="button">🚨 Envoyer le message critique</button><div id="criticalSystemMsg" class="form-msg"></div></section><section><span class="eyebrow">Diagnostic</span><h4>Livraisons récentes</h4><div id="pushLogList" class="push-log-list"></div></section></div>`;
  $("#pushQuickTestBtn").onclick=()=>sendAdminPushTest(true);$("#pushCustomTestBtn").onclick=()=>sendAdminPushTest(false);$("#criticalSystemSendBtn").onclick=sendCriticalSystemMessage;renderPushLogList();
}

function renderPushLogList(){
  const root=$("#pushLogList");if(!root)return;const rows=state.pushDeliveryLogs||[];
  root.innerHTML=rows.length?rows.slice(0,30).map(l=>{const p=state.profileDirectory.get(String(l.user_id));const dev=(state.adminPushSubscriptions||[]).find(s=>String(s.id)===String(l.subscription_id));return `<div class="push-log-row"><span class="push-log-status ${esc(l.status)}">${l.status==='sent'?'✓':l.status==='failed'?'⚠':l.status==='expired'?'×':'·'}</span><div><strong>${esc(l.delivery_kind||'notification')} · ${esc(p?.username||'Joueur')}</strong><small>${esc(fmtDate(l.created_at))} · ${esc(dev?.device_name||dev?.platform||'appareil non identifié')} · ${esc(l.status)}${l.response_code?` · HTTP ${l.response_code}`:''}</small>${l.error_message?`<p>${esc(l.error_message)}</p>`:''}</div></div>`;}).join(""):'<div class="empty">Aucun push journalisé.</div>';
}

async function sendAdminPushTest(quick=false){
  const target=$("#pushTestTarget")?.value||state.user.id,title=quick?"🔔 Test du Nid":$("#pushTestTitle")?.value,body=quick?"Si tu lis ceci, les plumes sont correctement raccordées.":$("#pushTestBody")?.value,deep_link=$("#pushTestLink")?.value||"home";
  setMsg("#pushTestStatus","Envoi en cours…");
  try{
    if(demoMode){setMsg("#pushTestStatus","✓ Test simulé : 1/1 appareil.","ok");return;}
    const {data,error}=await sb.functions.invoke("push-dispatch",{body:{action:"test",target_user_id:target,title,body,deep_link}});if(error)throw error;if(data?.error)throw new Error(data.error);setMsg("#pushTestStatus",`✓ ${data.sent||0} envoyé(s) · ${data.failed||0} échec(s).`,"ok");await Promise.all([loadAdminPushData(),loadNotificationData()]);renderAdminNotifications();renderNotificationBell();
  }catch(err){setMsg("#pushTestStatus",friendlyError(err),"error");}
}

async function sendCriticalSystemMessage(){
  const title=$("#criticalSystemTitle")?.value.trim(),body=$("#criticalSystemBody")?.value.trim(),push=$("#criticalSystemPush")?.checked!==false;
  if(!title||!body)return setMsg("#criticalSystemMsg","Titre et message obligatoires.","error");
  if(!confirm("Envoyer ce message critique à tous les joueurs actifs du Nid ?"))return;
  setMsg("#criticalSystemMsg","Envoi en cours…");
  try{
    if(demoMode){setMsg("#criticalSystemMsg","✓ Message critique simulé.","ok");return;}
    const {data,error}=await sb.rpc("admin_send_system_message_v060",{p_season_id:state.season?.id||null,p_title:title,p_body:body,p_push:push});
    if(error)throw error;setMsg("#criticalSystemMsg",`✓ Message envoyé à ${Number(data||0)} joueur(s).`,"ok");await loadNotificationData();renderNotificationBell();
  }catch(err){setMsg("#criticalSystemMsg",friendlyError(err),"error");}
}

function consumePendingDeepLink(){
  try{const url=new URL(location.href);const link=url.searchParams.get("deepLink")||sessionStorage.getItem("nidc_pending_deep_link");if(!link)return;sessionStorage.removeItem("nidc_pending_deep_link");if(url.searchParams.has("deepLink")){url.searchParams.delete("deepLink");history.replaceState({},"",url.pathname+url.search+url.hash);}setTimeout(()=>openNotificationDeepLink(link,{}),80);}catch{}
}
if("serviceWorker" in navigator){navigator.serviceWorker.addEventListener("message",event=>{if(event.data?.type==="nidc-deep-link"){if(state?.user)openNotificationDeepLink(event.data.deepLink,{});else sessionStorage.setItem("nidc_pending_deep_link",event.data.deepLink||"home");}});}
