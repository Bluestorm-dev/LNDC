"use strict";

// Le Nid des Champions V0.6.4 — avatars : catalogue et rendu
  // V0.5.3 — Avatars joueurs
  const OFFICIAL_AVATARS = [{"k":"avatar-hibou-royal","l":"Royal","c":"Nobles"},{"k":"avatar-hibou-argent","l":"Argent","c":"Nobles"},{"k":"avatar-hibou-or","l":"Or","c":"Nobles"},{"k":"avatar-hibou-saphir","l":"Saphir","c":"Nobles"},{"k":"avatar-hibou-amethyste","l":"Amethyste","c":"Nobles"},{"k":"avatar-hibou-velours","l":"Velours","c":"Nobles"},{"k":"avatar-hibou-couronne","l":"Couronne","c":"Nobles"},{"k":"avatar-hibou-imperial","l":"Imperial","c":"Nobles"},{"k":"avatar-hibou-europe","l":"Europe","c":"Nobles"},{"k":"avatar-hibou-prestige","l":"Prestige","c":"Nobles"},{"k":"avatar-hibou-minuit","l":"Minuit","c":"Nocturnes"},{"k":"avatar-hibou-eclipse","l":"Eclipse","c":"Nocturnes"},{"k":"avatar-hibou-lunaire","l":"Lunaire","c":"Nocturnes"},{"k":"avatar-hibou-nebuleuse","l":"Nebuleuse","c":"Nocturnes"},{"k":"avatar-hibou-astral","l":"Astral","c":"Nocturnes"},{"k":"avatar-hibou-constellation","l":"Constellation","c":"Nocturnes"},{"k":"avatar-hibou-etoile","l":"Etoile","c":"Nocturnes"},{"k":"avatar-hibou-comete","l":"Comete","c":"Nocturnes"},{"k":"avatar-hibou-orbite","l":"Orbite","c":"Nocturnes"},{"k":"avatar-hibou-galaxie","l":"Galaxie","c":"Nocturnes"},{"k":"avatar-hibou-echarpe","l":"Echarpe","c":"Supporters"},{"k":"avatar-hibou-tambour","l":"Tambour","c":"Supporters"},{"k":"avatar-hibou-tribune","l":"Tribune","c":"Supporters"},{"k":"avatar-hibou-ultra","l":"Ultra","c":"Supporters"},{"k":"avatar-hibou-drapeau","l":"Drapeau","c":"Supporters"},{"k":"avatar-hibou-chant","l":"Chant","c":"Supporters"},{"k":"avatar-hibou-stade","l":"Stade","c":"Supporters"},{"k":"avatar-hibou-kop","l":"Kop","c":"Supporters"},{"k":"avatar-hibou-tifo","l":"Tifo","c":"Supporters"},{"k":"avatar-hibou-fumigene","l":"Fumigene","c":"Supporters"},{"k":"avatar-hibou-buteur","l":"Buteur","c":"Football"},{"k":"avatar-hibou-gardien","l":"Gardien","c":"Football"},{"k":"avatar-hibou-coach","l":"Coach","c":"Football"},{"k":"avatar-hibou-arbitre","l":"Arbitre","c":"Football"},{"k":"avatar-hibou-capitaine","l":"Capitaine","c":"Football"},{"k":"avatar-hibou-meneur","l":"Meneur","c":"Football"},{"k":"avatar-hibou-defenseur","l":"Defenseur","c":"Football"},{"k":"avatar-hibou-ailier","l":"Ailier","c":"Football"},{"k":"avatar-hibou-numero10","l":"Numero10","c":"Football"},{"k":"avatar-hibou-remplacant","l":"Remplacant","c":"Football"},{"k":"avatar-hibou-coupe","l":"Coupe","c":"Champions"},{"k":"avatar-hibou-medaille","l":"Medaille","c":"Champions"},{"k":"avatar-hibou-champion","l":"Champion","c":"Champions"},{"k":"avatar-hibou-finale","l":"Finale","c":"Champions"},{"k":"avatar-hibou-podium","l":"Podium","c":"Champions"},{"k":"avatar-hibou-victoire","l":"Victoire","c":"Champions"},{"k":"avatar-hibou-etoile-or","l":"Etoile Or","c":"Champions"},{"k":"avatar-hibou-trophee","l":"Trophee","c":"Champions"},{"k":"avatar-hibou-legende","l":"Legende","c":"Champions"},{"k":"avatar-hibou-dynastie","l":"Dynastie","c":"Champions"},{"k":"avatar-hibou-casserole","l":"Casserole","c":"Humour"},{"k":"avatar-hibou-poele","l":"Poele","c":"Humour"},{"k":"avatar-hibou-boulet","l":"Boulet","c":"Humour"},{"k":"avatar-hibou-perdu","l":"Perdu","c":"Humour"},{"k":"avatar-hibou-endormi","l":"Endormi","c":"Humour"},{"k":"avatar-hibou-retard","l":"Retard","c":"Humour"},{"k":"avatar-hibou-var","l":"Var","c":"Humour"},{"k":"avatar-hibou-carton","l":"Carton","c":"Humour"},{"k":"avatar-hibou-zero","l":"Zero","c":"Humour"},{"k":"avatar-hibou-mauvaise-foi","l":"Mauvaise Foi","c":"Humour"},{"k":"avatar-hibou-masque","l":"Masque","c":"Mystérieux"},{"k":"avatar-hibou-ombre","l":"Ombre","c":"Mystérieux"},{"k":"avatar-hibou-fantome","l":"Fantome","c":"Mystérieux"},{"k":"avatar-hibou-secret","l":"Secret","c":"Mystérieux"},{"k":"avatar-hibou-oracle","l":"Oracle","c":"Mystérieux"},{"k":"avatar-hibou-prophete","l":"Prophete","c":"Mystérieux"},{"k":"avatar-hibou-mage","l":"Mage","c":"Mystérieux"},{"k":"avatar-hibou-alchimiste","l":"Alchimiste","c":"Mystérieux"},{"k":"avatar-hibou-sorcier","l":"Sorcier","c":"Mystérieux"},{"k":"avatar-hibou-enigme","l":"Enigme","c":"Mystérieux"},{"k":"avatar-hibou-neon","l":"Neon","c":"Futuristes"},{"k":"avatar-hibou-cyber","l":"Cyber","c":"Futuristes"},{"k":"avatar-hibou-hologramme","l":"Hologramme","c":"Futuristes"},{"k":"avatar-hibou-quantique","l":"Quantique","c":"Futuristes"},{"k":"avatar-hibou-electrique","l":"Electrique","c":"Futuristes"},{"k":"avatar-hibou-plasma","l":"Plasma","c":"Futuristes"},{"k":"avatar-hibou-vector","l":"Vector","c":"Futuristes"},{"k":"avatar-hibou-digital","l":"Digital","c":"Futuristes"},{"k":"avatar-hibou-android","l":"Android","c":"Futuristes"},{"k":"avatar-hibou-cosmos","l":"Cosmos","c":"Futuristes"},{"k":"avatar-hibou-cristal","l":"Cristal","c":"Rares"},{"k":"avatar-hibou-diamant","l":"Diamant","c":"Rares"},{"k":"avatar-hibou-obsidienne","l":"Obsidienne","c":"Rares"},{"k":"avatar-hibou-rubis","l":"Rubis","c":"Rares"},{"k":"avatar-hibou-emeraude","l":"Emeraude","c":"Rares"},{"k":"avatar-hibou-opale","l":"Opale","c":"Rares"},{"k":"avatar-hibou-titane","l":"Titane","c":"Rares"},{"k":"avatar-hibou-platine","l":"Platine","c":"Rares"},{"k":"avatar-hibou-arcane","l":"Arcane","c":"Rares"},{"k":"avatar-hibou-aurora","l":"Aurora","c":"Rares"}];
  const LEGACY_AVATAR_MAP = {"owl-gold":"avatar-hibou-or","owl-blue":"avatar-hibou-saphir","owl-violet":"avatar-hibou-amethyste"};
  const AVATAR_MAX_BYTES = 3 * 1024 * 1024;
  const AVATAR_MIME_TYPES = new Set(["image/png","image/jpeg","image/webp"]);
  function normalizedAvatarKey(key) {
    const k=LEGACY_AVATAR_MAP[key]||key||"avatar-hibou-or";
    return OFFICIAL_AVATARS.some(a=>a.k===k)?k:"avatar-hibou-or";
  }
  function playerAvatarUrl(profile,allowPending=false) {
    const p=profileForUser(profile);
    if(p.avatar_preview_url) return p.avatar_preview_url;
    if(p.avatar_source==="upload" && p.avatar_storage_path && (p.avatar_moderation_status==="approved" || allowPending)) {
      if(!configured) return p.avatar_storage_path;
      if(p.avatar_signed_url) return p.avatar_signed_url;
    }
    return `assets/avatars/nid/${normalizedAvatarKey(p.avatar_key)}.png`;
  }
  function avatarCoreHTML(profile,{allowPending=false}={}) {
    const p=profileForUser(profile);
    const initial=(p?.username||"?").slice(0,1).toUpperCase();
    const url=playerAvatarUrl(p,allowPending);
    const pending=p.avatar_source==="upload"&&p.avatar_moderation_status==="pending";
    return `<span class="avatar player-avatar-core player-avatar-transparent ${pending&&allowPending?'avatar-pending':''}"><img class="player-avatar-image" src="${esc(url)}" alt="Avatar de ${esc(p?.username||'joueur')}" loading="lazy" onerror="this.remove();this.parentElement.classList.add('avatar-broken')"><b aria-hidden="true">${esc(initial)}</b>${pending&&allowPending?'<em title="En attente de modération">⏳</em>':''}</span>`;
  }
  function avatarHTML(profile,opts={}) {
    const p=profileForUser(profile);
    const userId=p?.user_id||p?.id;
    const team=teamForUser(userId);
    const core=avatarCoreHTML(p,opts);
    if(!team) return core;
    return `<span class="team-avatar unified-player-avatar ${teamClass(team)}" style="${teamVisualVars(team)}" data-player-id="${esc(userId||'')}" title="${esc(team.team_name||team.name||'Team')}">${core}</span>`;
  }

  async function signAvatarRows(rows,{allowPendingForAdmin=false}={}) {
    if(demoMode||!configured||!rows?.length)return rows||[];
    const canAdmin=isAdminProfile()&&allowPendingForAdmin;
    const eligible=rows.filter(p=>p.avatar_source==="upload"&&p.avatar_storage_path&&(p.avatar_moderation_status==="approved"||String(p.id||p.user_id)===String(state.user?.id)||canAdmin));
    const paths=[...new Set(eligible.map(p=>p.avatar_storage_path))];
    if(!paths.length)return rows;
    const {data,error}=await sb.storage.from("player-avatars").createSignedUrls(paths,3600);
    if(error)return rows;
    const signed=new Map((data||[]).map(x=>[x.path,x.signedUrl||x.signedURL]).filter(x=>x[0]&&x[1]));
    rows.forEach(p=>{if(p.avatar_storage_path&&signed.has(p.avatar_storage_path))p.avatar_signed_url=signed.get(p.avatar_storage_path);});
    return rows;
  }

  async function loadProfileDirectory() {
    if(demoMode){state.profileDirectory=new Map(state.demoUsers.map(p=>[String(p.id),{...p,user_id:p.id}]));return;}
    const {data,error}=await sb.from("profiles").select("id,username,avatar_key,avatar_source,avatar_storage_path,avatar_moderation_status,avatar_rejection_reason,avatar_updated_at,club_heart,role,status").eq("status","active");
    if(error) throw new Error("Migration avatars V0.5.3 absente : exécute sql/HOTFIX_V0.5.3_EXISTING_DB.sql.");
    const rows=(data||[]).map(p=>({...p,user_id:p.id}));
    await signAvatarRows(rows);
    state.profileDirectory=new Map(rows.map(p=>[String(p.id),p]));
  }
