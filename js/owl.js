"use strict";

// Le Nid des Champions V0.6.4 — messages du Hibou masqué
function demoOwlMessages(){
  let rows=JSON.parse(localStorage.getItem("nidc_demo_owl_messages")||"null");
  if(!Array.isArray(rows)){rows=[{id:"owl-demo-1",season_id:state.season?.id,title:"Le Nid ouvre l’œil",body:"Les rivalités sont prêtes. Choisis bien ta Némésis : le Hibou, lui, prendra des notes.",importance:"info",target_scope:"all",target_id:null,push_enabled:false,automated:false,show_in_history:true,starts_at:new Date(Date.now()-3600000).toISOString(),expires_at:null,created_at:new Date(Date.now()-3600000).toISOString()}];localStorage.setItem("nidc_demo_owl_messages",JSON.stringify(rows));}return rows;
}

async function loadOwlData(){
  if(!state.user)return;
  if(demoMode){state.owlMessages=demoOwlMessages();return;}
  const {data,error}=await sb.from("owl_messages").select("*").order("starts_at",{ascending:false}).limit(100);if(error)throw new Error("Migration Hibou V0.6.2 absente : exécute sql/HOTFIX_V0.6.2_EXISTING_DB.sql.");state.owlMessages=data||[];
}

function activeOwlMessage(){const now=Date.now();return (state.owlMessages||[]).find(m=>new Date(m.starts_at||m.created_at).getTime()<=now&&(!m.expires_at||new Date(m.expires_at).getTime()>now))||null;}

function renderOwlHome(){
  const msg=activeOwlMessage();const quote=$("#hibouMessage");if(quote)quote.textContent=msg?`« ${msg.body} »`:`« Les casseroles ont déjà réservé leur soirée. »`;
  const card=$(".home-owl-card");if(!card)return;let tools=$("#homeOwlTools",card);if(!tools){tools=document.createElement("div");tools.id="homeOwlTools";tools.className="home-owl-tools";card.appendChild(tools);}tools.innerHTML=`<button id="writeToOwlBtn" class="btn gold small" type="button">Écrire au Hibou</button><button id="owlHistoryBtn" class="btn secondary small" type="button">Historique</button>`;$("#writeToOwlBtn").onclick=openSupportCenter;$("#owlHistoryBtn").onclick=openOwlHistory;
}

function openOwlHistory(){
  const rows=(state.owlMessages||[]).filter(m=>m.show_in_history!==false);modal("🦉 Historique du Hibou",`<div class="owl-history">${rows.length?rows.map(m=>`<article class="owl-history-item importance-${esc(m.importance||'info')}"><small>${esc(fmtDate(m.starts_at||m.created_at))}</small><strong>${esc(m.title)}</strong><p>${esc(m.body)}</p>${m.target_scope!=='all'?`<span class="chip">${m.target_scope==='team'?'Team':'Personnel'}</span>`:''}</article>`).join(''):'<div class="empty">Le Hibou n’a encore rien gravé dans ses archives.</div>'}</div>`);
}

function renderAdminOwl(){
  const root=$("#adminOwlPanel");if(!root)return;if(state.profile?.role!=="super_admin"){root.innerHTML='<div class="empty">Réservé au Super Admin.</div>';return;}
  const players=[...state.profileDirectory.values()].sort((a,b)=>String(a.username).localeCompare(String(b.username),"fr"));const teams=(state.teamDirectory||[]).filter(t=>t.status==='active');
  root.innerHTML=`<div class="grid grid-2"><section><span class="eyebrow gold">Message du Hibou</span><h4>Parler au Nid</h4><div class="field"><label>Cible</label><select id="owlTargetScope"><option value="all">Tout le Nid</option><option value="team">Une Team</option><option value="player">Un joueur</option></select></div><div id="owlTargetDynamic"></div><div class="field"><label>Titre</label><input id="owlAdminTitle" maxlength="120" value="Message du Hibou masqué"></div><div class="field"><label>Message</label><textarea id="owlAdminBody" rows="5" maxlength="4000"></textarea></div><div class="grid grid-2"><div class="field"><label>Importance</label><select id="owlAdminImportance"><option value="normal">Normal</option><option value="info" selected>Info</option><option value="important">Important</option><option value="urgent">Urgent</option></select></div><label class="notification-toggle"><span>Push</span><input id="owlAdminPush" type="checkbox"></label></div><button id="owlAdminSendBtn" class="btn gold small" type="button">🦉 Publier</button><div id="owlAdminMsg" class="form-msg"></div></section><section><span class="eyebrow">Historique</span><h4>Derniers messages</h4><div class="owl-admin-history">${(state.owlMessages||[]).slice(0,15).map(m=>`<div><small>${esc(fmtDate(m.created_at))} · ${esc(m.target_scope)}</small><strong>${esc(m.title)}</strong><p>${esc(m.body)}</p></div>`).join('')||'<div class="empty">Aucun message.</div>'}</div></section></div>`;
  const renderTarget=()=>{const scope=$("#owlTargetScope").value;const box=$("#owlTargetDynamic");if(scope==='player')box.innerHTML=`<div class="field"><label>Joueur</label><select id="owlTargetId">${players.map(p=>`<option value="${p.id}">${esc(p.username)}</option>`).join('')}</select></div>`;else if(scope==='team')box.innerHTML=`<div class="field"><label>Team</label><select id="owlTargetId">${teams.map(t=>`<option value="${t.team_id||t.id}">${esc(t.name)}</option>`).join('')}</select></div>`;else box.innerHTML='';};$("#owlTargetScope").onchange=renderTarget;renderTarget();$("#owlAdminSendBtn").onclick=sendAdminOwlMessage;
}

async function sendAdminOwlMessage(){
  const scope=$("#owlTargetScope").value,target=$("#owlTargetId")?.value||null,title=$("#owlAdminTitle").value.trim(),body=$("#owlAdminBody").value.trim(),importance=$("#owlAdminImportance").value,push=$("#owlAdminPush").checked;if(!title||!body)return setMsg("#owlAdminMsg","Titre et message obligatoires.","error");setMsg("#owlAdminMsg","Le Hibou taille sa plume…");
  try{
    if(demoMode){const rows=demoOwlMessages();rows.unshift({id:`owl-${Date.now()}`,season_id:state.season?.id,title,body,importance,target_scope:scope,target_id:target,push_enabled:push,automated:false,show_in_history:true,starts_at:new Date().toISOString(),created_at:new Date().toISOString()});localStorage.setItem("nidc_demo_owl_messages",JSON.stringify(rows));}
    else{const {data:messageId,error}=await sb.rpc("admin_send_owl_message_v060",{p_season_id:state.season?.id||null,p_title:title,p_body:body,p_importance:importance,p_target_scope:scope,p_target_id:target||null,p_push:push});if(error)throw error;}
    await Promise.all([loadOwlData(),loadNotificationData()]);renderOwlHome();renderAdminOwl();renderNotificationBell();toast(push?"🦉 Message publié · Push immédiat déclenché.":"🦉 Message publié.");
  }catch(err){setMsg("#owlAdminMsg",friendlyError(err),"error");}
}


function openAdminOwlMessageForPlayer(userId){
  if(state.profile?.role!=="super_admin")return;const player=state.profileDirectory.get(String(userId));if(!player)return toast("Joueur introuvable.","error");
  const root=modal(`🦉 Message pour ${player.username}`,`<div class="field"><label>Titre</label><input id="directOwlTitle" maxlength="120" value="Message du Hibou masqué"></div><div class="field"><label>Message</label><textarea id="directOwlBody" rows="5" maxlength="4000"></textarea></div><div class="grid grid-2"><div class="field"><label>Importance</label><select id="directOwlImportance"><option value="normal">Normal</option><option value="info" selected>Info</option><option value="important">Important</option><option value="urgent">Urgent</option></select></div><label class="notification-toggle"><span>Push</span><input id="directOwlPush" type="checkbox"></label></div><button id="directOwlSend" class="btn gold small" type="button">Envoyer à ${esc(player.username)}</button><div id="directOwlMsg" class="form-msg"></div>`);
  $("#directOwlSend",root).onclick=async()=>{const title=$("#directOwlTitle",root).value.trim(),body=$("#directOwlBody",root).value.trim(),importance=$("#directOwlImportance",root).value,push=$("#directOwlPush",root).checked;if(!title||!body)return setMsg("#directOwlMsg","Titre et message obligatoires.","error");try{if(demoMode){const rows=demoOwlMessages();rows.unshift({id:`owl-${Date.now()}`,season_id:state.season?.id,title,body,importance,target_scope:"player",target_id:userId,push_enabled:push,show_in_history:true,starts_at:new Date().toISOString(),created_at:new Date().toISOString()});localStorage.setItem("nidc_demo_owl_messages",JSON.stringify(rows));}else{const {data:messageId,error}=await sb.rpc("admin_send_owl_message_v060",{p_season_id:state.season?.id||null,p_title:title,p_body:body,p_importance:importance,p_target_scope:"player",p_target_id:userId,p_push:push});if(error)throw error;}await Promise.all([loadOwlData(),loadNotificationData()]);toast(push?`🦉 Message envoyé à ${player.username} · Push immédiat déclenché.`:`🦉 Message envoyé à ${player.username}.`);$("#modalRoot").innerHTML="";}catch(err){setMsg("#directOwlMsg",friendlyError(err),"error");}};
}
