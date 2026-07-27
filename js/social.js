"use strict";

// Le Nid des Champions V0.6.4 — réactions rapides entre joueurs
const PLAYER_REACTION_EMOJIS = [
  ["👏","Bien joué"],
  ["🔥","En feu"],
  ["😂","MDR"],
  ["😱","Incroyable"],
  ["🦉","Hibou"],
  ["🏆","Champion"],
  ["💀","Ça pique"],
  ["❤️","Respect"]
];

function reactionTargetProfile(userId){
  return state.profileDirectory?.get(String(userId)) || null;
}

function reactionButtonHTML(userId, compact=false){
  if(!state.user || String(userId)===String(state.user.id)) return "";
  return `<button type="button" class="player-reaction-trigger ${compact?'compact':''}" data-player-react="${esc(userId)}" title="Envoyer une réaction" aria-label="Envoyer une réaction">😊</button>`;
}

function openPlayerReactionPicker(userId){
  if(!state.user)return;
  if(String(userId)===String(state.user.id))return toast("Tu ne peux pas t’envoyer une réaction à toi-même 😄.","error");
  const p=reactionTargetProfile(userId);
  if(!p)return toast("Joueur introuvable.","error");
  const root=modal(`Réagir à ${p.username}`,`<div class="player-reaction-modal">
    <div class="player-reaction-target">${avatarHTML({...p,user_id:p.id||userId})}<div><span class="eyebrow">Réaction rapide</span><strong>${esc(p.username)}</strong><small>Pas de messagerie : juste une petite plume lancée depuis le Nid.</small></div></div>
    <div class="player-reaction-grid">${PLAYER_REACTION_EMOJIS.map(([emoji,label])=>`<button type="button" data-send-reaction="${esc(emoji)}"><span>${emoji}</span><small>${esc(label)}</small></button>`).join("")}</div>
    <p id="playerReactionMsg" class="form-msg"></p>
  </div>`);
  $$('[data-send-reaction]',root).forEach(btn=>btn.onclick=()=>sendPlayerReaction(userId,btn.dataset.sendReaction,root));
}

async function sendPlayerReaction(recipientUserId,emoji,modalRoot=null){
  const target=reactionTargetProfile(recipientUserId);
  if(!PLAYER_REACTION_EMOJIS.some(([e])=>e===emoji))return;
  const msg=modalRoot?$("#playerReactionMsg",modalRoot):null;
  if(msg){msg.textContent="Envoi…";msg.className="form-msg";}
  try{
    if(demoMode){
      const out=JSON.parse(localStorage.getItem("nidc_demo_reactions")||"[]");
      out.unshift({id:`demo-r-${Date.now()}`,season_id:state.season?.id||null,sender_user_id:state.user.id,recipient_user_id:recipientUserId,emoji,created_at:new Date().toISOString()});
      localStorage.setItem("nidc_demo_reactions",JSON.stringify(out.slice(0,100)));
    }else{
      const {error}=await sb.rpc("send_player_reaction_v062",{p_recipient_user_id:recipientUserId,p_emoji:emoji,p_season_id:state.season?.id||null});
      if(error)throw error;
    }
    if(msg){msg.textContent=`${emoji} envoyé à ${target?.username||"ce joueur"}.`;msg.className="form-msg ok";}
    toast(`${emoji} envoyé à ${target?.username||"ce joueur"}.`);
    setTimeout(()=>{if(modalRoot&&modalRoot===document.querySelector('#modalRoot'))modalRoot.innerHTML="";},420);
  }catch(err){
    const text=friendlyError(err);if(msg){msg.textContent=text;msg.className="form-msg error";}else toast(text,"error");
  }
}

function bindPlayerReactionButtons(root=document){
  $$('[data-player-react]',root).forEach(btn=>{btn.onclick=e=>{e.preventDefault();e.stopPropagation();openPlayerReactionPicker(btn.dataset.playerReact);};});
}
